import 'dart:async';
import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

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
  final List<List<GridNode>>? initialGrid;
  final GridCoordinate? start;
  final GridCoordinate? goal;

  const AlgorithmBattleScreen({
    super.key,
    this.initialGrid,
    this.start,
    this.goal,
  });

  @override
  State<AlgorithmBattleScreen> createState() => _AlgorithmBattleScreenState();
}

class _AlgorithmBattleScreenState extends State<AlgorithmBattleScreen> {
  String _algoAId = 'BFS';
  String _algoBId = 'A*';
  AlgorithmExecutor<GridCoordinate>? _executorA;
  AlgorithmExecutor<GridCoordinate>? _executorB;
  AlgorithmStep<GridCoordinate>? _stepA;
  AlgorithmStep<GridCoordinate>? _stepB;
  AlgorithmMetrics? _metricsA;
  AlgorithmMetrics? _metricsB;
  bool _isRunning = false;
  late final GridController _controller;

  @override
  void initState() {
    super.initState();
    _controller = GridController(
      rows: widget.initialGrid?.length ?? 12,
      columns: widget.initialGrid?[0].length ?? 15,
    );
    if (widget.initialGrid != null) {
      _controller.loadFromGrid(widget.initialGrid!);
      if (widget.start != null) {
        _controller.moveAnchor(
          isStart: true,
          row: widget.start!.row,
          column: widget.start!.column,
        );
      }
      if (widget.goal != null) {
        _controller.moveAnchor(
          isStart: false,
          row: widget.goal!.row,
          column: widget.goal!.column,
        );
      }
    }
  }

  SearchAlgorithm<GridCoordinate> _getAlgorithm(String id) {
    return switch (id) {
      'BFS' => BFSAlgorithm<GridCoordinate>(),
      'DFS' => DFSAlgorithm<GridCoordinate>(),
      'Dijkstra' => DijkstraAlgorithm<GridCoordinate>(),
      'Greedy' => GreedyBestFirstAlgorithm<GridCoordinate>(),
      'A*' => AStarAlgorithm<GridCoordinate>(),
      _ => AStarAlgorithm<GridCoordinate>(),
    };
  }

