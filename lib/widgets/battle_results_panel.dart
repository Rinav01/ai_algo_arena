import 'package:flutter/material.dart';
import '../services/battle_analyzer.dart';

class BattleResultsPanel extends StatefulWidget {
  final AlgorithmMetrics? bfsMetrics;
  final AlgorithmMetrics? dfsMetrics;
  final AlgorithmMetrics? algorithmAMetrics;
  final AlgorithmMetrics? algorithmBMetrics;
  final String algorithmAName;
  final String algorithmBName;
  final bool isLoading;

  const BattleResultsPanel({
    Key? key,
    this.bfsMetrics,
    this.dfsMetrics,
    this.algorithmAMetrics,
    this.algorithmBMetrics,
    this.algorithmAName = 'Algorithm A',
    this.algorithmBName = 'Algorithm B',
    this.isLoading = false,
  }) : super(key: key);

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
      duration: const Duration(milliseconds: 1000),
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
    if (!widget.isLoading && widget.algorithmAMetrics != null) {
      _animationController.forward(from: 0.0);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (widget.isLoading || widget.algorithmAMetrics == null) {
      return const SizedBox.shrink();
    }

    final metricsA = widget.algorithmAMetrics!;
    final metricsB = widget.algorithmBMetrics ?? metricsA;

    final result = BattleResult(algorithm1: metricsA, algorithm2: metricsB);

    return ScaleTransition(
      scale: Tween<double>(begin: 0.8, end: 1.0).animate(
        CurvedAnimation(parent: _animationController, curve: Curves.elasticOut),
      ),
      child: Container(
        margin: const EdgeInsets.all(16),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: const Color(0xFF0E2233),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: const Color(0xFFFFA500), width: 2),
          boxShadow: [
            BoxShadow(
              color: const Color(0xFFFFA500).withValues(alpha: 0.2),
              blurRadius: 12,
              spreadRadius: 2,
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Winner Banner
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    Colors.green.withValues(alpha: 0.3),
                    Colors.green.withValues(alpha: 0.1),
                  ],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: Colors.green.withValues(alpha: 0.5),
                  width: 1,
                ),
              ),
              child: Row(
                children: [
                  const Text('🏆', style: TextStyle(fontSize: 24)),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          '${result.winner.algorithmName} WINS!',
                          style: const TextStyle(
                            color: Colors.green,
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
                          ),
                        ),
                        Text(
                          'Victory Margin: ${result.victoryMargin.toStringAsFixed(1)}%',
                          style: TextStyle(
                            color: Colors.green[300],
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),

            // Metrics Grid
            GridView.count(
              crossAxisCount: 2,
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              mainAxisSpacing: 12,
              crossAxisSpacing: 12,
              childAspectRatio: 0.9,
              children: [
                _buildMetricCard(
                  label: 'Nodes Explored',
                  valueA: '${metricsA.exploredStates.length}',
                  valueB: '${metricsB.exploredStates.length}',
                  winner: result.winner.algorithmName == widget.algorithmAName
                      ? 'A'
                      : 'B',
                  metricName: 'Nodes',
                  isWinnerA:
                      result.winner.algorithmName == widget.algorithmAName,
                ),
                _buildMetricCard(
                  label: 'Path Length',
                  valueA: '${metricsA.path.length}',
                  valueB: '${metricsB.path.length}',
                  winner: metricsA.path.length < metricsB.path.length
                      ? 'A'
                      : 'B',
                  metricName: 'Moves',
                  isWinnerA: metricsA.path.length < metricsB.path.length,
                ),
                _buildMetricCard(
                  label: 'Efficiency (Path/Explored)',
                  valueA:
                      (metricsA.path.length /
                              (metricsA.exploredStates.length + 1))
                          .toStringAsFixed(2),
                  valueB:
                      (metricsB.path.length /
                              (metricsB.exploredStates.length + 1))
                          .toStringAsFixed(2),
                  winner:
                      (metricsA.path.length /
                              (metricsA.exploredStates.length + 1)) >
                          (metricsB.path.length /
                              (metricsB.exploredStates.length + 1))
                      ? 'A'
                      : 'B',
                  metricName: 'Score',
                  isWinnerA:
                      (metricsA.path.length /
                          (metricsA.exploredStates.length + 1)) >
                      (metricsB.path.length /
                          (metricsB.exploredStates.length + 1)),
                ),
                _buildMetricCard(
                  label: 'Execution Time',
                  valueA: '${metricsA.executionTime.inMilliseconds}ms',
                  valueB: '${metricsB.executionTime.inMilliseconds}ms',
                  winner: metricsA.executionTime < metricsB.executionTime
                      ? 'A'
                      : 'B',
                  metricName: 'Time',
                  isWinnerA: metricsA.executionTime < metricsB.executionTime,
                ),
              ],
            ),
            const SizedBox(height: 16),

            // Detailed Report
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.black.withValues(alpha: 0.3),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Analysis',
                    style: Theme.of(context).textTheme.labelSmall?.copyWith(
                      color: Colors.grey[400],
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    result.getDetailedReport(),
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: Colors.grey[300],
                      height: 1.6,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMetricCard({
    required String label,
    required String valueA,
    required String valueB,
    required String winner,
    required String metricName,
    required bool isWinnerA,
  }) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.black.withValues(alpha: 0.3),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.white.withValues(alpha: 0.06), width: 1),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: Theme.of(
              context,
            ).textTheme.labelSmall?.copyWith(color: Colors.grey[400]),
          ),
          const SizedBox(height: 8),
          Expanded(
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: isWinnerA
                          ? Colors.green.withValues(alpha: 0.2)
                          : Colors.grey.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(6),
                      border: Border.all(
                        color: isWinnerA
                            ? Colors.green.withValues(alpha: 0.5)
                            : Colors.grey.withValues(alpha: 0.2),
                      ),
                    ),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          'A',
                          style: TextStyle(
                            fontSize: 10,
                            color: isWinnerA ? Colors.green : Colors.grey[400],
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 4),
                        FittedBox(
                          fit: BoxFit.scaleDown,
                          child: Text(
                            valueA,
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 12,
                              color: isWinnerA
                                  ? Colors.green[300]
                                  : Colors.grey[300],
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: !isWinnerA
                          ? Colors.green.withValues(alpha: 0.2)
                          : Colors.grey.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(6),
                      border: Border.all(
                        color: !isWinnerA
                            ? Colors.green.withValues(alpha: 0.5)
                            : Colors.grey.withValues(alpha: 0.2),
                      ),
                    ),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          'B',
                          style: TextStyle(
                            fontSize: 10,
                            color: !isWinnerA ? Colors.green : Colors.grey[400],
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 4),
                        FittedBox(
                          fit: BoxFit.scaleDown,
                          child: Text(
                            valueB,
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 12,
                              color: !isWinnerA
                                  ? Colors.green[300]
                                  : Colors.grey[300],
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
