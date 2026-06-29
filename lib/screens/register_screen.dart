import 'package:flutter/material.dart';
import '../core/authentication/auth_service.dart';
import '../core/models/usuario.dart';
import '../service/usuario_service.dart';

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
  bool _isSaving = false;

  @override
  void dispose() {
    loginController.dispose();
    senhaController.dispose();
    super.dispose();
  }

  void _mostrarFeedback(String mensagem, {bool isError = false}) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(mensagem),
        backgroundColor: isError ? Colors.redAccent : Colors.green,
      ),
    );
  }

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
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 32.0, vertical: 12.0),
                child: TextFormField(
                  controller: loginController,
                  keyboardType: TextInputType.emailAddress,
                  enabled: !_isSaving,
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
                  value: permissaoSelecionada,
                  items: perfis.map((String perfil) {
                    return DropdownMenuItem<String>(
                      value: perfil,
                      child: Text(perfil),
                    );
                  }).toList(),
                  onChanged: _isSaving ? null : (novoValor) {
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
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 32.0, vertical: 12.0),
                child: TextFormField(
                  controller: senhaController,
                  obscureText: true,
                  enabled: !_isSaving,
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
              SizedBox(
                height: 50,
                width: 250,
                child: ElevatedButton(
                  onPressed: _isSaving ? null : () async {
                    if (_formKey.currentState!.validate()) {
                      setState(() => _isSaving = true);

                      final String emailInserido = loginController.text.trim();

                      final Usuario novoUsuario = Usuario(
                        login: emailInserido,
                        senha: senhaController.text,
                        permissao: permissaoSelecionada!,
                      );

                      try {
                        await UsuarioService().insertUsuario(novoUsuario);

                        _mostrarFeedback('Usuário cadastrado com sucesso!');
                        if (mounted) Navigator.pop(context);
                      } catch (e) {

                        _mostrarFeedback(e.toString(), isError: true);
                      } finally {
                        if (mounted) {
                          setState(() => _isSaving = false);
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
                  child: _isSaving
                      ? const SizedBox(
                    width: 24,
                    height: 24,
                    child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
                  )
                      : const Text('Cadastrar', style: TextStyle(fontSize: 22)),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}