import 'package:sqflite/sqflite.dart';
import 'package:uuid/uuid.dart';
import '../database/app_database.dart';
import '../models/reserva.dart';
import '../models/quarto.dart';
import '../models/enums/status_quarto.dart';
import '../models/enums/status_reserva.dart';

class ReservaDAO {
  final _uuid = const Uuid();

  static const List<StatusQuarto> statusBloqueados = [
    StatusQuarto.Ocupado,
    StatusQuarto.Reservado,
    StatusQuarto.Manutencao,
    StatusQuarto.Limpeza,
    StatusQuarto.Indisponivel,
  ];

  Future<int> insertReserva(Reserva reserva, Quarto quarto) async {
    final db = await AppDatabase().database;

    if (statusBloqueados.contains(quarto.status)) {
      throw Exception("Quarto ${quarto.numero} indisponível. Status: ${quarto.status.name}");
    }

    if (reserva.hospedesIds.isEmpty) {
      throw Exception("Nenhum hóspede selecionado para a reserva.");
    }

    // Calcula valor total antes de salvar
    reserva.valorTotal = Reserva.calcularValorEstadia(
        reserva.checkIn,
        reserva.checkOut,
        quarto.diaria
    );

    reserva.uuid ??= _uuid.v4();

    return await db.transaction((txn) async {
      int reservaId = await txn.insert('reservas', reserva.toMap());

      for (int hId in reserva.hospedesIds) {
        await txn.insert('reserva_hospede', {
          'reserva_id': reservaId,
          'hospede_id': hId,
        });
      }

      // Atualiza o status do quarto para Reservado
      await txn.update(
        'quartos',
        {'status': StatusQuarto.Reservado.name},
        where: 'id = ?',
        whereArgs: [quarto.id],
      );

      return reservaId;
    });
  }

  Future<List<Reserva>> findAll() async {
    final db = await AppDatabase().database;

    final List<Map<String, dynamic>> maps = await db.rawQuery('''
      SELECT 
        r.*, 
        q.numero as numero_quarto,
        u.login as login_usuario
      FROM reservas r
      JOIN quartos q ON r.quarto_id = q.id
      JOIN usuarios u ON r.usuario_id = u.id
      ORDER BY r.checkIn DESC
    ''');

    List<Reserva> reservas = [];

    for (var map in maps) {

      Reserva reserva = Reserva.fromMap(map);

      final List<Map<String, dynamic>> hospedesRelacionados = await db.query(
        'reserva_hospede',
        columns: ['hospede_id'],
        where: 'reserva_id = ?',
        whereArgs: [reserva.id],
      );

      reserva.hospedesIds = hospedesRelacionados
          .map((h) => h['hospede_id'] as int)
          .toList();

      // Busca o nome do primeiro hóspede para exibição (Hóspede Principal)
      if (reserva.hospedesIds.isNotEmpty) {
        final List<Map<String, dynamic>> nomeResult = await db.query(
          'hospedes',
          columns: ['nome'],
          where: 'id = ?',
          whereArgs: [reserva.hospedesIds.first],
        );

        if (nomeResult.isNotEmpty) {
          reserva.nomeHospedePrincipal = nomeResult.first['nome'];
        }
      }

      reservas.add(reserva);
    }

    return reservas;
  }

  Future<void> realizarCheckIn(int reservaId, int quartoId) async {
    final db = await AppDatabase().database;

    await db.transaction((txn) async {
      await txn.update(
        'reservas',
        {'status': StatusReserva.Check_in.name},
        where: 'id = ?',
        whereArgs: [reservaId],
      );

      await txn.update(
        'quartos',
        {'status': StatusQuarto.Ocupado.name},
        where: 'id = ?',
        whereArgs: [quartoId],
      );
    });
  }

  Future<void> realizarCheckOut(int reservaId, int quartoId) async {
    final db = await AppDatabase().database;

    await db.transaction((txn) async {
      await txn.update(
        'reservas',
        {'status': StatusReserva.Check_out.name},
        where: 'id = ?',
        whereArgs: [reservaId],
      );

      await txn.update(
        'quartos',
        {'status': StatusQuarto.Limpeza.name},
        where: 'id = ?',
        whereArgs: [quartoId],
      );
    });
  }

  // API
  Future<Reserva?> findByUuid(String uuid) async {
    final db = await AppDatabase().database;
    final List<Map<String, dynamic>> maps = await db.query(
      'reservas',
      where: 'uuid = ?',
      whereArgs: [uuid],
    );

    if (maps.isEmpty) return null;
    return Reserva.fromMap(maps.first);
  }

  Future<void> updateReservaManual(Reserva reserva, Quarto quartoNovo) async {
    final db = await AppDatabase().database;

    final List<Map<String, dynamic>> res = await db.query(
      'reservas',
      where: 'id = ?',
      whereArgs: [reserva.id],
    );

    if (res.isEmpty) throw Exception("Reserva não encontrada para atualização.");
    int quartoAntigoId = res.first['quarto_id'];

    await db.transaction((txn) async {

      await txn.update(
        'reservas',
        reserva.toMap(),
        where: 'id = ?',
        whereArgs: [reserva.id],
      );

      // Atualiza os hóspedes (Remove os antigos e insere os novos vínculos)
      await txn.delete(
        'reserva_hospede',
        where: 'reserva_id = ?',
        whereArgs: [reserva.id],
      );

      for (int hId in reserva.hospedesIds) {
        await txn.insert('reserva_hospede', {
          'reserva_id': reserva.id,
          'hospede_id': hId,
        });
      }

      if (quartoAntigoId != quartoNovo.id) {
        // Libera o quarto antigo
        await txn.update(
          'quartos',
          {'status': StatusQuarto.Disponivel.name},
          where: 'id = ?',
          whereArgs: [quartoAntigoId],
        );

        // Bloqueia o quarto novo
        await txn.update(
          'quartos',
          {'status': StatusQuarto.Reservado.name},
          where: 'id = ?',
          whereArgs: [quartoNovo.id],
        );
      }
    });
  }

  Future<void> deleteReservaManual(Reserva reserva) async {
    final db = await AppDatabase().database;

    await db.transaction((txn) async {

      await txn.delete(
        'reservas',
        where: 'id = ?',
        whereArgs: [reserva.id],
      );

      // Se a reserva não estava finalizada, libera o quarto
      if (reserva.status == StatusReserva.Reservada || reserva.status == StatusReserva.Check_in) {
        await txn.update(
          'quartos',
          {'status': StatusQuarto.Disponivel.name},
          where: 'id = ?',
          whereArgs: [reserva.quartoId],
        );
      }
    });
  }
}