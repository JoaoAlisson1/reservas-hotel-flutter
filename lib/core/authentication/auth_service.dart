import '../dao/usuarioDAO.dart';
import '../models/usuario.dart';

class AuthService {
  static final AuthService _instance = AuthService._internal();
  factory AuthService() => _instance;
  AuthService._internal();

  final UsuarioDAO _usuarioDAO = UsuarioDAO();

  // Variável que armazena quem está usando o app no momento
  Usuario? _usuarioLogado;
  Usuario? get usuarioLogado => _usuarioLogado;

  bool get podeGerenciarOperacoes {
    if (_usuarioLogado == null) return false;
    return _usuarioLogado!.permissao == 'ADMIN' ||
        _usuarioLogado!.permissao == 'RECEPCIONISTA';
  }

  /// Retorna verdadeiro apenas se for ADMIN.
  /// Usado para: Excluir qualquer registro e gerenciar a equipe de Funcionários.
  bool get ehAdmin {
    return _usuarioLogado?.permissao == 'ADMIN';
  }

  Future<bool> login(String email, String senha) async {
    try {
      final user = await _usuarioDAO.getUsuario(email, senha);
      if (user != null) {
        _usuarioLogado = user;
        return true;
      }
      return false;
    } catch (e) {
      print("Erro no login: $e");
      return false;
    }
  }

  Future<bool> register(Usuario usuario) async {
    try {

      final bool emailJaExiste = await _usuarioDAO.verificarSeEmailExiste(usuario.login);

      if (emailJaExiste) {
        print("Erro no registro: O e-mail ${usuario.login} já está em uso.");
        return false; // Retorna false e impede o cadastro
      }

      await _usuarioDAO.insertUsuario(usuario);
      return true;
    } catch (e) {
      print("Erro no registro: $e");

      return false;
    }
  }

  void logout() {
    _usuarioLogado = null;
  }
}