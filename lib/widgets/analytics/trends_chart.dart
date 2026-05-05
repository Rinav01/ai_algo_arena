import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:algo_arena/core/app_theme.dart';
import 'package:algo_arena/models/analytics_models.dart';
import 'package:algo_arena/services/api_service.dart';

class TrendsLineChart extends StatelessWidget {
  final List<TrendData> data;
  final String metric;

  const TrendsLineChart({super.key, required this.data, required this.metric});

  @override
  Widget build(BuildContext context) {
    if (data.isEmpty) return const SizedBox.shrink();

    return Container(
      height: (MediaQuery.sizeOf(context).height * 0.4).clamp(300.0, 450.0),
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
                    style: Theme.of(
                      context,
                    ).textTheme.labelSmall?.copyWith(color: AppTheme.textMuted),
                  ),
                ],
              ),
              // Legend
              Wrap(
                spacing: 12,
                runSpacing: 8,
                children: data.asMap().entries
                    .map((entry) => _LegendItem(
                      label: entry.value.algorithm, 
                      color: _getColorForIndex(entry.key),
                    ))
                    .toList(),
              ),
            ],
          ),
          const SizedBox(height: 32),
          Expanded(
            child: LineChart(
              LineChartData(
                lineTouchData: LineTouchData(
                  touchCallback:
                      (FlTouchEvent event, LineTouchResponse? touchResponse) {
                        if (event is FlTapUpEvent &&
                            touchResponse != null &&
                            touchResponse.lineBarSpots != null &&
                            touchResponse.lineBarSpots!.isNotEmpty) {
                          final spot = touchResponse.lineBarSpots!.first;
                          final date =
                              data[spot.barIndex].points[spot.spotIndex].date;
                          _showTopRunsBottomSheet(context, date);
                        }
                      },
                  touchTooltipData: LineTouchTooltipData(
                    getTooltipColor: (_) => AppTheme.surfaceHigh,
                    getTooltipItems: (touchedSpots) {
                      return touchedSpots.map((spot) {
                        return LineTooltipItem(
                          "${data[spot.barIndex].algorithm}\n",
                          const TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                            fontSize: 12,
                          ),
                          children: [
                            TextSpan(
                              text: spot.y.toStringAsFixed(1),
                              style: const TextStyle(
                                color: AppTheme.accentLight,
                              ),
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
                  rightTitles: const AxisTitles(
                    sideTitles: SideTitles(showTitles: false),
                  ),
                  topTitles: const AxisTitles(
                    sideTitles: SideTitles(showTitles: false),
                  ),
                  bottomTitles: AxisTitles(
                    axisNameWidget: const Text(
                      'BATTLE HISTORY',
                      style: TextStyle(color: AppTheme.textMuted, fontSize: 10, fontWeight: FontWeight.bold, letterSpacing: 1.2),
                    ),
                    axisNameSize: 20,
                    sideTitles: SideTitles(
                      showTitles: true,
                      reservedSize: 30,
                      interval: 1,
                      getTitlesWidget: (value, meta) {
                        return const SizedBox.shrink();
                      },
                    ),
                  ),
                  leftTitles: AxisTitles(
                    axisNameWidget: Text(
                      metric.toUpperCase().replaceAll('_', ' '),
                      style: const TextStyle(color: AppTheme.textMuted, fontSize: 10, fontWeight: FontWeight.bold, letterSpacing: 1.2),
                    ),
                    axisNameSize: 24,
                    sideTitles: SideTitles(
                      showTitles: true,
                      reservedSize: 42,
                      getTitlesWidget: (value, meta) {
                        return Text(
                          value.toInt().toString(),
                          style: const TextStyle(
                            color: AppTheme.textMuted,
                            fontSize: 10,
                          ),
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
                    dotData: const FlDotData(show: true),
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
    final colors = [
      AppTheme.accent,
      AppTheme.cyan,
      AppTheme.success,
      AppTheme.warning,
    ];
    return colors[index % colors.length];
  }

  void _showTopRunsBottomSheet(BuildContext context, DateTime date) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (context) => _TopRunsSheet(date: date),
    );
  }
}

class _TopRunsSheet extends StatefulWidget {
  final DateTime date;
  const _TopRunsSheet({required this.date});

  @override
  State<_TopRunsSheet> createState() => _TopRunsSheetState();
}

class _TopRunsSheetState extends State<_TopRunsSheet> {
  late Future<List<dynamic>> _runsFuture;

  @override
  void initState() {
    super.initState();
    final dateStr = widget.date.toIso8601String().substring(0, 10);
    // Use getRuns with sort and date to fetch top 3 longest runs
    _runsFuture = ApiService().getRuns(
      limit: 3,
      sort: '-durationMs',
      date: dateStr,
    );
  }

  @override
  Widget build(BuildContext context) {
    final dateFormatted =
        "${widget.date.year}-${widget.date.month.toString().padLeft(2, '0')}-${widget.date.day.toString().padLeft(2, '0')}";

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: const BoxDecoration(
        color: AppTheme.surfaceHigh,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: AppTheme.textMuted.withValues(alpha: 0.3),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            const SizedBox(height: 24),
            Text(
              "Top 3 Longest Runs",
              style: Theme.of(
                context,
              ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 4),
            Text(
              "Date: $dateFormatted",
              style: Theme.of(
                context,
              ).textTheme.bodyMedium?.copyWith(color: AppTheme.accentLight),
            ),
            const SizedBox(height: 20),
            FutureBuilder<List<dynamic>>(
              future: _runsFuture,
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(
                    child: Padding(
                      padding: EdgeInsets.all(40.0),
                      child: CircularProgressIndicator(color: AppTheme.accent),
                    ),
                  );
                }
                if (snapshot.hasError) {
                  return Center(
                    child: Padding(
                      padding: const EdgeInsets.all(20.0),
                      child: Text(
                        "Error: ${snapshot.error}",
                        style: const TextStyle(color: AppTheme.error),
                      ),
                    ),
                  );
                }

                final runs = snapshot.data ?? [];
                if (runs.isEmpty) {
                  return const Center(
                    child: Padding(
                      padding: EdgeInsets.all(40.0),
                      child: Text(
                        "No runs found for this date.",
                        style: TextStyle(color: AppTheme.textMuted),
                      ),
                    ),
                  );
                }

                return ListView.separated(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: runs.length,
                  separatorBuilder: (context, index) =>
                      const SizedBox(height: 12),
                  itemBuilder: (context, index) {
                    final run = runs[index];
                    final duration = run['durationMs'] ?? 0;
                    final algorithm = run['algorithm'] ?? 'Unknown';
                    final nodes = run['metrics']?['nodesVisited'] ?? 0;

                    return Container(
                      decoration: AppTheme.glassCard(radius: 12),
                      clipBehavior: Clip.antiAlias,
                      child: Material(
                        color: Colors.transparent,
                        child: InkWell(
                          onTap: () {
                            debugPrint(
                              "Replay Card Tapped! Navigating to /replay",
                            );
                            // Safely pop bottom sheet then push replay
                            final navigator = Navigator.of(context);
                            navigator.pop();
                            navigator.pushNamed('/replay', arguments: run);
                          },
                          child: Padding(
                            padding: const EdgeInsets.all(16),
                            child: Row(
                              children: [
                                Container(
                                  padding: const EdgeInsets.all(12),
                                  decoration: BoxDecoration(
                                    color: AppTheme.accent.withValues(
                                      alpha: 0.1,
                                    ),
                                    shape: BoxShape.circle,
                                  ),
                                  child: const Icon(
                                    Icons.play_arrow_rounded,
                                    color: AppTheme.accent,
                                  ),
                                ),
                                const SizedBox(width: 16),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        algorithm,
                                        style: const TextStyle(
                                          fontWeight: FontWeight.bold,
                                          fontSize: 16,
                                        ),
                                      ),
                                      const SizedBox(height: 4),
                                      Text(
                                        "$nodes nodes visited",
                                        style: const TextStyle(
                                          color: AppTheme.textMuted,
                                          fontSize: 12,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                Column(
                                  crossAxisAlignment: CrossAxisAlignment.end,
                                  children: [
                                    Text(
                                      "${duration.toStringAsFixed(1)}ms",
                                      style: const TextStyle(
                                        color: AppTheme.accentLight,
                                        fontWeight: FontWeight.bold,
                                        fontSize: 16,
                                      ),
                                    ),
                                    const SizedBox(height: 4),
                                    Text(
                                      "Rank #${index + 1}",
                                      style: const TextStyle(
                                        color: AppTheme.textMuted,
                                        fontSize: 10,
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    );
                  },
                );
              },
            ),
          ],
        ),
      ),
    );
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
          width: 8,
          height: 8,
          decoration: BoxDecoration(
            color: color,
            shape: BoxShape.circle,
          ),
        ),
        const SizedBox(width: 4),
        Text(
          label,
          style: const TextStyle(fontSize: 10, color: AppTheme.textMuted),
        ),
      ],
    );
  }
}
