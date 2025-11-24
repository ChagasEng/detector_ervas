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
    "Vegetação comum": Color(0xFF10B981),
    "Erva-de-Siam": Color(0xFFEF4444),
    "Erva-de-cobra": Color(0xFFF59E0B),
    "Parkinsonia": Color(0xFF3B82F6),
    "Lantana": Color(0xFF8B5CF6),
    "Cipó-de-borracha": Color(0xFF92400E),
    "Acácia-espinhosa": Color(0xFF06B6D4),
    "Maçã Chinesa": Color(0xFF6366F1),
    "Parthênio": Color(0xFFEC4899),
  };

  Widget _buildStatCard(String title, String value, IconData icon, Color color) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: color.withOpacity(0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(icon, color: color, size: 24),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                    color: Colors.grey.shade600,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  value,
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w700,
                    color: Color(0xFF1F2937),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _chartSelector(String type, IconData icon, String label) {
    final isSelected = chartType == type;
    
    return Expanded(
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 4),
        child: Material(
          color: isSelected ? Color(0xFF059669) : Colors.grey.shade100,
          borderRadius: BorderRadius.circular(12),
          child: InkWell(
            onTap: () => setState(() => chartType = type),
            borderRadius: BorderRadius.circular(12),
            child: Container(
              padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 8),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    icon,
                    color: isSelected ? Colors.white : Color(0xFF6B7280),
                    size: 20,
                  ),
                  const SizedBox(height: 6),
                  Text(
                    label,
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                      color: isSelected ? Colors.white : Color(0xFF6B7280),
                    ),
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildPieChart(List<MapEntry<String, int>> sorted, int total, double width) {
    return PieChart(
      PieChartData(
        centerSpaceRadius: width * 0.2,
        sectionsSpace: 2,
        startDegreeOffset: -90,
        sections: sorted.asMap().entries.map((entry) {
          final index = entry.key;
          final e = entry.value;
          final percent = e.value / total * 100;
          final isSmallSlice = percent < 5;
          
          return PieChartSectionData(
            color: speciesColors[e.key] ?? Colors.grey.shade400,
            value: percent,
            radius: width * 0.25,
            title: isSmallSlice ? '' : '${percent.toStringAsFixed(0)}%',
            titleStyle: const TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w700,
              color: Colors.white,
            ),
            badgeWidget: isSmallSlice ? Text(
              '${percent.toStringAsFixed(0)}%',
              style: const TextStyle(
                fontSize: 10,
                fontWeight: FontWeight.w700,
                color: Colors.white,
              ),
            ) : null,
            badgePositionPercentageOffset: isSmallSlice ? 0.6 : null,
          );
        }).toList(),
      ),
    );
  }

  Widget _buildBarChart(List<MapEntry<String, int>> sorted, int total, double width) {
    final maxValue = sorted.isNotEmpty 
        ? sorted.map((e) => e.value).reduce((a, b) => a > b ? a : b).toDouble()
        : 0.0;

    return BarChart(
      BarChartData(
        alignment: BarChartAlignment.spaceAround,
        maxY: maxValue * 1.1,
        barTouchData: BarTouchData(
          enabled: true,
          touchTooltipData: BarTouchTooltipData(
            tooltipBgColor: Colors.black87,
            getTooltipItem: (group, groupIndex, rod, rodIndex) {
              final species = sorted[groupIndex].key;
              final count = sorted[groupIndex].value;
              final percent = (count / total * 100).toStringAsFixed(1);
              
              return BarTooltipItem(
                '$species\n$count análises ($percent%)',
                const TextStyle(color: Colors.white),
              );
            },
          ),
        ),
        titlesData: FlTitlesData(
          show: true,
          bottomTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              getTitlesWidget: (value, meta) {
                final index = value.toInt();
                if (index < 0 || index >= sorted.length) return const SizedBox();
                
                final label = sorted[index].key;
                final shortLabel = label.length > 12 
                    ? '${label.substring(0, 12)}...' 
                    : label;
                
                return Padding(
                  padding: const EdgeInsets.only(top: 8.0),
                  child: Text(
                    shortLabel,
                    style: const TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.w500,
                      color: Color(0xFF6B7280),
                    ),
                    textAlign: TextAlign.center,
                    maxLines: 2,
                  ),
                );
              },
              reservedSize: 40,
            ),
          ),
          leftTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              getTitlesWidget: (value, meta) {
                if (value == meta.min || value == meta.max) return const SizedBox();
                return Text(
                  value.toInt().toString(),
                  style: const TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.w500,
                    color: Color(0xFF6B7280),
                  ),
                );
              },
              reservedSize: 28,
            ),
          ),
          rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
          topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
        ),
        gridData: FlGridData(
          show: true,
          drawVerticalLine: false,
          getDrawingHorizontalLine: (value) => FlLine(
            color: Colors.grey.shade200,
            strokeWidth: 1,
          ),
        ),
        borderData: FlBorderData(
          show: true,
          border: Border.all(color: Colors.grey.shade300, width: 1),
        ),
        barGroups: sorted.asMap().entries.map((entry) {
          final i = entry.key;
          final e = entry.value;
          
          return BarChartGroupData(
            x: i,
            barRods: [
              BarChartRodData(
                toY: e.value.toDouble(),
                color: speciesColors[e.key] ?? Colors.grey.shade400,
                borderRadius: BorderRadius.circular(4),
                width: width * 0.08,
              ),
            ],
          );
        }).toList(),
      ),
    );
  }

  Widget _buildLineChart(List<MapEntry<String, int>> sorted, double width) {
    if (sorted.isEmpty) return const SizedBox();

    final maxValue = sorted.map((e) => e.value).reduce((a, b) => a > b ? a : b).toDouble();

    return LineChart(
      LineChartData(
        minX: 0,
        maxX: (sorted.length - 1).toDouble(),
        minY: 0,
        maxY: maxValue * 1.1,
        gridData: FlGridData(
          show: true,
          drawVerticalLine: false,
          getDrawingHorizontalLine: (value) => FlLine(
            color: Colors.grey.shade200,
            strokeWidth: 1,
          ),
        ),
        titlesData: FlTitlesData(
          bottomTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              getTitlesWidget: (value, meta) {
                final index = value.toInt();
                if (index < 0 || index >= sorted.length) return const SizedBox();
                
                return Padding(
                  padding: const EdgeInsets.only(top: 8.0),
                  child: Text(
                    '${index + 1}',
                    style: const TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.w500,
                      color: Color(0xFF6B7280),
                    ),
                  ),
                );
              },
              reservedSize: 28,
            ),
          ),
          leftTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              getTitlesWidget: (value, meta) {
                return Text(
                  value.toInt().toString(),
                  style: const TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.w500,
                    color: Color(0xFF6B7280),
                  ),
                );
              },
              reservedSize: 28,
            ),
          ),
          rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
          topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
        ),
        borderData: FlBorderData(
          show: true,
          border: Border.all(color: Colors.grey.shade300, width: 1),
        ),
        lineBarsData: [
          LineChartBarData(
            color: Color(0xFF059669),
            barWidth: 3,
            isCurved: true,
            dotData: FlDotData(
              show: true,
              getDotPainter: (spot, percent, barData, index) {
                return FlDotCirclePainter(
                  radius: 4,
                  color: Color(0xFF059669),
                  strokeWidth: 2,
                  strokeColor: Colors.white,
                );
              },
            ),
            belowBarData: BarAreaData(
              show: true,
              color: Color(0xFF059669).withOpacity(0.1),
            ),
            spots: sorted.asMap().entries.map((entry) {
              final i = entry.key;
              final value = entry.value.value.toDouble();
              return FlSpot(i.toDouble(), value);
            }).toList(),
          ),
        ],
      ),
    );
  }

  Widget _buildLegend(List<MapEntry<String, int>> sorted, int total) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Legenda de Espécies',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w700,
              color: Color(0xFF1F2937),
            ),
          ),
          const SizedBox(height: 12),
          Wrap(
            spacing: 12,
            runSpacing: 8,
            children: sorted.map((e) {
              final percent = (e.value / total * 100).toStringAsFixed(1);
              
              return Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: Colors.grey.shade50,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.grey.shade200),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      width: 12,
                      height: 12,
                      decoration: BoxDecoration(
                        color: speciesColors[e.key] ?? Colors.grey,
                        shape: BoxShape.circle,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      e.key,
                      style: const TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    const SizedBox(width: 6),
                    Text(
                      '(${e.value} - $percent%)',
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                        color: Colors.grey.shade600,
                      ),
                    ),
                  ],
                ),
              );
            }).toList(),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final box = Hive.box('history');
    final items = box.values
        .map((e) => HistoryItem.fromMap(Map<String, dynamic>.from(e)))
        .toList();

    if (items.isEmpty) {
      return Scaffold(
        appBar: AppBar(
          title: const Text(
            'Dashboard Agronômico',
            style: TextStyle(fontWeight: FontWeight.w700),
          ),
          backgroundColor: Color(0xFF059669),
          foregroundColor: Colors.white,
          elevation: 0,
        ),
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.analytics_outlined,
                size: 80,
                color: Colors.grey.shade400,
              ),
              const SizedBox(height: 16),
              Text(
                'Nenhuma análise encontrada',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                  color: Colors.grey.shade600,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'Realize algumas análises para ver as estatísticas',
                style: TextStyle(
                  fontSize: 14,
                  color: Colors.grey.shade500,
                ),
              ),
            ],
          ),
        ),
      );
    }

    final counts = <String, int>{};
    for (var item in items) {
      counts[item.label] = (counts[item.label] ?? 0) + 1;
    }

    final total = items.length;
    final sorted = counts.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));

    final mostCommon = sorted.isNotEmpty ? sorted.first.key : 'N/A';
    final totalSpecies = counts.length;

    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Dashboard Agronômico',
          style: TextStyle(fontWeight: FontWeight.w700),
        ),
        backgroundColor: Color(0xFF059669),
        foregroundColor: Colors.white,
        elevation: 0,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Cards de estatísticas
            Row(
              children: [
                Expanded(
                  child: _buildStatCard(
                    'Total de Análises',
                    total.toString(),
                    Icons.analytics,
                    Color(0xFF059669),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _buildStatCard(
                    'Espécies Identificadas',
                    totalSpecies.toString(),
                    Icons.eco,
                    Color(0xFF3B82F6),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            _buildStatCard(
              'Espécie Mais Comum',
              mostCommon,
              Icons.trending_up,
              Color(0xFFEF4444),
            ),
            const SizedBox(height: 24),

            // Seletor de gráficos
            Container(
              padding: const EdgeInsets.all(4),
              decoration: BoxDecoration(
                color: Colors.grey.shade100,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(
                children: [
                  _chartSelector("pizza", Icons.pie_chart, "Pizza"),
                  _chartSelector("barras", Icons.bar_chart, "Barras"),
                  _chartSelector("linha", Icons.show_chart, "Linha"),
                ],
              ),
            ),
            const SizedBox(height: 24),

            // Gráfico
            Container(
              height: 300,
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.05),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: AnimatedSwitcher(
                duration: const Duration(milliseconds: 400),
                child: _buildChart(sorted, total, MediaQuery.of(context).size.width),
              ),
            ),
            const SizedBox(height: 16),

            // Legenda
            _buildLegend(sorted, total),
          ],
        ),
      ),
    );
  }

  Widget _buildChart(List<MapEntry<String, int>> sorted, int total, double width) {
    switch (chartType) {
      case "pizza":
        return _buildPieChart(sorted, total, width);
      case "barras":
        return _buildBarChart(sorted, total, width);
      case "linha":
        return _buildLineChart(sorted, width);
      default:
        return _buildPieChart(sorted, total, width);
    }
  }
}