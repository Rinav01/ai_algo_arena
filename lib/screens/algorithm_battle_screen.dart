import 'dart:async';
import 'dart:ui';

import 'package:flutter/material.dart';

import '../core/app_theme.dart';
import '../core/grid_problem.dart';
import '../core/problem_definition.dart';
import '../core/search_algorithms.dart';
import '../models/grid_node.dart';
import '../services/algorithm_executor.dart';
import '../services/battle_analyzer.dart';
import '../state/grid_controller.dart';
import '../widgets/battle_results_panel.dart';
import '../widgets/visualizer_widgets.dart';

class AlgorithmBattleScreen extends StatefulWidget {
  const AlgorithmBattleScreen({super.key});

  @override
  State<AlgorithmBattleScreen> createState() => _AlgorithmBattleScreenState();
}

class _AlgorithmBattleScreenState extends State<AlgorithmBattleScreen> {
  late final GridController _controller;
  AlgorithmExecutor<GridCoordinate>? _bfsExecutor;
  AlgorithmExecutor<GridCoordinate>? _dfsExecutor;
  AlgorithmStep<GridCoordinate>? _bfsStep;
  AlgorithmStep<GridCoordinate>? _dfsStep;
  AlgorithmMetrics? _bfsMetrics;
  AlgorithmMetrics? _dfsMetrics;
  bool _isRunning = false;

  @override
  void initState() {
    super.initState();
    _controller = GridController(rows: 8, columns: 20);
  }

  @override
  void dispose() {
    _bfsExecutor?.dispose();
    _dfsExecutor?.dispose();
    _controller.dispose();
    super.dispose();
  }

  Future<void> _runBattle() async {
    if (_isRunning) return;

    setState(() {
      _isRunning = true;
      _bfsStep = null;
      _dfsStep = null;
      _bfsMetrics = null;
      _dfsMetrics = null;
    });

    await _bfsExecutor?.dispose();
    await _dfsExecutor?.dispose();

    final problem = GridProblem(
      grid: _controller.grid,
      start: GridCoordinate(
        row: _controller.start.row,
        column: _controller.start.column,
      ),
      goal: GridCoordinate(
        row: _controller.goal.row,
        column: _controller.goal.column,
      ),
    );

    _bfsExecutor = AlgorithmExecutor<GridCoordinate>(
      algorithm: BFSAlgorithm<GridCoordinate>(),
      problem: problem,
    );
    _dfsExecutor = AlgorithmExecutor<GridCoordinate>(
      algorithm: DFSAlgorithm<GridCoordinate>(),
      problem: problem,
    );

    try {
      final bfsDone = _runTrackedExecutor(
        executor: _bfsExecutor!,
        algorithmName: 'Breadth-First Search',
        onStep: (step) {
          if (!mounted) return;
          setState(() {
            _bfsStep = step;
          });
        },
        onFinished: (step, executionTime) {
          if (!mounted) return;
          setState(() {
            _bfsStep = step;
            _bfsMetrics = AlgorithmMetrics(
              algorithmName: 'Breadth-First Search',
              exploredStates: step.explored,
              path: step.path,
              totalSteps: step.stepCount,
              executionTime: executionTime,
              pathCost: step.path.length.toDouble(),
              foundPath: step.path.isNotEmpty,
            );
          });
        },
      );
      final dfsDone = _runTrackedExecutor(
        executor: _dfsExecutor!,
        algorithmName: 'Depth-First Search',
        onStep: (step) {
          if (!mounted) return;
          setState(() {
            _dfsStep = step;
          });
        },
        onFinished: (step, executionTime) {
          if (!mounted) return;
          setState(() {
            _dfsStep = step;
            _dfsMetrics = AlgorithmMetrics(
              algorithmName: 'Depth-First Search',
              exploredStates: step.explored,
              path: step.path,
              totalSteps: step.stepCount,
              executionTime: executionTime,
              pathCost: step.path.length.toDouble(),
              foundPath: step.path.isNotEmpty,
            );
          });
        },
      );

      await Future.wait([bfsDone, dfsDone]);
    } finally {
      if (mounted) {
        setState(() {
          _isRunning = false;
        });
      }
    }
  }

  Future<void> _runTrackedExecutor({
    required AlgorithmExecutor<GridCoordinate> executor,
    required String algorithmName,
    required void Function(AlgorithmStep<GridCoordinate> step) onStep,
    required void Function(
      AlgorithmStep<GridCoordinate> step,
      Duration executionTime,
    )
    onFinished,
  }) async {
    final completer = Completer<void>();
    final stopwatch = Stopwatch()..start();
    AlgorithmStep<GridCoordinate>? latestStep;

    await executor.start();

    executor.stepStream.listen(
      (step) {
        latestStep = step;
        onStep(step);
      },
      onDone: () {
        stopwatch.stop();
        final finalStep =
            latestStep ??
            AlgorithmStep<GridCoordinate>(
              explored: const [],
              path: const [],
              stepCount: 0,
              message: '$algorithmName did not emit steps.',
            );
        onFinished(finalStep, stopwatch.elapsed);
        if (!completer.isCompleted) {
          completer.complete();
        }
      },
      onError: (_) {
        stopwatch.stop();
        if (!completer.isCompleted) {
          completer.complete();
        }
      },
    );

    return completer.future;
  }

