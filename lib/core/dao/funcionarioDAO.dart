import 'package:uuid/uuid.dart';
import '../database/app_database.dart';
import '../models/funcionario.dart';

class FuncionarioDAO {
  static const String table = 'funcionarios';
  final _uuid = const Uuid();

  Future<int> insertFuncionario(Funcionario funcionario) async {
    try {
      final db = await AppDatabase().database;

      funcionario.uuid ??= _uuid.v4();

      return await db.insert(table, funcionario.toMap());
    } catch (e) {

      if (e.toString().contains('UNIQUE constraint failed')) {
        throw Exception('Este e-mail já está cadastrado para outro funcionário.');
      }
      rethrow;
    }
  }

  // LISTAR TODOS
  Future<List<Funcionario>> findAll() async {
    final db = await AppDatabase().database;
    final List<Map<String, dynamic>> maps = await db.query(table, orderBy: 'nome ASC');

    return List.generate(maps.length, (i) => Funcionario.fromMap(maps[i]));
  }

  Future<int> updateFuncionario(Funcionario funcionario) async {
    try {
      final db = await AppDatabase().database;

      return await db.update(
        table,
        funcionario.toMap(),
        where: 'id = ?',
        whereArgs: [funcionario.id],
      );
    } catch (e) {
      if (e.toString().contains('UNIQUE constraint failed')) {
        throw Exception('Não foi possível atualizar: este e-mail já está em uso.');
      }
      rethrow;
    }
  }

  Future<int> delete(int id) async {
    final db = await AppDatabase().database;
    return await db.delete(
      table,
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  Future<Funcionario?> findById(int id) async {
    final db = await AppDatabase().database;
    final List<Map<String, dynamic>> maps = await db.query(
      table,
      where: 'id = ?',
      whereArgs: [id],
    );

    if (maps.isNotEmpty) {
      return Funcionario.fromMap(maps.first);
    }
    return null;
  }
}