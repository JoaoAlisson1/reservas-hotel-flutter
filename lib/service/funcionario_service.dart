import 'dart:convert';
import 'package:http/http.dart' as http;
import '../core/models/funcionario.dart';
import '../core/authentication/auth_service.dart';

class FuncionarioService {

  final String _baseUrl = 'https://reservas-hotel-flutter-api-2.onrender.com/funcionarios';
  final AuthService _authService = AuthService();

  Future<Map<String, String>> _getHeaders() async {
    final token = await _authService.getToken();
    return {
      'Content-Type': 'application/json',
      'Authorization': 'Bearer $token',
    };
  }

  Future<List<Funcionario>> getFuncionarios() async {
    try {
      final headers = await _getHeaders();

      final response = await http.get(
        Uri.parse(_baseUrl),
        headers: headers, // Passa as credenciais com o Token
      );

      if (response.statusCode == 200) {
        final List<dynamic> data = jsonDecode(response.body);
        return data.map((json) => Funcionario.fromMap(json)).toList();
      } else {
        throw Exception('Falha ao carregar funcionários do servidor.');
      }
    } catch (e) {
      throw Exception('Não foi possível conectar ao servidor: $e');
    }
  }

  Future<Funcionario?> getFuncionarioById(int id) async {
    try {
      final headers = await _getHeaders();

      final response = await http.get(
        Uri.parse('$_baseUrl/$id'),
        headers: headers,
      );

      if (response.statusCode == 200) {
        return Funcionario.fromMap(jsonDecode(response.body));
      } else if (response.statusCode == 404) {
        return null;
      } else {
        throw Exception('Erro ao buscar detalhes do funcionário.');
      }
    } catch (e) {
      throw Exception('Erro de conexão ao buscar funcionário: $e');
    }
  }

  Future<void> insertFuncionario(Funcionario funcionario) async {
    try {
      final headers = await _getHeaders();

      final response = await http.post(
        Uri.parse(_baseUrl),
        headers: headers,
        body: jsonEncode(funcionario.toMap()),
      );

      if (response.statusCode != 200 && response.statusCode != 201) {
        if (response.statusCode == 409 || response.statusCode == 400) {
          String mensagemErro = _extrairMensagemErro(response.body);
          throw Exception(mensagemErro.isNotEmpty
              ? mensagemErro
              : 'Este e-mail já está cadastrado para outro funcionário.');
        }
        throw Exception('Erro ao cadastrar funcionário no servidor.');
      }
    } catch (e) {
      if (e.toString().contains('Exception:')) rethrow;
      throw Exception('Erro de conexão ao tentar cadastrar o funcionário.');
    }
  }

  Future<void> updateFuncionario(Funcionario funcionario) async {
    try {
      final headers = await _getHeaders();

      final response = await http.put(
        Uri.parse('$_baseUrl/${funcionario.id}'),
        headers: headers,
        body: jsonEncode(funcionario.toMap()),
      );

      if (response.statusCode != 200) {
        if (response.statusCode == 409 || response.statusCode == 400) {
          String mensagemErro = _extrairMensagemErro(response.body);
          throw Exception(mensagemErro.isNotEmpty
              ? mensagemErro
              : 'Não foi possível atualizar: este e-mail já está em uso.');
        }
        throw Exception('Erro ao atualizar dados do funcionário.');
      }
    } catch (e) {
      if (e.toString().contains('Exception:')) rethrow;
      throw Exception('Erro de conexão ao tentar atualizar o funcionário.');
    }
  }

  Future<void> deleteFuncionario(int id) async {
    try {
      final headers = await _getHeaders();

      final response = await http.delete(
        Uri.parse('$_baseUrl/$id'),
        headers: headers,
      );

      if (response.statusCode != 200 && response.statusCode != 204) {
        if (response.statusCode == 409) {
          throw Exception(
              'Não é possível excluir este funcionário pois ele possui registros vinculados no sistema.'
          );
        }
        throw Exception('Erro ao excluir funcionário do servidor.');
      }
    } catch (e) {
      if (e.toString().contains('Exception:')) rethrow;
      throw Exception('Erro de conexão ao tentar excluir o funcionário.');
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