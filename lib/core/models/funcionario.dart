class Funcionario {
  int? id;
  String? uuid;
  String nome;
  String email;
  String telefone;

  Funcionario({
    this.id,
    this.uuid,
    required this.nome,
    required this.email,
    required this.telefone,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'uuid': uuid,
      'nome': nome,
      'email': email,
      'telefone': telefone,
    };
  }

  factory Funcionario.fromMap(Map<String, dynamic> map) {
    return Funcionario(
      id: map['id'],
      uuid: map['uuid'],
      nome: map['nome'],
      email: map['email'],
      telefone: map['telefone'],
    );
  }
}