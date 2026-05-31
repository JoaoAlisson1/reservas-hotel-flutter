import 'package:flutter/material.dart';
import 'package:mask_text_input_formatter/mask_text_input_formatter.dart';
import '../core/dao/hospedeDAO.dart';
import '../core/models/hospede.dart';

class HospedeRegisterScreen extends StatefulWidget {
  final Hospede? hospedeParaEdicao; // Recebe o objeto se for edição

  const HospedeRegisterScreen({super.key, this.hospedeParaEdicao});

  @override
  State<HospedeRegisterScreen> createState() => _HospedeRegisterScreenState();
}

class _HospedeRegisterScreenState extends State<HospedeRegisterScreen> {
  final _formKey = GlobalKey<FormState>();

  late TextEditingController _nomeController;
  late TextEditingController _emailController;
  late TextEditingController _telefoneController;
  late TextEditingController _cpfController;

  // Máscaras
  final _maskTelefone = MaskTextInputFormatter(mask: '(##) #####-####');
  final _maskCPF = MaskTextInputFormatter(mask: '###.###.###-##');

  @override
  void initState() {
    super.initState();

    final bool isEdicao = widget.hospedeParaEdicao != null;

    String inicialNome = widget.hospedeParaEdicao?.nome ?? "";
    String inicialEmail = widget.hospedeParaEdicao?.email ?? "";
    String inicialTelefone = widget.hospedeParaEdicao?.telefone ?? "";
    String inicialCPF = widget.hospedeParaEdicao?.cpf ?? "";

    _nomeController = TextEditingController(text: inicialNome);
    _emailController = TextEditingController(text: inicialEmail);

    _cpfController = TextEditingController(
        text: isEdicao ? _maskCPF.maskText(inicialCPF) : ""
    );

    _telefoneController = TextEditingController(
        text: isEdicao ? _maskTelefone.maskText(inicialTelefone) : ""
    );

    if (isEdicao) {
      _maskCPF.formatEditUpdate(
          TextEditingValue.empty,
          TextEditingValue(text: _maskCPF.maskText(inicialCPF))
      );
      _maskTelefone.formatEditUpdate(
          TextEditingValue.empty,
          TextEditingValue(text: _maskTelefone.maskText(inicialTelefone))
      );
    }
  }

  void _salvar() async {
    if (_formKey.currentState!.validate()) {
      final hospede = Hospede(
        id: widget.hospedeParaEdicao?.id,
        uuid: widget.hospedeParaEdicao?.uuid,
        nome: _nomeController.text.trim(),
        email: _emailController.text.trim(),
        telefone: _maskTelefone.getUnmaskedText(),
        cpf: _maskCPF.getUnmaskedText(),
      );

      try {
        if (widget.hospedeParaEdicao == null) {
          await HospedeDAO().insertHospede(hospede);
        } else {
          await HospedeDAO().updateHospede(hospede);
        }

        if (mounted) Navigator.pop(context, true);
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
              content: Text(e.toString().replaceAll('Exception: ', '')),
              backgroundColor: Colors.red
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {

    final bool isEdicao = widget.hospedeParaEdicao != null;

    return Scaffold(
      appBar: AppBar(
          title: Text(isEdicao ? "Editar Hóspede" : "Novo Hóspede"),
          backgroundColor: Colors.blueGrey
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Form(
          key: _formKey,
          child: Column(
            children: [
              Icon(isEdicao ? Icons.edit_note : Icons.person_add_alt_1, size: 80, color: Colors.blueGrey),
              const SizedBox(height: 20),
              TextFormField(
                controller: _nomeController,
                decoration: const InputDecoration(labelText: 'Nome Completo', border: OutlineInputBorder()),
                validator: (v) => (v == null || v.isEmpty) ? 'Informe o nome' : null,
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _cpfController,
                inputFormatters: [_maskCPF],
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(labelText: 'CPF', border: OutlineInputBorder()),
                validator: (v) => (_maskCPF.getUnmaskedText().length < 11) ? 'CPF incompleto' : null,
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _emailController,
                keyboardType: TextInputType.emailAddress,
                decoration: const InputDecoration(labelText: 'E-mail', border: OutlineInputBorder()),
                validator: (v) => (v == null || !v.contains('@')) ? 'E-mail inválido' : null,
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _telefoneController,
                inputFormatters: [_maskTelefone],
                keyboardType: TextInputType.phone,
                decoration: const InputDecoration(labelText: 'Telefone', border: OutlineInputBorder()),
                validator: (v) => (_maskTelefone.getUnmaskedText().length < 10) ? 'Telefone incompleto' : null,
              ),
              const SizedBox(height: 32),
              SizedBox(
                width: double.infinity,
                height: 50,
                child: ElevatedButton(
                    onPressed: _salvar,
                    child: Text(isEdicao ? "Salvar Alterações" : "Salvar Registro")
                ),
              )
            ],
          ),
        ),
      ),
    );
  }
}