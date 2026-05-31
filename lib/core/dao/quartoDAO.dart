import 'package:uuid/uuid.dart';
import '../database/app_database.dart';
import '../models/quarto.dart';

class QuartoDAO {
  static const String table = 'quartos';
  final _uuid = const Uuid();

  Future<int> insertQuarto(Quarto quarto) async {
    try {
      final db = await AppDatabase().database;
      quarto.uuid ??= _uuid.v4();

      // Impede números de quartos duplicados
      return await db.insert(table, quarto.toMap());
    } catch (e) {
      if (e.toString().contains('UNIQUE constraint failed')) {
        throw Exception('Já existe um quarto cadastrado com o número ${quarto.numero}.');
      }
      rethrow;
    }
  }

  Future<List<Quarto>> findAll() async {
    final db = await AppDatabase().database;
    final List<Map<String, dynamic>> maps = await db.query(table, orderBy: 'numero ASC');
    return List.generate(maps.length, (i) => Quarto.fromMap(maps[i]));
  }

  Future<int> updateQuarto(Quarto quarto) async {
    try {
      final db = await AppDatabase().database;
      return await db.update(
          table,
          quarto.toMap(),
          where: 'id = ?',
          whereArgs: [quarto.id]
      );
    } catch (e) {
      // verifica se o novo número escolhido já pertence a outro ID
      if (e.toString().contains('UNIQUE constraint failed')) {
        throw Exception('Já existe um quarto cadastrado com o número ${quarto.numero}.');
      }
      rethrow;
    }
  }

  Future<int> deleteQuarto(int id) async {
    final db = await AppDatabase().database;

    //  Verifica se existe pelo menos uma reserva vinculada a este quarto
    final List<Map<String, dynamic>> reservasVinculadas = await db.query(
      'reservas',
      where: 'quarto_id = ?',
      whereArgs: [id],
      limit: 1,
    );

    if (reservasVinculadas.isNotEmpty) {
      throw Exception(
          'Não é possível excluir este quarto pois ele possui reservas registradas no histórico.'
      );
    }

    return await db.delete(table, where: 'id = ?', whereArgs: [id]);
  }
}