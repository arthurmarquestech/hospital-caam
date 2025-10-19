import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:http/http.dart' as http;
import 'exercicio_tela.dart';
import 'minhas_solicitacoes_screen.dart';

class SolicitacaoScreen extends StatefulWidget {
  final int idUsuario;
  final String nomeUsuario;

  const SolicitacaoScreen({
    super.key,
    required this.idUsuario,
    required this.nomeUsuario,
  });

  @override
  State<SolicitacaoScreen> createState() => _SolicitacaoScreenState();
}

class _SolicitacaoScreenState extends State<SolicitacaoScreen> {
  final _formKey = GlobalKey<FormState>();
  String? _motivoSelecionado;
  String? _destinoSelecionado;
  bool _estaAEnviar = false;

  DateTime? _dataDeSelecionada;

  final Map<String, bool> _tiposSolicitacao = {
    'Alterar horário(s) de atendimento': false,
    'Alterar dia(s) de atendimento': false,
    'Excluir horário(s) de atendimento': false,
    'Excluir dia(s) de atendimento': false,
    'Trocar dia ou horário de atendimento': false,
    'Bloquear dia ou horário de atendimento': false,
  };

  String? _tipoVigencia;
  final Map<String, bool> _periodos = {
    'Manhã': false,
    'Tarde': false,
    'Noite': false,
  };

  final _observacoesController = TextEditingController();
  final _dataDeController = TextEditingController();
  final _dataAteController = TextEditingController();

  final List<String> _destinos = [
    "CLÍNICA A",
    "CLINICA B",
    "CLINICA C",
    "CLINICA D",
    "CLINICA E"
  ];

  @override
  void dispose() {
    _observacoesController.dispose();
    _dataDeController.dispose();
    _dataAteController.dispose();
    super.dispose();
  }

  Future<void> _selecionarData(
      BuildContext context, TextEditingController controller,
      {required bool isDataDe}) async {
    final primeiroDiaPermitido =
        isDataDe ? DateTime.now() : _dataDeSelecionada ?? DateTime.now();

    final DateTime? picked = await showDatePicker(
      context: context,
      locale: const Locale('pt', 'BR'),
      initialDate:
          primeiroDiaPermitido, // O calendário abre no primeiro dia permitido.
      firstDate:
          primeiroDiaPermitido, // Não permite selecionar dias anteriores.
      lastDate: DateTime(2030),
    );

    if (picked != null) {
      setState(() {
        controller.text = DateFormat('dd/MM/yyyy').format(picked);
        if (isDataDe) {
          _dataDeSelecionada = picked;
          if (_dataAteController.text.isNotEmpty) {
            final dataAte =
                DateFormat('dd/MM/yyyy').parse(_dataAteController.text);
            if (dataAte.isBefore(picked)) {
              _dataAteController.clear();
            }
          }
        }
      });
    }
  }

  void _logout() {
    Navigator.pushAndRemoveUntil(
      context,
      MaterialPageRoute(builder: (context) => const LoginScreen()),
      (Route<dynamic> route) => false,
    );
  }

  void _limparFormulario() {
    _formKey.currentState?.reset();
    setState(() {
      _destinoSelecionado = null;
      _motivoSelecionado = null;
      _tipoVigencia = null;
      _tiposSolicitacao.updateAll((key, value) => false);
      _periodos.updateAll((key, value) => false);
      _observacoesController.clear();
      _dataDeController.clear();
      _dataAteController.clear();
      _dataDeSelecionada = null; // Limpa a data guardada
      _estaAEnviar = false;
    });
  }

