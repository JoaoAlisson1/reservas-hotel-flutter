import 'package:flutter/material.dart';
import 'package:mask_text_input_formatter/mask_text_input_formatter.dart';
import '../core/dao/funcionarioDAO.dart';
import '../core/models/funcionario.dart';

class FuncionarioRegisterScreen extends StatefulWidget {
  const FuncionarioRegisterScreen({super.key});

  @override
  State<FuncionarioRegisterScreen> createState() => _FuncionarioRegisterScreenState();
}

class _FuncionarioRegisterScreenState extends State<FuncionarioRegisterScreen> {
  final _formKey = GlobalKey<FormState>();

  final _nomeController = TextEditingController();
  final _emailController = TextEditingController();
  final _telefoneController = TextEditingController();

  // configuração da mascara
  final _maskTelefone = MaskTextInputFormatter(
    mask: '(##) #####-####',
    filter: {"#": RegExp(r'[0-9]')},
    type: MaskAutoCompletionType.lazy,
  );

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: const Text("Novo Funcionário"),
        backgroundColor: Colors.blueGrey,
        foregroundColor: Colors.white,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24.0),
        child: Form(
          key: _formKey,
          child: Column(
            children: [
              const Icon(Icons.badge, size: 80, color: Colors.blueGrey),
              const SizedBox(height: 16),
              const Text(
                "Dados Pessoais",
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.blueGrey),
              ),
              const SizedBox(height: 24),

              TextFormField(
                controller: _nomeController,
                textCapitalization: TextCapitalization.words,
                decoration: InputDecoration(
                  labelText: 'Nome Completo',
                  prefixIcon: const Icon(Icons.person),
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(16)),
                ),
                validator: (value) => (value == null || value.isEmpty) ? 'Informe o nome' : null,
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _emailController,
                keyboardType: TextInputType.emailAddress,
                decoration: InputDecoration(
                  labelText: 'E-mail',
                  prefixIcon: const Icon(Icons.email),
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(16)),
                ),
                validator: (value) {
                  if (value == null || !value.contains('@')) return 'E-mail inválido';
                  return null;
                },
              ),
              const SizedBox(height: 16),

              // Campo Telefone com Máscara e Validação
              TextFormField(
                controller: _telefoneController,
                keyboardType: TextInputType.phone,
                inputFormatters: [_maskTelefone], // Aplica a máscara visual
                decoration: InputDecoration(
                  labelText: 'Telefone',
                  hintText: '(00) 00000-0000',
                  prefixIcon: const Icon(Icons.phone),
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(16)),
                ),
                validator: (value) {
                  if (value == null || value.isEmpty) return 'Informe o telefone';

                  // Valida se o usuário digitou o número completo
                  if (_maskTelefone.getUnmaskedText().length < 10) {
                    return 'Telefone incompleto';
                  }
                  return null;
                },
              ),

              const SizedBox(height: 32),

              SizedBox(
                width: double.infinity,
                height: 50,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.blueGrey,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                  ),
                  onPressed: _salvarFuncionario,
                  child: const Text("Cadastrar Funcionário", style: TextStyle(fontSize: 18)),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _salvarFuncionario() async {
    if (_formKey.currentState!.validate()) {

      final novoFuncionario = Funcionario(
        nome: _nomeController.text.trim(),
        email: _emailController.text.trim(),
        telefone: _maskTelefone.getUnmaskedText(),
      );

      try {

        await FuncionarioDAO().insertFuncionario(novoFuncionario);

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text("Funcionário salvo com sucesso!"),
              backgroundColor: Colors.green,
              behavior: SnackBarBehavior.floating,
            ),
          );
          Navigator.pop(context, true); // Retorna true para atualizar a lista automaticamente
        }
      } catch (e) {

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(e.toString().replaceAll('Exception: ', '')),
              backgroundColor: Colors.redAccent,
              behavior: SnackBarBehavior.floating,
            ),
          );
        }
      }
    }
  }
}