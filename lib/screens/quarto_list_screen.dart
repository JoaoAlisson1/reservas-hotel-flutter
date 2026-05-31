import 'package:flutter/material.dart';
import '../core/dao/quartoDAO.dart';
import '../core/models/enums/status_quarto.dart';
import '../core/models/enums/tipo_quarto.dart';
import '../core/models/quarto.dart';
import '../core/authentication/auth_service.dart';
import 'quarto_register_screen.dart';

class QuartoListScreen extends StatefulWidget {
  const QuartoListScreen({super.key});

  @override
  State<QuartoListScreen> createState() => _QuartoListScreenState();
}

class _QuartoListScreenState extends State<QuartoListScreen> {
  final QuartoDAO _dao = QuartoDAO();
  List<Quarto> _quartos = [];
  bool _isLoading = true;

  List<Quarto> _quartosFiltrados = [];
  final TextEditingController _searchController = TextEditingController();
  bool _isSearchOpen = false;

  @override
  void initState() {
    super.initState();
    _carregarQuartos();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _carregarQuartos() async {
    setState(() => _isLoading = true);
    try {
      final dados = await _dao.findAll();
      setState(() {
        _quartos = dados;
        _quartosFiltrados = dados; // Inicializa a lista filtrada com todos os dados
      });
    } finally {
      setState(() => _isLoading = false);
    }
  }

  void _filterQuartos(String query) {
    setState(() {
      _quartosFiltrados = _quartos.where((q) {
        final numero = q.numero.toString();
        final tipo = q.tipo.name.toLowerCase();
        final status = q.status.name.toLowerCase();
        final input = query.toLowerCase();

        return numero.contains(input) ||
            tipo.contains(input) ||
            status.contains(input);
      }).toList();
    });
  }

  _editQuarto(Quarto q) async {
    final _formKeyEdit = GlobalKey<FormState>();
    final numeroController = TextEditingController(text: q.numero.toString());
    final diariaController = TextEditingController(text: q.diaria.toStringAsFixed(2));

    TipoQuarto tipoEditado = q.tipo;
    StatusQuarto statusEditado = q.status;
    String? mensagemErro;

    await showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          title: const Text('Editar Quarto'),
          content: SingleChildScrollView(
            child: Form(
              key: _formKeyEdit,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  if (mensagemErro != null)
                    Container(
                      padding: const EdgeInsets.all(8),
                      margin: const EdgeInsets.only(bottom: 16),
                      decoration: BoxDecoration(
                        color: Colors.red.shade50,
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: Colors.red.shade200),
                      ),
                      child: Row(
                        children: [
                          const Icon(Icons.error_outline, color: Colors.red, size: 20),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              mensagemErro!,
                              style: const TextStyle(color: Colors.red, fontSize: 13, fontWeight: FontWeight.bold),
                            ),
                          ),
                        ],
                      ),
                    ),

                  TextFormField(
                    controller: numeroController,
                    keyboardType: TextInputType.number,
                    decoration: const InputDecoration(labelText: 'Número', border: OutlineInputBorder()),
                    validator: (v) => (v == null || v.isEmpty) ? 'Informe o número' : null,
                  ),
                  const SizedBox(height: 16),
                  DropdownButtonFormField<TipoQuarto>(
                    value: tipoEditado,
                    items: TipoQuarto.values.map((t) => DropdownMenuItem(value: t, child: Text(t.name))).toList(),
                    onChanged: (val) => setDialogState(() => tipoEditado = val!),
                    decoration: const InputDecoration(labelText: 'Tipo', border: OutlineInputBorder()),
                  ),
                  const SizedBox(height: 16),
                  DropdownButtonFormField<StatusQuarto>(
                    value: statusEditado,
                    items: StatusQuarto.values.map((s) => DropdownMenuItem(value: s, child: Text(s.name))).toList(),
                    onChanged: (val) => setDialogState(() => statusEditado = val!),
                    decoration: const InputDecoration(labelText: 'Status', border: OutlineInputBorder()),
                  ),
                  const SizedBox(height: 16),
                  TextFormField(
                    controller: diariaController,
                    keyboardType: const TextInputType.numberWithOptions(decimal: true),
                    decoration: const InputDecoration(labelText: 'Diária (R\$)', border: OutlineInputBorder()),
                    validator: (v) => (v == null || v.isEmpty) ? 'Informe a diária' : null,
                  ),
                ],
              ),
            ),
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancelar')),
            ElevatedButton(
              style: ElevatedButton.styleFrom(backgroundColor: Colors.blueGrey, foregroundColor: Colors.white),
              onPressed: () async {
                if (_formKeyEdit.currentState!.validate()) {
                  final updated = Quarto(
                    id: q.id,
                    uuid: q.uuid,
                    numero: int.parse(numeroController.text),
                    tipo: tipoEditado,
                    status: statusEditado,
                    diaria: double.parse(diariaController.text.replaceAll(',', '.')),
                  );

                  try {
                    await _dao.updateQuarto(updated);
                    _carregarQuartos();
                    if (context.mounted) {
                      Navigator.pop(context);
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text("Quarto atualizado!"), backgroundColor: Colors.green),
                      );
                    }
                  } catch (e) {
                    setDialogState(() {
                      mensagemErro = e.toString().replaceAll('Exception: ', '');
                    });
                  }
                }
              },
              child: const Text('Salvar'),
            ),
          ],
        ),
      ),
    );
  }

  Color _getStatusColor(StatusQuarto status) {
    switch (status) {
      case StatusQuarto.Disponivel: return Colors.green;
      case StatusQuarto.Ocupado: return Colors.red;
      case StatusQuarto.Reservado: return Colors.orange;
      case StatusQuarto.Manutencao: return Colors.blueGrey;
      case StatusQuarto.Limpeza: return Colors.blue;
      case StatusQuarto.Indisponivel: return Colors.grey;
    }
  }

  @override
  Widget build(BuildContext context) {
    final auth = AuthService();
    final bool podeEditar = auth.podeGerenciarOperacoes; // Admin ou Recepcionista
    final bool podeExcluir = auth.ehAdmin; // Apenas Admin

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
            hintText: "Buscar quarto por número ou tipo...",
            hintStyle: TextStyle(color: Colors.white70),
            border: InputBorder.none,
          ),
          onChanged: _filterQuartos,
        )
            : const Text("Gestão de Quartos"),
        actions: [
          IconButton(
            icon: Icon(_isSearchOpen ? Icons.close : Icons.search),
            onPressed: () {
              setState(() {
                _isSearchOpen = !_isSearchOpen;
                if (!_isSearchOpen) {
                  _searchController.clear();
                  _quartosFiltrados = _quartos;
                }
              });
            },
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator(color: Colors.blueGrey))
          : _quartosFiltrados.isEmpty
          ? const Center(child: Text("Nenhum quarto encontrado."))
          : ListView.builder(
        padding: const EdgeInsets.all(8),
        itemCount: _quartosFiltrados.length,
        itemBuilder: (context, index) {
          final q = _quartosFiltrados[index];
          return Card(
            elevation: 2,
            margin: const EdgeInsets.symmetric(vertical: 4),
            child: ListTile(
              leading: CircleAvatar(
                backgroundColor: _getStatusColor(q.status).withOpacity(0.2),
                child: Icon(Icons.bed, color: _getStatusColor(q.status)),
              ),
              title: Text("Quarto ${q.numero}", style: const TextStyle(fontWeight: FontWeight.bold)),
              subtitle: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text("${q.tipo.name} • R\$ ${q.diaria.toStringAsFixed(2)}"),
                  Text(
                    q.status.name,
                    style: TextStyle(color: _getStatusColor(q.status), fontWeight: FontWeight.bold, fontSize: 12),
                  ),
                ],
              ),
              trailing: (podeEditar || podeExcluir)
                  ? PopupMenuButton<String>(
                onSelected: (val) {
                  if (val == 'edit') _editQuarto(q);
                  if (val == 'delete') _confirmarExclusao(q);
                },
                itemBuilder: (context) => [
                  if (podeEditar)
                    const PopupMenuItem(value: 'edit', child: Row(children: [Icon(Icons.edit, color: Colors.blue, size: 20), SizedBox(width: 10), Text('Editar')])),
                  if (podeExcluir)
                    const PopupMenuItem(value: 'delete', child: Row(children: [Icon(Icons.delete, color: Colors.red, size: 20), SizedBox(width: 10), Text('Excluir')])),
                ],
              )
                  : null,
            ),
          );
        },
      ),
      floatingActionButton: podeEditar
          ? FloatingActionButton(
        backgroundColor: Colors.blueGrey,
        onPressed: () async {
          final resultado = await Navigator.push(
            context,
            MaterialPageRoute(builder: (c) => const QuartoRegisterScreen()),
          );

          if (resultado == true) {
            _carregarQuartos();

            if (mounted) {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text("Quarto cadastrado com sucesso!"),
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

  void _confirmarExclusao(Quarto q) {
    showDialog(
      context: context,
      builder: (c) => AlertDialog(
        title: const Text("Excluir Quarto"),
        content: Text("Tem certeza que deseja remover o Quarto ${q.numero}?"),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(c),
              child: const Text("Cancelar")
          ),
          TextButton(
            onPressed: () async {
              try {
                await _dao.deleteQuarto(q.id!);
                if (mounted) Navigator.pop(c);
                _carregarQuartos();

                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text("Quarto ${q.numero} removido com sucesso!"),
                      backgroundColor: Colors.redAccent,
                      duration: const Duration(seconds: 2),
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
                      action: SnackBarAction(
                        label: "OK",
                        textColor: Colors.white,
                        onPressed: () {},
                      ),
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