import 'package:flutter/material.dart';
import 'dart:async';
import 'package:ai_algo_app/core/app_theme.dart';
import 'package:ai_algo_app/core/eightpuzzle_problem.dart';
import 'package:ai_algo_app/core/search_algorithms.dart';
import 'package:ai_algo_app/services/algorithm_executor.dart';
import 'package:ai_algo_app/core/problem_definition.dart';
import 'package:ai_algo_app/widgets/visualizer_widgets.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_animate/flutter_animate.dart';

class EightPuzzleVisualizerScreen extends StatefulWidget {
  const EightPuzzleVisualizerScreen({super.key});

  @override
  State<EightPuzzleVisualizerScreen> createState() =>
      _EightPuzzleVisualizerScreenState();
}

class _EightPuzzleVisualizerScreenState
    extends State<EightPuzzleVisualizerScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _victoryController;
  late EightPuzzleProblem problem;
  late PuzzleState currentState;
  AlgorithmExecutor<PuzzleState>? executor;
  StreamSubscription<AlgorithmStep<PuzzleState>>? _stepSubscription;

  List<PuzzleState> currentPath = [];
  Set<PuzzleState> exploredStates = {};
  // Track last UI update time to avoid excessive setState calls
  DateTime _lastUiUpdate = DateTime.fromMillisecondsSinceEpoch(0);
  int stepCount = 0;
  int nodesExplored = 0;
  bool isSolving = false;
  bool isSolved = false;
  final List<String> algorithms = ['BFS', 'A*', 'Greedy'];
  String selectedDifficulty = 'Medium';
  final Map<String, int> difficulties = {
    'Easy': 10,
    'Medium': 25,
    'Hard': 50,
  };
  String selectedAlgorithm = 'A*';
  double executionSpeed = 2.0;
  String _statusMessage = 'Ready to solve';

  Duration get _stepDelay {
    if (executionSpeed >= 4.9) return Duration.zero;
    final milliseconds = (220 / executionSpeed).round().clamp(10, 2200);
    return Duration(milliseconds: milliseconds);
  }

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

  void _resetPuzzle() {
    _stepSubscription?.cancel();
    _stepSubscription = null;
    if (executor != null) {
      executor!.stop();
      executor!.dispose();
      executor = null;
    }

    // Default start state (solved goal)
    problem = EightPuzzleProblem(
      initialState: EightPuzzleProblem.defaultGoalState,
    );
    currentState = problem.initialState;
    currentPath = [currentState];
    exploredStates.clear();
    stepCount = 0;
    nodesExplored = 0;
    isSolving = false;
    isSolved = false;
    _statusMessage = 'Ready to solve';
  }

  Future<void> _shuffle() async {
    if (isSolving) return;

    setState(() {
      isSolving = true;
      isSolved = false;
      _statusMessage = 'Scrambling...';
    });

    final depth = difficulties[selectedDifficulty] ?? 25;
    PuzzleState tempState = currentState;

    // Visual Scramble: Fast sequence of valid moves
    for (int i = 0; i < depth; i++) {
      final neighbors = problem.getNeighbors(tempState);
      // Pick a random neighbor
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
      exploredStates.clear();
      _statusMessage = 'Shuffle complete';
    });
  }

  Future<void> _solvePuzzle() async {
    if (isSolving) return;

    if (!EightPuzzleProblem.isSolvable(currentState)) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('This puzzle configuration is unsolvable!'),
          backgroundColor: Colors.redAccent,
        ),
      );
      setState(() => _statusMessage = 'Unsolvable State');
      return;
    }

    setState(() {
      isSolving = true;
      isSolved = false;
      exploredStates.clear();
      currentPath = [currentState];
      stepCount = 0;
      nodesExplored = 0;
      _statusMessage = 'Starting $selectedAlgorithm...';
    });

    late SearchAlgorithm<PuzzleState> algorithm;
    switch (selectedAlgorithm) {
      case 'BFS':
        algorithm = BFSAlgorithm<PuzzleState>();
        break;
      case 'A*':
        algorithm = AStarAlgorithm<PuzzleState>();
        break;
      case 'Greedy':
        algorithm = GreedyBestFirstAlgorithm<PuzzleState>();
        break;
      default:
        algorithm = AStarAlgorithm<PuzzleState>();
    }

    executor = AlgorithmExecutor<PuzzleState>(
      algorithm: algorithm,
      problem: problem,
      stepDelayMs: _stepDelay.inMilliseconds,
    );

    try {
      await executor!.start();

      await _stepSubscription?.cancel();
      _stepSubscription = executor!.stepStream.listen(
        (step) {
          if (!mounted) return;

          // Update internal values always, but throttle UI rebuilds
          stepCount = step.stepCount;
          nodesExplored = executor!.exploredSet.length;
          exploredStates = executor!.exploredSet.cast<PuzzleState>().toSet();

          if (step.path.isNotEmpty) {
            currentPath = step.path;
            currentState = step.path.last;
          } else if (step.newlyExplored.isNotEmpty) {
            currentState = step.newlyExplored.last;
          }

          _statusMessage = step.message ?? _statusMessage;

          if (step.isGoalReached) {
            isSolved = true;
            isSolving = false;
            final g = currentPath.length - 1;
            _statusMessage = 'Goal Reached! Cost: $g moves';
            _victoryController.forward(from: 0.0);
          } else {
            // Update f = g + h status
            final g = currentPath.length - 1;
            final h = problem.heuristic(currentState).toInt();
            final f = g + h;
            _statusMessage = 'Searching (f=$f = g:$g + h:$h)';
          }

          final now = DateTime.now();
          if (now.difference(_lastUiUpdate) >=
              const Duration(milliseconds: 50)) {
            _lastUiUpdate = now;
            setState(() {});
          }
        },
        onError: (error) {
          if (mounted) {
            ScaffoldMessenger.of(
              context,
            ).showSnackBar(SnackBar(content: Text('Error: $error')));
            setState(() {
              isSolving = false;
              _statusMessage = 'Error: $error';
            });
          }
        },
        onDone: () {
          if (mounted) {
            setState(() => isSolving = false);
          }
        },
      );
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Error: $e')));
        setState(() {
          isSolving = false;
          _statusMessage = 'Error: $e';
        });
      }
    }
  }

  void _reset() {
    if (isSolving) executor?.stop();
    setState(() => _resetPuzzle());
  }

  void _pauseResume() {
    if (isSolving) {
      executor?.pause();
      setState(() {
        isSolving = false;
        _statusMessage = 'Paused';
      });
    } else if (stepCount > 0) {
      executor?.resume();
      setState(() {
        isSolving = true;
        _statusMessage = 'Resumed';
      });
    }
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
        exploredStates.clear();
        isSolved = problem.isGoal(currentState);
        _statusMessage = isSolved
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
                borderRadius: BorderRadius.vertical(top: Radius.circular(24.r)),
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
                      width: 40.w,
                      height: 4.h,
                      margin: EdgeInsets.only(bottom: 20.h),
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.2),
                        borderRadius: BorderRadius.circular(2.r),
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
                padding: EdgeInsets.only(right: 12.w),
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
                      horizontal: 16.w,
                      vertical: 10.h,
                    ),
                    decoration: BoxDecoration(
                      color: isSelected
                          ? AppTheme.accent.withValues(alpha: 0.15)
                          : AppTheme.surfaceHigh,
                      borderRadius: BorderRadius.circular(8.r),
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
                    _solvePuzzle().then((_) => setModalState(() {}));
                  },
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.accent,
              foregroundColor: Colors.white,
              padding: EdgeInsets.symmetric(vertical: 16.h),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12.r),
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
  void dispose() {
    _stepSubscription?.cancel();
    _victoryController.dispose();
    executor?.dispose();
    super.dispose();
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
              VisualizerHeader(
                title: '8-Puzzle Solver',
                subtitle: 'SLIDING TILE VIZ',
                onBackTap: () => Navigator.pop(context),
              ),
              const SizedBox(height: 20),

              Row(
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
              ),
              const SizedBox(height: 14),

              Center(
                child: StatusBanner(
                  message: _statusMessage,
                  isSolved: isSolved,
                  isSolving: isSolving,
                ).animate(target: isSolved ? 1 : 0).shimmer(
                  duration: 3.seconds,
                  color: AppTheme.success.withValues(alpha: 0.15),
                ),
              ),
              const SizedBox(height: 16),

              // Difficulty and Shuffle Row
              Row(
                children: [
                  Expanded(
                    child: Container(
                      padding: EdgeInsets.symmetric(horizontal: 12.w),
                      decoration: AppTheme.glassCard(radius: 12),
                      child: DropdownButtonHideUnderline(
                        child: DropdownButton<String>(
                          value: selectedDifficulty,
                          isExpanded: true,
                          dropdownColor: AppTheme.surfaceHighest,
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 13.sp,
                          ),
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
                      padding: EdgeInsets.symmetric(
                        horizontal: 16.w,
                        vertical: 12.h,
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12.r),
                      ),
                    ),
                  ),
                ],
              ),

              _buildPuzzleVisualization(),
              const SizedBox(height: 24),

              VisualizerControls(
                isSolving: isSolving,
                isSolved: isSolved,
                stepCount: stepCount,
                onSolve: _showAISolveMenu,
                onPauseResume: _pauseResume,
                onClear: _reset,
              ),
            ],
          ),
        ),
      ),
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
                borderRadius: BorderRadius.circular(16.r),
                child: Container(
                  padding: EdgeInsets.all(12.r),
                  decoration: AppTheme.glassCardAccent(radius: 16),
                  child: _buildPuzzleGrid(currentState, isInteractive: true),
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
                padding: EdgeInsets.all(8.r),
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
                // We generate widgets for each tile value (1-8)
                // Empty space (0) doesn't need a visible tile
                final value = i + 1;
                if (value == 9) {
                  return const SizedBox.shrink();
                } // value 9 represents empty in this loop's logic if we use 0-8

                // Let's be explicit: tiles are 1, 2, 3, 4, 5, 6, 7, 8.
                // The empty space is 0.
                final tileValue = value < 9 ? value : 0;
                if (tileValue == 0) {
                  return const SizedBox.shrink();
                }

                // Find where this tile value is in the current state
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
                    child: Container(
                      decoration: BoxDecoration(
                        color: isSolved
                            ? AppTheme.success.withValues(alpha: 0.08)
                            : AppTheme.surfaceHigh,
                        borderRadius: BorderRadius.circular(
                          isInteractive ? 12.r : 6.r,
                        ),
                        border: Border.all(
                          color: isSolved
                              ? AppTheme.success.withValues(alpha: 0.4)
                              : Colors.white.withValues(alpha: 0.1),
                          width: 1.w,
                        ),
                        boxShadow: isSolved
                            ? [
                                BoxShadow(
                                  color: AppTheme.success.withValues(alpha: 0.15),
                                  blurRadius: 15.r,
                                  spreadRadius: -2.r,
                                )
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
                    ).animate(target: isSolved ? 1 : 0).shimmer(
                      duration: 3.seconds,
                      color: AppTheme.success.withValues(alpha: 0.2),
                    ).moveY(
                      begin: 0,
                      end: -4,
                      duration: 1200.ms,
                      curve: Curves.easeInOutSine,
                    ).scale(
                      begin: const Offset(1, 1),
                      end: const Offset(1.02, 1.02),
                      duration: 1200.ms,
                      curve: Curves.easeInOutSine,
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
