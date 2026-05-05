import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:algo_arena/core/app_theme.dart';
import 'package:algo_arena/models/analytics_models.dart';

class DistributionPieChart extends StatefulWidget {
  final List<DistributionData> data;

  const DistributionPieChart({super.key, required this.data});

  @override
  State<DistributionPieChart> createState() => _DistributionPieChartState();
}

class _DistributionPieChartState extends State<DistributionPieChart> {
  int touchedIndex = -1;

  @override
  Widget build(BuildContext context) {
    if (widget.data.isEmpty) return const SizedBox.shrink();

    return Container(
      height: (MediaQuery.sizeOf(context).height * 0.35).clamp(250.0, 400.0),
      padding: const EdgeInsets.all(20),
      decoration: AppTheme.glassCard(radius: 20),
      child: Row(
        children: [
          Expanded(
            flex: 2,
            child: PieChart(
              PieChartData(
                pieTouchData: PieTouchData(
                  touchCallback: (FlTouchEvent event, pieTouchResponse) {
                    setState(() {
                      if (!event.isInterestedForInteractions ||
                          pieTouchResponse == null ||
                          pieTouchResponse.touchedSection == null) {
                        touchedIndex = -1;
                        return;
                      }
                      touchedIndex = pieTouchResponse.touchedSection!.touchedSectionIndex;
                    });
                  },
                ),
                borderData: FlBorderData(show: false),
                sectionsSpace: 4,
                centerSpaceRadius: 40,
                sections: widget.data.asMap().entries.map((entry) {
                  final index = entry.key;
                  final item = entry.value;
                  final isTouched = index == touchedIndex;
                  final fontSize = isTouched ? 16.0 : 12.0;
                  final radius = isTouched ? 70.0 : 60.0;

                  return PieChartSectionData(
                    color: _getColorForIndex(index),
                    value: item.percentage,
                    title: isTouched ? '${item.percentage.toStringAsFixed(1)}%' : '',
                    radius: radius,
                    titleStyle: TextStyle(
                      fontSize: fontSize,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  );
                }).toList(),
              ),
            ),
          ),
          const SizedBox(width: 20),
          Expanded(
            flex: 1,
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: widget.data.asMap().entries.map((entry) {
                final index = entry.key;
                final item = entry.value;
                return Padding(
                  padding: const EdgeInsets.symmetric(vertical: 4.0),
                  child: Row(
                    children: [
                      Container(
                        width: 12,
                        height: 12,
                        decoration: BoxDecoration(
                          color: _getColorForIndex(index),
                          shape: BoxShape.circle,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          item.algorithm,
                          style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                color: touchedIndex == index ? Colors.white : AppTheme.textMuted,
                                fontWeight: touchedIndex == index ? FontWeight.bold : FontWeight.normal,
                              ),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                );
              }).toList(),
            ),
          ),
        ],
      ),
    );
  }

  Color _getColorForIndex(int index) {
    final colors = [AppTheme.accent, AppTheme.cyan, AppTheme.success, AppTheme.warning, AppTheme.accentLight];
    return colors[index % colors.length];
  }
}
