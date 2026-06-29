import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../core/models/hospede.dart';
import '../core/models/quarto.dart';
import '../core/models/reserva.dart';
import '../core/models/enums/status_reserva.dart';
import '../core/authentication/auth_service.dart';
import '../service/hospede_service.dart';
import '../service/quarto_service.dart';
import '../service/reserva_service.dart';

class ReservaRegisterScreen extends StatefulWidget {
  final Reserva? reservaParaEdicao;

  const ReservaRegisterScreen({super.key, this.reservaParaEdicao});

  @override
  State<ReservaRegisterScreen> createState() => _ReservaRegisterScreenState();
}

class _ReservaRegisterScreenState extends State<ReservaRegisterScreen> {
  final _formKey = GlobalKey<FormState>();
  final ReservaService _reservaService = ReservaService();
  final QuartoService _quartoService = QuartoService();
  final HospedeService _hospedeService = HospedeService();

  List<Quarto> _quartosDisponiveis = [];
  List<Hospede> _todosHospedes = [];

  Quarto? _quartoSelecionado;
  List<Hospede> _hospedesSelecionados = [];
  DateTimeRange? _datasSelecionadas;
  double _valorTotalCalculado = 0.0;
  StatusReserva _status = StatusReserva.Reservada;

  bool _isLoading = true;
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    _carregarDados();
  }

  Future<void> _carregarDados() async {
    try {
      final hospedes = await _hospedeService.getHospedes();
      final quartos = await _quartoService.getQuartos();

      if (!mounted) return;

      setState(() {
        _todosHospedes = hospedes;
        _quartosDisponiveis = quartos.where((q) => q.status.name == 'Disponivel').toList();

        if (widget.reservaParaEdicao != null) {
          final reserva = widget.reservaParaEdicao!;

          _hospedesSelecionados = _todosHospedes
              .where((h) => reserva.hospedesIds.any((id) => id.toString() == h.id.toString()))
              .toList();

          try {
            _quartoSelecionado = quartos.firstWhere((q) => q.id == reserva.quartoId);
            if (!_quartosDisponiveis.any((q) => q.id == _quartoSelecionado!.id)) {
              _quartosDisponiveis.add(_quartoSelecionado!);
            }
          } catch (_) {
            debugPrint("Quarto da reserva de edição não encontrado localmente.");
          }

          _status = reserva.status;
          _datasSelecionadas = DateTimeRange(start: reserva.checkIn, end: reserva.checkOut);
          _valorTotalCalculado = reserva.valorTotal;
        }
        _isLoading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() => _isLoading = false);
      _mostrarErro("Falha ao sincronizar dados com o servidor: $e");
    }
  }

  void _selecionarHospedes() async {
    if (_isSaving) return;
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
                    ? const Text("Nenhum hóspede cadastrado no servidor.")
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
    if (_isSaving) return;
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
    if (_hospedesSelecionados.isEmpty) {
      _mostrarErro("Selecione ao menos um hóspede.");
      return;
    }
    if (_datasSelecionadas == null) {
      _mostrarErro("Selecione o período de check-in e check-out.");
      return;
    }

    if (_formKey.currentState!.validate()) {
      final usuarioLogadoId = AuthService().usuarioLogado?.id;

      if (usuarioLogadoId == null) {
        _mostrarErro("Sessão expirada. Faça login novamente.");
        return;
      }

      setState(() => _isSaving = true);

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
          await _reservaService.insertReserva(reserva);
        } else {
          await _reservaService.updateReserva(reserva);
        }

        if (!mounted) return;
        Navigator.pop(context, true);
      } catch (e) {
        if (!mounted) return;
        _mostrarErro(e.toString());
      } finally {
        if (mounted) {
          setState(() => _isSaving = false);
        }
      }
    }
  }

  void _mostrarErro(String msg) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(msg.replaceAll('Exception: ', '')),
        backgroundColor: Colors.red,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final df = DateFormat('dd/MM/yyyy');

    if (_isLoading) return const Scaffold(body: Center(child: CircularProgressIndicator(color: Colors.blueGrey)));

    return Scaffold(
      appBar: AppBar(
        title: Text(widget.reservaParaEdicao == null ? "Nova Reserva" : "Editar Reserva"),
        backgroundColor: Colors.blueGrey,
        foregroundColor: Colors.white,
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
                onTap: _isSaving ? null : _selecionarHospedes,
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
                onChanged: _isSaving ? null : (val) {
                  setState(() => _quartoSelecionado = val);
                  _atualizarCalculo();
                },
                validator: (val) => val == null ? "Selecione um quarto" : null,
              ),
              const SizedBox(height: 20),
              InkWell(
                onTap: _isSaving ? null : _selecionarDatas,
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

                    if (_quartoSelecionado != null)
                      _resumoLinha("Quarto selecionado:", "Nº ${_quartoSelecionado!.numero} (${_quartoSelecionado!.tipo.name})"),

                    if (_quartoSelecionado != null)
                      _resumoLinha("Valor da diária:", "R\$ ${_quartoSelecionado!.diaria.toStringAsFixed(2)}"),

                    const Divider(),

                    _resumoLinha("Total de Hóspedes:", "${_hospedesSelecionados.length}"),

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
                  onPressed: _isSaving ? null : _salvar,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.blueGrey,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                  ),
                  child: _isSaving
                      ? const SizedBox(
                    width: 24,
                    height: 24,
                    child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
                  )
                      : const Text("Confirmar Reserva",
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