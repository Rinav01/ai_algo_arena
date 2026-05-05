import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:algo_arena/core/app_theme.dart';
import 'package:algo_arena/models/analytics_models.dart';
import 'package:algo_arena/state/analytics_provider.dart';
import 'package:algo_arena/widgets/analytics/analytics_skeleton.dart';

class ComplexityTabContent extends ConsumerWidget {
  const ComplexityTabContent({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final complexityAsync = ref.watch(complexityProvider);

    return RefreshIndicator(
      onRefresh: () async => ref.invalidate(complexityProvider),
      color: AppTheme.accent,
      backgroundColor: AppTheme.surfaceHigh,
      child: CustomScrollView(
        physics: const BouncingScrollPhysics(),
        slivers: [
          complexityAsync.when(
            loading: () => const SliverFillRemaining(child: AnalyticsSkeleton()),
            error: (err, stack) => SliverFillRemaining(
              child: Center(
                child: Text('Error loading complexity data: $err', style: const TextStyle(color: AppTheme.error)),
              ),
            ),
            data: (res) {
              if (res.data.isEmpty) {
                return const SliverFillRemaining(
                  child: Center(child: Text('No complexity data available yet.')),
                );
              }

              return SliverPadding(
                padding: const EdgeInsets.all(20),
                sliver: SliverList(
                  delegate: SliverChildListDelegate([
                    _SectionHeader(label: "BIG-O HEURISTIC COMPLEXITY"),
                    const SizedBox(height: 8),
                    Text(
                      "Time complexity vs Obstacle Density. Spot exponential explosion visually.",
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(color: AppTheme.textMuted),
                    ),
                    const SizedBox(height: 16),
                    _ComplexityScatterPlot(data: res.data),
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

class _ComplexityScatterPlot extends StatelessWidget {
  final List<ComplexityDataPoint> data;

  const _ComplexityScatterPlot({required this.data});

  @override
  Widget build(BuildContext context) {
    // Group by algorithm to assign distinct colors
    final algoColors = <String, Color>{
      'BFS': AppTheme.cyan,
      'DFS': AppTheme.warning,
      'A*': AppTheme.success,
      'Dijkstra': AppTheme.accent,
      'Greedy': AppTheme.error,
    };

    return Container(
      height: (MediaQuery.sizeOf(context).height * 0.45).clamp(300.0, 500.0),
      padding: const EdgeInsets.all(20),
      decoration: AppTheme.glassCard(radius: 20),
      child: Column(
        children: [
          Expanded(
            child: ScatterChart(
              ScatterChartData(
                scatterSpots: data.map((point) {
                  return ScatterSpot(
                    point.obstacleDensity,
                    point.durationMs,
                    dotPainter: FlDotCirclePainter(
                      color: (algoColors[point.algorithm] ?? AppTheme.accentLight).withValues(alpha: 0.6),
                      radius: 4,
                    ),
                  );
                }).toList(),
                minX: 0,
                maxX: 1, // Density 0 to 1
                minY: 0,
                gridData: FlGridData(
                  show: true,
                  drawVerticalLine: true,
                  getDrawingHorizontalLine: (value) => FlLine(
                    color: Colors.white.withValues(alpha: 0.1),
                    strokeWidth: 1,
                  ),
                  getDrawingVerticalLine: (value) => FlLine(
                    color: Colors.white.withValues(alpha: 0.1),
                    strokeWidth: 1,
                  ),
                ),
                titlesData: FlTitlesData(
                  show: true,
                  bottomTitles: AxisTitles(
                    axisNameWidget: const Padding(
                      padding: EdgeInsets.only(top: 8.0),
                      child: Text('Obstacle Density (%)', style: TextStyle(color: AppTheme.textMuted, fontSize: 10)),
                    ),
                    sideTitles: SideTitles(
                      showTitles: true,
                      reservedSize: 40,
                      getTitlesWidget: (value, meta) {
                        return Text('${(value * 100).toInt()}%', style: const TextStyle(color: AppTheme.textMuted, fontSize: 10));
                      },
                    ),
                  ),
                  leftTitles: AxisTitles(
                    axisNameWidget: const Text('Time (ms)', style: TextStyle(color: AppTheme.textMuted, fontSize: 10)),
                    sideTitles: SideTitles(
                      showTitles: true,
                      reservedSize: 50,
                      getTitlesWidget: (value, meta) {
                        return Text('${value.toInt()}', style: const TextStyle(color: AppTheme.textMuted, fontSize: 10));
                      },
                    ),
                  ),
                  rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                  topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                ),
                borderData: FlBorderData(show: false),
                scatterTouchData: ScatterTouchData(
                  enabled: true,
                  touchTooltipData: ScatterTouchTooltipData(
                    getTooltipColor: (_) => AppTheme.surfaceHigh,
                    getTooltipItems: (touchedSpot) {
                      final point = data.firstWhere(
                        (p) => p.obstacleDensity == touchedSpot.x && p.durationMs == touchedSpot.y,
                        orElse: () => data.first,
                      );
                      return ScatterTooltipItem(
                        '${point.algorithm}\n',
                        textStyle: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                        children: [
                          TextSpan(
                            text: 'Heuristic: ${point.heuristic ?? 'None'}\n',
                            style: const TextStyle(color: AppTheme.textMuted, fontWeight: FontWeight.normal, fontSize: 12),
                          ),
                          TextSpan(
                            text: 'Density: ${(point.obstacleDensity * 100).toStringAsFixed(1)}%\n',
                            style: const TextStyle(color: AppTheme.textMuted, fontWeight: FontWeight.normal, fontSize: 12),
                          ),
                          TextSpan(
                            text: 'Time: ${point.durationMs.toStringAsFixed(1)}ms',
                            style: const TextStyle(color: AppTheme.accentLight, fontWeight: FontWeight.normal, fontSize: 12),
                          ),
                        ],
                      );
                    },
                  ),
                ),
              ),
            ),
          ),
          const SizedBox(height: 16),
          // Legend
          Wrap(
            spacing: 16,
            runSpacing: 8,
            alignment: WrapAlignment.center,
            children: algoColors.entries.map((entry) {
              return Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    width: 12,
                    height: 12,
                    decoration: BoxDecoration(
                      color: entry.value,
                      shape: BoxShape.circle,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    entry.key,
                    style: const TextStyle(color: AppTheme.textMuted, fontSize: 12),
                  ),
                ],
              );
            }).toList(),
          ),
        ],
      ),
    );
  }
}
