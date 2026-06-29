import 'enums/status_reserva.dart';

class Reserva {
  int? id;
  String? uuid;
  DateTime checkIn;
  DateTime checkOut;
  double valorTotal;
  StatusReserva status;
  int usuarioId;
  int quartoId;
  List<int> hospedesIds;

  String? nomeHospedePrincipal;
  int? numeroQuarto;
  String? loginUsuarioResponsavel;

  Reserva({
    this.id,
    this.uuid,
    required this.checkIn,
    required this.checkOut,
    this.valorTotal = 0.0,
    required this.status,
    required this.usuarioId,
    required this.quartoId,
    List<int>? hospedesIds,
    this.nomeHospedePrincipal,
    this.numeroQuarto,
  }) : this.hospedesIds = hospedesIds ?? [];

  static double calcularValorEstadia(DateTime checkIn, DateTime checkOut, double diaria) {
    if (checkOut.isBefore(checkIn)) {
      throw Exception("A data de check-out não pode ser anterior à data de check-in.");
    }

    // Calcula a diferença absoluta em dias
    int dias = checkOut.difference(checkIn).inDays;

    if (dias <= 0) {
      dias = 1;
    }

    return dias * diaria;
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'uuid': uuid,
      'checkIn': checkIn.toIso8601String(),
      'checkOut': checkOut.toIso8601String(),
      'valorTotal': valorTotal,
      'status': status.name,
      'usuario_id': usuarioId,
      'quarto_id': quartoId,
      'hospedes_ids': hospedesIds,
    };
  }

  factory Reserva.fromMap(Map<String, dynamic> map) {
    return Reserva(
      id: map['id'],
      uuid: map['uuid'],
      checkIn: DateTime.parse(map['checkIn']),
      checkOut: DateTime.parse(map['checkOut']),
      valorTotal: map['valorTotal']?.toDouble() ?? 0.0,
      status: StatusReserva.values.byName(map['status']),
      usuarioId: map['usuarioId'] ?? map['usuario_id'],
      quartoId: map['quartoId'] ?? map['quarto_id'],
      nomeHospedePrincipal: map['nomeHospedePrincipal'] ?? map['nome_hospede'],
      numeroQuarto: map['numeroQuarto'] ?? map['numero_quarto'],
      hospedesIds: map['hospedesIds'] != null
          ? List<int>.from(map['hospedesIds'])
          : (map['hospedes_ids'] != null ? List<int>.from(map['hospedes_ids']) : []),
    )..loginUsuarioResponsavel = map['loginUsuarioResponsavel'] ?? map['login_usuario'];
  }
}