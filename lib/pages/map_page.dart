import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:hive/hive.dart';
import 'package:latlong2/latlong.dart';
import '../models/history_item.dart';
import 'dart:math';

class MapPage extends StatefulWidget {
  const MapPage({super.key});

  @override
  State<MapPage> createState() => _MapPageState();
}

class _MapPageState extends State<MapPage> {
  final List<LatLng> _points = [];

  @override
  void initState() {
    super.initState();
    _loadPoints();
  }

  void _loadPoints() {
    final box = Hive.box('history');
    for (var e in box.values) {
      final item = HistoryItem.fromMap(Map<String, dynamic>.from(e));
      if (item.latitude != null &&
          item.longitude != null &&
          item.label != 'Vegetação comum') {
        _points.add(LatLng(item.latitude!, item.longitude!));
      }
    }
    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    if (_points.isEmpty) {
      return Scaffold(
        appBar: AppBar(
          title: const Text('Mapa de Ervas Daninhas 🌍'),
          backgroundColor: Colors.green.shade700,
          foregroundColor: Colors.white,
        ),
        body: const Center(
          child: Text(
            'Nenhuma detecção registrada ainda.',
            style: TextStyle(fontSize: 16, color: Colors.black54),
          ),
        ),
      );
    }

    // Calcula o centro (média das coordenadas)
    final latAvg =
        _points.map((p) => p.latitude).reduce((a, b) => a + b) / _points.length;
    final lngAvg =
        _points.map((p) => p.longitude).reduce((a, b) => a + b) / _points.length;
    final center = LatLng(latAvg, lngAvg);

    // 🔥 Calcula densidade local (contagem de pontos próximos)
    List<CircleMarker> circles = [];
    const distance = Distance();
    for (var p in _points) {
      int neighbors = 0;
      for (var other in _points) {
        if (distance(p, other) < 150) neighbors++; // raio de 150m para densidade
      }

      // Cores conforme densidade
      Color color;
      if (neighbors <= 1) {
        color = Colors.green.withOpacity(0.4);
      } else if (neighbors <= 3) {
        color = Colors.orange.withOpacity(0.5);
      } else {
        color = Colors.red.withOpacity(0.55);
      }

      circles.add(CircleMarker(
        point: p,
        color: color,
        borderStrokeWidth: 0,
        useRadiusInMeter: true,
        radius: 120 + neighbors * 30.0, // raio proporcional à densidade
      ));
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Mapa de Ervas Daninhas 🌍'),
        backgroundColor: Colors.green.shade700,
        foregroundColor: Colors.white,
      ),
      body: FlutterMap(
        options: MapOptions(
          initialCenter: center,
          initialZoom: 15, // mais próximo
          maxZoom: 19,
          minZoom: 10,
        ),
        children: [
          TileLayer(
            urlTemplate:
                'https://{s}.tile.openstreetmap.org/{z}/{x}/{y}.png',
            subdomains: const ['a', 'b', 'c'],
            userAgentPackageName: 'com.example.detector_ervas_daninhas',
          ),
          CircleLayer(circles: circles),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        backgroundColor: Colors.green.shade700,
        child: const Icon(Icons.my_location),
        onPressed: () => setState(() {}),
      ),
    );
  }
}
