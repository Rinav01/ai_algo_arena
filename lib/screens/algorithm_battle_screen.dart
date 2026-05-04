import 'dart:async';
import 'dart:typed_data';
import 'package:algo_arena/widgets/premium_glass_container.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:algo_arena/core/app_theme.dart';
import 'package:algo_arena/core/grid_problem.dart';
import 'package:algo_arena/core/problem_definition.dart';
import 'package:algo_arena/core/search_algorithms.dart';
import 'package:algo_arena/models/grid_node.dart';
import 'package:algo_arena/services/algorithm_executor.dart';
import 'package:algo_arena/services/battle_analyzer.dart';
import 'package:algo_arena/state/grid_controller.dart';
import 'package:algo_arena/services/stats_service.dart';
import 'package:algo_arena/widgets/grid_visualizer_canvas.dart';
import 'package:algo_arena/widgets/visualizer_widgets.dart';
import 'package:algo_arena/state/settings_provider.dart';
import 'package:algo_arena/models/algo_info.dart';
import 'package:algo_arena/services/maze_generator.dart';
import 'package:algo_arena/services/api_service.dart';
import 'package:algo_arena/state/api_provider.dart';
import 'package:algo_arena/services/run_optimizer.dart';
import 'package:algo_arena/widgets/feature_tour.dart';

class AlgorithmBattleScreen extends ConsumerStatefulWidget {
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
  ConsumerState<AlgorithmBattleScreen> createState() =>
      _AlgorithmBattleScreenState();
}

class _AlgorithmBattleScreenState extends ConsumerState<AlgorithmBattleScreen> {
  String _algoAId = 'BFS';
  String _algoBId = 'A*';
  AlgorithmExecutor<GridCoordinate>? _executorA;
  AlgorithmExecutor<GridCoordinate>? _executorB;
  bool _isRunning = false;
  bool _showVictoryAnimation = false;
  String? _winnerId;
  AlgorithmStep<GridCoordinate>? _stepA;
  AlgorithmStep<GridCoordinate>? _stepB;
  AlgorithmMetrics? _metricsA;
  AlgorithmMetrics? _metricsB;
  late final GridController _controller;

