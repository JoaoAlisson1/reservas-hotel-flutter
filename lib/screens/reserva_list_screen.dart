import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../core/dao/reservaDAO.dart';
import '../core/models/reserva.dart';
import '../core/models/enums/status_reserva.dart';
import '../core/authentication/auth_service.dart';
import 'reserva_register_screen.dart';

class ReservaListScreen extends StatefulWidget {
  const ReservaListScreen({super.key});

  @override
  State<ReservaListScreen> createState() => _ReservaListScreenState();
}

class _ReservaListScreenState extends State<ReservaListScreen> {
  final ReservaDAO _dao = ReservaDAO();
  final _df = DateFormat('dd/MM/yyyy');

  List<Reserva> _reservas = [];
  List<Reserva> _reservasFiltradas = [];

  bool _isLoading = true;
  bool _isSearching = false;
  final TextEditingController _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _carregarReservas();
  }

  Future<void> _carregarReservas() async {
    setState(() => _isLoading = true);
    try {
      final dados = await _dao.findAll();
      setState(() {
        _reservas = dados;
        _reservasFiltradas = dados;
      });
    } finally {
      setState(() => _isLoading = false);
    }
  }

  void _filtrarReservas(String query) {
    setState(() {
      _reservasFiltradas = _reservas.where((r) {
        final nomeHospede = r.nomeHospedePrincipal?.toLowerCase() ?? "";
        final numeroQuarto = r.numeroQuarto.toString();
        final input = query.toLowerCase();

        return nomeHospede.contains(input) || numeroQuarto.contains(input);
      }).toList();
    });
  }

  Color _getStatusColor(StatusReserva status) {
    switch (status) {
      case StatusReserva.Reservada: return Colors.orange;
      case StatusReserva.Check_in: return Colors.green;
      case StatusReserva.Check_out: return Colors.blueGrey;
      case StatusReserva.Cancelada: return Colors.red;
      default: return Colors.grey;
    }
  }

  @override
  Widget build(BuildContext context) {
    final auth = AuthService();
    final bool podeGerenciar = auth.podeGerenciarOperacoes;
    final bool podeExcluir = auth.ehAdmin;

    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.blueGrey,
        foregroundColor: Colors.white,
        title: _isSearching
            ? TextField(
          controller: _searchController,
          autofocus: true,
          style: const TextStyle(color: Colors.white),
          decoration: const InputDecoration(
            hintText: "Buscar hóspede ou quarto...",
            hintStyle: TextStyle(color: Colors.white70),
            border: InputBorder.none,
          ),
          onChanged: _filtrarReservas,
        )
            : const Text("Gestão de Reservas"),
        actions: [
          IconButton(
            icon: Icon(_isSearching ? Icons.close : Icons.search),
            onPressed: () {
              setState(() {
                if (_isSearching) {
                  _isSearching = false;
                  _searchController.clear();
                  _filtrarReservas("");
                } else {
                  _isSearching = true;
                }
              });
            },
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator(color: Colors.blueGrey))
          : _reservasFiltradas.isEmpty
          ? const Center(child: Text("Nenhuma reserva encontrada."))
          : ListView.builder(
        padding: const EdgeInsets.all(8),
        itemCount: _reservasFiltradas.length,
        itemBuilder: (context, index) {
          final r = _reservasFiltradas[index];
          return Card(
            elevation: 2,
            margin: const EdgeInsets.symmetric(vertical: 4),
            child: InkWell(
              borderRadius: BorderRadius.circular(8),
              onTap: () => _mostrarDetalhesReserva(r),
              child: ListTile(
                leading: CircleAvatar(
                  backgroundColor: _getStatusColor(r.status).withOpacity(0.2),
                  child: Icon(Icons.event_available, color: _getStatusColor(r.status)),
                ),
                title: Text(
                  r.nomeHospedePrincipal ?? "Hóspede não identificado",
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
                subtitle: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text("Quarto: ${r.numeroQuarto} • Total: R\$ ${r.valorTotal.toStringAsFixed(2)}"),
                    Text(
                      "${_df.format(r.checkIn)} até ${_df.format(r.checkOut)}",
                      style: const TextStyle(fontSize: 12),
                    ),
                    const SizedBox(height: 4),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                      decoration: BoxDecoration(
                        color: _getStatusColor(r.status),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        r.status.name.replaceAll('_', ' '),
                        style: const TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold),
                      ),
                    ),
                  ],
                ),
                trailing: (podeGerenciar || podeExcluir)
                    ? PopupMenuButton<String>(
                  onSelected: (val) {
                    if (val == 'edit') _irParaFormulario(reserva: r);
                    if (val == 'delete') _confirmarExclusao(r);
                    if (val == 'checkin') _confirmarAcao(r, "Check-in");
                    if (val == 'checkout') _confirmarAcao(r, "Check-out");
                  },
                  itemBuilder: (context) => [
                    if (podeGerenciar)
                      const PopupMenuItem(
                          value: 'edit',
                          child: Row(children: [Icon(Icons.edit, color: Colors.blue, size: 20), SizedBox(width: 10), Text('Editar')])),
                    if (podeGerenciar && r.status == StatusReserva.Reservada)
                      const PopupMenuItem(
                          value: 'checkin',
                          child: Row(children: [Icon(Icons.login, color: Colors.green, size: 20), SizedBox(width: 10), Text('Fazer Check-in')])),
                    if (podeGerenciar && r.status == StatusReserva.Check_in)
                      const PopupMenuItem(
                          value: 'checkout',
                          child: Row(children: [Icon(Icons.logout, color: Colors.orange, size: 20), SizedBox(width: 10), Text('Fazer Check-out')])),
                    if (podeExcluir)
                      const PopupMenuItem(
                          value: 'delete',
                          child: Row(children: [Icon(Icons.delete, color: Colors.red, size: 20), SizedBox(width: 10), Text('Excluir')])),
                  ],
                )
                    : null,
              ),
            ),
          );
        },
      ),
      floatingActionButton: podeGerenciar
          ? FloatingActionButton(
        backgroundColor: Colors.blueGrey,
        onPressed: () => _irParaFormulario(),
        child: const Icon(Icons.add, color: Colors.white),
      )
          : null,
    );
  }

  void _mostrarDetalhesReserva(Reserva r) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(25)),
      ),
      builder: (context) {
        return Container(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text("Resumo da Reserva",
                      style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.blueGrey)),
                  IconButton(onPressed: () => Navigator.pop(context), icon: const Icon(Icons.close)),
                ],
              ),
              const Divider(),
              const SizedBox(height: 10),
              _itemResumo(Icons.person, "Hóspede Principal", r.nomeHospedePrincipal ?? "Não informado"),
              _itemResumo(Icons.assignment_ind, "Atendente Responsável", r.loginUsuarioResponsavel ?? "Não identificado"),
              _itemResumo(Icons.bed, "Quarto", "Nº ${r.numeroQuarto}"),
              _itemResumo(Icons.calendar_month, "Estadia", "${_df.format(r.checkIn)} — ${_df.format(r.checkOut)}"),
              _itemResumo(Icons.payments, "Valor Total", "R\$ ${r.valorTotal.toStringAsFixed(2)}"),
              const SizedBox(height: 20),
              Center(
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
                  decoration: BoxDecoration(
                    color: _getStatusColor(r.status).withOpacity(0.1),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: _getStatusColor(r.status), width: 1.5),
                  ),
                  child: Text(
                    r.status.name.replaceAll('_', ' ').toUpperCase(),
                    style: TextStyle(color: _getStatusColor(r.status), fontWeight: FontWeight.bold, fontSize: 12),
                  ),
                ),
              ),
              const SizedBox(height: 25),
              if (AuthService().podeGerenciarOperacoes)
                SizedBox(
                  width: double.infinity,
                  height: 50,
                  child: ElevatedButton.icon(
                    onPressed: () {
                      Navigator.pop(context);
                      _irParaFormulario(reserva: r);
                    },
                    icon: const Icon(Icons.edit, color: Colors.white),
                    label: const Text("EDITAR RESERVA", style: TextStyle(color: Colors.white)),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.blueGrey,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                  ),
                ),
            ],
          ),
        );
      },
    );
  }

  Widget _itemResumo(IconData icon, String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 10),
      child: Row(
        children: [
          Icon(icon, size: 22, color: Colors.blueGrey.shade400),
          const SizedBox(width: 16),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(label, style: const TextStyle(fontSize: 12, color: Colors.grey)),
              Text(value, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
            ],
          ),
        ],
      ),
    );
  }

  void _confirmarAcao(Reserva r, String acao) {
    showDialog(
      context: context,
      builder: (c) => AlertDialog(
        title: Text("Confirmar $acao"),
        content: Text("Deseja realizar o $acao para o hóspede ${r.nomeHospedePrincipal}?"),
        actions: [
          TextButton(onPressed: () => Navigator.pop(c), child: const Text("Cancelar")),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: acao == "Check-in" ? Colors.green : Colors.orange),
            onPressed: () async {
              try {
                if (acao == "Check-in") {
                  await _dao.realizarCheckIn(r.id!, r.quartoId);
                } else {
                  await _dao.realizarCheckOut(r.id!, r.quartoId);
                }
                if (mounted) Navigator.pop(c);
                _carregarReservas();
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text("$acao concluído!"), backgroundColor: Colors.green),
                  );
                }
              } catch (e) {
                if (mounted) Navigator.pop(c);
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text("Erro ao processar: $e"), backgroundColor: Colors.red),
                );
              }
            },
            child: const Text("Confirmar", style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  void _irParaFormulario({Reserva? reserva}) async {
    final resultado = await Navigator.push(
      context,
      MaterialPageRoute(builder: (c) => ReservaRegisterScreen(reservaParaEdicao: reserva)),
    );
    if (resultado == true) _carregarReservas();
  }

  void _confirmarExclusao(Reserva r) {
    String mensagemAviso = "Deseja remover a reserva de ${r.nomeHospedePrincipal}?";
    if (r.status == StatusReserva.Check_in) {
      mensagemAviso = "ESTA RESERVA ESTÁ ATIVA.\n\nAo excluir, o quarto ${r.numeroQuarto} será liberado. Continuar?";
    }

    showDialog(
      context: context,
      builder: (c) => AlertDialog(
        title: const Text("Excluir Reserva"),
        content: Text(mensagemAviso),
        actions: [
          TextButton(onPressed: () => Navigator.pop(c), child: const Text("Cancelar")),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red.shade800),
            onPressed: () async {
              try {
                await _dao.deleteReservaManual(r);
                if (mounted) Navigator.pop(c);
                _carregarReservas();
              } catch (e) {
                if (mounted) Navigator.pop(c);
                ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Erro: $e"), backgroundColor: Colors.red));
              }
            },
            child: const Text("Excluir", style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }
}