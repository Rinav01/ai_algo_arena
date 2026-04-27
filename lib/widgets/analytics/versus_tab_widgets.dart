import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:algo_arena/core/app_theme.dart';
import 'package:algo_arena/models/analytics_models.dart';
import 'package:algo_arena/state/analytics_provider.dart';
import 'package:algo_arena/widgets/analytics/analytics_skeleton.dart';

class VersusTabContent extends ConsumerWidget {
  const VersusTabContent({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final battleAsync = ref.watch(battleInsightsProvider);

    return RefreshIndicator(
      onRefresh: () async => ref.invalidate(battleInsightsProvider),
      color: AppTheme.accent,
      backgroundColor: AppTheme.surfaceHigh,
      child: CustomScrollView(
        physics: const BouncingScrollPhysics(),
        slivers: [
          battleAsync.when(
            loading: () => const SliverFillRemaining(child: AnalyticsSkeleton()),
            error: (err, stack) => SliverFillRemaining(
              child: Center(
                child: Text('Error loading versus data: $err', style: const TextStyle(color: AppTheme.error)),
              ),
            ),
            data: (battleRes) {
              final battleData = battleRes.battleData;
              if (battleData == null || battleData.winnerDistribution.isEmpty) {
                return const SliverFillRemaining(
                  child: Center(child: Text('No battle data available yet. Run some battles!')),
                );
              }

              return SliverPadding(
                padding: const EdgeInsets.all(20),
                sliver: SliverList(
                  delegate: SliverChildListDelegate([
                    _SectionHeader(label: "WIN RATE DISTRIBUTION"),
                    const SizedBox(height: 16),
                    _WinRatePieChart(data: battleData.winnerDistribution),
                    const SizedBox(height: 32),
                    _SectionHeader(label: "MARGIN OF VICTORY (AVG NODES)"),
                    const SizedBox(height: 16),
                    _MarginOfVictoryBarChart(data: battleData.winnerDistribution),
                    const SizedBox(height: 100),
                  ]),
                ),
              );
            },
          ),
        ],
      ),
    );
  }
}

class _SectionHeader extends StatelessWidget {
  final String label;
  const _SectionHeader({required this.label});

  @override
  Widget build(BuildContext context) {
    return Text(
      label,
      style: Theme.of(context).textTheme.labelSmall?.copyWith(
            color: AppTheme.accentLight,
            letterSpacing: 2,
            fontWeight: FontWeight.bold,
          ),
    );
  }
}

class _WinRatePieChart extends StatefulWidget {
  final List<WinnerStat> data;

  const _WinRatePieChart({required this.data});

  @override
  State<_WinRatePieChart> createState() => _WinRatePieChartState();
}

class _WinRatePieChartState extends State<_WinRatePieChart> {
  int touchedIndex = -1;

