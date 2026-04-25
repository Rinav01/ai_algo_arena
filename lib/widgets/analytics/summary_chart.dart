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
            style: Theme.of(context).textTheme.labelSmall?.copyWith(color: AppTheme.textMuted),
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
                      return BarTooltipItem(
                        "${data[groupIndex].algorithm}\n",
                        const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                        children: [
                          TextSpan(
                            text: "${rod.toY.toStringAsFixed(1)} ${metric == 'nodes' ? 'nodes' : 'ms'}",
                            style: const TextStyle(color: AppTheme.accentLight),
                          ),
                        ],
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
                        if (value.toInt() < 0 || value.toInt() >= data.length) return const SizedBox.shrink();
                        return Padding(
                          padding: const EdgeInsets.only(top: 8.0),
                          child: Text(
                            data[value.toInt()].algorithm,
                            style: const TextStyle(color: AppTheme.textMuted, fontSize: 10),
                          ),
                        );
                      },
                    ),
                  ),
                  leftTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                  topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                  rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                ),
                gridData: const FlGridData(show: false),
                borderData: FlBorderData(show: false),
                barGroups: data.asMap().entries.map((entry) {
                  final index = entry.key;
                  final item = entry.value;
                  final value = metric == 'nodes' ? item.avgNodes : item.avgTime;

                  return BarChartGroupData(
                    x: index,
                    barRods: [
                      BarChartRodData(
                        toY: value,
                        gradient: AppTheme.ctaGradient,
                        width: 16,
                        borderRadius: const BorderRadius.vertical(top: Radius.circular(6)),
                        backDrawRodData: BackgroundBarChartRodData(
                          show: true,
                          toY: _getMaxY(),
                          color: AppTheme.surfaceVariant.withValues(alpha: 0.3),
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
        ],
      ),
    );
  }

  double _getMaxY() {
    if (data.isEmpty) return 100;
    final maxVal = data.map((e) => metric == 'nodes' ? e.avgNodes : e.avgTime).reduce((a, b) => a > b ? a : b);
    return maxVal * 1.2;
  }
}