  Future<void> _runBattle() async {
    if (_isRunning) return;

    setState(() {
      _isRunning = true;
      _stepA = null;
      _stepB = null;
      _metricsA = null;
      _metricsB = null;
    });

    await _executorA?.dispose();
    await _executorB?.dispose();

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

    _executorA = AlgorithmExecutor<GridCoordinate>(
      algorithm: _getAlgorithm(_algoAId),
      problem: problem,
      stepDelayMs: _stepDelay.inMilliseconds,
    );
    _executorB = AlgorithmExecutor<GridCoordinate>(
      algorithm: _getAlgorithm(_algoBId),
      problem: problem,
      stepDelayMs: _stepDelay.inMilliseconds,
    );

    final completerA = Completer<void>();
    final completerB = Completer<void>();
    final stopwatchA = Stopwatch()..start();
    final stopwatchB = Stopwatch()..start();
    AlgorithmStep<GridCoordinate>? lastStepA;
    AlgorithmStep<GridCoordinate>? lastStepB;

    try {
      _executorA!.stepStream.listen(
        (step) {
          lastStepA = step;
          if (!mounted) return;
          setState(() => _stepA = step);
        },
        onDone: () {
          stopwatchA.stop();
          final finalStep = lastStepA;
          if (mounted && finalStep != null) {
            setState(() {
              _stepA = finalStep;
              _metricsA = AlgorithmMetrics(
                algorithmName: _algoAId,
                exploredStates: _executorA!.exploredSet.toList(),
                path: _executorA!.currentPath,
                totalSteps: finalStep.stepCount,
                executionTime: stopwatchA.elapsed,
                pathCost: _executorA!.currentPath.length.toDouble(),
                foundPath: finalStep.isGoalReached,
              );
            });
          }
          if (!completerA.isCompleted) completerA.complete();
        },
        onError: (_) {
          if (!completerA.isCompleted) completerA.complete();
        },
      );

      _executorB!.stepStream.listen(
        (step) {
          lastStepB = step;
          if (!mounted) return;
          setState(() => _stepB = step);
        },
        onDone: () {
          stopwatchB.stop();
          final finalStep = lastStepB;
          if (mounted && finalStep != null) {
            setState(() {
              _stepB = finalStep;
              _metricsB = AlgorithmMetrics(
                algorithmName: _algoBId,
                exploredStates: _executorB!.exploredSet.toList(),
                path: _executorB!.currentPath,
                totalSteps: finalStep.stepCount,
                executionTime: stopwatchB.elapsed,
                pathCost: _executorB!.currentPath.length.toDouble(),
                foundPath: finalStep.isGoalReached,
              );
            });
          }
          if (!completerB.isCompleted) completerB.complete();
        },
        onError: (_) {
          if (!completerB.isCompleted) completerB.complete();
        },
      );

      await Future.wait([_executorA!.start(), _executorB!.start()]);
      await Future.wait([completerA.future, completerB.future]);
    } finally {
      if (mounted) setState(() => _isRunning = false);
    }
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
      _stepA = null;
      _stepB = null;
      _metricsA = null;
      _metricsB = null;
    });
  }

  @override
  void dispose() {
    _executorA?.dispose();
    _executorB?.dispose();
    _controller.dispose();
    super.dispose();
  }

  // Default step delay for executors
  Duration get _stepDelay => const Duration(milliseconds: 5);

  @override
  Widget build(BuildContext context) {
    bool? isAWinner;
    if (_metricsA != null && _metricsB != null) {
      isAWinner =
          BattleResult(algorithm1: _metricsA!, algorithm2: _metricsB!).winner ==
          _metricsA;
    }

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
                subtitle: 'SHOWPIECE ARENA',
                onBackTap: () => Navigator.pop(context),
              ),
              const SizedBox(height: 20),

              // Algorithm Selectors
              _buildSelectors(),
              const SizedBox(height: 16),

              BattleResultsPanel(
                algorithmAMetrics: _metricsA,
                algorithmBMetrics: _metricsB,
                algorithmAName: _algoAId,
                algorithmBName: _algoBId,
                isLoading: _isRunning,
              ),
              const SizedBox(height: 16),

              AnimatedBuilder(
                animation: _controller,
                builder: (context, _) => Column(
                  children: [
                    _buildIndividualGrid(
                      label: 'PLAYER 1: $_algoAId',
                      step: _stepA,
                      executor: _executorA,
                      color: AppTheme.accent,
                      isWinner: isAWinner == true,
                    ),
                    const SizedBox(height: 24),
                    _buildIndividualGrid(
                      label: 'PLAYER 2: $_algoBId',
                      step: _stepB,
                      executor: _executorB,
                      color: AppTheme.error,
                      isWinner: isAWinner == false,
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),

              Row(
                children: [
                  Expanded(
                    child: GlassStatCard(
                      label: '$_algoAId EXPLORED',
                      value: _executorA?.exploredSet.length ?? 0,
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: GlassStatCard(
                      label: '$_algoBId EXPLORED',
                      value: _executorB?.exploredSet.length ?? 0,
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: GlassStatCard(
                      label: 'STATUS',
                      value: _isRunning ? 'BATTLING' : 'READY',
                    ),
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
                        height: 56.h,
                        decoration: BoxDecoration(
                          gradient: AppTheme.ctaGradient,
                          borderRadius: BorderRadius.circular(16.r),
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
                            _isRunning ? 'COMPUTING...' : 'START BATTLE',
                            style: Theme.of(context).textTheme.labelLarge
                                ?.copyWith(
                                  color: Colors.white,
                                  letterSpacing: 2,
                                  fontSize: 16.sp,
                                  fontWeight: FontWeight.w900,
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

  Widget _buildSelectors() {
    return Row(
      children: [
        Expanded(child: _buildAlgoSelector(true)),
        const SizedBox(width: 12),
        const Text(
          'VS',
          style: TextStyle(
            color: AppTheme.textMuted,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(child: _buildAlgoSelector(false)),
      ],
    );
  }

  Widget _buildAlgoSelector(bool isPlayerA) {
    final current = isPlayerA ? _algoAId : _algoBId;
    final color = isPlayerA ? AppTheme.accent : AppTheme.error;

    return Container(
      padding: EdgeInsets.symmetric(horizontal: 12.w),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(12.r),
        border: Border.all(color: color.withValues(alpha: 0.2)),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<String>(
          value: current,
          dropdownColor: AppTheme.surfaceHigh,
          icon: Icon(Icons.keyboard_arrow_down, color: color, size: 18.r),
          isExpanded: true,
          style: TextStyle(
            color: color,
            fontWeight: FontWeight.bold,
            fontSize: 13.sp,
          ),
          items: ['BFS', 'DFS', 'Dijkstra', 'Greedy', 'A*'].map((id) {
            return DropdownMenuItem(value: id, child: Text(id));
          }).toList(),
          onChanged: _isRunning
              ? null
              : (val) {
                  if (val != null) {
                    setState(() {
                      if (isPlayerA) {
                        _algoAId = val;
                      } else {
                        _algoBId = val;
                      }
                      _stepA = null;
                      _stepB = null;
                      _metricsA = null;
                      _metricsB = null;
                    });
                  }
                },
        ),
      ),
    );
  }

  Widget _buildIndividualGrid({
    required String label,
    required AlgorithmStep<GridCoordinate>? step,
    required AlgorithmExecutor<GridCoordinate>? executor,
    required Color color,
    bool isWinner = false,
  }) {
    final bool isLoser = !isWinner && _metricsA != null && _metricsB != null;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: EdgeInsets.only(left: 4.w, bottom: 8.h),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                label,
                style: Theme.of(context).textTheme.labelSmall?.copyWith(
                  color: isWinner ? color : color.withValues(alpha: 0.7),
                  letterSpacing: 2,
                  fontWeight: isWinner ? FontWeight.bold : FontWeight.normal,
                ),
              ),
              if (isWinner)
                Container(
                  padding: EdgeInsets.symmetric(horizontal: 8.w, vertical: 2.h),
                  decoration: BoxDecoration(
                    color: color,
                    borderRadius: BorderRadius.circular(4.r),
                  ),
                  child: Text(
                    'WINNER',
                    style: TextStyle(
                      color: Colors.black,
                      fontSize: 10.sp,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
            ],
          ),
        ),
        Opacity(
          opacity: isLoser ? 0.4 : 1.0,
          child: Container(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(16.r),
              boxShadow: isWinner
                  ? [
                      BoxShadow(
                        color: color.withValues(alpha: 0.3),
                        blurRadius: 30,
                        spreadRadius: 6,
                      ),
                    ]
                  : null,
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(16.r),
              child: BackdropFilter(
                filter: ImageFilter.blur(sigmaX: 8, sigmaY: 8),
                child: Container(
                  decoration: AppTheme.glassCard(
                    radius: 16,
                    borderColor: isWinner
                        ? color.withValues(alpha: 0.8)
                        : color.withValues(alpha: 0.2),
                  ),
                  padding: EdgeInsets.all(8.r),
                  child: GridView.builder(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: _controller.columns,
                      childAspectRatio: 1,
                      crossAxisSpacing: 1.5,
                      mainAxisSpacing: 1.5,
                    ),
                    itemCount: _controller.rows * _controller.columns,
                    itemBuilder: (_, index) {
                      final row = index ~/ _controller.columns;
                      final column = index % _controller.columns;
                      final node = _controller.grid[row][column];
                      final state = GridCoordinate(row: row, column: column);

                      bool isExplored =
                          executor?.exploredSet.contains(state) ?? false;
                      bool isPath =
                          executor?.currentPath.contains(state) ?? false;
                      bool isCurrent = step?.currentState == state;

                      final cellColor = _getCellColorForAlgo(
                        node,
                        isPath,
                        isExplored,
                        color,
                      );

                      return AnimatedContainer(
                        duration: const Duration(milliseconds: 200),
                        curve: Curves.easeOut,
                        decoration: BoxDecoration(
                          color: cellColor,
                          borderRadius: BorderRadius.circular(1.5.r),
                          boxShadow: isCurrent
                              ? [
                                  BoxShadow(
                                    color: color.withValues(alpha: 0.8),
                                    blurRadius: 8,
                                    spreadRadius: 2,
                                  ),
                                ]
                              : (isPath
                                    ? [
                                        BoxShadow(
                                          color: AppTheme.cyan.withValues(
                                            alpha: 0.4,
                                          ),
                                          blurRadius: 4,
                                        ),
                                      ]
                                    : null),
                        ),
                        child: isCurrent
                            ? Center(
                                child: Container(
                                  width: 4.w,
                                  height: 4.h,
                                  decoration: BoxDecoration(
                                    color: Colors.white,
                                    shape: BoxShape.circle,
                                  ),
                                ),
                              )
                            : null,
                      );
                    },
                  ),
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }

  Color _getCellColorForAlgo(
    GridNode node,
    bool isPath,
    bool isExplored,
    Color algoColor,
  ) {
    if (node.type == NodeType.wall) return AppTheme.cellWall;
    if (node.type == NodeType.start) return AppTheme.cellStart;
    if (node.type == NodeType.goal) return AppTheme.cellGoal;
    if (isPath) return AppTheme.cyan;
    if (isExplored) return algoColor.withValues(alpha: 0.4);
    return AppTheme.surfaceLow;
  }

  Widget _buildControlButton({
    required IconData icon,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 56.w,
        height: 56.h,
        decoration: BoxDecoration(
          color: AppTheme.surfaceHigh,
          borderRadius: BorderRadius.circular(16.r),
          border: Border.all(color: Colors.white.withValues(alpha: 0.06)),
        ),
        child: Icon(icon, color: AppTheme.accentLight, size: 28),
      ),
    );
  }
}
