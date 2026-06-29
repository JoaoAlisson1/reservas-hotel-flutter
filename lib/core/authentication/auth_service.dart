import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:sqflite/sqflite.dart';
import '../database/app_database.dart';
import '../models/usuario.dart';

class AuthService {
  static final AuthService _instance = AuthService._internal();
  factory AuthService() => _instance;
  AuthService._internal();

  final String _baseUrlLogin = 'https://reservas-hotel-flutter-api-2.onrender.com/login';

  final _storage = const FlutterSecureStorage();

  Usuario? _usuarioLogado;
  Usuario? get usuarioLogado => _usuarioLogado;

  bool get podeGerenciarOperacoes {
    if (_usuarioLogado == null) return false;
    final permissao = _usuarioLogado!.permissao.toUpperCase();
    return permissao == 'ADMIN' || permissao == 'RECEPCIONISTA';
  }

  bool get ehAdmin {
    if (_usuarioLogado == null) return false;
    return _usuarioLogado!.permissao.toUpperCase() == 'ADMIN';
  }

  Future<String?> getToken() async {
    return await _storage.read(key: 'jwt_token');
  }

  Future<bool> login(String email, String senha) async {
    try {
      final response = await http.post(
        Uri.parse(_baseUrlLogin),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'login': email,
          'senha': senha,
        }),
      );

      if (response.statusCode == 200) {
        final Map<String, dynamic> data = jsonDecode(response.body);

        String token = data['accessToken'];
        await _storage.write(key: 'jwt_token', value: token);

        _usuarioLogado = Usuario.fromMap(data);

        if (_usuarioLogado?.id != null) {
          final db = await AppDatabase().database;
          await db.insert(
            'usuarios',
            {'id': _usuarioLogado!.id},
            conflictAlgorithm: ConflictAlgorithm.ignore,
          );
        }

        return true;
      }
      return false;
    } catch (e) {
      print("Erro no login HTTP: $e");
      return false;
    }
  }

  Future<void> logout() async {
    _usuarioLogado = null;
    await _storage.delete(key: 'jwt_token');
  }
}