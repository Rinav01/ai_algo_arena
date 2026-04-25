import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:algo_arena/core/app_theme.dart';
import 'package:algo_arena/models/analytics_models.dart';
import 'package:intl/intl.dart';

class TrendsLineChart extends StatelessWidget {
  final List<TrendData> data;
  final String metric;

  const TrendsLineChart({super.key, required this.data, required this.metric});

  @override
  Widget build(BuildContext context) {
    if (data.isEmpty) return const SizedBox.shrink();

    return Container(
      height: 350,
      padding: const EdgeInsets.all(20),
      decoration: AppTheme.glassCard(radius: 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    "Performance Trends",
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                          fontFamily: 'SpaceGrotesk',
                          fontWeight: FontWeight.bold,
                        ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    "Metric: ${metric.toUpperCase()}",
                    style: Theme.of(context).textTheme.labelSmall?.copyWith(color: AppTheme.textMuted),
                  ),
                ],
              ),
              // Legend
              Wrap(
                spacing: 12,
                children: data.map((d) => _LegendItem(label: d.algorithm)).toList(),
              ),
            ],
          ),
          const SizedBox(height: 32),
          Expanded(
            child: LineChart(
              LineChartData(
                lineTouchData: LineTouchData(
                  touchTooltipData: LineTouchTooltipData(
                    getTooltipColor: (_) => AppTheme.surfaceHigh,
                    getTooltipItems: (touchedSpots) {
                      return touchedSpots.map((spot) {
                        return LineTooltipItem(
                          "${data[spot.barIndex].algorithm}\n",
                          const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 12),
                          children: [
                            TextSpan(
                              text: spot.y.toStringAsFixed(1),
                              style: const TextStyle(color: AppTheme.accentLight),
                            ),
                          ],
                        );
                      }).toList();
                    },
                  ),
                ),
                gridData: FlGridData(
                  show: true,
                  drawVerticalLine: false,
                  getDrawingHorizontalLine: (value) => FlLine(
                    color: Colors.white.withValues(alpha: 0.05),
                    strokeWidth: 1,
                  ),
                ),
                titlesData: FlTitlesData(
                  show: true,
                  rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                  topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                  bottomTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      reservedSize: 30,
                      interval: 1,
                      getTitlesWidget: (value, meta) {
                        // Assuming X is time, simplify labels
                        return const SizedBox.shrink(); 
                      },
                    ),
                  ),
                  leftTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      reservedSize: 42,
                      getTitlesWidget: (value, meta) {
                        return Text(
                          value.toInt().toString(),
                          style: const TextStyle(color: AppTheme.textMuted, fontSize: 10),
                        );
                      },
                    ),
                  ),
                ),
                borderData: FlBorderData(show: false),
                lineBarsData: data.asMap().entries.map((entry) {
                  final index = entry.key;
                  final trend = entry.value;
                  return LineChartBarData(
                    spots: trend.points.asMap().entries.map((pEntry) {
                      return FlSpot(pEntry.key.toDouble(), pEntry.value.value);
                    }).toList(),
                    isCurved: true,
                    gradient: LinearGradient(
                      colors: [
                        _getColorForIndex(index),
                        _getColorForIndex(index).withValues(alpha: 0.5),
                      ],
                    ),
                    barWidth: 3,
                    isStrokeCapRound: true,
                    dotData: const FlDotData(show: false),
                    belowBarData: BarAreaData(
                      show: true,
                      gradient: LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: [
                          _getColorForIndex(index).withValues(alpha: 0.2),
                          _getColorForIndex(index).withValues(alpha: 0),
                        ],
                      ),
                    ),
                  );
                }).toList(),
              ),
              duration: const Duration(milliseconds: 1000),
              curve: Curves.easeInOut,
            ),
          ),
        ],
      ),
    );
  }

  Color _getColorForIndex(int index) {
    final colors = [AppTheme.accent, AppTheme.cyan, AppTheme.success, AppTheme.warning];
    return colors[index % colors.length];
  }
}

class _LegendItem extends StatelessWidget {
  final String label;
  const _LegendItem({required this.label});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 8,
          height: 8,
          decoration: const BoxDecoration(color: AppTheme.accent, shape: BoxShape.circle),
        ),
        const SizedBox(width: 4),
        Text(label, style: const TextStyle(fontSize: 10, color: AppTheme.textMuted)),
      ],
    );
  }
}