  final GlobalKey _selectorsKey = GlobalKey();
  final GlobalKey _toolsKey = GlobalKey();
  final GlobalKey _battleCtaKey = GlobalKey();

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
      if (widget.goal != null && widget.goal!.row != -1) {
        _controller.moveAnchor(
          isStart: false,
          row: widget.goal!.row,
          column: widget.goal!.column,
        );
      }
    }

    WidgetsBinding.instance.addPostFrameCallback((_) {
      FeatureTour.startTour(
        context: context,
        tourKey: 'algorithm_battle',
        steps: [
          TourStep(
            targetKey: _selectorsKey,
            title: 'Algorithm Selectors',
            description: 'Choose which two algorithms will compete side-by-side in real time.',
          ),
          TourStep(
            targetKey: _toolsKey,
            title: 'Grid Editor Tools',
            description: 'Draw walls or weights, adjust starting or goal points on the arena grid.',
          ),
          TourStep(
            targetKey: _battleCtaKey,
            title: 'Launch Battle',
            description: 'Run both algorithms simultaneously to compare speed, path length, and explored node costs.',
          ),
        ],
      );
    });
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

  double _calculatePathCost(List<GridCoordinate> path) {
    if (path.isEmpty) return double.infinity;
    double total = 0;
    // We skip the first node (start) as its arrival cost is 0.
    // Every subsequent node's weight is added as the cost to enter that node.
    for (int i = 1; i < path.length; i++) {
      final coord = path[i];
      total += _controller.grid[coord.row][coord.column].weight;
    }
    return total;
  }

  Future<void> _runBattle() async {
    if (_isRunning) return;

    setState(() {
      _isRunning = true;
      _stepA = null;
      _stepB = null;
      _metricsA = null;
      _metricsB = null;
      _winnerId = null;
      _showVictoryAnimation = false;
    });

    await _executorA?.dispose();
    await _executorB?.dispose();

    final goal = _controller.goal;
    if (goal == null) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please place a Goal node first')),
      );
      setState(() => _isRunning = false);
      return;
    }

    final settings = ref.read(settingsProvider);
    final snapshot = _controller.toOptimizedSnapshot(settings);

    _executorA = AlgorithmExecutor<GridCoordinate>(
      algorithm: _getAlgorithm(_algoAId),
      problemSnapshot: snapshot,
      stepDelayMs: _stepDelay.inMilliseconds,
      algorithmId: _algoAId,
    );
    _executorB = AlgorithmExecutor<GridCoordinate>(
      algorithm: _getAlgorithm(_algoBId),
      problemSnapshot: snapshot,
      stepDelayMs: _stepDelay.inMilliseconds,
      algorithmId: _algoBId,
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
          if (_stepA == null) setState(() => _stepA = step);
        },
        onDone: () {
          stopwatchA.stop();
          final finalStep = lastStepA;
          if (mounted && finalStep != null) {
            final history = _executorA!.history ?? [];
            final fullExplored = history
                .expand((s) => s.newlyExplored)
                .toList();
            setState(() {
              _stepA = finalStep;
              _metricsA = AlgorithmMetrics(
                algorithmName: _algoAId,
                exploredStates: fullExplored,
                path: finalStep.path,
                totalSteps: finalStep.stepCount,
                executionTime: stopwatchA.elapsed,
                pathCost: _calculatePathCost(finalStep.path),
                foundPath: finalStep.isGoalReached,
                history: history,
                problemSnapshot: snapshot,
              );
              debugPrint(
                'Battle Stats [A]: ${_metricsA!.algorithmName} - Cost: ${_metricsA!.pathCost}, Nodes: ${_metricsA!.exploredStates.length}, Found: ${_metricsA!.foundPath}',
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
          if (_stepB == null) setState(() => _stepB = step);
        },
        onDone: () {
          stopwatchB.stop();
          final finalStep = lastStepB;
          if (mounted && finalStep != null) {
            final history = _executorB!.history ?? [];
            final fullExplored = history
                .expand((s) => s.newlyExplored)
                .toList();
            setState(() {
              _stepB = finalStep;
              _metricsB = AlgorithmMetrics(
                algorithmName: _algoBId,
                exploredStates: fullExplored,
                path: finalStep.path,
                totalSteps: finalStep.stepCount,
                executionTime: stopwatchB.elapsed,
                pathCost: _calculatePathCost(finalStep.path),
                foundPath: finalStep.isGoalReached,
                history: history,
                problemSnapshot: snapshot,
              );
              debugPrint(
                'Battle Stats [B]: ${_metricsB!.algorithmName} - Cost: ${_metricsB!.pathCost}, Nodes: ${_metricsB!.exploredStates.length}, Found: ${_metricsB!.foundPath}',
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
      debugPrint('Battle stream completed. Processing results...');
      await Future.wait([completerA.future, completerB.future]);
      debugPrint('Both completers finished.');

      if (mounted) {
        String? winnerAlgo;
        if (_metricsA != null && _metricsB != null) {
          final result = BattleResult(
            algorithm1: _metricsA!,
            algorithm2: _metricsB!,
          );
          winnerAlgo = result.winner.algorithmName;

          debugPrint('Determined winner: $winnerAlgo. Calling auto-save.');
          _autoSaveRun(result);

          setState(() {
            _winnerId = (winnerAlgo == _algoAId) ? 'A' : 'B';
            _showVictoryAnimation = true;
          });

          await Future.delayed(const Duration(seconds: 4));

          if (mounted) {
            setState(() => _showVictoryAnimation = false);
            _showBattleAnalytics(result);
          }
        }
        ref
            .read(arenaStatsProvider.notifier)
            .recordBattleCompletion(winnerAlgo);
      }
    } finally {
      if (mounted) {
        setState(() => _isRunning = false);
      }
    }
  }

  Map<String, dynamic>? _sanitizeSnapshot(Map<String, dynamic>? snapshot) {
    if (snapshot == null) return null;
    final sanitized = Map<String, dynamic>.from(snapshot);
    if (sanitized['types'] is Uint8List) {
      sanitized['types'] = (sanitized['types'] as Uint8List).toList();
    }
    if (sanitized['weights'] is Float32List) {
      sanitized['weights'] = (sanitized['weights'] as Float32List).toList();
    }

    return sanitized;
  }

  Future<void> _autoSaveRun(BattleResult result) async {
    debugPrint('Auto-saving battle results with Phase 2 optimizations...');
    try {
      final cols = _controller.columns;
      final totalCells = _controller.rows * cols;
      final wallCount = _controller.grid
          .expand((r) => r)
          .where((n) => n.type == NodeType.wall)
          .length;
      final density = wallCount / totalCells;

      final nodeDiff =
          (result.algorithm1.totalSteps - result.algorithm2.totalSteps).abs();
      final timeDiff =
          (result.algorithm1.executionTime.inMilliseconds -
                  result.algorithm2.executionTime.inMilliseconds)
              .abs();

      final runData = {
        'algorithm':
            '${result.algorithm1.algorithmName} vs ${result.algorithm2.algorithmName}',
        'type': 'battle',
        'isBattle': true, // Legacy support
        'snapshot': _sanitizeSnapshot(result.algorithm1.problemSnapshot),
        'totalSteps': result.winner.totalSteps, // Summary for list view
        'durationMs':
            result.winner.executionTime.inMilliseconds, // Summary for list view
        'metadata': {
          'winner': result.winner.algorithmName,
          'obstacleDensity': density,
          'nodesDiff': nodeDiff,
          'timeDiff': timeDiff,
          'nodesExplored': result.winner.exploredStates.length,
          'pathLength': result.winner.path.length,
          'pathCost': result.winner.pathCost,
        },
        'competitors': [
          RunOptimizer.optimizeCompetitor(
            result.algorithm1.algorithmName,
            result.algorithm1.history.cast<AlgorithmStep<GridCoordinate>>(),
            result.algorithm1.path.cast<GridCoordinate>(),
            result.algorithm1.executionTime,
            cols,
            isWinner: result.winner == result.algorithm1,
          ),
          RunOptimizer.optimizeCompetitor(
            result.algorithm2.algorithmName,
            result.algorithm2.history.cast<AlgorithmStep<GridCoordinate>>(),
            result.algorithm2.path.cast<GridCoordinate>(),
            result.algorithm2.executionTime,
            cols,
            isWinner: result.winner == result.algorithm2,
          ),
        ],
        'timestamp': DateTime.now().toIso8601String(),
        'tags': ['battle', density > 0.3 ? 'dense' : 'sparse'],
      };

      debugPrint('Sending optimized battle data...');
      await ApiService().saveRun(runData);

      if (mounted) {
        ref.invalidate(runsProvider);
      }
    } catch (e) {
      debugPrint('CRITICAL: Error auto-saving battle run: $e');
    }
  }

  void _showBattleAnalytics(BattleResult result) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (context) => _BattleAnalyticsSheet(
        result: result,
        onSave: () => _autoSaveRun(result),
      ),
    );
  }

  void _randomizeMaze() {
    MazeGenerator.generatePrims(_controller, includeWeights: true);
    setState(() {
      _stepA = null;
      _stepB = null;
      _metricsA = null;
      _metricsB = null;
      _winnerId = null;
      _showVictoryAnimation = false;
    });
  }

  void _resetArena() {
    _controller.resetGrid();
    setState(() {
      _stepA = null;
      _stepB = null;
      _metricsA = null;
      _metricsB = null;
      _winnerId = null;
      _showVictoryAnimation = false;
    });
  }

  @override
  void dispose() {
    _executorA?.dispose();
    _executorB?.dispose();
    _controller.dispose();
    super.dispose();
  }

  Duration get _stepDelay => const Duration(milliseconds: 5);

  @override
  Widget build(BuildContext context) {
    final bool isAWinner = _winnerId == 'A';
    final bool isBWinner = _winnerId == 'B';

    return Scaffold(
      backgroundColor: AppTheme.background,
      body: SafeArea(
        child: Stack(
          children: [
            SingleChildScrollView(
              padding: EdgeInsets.fromLTRB(
                MediaQuery.of(context).size.width * 0.05,
                20,
                MediaQuery.of(context).size.width * 0.05,
                32,
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  VisualizerHeader(
                    title: 'Algorithm Battle',
                    subtitle: 'SHOWPIECE ARENA',
                    onBackTap: () => Navigator.pop(context),
                    info: AlgoInfo.battleArena,
                  ),
                  const SizedBox(height: 20),
                  _buildSelectors(),
                  const SizedBox(height: 16),
                  AnimatedBuilder(
                    animation: _controller,
                    builder: (context, _) => Container(
                      key: _toolsKey,
                      child: Opacity(
                        opacity: _isRunning ? 0.5 : 1.0,
                        child: IgnorePointer(
                          ignoring: _isRunning,
                          child: ToolSelector(
                            selectedTool: _controller.selectedTool,
                            onToolSelected: (tool) =>
                                _controller.setTool(tool as PaintTool),
                            isSolving: _isRunning,
                          ),
                        ),
                      ),
                    ),
                  ),
                  ListenableBuilder(
                    listenable: _controller,
                    builder: (context, _) {
                      if (_controller.selectedTool != PaintTool.weight)
                        return const SizedBox.shrink();
                      return Animate(
                        effects: const [
                          FadeEffect(),
                          SlideEffect(begin: Offset(0, 0.5)),
                        ],
                        child: Padding(
                          padding: const EdgeInsets.only(top: 8.0),
                          child: Text(
                            'TIP: Tap weight nodes multiple times to cycle cost (2x → 5x → 10x)',
                            style: AppTheme.labelStyle.copyWith(
                              fontSize: 9,
                              color: AppTheme.warning.withValues(alpha: 0.8),
                            ),
                            textAlign: TextAlign.center,
                          ),
                        ),
                      );
                    },
                  ),
                  const SizedBox(height: 24),
                  AnimatedBuilder(
                    animation: _controller,
                    builder: (context, _) {
                      final bool isWide = MediaQuery.of(context).size.width > 720;
                      final Widget gridA = _buildIndividualGrid(
                        label: 'PLAYER 1: $_algoAId',
                        step: _stepA,
                        executor: _executorA,
                        color: AppTheme.accent,
                        isWinner: isAWinner,
                      );
                      final Widget gridB = _buildIndividualGrid(
                        label: 'PLAYER 2: $_algoBId',
                        step: _stepB,
                        executor: _executorB,
                        color: AppTheme.error,
                        isWinner: isBWinner,
                      );
                      
                      if (isWide) {
                        return Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Expanded(child: gridA),
                            const SizedBox(width: 24),
                            Expanded(child: gridB),
                          ],
                        );
                      }
                      return Column(
                        children: [
                          gridA,
                          const SizedBox(height: 24),
                          gridB,
                        ],
                      );
                    },
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
                        icon: Icons.auto_awesome_rounded,
                        onTap: _isRunning ? () {} : _randomizeMaze,
                        tooltip: 'Randomize Arena',
                      ),
                      const SizedBox(width: 12),
                      _buildControlButton(
                        icon: Icons.restart_alt_rounded,
                        onTap: _isRunning ? () {} : _resetArena,
                        tooltip: 'Clear Grid',
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: GestureDetector(
                          onTap: _isRunning ? null : _runBattle,
                          child: Container(
                            key: _battleCtaKey,
                            height: 56.0,
                            decoration: BoxDecoration(
                              gradient: AppTheme.ctaGradient,
                              borderRadius: BorderRadius.circular(16.0),
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
                                      fontSize: 16.0,
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

            // Victory Overlay
            if (_showVictoryAnimation && _winnerId != null)
              Positioned.fill(
                child: TweenAnimationBuilder<double>(
                  duration: const Duration(milliseconds: 600),
                  tween: Tween(begin: 0.0, end: 1.0),
                  builder: (context, value, child) {
                    return Container(
                      color: Colors.black.withValues(alpha: 0.7 * value),
                      child: Center(
                        child: Opacity(
                          opacity: value,
                          child: Transform.scale(
                            scale: 0.8 + (0.2 * value),
                            child: Column(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(
                                  Icons.emoji_events_rounded,
                                  size: 80,
                                  color: _winnerId == 'A'
                                      ? AppTheme.accent
                                      : AppTheme.error,
                                ),
                                const SizedBox(height: 16),
                                Text(
                                  '${_winnerId == 'A' ? _algoAId : _algoBId} WINS!',
                                  textAlign: TextAlign.center,
                                  style: Theme.of(context)
                                      .textTheme
                                      .headlineMedium
                                      ?.copyWith(
                                        color: Colors.white,
                                        fontWeight: FontWeight.w900,
                                        letterSpacing: 2,
                                        shadows: [
                                          Shadow(
                                            color:
                                                (_winnerId == 'A'
                                                        ? AppTheme.accent
                                                        : AppTheme.error)
                                                    .withValues(alpha: 0.5),
                                            blurRadius: 20,
                                          ),
                                        ],
                                      ),
                                ),
                                const SizedBox(height: 8),
                                Text(
                                  'SUPERIOR PERFORMANCE',
                                  style: Theme.of(context).textTheme.labelSmall
                                      ?.copyWith(
                                        color: Colors.white60,
                                        letterSpacing: 4,
                                      ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    );
                  },
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildSelectors() {
    return Row(
      key: _selectorsKey,
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
      padding: const EdgeInsets.symmetric(horizontal: 12.0),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(12.0),
        border: Border.all(color: color.withValues(alpha: 0.2)),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<String>(
          value: current,
          dropdownColor: AppTheme.surfaceHigh,
          icon: Icon(Icons.keyboard_arrow_down, color: color, size: 18.0),
          isExpanded: true,
          style: TextStyle(
            color: color,
            fontWeight: FontWeight.bold,
            fontSize: 13.0,
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
    final bool isWinningNow = isWinner && _showVictoryAnimation;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(left: 4.0, bottom: 8.0),
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
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8.0,
                    vertical: 2.0,
                  ),
                  decoration: BoxDecoration(
                    color: color,
                    borderRadius: BorderRadius.circular(4.0),
                    boxShadow: isWinningNow
                        ? [
                            BoxShadow(
                              color: color.withValues(alpha: 0.6),
                              blurRadius: 12,
                              spreadRadius: 2,
                            ),
                          ]
                        : null,
                  ),
                  child: Text(
                    isWinningNow ? 'VICTORY' : 'WINNER',
                    style: const TextStyle(
                      color: Colors.black,
                      fontSize: 10.0,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
            ],
          ),
        ),
        TweenAnimationBuilder<double>(
          duration: const Duration(milliseconds: 800),
          curve: Curves.elasticOut,
          tween: Tween(begin: 1.0, end: isWinningNow ? 1.04 : 1.0),
          builder: (context, scale, child) {
            return Transform.scale(
              scale: scale,
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 400),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(16.0),
                  boxShadow: isWinner
                      ? [
                          BoxShadow(
                            color: color.withValues(
                              alpha: isWinningNow ? 0.5 : 0.3,
                            ),
                            blurRadius: isWinningNow ? 40 : 30,
                            spreadRadius: isWinningNow ? 10 : 6,
                          ),
                        ]
                      : null,
                ),
                child: child,
              ),
            );
          },
          child: Container(
            decoration: AppTheme.glassCard(
              radius: 16,
              borderColor: isWinner
                  ? color.withValues(alpha: 0.8)
                  : color.withValues(alpha: 0.2),
            ),
            padding: const EdgeInsets.all(8.0),
            child: AspectRatio(
              aspectRatio: 25 / 15,
              child: GridVisualizerCanvas(
                controller: _controller,
                executor: executor,
                accentColor: color,
                isInteractive: !_isRunning && !_showVictoryAnimation,
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildControlButton({
    required IconData icon,
    required VoidCallback onTap,
    String? tooltip,
  }) {
    Widget child = Container(
      width: 56.0,
      height: 56.0,
      decoration: BoxDecoration(
        color: AppTheme.surfaceHigh,
        borderRadius: BorderRadius.circular(16.0),
        border: Border.all(color: Colors.white.withValues(alpha: 0.06)),
      ),
      child: Icon(icon, color: AppTheme.accentLight, size: 28),
    );

    if (tooltip != null) {
      child = Tooltip(message: tooltip, child: child);
    }

    return GestureDetector(onTap: onTap, child: child);
  }
}

class _BattleAnalyticsSheet extends StatelessWidget {
  final BattleResult result;
  final VoidCallback? onSave;

  const _BattleAnalyticsSheet({required this.result, this.onSave});

  @override
  Widget build(BuildContext context) {
    return PremiumGlassContainer(
      radius: 32,
      padding: EdgeInsets.fromLTRB(
        MediaQuery.of(context).size.width * 0.05,
        12,
        MediaQuery.of(context).size.width * 0.05,
        40,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 40,
            height: 4,
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.2),
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          const SizedBox(height: 24),
          Text(
            'BATTLE ANALYTICS',
            style: Theme.of(context).textTheme.headlineSmall?.copyWith(
              letterSpacing: 4,
              fontWeight: FontWeight.w900,
              color: AppTheme.accentLight,
            ),
          ),
          const SizedBox(height: 32),
          _buildMetricRow(
            context,
            'TIME ELAPSED',
            '${result.algorithm1.executionTime.inMilliseconds}ms',
            '${result.algorithm2.executionTime.inMilliseconds}ms',
            result.winner == result.algorithm1,
          ),
          const SizedBox(height: 16),
          _buildMetricRow(
            context,
            'NODES EXPLORED',
            result.algorithm1.totalSteps.toString(),
            result.algorithm2.totalSteps.toString(),
            result.algorithm1.totalSteps < result.algorithm2.totalSteps,
          ),
          const SizedBox(height: 16),
          _buildMetricRow(
            context,
            'PATH LENGTH',
            result.algorithm1.pathCost.toInt().toString(),
            result.algorithm2.pathCost.toInt().toString(),
            result.algorithm1.pathCost <= result.algorithm2.pathCost,
          ),
          const SizedBox(height: 32),
          Text(
            'KEY INSIGHTS',
            style: Theme.of(
              context,
            ).textTheme.labelSmall?.copyWith(letterSpacing: 2),
          ),
          const SizedBox(height: 12),
          ...result.getAnalysisInsights().map(
            (insight) => Padding(
              padding: const EdgeInsets.only(bottom: 8.0),
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 10,
                ),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.03),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Row(
                  children: [
                    Icon(insight.icon, size: 16, color: AppTheme.accentLight),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        insight.text,
                        style: Theme.of(
                          context,
                        ).textTheme.bodySmall?.copyWith(color: Colors.white70),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
          const SizedBox(height: 24),
          Row(
            children: [
              Expanded(
                child: ElevatedButton.icon(
                  onPressed: onSave,
                  icon: const Icon(Icons.save_rounded),
                  label: const Text('SAVE REPLAY'),
                  style: AppTheme.secondaryButton(),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: ElevatedButton(
                  onPressed: () => Navigator.pop(context),
                  style: AppTheme.primaryButton(),
                  child: const Text('DISMISS'),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildMetricRow(
    BuildContext context,
    String label,
    String valA,
    String valB,
    bool isAWinner,
  ) {
    return Column(
      children: [
        Text(label, style: Theme.of(context).textTheme.labelSmall),
        const SizedBox(height: 8),
        Row(
          children: [
            Expanded(
              child: _MetricPill(
                value: valA,
                color: AppTheme.accent,
                isBetter: isAWinner,
                label: result.algorithm1.algorithmName,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _MetricPill(
                value: valB,
                color: AppTheme.error,
                isBetter: !isAWinner,
                label: result.algorithm2.algorithmName,
              ),
            ),
          ],
        ),
      ],
    );
  }
}

class _MetricPill extends StatelessWidget {
  final String value;
  final String label;
  final Color color;
  final bool isBetter;

  const _MetricPill({
    required this.value,
    required this.label,
    required this.color,
    required this.isBetter,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.05),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: isBetter ? color : color.withValues(alpha: 0.1),
          width: isBetter ? 2 : 1,
        ),
      ),
      child: Column(
        children: [
          Text(
            value,
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: isBetter
                  ? Colors.white
                  : Colors.white.withValues(alpha: 0.5),
            ),
          ),
          Text(
            label,
            style: TextStyle(
              fontSize: 10,
              color: color.withValues(alpha: 0.7),
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }
}
