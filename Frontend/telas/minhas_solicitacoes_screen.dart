import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:intl/intl.dart';

class MinhasSolicitacoesScreen extends StatefulWidget {
  final int idUsuario;

  const MinhasSolicitacoesScreen({super.key, required this.idUsuario});

  @override
  State<MinhasSolicitacoesScreen> createState() =>
      _MinhasSolicitacoesScreenState();
}

class _MinhasSolicitacoesScreenState extends State<MinhasSolicitacoesScreen> {
  late Future<List<dynamic>> _futureMinhasSolicitacoes;

  @override
  void initState() {
    super.initState();
    _futureMinhasSolicitacoes = _buscarMinhasSolicitacoes();
  }

  Future<List<dynamic>> _buscarMinhasSolicitacoes() async {
    final url =
        Uri.parse('http://localhost/Backend/buscar_minhas_solicitacoes.php');
    try {
      final response = await http.post(
        url,
        headers: {'Content-Type': 'application/json'},
        body: json.encode({'id_solicitante': widget.idUsuario}),
      );

      if (response.statusCode == 200) {
        final responseData = json.decode(response.body);
        if (responseData['sucesso'] == true) {
          return responseData['dados'];
        } else {
          throw Exception(
              'Falha ao carregar dados: ${responseData['mensagem']}');
        }
      } else {
        throw Exception(
            'Falha ao carregar dados do servidor (Código: ${response.statusCode})');
      }
    } catch (e) {
      throw Exception('Erro de conexão: $e');
    }
  }

  Color _getStatusColor(String? status) {
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

  String _formatarData(String? dataString, {bool apenasData = false}) {
    if (dataString == null || dataString.isEmpty) {
      return 'N/A';
    }
    try {
      final data = DateTime.parse(dataString);
      if (apenasData) {
        return DateFormat('dd/MM/yyyy').format(data);
      }
      return DateFormat('dd/MM/yyyy HH:mm').format(data);
    } catch (e) {
      return dataString;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Minhas Solicitações',
          style: TextStyle(color: Colors.white),
        ),
        backgroundColor: const Color(0xFF1A9DD0),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Navigator.of(context).pop(),
        ),
      ),
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 900),
          child: FutureBuilder<List<dynamic>>(
            future: _futureMinhasSolicitacoes,
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const Center(child: CircularProgressIndicator());
              } else if (snapshot.hasError) {
                return Center(child: Text('Erro: ${snapshot.error}'));
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
                  final dataDe = solicitacao['data_de'];
                  final dataAte = solicitacao['data_ate'];
                  String periodoTexto = '';

                  if (dataDe != null && dataDe.isNotEmpty) {
                    periodoTexto =
                        'Período: ${_formatarData(dataDe, apenasData: true)}';
                    if (dataAte != null && dataAte.isNotEmpty) {
                      periodoTexto +=
                          ' até ${_formatarData(dataAte, apenasData: true)}';
                    }
                  }

                  return Card(
                    elevation: 3,
                    margin: const EdgeInsets.only(bottom: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8.0),
                    ),
                    child: Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                solicitacao['destino']?.toUpperCase() ?? 'N/A',
                                style: TextStyle(
                                    fontSize: 12,
                                    color: Colors.grey.shade600,
                                    fontWeight: FontWeight.bold),
                              ),
                              Container(
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 8, vertical: 4),
                                decoration: BoxDecoration(
                                  color: _getStatusColor(solicitacao['status']),
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: Text(
                                  solicitacao['status']?.toUpperCase() ?? 'N/A',
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontWeight: FontWeight.bold,
                                    fontSize: 12,
                                  ),
                                ),
                              ),
                            ],
                          ),
                          const Divider(),
                          const SizedBox(height: 8),
                          Text(
                            (solicitacao['tipos_solicitacao'] as List)
                                .join(', '),
                            style: const TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 16,
                            ),
                          ),
                          const SizedBox(height: 12),
                          // --- LINHA FINAL COM AS INFORMAÇÕES ADICIONAIS ---
                          Text(
                            'Criado em: ${_formatarData(solicitacao['data_criacao'])}',
                            style: TextStyle(
                              color: Colors.grey.shade600,
                              fontSize: 13,
                            ),
                          ),
                          if (periodoTexto.isNotEmpty)
                            Padding(
                              padding: const EdgeInsets.only(top: 4.0),
                              child: Text(
                                periodoTexto,
                                style: TextStyle(
                                  color: Colors.grey.shade600,
                                  fontSize: 13,
                                ),
                              ),
                            ),
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
