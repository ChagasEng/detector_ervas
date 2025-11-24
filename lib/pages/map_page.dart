import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:hive/hive.dart';
import 'package:latlong2/latlong.dart';
import 'package:fl_chart/fl_chart.dart';
import '../models/history_item.dart';
import 'dart:io';

class MapPage extends StatefulWidget {
  const MapPage({super.key});

  @override
  State<MapPage> createState() => _MapPageState();
}

class _MapPageState extends State<MapPage> {
  final List<HistoryItem> _allItems = [];
  List<HistoryItem> _filteredItems = [];

  bool usePins = false;
  bool useSatellite = false; // ⭐ MODO SATÉLITE ATIVADO/DESATIVADO

  String? selectedDate;
  DateTime? startRange;
  DateTime? endRange;

  @override
  void initState() {
    super.initState();
    _loadItems();
  }

  void _loadItems() {
    final box = Hive.box('history');

    _allItems.clear();
    for (var e in box.values) {
      final item = HistoryItem.fromMap(Map<String, dynamic>.from(e));

      if (item.latitude != null &&
          item.longitude != null &&
          item.label != "Vegetação comum") {
        _allItems.add(item);
      }
    }

    _filteredItems = List.from(_allItems);
    setState(() {});
  }

  List<String> getUniqueDates() {
    final dates = _allItems
        .map((e) => "${e.date.day}/${e.date.month}/${e.date.year}")
        .toSet()
        .toList();
    dates.sort();
    return dates.reversed.toList();
  }

  void filterBySelectedDate(String dateString) {
    selectedDate = dateString;
    startRange = null;
    endRange = null;

    _filteredItems = _allItems.where((item) {
      final d = "${item.date.day}/${item.date.month}/${item.date.year}";
      return d == dateString;
    }).toList();

    setState(() {});
  }

  void filterByRange(int days) {
    final now = DateTime.now();
    startRange = now.subtract(Duration(days: days));
    endRange = now;
    selectedDate = null;

    _filteredItems = _allItems.where((item) {
      return item.date.isAfter(startRange!) && item.date.isBefore(endRange!);
    }).toList();

    setState(() {});
  }

  List<FlSpot> generateSpots() {
    Map<String, int> countByDay = {};

    for (var item in _filteredItems) {
      final key = "${item.date.day}/${item.date.month}";
      countByDay[key] = (countByDay[key] ?? 0) + 1;
    }

    List<String> sortedKeys = countByDay.keys.toList();
    sortedKeys.sort((a, b) {
      final pa = a.split("/");
      final pb = b.split("/");
      final da = DateTime(2025, int.parse(pa[1]), int.parse(pa[0]));
      final db = DateTime(2025, int.parse(pb[1]), int.parse(pb[0]));
      return da.compareTo(db);
    });

    List<FlSpot> spots = [];
    for (int i = 0; i < sortedKeys.length; i++) {
      spots.add(FlSpot(i.toDouble(), countByDay[sortedKeys[i]]!.toDouble()));
    }
    return spots;
  }

