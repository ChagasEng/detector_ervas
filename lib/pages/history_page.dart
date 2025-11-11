import 'dart:io';
import 'package:flutter/material.dart';
import 'package:hive/hive.dart';
import '../models/history_item.dart';
import 'map_page.dart';
import 'chatbase_embed_page.dart'; // 👈 Importa o Chatbase

class HistoryPage extends StatelessWidget {
  const HistoryPage({super.key});

  @override
  Widget build(BuildContext context) {
    final box = Hive.box('history');
    final items = box.values
        .map((e) => HistoryItem.fromMap(Map<String, dynamic>.from(e)))
        .toList()
        .reversed
        .toList();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Histórico de Análises 🌿'),
        backgroundColor: Colors.green.shade700,
        foregroundColor: Colors.white,
        actions: [
          // 💬 Botão para abrir o Chatbase
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

          // 🔹 Botão para abrir o mapa de calor
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

          // 🔹 Botão para limpar histórico
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
          : ListView.builder(
              padding: const EdgeInsets.all(12),
              itemCount: items.length,
              itemBuilder: (context, i) {
                final item = items[i];
                return Card(
                  margin: const EdgeInsets.symmetric(vertical: 8),
                  elevation: 3,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: ListTile(
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
    );
  }
}
