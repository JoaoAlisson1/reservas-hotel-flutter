import 'package:flutter/material.dart';
import '../core/authentication/auth_service.dart';
import '../core/models/usuario.dart';
import '../core/dao/usuarioDAO.dart';
import 'register_screen.dart';

class UsuariosListScreen extends StatefulWidget {
  const UsuariosListScreen({super.key});

  @override
  State<UsuariosListScreen> createState() => _UsuariosListScreenState();
}

class _UsuariosListScreenState extends State<UsuariosListScreen> {
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
      usuarios = await UsuarioDAO().findAllUsuarios();
    } finally {
      setState(() => loading = false);
    }
  }

  deleteUsuario(int id) async {
    await UsuarioDAO().deleteUsuario(id);
    getUsuarios();
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Usuário removido com sucesso!')),
    );
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
                  initialValue: permissaoEditada,
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
                await UsuarioDAO().updateUsuario(updated);
                getUsuarios();
                Navigator.pop(context);
              },
              child: const Text('Salvar'),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final bool usuarioLogadoEhAdmin = AuthService().usuarioLogado?.permissao == 'ADMIN';

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
          final bool isAdmin = user.permissao == 'ADMIN';

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

              // O menu de ações só aparece se o usuário que está logado for um ADMIN
              trailing: usuarioLogadoEhAdmin ? PopupMenuButton<String>(
                onSelected: (value) {
                  if (value == 'edit') editUsuario(index);
                  if (value == 'delete') {
                    if (user.id == 1) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('O Administrador raiz não pode ser excluído!')),
                      );
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
              ) : null, // Se não for admin, o menu de editar/excluir some da lista
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