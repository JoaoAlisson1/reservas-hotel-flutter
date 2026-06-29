import 'dart:convert';
import 'package:http/http.dart' as http;
import '../core/models/usuario.dart';
import '../core/authentication/auth_service.dart';

class UsuarioService {

  final String _baseUrl = 'https://reservas-hotel-flutter-api-2.onrender.com/usuarios';
  final AuthService _authService = AuthService();

  Future<Map<String, String>> _getHeaders() async {
    final token = await _authService.getToken();
    return {
      'Content-Type': 'application/json',
      'Authorization': 'Bearer $token',
    };
  }

  Future<List<Usuario>> getUsuarios() async {
    try {

      final headers = await _getHeaders();
      final response = await http.get(
        Uri.parse(_baseUrl),
        headers: headers, // Passa as credenciais com o Token
      );

      if (response.statusCode == 200) {
        final List<dynamic> dados = jsonDecode(response.body);
        return dados.map((json) => Usuario.fromMap(json)).toList();
      }
      throw Exception("Falha ao listar usuários do servidor.");
    } catch (e) {
      throw Exception("Erro de conexão com o servidor: $e");
    }
  }

  Future<void> insertUsuario(Usuario usuario) async {
    try {

      final headers = await _getHeaders();
      final response = await http.post(
        Uri.parse(_baseUrl),
        headers: headers,
        body: jsonEncode(usuario.toMap()),
      );

      if (response.statusCode != 200 && response.statusCode != 201) {
        final errorData = jsonDecode(response.body);
        throw Exception(errorData['message'] ?? "Erro ao salvar usuário.");
      }
    } catch (e) {
      throw Exception(e.toString().replaceAll('Exception: ', ''));
    }
  }

  Future<void> updateUsuario(Usuario usuario) async {
    try {

      final headers = await _getHeaders();
      final response = await http.put(
        Uri.parse('$_baseUrl/${usuario.id}'),
        headers: headers,
        body: jsonEncode(usuario.toMap()),
      );

      if (response.statusCode != 200 && response.statusCode != 204) {
        final errorData = jsonDecode(response.body);
        throw Exception(errorData['message'] ?? "Erro ao atualizar usuário.");
      }
    } catch (e) {
      throw Exception(e.toString().replaceAll('Exception: ', ''));
    }
  }

  Future<void> deleteUsuario(int id) async {
    try {

      final headers = await _getHeaders();
      final response = await http.delete(
        Uri.parse('$_baseUrl/$id'),
        headers: headers,
      );

      if (response.statusCode != 200 && response.statusCode != 204) {
        final errorData = jsonDecode(response.body);
        throw Exception(errorData['message'] ?? "Não foi possível excluir o usuário.");
      }
    } catch (e) {
      throw Exception("Erro ao conectar ao servidor: $e");
    }
  }
}