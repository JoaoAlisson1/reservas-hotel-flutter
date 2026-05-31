import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../core/dao/hospedeDAO.dart';
import '../core/dao/quartoDAO.dart';
import '../core/dao/reservaDAO.dart';
import '../core/models/hospede.dart';
import '../core/models/quarto.dart';
import '../core/models/reserva.dart';
import '../core/models/enums/status_reserva.dart';
import '../core/authentication/auth_service.dart';

class ReservaRegisterScreen extends StatefulWidget {
  final Reserva? reservaParaEdicao;

  const ReservaRegisterScreen({super.key, this.reservaParaEdicao});

  @override
  State<ReservaRegisterScreen> createState() => _ReservaRegisterScreenState();
}

class _ReservaRegisterScreenState extends State<ReservaRegisterScreen> {
  final _formKey = GlobalKey<FormState>();
  final _dao = ReservaDAO();

  List<Quarto> _quartosDisponiveis = [];
  List<Hospede> _todosHospedes = [];

  Quarto? _quartoSelecionado;
  List<Hospede> _hospedesSelecionados = [];
  DateTimeRange? _datasSelecionadas;
  double _valorTotalCalculado = 0.0;
  StatusReserva _status = StatusReserva.Reservada;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _carregarDados();
  }

  Future<void> _carregarDados() async {
    try {
      final hospedes = await HospedeDAO().findAll();
      final quartos = await QuartoDAO().findAll();

      setState(() {
        _todosHospedes = hospedes;
        _quartosDisponiveis = quartos.where((q) =>
        !ReservaDAO.statusBloqueados.contains(q.status)
        ).toList();

        if (widget.reservaParaEdicao != null) {
          final reserva = widget.reservaParaEdicao!;
          _hospedesSelecionados = _todosHospedes
              .where((h) => reserva.hospedesIds.any((id) => id.toString() == h.id.toString()))
              .toList();

          _quartoSelecionado = quartos.firstWhere((q) => q.id == reserva.quartoId);
          if (!_quartosDisponiveis.any((q) => q.id == _quartoSelecionado!.id)) {
            _quartosDisponiveis.add(_quartoSelecionado!);
          }

          _status = reserva.status;
          _datasSelecionadas = DateTimeRange(start: reserva.checkIn, end: reserva.checkOut);
          _valorTotalCalculado = reserva.valorTotal;
        }
        _isLoading = false;
      });
    } catch (e) {
      debugPrint("Erro ao carregar dados: $e");
    }
  }

  void _selecionarHospedes() async {
    await showDialog(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return AlertDialog(
              title: const Text("Selecionar Hóspedes"),
              content: SizedBox(
                width: double.maxFinite,
                child: _todosHospedes.isEmpty
                    ? const Text("Nenhum hóspede cadastrado.")
                    : ListView.builder(
                  shrinkWrap: true,
                  itemCount: _todosHospedes.length,
                  itemBuilder: (context, index) {
                    final hospede = _todosHospedes[index];
                    final isSelected = _hospedesSelecionados.any((h) => h.id == hospede.id);

                    return CheckboxListTile(
                      title: Text(hospede.nome),
                      value: isSelected,
                      onChanged: (bool? value) {
                        setState(() {
                          if (value == true) {
                            _hospedesSelecionados.add(hospede);
                          } else {
                            _hospedesSelecionados.removeWhere((h) => h.id == hospede.id);
                          }
                        });
                        setDialogState(() {});
                      },
                    );
                  },
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text("Concluir"),
                ),
              ],
            );
          },
        );
      },
    );
  }

  void _atualizarCalculo() {
    if (_datasSelecionadas != null && _quartoSelecionado != null) {
      setState(() {
        _valorTotalCalculado = Reserva.calcularValorEstadia(
          _datasSelecionadas!.start,
          _datasSelecionadas!.end,
          _quartoSelecionado!.diaria,
        );
      });
    }
  }

  Future<void> _selecionarDatas() async {
    final DateTimeRange? picked = await showDateRangePicker(
      context: context,
      firstDate: DateTime.now().subtract(const Duration(days: 365)),
      lastDate: DateTime.now().add(const Duration(days: 365)),
      initialDateRange: _datasSelecionadas,
    );

    if (picked != null) {
      setState(() => _datasSelecionadas = picked);
      _atualizarCalculo();
    }
  }

  void _salvar() async {
    if (_formKey.currentState!.validate()) {
      final usuarioLogadoId = AuthService().usuarioLogado?.id;

      if (usuarioLogadoId == null) {
        _mostrarErro("Nenhum usuário logado no sistema.");

        return;
      }

      final reserva = Reserva(
        id: widget.reservaParaEdicao?.id,
        uuid: widget.reservaParaEdicao?.uuid,
        checkIn: _datasSelecionadas!.start,
        checkOut: _datasSelecionadas!.end,
        valorTotal: _valorTotalCalculado,
        status: _status,
        usuarioId: usuarioLogadoId,
        quartoId: _quartoSelecionado!.id!,
        hospedesIds: _hospedesSelecionados.map((h) => h.id!).toList(),
      );

      try {
        if (widget.reservaParaEdicao == null) {
          await _dao.insertReserva(reserva, _quartoSelecionado!);
        } else {
          await _dao.updateReservaManual(reserva, _quartoSelecionado!);
        }
        if (mounted) Navigator.pop(context, true);
      } catch (e) {
        _mostrarErro(e.toString());
      }
    }
  }

  void _mostrarErro(String msg) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
          content: Text(msg.replaceAll('Exception: ', '')),
          backgroundColor: Colors.red
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final df = DateFormat('dd/MM/yyyy');

    if (_isLoading) return const Scaffold(body: Center(child: CircularProgressIndicator()));

    return Scaffold(
      appBar: AppBar(
        title: Text(widget.reservaParaEdicao == null ? "Nova Reserva" : "Editar Reserva"),
        backgroundColor: Colors.blueGrey,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text("Informações da Estadia",
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.blueGrey)),
              const Divider(),
              const SizedBox(height: 15),

              InkWell(
                onTap: _selecionarHospedes,
                child: InputDecorator(
                  decoration: const InputDecoration(
                    labelText: "Hóspedes",
                    border: OutlineInputBorder(),
                    prefixIcon: Icon(Icons.group),
                  ),
                  child: Text(
                    _hospedesSelecionados.isEmpty
                        ? "Clique para selecionar hóspedes"
                        : _hospedesSelecionados.map((h) => h.nome).join(", "),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                        color: _hospedesSelecionados.isEmpty ? Colors.grey[600] : Colors.black
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 20),

              DropdownButtonFormField<Quarto>(
                value: _quartoSelecionado,
                isExpanded: true,
                decoration: const InputDecoration(
                  labelText: "Quarto",
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.bed),
                ),
                items: _quartosDisponiveis.map((q) => DropdownMenuItem(
                  value: q,
                  child: Text("Quarto ${q.numero} (${q.tipo.name})"),
                )).toList(),
                onChanged: (val) {
                  setState(() => _quartoSelecionado = val);
                  _atualizarCalculo();
                },
                validator: (val) => val == null ? "Selecione um quarto" : null,
              ),
              const SizedBox(height: 20),

              // Seletor de Datas
              InkWell(
                onTap: _selecionarDatas,
                child: InputDecorator(
                  decoration: const InputDecoration(
                    labelText: "Período",
                    border: OutlineInputBorder(),
                    prefixIcon: Icon(Icons.calendar_month),
                  ),
                  child: Text(_datasSelecionadas == null
                      ? "Selecionar Check-in e Check-out"
                      : "${df.format(_datasSelecionadas!.start)} - ${df.format(_datasSelecionadas!.end)}"),
                ),
              ),
              const SizedBox(height: 30),

              // Widget de Resumo
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: Colors.blueGrey.withOpacity(0.05),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.blueGrey.withOpacity(0.2)),
                ),
                child: Column(
                  children: [
                    const Text("RESUMO DA RESERVA",
                        style: TextStyle(fontWeight: FontWeight.bold, letterSpacing: 1.1)),
                    const SizedBox(height: 15),

                    // Mostra o número do quarto e o valor da diária
                    if (_quartoSelecionado != null)
                      _resumoLinha("Quarto selecionado:", "Nº ${_quartoSelecionado!.numero} (${_quartoSelecionado!.tipo.name})"),

                    if (_quartoSelecionado != null)
                      _resumoLinha("Valor da diária:", "R\$ ${_quartoSelecionado!.diaria.toStringAsFixed(2)}"),

                    const Divider(),

                    _resumoLinha("Total de Hóspedes:", "${_hospedesSelecionados.length}"),

                    // mostra as datas separadas e as diárias
                    if (_datasSelecionadas != null) ...[
                      _resumoLinha("Data de Entrada:", df.format(_datasSelecionadas!.start)),
                      _resumoLinha("Data de Saída:", df.format(_datasSelecionadas!.end)),
                      _resumoLinha("Total de Diárias:",
                          "${_datasSelecionadas!.duration.inDays == 0 ? 1 : _datasSelecionadas!.duration.inDays}x"),
                    ],

                    const Divider(height: 30),

                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text("VALOR TOTAL:", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                        Text("R\$ ${_valorTotalCalculado.toStringAsFixed(2)}",
                            style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: Colors.green)),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 30),

              SizedBox(
                width: double.infinity,
                height: 55,
                child: ElevatedButton(
                  onPressed: _salvar,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.blueGrey,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                  ),
                  child: const Text("Confirmar Reserva",
                      style: TextStyle(fontSize: 16, color: Colors.white)),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _resumoLinha(String label, String valor) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label),
          Text(valor, style: const TextStyle(fontWeight: FontWeight.w500))
        ],
      ),
    );
  }
}