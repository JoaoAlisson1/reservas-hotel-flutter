import '../database/app_database.dart';
import '../models/usuario.dart';

class UsuarioDAO {

  static const String table = 'usuarios';

  Future<int> insertUsuario(Usuario usuario) async {
    final db = await AppDatabase().database;
    return await db.insert(table, usuario.toMap());
  }

  Future<Usuario?> getUsuario(String login, String senha) async {
    final db = await AppDatabase().database;
    final result = await db.query(
      table,
      where: 'login = ? AND senha = ?',
      whereArgs: [login, senha],
    );

    if (result.isNotEmpty) {
      return Usuario.fromMap(result.first);
    }
    return null;
  }

  Future<int> updateUsuario(Usuario usuario) async {
    final db = await AppDatabase().database;
    return await db.update(
      table,
      usuario.toMap(),
      where: 'id = ?',
      whereArgs: [usuario.id],
    );
  }

  Future<int> deleteUsuario(int id) async {
    final db = await AppDatabase().database;
    return await db.delete(
      table,
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  Future<List<Usuario>> findAllUsuarios() async {
    final db = await AppDatabase().database;
    final result = await db.query(
      table,
      orderBy: 'login ASC',
    );
    return result.map((element) => Usuario.fromMap(element)).toList();
  }

  Future<bool> verificarSeEmailExiste(String login) async {
    final db = await AppDatabase().database;
    final result = await db.query(
      table,
      where: 'login = ?',
      whereArgs: [login],
    );

    return result.isNotEmpty;
  }
}