  Future<void> _enviarSolicitacao() async {
    if (_formKey.currentState!.validate() && !_estaAEnviar) {
      setState(() {
        _estaAEnviar = true;
      });

      final tiposSelecionados = _tiposSolicitacao.entries
          .where((entry) => entry.value)
          .map((entry) => entry.key)
          .toList();

      final periodosSelecionados = _periodos.entries
          .where((entry) => entry.value)
          .map((entry) => entry.key)
          .toList();

      final url = Uri.parse('http://localhost/Backend/enviar_solicitacao.php');
      try {
        final response = await http.post(
          url,
          headers: {'Content-Type': 'application/json'},
          body: json.encode({
            'id_solicitante': widget.idUsuario,
            'destino': _destinoSelecionado,
            'tipos_solicitacao': tiposSelecionados,
            'observacoes': _observacoesController.text,
            'tipo_vigencia': _tipoVigencia,
            'data_de': _dataDeController.text,
            'data_ate': _dataAteController.text,
            'periodos': periodosSelecionados,
            'motivo': _motivoSelecionado,
          }),
        );
        if (!mounted) return;

        final responseData = json.decode(response.body);
        if (responseData['sucesso'] == true) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Solicitação enviada com sucesso!'),
              backgroundColor: Colors.green,
            ),
          );
          _limparFormulario();
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Erro: ${responseData['mensagem']}'),
              backgroundColor: Colors.red,
            ),
          );
        }
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Erro de conexão: $e'),
            backgroundColor: Colors.red,
          ),
        );
      } finally {
        if (mounted) {
          setState(() {
            _estaAEnviar = false;
          });
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'CAAM - Comunicação de Alteração de Agenda Médica',
          style: TextStyle(color: Colors.white, fontSize: 18),
        ),
        backgroundColor: const Color(0xFF1A9DD0),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) =>
                      MinhasSolicitacoesScreen(idUsuario: widget.idUsuario),
                ),
              );
            },
            child: const Text(
              'Minhas Solicitações',
              style: TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          IconButton(
            icon: const Icon(Icons.logout, color: Colors.white),
            tooltip: 'Sair',
            onPressed: _logout,
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(vertical: 24.0, horizontal: 16.0),
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 1200),
            child: Form(
              key: _formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildCard(
                    child: Column(
                      children: [
                        _buildInfoField(
                          label: 'Solicitante',
                          value: widget.nomeUsuario,
                        ),
                        const SizedBox(height: 16),
                        DropdownButtonFormField<String>(
                          value: _destinoSelecionado,
                          decoration: const InputDecoration(
                            labelText: 'Destino',
                            border: OutlineInputBorder(),
                          ),
                          items: _destinos.map((String destino) {
                            return DropdownMenuItem<String>(
                              value: destino,
                              child: Text(destino),
                            );
                          }).toList(),
                          onChanged: (String? newValue) {
                            setState(() {
                              _destinoSelecionado = newValue;
                            });
                          },
                          validator: (value) => value == null || value.isEmpty
                              ? 'Por favor, selecione um destino'
                              : null,
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 20),
                  LayoutBuilder(
                    builder: (context, constraints) {
                      if (constraints.maxWidth > 800) {
                        return Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Expanded(child: _buildTipoSolicitacaoCard()),
                            const SizedBox(width: 20),
                            Expanded(child: _buildPeriodoVigenciaCard()),
                          ],
                        );
                      }
                      return Column(
                        children: [
                          _buildTipoSolicitacaoCard(),
                          const SizedBox(height: 20),
                          _buildPeriodoVigenciaCard(),
                        ],
                      );
                    },
                  ),
                  const SizedBox(height: 30),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: _estaAEnviar ? null : _enviarSolicitacao,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF1A9DD0),
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                      child: _estaAEnviar
                          ? const SizedBox(
                              width: 24,
                              height: 24,
                              child: CircularProgressIndicator(
                                color: Colors.white,
                                strokeWidth: 3,
                              ),
                            )
                          : const Text(
                              'ENVIAR SOLICITAÇÃO',
                              style:
                                  TextStyle(fontSize: 16, color: Colors.white),
                            ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildTipoSolicitacaoCard() {
    return _buildCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'TIPO DE SOLICITAÇÃO',
            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
          ),
          const Divider(),
          ..._tiposSolicitacao.keys.map((String key) {
            return CheckboxListTile(
              title: Text(key),
              value: _tiposSolicitacao[key],
              onChanged: (bool? value) =>
                  setState(() => _tiposSolicitacao[key] = value!),
              controlAffinity: ListTileControlAffinity.leading,
              contentPadding: EdgeInsets.zero,
            );
          }).toList(),
          const SizedBox(height: 16),
          TextFormField(
            controller: _observacoesController,
            decoration: const InputDecoration(
              labelText: 'Observações adicionais sobre a solicitação',
              border: OutlineInputBorder(),
            ),
            maxLines: 3,
          ),
        ],
      ),
    );
  }

  Widget _buildPeriodoVigenciaCard() {
    return _buildCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'PERÍODO PARA ALTERAÇÃO (VIGÊNCIA)',
            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
          ),
          const Divider(),
          Row(
            children: [
              Expanded(
                child: RadioListTile<String>(
                  title: const Text('Temporário'),
                  value: 'Temporário',
                  groupValue: _tipoVigencia,
                  onChanged: (value) => setState(() => _tipoVigencia = value),
                ),
              ),
              Expanded(
                child: RadioListTile<String>(
                  title: const Text('Permanente'),
                  value: 'Permanente',
                  groupValue: _tipoVigencia,
                  onChanged: (value) => setState(() => _tipoVigencia = value),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: _buildDateField(
                  label: 'De:',
                  controller: _dataDeController,
                  // --- ALTERAÇÃO: Informa que este é o campo "De" ---
                  onTap: () => _selecionarData(context, _dataDeController,
                      isDataDe: true),
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: _buildDateField(
                  label: 'Até:',
                  controller: _dataAteController,
                  // --- ALTERAÇÃO: Informa que este é o campo "Até" ---
                  onTap: () => _selecionarData(context, _dataAteController,
                      isDataDe: false),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: _periodos.keys.map((String key) {
              return Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Checkbox(
                    value: _periodos[key],
                    onChanged: (bool? value) =>
                        setState(() => _periodos[key] = value!),
                  ),
                  Text(key),
                ],
              );
            }).toList(),
          ),
          const SizedBox(height: 24),
          DropdownButtonFormField<String>(
            value: _motivoSelecionado,
            decoration: const InputDecoration(
              labelText: 'Motivo da Solicitação',
              border: OutlineInputBorder(),
            ),
            items: [
              'Agenda Cirúrgica',
              'Congresso',
              'Doença',
              'Licença Maternidade',
              'Ociosidade da Agenda',
              'Outro',
              'Recesso',
              'Solicitação do Hospital',
            ].map((String motivo) {
              return DropdownMenuItem<String>(
                value: motivo,
                child: Text(motivo),
              );
            }).toList(),
            onChanged: (String? newValue) =>
                setState(() => _motivoSelecionado = newValue),
            validator: (value) => value == null ? 'Campo obrigatório' : null,
          ),
        ],
      ),
    );
  }

  // --- WIDGET _buildDateField ATUALIZADO ---
  Widget _buildDateField({
    required String label,
    required TextEditingController controller,
    required VoidCallback onTap, // Usa um callback para a ação de toque
  }) {
    return TextFormField(
      controller: controller,
      readOnly: true, // O campo continua a ser apenas de leitura
      decoration: InputDecoration(
        labelText: label,
        border: const OutlineInputBorder(),
        suffixIcon: IconButton(
          icon: const Icon(Icons.calendar_today),
          onPressed: onTap, // O ícone também chama o callback
        ),
      ),
      onTap: onTap, // O campo inteiro chama o callback
    );
  }

  Widget _buildCard({required Widget child}) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(8.0),
        side: BorderSide(color: Colors.grey.shade300),
      ),
      child: Padding(padding: const EdgeInsets.all(16.0), child: child),
    );
  }

  Widget _buildInfoField({required String label, required String value}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: const TextStyle(color: Colors.grey, fontSize: 12)),
        const SizedBox(height: 4),
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: Colors.grey[200],
            borderRadius: BorderRadius.circular(4),
          ),
          child: Text(value, style: const TextStyle(fontSize: 16)),
        ),
      ],
    );
  }
}
