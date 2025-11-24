import 'package:flutter/material.dart';
import 'package:hive/hive.dart';
import 'package:fl_chart/fl_chart.dart';
import '../models/history_item.dart';

class DashboardPage extends StatefulWidget {
  const DashboardPage({super.key});

  @override
  State<DashboardPage> createState() => _DashboardPageState();
}

class _DashboardPageState extends State<DashboardPage> {
  String chartType = "pizza";

  final Map<String, Color> speciesColors = {
    "Vegetação comum": Colors.green,
    "Erva-de-Siam": Colors.red,
    "Erva-de-cobra": Colors.orange,
    "Parkinsonia": Colors.blue,
    "Lantana": Colors.purple,
    "Cipó-de-borracha": Colors.brown,
    "Acácia-espinhosa": Colors.teal,
    "Maçã Chinesa": Colors.indigo,
    "Parthênio": Colors.pink,
  };

  @override
  Widget build(BuildContext context) {
    final box = Hive.box('history');

    final items = box.values
        .map((e) => HistoryItem.fromMap(Map<String, dynamic>.from(e)))
        .toList();

    if (items.isEmpty) {
      return Scaffold(
        appBar: AppBar(
          title: const Text("Dashboard Agronômico"),
          backgroundColor: Colors.green,
        ),
        body: const Center(child: Text("Nenhuma análise encontrada")),
      );
    }

    final counts = <String, int>{};
    for (var item in items) {
      counts[item.label] = (counts[item.label] ?? 0) + 1;
    }

    final total = items.length;
    final sorted = counts.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));

    return Scaffold(
      appBar: AppBar(
        title: const Text("Dashboard Agronômico"),
        backgroundColor: Colors.green,
      ),
      body: LayoutBuilder(
        builder: (context, constraints) {
          final width = constraints.maxWidth;

          return Padding(
            padding: const EdgeInsets.all(18),
            child: Column(
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    _chartSelector("barras", Icons.bar_chart),
                    _chartSelector("pizza", Icons.pie_chart),
                    _chartSelector("linha", Icons.show_chart),
                  ],
                ),
                const SizedBox(height: 20),
                Expanded(
                  child: AnimatedSwitcher(
                    duration: const Duration(milliseconds: 300),
                    child: _buildChart(sorted, total, width),
                  ),
                ),
                const SizedBox(height: 14),
                if (chartType != "barras") _legend(sorted),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _chartSelector(String type, IconData icon) {
    final isSelected = chartType == type;

    return GestureDetector(
      onTap: () => setState(() => chartType = type),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 16),
        decoration: BoxDecoration(
          color: isSelected ? Colors.green : Colors.grey.shade200,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(
          children: [
            Icon(icon, color: isSelected ? Colors.white : Colors.black),
            const SizedBox(width: 8),
            Text(
              type.toUpperCase(),
              style: TextStyle(
                color: isSelected ? Colors.white : Colors.black,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildChart(
    List<MapEntry<String, int>> sorted,
    int total,
    double width,
  ) {
    switch (chartType) {
      case "pizza":
        return _buildPie(sorted, total, width);
      case "linha":
        return _buildLine(sorted, width);
      default:
        return _buildBars(sorted, total, width);
    }
  }

  Widget _buildBars(
    List<MapEntry<String, int>> sorted,
    int total,
    double width,
  ) {
    return BarChart(
      BarChartData(
        barGroups: List.generate(sorted.length, (i) {
          final label = sorted[i].key;
          final percent = sorted[i].value / total * 100;
          return BarChartGroupData(
            x: i,
            barRods: [
              BarChartRodData(
                toY: percent,
                color: speciesColors[label] ?? Colors.grey,
                borderRadius: BorderRadius.circular(4),
                width: width * 0.06,
              ),
            ],
          );
        }),
        titlesData: FlTitlesData(
          bottomTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              getTitlesWidget: (value, meta) {
                final index = value.toInt();
                if (index < 0 || index >= sorted.length) {
                  return const SizedBox.shrink();
                }

                return Transform.rotate(
                  angle: 45 * 3.141592653589793 / 180,
                  child: Text(
                    sorted[index].key,
                    style: const TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                );
              },
            ),
          ),
          leftTitles: const AxisTitles(),
          rightTitles: const AxisTitles(),
        ),
        gridData: const FlGridData(show: false),
        borderData: FlBorderData(show: false),
      ),
    );
  }

  Widget _buildPie(
    List<MapEntry<String, int>> sorted,
    int total,
    double width,
  ) {
    return PieChart(
      PieChartData(
        centerSpaceRadius: width * 0.15,
        sectionsSpace: 4,
        sections: sorted.map((e) {
          final percent = e.value / total * 100;
          return PieChartSectionData(
            color: speciesColors[e.key] ?? Colors.grey,
            value: percent,
            radius: width * 0.23,
            title: "${percent.toStringAsFixed(0)}%",
            titleStyle: const TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.bold,
              fontSize: 14,
            ),
          );
        }).toList(),
      ),
    );
  }

  Widget _buildLine(List<MapEntry<String, int>> sorted, double width) {
    return LineChart(
      LineChartData(
        minX: 0,
        maxX: sorted.length.toDouble() - 1,
        minY: 0,
        maxY: sorted
                .map((e) => e.value)
                .reduce((a, b) => a > b ? a : b)
                .toDouble() +
            1,
        gridData: const FlGridData(show: false),
        borderData: FlBorderData(show: false),
        titlesData: FlTitlesData(show: false),
        lineBarsData: [
          LineChartBarData(
            color: Colors.green.shade700,
            barWidth: 4,
            isCurved: true,
            dotData: FlDotData(show: true),
            spots: [
              for (var i = 0; i < sorted.length; i++)
                FlSpot(i.toDouble(), sorted[i].value.toDouble()),
            ],
          ),
        ],
      ),
    );
  }

  Widget _legend(List<MapEntry<String, int>> sorted) {
    return Wrap(
      spacing: 12,
      runSpacing: 6,
      children: sorted.map((e) {
        return Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 14,
              height: 14,
              decoration: BoxDecoration(
                color: speciesColors[e.key] ?? Colors.grey,
                shape: BoxShape.circle,
              ),
            ),
            const SizedBox(width: 6),
            Text(
              e.key,
              style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
            ),
          ],
        );
      }).toList(),
    );
  }
}
