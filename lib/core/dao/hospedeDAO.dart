import 'package:uuid/uuid.dart';
import '../database/app_database.dart';
import '../models/hospede.dart';

class HospedeDAO {
  static const String table = 'hospedes';
  final _uuid = const Uuid();

  Future<int> insertHospede(Hospede hospede) async {
    try {
      final db = await AppDatabase().database;
      hospede.uuid ??= _uuid.v4();
      return await db.insert(table, hospede.toMap());
    } catch (e) {
      if (e.toString().contains('UNIQUE constraint failed')) {
        if (e.toString().contains('cpf')) throw Exception('Este CPF já está cadastrado.');
        if (e.toString().contains('email')) throw Exception('Este e-mail já está em uso.');
      }
      rethrow;
    }
  }

  Future<List<Hospede>> findAll() async {
    final db = await AppDatabase().database;
    final List<Map<String, dynamic>> maps = await db.query(table, orderBy: 'nome ASC');
    return List.generate(maps.length, (i) => Hospede.fromMap(maps[i]));
  }

  Future<int> updateHospede(Hospede hospede) async {
    try {
      final db = await AppDatabase().database;
      return await db.update(table, hospede.toMap(), where: 'id = ?', whereArgs: [hospede.id]);
    } catch (e) {
      if (e.toString().contains('UNIQUE constraint failed')) {
        throw Exception('Conflito de dados: CPF ou E-mail já pertencem a outro hóspede.');
      }
      rethrow;
    }
  }

  Future<int> deleteHospede(int id) async {
    final db = await AppDatabase().database;

    // Verifica se o hóspede está em alguma reserva na tabela associativa
    final List<Map<String, dynamic>> vinculo = await db.query(
      'reserva_hospede',
      where: 'hospede_id = ?',
      whereArgs: [id],
      limit: 1,
    );

    if (vinculo.isNotEmpty) {
      throw Exception('Não é possível excluir este hóspede pois ele possui reservas registradas.');
    }

    // Se não houver vínculos, procede com a exclusão
    return await db.delete(table, where: 'id = ?', whereArgs: [id]);
  }
}