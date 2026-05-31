import 'package:uuid/uuid.dart';

import 'enums/status_quarto.dart';
import 'enums/tipo_quarto.dart';

class Quarto {
  int? id;
  String? uuid;
  int numero;
  TipoQuarto tipo;
  StatusQuarto status;
  double diaria;

  Quarto({
    this.id,
    this.uuid,
    required this.numero,
    required this.tipo,
    required this.status,
    required this.diaria,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'uuid': uuid,
      'numero': numero,
      'tipo': tipo.name,
      'status': status.name,
      'diaria': diaria,
    };
  }

  factory Quarto.fromMap(Map<String, dynamic> map) {
    return Quarto(
      id: map['id'],
      uuid: map['uuid'],
      numero: map['numero'],
      tipo: TipoQuarto.values.byName(map['tipo']),
      status: StatusQuarto.values.byName(map['status']),
      diaria: map['diaria'],
    );
  }
}