import 'dart:convert';
import 'package:http/http.dart' as http;
import '../core/models/quarto.dart';
import '../core/authentication/auth_service.dart';

class QuartoService {

  final String _baseUrl = 'https://reservas-hotel-flutter-api-2.onrender.com/quartos';
  final AuthService _authService = AuthService();

  Future<Map<String, String>> _getHeaders() async {
    final token = await _authService.getToken();
    return {
      'Content-Type': 'application/json',
      'Authorization': 'Bearer $token',
    };
  }

  Future<List<Quarto>> getQuartos() async {
    try {
      final headers = await _getHeaders();
      final response = await http.get(
        Uri.parse(_baseUrl),
        headers: headers,
      );

      if (response.statusCode == 200) {
        final List<dynamic> data = jsonDecode(response.body);
        return data.map((json) => Quarto.fromMap(json)).toList();
      } else {
        throw Exception('Falha ao carregar quartos do servidor.');
      }
    } catch (e) {
      throw Exception('Não foi possível conectar ao servidor: $e');
    }
  }

  Future<void> insertQuarto(Quarto quarto) async {
    try {
      final headers = await _getHeaders();

      final response = await http.post(
        Uri.parse(_baseUrl),
        headers: headers,
        body: jsonEncode(quarto.toMap()),
      );

      if (response.statusCode != 200 && response.statusCode != 201) {
        if (response.statusCode == 409 || response.statusCode == 400) {
          String mensagemErro = _extrairMensagemErro(response.body);
          throw Exception(mensagemErro.isNotEmpty
              ? mensagemErro
              : 'Já existe um quarto cadastrado com o número ${quarto.numero}.');
        }

        throw Exception('Erro ao cadastrar quarto no servidor.');
      }
    } catch (e) {
      if (e.toString().contains('Exception:')) rethrow;
      throw Exception('Erro de conexão ao tentar cadastrar o quarto.');
    }
  }

  Future<void> updateQuarto(Quarto quarto) async {
    try {
      final headers = await _getHeaders();

      final response = await http.put(
        Uri.parse('$_baseUrl/${quarto.id}'),
        headers: headers,
        body: jsonEncode(quarto.toMap()),
      );

      if (response.statusCode != 200) {
        if (response.statusCode == 409 || response.statusCode == 400) {
          String mensagemErro = _extrairMensagemErro(response.body);
          throw Exception(mensagemErro.isNotEmpty
              ? mensagemErro
              : 'O número ${quarto.numero} já está sendo usado por outro quarto.');
        }
        throw Exception('Erro ao atualizar quarto.');
      }
    } catch (e) {
      if (e.toString().contains('Exception:')) rethrow;
      throw Exception('Erro de conexão ao tentar atualizar o quarto.');
    }
  }

  Future<void> deleteQuarto(int id) async {
    try {
      final headers = await _getHeaders();

      final response = await http.delete(
        Uri.parse('$_baseUrl/$id'),
        headers: headers,
      );

      if (response.statusCode != 200 && response.statusCode != 204) {

        if (response.statusCode == 409) {
          throw Exception(
              'Não é possível excluir este quarto pois ele possui reservas registradas no histórico.'
          );
        }

        throw Exception('Erro ao excluir quarto do servidor.');
      }
    } catch (e) {
      if (e.toString().contains('Exception:')) rethrow;
      throw Exception('Erro de conexão ao tentar excluir o quarto.');
    }
  }

  String _extrairMensagemErro(String body) {
    try {
      final dados = jsonDecode(body);
      if (dados is Map && dados.containsKey('message')) {
        return dados['message'];
      }
      return body;
    } catch (_) {
      return body;
    }
  }
}