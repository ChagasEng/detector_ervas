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

  // Layout responsivo baseado na largura da tela
  bool get isSmallScreen => MediaQuery.of(context).size.width < 600;
  bool get isMediumScreen => 
      MediaQuery.of(context).size.width >= 600 && 
      MediaQuery.of(context).size.width < 1200;
  bool get isLargeScreen => MediaQuery.of(context).size.width >= 1200;

  double get chartHeight {
    if (isSmallScreen) return 280;
    if (isMediumScreen) return 320;
    return 350;
  }

  double get cardHeight {
    if (isSmallScreen) return 80;
    return 90;
  }

  Widget _buildStatCard(String title, String value, IconData icon, Color color) {
  return LayoutBuilder(
    builder: (context, constraints) {
      final w = constraints.maxWidth;
      final h = constraints.maxHeight;

      final isMini = w < 150; // telas extremamente pequenas

      return Container(
        height: cardHeight,
        padding: EdgeInsets.all(isSmallScreen ? 10 : 14),
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
              padding: EdgeInsets.all(isMini ? 6 : (isSmallScreen ? 8 : 12)),
              decoration: BoxDecoration(
                color: color.withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(
                icon,
                color: color,
                size: isMini ? 16 : (isSmallScreen ? 20 : 24),
              ),
            ),
            SizedBox(width: isMini ? 6 : (isSmallScreen ? 8 : 12)),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    title,
                    style: TextStyle(
                      fontSize: isMini ? 9 : (isSmallScreen ? 10 : 12),
                      fontWeight: FontWeight.w500,
                      color: Colors.grey.shade600,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  SizedBox(height: isMini ? 1 : (isSmallScreen ? 2 : 4)),
                  Text(
                    value,
                    style: TextStyle(
                      fontSize: isMini ? 14 : (isSmallScreen ? 16 : 18),
                      fontWeight: FontWeight.w700,
                      color: const Color(0xFF1F2937),
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
          ],
        ),
      );
    },
  );
}


  Widget _chartSelector(String type, IconData icon, String label) {
    final isSelected = chartType == type;
    
    return Expanded(
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 2),
        child: Material(
          color: isSelected ? Color(0xFF059669) : Colors.grey.shade100,
          borderRadius: BorderRadius.circular(8),
          child: InkWell(
            onTap: () => setState(() => chartType = type),
            borderRadius: BorderRadius.circular(8),
            child: Container(
              padding: EdgeInsets.symmetric(
                vertical: isSmallScreen ? 12 : 16, 
                horizontal: isSmallScreen ? 4 : 8
              ),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    icon,
                    color: isSelected ? Colors.white : Color(0xFF6B7280),
                    size: isSmallScreen ? 18 : 20,
                  ),
                  SizedBox(height: isSmallScreen ? 4 : 6),
                  Text(
                    label,
                    style: TextStyle(
                      fontSize: isSmallScreen ? 9 : 11,
                      fontWeight: FontWeight.w600,
                      color: isSelected ? Colors.white : Color(0xFF6B7280),
                    ),
                    textAlign: TextAlign.center,
                    maxLines: 1,
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildPieChart(List<MapEntry<String, int>> sorted, int total, double maxWidth) {
  final double radius = (maxWidth * 0.28).clamp(60, 130);
  final double centerRadius = (maxWidth * 0.15).clamp(30, 55);

  return Center(
    child: PieChart(
      PieChartData(
        sectionsSpace: 2,
        centerSpaceRadius: centerRadius,
        startDegreeOffset: -90,
        sections: sorted.map((e) {
          final percent = (e.value / total * 100);
          final small = percent < 5;

          return PieChartSectionData(
            color: speciesColors[e.key] ?? Colors.grey,
            value: percent,
            radius: radius,
            title: small ? '' : '${percent.toStringAsFixed(0)}%',
            titleStyle: const TextStyle(
              fontSize: 10,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
            badgeWidget: small
                ? Text(
                    '${percent.toStringAsFixed(0)}%',
                    style: const TextStyle(
                      fontSize: 8,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  )
                : null,
            badgePositionPercentageOffset: small ? 0.6 : null,
          );
        }).toList(),
      ),
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
                final maxChars = isSmallScreen ? 8 : 12;
                final shortLabel = label.length > maxChars 
                    ? '${label.substring(0, maxChars)}...' 
                    : label;
                
                return Padding(
                  padding: const EdgeInsets.only(top: 8.0),
                  child: Text(
                    shortLabel,
                    style: TextStyle(
                      fontSize: isSmallScreen ? 8 : 10,
                      fontWeight: FontWeight.w500,
                      color: Color(0xFF6B7280),
                    ),
                    textAlign: TextAlign.center,
                    maxLines: 2,
                  ),
                );
              },
              reservedSize: isSmallScreen ? 35 : 40,
            ),
          ),
          leftTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              getTitlesWidget: (value, meta) {
                if (value == meta.min || value == meta.max) return const SizedBox();
                return Text(
                  value.toInt().toString(),
                  style: TextStyle(
                    fontSize: isSmallScreen ? 8 : 10,
                    fontWeight: FontWeight.w500,
                    color: Color(0xFF6B7280),
                  ),
                );
              },
              reservedSize: isSmallScreen ? 24 : 28,
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
                width: isSmallScreen ? width * 0.06 : width * 0.08,
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
                    style: TextStyle(
                      fontSize: isSmallScreen ? 8 : 10,
                      fontWeight: FontWeight.w500,
                      color: Color(0xFF6B7280),
                    ),
                  ),
                );
              },
              reservedSize: isSmallScreen ? 24 : 28,
            ),
          ),
          leftTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              getTitlesWidget: (value, meta) {
                return Text(
                  value.toInt().toString(),
                  style: TextStyle(
                    fontSize: isSmallScreen ? 8 : 10,
                    fontWeight: FontWeight.w500,
                    color: Color(0xFF6B7280),
                  ),
                );
              },
              reservedSize: isSmallScreen ? 24 : 28,
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
                  radius: isSmallScreen ? 3 : 4,
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
      padding: EdgeInsets.all(isSmallScreen ? 12 : 16),
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
          Text(
            'Legenda de Espécies',
            style: TextStyle(
              fontSize: isSmallScreen ? 14 : 16,
              fontWeight: FontWeight.w700,
              color: Color(0xFF1F2937),
            ),
          ),
          SizedBox(height: isSmallScreen ? 8 : 12),
          Wrap(
            spacing: isSmallScreen ? 8 : 12,
            runSpacing: isSmallScreen ? 6 : 8,
            children: sorted.map((e) {
              final percent = (e.value / total * 100).toStringAsFixed(1);
              final maxLabelLength = isSmallScreen ? 15 : 30;
              final displayLabel = e.key.length > maxLabelLength 
                  ? '${e.key.substring(0, maxLabelLength)}...' 
                  : e.key;
              
              return Container(
                padding: EdgeInsets.symmetric(
                  horizontal: isSmallScreen ? 8 : 12, 
                  vertical: isSmallScreen ? 4 : 6
                ),
                decoration: BoxDecoration(
                  color: Colors.grey.shade50,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.grey.shade200),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      width: isSmallScreen ? 10 : 12,
                      height: isSmallScreen ? 10 : 12,
                      decoration: BoxDecoration(
                        color: speciesColors[e.key] ?? Colors.grey,
                        shape: BoxShape.circle,
                      ),
                    ),
                    SizedBox(width: isSmallScreen ? 6 : 8),
                    Text(
                      displayLabel,
                      style: TextStyle(
                        fontSize: isSmallScreen ? 10 : 12,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    SizedBox(width: isSmallScreen ? 4 : 6),
                    Text(
                      '(${e.value})',
                      style: TextStyle(
                        fontSize: isSmallScreen ? 9 : 11,
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
          title: Text(
            'Dashboard Agronômico',
            style: TextStyle(
              fontWeight: FontWeight.w700,
              fontSize: isSmallScreen ? 18 : 20,
            ),
          ),
          backgroundColor: Color(0xFF059669),
          foregroundColor: Colors.white,
          elevation: 0,
        ),
        body: Center(
          child: Padding(
            padding: EdgeInsets.all(isSmallScreen ? 20 : 32),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.analytics_outlined,
                  size: isSmallScreen ? 60 : 80,
                  color: Colors.grey.shade400,
                ),
                SizedBox(height: isSmallScreen ? 12 : 16),
                Text(
                  'Nenhuma análise encontrada',
                  style: TextStyle(
                    fontSize: isSmallScreen ? 16 : 18,
                    fontWeight: FontWeight.w600,
                    color: Colors.grey.shade600,
                  ),
                  textAlign: TextAlign.center,
                ),
                SizedBox(height: isSmallScreen ? 6 : 8),
                Text(
                  'Realize algumas análises para ver as estatísticas',
                  style: TextStyle(
                    fontSize: isSmallScreen ? 12 : 14,
                    color: Colors.grey.shade500,
                  ),
                  textAlign: TextAlign.center,
                ),
              ],
            ),
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
        title: Text(
          'Dashboard Agronômico',
          style: TextStyle(
            fontWeight: FontWeight.w700,
            fontSize: isSmallScreen ? 18 : 20,
          ),
        ),
        backgroundColor: Color(0xFF059669),
        foregroundColor: Colors.white,
        elevation: 0,
      ),
      body: SingleChildScrollView(
        padding: EdgeInsets.all(isSmallScreen ? 12 : 16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Cards de estatísticas - Layout responsivo
            if (isSmallScreen) ...[
              // Layout para telas pequenas - vertical
              _buildStatCard(
                'Total de Análises',
                total.toString(),
                Icons.analytics,
                Color(0xFF059669),
              ),
              SizedBox(height: 8),
              _buildStatCard(
                'Espécies Identificadas',
                totalSpecies.toString(),
                Icons.eco,
                Color(0xFF3B82F6),
              ),
              SizedBox(height: 8),
              _buildStatCard(
                'Espécie Mais Comum',
                mostCommon,
                Icons.trending_up,
                Color(0xFFEF4444),
              ),
            ] else ...[
              // Layout para telas médias e grandes - horizontal
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
                  SizedBox(width: 12),
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
              SizedBox(height: 12),
              _buildStatCard(
                'Espécie Mais Comum',
                mostCommon,
                Icons.trending_up,
                Color(0xFFEF4444),
              ),
            ],
            SizedBox(height: isSmallScreen ? 16 : 24),

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
            SizedBox(height: isSmallScreen ? 16 : 24),

            // Gráfico
            Container(
              height: chartHeight,
              padding: EdgeInsets.all(isSmallScreen ? 12 : 16),
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
            SizedBox(height: isSmallScreen ? 12 : 16),

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