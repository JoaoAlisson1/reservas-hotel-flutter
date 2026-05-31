import 'package:flutter/material.dart';
import 'package:mask_text_input_formatter/mask_text_input_formatter.dart';
import '../core/dao/funcionarioDAO.dart';
import '../core/models/funcionario.dart';
import '../core/authentication/auth_service.dart';
import 'funcionario_register_screen.dart';

class FuncionarioListScreen extends StatefulWidget {
  const FuncionarioListScreen({super.key});

  @override
  State<FuncionarioListScreen> createState() => _FuncionarioListScreenState();
}

class _FuncionarioListScreenState extends State<FuncionarioListScreen> {
  final FuncionarioDAO _dao = FuncionarioDAO();
  List<Funcionario> _funcionarios = [];
  bool _isLoading = true;

  List<Funcionario> _funcionariosFiltrados = [];
  final TextEditingController _searchController = TextEditingController();
  bool _isSearchOpen = false;

  // Máscara para formatar a exibição do telefone na lista
  final _maskFormatter = MaskTextInputFormatter(
    mask: '(##) #####-####',
    filter: {"#": RegExp(r'[0-9]')},
  );

  @override
  void initState() {
    super.initState();
    _carregarFuncionarios();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _carregarFuncionarios() async {
    setState(() => _isLoading = true);
    try {
      final dados = await _dao.findAll();
      setState(() {
        _funcionarios = dados;
        _funcionariosFiltrados = dados;
      });
    } finally {
      setState(() => _isLoading = false);
    }
  }

  void _filterFuncionarios(String query) {
    setState(() {
      _funcionariosFiltrados = _funcionarios.where((f) {
        final nome = f.nome.toLowerCase();
        final email = f.email.toLowerCase();
        final input = query.toLowerCase();

        return nome.contains(input) || email.contains(input);
      }).toList();
    });
  }

  _editFuncionario(Funcionario f) async {
    final _formKeyEdit = GlobalKey<FormState>();

    final nomeController = TextEditingController(text: f.nome);
    final emailController = TextEditingController(text: f.email);

    final maskFormatterEdit = MaskTextInputFormatter(
      mask: '(##) #####-####',
      filter: {"#": RegExp(r'[0-9]')},
      initialText: f.telefone,
    );

    final telefoneController = TextEditingController(
      text: maskFormatterEdit.maskText(f.telefone),
    );

    await showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Editar Funcionário'),
        content: SingleChildScrollView(
          child: Form(
            key: _formKeyEdit,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextFormField(
                  controller: nomeController,
                  decoration: const InputDecoration(labelText: 'Nome'),
                  validator: (value) => (value == null || value.isEmpty) ? 'Informe o nome' : null,
                ),
                TextFormField(
                  controller: emailController,
                  decoration: const InputDecoration(labelText: 'E-mail'),
                  validator: (value) {
                    if (value == null || !value.contains('@')) return 'E-mail inválido';
                    return null;
                  },
                ),
                TextFormField(
                  controller: telefoneController,
                  inputFormatters: [maskFormatterEdit],
                  keyboardType: TextInputType.phone,
                  decoration: const InputDecoration(
                    labelText: 'Telefone',
                    hintText: '(00) 00000-0000',
                  ),
                  validator: (value) {
                    if (value == null || value.isEmpty) return 'Informe o telefone';
                    if (maskFormatterEdit.getUnmaskedText().length < 10) {
                      return 'Telefone incompleto';
                    }
                    return null;
                  },
                ),
              ],
            ),
          ),
        ),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancelar')
          ),
          ElevatedButton(
            onPressed: () async {
              // Só prossegue se o formulário for válido
              if (_formKeyEdit.currentState!.validate()) {
                final updated = Funcionario(
                  id: f.id,
                  uuid: f.uuid,
                  nome: nomeController.text.trim(),
                  email: emailController.text.trim(),
                  telefone: maskFormatterEdit.getUnmaskedText(),
                );

                try {
                  await _dao.updateFuncionario(updated);
                  _carregarFuncionarios();
                  if (context.mounted) Navigator.pop(context);
                } catch (e) {
                  if (context.mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                          content: Text(e.toString().replaceAll('Exception: ', '')),
                          backgroundColor: Colors.red
                      ),
                    );
                  }
                }
              }
            },
            child: const Text('Salvar'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final bool usuarioLogadoEhAdmin = AuthService().usuarioLogado?.permissao == 'ADMIN';

    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.blueGrey,
        foregroundColor: Colors.white,
        title: _isSearchOpen
            ? TextField(
          controller: _searchController,
          autofocus: true,
          style: const TextStyle(color: Colors.white),
          decoration: const InputDecoration(
            hintText: "Buscar por nome ou e-mail...",
            hintStyle: TextStyle(color: Colors.white70),
            border: InputBorder.none,
          ),
          onChanged: _filterFuncionarios,
        )
            : const Text("Equipe de Funcionários"),
        actions: [
          IconButton(
            icon: Icon(_isSearchOpen ? Icons.close : Icons.search),
            onPressed: () {
              setState(() {
                _isSearchOpen = !_isSearchOpen;
                if (!_isSearchOpen) {
                  _searchController.clear();
                  _funcionariosFiltrados = _funcionarios;
                }
              });
            },
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator(color: Colors.blueGrey))
          : _funcionariosFiltrados.isEmpty
          ? const Center(child: Text("Nenhum funcionário encontrado."))
          : ListView.builder(
        padding: const EdgeInsets.all(8),
        itemCount: _funcionariosFiltrados.length,
        itemBuilder: (context, index) {
          final f = _funcionariosFiltrados[index];
          String telefoneFormatado = _maskFormatter.maskText(f.telefone);

          return Card(
            elevation: 2,
            margin: const EdgeInsets.symmetric(vertical: 4),
            child: ListTile(
              leading: const CircleAvatar(
                backgroundColor: Colors.blueAccent,
                child: Icon(Icons.badge, color: Colors.white),
              ),
              title: Text(f.nome, style: const TextStyle(fontWeight: FontWeight.bold)),
              subtitle: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text("Email: ${f.email}"),
                  Text("Tel: $telefoneFormatado"),
                  Text(
                    "UUID: ${f.uuid}",
                    style: const TextStyle(fontSize: 9, color: Colors.grey, fontStyle: FontStyle.italic),
                  ),
                ],
              ),
              trailing: usuarioLogadoEhAdmin
                  ? PopupMenuButton<String>(
                onSelected: (value) {
                  if (value == 'edit') _editFuncionario(f);
                  if (value == 'delete') _confirmarExclusao(f);
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
              )
                  : null,
            ),
          );
        },
      ),
      floatingActionButton: usuarioLogadoEhAdmin
          ? FloatingActionButton(
        backgroundColor: Colors.blueGrey,
        onPressed: () async {
          final result = await Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => const FuncionarioRegisterScreen()),
          );
          if (result == true) _carregarFuncionarios();
        },
        child: const Icon(Icons.add, color: Colors.white),
      )
          : null,
    );
  }

  void _confirmarExclusao(Funcionario f) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text("Excluir"),
        content: Text("Deseja remover ${f.nome}?"),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text("Cancelar")),
          TextButton(
            onPressed: () async {
              await _dao.delete(f.id!);
              _carregarFuncionarios();
              if (mounted) Navigator.pop(context);
            },
            child: const Text("Excluir", style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }
}