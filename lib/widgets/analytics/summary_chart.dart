import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:algo_arena/core/app_theme.dart';
import 'package:algo_arena/models/analytics_models.dart';

class SummaryBarChart extends StatelessWidget {
  final List<SummaryData> data;
  final String metric;

  const SummaryBarChart({super.key, required this.data, required this.metric});

  @override
  Widget build(BuildContext context) {
    if (data.isEmpty) return const SizedBox.shrink();

    return Container(
      height: 300,
      padding: const EdgeInsets.all(20),
      decoration: AppTheme.glassCard(radius: 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            "Algorithm Comparison",
            style: Theme.of(context).textTheme.titleLarge?.copyWith(
                  fontFamily: 'SpaceGrotesk',
                  fontWeight: FontWeight.bold,
                ),
          ),
          const SizedBox(height: 4),
          Text(
            metric == 'nodes' ? "Average Nodes Explored" : "Average Time (ms)",
            style: Theme.of(context).textTheme.labelSmall?.copyWith(
                  color: AppTheme.textMuted,
                  letterSpacing: 0.5,
                ),
          ),
          const SizedBox(height: 24),
          Expanded(
            child: BarChart(
              BarChartData(
                alignment: BarChartAlignment.spaceAround,
                maxY: _getMaxY(),
                barTouchData: BarTouchData(
                  touchTooltipData: BarTouchTooltipData(
                    getTooltipColor: (_) => AppTheme.surfaceHigh,
                    getTooltipItem: (group, groupIndex, rod, rodIndex) {
                      final item = data[groupIndex];
                      final actualValue = metric == 'nodes' ? item.avgNodes : item.avgTime;
                      return BarTooltipItem(
                        "${item.algorithm}\n",
                        const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                        children: [
                          TextSpan(
                            text: "${actualValue.toStringAsFixed(1)} ${metric == 'nodes' ? 'nodes' : 'ms'}",
                            style: const TextStyle(color: AppTheme.accentLight, fontWeight: FontWeight.w500),
                          ),
                        ],
                      );
                    },
                  ),
                ),
                titlesData: FlTitlesData(
                  show: true,
                  bottomTitles: AxisTitles(
                    axisNameWidget: const Text(
                      'ALGORITHM',
                      style: TextStyle(color: AppTheme.textMuted, fontSize: 10, fontWeight: FontWeight.bold, letterSpacing: 1.2),
                    ),
                    axisNameSize: 20,
                    sideTitles: SideTitles(
                      showTitles: true,
                      getTitlesWidget: (value, meta) {
                        if (value.toInt() < 0 || value.toInt() >= data.length) return const SizedBox.shrink();
                        return Padding(
                          padding: const EdgeInsets.only(top: 4.0),
                          child: Text(
                            data[value.toInt()].algorithm,
                            style: const TextStyle(color: AppTheme.textMuted, fontSize: 10),
                          ),
                        );
                      },
                    ),
                  ),
                  leftTitles: AxisTitles(
                    axisNameWidget: Text(
                      metric == 'nodes' ? 'AVG. NODES' : 'AVG. TIME (ms)',
                      style: const TextStyle(color: AppTheme.textMuted, fontSize: 10, fontWeight: FontWeight.bold, letterSpacing: 1.2),
                    ),
                    axisNameSize: 20,
                    sideTitles: SideTitles(
                      showTitles: true,
                      reservedSize: 40,
                      getTitlesWidget: (value, meta) {
                        return Text(
                          value.toInt().toString(),
                          style: const TextStyle(color: AppTheme.textMuted, fontSize: 10),
                        );
                      },
                    ),
                  ),
                  topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                  rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                ),
                gridData: const FlGridData(show: false),
                borderData: FlBorderData(show: false),
                barGroups: data.asMap().entries.map((entry) {
                  final index = entry.key;
                  final item = entry.value;
                  final rawValue = metric == 'nodes' ? item.avgNodes : item.avgTime;
                  final maxY = _getMaxY();
                  
                  // If value is 0, don't show a bar. 
                  // If it's small, ensure it's at least 5% of maxY for visibility
                  final visualValue = rawValue > 0 ? (rawValue < maxY * 0.05 ? maxY * 0.05 : rawValue) : 0.0;

                  return BarChartGroupData(
                    x: index,
                    barRods: [
                      BarChartRodData(
                        toY: visualValue,
                        color: _getColorForIndex(index),
                        width: 18,
                        borderRadius: const BorderRadius.vertical(top: Radius.circular(6)),
                        backDrawRodData: BackgroundBarChartRodData(
                          show: rawValue > 0, // Only show background if there's actually data
                          toY: maxY,
                          color: AppTheme.surfaceVariant.withValues(alpha: 0.15), // More subtle background
                        ),
                      ),
                    ],
                  );
                }).toList(),
              ),
              duration: const Duration(milliseconds: 800),
              curve: Curves.easeOutQuart,
            ),
          ),
          const SizedBox(height: 16),
          Wrap(
            spacing: 12,
            runSpacing: 8,
            children: data.asMap().entries.map((entry) {
              return _LegendItem(
                label: entry.value.algorithm,
                color: _getColorForIndex(entry.key),
              );
            }).toList(),
          ),
        ],
      ),
    );
  }

  double _getMaxY() {
    if (data.isEmpty) return 100;
    final maxVal = data.map((e) => metric == 'nodes' ? e.avgNodes : e.avgTime).reduce((a, b) => a > b ? a : b);
    return maxVal < 10 ? 10.0 : maxVal * 1.2;
  }

  Color _getColorForIndex(int index) {
    final colors = [
      AppTheme.accent,
      AppTheme.cyan,
      AppTheme.success,
      AppTheme.warning,
      AppTheme.error,
      const Color(0xFF9D50BB), // Purple
      const Color(0xFF6E48AA), // Deep Purple
      const Color(0xFF2193b0), // Blue
    ];
    return colors[index % colors.length];
  }
}

class _LegendItem extends StatelessWidget {
  final String label;
  final Color color;
  const _LegendItem({required this.label, required this.color});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 10,
          height: 10,
          decoration: BoxDecoration(
            color: color,
            shape: BoxShape.circle,
          ),
        ),
        const SizedBox(width: 6),
        Text(
          label,
          style: const TextStyle(fontSize: 10, color: AppTheme.textMuted),
        ),
      ],
    );
  }
}
