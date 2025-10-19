import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:intl/intl.dart';
import 'exercicio_tela.dart';

class GestorScreen extends StatefulWidget {
  final String nomeUsuario;

  const GestorScreen({
    super.key,
    required this.nomeUsuario,
  });

  @override
  State<GestorScreen> createState() => _GestorScreenState();
}

class _GestorScreenState extends State<GestorScreen> {
  Future<List<dynamic>>? _futureSolicitacoes;

  @override
  void initState() {
    super.initState();
    _carregarSolicitacoes();
  }

  void _carregarSolicitacoes() {
    setState(() {
      _futureSolicitacoes = _buscarSolicitacoes();
    });
  }

  Future<List<dynamic>> _buscarSolicitacoes() async {
    final url = Uri.parse('http://localhost/Backend/buscar_solicitacoes.php');
    try {
      final response = await http.get(url);
      if (response.statusCode == 200) {
        final responseData = json.decode(response.body);
        if (responseData['sucesso'] == true) {
          return responseData['dados'];
        } else {
          throw Exception(
              'Falha ao carregar dados: ${responseData['mensagem']}');
        }
      } else {
        throw Exception('Falha no servidor (Código: ${response.statusCode})');
      }
    } catch (e) {
      throw Exception('Erro de conexão: $e');
    }
  }

  Future<void> _atualizarStatus(int id, String status) async {
    final url =
        Uri.parse('http://localhost/Backend/atualizar_status_solicitacao.php');
    try {
      final response = await http.post(
        url,
        headers: {'Content-Type': 'application/json'},
        body: json.encode({'id': id, 'status': status}),
      );

      if (mounted && response.statusCode == 200) {
        final responseData = json.decode(response.body);
        if (responseData['sucesso'] == true) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Solicitação ${status.toLowerCase()} com sucesso!'),
              backgroundColor: Colors.green,
            ),
          );
          _carregarSolicitacoes(); // Recarrega a lista
        } else {
          throw Exception(responseData['mensagem']);
        }
      } else {
        throw Exception(
            'Falha ao comunicar com o servidor (Código: ${response.statusCode})');
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Erro ao atualizar: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  void _logout() {
    Navigator.pushAndRemoveUntil(
      context,
      MaterialPageRoute(builder: (context) => const LoginScreen()),
      (Route<dynamic> route) => false,
    );
  }

  String _formatarData(String? dataString, {bool apenasData = false}) {
    if (dataString == null || dataString.isEmpty) return 'N/A';
    try {
      final data = DateTime.parse(dataString);
      if (apenasData) return DateFormat('dd/MM/yyyy').format(data);
      return DateFormat('dd/MM/yyyy HH:mm').format(data);
    } catch (e) {
      return dataString;
    }
  }

  Color _getStatusColor(String status) {
    switch (status) {
      case 'Aprovado':
        return Colors.green.shade700;
      case 'Pendente':
        return Colors.orange.shade700;
      case 'Recusado':
        return Colors.red.shade700;
      default:
        return Colors.grey.shade700;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          'Painel do Gestor - ${widget.nomeUsuario}',
          style: const TextStyle(color: Colors.white, fontSize: 18),
        ),
        backgroundColor: const Color(0xFF1A9DD0),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh, color: Colors.white),
            tooltip: 'Recarregar',
            onPressed: _carregarSolicitacoes,
          ),
          IconButton(
            icon: const Icon(Icons.logout, color: Colors.white),
            tooltip: 'Sair',
            onPressed: _logout,
          ),
        ],
      ),
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 1200),
          child: FutureBuilder<List<dynamic>>(
            future: _futureSolicitacoes,
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const Center(child: CircularProgressIndicator());
              } else if (snapshot.hasError) {
                return Center(child: Text('${snapshot.error}'));
              } else if (!snapshot.hasData || snapshot.data!.isEmpty) {
                return const Center(
                  child: Text(
                    'Nenhuma solicitação encontrada.',
                    style: TextStyle(fontSize: 18, color: Colors.grey),
                  ),
                );
              }

              final solicitacoes = snapshot.data!;
              return ListView.builder(
                padding: const EdgeInsets.all(16.0),
                itemCount: solicitacoes.length,
                itemBuilder: (context, index) {
                  final solicitacao = solicitacoes[index];
                  final bool isPendente = solicitacao['status'] == 'Pendente';

                  final dataDe = solicitacao['data_de'];
                  final dataAte = solicitacao['data_ate'];
                  String periodoTexto = '';
                  if (dataDe != null && dataDe.isNotEmpty) {
                    periodoTexto =
                        'Período Solicitado: ${_formatarData(dataDe, apenasData: true)}';
                    if (dataAte != null && dataAte.isNotEmpty) {
                      periodoTexto +=
                          ' até ${_formatarData(dataAte, apenasData: true)}';
                    }
                  }

                  // --- CORREÇÃO APLICADA AQUI ---
                  // Garantimos que o ID é um inteiro antes de o usar.
                  final int solicitacaoId =
                      int.parse(solicitacao['id'].toString());

                  return Card(
                    elevation: 2,
                    margin: const EdgeInsets.only(bottom: 16),
                    child: Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Expanded(
                                child: Text(
                                  'Solicitante: ${solicitacao['nome_solicitante'] ?? 'N/A'}',
                                  style: const TextStyle(
                                      fontWeight: FontWeight.bold,
                                      fontSize: 16),
                                ),
                              ),
                              Container(
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 8, vertical: 4),
                                decoration: BoxDecoration(
                                  color: _getStatusColor(
                                      solicitacao['status'] ?? ''),
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: Text(
                                  solicitacao['status']?.toUpperCase() ?? 'N/A',
                                  style: const TextStyle(
                                      color: Colors.white,
                                      fontSize: 12,
                                      fontWeight: FontWeight.bold),
                                ),
                              )
                            ],
                          ),
                          const Divider(),
                          Text('Destino: ${solicitacao['destino'] ?? 'N/A'}'),
                          Text('Motivo: ${solicitacao['motivo'] ?? 'N/A'}'),
                          if (solicitacao['observacoes'] != null &&
                              solicitacao['observacoes'].isNotEmpty)
                            Text('Observações: ${solicitacao['observacoes']}'),
                          if (periodoTexto.isNotEmpty) Text(periodoTexto),
                          const SizedBox(height: 4),
                          Text(
                            'Enviado em: ${_formatarData(solicitacao['data_criacao'])}',
                            style: TextStyle(
                                color: Colors.grey.shade600, fontSize: 12),
                          ),
                          if (isPendente) ...[
                            const SizedBox(height: 16),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.end,
                              children: [
                                TextButton.icon(
                                  icon: const Icon(Icons.close,
                                      color: Colors.red),
                                  label: const Text('Recusar',
                                      style: TextStyle(color: Colors.red)),
                                  // --- CORREÇÃO APLICADA AQUI ---
                                  onPressed: () => _atualizarStatus(
                                      solicitacaoId, 'Recusado'),
                                ),
                                const SizedBox(width: 8),
                                ElevatedButton.icon(
                                  icon: const Icon(Icons.check,
                                      color: Colors.white),
                                  label: const Text('Aprovar'),
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: Colors.green.shade700,
                                    foregroundColor: Colors.white,
                                  ),
                                  // --- CORREÇÃO APLICADA AQUI ---
                                  onPressed: () => _atualizarStatus(
                                      solicitacaoId, 'Aprovado'),
                                ),
                              ],
                            )
                          ]
                        ],
                      ),
                    ),
                  );
                },
              );
            },
          ),
        ),
      ),
    );
  }
}
