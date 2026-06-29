import 'dart:convert';
import 'package:http/http.dart' as http;
import '../core/models/reserva.dart';
import '../core/authentication/auth_service.dart';

class ReservaService {

  final String _baseUrl = 'https://reservas-hotel-flutter-api-2.onrender.com/reservas';
  final AuthService _authService = AuthService();

  Future<Map<String, String>> _getHeaders() async {
    final token = await _authService.getToken();
    return {
      'Content-Type': 'application/json',
      'Authorization': 'Bearer $token',
    };
  }

  Future<List<Reserva>> getReservas() async {
    try {
      final headers = await _getHeaders();
      final response = await http.get(
        Uri.parse(_baseUrl),
        headers: headers,
      );

      if (response.statusCode == 200) {
        final List<dynamic> data = jsonDecode(response.body);
        return data.map((json) => Reserva.fromMap(json)).toList();
      } else {
        throw Exception('Falha ao carregar a listagem de reservas.');
      }
    } catch (e) {
      throw Exception('Não foi possível conectar ao servidor: $e');
    }
  }

  Future<Reserva?> getReservaByUuid(String uuid) async {
    try {
      final headers = await _getHeaders();
      final response = await http.get(
        Uri.parse('$_baseUrl/uuid/$uuid'),
        headers: headers,
      );

      if (response.statusCode == 200) {
        return Reserva.fromMap(jsonDecode(response.body));
      } else if (response.statusCode == 404) {
        return null;
      } else {
        throw Exception('Erro ao buscar dados da reserva por UUID.');
      }
    } catch (e) {
      throw Exception('Erro de conexão ao buscar reserva: $e');
    }
  }

  Future<void> insertReserva(Reserva reserva) async {
    try {
      final headers = await _getHeaders();
      final response = await http.post(
        Uri.parse(_baseUrl),
        headers: headers,
        body: jsonEncode(reserva.toMap()),
      );

      if (response.statusCode != 200 && response.statusCode != 201) {
        String mensajeErro = _extrairMensagemErro(response.body);
        throw Exception(mensajeErro.isNotEmpty
            ? mensajeErro
            : 'Erro ao processar reserva. Verifique a disponibilidade do quarto.');
      }
    } catch (e) {
      if (e.toString().contains('Exception:')) rethrow;
      throw Exception('Erro de conexão ao tentar cadastrar a reserva.');
    }
  }

  Future<void> updateReserva(Reserva reserva) async {
    try {
      final headers = await _getHeaders();
      final response = await http.put(
        Uri.parse('$_baseUrl/${reserva.id}'),
        headers: headers,
        body: jsonEncode(reserva.toMap()),
      );

      if (response.statusCode != 200) {
        String mensajeErro = _extrairMensagemErro(response.body);
        throw Exception(mensajeErro.isNotEmpty ? mensajeErro : 'Erro ao atualizar dados da reserva.');
      }
    } catch (e) {
      if (e.toString().contains('Exception:')) rethrow;
      throw Exception('Erro de conexão ao tentar atualizar a reserva.');
    }
  }

  Future<void> realizarCheckIn(int id) async {
    try {
      final headers = await _getHeaders();
      final response = await http.put(
        Uri.parse('$_baseUrl/$id/checkin'),
        headers: headers,
      );

      if (response.statusCode != 200) {
        String mensagemErro = _extrairMensagemErro(response.body);
        throw Exception(mensagemErro.isNotEmpty ? mensagemErro : 'Não foi possível realizar o Check-in.');
      }
    } catch (e) {
      if (e.toString().contains('Exception:')) rethrow;
      throw Exception('Erro de conexão ao registrar Check-in.');
    }
  }

  Future<void> realizarCheckOut(int id) async {
    try {
      final headers = await _getHeaders();
      final response = await http.put(
        Uri.parse('$_baseUrl/$id/checkout'),
        headers: headers,
      );

      if (response.statusCode != 200) {
        String mensagemErro = _extrairMensagemErro(response.body);
        throw Exception(mensagemErro.isNotEmpty ? mensagemErro : 'Não foi possível realizar o Check-out.');
      }
    } catch (e) {
      if (e.toString().contains('Exception:')) rethrow;
      throw Exception('Erro de conexão ao registrar Check-out.');
    }
  }

  Future<void> deleteReserva(int id) async {
    try {
      final headers = await _getHeaders();
      final response = await http.delete(
        Uri.parse('$_baseUrl/$id'),
        headers: headers,
      );

      if (response.statusCode != 200 && response.statusCode != 204) {
        String mensajeErro = _extrairMensagemErro(response.body);
        throw Exception(mensajeErro.isNotEmpty ? mensajeErro : 'Erro ao remover reserva.');
      }
    } catch (e) {
      if (e.toString().contains('Exception:')) rethrow;
      throw Exception('Erro de conexão ao tentar remover a reserva.');
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