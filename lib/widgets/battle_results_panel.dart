import 'package:flutter/material.dart';
import 'package:algo_arena/core/app_theme.dart';
import 'package:algo_arena/services/battle_analyzer.dart';
import 'package:flutter_animate/flutter_animate.dart';

class BattleResultsPanel extends StatefulWidget {
  final AlgorithmMetrics? algorithmAMetrics;
  final AlgorithmMetrics? algorithmBMetrics;
  final String algorithmAName;
  final String algorithmBName;
  final bool isLoading;

  const BattleResultsPanel({
    super.key,
    this.algorithmAMetrics,
    this.algorithmBMetrics,
    this.algorithmAName = 'Algorithm A',
    this.algorithmBName = 'Algorithm B',
    this.isLoading = false,
  });

  @override
  State<BattleResultsPanel> createState() => _BattleResultsPanelState();
}

class _BattleResultsPanelState extends State<BattleResultsPanel>
    with SingleTickerProviderStateMixin {
  late AnimationController _animationController;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 1200),
      vsync: this,
    );
    if (!widget.isLoading && widget.algorithmAMetrics != null) {
      _animationController.forward();
    }
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  @override
  void didUpdateWidget(BattleResultsPanel oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (!widget.isLoading &&
        widget.algorithmAMetrics != null &&
        oldWidget.isLoading) {
      _animationController.forward(from: 0.0);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (widget.isLoading || widget.algorithmAMetrics == null) {
      return const SizedBox.shrink();
    }

    final metricsA = widget.algorithmAMetrics!;
    final metricsB = widget.algorithmBMetrics!;
    final result = BattleResult(algorithm1: metricsA, algorithm2: metricsB);
    final isAWinner = result.winner == metricsA;

    return FadeTransition(
      opacity: _animationController,
      child: SlideTransition(
        position: Tween<Offset>(begin: const Offset(0, 0.1), end: Offset.zero)
            .animate(
              CurvedAnimation(
                parent: _animationController,
                curve: Curves.easeOutCubic,
              ),
            ),
        child: Container(
          decoration: AppTheme.glassCardAccent(radius: 20),
          child: Column(
            children: [
              // 🏆 Elite Winner Banner
              _buildWinnerBanner(result, isAWinner),

              Padding(
                padding: EdgeInsets.all(20.0),
                child: Column(
                  children: [
                    // Comparison Grid
                    _buildMetricsComparison(metricsA, metricsB, isAWinner),

                    const SizedBox(height: 20),

                    // Efficiency Bar
                    _buildEfficiencyBar(metricsA, metricsB),

                    const SizedBox(height: 24),

                    // Analysis Report
                    _buildAnalysisBox(result),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildWinnerBanner(BattleResult result, bool isAWinner) {
    return Container(
      width: double.infinity,
      padding: EdgeInsets.symmetric(vertical: 20.0),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            AppTheme.success.withValues(alpha: 0.3),
            AppTheme.success.withValues(alpha: 0.05),
          ],
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
        ),
        borderRadius: BorderRadius.only(
          topLeft: Radius.circular(20.0),
          topRight: Radius.circular(20.0),
        ),
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Text('🏆', style: TextStyle(fontSize: 28)),
              const SizedBox(width: 12),
              Text(
                '${result.winner.algorithmName} WINS BY ${result.victoryMargin.toStringAsFixed(1)}%',
                style: TextStyle(
                  color: AppTheme.success,
                  fontWeight: FontWeight.w900,
                  fontSize: 18.0,
                  letterSpacing: 2,
                ),
              ),
              const SizedBox(width: 12),
              const Text('🏆', style: TextStyle(fontSize: 28)),
            ],
          ),
          const SizedBox(height: 4),
          Text(
            'Margin calculated based on nodes explored efficiency',
            style: Theme.of(
              context,
            ).textTheme.bodySmall?.copyWith(color: AppTheme.textMuted),
          ),
        ],
      ),
    );
  }

  Widget _buildMetricsComparison(
    AlgorithmMetrics a,
    AlgorithmMetrics b,
    bool isAWinner,
  ) {
    return Column(
      children: [
        _buildMetricRow(
          'Nodes Explored',
          a.exploredStates.length.toString(),
          b.exploredStates.length.toString(),
          isAWinner,
        ),
        const SizedBox(height: 12),
        _buildMetricRow(
          'Path Length',
          a.path.length.toString(),
          b.path.length.toString(),
          a.path.length <= b.path.length,
        ),
        const SizedBox(height: 12),
        _buildMetricRow(
          'Efficiency',
          a.efficiencyScore.toStringAsFixed(2),
          b.efficiencyScore.toStringAsFixed(2),
          isAWinner,
        ),
        const SizedBox(height: 12),
        _buildMetricRow(
          'Time',
          '${a.executionTime.inMilliseconds}ms',
          '${b.executionTime.inMilliseconds}ms',
          a.executionTime < b.executionTime,
        ),
      ],
    );
  }

  Widget _buildMetricRow(
    String label,
    String valA,
    String valB,
    bool preferredA,
  ) {
    return Row(
      children: [
        Expanded(
          flex: 2,
          child: Text(
            label,
            style: Theme.of(
              context,
            ).textTheme.bodyMedium?.copyWith(color: AppTheme.textMuted),
          ),
        ),
        Expanded(
          child: _buildValueBox(valA, preferredA, widget.algorithmAName),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: _buildValueBox(valB, !preferredA, widget.algorithmBName),
        ),
      ],
    );
  }

  Widget _buildValueBox(String value, bool isBetter, String algo) {
    final color = isBetter ? AppTheme.success : AppTheme.textMuted;
    return Container(
      padding: EdgeInsets.symmetric(vertical: 8.0, horizontal: 4.0),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(8.0),
        border: Border.all(color: color.withValues(alpha: 0.2)),
        boxShadow: isBetter
            ? [
                BoxShadow(
                  color: AppTheme.success.withValues(alpha: 0.1),
                  blurRadius: 8,
                  spreadRadius: -2,
                ),
              ]
            : null,
      ),
      child: Center(
        child: Text(
          value,
          style: TextStyle(
            color: isBetter ? Colors.white : AppTheme.textMuted,
            fontWeight: isBetter ? FontWeight.bold : FontWeight.normal,
            fontSize: 14.0,
          ),
        ),
      ),
    );
  }

  Widget _buildEfficiencyBar(AlgorithmMetrics a, AlgorithmMetrics b) {
    final scoreA = a.efficiencyScore;
    final scoreB = b.efficiencyScore;
    final total = scoreA + scoreB;
    final flexA = (scoreA / (total != 0 ? total : 1) * 100).round();
    final flexB = 100 - flexA;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'EFFICIENCY SCORE COMPARISON',
          style: Theme.of(context).textTheme.labelSmall?.copyWith(
            letterSpacing: 1.5,
            color: AppTheme.textMuted,
          ),
        ),
        const SizedBox(height: 8),
        ClipRRect(
          borderRadius: BorderRadius.circular(4.0),
          child: SizedBox(
            height: 8.0,
            child: Row(
              children: [
                Expanded(
                  flex: flexA,
                  child: Container(color: AppTheme.accent),
                ),
                Expanded(
                  flex: flexB,
                  child: Container(color: AppTheme.error),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 6),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              '${widget.algorithmAName}: $flexA%',
              style: TextStyle(
                color: AppTheme.accent,
                fontSize: 10.0,
                fontWeight: FontWeight.bold,
              ),
            ),
            Text(
              '${widget.algorithmBName}: $flexB%',
              style: TextStyle(
                color: AppTheme.error,
                fontSize: 10.0,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildAnalysisBox(BattleResult result) {
    final insights = result.getAnalysisInsights();

    return Container(
      width: double.infinity,
      padding: EdgeInsets.all(20.0),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.03),
        borderRadius: BorderRadius.circular(20.0),
        border: Border.all(color: AppTheme.accent.withValues(alpha: 0.15)),
        boxShadow: [
          BoxShadow(
            color: AppTheme.accent.withValues(alpha: 0.05),
            blurRadius: 20,
            spreadRadius: -5,
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: EdgeInsets.all(6.0),
                decoration: BoxDecoration(
                  color: AppTheme.accent.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(8.0),
                ),
                child: Icon(
                  Icons.insights_rounded,
                  size: 18.0,
                  color: AppTheme.accent,
                ),
              ),
              const SizedBox(width: 12),
              Text(
                'STRATEGIC ANALYSIS',
                style: Theme.of(context).textTheme.labelLarge?.copyWith(
                  color: AppTheme.accent,
                  fontWeight: FontWeight.w800,
                  letterSpacing: 1.2,
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          ...List.generate(insights.length, (index) {
            final insight = insights[index];
            return Padding(
              padding: EdgeInsets.only(
                bottom: index == insights.length - 1 ? 0 : 16.0,
              ),
              child:
                  Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Container(
                            margin: EdgeInsets.only(top: 2.0),
                            child: Icon(
                              insight.icon,
                              size: 16.0,
                              color: _getInsightColor(insight.type),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Text(
                              insight.text,
                              style: Theme.of(context).textTheme.bodyMedium
                                  ?.copyWith(
                                    color: Colors.white.withValues(alpha: 0.85),
                                    height: 1.4,
                                  ),
                            ),
                          ),
                        ],
                      )
                      .animate()
                      .fadeIn(duration: 400.ms, delay: (200 + (index * 150)).ms)
                      .slideX(begin: 0.05, curve: Curves.easeOutQuad),
            );
          }),
        ],
      ),
    );
  }

  Color _getInsightColor(InsightType type) {
    switch (type) {
      case InsightType.winner:
        return Color(0xFFA855F7); // Purple
      case InsightType.success:
        return AppTheme.success;
      case InsightType.parity:
        return AppTheme.accent;
      case InsightType.info:
        return Colors.blueAccent;
    }
  }
}