  @override
  Widget build(BuildContext context) {
    final total = widget.data.fold<int>(0, (sum, item) => sum + item.count);

    return Container(
      height: 300,
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
                  final percentage = total > 0 ? (item.count / total * 100) : 0.0;

                  return PieChartSectionData(
                    color: _getColorForIndex(index),
                    value: item.count.toDouble(),
                    title: isTouched ? '${percentage.toStringAsFixed(1)}%' : '',
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
                          item.winner,
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
    final colors = [AppTheme.accent, AppTheme.cyan, AppTheme.success, AppTheme.warning, AppTheme.error];
    return colors[index % colors.length];
  }
}

class _MarginOfVictoryBarChart extends StatelessWidget {
  final List<WinnerStat> data;

  const _MarginOfVictoryBarChart({required this.data});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          height: 300,
          padding: const EdgeInsets.all(20),
          decoration: AppTheme.glassCard(radius: 20),
          child: BarChart(
            BarChartData(
              alignment: BarChartAlignment.spaceAround,
              maxY: _getMaxY(),
              barTouchData: BarTouchData(
                enabled: true,
                touchTooltipData: BarTouchTooltipData(
                  getTooltipColor: (_) => AppTheme.surfaceHigh,
                  getTooltipItem: (group, groupIndex, rod, rodIndex) {
                    return BarTooltipItem(
                      '${data[group.x].winner}\n',
                      const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                      children: [
                        TextSpan(
                          text: '${rod.toY.abs().toInt()} nodes saved',
                          style: const TextStyle(color: AppTheme.accentLight, fontWeight: FontWeight.normal),
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
                    'WINNER ALGORITHM',
                    style: TextStyle(color: AppTheme.textMuted, fontSize: 10, fontWeight: FontWeight.bold, letterSpacing: 1.2),
                  ),
                  axisNameSize: 20,
                  sideTitles: SideTitles(
                    showTitles: true,
                    getTitlesWidget: (value, meta) {
                      if (value < 0 || value >= data.length) return const SizedBox.shrink();
                      return Padding(
                        padding: const EdgeInsets.only(top: 4.0),
                        child: Text(
                          data[value.toInt()].winner,
                          style: const TextStyle(color: AppTheme.textMuted, fontSize: 10),
                        ),
                      );
                    },
                    reservedSize: 30,
                  ),
                ),
                leftTitles: AxisTitles(
                  axisNameWidget: const Text(
                    'NODES SAVED',
                    style: TextStyle(color: AppTheme.textMuted, fontSize: 10, fontWeight: FontWeight.bold, letterSpacing: 1.2),
                  ),
                  axisNameSize: 20,
                  sideTitles: SideTitles(
                    showTitles: true,
                    getTitlesWidget: (value, meta) {
                      return Text(
                        value.toInt().toString(),
                        style: const TextStyle(color: AppTheme.textMuted, fontSize: 10),
                      );
                    },
                    reservedSize: 40,
                  ),
                ),
                rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
              ),
              gridData: FlGridData(
                show: true,
                drawVerticalLine: false,
                getDrawingHorizontalLine: (value) => FlLine(
                  color: Colors.white.withValues(alpha: 0.1),
                  strokeWidth: 1,
                ),
              ),
              borderData: FlBorderData(show: false),
              barGroups: data.asMap().entries.map((entry) {
                final index = entry.key;
                final stat = entry.value;
                final margin = stat.avgNodesDiff.abs();
                final maxY = _getMaxY();
                final visualValue = margin > 0 ? (margin < maxY * 0.05 ? maxY * 0.05 : margin) : 0.0;

                return BarChartGroupData(
                  x: index,
                  barRods: [
                    BarChartRodData(
                      toY: visualValue,
                      color: _getColorForIndex(index),
                      width: 16,
                      borderRadius: const BorderRadius.vertical(top: Radius.circular(4)),
                      backDrawRodData: BackgroundBarChartRodData(
                        show: margin > 0,
                        toY: maxY,
                        color: AppTheme.surfaceVariant.withValues(alpha: 0.15),
                      ),
                    ),
                  ],
                );
              }).toList(),
            ),
          ),
        ),
        const SizedBox(height: 16),
        Wrap(
          spacing: 12,
          runSpacing: 8,
          children: data.asMap().entries.map((entry) {
            return Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 10,
                  height: 10,
                  decoration: BoxDecoration(
                    color: _getColorForIndex(entry.key),
                    shape: BoxShape.circle,
                  ),
                ),
                const SizedBox(width: 6),
                Text(
                  entry.value.winner,
                  style: const TextStyle(fontSize: 10, color: AppTheme.textMuted),
                ),
              ],
            );
          }).toList(),
        ),
      ],
    );
  }

  Color _getColorForIndex(int index) {
    final colors = [AppTheme.accent, AppTheme.cyan, AppTheme.success, AppTheme.warning, AppTheme.error];
    return colors[index % colors.length];
  }

  double _getMaxY() {
    double maxVal = 0;
    for (var stat in data) {
      if (stat.avgNodesDiff.abs() > maxVal) maxVal = stat.avgNodesDiff.abs();
    }
    return maxVal < 10 ? 10.0 : maxVal * 1.2; // Add some headroom
  }
}
