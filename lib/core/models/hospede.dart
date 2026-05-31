class Hospede {
  int? id;
  String? uuid;
  String nome;
  String email;
  String telefone;
  String cpf;

  Hospede({
    this.id,
    this.uuid,
    required this.nome,
    required this.email,
    required this.telefone,
    required this.cpf,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'uuid': uuid,
      'nome': nome,
      'email': email,
      'telefone': telefone,
      'cpf': cpf,
    };
  }

  factory Hospede.fromMap(Map<String, dynamic> map) {
    return Hospede(
      id: map['id'],
      uuid: map['uuid'],
      nome: map['nome'],
      email: map['email'],
      telefone: map['telefone'],
      cpf: map['cpf'],
    );
  }
}