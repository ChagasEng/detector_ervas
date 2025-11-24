import 'dart:io';
import 'package:detector_ervas_daninhas/pages/dashboard_page.dart';
import 'package:flutter/material.dart';
import 'package:hive/hive.dart';
import '../models/history_item.dart';
import 'map_page.dart';
import 'chatbase_embed_page.dart';
import 'history_view_page.dart';

class HistoryPage extends StatefulWidget {
  const HistoryPage({super.key});

  @override
  State<HistoryPage> createState() => _HistoryPageState();
}

class _HistoryPageState extends State<HistoryPage> {
  static const int itemsPerPage = 8;
  int currentPage = 0;

  @override
  Widget build(BuildContext context) {
    final box = Hive.box('history');

    final items = box.values
        .map((e) => HistoryItem.fromMap(Map<String, dynamic>.from(e)))
        .toList()
        .reversed
        .toList();

    final totalPages = (items.length / itemsPerPage).ceil();

    final pageItems = items
        .skip(currentPage * itemsPerPage)
        .take(itemsPerPage)
        .toList();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Histórico de Análises 🌿'),
        backgroundColor: Colors.green.shade700,
        foregroundColor: Colors.white,
        actions: [
          // --- BOTÃO ALDO (NOVO) ---
          IconButton(
            icon: const Icon(Icons.analytics_outlined),
            tooltip: 'Dashboard Agronômico (Aldo)',
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const DashboardPage()),
              );
            },
          ),

          IconButton(
            icon: const Icon(Icons.chat_bubble_outline),
            tooltip: 'Assistente Chatbase',
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const ChatbaseEmbedPage()),
              );
            },
          ),
          IconButton(
            icon: const Icon(Icons.map_rounded),
            tooltip: 'Ver no mapa',
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const MapPage()),
              );
            },
          ),
          IconButton(
            icon: const Icon(Icons.delete_forever),
            tooltip: 'Limpar histórico',
            onPressed: () async {
              final confirm = await showDialog<bool>(
                context: context,
                builder: (context) => AlertDialog(
                  title: const Text('Apagar histórico?'),
                  content: const Text(
                    'Essa ação removerá todas as análises salvas.',
                  ),
                  actions: [
                    TextButton(
                      onPressed: () => Navigator.pop(context, false),
                      child: const Text('Cancelar'),
                    ),
                    ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.redAccent,
                      ),
                      onPressed: () => Navigator.pop(context, true),
                      child: const Text('Apagar'),
                    ),
                  ],
                ),
              );

              if (confirm == true) {
                await box.clear();
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Histórico apagado com sucesso.'),
                  ),
                );
                Navigator.pop(context);
              }
            },
          ),
        ],
      ),

      body: items.isEmpty
          ? const Center(
              child: Text(
                'Nenhuma análise registrada ainda.',
                style: TextStyle(fontSize: 16, color: Colors.black54),
              ),
            )
          : Column(
              children: [
                Expanded(
                  child: ListView.builder(
                    padding: const EdgeInsets.all(12),
                    itemCount: pageItems.length,
                    itemBuilder: (context, i) {
                      final item = pageItems[i];
                      return Card(
                        margin: const EdgeInsets.symmetric(vertical: 8),
                        elevation: 3,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                        ),
                        child: ListTile(
                          onTap: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (_) => HistoryViewPage(item: item),
                              ),
                            );
                          },
                          leading: ClipRRect(
                            borderRadius: BorderRadius.circular(8),
                            child: Image.file(
                              File(item.imagePath),
                              width: 60,
                              height: 60,
                              fit: BoxFit.cover,
                              errorBuilder: (_, __, ___) => Container(
                                color: Colors.grey.shade200,
                                child: const Icon(Icons.image_not_supported),
                              ),
                            ),
                          ),
                          title: Text(
                            item.label,
                            style: const TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 16,
                            ),
                          ),
                          subtitle: Text(
                            'Confiança: ${item.confidence}%\n'
                            'Data: ${item.date.day}/${item.date.month}/${item.date.year} '
                            '${item.date.hour}:${item.date.minute.toString().padLeft(2, '0')}\n'
                            '${item.latitude != null ? 'Lat: ${item.latitude!.toStringAsFixed(5)}, Lng: ${item.longitude!.toStringAsFixed(5)}' : ''}',
                          ),
                          trailing: const Icon(
                            Icons.arrow_forward_ios_rounded,
                            size: 16,
                            color: Colors.grey,
                          ),
                        ),
                      );
                    },
                  ),
                ),

                // PAGINAÇÃO
                if (totalPages > 1)
                  Padding(
                    padding: const EdgeInsets.all(8),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        OutlinedButton(
                          onPressed: currentPage > 0
                              ? () => setState(() => currentPage--)
                              : null,
                          child: const Text("Anterior"),
                        ),
                        const SizedBox(width: 12),
                        Text(
                          "Página ${currentPage + 1} de $totalPages",
                          style: const TextStyle(fontWeight: FontWeight.w600),
                        ),
                        const SizedBox(width: 12),
                        OutlinedButton(
                          onPressed: currentPage < totalPages - 1
                              ? () => setState(() => currentPage++)
                              : null,
                          child: const Text("Próxima"),
                        ),
                      ],
                    ),
                  ),
              ],
            ),
    );
  }
}
