import 'package:flutter/material.dart';
import '../core/authentication/auth_service.dart';
import '../core/models/usuario.dart';
import '../core/dao/usuarioDAO.dart';

class RegisterScreen extends StatefulWidget {
  const RegisterScreen({super.key});

  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();

  final loginController = TextEditingController();
  final senhaController = TextEditingController();
  String? permissaoSelecionada;

  final List<String> perfis = ['ADMIN', 'RECEPCIONISTA'];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: const Text("Novo Usuário"),
        backgroundColor: Colors.blueGrey,
        foregroundColor: Colors.white,
      ),
      body: SingleChildScrollView(
        child: Form(
          key: _formKey,
          child: Column(
            children: [
              const Padding(
                padding: EdgeInsets.only(top: 40.0, bottom: 10.0),
                child: Center(
                  child: Icon(Icons.person_add, size: 80, color: Colors.blueGrey),
                ),
              ),
              const Text(
                "Cadastrar no Sistema",
                style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: Colors.blueGrey),
              ),

              // Campo de E-mail (Login)
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 32.0, vertical: 12.0),
                child: TextFormField(
                  controller: loginController,
                  keyboardType: TextInputType.emailAddress,
                  validator: (value) {
                    if (value == null || value.isEmpty) return '* Obrigatório';
                    if (!value.contains('@') || !value.contains('.')) {
                      return 'Insira um e-mail válido';
                    }
                    return null;
                  },
                  decoration: InputDecoration(
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(16)),
                    label: const Text('E-mail (Login)'),
                    prefixIcon: const Icon(Icons.email),
                  ),
                ),
              ),

              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 32.0, vertical: 12.0),
                child: DropdownButtonFormField<String>(
                  initialValue: permissaoSelecionada,
                  items: perfis.map((String perfil) {
                    return DropdownMenuItem<String>(
                      value: perfil,
                      child: Text(perfil),
                    );
                  }).toList(),
                  onChanged: (novoValor) {
                    setState(() {
                      permissaoSelecionada = novoValor;
                    });
                  },
                  validator: (value) => value == null ? '* Selecione um cargo' : null,
                  decoration: InputDecoration(
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(16)),
                    label: const Text('Cargo / Permissão'),
                    prefixIcon: const Icon(Icons.badge),
                  ),
                ),
              ),

              // Campo de Senha
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 32.0, vertical: 12.0),
                child: TextFormField(
                  controller: senhaController,
                  obscureText: true,
                  validator: (value) => (value == null || value.length < 3)
                      ? 'Mínimo 3 caracteres'
                      : null,
                  decoration: InputDecoration(
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(16)),
                    label: const Text('Senha'),
                    prefixIcon: const Icon(Icons.lock),
                  ),
                ),
              ),

              const SizedBox(height: 30),

              // Botão de Cadastrar
              SizedBox(
                height: 50,
                width: 250,
                child: ElevatedButton(
                  onPressed: () async {
                    if (_formKey.currentState!.validate()) {
                      final String emailInserido = loginController.text.trim();

                      final bool emailJaExiste = await UsuarioDAO().verificarSeEmailExiste(emailInserido);

                      if (emailJaExiste) {
                        if (mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text('Este e-mail já está cadastrado no sistema!'),
                              backgroundColor: Colors.redAccent,
                            ),
                          );
                        }
                        return;
                      }

                      final Usuario novoUsuario = Usuario(
                        login: emailInserido,
                        senha: senhaController.text,
                        permissao: permissaoSelecionada!,
                      );

                      final bool success = await AuthService().register(novoUsuario);

                      if (success) {
                        if (mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text('Usuário cadastrado com sucesso!'),
                              backgroundColor: Colors.green,
                            ),
                          );
                          Navigator.pop(context);
                        }
                      } else {
                        if (mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text('Erro ao cadastrar usuário.'),
                              backgroundColor: Colors.redAccent,
                            ),
                          );
                        }
                      }
                    }
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.blueGrey,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(20)),
                  ),
                  child: const Text('Cadastrar', style: TextStyle(fontSize: 22)),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}