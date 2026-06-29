import 'package:flutter/material.dart';
import '../core/authentication/auth_service.dart';
import '../core/models/usuario.dart';
import '../service/usuario_service.dart';
import 'register_screen.dart';

class UsuariosListScreen extends StatefulWidget {
  const UsuariosListScreen({super.key});

  @override
  State<UsuariosListScreen> createState() => _UsuariosListScreenState();
}

class _UsuariosListScreenState extends State<UsuariosListScreen> {

  final UsuarioService _usuarioService = UsuarioService();

  List<Usuario> usuarios = [];
  bool loading = true;

  @override
  void initState() {
    super.initState();
    getUsuarios();
  }

  getUsuarios() async {
    setState(() => loading = true);
    try {
      final lista = await _usuarioService.getUsuarios();
      setState(() {
        usuarios = lista;
      });
    } catch (e) {
      _mostrarMensagem("Erro ao carregar usuários: $e", escorregadio: true);
    } finally {
      setState(() => loading = false);
    }
  }

  deleteUsuario(int id) async {
    try {
      await _usuarioService.deleteUsuario(id);
      _mostrarMensagem('Usuário removido com sucesso!');
      getUsuarios();
    } catch (e) {
      _mostrarMensagem(e.toString());
    }
  }

  editUsuario(int index) async {
    final user = usuarios[index];
    final loginController = TextEditingController(text: user.login);
    final senhaController = TextEditingController(text: user.senha);
    String? permissaoEditada = user.permissao;

    await showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          title: const Text('Editar Usuário'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                    controller: loginController,
                    decoration: const InputDecoration(labelText: 'E-mail')
                ),
                const SizedBox(height: 10),

                DropdownButtonFormField<String>(
                  value: permissaoEditada,
                  items: const [
                    DropdownMenuItem(value: 'ADMIN', child: Text('ADMIN')),
                    DropdownMenuItem(value: 'RECEPCIONISTA', child: Text('RECEPCIONISTA')),
                  ],
                  onChanged: (value) {
                    setDialogState(() => permissaoEditada = value);
                  },
                  decoration: const InputDecoration(labelText: 'Cargo'),
                ),

                TextField(
                    controller: senhaController,
                    obscureText: true,
                    decoration: const InputDecoration(labelText: 'Nova Senha')
                ),
              ],
            ),
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancelar')),
            ElevatedButton(
              onPressed: () async {
                final updated = Usuario(
                  id: user.id,
                  login: loginController.text,
                  permissao: permissaoEditada!,
                  senha: senhaController.text,
                );

                try {
                  await _usuarioService.updateUsuario(updated);
                  _mostrarMensagem('Usuário atualizado com sucesso!');
                  if (mounted) Navigator.pop(context);
                  getUsuarios();
                } catch (e) {
                  _mostrarMensagem(e.toString());
                }
              },
              child: const Text('Salvar'),
            ),
          ],
        ),
      ),
    );
  }

  void _mostrarMensagem(String msg, {bool escorregadio = false}) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(msg.replaceAll('Exception: ', '')),
        backgroundColor: escorregadio ? Colors.red : Colors.green,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final bool usuarioLogadoEhAdmin = AuthService().ehAdmin;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Gerenciar Usuários'),
        backgroundColor: Colors.blueGrey,
        foregroundColor: Colors.white,
      ),
      body: loading
          ? const Center(child: CircularProgressIndicator(color: Colors.blueGrey))
          : usuarios.isEmpty
          ? const Center(child: Text('Nenhum usuário encontrado.'))
          : ListView.builder(
        padding: const EdgeInsets.all(8),
        itemCount: usuarios.length,
        itemBuilder: (context, index) {
          final user = usuarios[index];
          final bool isAdmin = user.permissao.toUpperCase() == 'ADMIN';

          return Card(
            elevation: 2,
            margin: const EdgeInsets.symmetric(vertical: 4),
            child: ListTile(
              leading: CircleAvatar(
                backgroundColor: isAdmin ? Colors.red.shade100 : Colors.blue.shade100,
                child: Icon(
                  isAdmin ? Icons.security : Icons.person,
                  color: isAdmin ? Colors.red : Colors.blue,
                ),
              ),
              title: Text(
                user.login,
                style: const TextStyle(fontWeight: FontWeight.bold),
              ),
              subtitle: Text(isAdmin ? 'Administrador' : 'Recepcionista'),

              trailing: usuarioLogadoEhAdmin ? PopupMenuButton<String>(
                onSelected: (value) {
                  if (value == 'edit') editUsuario(index);
                  if (value == 'delete') {
                    if (user.id == 1) {
                      _mostrarMensagem('O Administrador raiz não pode ser excluído!', escorregadio: true);
                    } else {
                      deleteUsuario(user.id!);
                    }
                  }
                },
                itemBuilder: (context) => [
                  const PopupMenuItem(
                    value: 'edit',
                    child: Row(
                      children: [
                        Icon(Icons.edit, size: 20, color: Colors.blue),
                        SizedBox(width: 10),
                        Text('Editar'),
                      ],
                    ),
                  ),
                  const PopupMenuItem(
                    value: 'delete',
                    child: Row(
                      children: [
                        Icon(Icons.delete, size: 20, color: Colors.red),
                        SizedBox(width: 10),
                        Text('Excluir', style: TextStyle(color: Colors.red)),
                      ],
                    ),
                  ),
                ],
              ) : null,
            ),
          );
        },
      ),
      floatingActionButton: usuarioLogadoEhAdmin ? FloatingActionButton(
        backgroundColor: Colors.blueGrey,
        onPressed: () {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => const RegisterScreen()),
          ).then((value) => getUsuarios());
        },
        child: const Icon(Icons.person_add, color: Colors.white),
      ) : null,
    );
  }
}