import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:algo_arena/core/app_theme.dart';
import 'package:flutter_animate/flutter_animate.dart';

class PerformanceDetailsModal extends StatelessWidget {
  final List<FlSpot> dataPoints;
  final Color accentColor;

  const PerformanceDetailsModal({
    super.key,
    required this.dataPoints,
    required this.accentColor,
  });

  static void show(BuildContext context, List<FlSpot> dataPoints, Color accentColor) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (context) => PerformanceDetailsModal(
        dataPoints: dataPoints,
        accentColor: accentColor,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final double peakExplored = dataPoints.isEmpty 
        ? 0 
        : dataPoints.map((e) => e.y).reduce((a, b) => a > b ? a : b);
    
    final double totalSteps = dataPoints.isEmpty ? 0 : dataPoints.last.x;

    return Container(
      height: MediaQuery.of(context).size.height * 0.85,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: AppTheme.background.withValues(alpha: 0.95),
        borderRadius: const BorderRadius.vertical(top: Radius.circular(32)),
        border: Border.all(color: Colors.white10),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Center(
            child: Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: Colors.white24,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
          const SizedBox(height: 24),
          Expanded(
            child: SingleChildScrollView(
              physics: const BouncingScrollPhysics(),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: accentColor.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Icon(Icons.analytics_rounded, color: accentColor),
                      ),
                      const SizedBox(width: 16),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'COMPUTATIONAL INSIGHTS',
                            style: AppTheme.labelStyle.copyWith(color: accentColor),
                          ),
                          Text(
                            'Algorithm Efficiency',
                            style: AppTheme.titleStyle.copyWith(fontSize: 20),
                          ),
                        ],
                      ),
                    ],
                  ),
                  const SizedBox(height: 32),
                  SizedBox(
                    height: (MediaQuery.sizeOf(context).height * 0.35).clamp(250.0, 400.0),
                    child: LineChart(
                      LineChartData(
                        gridData: FlGridData(
                          show: true,
                          getDrawingHorizontalLine: (value) => FlLine(
                            color: Colors.white.withValues(alpha: 0.05),
                            strokeWidth: 1,
                          ),
                        ),
                        titlesData: FlTitlesData(
                          leftTitles: AxisTitles(
                            sideTitles: SideTitles(
                              showTitles: true,
                              reservedSize: 40,
                              getTitlesWidget: (v, m) => Text(
                                v.toInt().toString(),
                                style: const TextStyle(color: Colors.white24, fontSize: 10),
                              ),
                            ),
                          ),
                          bottomTitles: AxisTitles(
                            sideTitles: SideTitles(
                              showTitles: true,
                              getTitlesWidget: (v, m) => Text(
                                v.toInt().toString(),
                                style: const TextStyle(color: Colors.white24, fontSize: 10),
                              ),
                            ),
                          ),
                          topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                          rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                        ),
                        borderData: FlBorderData(show: false),
                        lineBarsData: [
                          LineChartBarData(
                            spots: dataPoints,
                            isCurved: true,
                            color: accentColor,
                            barWidth: 4,
                            belowBarData: BarAreaData(
                              show: true,
                              gradient: LinearGradient(
                                begin: Alignment.topCenter,
                                end: Alignment.bottomCenter,
                                colors: [
                                  accentColor.withValues(alpha: 0.3),
                                  accentColor.withValues(alpha: 0.0),
                                ],
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ).animate().fadeIn(duration: 600.ms).scale(begin: const Offset(0.95, 0.95)),
                  const SizedBox(height: 40),
                  Text(
                    'KEY METRICS',
                    style: AppTheme.labelStyle.copyWith(color: Colors.white54),
                  ),
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      _buildMetric('Peak Frontier', peakExplored.toInt().toString(), Icons.vertical_align_top_rounded),
                      const SizedBox(width: 16),
                      _buildMetric('Total Iterations', totalSteps.toInt().toString(), Icons.repeat_rounded),
                    ],
                  ),
                  const SizedBox(height: 32),
                  Text(
                    'ANALYSIS',
                    style: AppTheme.labelStyle.copyWith(color: Colors.white54),
                  ),
                  const SizedBox(height: 12),
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.03),
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: Colors.white10),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            const Icon(Icons.psychology_rounded, color: Colors.amber, size: 18),
                            const SizedBox(width: 8),
                            Text(
                              'Search Characteristics',
                              style: AppTheme.titleStyle.copyWith(fontSize: 14),
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),
                        Text(
                          _generateAnalysis(dataPoints),
                          style: AppTheme.bodyStyle.copyWith(fontSize: 14, color: Colors.white70),
                        ),
                      ],
                    ),
                  ).animate().slideY(begin: 0.1, duration: 400.ms),
                ],
              ),
            ),
          ),
          const SizedBox(height: 24),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: () => Navigator.pop(context),
              style: AppTheme.primaryButton(),
              child: const Text('CLOSE'),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMetric(String label, String value, IconData icon) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: 0.03),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: Colors.white10),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(icon, color: Colors.white38, size: 16),
            const SizedBox(height: 12),
            Text(value, style: AppTheme.titleStyle.copyWith(fontSize: 24)),
            Text(label, style: AppTheme.labelStyle.copyWith(fontSize: 10, color: Colors.white38)),
          ],
        ),
      ),
    );
  }

  String _generateAnalysis(List<FlSpot> points) {
    if (points.length < 2) return "Insufficient data for analysis.";
    
    final last = points.last;
    final ratio = last.y / last.x;

    if (ratio > 1.5) {
      return "The algorithm is exploring significantly more states than necessary for the path. This suggests high branching or many obstacles.";
    } else if (ratio < 0.5) {
      return "Highly efficient search path. The algorithm is targeting the goal with minimal redundant exploration.";
    } else {
      return "Balanced search pattern. Consistent expansion of the search frontier relative to the steps taken.";
    }
  }
}
