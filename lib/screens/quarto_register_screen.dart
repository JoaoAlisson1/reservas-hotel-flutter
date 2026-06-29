import 'package:flutter/material.dart';
import 'package:mask_text_input_formatter/mask_text_input_formatter.dart';
import '../core/models/enums/status_quarto.dart';
import '../core/models/enums/tipo_quarto.dart';
import '../core/models/quarto.dart';
import '../service/quarto_service.dart';

class QuartoRegisterScreen extends StatefulWidget {
  const QuartoRegisterScreen({super.key});

  @override
  State<QuartoRegisterScreen> createState() => _QuartoRegisterScreenState();
}

class _QuartoRegisterScreenState extends State<QuartoRegisterScreen> {
  final _formKey = GlobalKey<FormState>();

  final _numeroController = TextEditingController();
  final _diariaController = TextEditingController();

  TipoQuarto _tipoSelecionado = TipoQuarto.Solteiro;
  StatusQuarto _statusSelecionado = StatusQuarto.Disponivel;

  @override
  void dispose() {
    _numeroController.dispose();
    _diariaController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Novo Quarto"), backgroundColor: Colors.blueGrey),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Form(
          key: _formKey,
          child: Column(
            children: [
              const Icon(Icons.bed, size: 80, color: Colors.blueGrey),
              const SizedBox(height: 20),

              TextFormField(
                controller: _numeroController,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(labelText: 'Número do Quarto', border: OutlineInputBorder()),
                validator: (value) => (value == null || value.isEmpty) ? 'Informe o número' : null,
              ),
              const SizedBox(height: 16),

              DropdownButtonFormField<TipoQuarto>(
                value: _tipoSelecionado,
                decoration: const InputDecoration(labelText: 'Tipo de Quarto', border: OutlineInputBorder()),
                items: TipoQuarto.values.map((tipo) => DropdownMenuItem(
                    value: tipo,
                    child: Text(tipo.name)
                )).toList(),
                onChanged: (val) => setState(() => _tipoSelecionado = val!),
              ),
              const SizedBox(height: 16),

              DropdownButtonFormField<StatusQuarto>(
                value: _statusSelecionado,
                decoration: const InputDecoration(labelText: 'Status Inicial', border: OutlineInputBorder()),
                items: StatusQuarto.values.map((status) => DropdownMenuItem(
                    value: status,
                    child: Text(status.name)
                )).toList(),
                onChanged: (val) => setState(() => _statusSelecionado = val!),
              ),
              const SizedBox(height: 16),

              TextFormField(
                controller: _diariaController,
                keyboardType: const TextInputType.numberWithOptions(decimal: true),
                decoration: const InputDecoration(labelText: 'Valor da Diária (R\$)', border: OutlineInputBorder()),
                validator: (value) => (value == null || value.isEmpty) ? 'Informe o valor' : null,
              ),

              const SizedBox(height: 32),

              SizedBox(
                width: double.infinity,
                height: 50,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.blueGrey,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                  ),
                  onPressed: _salvarQuarto,
                  child: const Text(
                    "Cadastrar Quarto",
                    style: TextStyle(fontSize: 18),
                  ),
                ),
              )
            ],
          ),
        ),
      ),
    );
  }

  void _salvarQuarto() async {
    if (_formKey.currentState!.validate()) {
      final novoQuarto = Quarto(
        numero: int.parse(_numeroController.text),
        tipo: _tipoSelecionado,
        status: _statusSelecionado,
        diaria: double.parse(_diariaController.text.replaceAll(',', '.')),
      );

      try {
        await QuartoService().insertQuarto(novoQuarto);

        if (mounted) Navigator.pop(context, true);
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(e.toString().replaceAll('Exception: ', '')),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    }
  }
}