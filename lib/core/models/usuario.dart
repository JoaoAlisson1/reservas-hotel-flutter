class Usuario {
  final int? id;
  final String login;
  final String senha;
  final String permissao;

  Usuario({
    this.id,
    required this.login,
    required this.senha,
    required this.permissao,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'login': login,
      'senha': senha,
      'permissao': permissao,
    };
  }

  factory Usuario.fromMap(Map<String, dynamic> map) {
    return Usuario(
      id: map['id'] as int?,
      login: map['login'] as String,
      senha: map['senha'] != null ? map['senha'] as String : '',
      permissao: map['permissao'] as String,
    );
  }
}