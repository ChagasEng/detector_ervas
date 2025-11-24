import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import '../models/history_item.dart';

class HistoryViewPage extends StatelessWidget {
  final HistoryItem item;
  const HistoryViewPage({super.key, required this.item});

  @override
  Widget build(BuildContext context) {
    final hasLocation = item.latitude != null && item.longitude != null;

    return Scaffold(
      appBar: AppBar(
        title: Text(item.label),
        backgroundColor: Colors.green.shade700,
        foregroundColor: Colors.white,
      ),
      body: Column(
        children: [
          // 📌 FOTO MENOR E MAIS PROFISSIONAL
          SizedBox(
            height: MediaQuery.of(context).size.height * 0.35,
            child: InteractiveViewer(
              maxScale: 5,
              child: Image.file(
                File(item.imagePath),
                width: double.infinity,
                fit: BoxFit.cover,
                errorBuilder: (_, __, ___) => const Center(
                  child: Icon(Icons.broken_image, size: 80),
                ),
              ),
            ),
          ),

          // 📌 DETALHES
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(18),
            decoration: const BoxDecoration(
              color: Colors.white,
              boxShadow: [
                BoxShadow(
                  color: Colors.black12,
                  blurRadius: 4,
                  offset: Offset(0, -2),
                ),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  item.label,
                  style: const TextStyle(
                    fontSize: 20, 
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 6),
                Text("Confiança: ${item.confidence}%"),
                Text(
                  "Data: ${item.date.day}/${item.date.month}/${item.date.year} "
                  "${item.date.hour}:${item.date.minute.toString().padLeft(2, '0')}",
                ),
                if (hasLocation)
                  Text(
                    "Lat: ${item.latitude}, Lng: ${item.longitude}",
                  ),
              ],
            ),
          ),

          const SizedBox(height: 8),

          // 📌 MAPA COM PIN — SOMENTE SE HOUVER GPS
          if (hasLocation)
            Expanded(
              child: Padding(
                padding: const EdgeInsets.all(12.0),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(16),
                  child: FlutterMap(
                    options: MapOptions(
                      initialCenter: LatLng(item.latitude!, item.longitude!),
                      initialZoom: 16,
                      maxZoom: 18,
                      minZoom: 13,
                    ),
                    children: [
                      TileLayer(
                        urlTemplate:
                            'https://{s}.tile.openstreetmap.org/{z}/{x}/{y}.png',
                        subdomains: const ['a', 'b', 'c'],
                        userAgentPackageName: 'com.example.plantscan',
                      ),

                      // PIN
                      MarkerLayer(
                        markers: [
                          Marker(
                            point: LatLng(item.latitude!, item.longitude!),
                            width: 40,
                            height: 40,
                            child: const Icon(
                              Icons.location_on,
                              size: 40,
                              color: Colors.red,
                            ),
                          ),
                        ],
                      )
                    ],
                  ),
                ),
              ),
            ),

          if (!hasLocation)
            const Padding(
              padding: EdgeInsets.all(16),
              child: Text(
                "Nenhuma coordenada registrada para esta análise.",
                style: TextStyle(fontSize: 16, color: Colors.black54),
              ),
            )
        ],
      ),
    );
  }
}