  void _randomizeMaze() {
    _controller.clearWalls();
    final randomSeed = DateTime.now().millisecondsSinceEpoch % 100;
    for (int i = 0; i < randomSeed; i++) {
      final row = (i * 7) % _controller.rows;
      final col = (i * 11) % _controller.columns;
      _controller.handleCellInteraction(row, col);
    }

    setState(() {
      _bfsStep = null;
      _dfsStep = null;
      _bfsMetrics = null;
      _dfsMetrics = null;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.background,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(20, 20, 20, 32),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Header
              VisualizerHeader(
                title: 'Algorithm Battle',
                subtitle: 'HEAD-TO-HEAD VIZ',
                onBackTap: () => Navigator.pop(context),
              ),
              const SizedBox(height: 20),
              
              Row(
                children: [
                  Expanded(
                    child: _buildAlgoInfo(
                      'BFS (P1)',
                      _bfsStep,
                      AppTheme.warning,
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: _buildAlgoInfo(
                      'DFS (P2)',
                      _dfsStep,
                      AppTheme.error,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              
              BattleResultsPanel(
                algorithmAMetrics: _bfsMetrics,
                algorithmBMetrics: _dfsMetrics,
                algorithmAName: 'BFS',
                algorithmBName: 'DFS',
                isLoading: _isRunning,
              ),
              const SizedBox(height: 16),
              
              ClipRRect(
                borderRadius: BorderRadius.circular(16),
                child: BackdropFilter(
                  filter: ImageFilter.blur(sigmaX: 8, sigmaY: 8),
                  child: Container(
                    decoration: AppTheme.glassCardAccent(radius: 16),
                    padding: const EdgeInsets.all(8),
                    child: AnimatedBuilder(
                      animation: _controller,
                      builder: (context, _) => _buildBattleGrid(),
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 16),
              
              Row(
                children: [
                  Expanded(
                    child: GlassStatCard(label: 'BFS EXPLORED', value: _bfsStep?.explored.length ?? 0),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: GlassStatCard(label: 'DFS EXPLORED', value: _dfsStep?.explored.length ?? 0),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: GlassStatCard(label: 'STATUS', value: _isRunning ? 'RUNNING' : 'IDLE'),
                  ),
                ],
              ),
              const SizedBox(height: 24),
              
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  _buildControlButton(
                    icon: Icons.replay_rounded,
                    onTap: _randomizeMaze,
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: GestureDetector(
                      onTap: _isRunning ? null : _runBattle,
                      child: Container(
                        height: 56,
                        decoration: BoxDecoration(
                          gradient: AppTheme.ctaGradient,
                          borderRadius: BorderRadius.circular(16),
                          boxShadow: [
                            BoxShadow(
                              color: AppTheme.accent.withValues(alpha: 0.3),
                              blurRadius: 16,
                              spreadRadius: -4,
                            ),
                          ],
                        ),
                        child: Center(
                          child: Text(
                            _isRunning ? 'BATTLING...' : 'START BATTLE',
                            style: Theme.of(context).textTheme.labelLarge?.copyWith(
                              color: Colors.white,
                              letterSpacing: 1.5,
                              fontSize: 15,
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildAlgoInfo(
    String name,
    AlgorithmStep<GridCoordinate>? step,
    Color color,
  ) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withValues(alpha: 0.3), width: 1),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 8, height: 8,
                decoration: BoxDecoration(shape: BoxShape.circle, color: color),
              ),
              const SizedBox(width: 6),
              Text(
                name,
                style: Theme.of(context).textTheme.labelSmall?.copyWith(
                  color: color,
                  letterSpacing: 1,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          if (step != null)
            Text(
              'Frontier: [${step.explored.take(3).map((e) => '${e.row},${e.column}').join(', ')}...]',
              style: Theme.of(context).textTheme.bodySmall,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            )
          else
            Text(
              'Awaiting start...',
              style: Theme.of(context).textTheme.bodySmall?.copyWith(color: AppTheme.textMuted),
            ),
        ],
      ),
    );
  }

  Widget _buildBattleGrid() {
    final grid = _controller.grid;
    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: _controller.columns,
        childAspectRatio: 1,
        crossAxisSpacing: 1.5,
        mainAxisSpacing: 1.5,
      ),
      itemCount: _controller.rows * _controller.columns,
      itemBuilder: (context, index) {
        final row = index ~/ _controller.columns;
        final column = index % _controller.columns;
        final node = grid[row][column];

        bool isBfsExplored = false;
        bool isDfsExplored = false;
        bool isPath = false;

        if (_bfsStep != null) {
          isBfsExplored = _bfsStep!.explored.any(
            (e) => e.row == row && e.column == column,
          );
          isPath = _bfsStep!.path.any(
            (e) => e.row == row && e.column == column,
          );
        }

        if (_dfsStep != null && !isBfsExplored && !isPath) {
          isDfsExplored = _dfsStep!.explored.any(
            (e) => e.row == row && e.column == column,
          );
        }

        final cellColor = _getCellBattleColor(
          node,
          isPath,
          isBfsExplored,
          isDfsExplored,
        );

        return Container(
          decoration: BoxDecoration(
            color: cellColor,
            borderRadius: BorderRadius.circular(2),
          ),
        );
      },
    );
  }

  Color _getCellBattleColor(
    GridNode node,
    bool isPath,
    bool isBfsExplored,
    bool isDfsExplored,
  ) {
    if (node.type == NodeType.wall) return AppTheme.cellWall;
    if (node.type == NodeType.start) return AppTheme.cellStart;
    if (node.type == NodeType.goal) return AppTheme.cellGoal;
    if (isPath) return AppTheme.success.withValues(alpha: 0.8);
    if (isBfsExplored) return AppTheme.warning.withValues(alpha: 0.4);
    if (isDfsExplored) return AppTheme.error.withValues(alpha: 0.4);
    return AppTheme.surfaceLow;
  }

  Widget _buildControlButton({
    required IconData icon,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 56, height: 56,
        decoration: BoxDecoration(
          color: AppTheme.surfaceHigh,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: Colors.white.withValues(alpha: 0.06)),
        ),
        child: Icon(icon, color: AppTheme.accentLight, size: 28),
      ),
    );
  }
}