  void openPinDetails(HistoryItem item) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(22)),
      ),
      builder: (_) {
        return Padding(
          padding: const EdgeInsets.all(18),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                height: 140,
                width: double.infinity,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(16),
                  image: DecorationImage(
                    image: FileImage(File(item.imagePath)),
                    fit: BoxFit.cover,
                  ),
                ),
              ),
              const SizedBox(height: 16),
              Text(
                item.label,
                style: const TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                ),
              ),
              Text("Confiança: ${item.confidence}%"),
              const SizedBox(height: 8),
              Text(
                "${item.date.day}/${item.date.month}/${item.date.year}",
                style: const TextStyle(fontSize: 14, color: Colors.grey),
              ),
              const SizedBox(height: 16),
              ElevatedButton(
                onPressed: () => Navigator.pop(context),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.green.shade700,
                ),
                child: const Text("Fechar"),
              ),
            ],
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_filteredItems.isEmpty) {
      return Scaffold(
        appBar: AppBar(
          title: const Text("Mapa de Ervas Daninhas 🌿"),
          backgroundColor: Colors.green.shade700,
          foregroundColor: Colors.white,
        ),
        body: const Center(child: Text("Nenhuma detecção encontrada.")),
      );
    }

    final points = _filteredItems
        .map((e) => LatLng(e.latitude!, e.longitude!))
        .toList();

    final center = points.length == 1
        ? points.first
        : LatLng(
            points.map((e) => e.latitude).reduce((a, b) => a + b) /
                points.length,
            points.map((e) => e.longitude).reduce((a, b) => a + b) /
                points.length,
          );

    final distance = Distance();

    List<CircleMarker> circles = [];
    if (!usePins) {
      for (var p in points) {
        int neighbors = 0;

        for (var other in points) {
          if (distance(p, other) < 120) neighbors++;
        }

        circles.add(
          CircleMarker(
            point: p,
            useRadiusInMeter: true,
            radius: 40 + neighbors * 14,
            color: Colors.red.withOpacity(0.30 + (neighbors * 0.05)),
          ),
        );
      }
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text("Mapa de Ervas Daninhas 🌿"),
        backgroundColor: Colors.green.shade700,
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            icon: Icon(
              useSatellite ? Icons.map_rounded : Icons.satellite_alt_rounded,
              size: 28,
              color: Colors.white,
            ),
            onPressed: () {
              setState(() => useSatellite = !useSatellite);
            },
          ),
        ],
      ),

      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(8, 8, 8, 0),
            child: DropdownButtonFormField<String>(
              value: selectedDate,
              decoration: const InputDecoration(
                labelText: "Selecionar data",
                border: OutlineInputBorder(),
              ),
              items: getUniqueDates()
                  .map((d) => DropdownMenuItem(value: d, child: Text(d)))
                  .toList(),
              onChanged: (value) => filterBySelectedDate(value!),
            ),
          ),

          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              ElevatedButton(
                onPressed: () => filterByRange(7),
                child: const Text("Últimos 7 dias"),
              ),
              ElevatedButton(
                onPressed: () => filterByRange(30),
                child: const Text("Últimos 30 dias"),
              ),
            ],
          ),

          const SizedBox(height: 1),

          SizedBox(
            height: 1,
            child: LineChart(
              LineChartData(
                titlesData: FlTitlesData(show: false),
                borderData: FlBorderData(show: false),
                lineBarsData: [
                  LineChartBarData(
                    spots: generateSpots(),
                    isCurved: true,
                    barWidth: 3,
                    color: Colors.green.shade700,
                    dotData: FlDotData(show: true),
                  ),
                ],
              ),
            ),
          ),

          Padding(
            padding: const EdgeInsets.only(top: 4),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                ChoiceChip(
                  selectedColor: Colors.green.shade600,
                  label: const Text("Círculos"),
                  selected: !usePins,
                  onSelected: (_) => setState(() => usePins = false),
                ),
                const SizedBox(width: 12),
                ChoiceChip(
                  selectedColor: Colors.green.shade600,
                  label: const Text("PINs"),
                  selected: usePins,
                  onSelected: (_) => setState(() => usePins = true),
                ),
              ],
            ),
          ),

          Expanded(
            child: FlutterMap(
              options: MapOptions(
                initialCenter: center,
                initialZoom: 15,
                maxZoom: useSatellite ? 17 : 19, // ⭐ ZOOM LIMITADO NO SATÉLITE
              ),
              children: [
                TileLayer(
                  urlTemplate: useSatellite
                      ? "https://services.arcgisonline.com/ArcGIS/rest/services/World_Imagery/MapServer/tile/{z}/{y}/{x}"
                      : "https://{s}.tile.openstreetmap.org/{z}/{x}/{y}.png",
                  subdomains: useSatellite ? [] : const ['a', 'b', 'c'],
                ),

                if (usePins)
                  MarkerLayer(
                    markers: _filteredItems.map((item) {
                      return Marker(
                        point: LatLng(item.latitude!, item.longitude!),
                        width: 40,
                        height: 40,
                        child: GestureDetector(
                          onTap: () => openPinDetails(item),
                          child: const Icon(
                            Icons.location_on,
                            color: Colors.red,
                            size: 38,
                          ),
                        ),
                      );
                    }).toList(),
                  )
                else
                  CircleLayer(circles: circles),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
