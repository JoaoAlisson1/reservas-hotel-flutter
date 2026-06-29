import 'dart:convert';
import 'package:http/http.dart' as http;
import '../core/models/hospede.dart';
import '../core/authentication/auth_service.dart';

class HospedeService {

  final String _baseUrl = 'https://reservas-hotel-flutter-api-2.onrender.com/hospedes';
  final AuthService _authService = AuthService();

  Future<Map<String, String>> _getHeaders() async {
    final token = await _authService.getToken();
    return {
      'Content-Type': 'application/json',
      'Authorization': 'Bearer $token',
    };
  }

  Future<List<Hospede>> getHospedes() async {
    try {
      final headers = await _getHeaders();

      final response = await http.get(
        Uri.parse(_baseUrl),
        headers: headers,
      );

      if (response.statusCode == 200) {

        final List<dynamic> data = jsonDecode(response.body);
        return data.map((json) => Hospede.fromMap(json)).toList();
      } else {
        throw Exception('Falha ao carregar hóspedes do servidor.');
      }
    } catch (e) {
      throw Exception('Não foi possível conectar ao servidor: $e');
    }
  }

  Future<void> insertHospede(Hospede hospede) async {
    try {

      final headers = await _getHeaders();

      final response = await http.post(
        Uri.parse(_baseUrl),
        headers: headers,
        body: jsonEncode(hospede.toMap()),
      );

      if (response.statusCode != 200 && response.statusCode != 201) {

        if (response.statusCode == 409 || response.statusCode == 400) {
          String mensagemErro = _extrairMensagemErro(response.body);

          if (mensagemErro.isNotEmpty) {
            throw Exception(mensagemErro);
          }

          throw Exception('Conflito de dados: CPF ou E-mail já estão cadastrados.');
        }

        throw Exception('Erro ao cadastrar hóspede no servidor.');
      }
    } catch (e) {
      if (e.toString().contains('Exception:')) rethrow;
      throw Exception('Erro de conexão ao tentar cadastrar o hóspede.');
    }
  }

  Future<void> updateHospede(Hospede hospede) async {
    try {
      final headers = await _getHeaders();

      final response = await http.put(
        Uri.parse('$_baseUrl/${hospede.id}'),
        headers: headers,
        body: jsonEncode(hospede.toMap()),
      );

      if (response.statusCode != 200) {
        if (response.statusCode == 409 || response.statusCode == 400) {
          String mensagemErro = _extrairMensagemErro(response.body);

          if (mensagemErro.isNotEmpty) {
            throw Exception(mensagemErro);
          }

          throw Exception('Conflito de dados: CPF ou E-mail já pertencem a outro hóspede.');
        }
        throw Exception('Erro ao atualizar dados do hóspede.');
      }
    } catch (e) {
      if (e.toString().contains('Exception:')) rethrow;
      throw Exception('Erro de conexão ao tentar atualizar o hóspede.');
    }
  }

  Future<void> deleteHospede(int id) async {
    try {
      final headers = await _getHeaders();

      final response = await http.delete(
        Uri.parse('$_baseUrl/$id'),
        headers: headers,
      );

      if (response.statusCode != 200 && response.statusCode != 204) {

        if (response.statusCode == 409) {
          throw Exception(
              'Não é possível excluir este hóspede pois ele possui reservas registradas.'
          );
        }

        throw Exception('Erro ao excluir hóspede do servidor.');
      }
    } catch (e) {
      if (e.toString().contains('Exception:')) rethrow;
      throw Exception('Erro de conexão ao tentar excluir o hóspede.');
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