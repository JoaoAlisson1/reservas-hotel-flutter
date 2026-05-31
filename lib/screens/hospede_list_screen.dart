import 'package:flutter/material.dart';
import 'package:mask_text_input_formatter/mask_text_input_formatter.dart';
import '../core/dao/hospedeDAO.dart';
import '../core/models/hospede.dart';
import '../core/authentication/auth_service.dart';
import 'hospede_register_screen.dart';

class HospedeListScreen extends StatefulWidget {
  const HospedeListScreen({super.key});

  @override
  State<HospedeListScreen> createState() => _HospedeListScreenState();
}

class _HospedeListScreenState extends State<HospedeListScreen> {
  final HospedeDAO _dao = HospedeDAO();
  List<Hospede> _hospedes = [];
  bool _isLoading = true;

  List<Hospede> _hospedesFiltrados = [];
  final TextEditingController _searchController = TextEditingController();
  bool _isSearchOpen = false;

  // Máscaras para formatar a exibição e os campos de edição
  final _maskTelefone = MaskTextInputFormatter(mask: '(##) #####-####');
  final _maskCPF = MaskTextInputFormatter(mask: '###.###.###-##');

  @override
  void initState() {
    super.initState();
    _carregarHospedes();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _carregarHospedes() async {
    setState(() => _isLoading = true);
    try {
      final dados = await _dao.findAll();
      setState(() {
        _hospedes = dados;
        _hospedesFiltrados = dados;
      });
    } finally {
      setState(() => _isLoading = false);
    }
  }

  void _filterHospedes(String query) {
    setState(() {
      _hospedesFiltrados = _hospedes.where((h) {
        final nome = h.nome.toLowerCase();
        final cpfLimpo = h.cpf.replaceAll(RegExp(r'[^0-9]'), '');
        final input = query.toLowerCase().replaceAll(RegExp(r'[^0-9a-zA-Z]'), '');

        return nome.contains(query.toLowerCase()) || cpfLimpo.contains(input);
      }).toList();
    });
  }

  _editHospede(Hospede h) async {
    final resultado = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => HospedeRegisterScreen(hospedeParaEdicao: h),
      ),
    );

    if (resultado == true) {
      _carregarHospedes();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Hóspede atualizado com sucesso!"), backgroundColor: Colors.green),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final auth = AuthService();
    final bool podeGerenciar = auth.podeGerenciarOperacoes; // Admin ou Recepcionista

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
            hintText: "Buscar por nome ou CPF...",
            hintStyle: TextStyle(color: Colors.white70),
            border: InputBorder.none,
          ),
          onChanged: _filterHospedes,
        )
            : const Text("Gestão de Hóspedes"),
        actions: [
          IconButton(
            icon: Icon(_isSearchOpen ? Icons.close : Icons.search),
            onPressed: () {
              setState(() {
                _isSearchOpen = !_isSearchOpen;
                if (!_isSearchOpen) {
                  _searchController.clear();
                  _hospedesFiltrados = _hospedes; // Reseta a lista ao fechar a busca
                }
              });
            },
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator(color: Colors.blueGrey))
          : _hospedesFiltrados.isEmpty
          ? const Center(child: Text("Nenhum Hóspede encontrado."))
          : ListView.builder(
        padding: const EdgeInsets.all(8),
        itemCount: _hospedesFiltrados.length,
        itemBuilder: (context, index) {
          final h = _hospedesFiltrados[index];
          return Card(
            elevation: 2,
            margin: const EdgeInsets.symmetric(vertical: 4),
            child: ListTile(
              leading: const CircleAvatar(
                backgroundColor: Colors.blueGrey,
                child: Icon(Icons.person, color: Colors.white),
              ),
              title: Text(h.nome, style: const TextStyle(fontWeight: FontWeight.bold)),
              subtitle: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text("CPF: ${_maskCPF.maskText(h.cpf)}"),
                  Text("Email: ${h.email}"),
                  Text("Tel: ${_maskTelefone.maskText(h.telefone)}"),
                ],
              ),
              trailing: podeGerenciar
                  ? PopupMenuButton<String>(
                onSelected: (val) {
                  if (val == 'edit') _editHospede(h);
                  if (val == 'delete') _confirmarExclusao(h);
                },
                itemBuilder: (context) => [
                  const PopupMenuItem(
                    value: 'edit',
                    child: Row(
                      children: [
                        Icon(Icons.edit, color: Colors.blue, size: 20),
                        SizedBox(width: 10),
                        Text('Editar'),
                      ],
                    ),
                  ),
                  const PopupMenuItem(
                    value: 'delete',
                    child: Row(
                      children: [
                        Icon(Icons.delete, color: Colors.red, size: 20),
                        SizedBox(width: 10),
                        Text('Excluir'),
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
      floatingActionButton: podeGerenciar
          ? FloatingActionButton(
        backgroundColor: Colors.blueGrey,
        onPressed: () async {
          final resultado = await Navigator.push(
            context,
            MaterialPageRoute(builder: (c) => const HospedeRegisterScreen()),
          );

          if (resultado == true) {
            _carregarHospedes();
            if (mounted) {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text("Hóspede cadastrado com sucesso!"),
                  backgroundColor: Colors.green,
                ),
              );
            }
          }
        },
        child: const Icon(Icons.add, color: Colors.white),
      )
          : null,
    );
  }

  void _confirmarExclusao(Hospede h) {
    showDialog(
      context: context,
      builder: (c) => AlertDialog(
        title: const Text("Excluir Hóspede"),
        content: Text("Tem certeza que deseja remover o Hóspede ${h.nome}?"),
        actions: [
          TextButton(onPressed: () => Navigator.pop(c), child: const Text("Cancelar")),
          TextButton(
            onPressed: () async {
              try {

                await _dao.deleteHospede(h.id!);

                if (mounted) Navigator.pop(c);
                _carregarHospedes();

                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text("Hóspede ${h.nome} removido com sucesso!"),
                      backgroundColor: Colors.redAccent,
                    ),
                  );
                }
              } catch (e) {

                if (mounted) Navigator.pop(c);

                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(e.toString().replaceAll('Exception: ', '')),
                      backgroundColor: Colors.orange.shade900,
                      duration: const Duration(seconds: 4),
                    ),
                  );
                }
              }
            },
            child: const Text("Excluir", style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }
}