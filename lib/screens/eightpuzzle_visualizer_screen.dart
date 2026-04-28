import 'package:algo_arena/models/algo_info.dart';
import 'package:algo_arena/widgets/skeleton_loaders.dart';
import 'package:algo_arena/widgets/visualizer_widgets.dart';
import 'package:flutter/material.dart';
import 'dart:async';
import 'package:algo_arena/core/app_theme.dart';
import 'package:algo_arena/core/eightpuzzle_problem.dart';
import 'package:algo_arena/core/problem_definition.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:algo_arena/screens/visualizer_base_mixin.dart';
import 'package:algo_arena/services/api_service.dart';

class EightPuzzleVisualizerScreen extends ConsumerStatefulWidget {
  const EightPuzzleVisualizerScreen({super.key});

  @override
  ConsumerState<EightPuzzleVisualizerScreen> createState() =>
      _EightPuzzleVisualizerScreenState();
}

class _EightPuzzleVisualizerScreenState
    extends ConsumerState<EightPuzzleVisualizerScreen>
    with TickerProviderStateMixin, VisualizerBaseMixin<EightPuzzleVisualizerScreen, PuzzleState> {
  late AnimationController _victoryController;
  late EightPuzzleProblem problem;
  late PuzzleState currentState;

  List<PuzzleState> currentPath = [];
  
  final List<String> algorithms = ['BFS', 'A*', 'Greedy'];
  String selectedDifficulty = 'Medium';
  final Map<String, int> difficulties = {'Easy': 10, 'Medium': 25, 'Hard': 50};
  String selectedAlgorithm = 'A*';

  // Widget caching: static sections only rebuild when config changes
  Widget? _cachedHeader;
  Widget? _cachedStatsRow;
  Widget? _cachedConfigRow;
  Widget? _cachedControls;
  int _lastConfigHash = 0;

  /// Hash of all config state that static widgets depend on
  int get _configHash => Object.hash(
    selectedDifficulty,
    selectedAlgorithm,
    isSolving,
    isSolved,
    stepCount,
    executionSpeed,
    executor?.frontierSize,
    currentPath.length,
    statusMessage,
  );

  @override
  String get algorithmId => selectedAlgorithm;

  @override
  void initState() {
    super.initState();
    _victoryController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
      value: 1.0,
    );
    _resetPuzzle();
  }

  @override
  void dispose() {
    _victoryController.dispose();
    super.dispose();
  }

  @override
  Map<String, dynamic> getProblemSnapshot() {
    return {
      'type': 'puzzle',
      'initialState': problem.initialState.tiles,
      'goalState': problem.goalState.tiles,
    };
  }

  @override
  Future<void> onStep(AlgorithmStep<PuzzleState> step) async {
    if (step.path.isNotEmpty) {
      currentPath = step.path;
      currentState = step.path.last;
    } else if (step.newlyExplored.isNotEmpty) {
      currentState = step.newlyExplored.last;
    }

    // Update status message with search info
    final g = currentPath.length - 1;
    final h = problem.heuristic(currentState).toInt();
    final f = g + h;
    statusMessage = 'Searching (f=$f = g:$g + h:$h)';
  }

  @override
  Future<void> onGoalReached(AlgorithmStep<PuzzleState> step) async {
    final g = currentPath.length - 1;
    statusMessage = 'Goal Reached! Cost: $g moves';
    _victoryController.forward(from: 0.0);
  }

  @override
  Future<void> onAutoSave() async {
    // Implement auto-save for 8-puzzle
    try {
      final runData = {
        'algorithm': selectedAlgorithm,
        'type': 'puzzle',
        'isBattle': false,
        'snapshot': getProblemSnapshot(),
        'metadata': {
          'difficulty': selectedDifficulty,
          'foundPath': isSolved,
          'pathLength': currentPath.length - 1,
          'nodesExplored': nodesExplored,
          'heuristic': 'Manhattan',
        },
        'steps': executor!.history!.length, // Simplistic for now
        'durationMs': executor!.executionTime.inMilliseconds,
        'timestamp': DateTime.now().toIso8601String(),
      };
      await ApiService().saveRun(runData);
    } catch (e) {
      debugPrint('Error auto-saving 8-puzzle run: $e');
    }
  }

  void _resetPuzzle() {
    resetBase();
    problem = EightPuzzleProblem(
      initialState: EightPuzzleProblem.defaultGoalState,
    );
    currentState = problem.initialState;
    currentPath = [currentState];
  }

  Future<void> _shuffle() async {
    if (isSolving) return;

    setState(() {
      isSolving = true;
      isSolved = false;
      statusMessage = 'Scrambling...';
    });

    final depth = difficulties[selectedDifficulty] ?? 25;
    PuzzleState tempState = currentState;

    for (int i = 0; i < depth; i++) {
      final neighbors = problem.getNeighbors(tempState);
      final next =
          neighbors[DateTime.now().microsecondsSinceEpoch % neighbors.length];

      setState(() {
        currentState = next;
      });

      await Future.delayed(const Duration(milliseconds: 30));
      tempState = next;
    }

    setState(() {
      problem = EightPuzzleProblem(initialState: currentState);
      isSolving = false;
      stepCount = 0;
      nodesExplored = 0;
      currentPath = [currentState];
      statusMessage = 'Shuffle complete';
    });
  }

  void _handleTileTap(int index) {
    if (isSolving) return;

    final emptyIndex = currentState.tiles.indexOf(0);
    final emptyRow = emptyIndex ~/ 3;
    final emptyCol = emptyIndex % 3;

    final tapRow = index ~/ 3;
    final tapCol = index % 3;

    final isAdjacent =
        (emptyRow == tapRow && (emptyCol - tapCol).abs() == 1) ||
        (emptyCol == tapCol && (emptyRow - tapRow).abs() == 1);

    if (isAdjacent) {
      setState(() {
        final newTiles = List<int>.from(currentState.tiles);
        newTiles[emptyIndex] = newTiles[index];
        newTiles[index] = 0;
        currentState = PuzzleState(newTiles);

        problem = EightPuzzleProblem(initialState: currentState);
        stepCount = 0;
        nodesExplored = 0;
        currentPath = [currentState];
        isSolved = problem.isGoal(currentState);
        statusMessage = isSolved
            ? 'Goal reached manually!'
            : 'Playing manually';
        if (isSolved) {
          _victoryController.forward(from: 0.0);
        }
      });
    }
  }

  void _showAISolveMenu() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setModalState) {
            return Container(
              padding: EdgeInsets.fromLTRB(
                20,
                20,
                20,
                MediaQuery.of(context).viewInsets.bottom + 20,
              ),
              decoration: BoxDecoration(
                color: AppTheme.surfaceVariant.withValues(alpha: 0.98),
                borderRadius: BorderRadius.vertical(top: Radius.circular(24.0)),
                border: Border(
                  top: BorderSide(color: Colors.white.withValues(alpha: 0.12)),
                ),
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Center(
                    child: Container(
                      width: 40.0,
                      height: 4.0,
                      margin: EdgeInsets.only(bottom: 20.0),
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.2),
                        borderRadius: BorderRadius.circular(2.0),
                      ),
                    ),
                  ),
                  Text(
                    'AI Solver Config',
                    style: Theme.of(context).textTheme.headlineSmall,
                  ),
                  const SizedBox(height: 20),
                  _buildAlgorithmSelectorModal(setModalState),
                  const SizedBox(height: 20),
                  _buildSpeedControlModal(setModalState),
                  const SizedBox(height: 24),
                  _buildControlButtonsModal(setModalState),
                ],
              ),
            );
          },
        );
      },
    );
  }

  Widget _buildAlgorithmSelectorModal(StateSetter setModalState) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'ALGORITHM',
          style: Theme.of(
            context,
          ).textTheme.labelSmall?.copyWith(color: AppTheme.textMuted),
        ),
        const SizedBox(height: 12),
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: Row(
            children: algorithms.map((algo) {
              final isSelected = selectedAlgorithm == algo;
              return Padding(
                padding: EdgeInsets.only(right: 12.0),
                child: GestureDetector(
                  onTap: () {
                    if (!isSolving) {
                      setState(() => selectedAlgorithm = algo);
                      setModalState(() {});
                    }
                  },
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 200),
                    padding: EdgeInsets.symmetric(
                      horizontal: 16.0,
                      vertical: 10.0,
                    ),
                    decoration: BoxDecoration(
                      color: isSelected
                          ? AppTheme.accent.withValues(alpha: 0.15)
                          : AppTheme.surfaceHigh,
                      borderRadius: BorderRadius.circular(8.0),
                      border: Border.all(
                        color: isSelected
                            ? AppTheme.accent
                            : Colors.white.withValues(alpha: 0.05),
                      ),
                    ),
                    child: Text(
                      algo,
                      style: Theme.of(context).textTheme.labelLarge?.copyWith(
                        color: isSelected
                            ? AppTheme.accentLight
                            : AppTheme.textMuted,
                      ),
                    ),
                  ),
                ),
              );
            }).toList(),
          ),
        ),
      ],
    );
  }

  Widget _buildSpeedControlModal(StateSetter setModalState) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'EXECUTION SPEED',
              style: Theme.of(
                context,
              ).textTheme.labelSmall?.copyWith(color: AppTheme.textMuted),
            ),
            Text(
              '${executionSpeed.toStringAsFixed(1)}x',
              style: Theme.of(
                context,
              ).textTheme.labelLarge?.copyWith(color: AppTheme.accentLight),
            ),
          ],
        ),
        const SizedBox(height: 8),
        SliderTheme(
          data: SliderTheme.of(context).copyWith(
            activeTrackColor: AppTheme.accent,
            inactiveTrackColor: AppTheme.surfaceHighest,
            thumbColor: Colors.white,
            overlayColor: AppTheme.accent.withValues(alpha: 0.2),
          ),
          child: Slider(
            value: executionSpeed,
            min: 0.1,
            max: 5.0,
            onChanged: isSolving
                ? null
                : (value) {
                    setState(() => executionSpeed = value);
                    setModalState(() {});
                  },
          ),
        ),
      ],
    );
  }

  Widget _buildControlButtonsModal(StateSetter setModalState) {
    return Row(
      children: [
        Expanded(
          child: ElevatedButton(
            onPressed: isSolving
                ? null
                : () {
                    solve().then((_) => setModalState(() {}));
                  },
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.accent,
              foregroundColor: Colors.white,
              padding: EdgeInsets.symmetric(vertical: 16.0),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12.0),
              ),
            ),
            child: const Text(
              'START SOLVER',
              style: TextStyle(letterSpacing: 1.5, fontWeight: FontWeight.bold),
            ),
          ),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.background,
      body: SafeArea(
        child: !isShellReady 
            ? const Center(child: CircularProgressIndicator())
            : _buildFullContent(),
      ),
    );
  }

  /// Full content built after the defer period.
  /// Uses ListView for viewport culling — off-screen sections don't build.
  Widget _buildFullContent() {
    // Rebuild cached widgets only when their dependencies change
    final currentConfigHash = _configHash;
    if (currentConfigHash != _lastConfigHash) {
      _lastConfigHash = currentConfigHash;
      _cachedHeader = _buildHeader();
      _cachedStatsRow = _buildStatsRow();
      _cachedConfigRow = _buildConfigRow();
      _cachedControls = RepaintBoundary(child: _buildControls());
    }

    return ListView(
      padding: const EdgeInsets.fromLTRB(20, 20, 20, 32),
      children: [
        _cachedHeader!,
        const SizedBox(height: 20),
        _cachedStatsRow!,
        const SizedBox(height: 14),
        _buildStatusSection(),
        const SizedBox(height: 16),
        _cachedConfigRow!,
        const SizedBox(height: 20),
        _buildPuzzleVisualization(),
        const SizedBox(height: 24),
        _cachedControls!,
      ],
    );
  }

  Widget _buildHeader() {
    return VisualizerHeader(
      title: '8-Puzzle Solver',
      subtitle: 'SLIDING TILE VIZ',
      onBackTap: () => Navigator.pop(context),
      comparisonInfos: AlgoInfo.eightPuzzle,
      initialKey: selectedAlgorithm,
    );
  }

  Widget _buildStatsRow() {
    return Row(
      children: [
        Expanded(
          child: GlassStatCard(label: 'STEPS', value: stepCount),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: GlassStatCard(label: 'NODES', value: nodesExplored),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: GlassStatCard(
            label: 'FRONTIER',
            value: executor?.frontierSize ?? 0,
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: GlassStatCard(
            label: 'DEPTH',
            value: currentPath.length - 1,
          ),
        ),
      ],
    );
  }

  Widget _buildStatusSection() {
    return Center(
      child: StatusBanner(
        message: statusMessage,
        isSolved: isSolved,
        isSolving: isSolving,
      ).animate(
        target: isSolved ? 1 : 0,
        onPlay: (c) => isSolved ? c.repeat(reverse: true) : c.stop(),
      )
       .shimmer(duration: 1200.ms, color: AppTheme.success.withValues(alpha: 0.3))
       .animate(
        target: isSolving ? 1 : 0,
        onPlay: (c) => isSolving ? c.repeat(reverse: true) : c.stop(),
      )
       .shimmer(duration: 2.seconds, color: AppTheme.warning.withValues(alpha: 0.2))
       .shake(hz: 3, curve: Curves.easeInOut),
    );
  }

  Widget _buildConfigRow() {
    return Row(
      children: [
        Expanded(
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 12.0),
            decoration: AppTheme.glassCard(radius: 12),
            child: DropdownButtonHideUnderline(
              child: DropdownButton<String>(
                value: selectedDifficulty,
                isExpanded: true,
                dropdownColor: AppTheme.surfaceHighest,
                style: const TextStyle(color: Colors.white, fontSize: 13.0),
                items: difficulties.keys
                    .map(
                      (d) =>
                          DropdownMenuItem(value: d, child: Text(d)),
                    )
                    .toList(),
                onChanged: isSolving
                    ? null
                    : (v) {
                        if (v != null) {
                          setState(() => selectedDifficulty = v);
                        }
                      },
              ),
            ),
          ),
        ),
        const SizedBox(width: 10),
        ElevatedButton.icon(
          onPressed: isSolving ? null : _shuffle,
          icon: const Icon(Icons.shuffle, size: 18),
          label: const Text('SHUFFLE'),
          style: ElevatedButton.styleFrom(
            backgroundColor: AppTheme.surfaceHighest,
            foregroundColor: AppTheme.accentLight,
            padding: const EdgeInsets.symmetric(
              horizontal: 16.0,
              vertical: 12.0,
            ),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12.0),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildControls() {
    return VisualizerControls(
      isSolving: isSolving,
      isSolved: isSolved,
      stepCount: stepCount,
      onSolve: _showAISolveMenu,
      onPauseResume: pauseResume,
      onClear: _resetPuzzle,
    );
  }

  Widget _buildPuzzleVisualization() {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          flex: 2,
          child: Column(
            children: [
              Text(
                'Current State',
                style: Theme.of(
                  context,
                ).textTheme.labelSmall?.copyWith(color: AppTheme.textMuted),
              ),
              const SizedBox(height: 12),
              ClipRRect(
                borderRadius: BorderRadius.circular(16.0),
                child: Container(
                  padding: EdgeInsets.all(12.0),
                  decoration: AppTheme.glassCardAccent(radius: 16),
                  child: !isGridReady 
                      ? const SkeletonEightPuzzle()
                      : _buildPuzzleGrid(currentState, isInteractive: true)
                        .animate()
                        .fadeIn(duration: 400.ms),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(width: 24),
        Expanded(
          flex: 1,
          child: Column(
            children: [
              Text(
                'Goal',
                style: Theme.of(
                  context,
                ).textTheme.labelSmall?.copyWith(color: AppTheme.textMuted),
              ),
              const SizedBox(height: 12),
              Container(
                padding: EdgeInsets.all(8.0),
                decoration: AppTheme.glassCard(radius: 12),
                child: _buildPuzzleGrid(
                  problem.goalState,
                  isInteractive: false,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildPuzzleGrid(PuzzleState state, {required bool isInteractive}) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final size = constraints.maxWidth;
        final tileSize = (size - 12) / 3; // 6px spacing * 2 gaps = 12px

        return RepaintBoundary(
          child: SizedBox(
            height: size,
            width: size,
            child: Stack(
              children: List.generate(9, (i) {
                final value = i + 1;
                if (value == 9) {
                  return const SizedBox.shrink();
                } 

                final tileValue = value < 9 ? value : 0;
                if (tileValue == 0) {
                  return const SizedBox.shrink();
                }

                final pos = state.tiles.indexOf(tileValue);
                if (pos == -1) return const SizedBox.shrink();

                final row = pos ~/ 3;
                final col = pos % 3;

                return AnimatedPositioned(
                  key: ValueKey('tile_$tileValue'),
                  duration: const Duration(milliseconds: 200),
                  curve: Curves.easeOutBack,
                  top: row * (tileSize + 6),
                  left: col * (tileSize + 6),
                  width: tileSize,
                  height: tileSize,
                  child: GestureDetector(
                    onTap: isInteractive ? () => _handleTileTap(pos) : null,
                    child:
                        Container(
                              decoration: BoxDecoration(
                                color: isSolved
                                    ? AppTheme.success.withValues(alpha: 0.08)
                                    : AppTheme.surfaceHigh,
                                borderRadius: BorderRadius.circular(
                                  isInteractive ? 12.0 : 6.0,
                                ),
                                border: Border.all(
                                  color: isSolved
                                      ? AppTheme.success.withValues(alpha: 0.4)
                                      : Colors.white.withValues(alpha: 0.1),
                                  width: 1.0,
                                ),
                                boxShadow: isSolved
                                    ? [
                                        BoxShadow(
                                          color: AppTheme.success.withValues(
                                            alpha: 0.15,
                                          ),
                                          blurRadius: 15.0,
                                          spreadRadius: -2.0,
                                        ),
                                      ]
                                    : null,
                              ),
                              child: Center(
                                child: Text(
                                  '$tileValue',
                                  style: isInteractive
                                      ? Theme.of(
                                          context,
                                        ).textTheme.headlineMedium?.copyWith(
                                          fontWeight: FontWeight.bold,
                                          color: Colors.white,
                                        )
                                      : Theme.of(
                                          context,
                                        ).textTheme.bodyMedium?.copyWith(
                                          fontWeight: FontWeight.bold,
                                          color: Colors.white,
                                        ),
                                ),
                              ),
                            )
                            .animate(target: isSolving ? 1 : 0)
                            .tint(color: AppTheme.accent.withValues(alpha: 0.1), duration: 1.seconds)
                            .shake(hz: 2, rotation: 0.01, duration: 1.seconds)
                            .animate(
                              target: isSolved ? 1 : 0,
                              onPlay: (c) => isSolved ? c.repeat(reverse: true) : c.stop(),
                            )
                            .shimmer(
                              duration: 2.seconds,
                              color: AppTheme.success.withValues(alpha: 0.3),
                            )
                            .moveY(
                              begin: 0,
                              end: -5,
                              duration: 1.seconds,
                              curve: Curves.easeInOut,
                            )
                            .then()
                            .scale(
                              begin: const Offset(1, 1),
                              end: const Offset(1.04, 1.04),
                              duration: 1.seconds,
                              curve: Curves.easeInOut,
                            ),
                  ),
                );
              }),
            ),
          ),
        );
      },
    );
  }
}
