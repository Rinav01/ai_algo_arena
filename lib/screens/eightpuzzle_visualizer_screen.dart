import 'package:flutter/material.dart';
import 'dart:async';
import 'dart:ui';
import '../core/app_theme.dart';
import '../core/eightpuzzle_problem.dart';
import '../core/search_algorithms.dart';
import '../services/algorithm_executor.dart';
import '../core/problem_definition.dart';
import '../widgets/visualizer_widgets.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

class EightPuzzleVisualizerScreen extends StatefulWidget {
  const EightPuzzleVisualizerScreen({super.key});

  @override
  State<EightPuzzleVisualizerScreen> createState() =>
      _EightPuzzleVisualizerScreenState();
}

class _EightPuzzleVisualizerScreenState
    extends State<EightPuzzleVisualizerScreen> {
  late EightPuzzleProblem problem;
  late PuzzleState currentState;
  AlgorithmExecutor<PuzzleState>? executor;
  StreamSubscription<AlgorithmStep<PuzzleState>>? _stepSubscription;

  List<PuzzleState> currentPath = [];
  Set<String> exploredStates = {};
  int stepCount = 0;
  int nodesExplored = 0;
  bool isSolving = false;
  bool isSolved = false;
  String selectedAlgorithm = 'A*';
  double executionSpeed = 2.0;
  String _statusMessage = 'Ready to solve';

  final List<String> algorithms = ['BFS', 'DFS', 'A*', 'Dijkstra'];

  Duration get _stepDelay {
    final milliseconds = (220 / executionSpeed).round().clamp(10, 2200);
    return Duration(milliseconds: milliseconds);
  }

  @override
  void initState() {
    super.initState();
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
    // Create slightly scrambled puzzle for testing
    final scrambled = EightPuzzleProblem.scramble(12);
    problem = EightPuzzleProblem(initialState: scrambled);
    currentState = problem.initialState;
    currentPath = [currentState];
    exploredStates.clear();
    stepCount = 0;
    nodesExplored = 0;
    isSolving = false;
    isSolved = false;
    selectedAlgorithm = 'A*';
    _statusMessage = 'Ready to solve';
  }

  Future<void> _solvePuzzle() async {
    if (isSolving) return;

    setState(() {
      isSolving = true;
      isSolved = false;
      exploredStates.clear();
      currentPath = [problem.initialState];
      stepCount = 0;
      nodesExplored = 0;
      _statusMessage = 'Starting $selectedAlgorithm...';
    });

    late SearchAlgorithm<PuzzleState> algorithm;
    switch (selectedAlgorithm) {
      case 'BFS':
        algorithm = BFSAlgorithm<PuzzleState>();
        break;
      case 'DFS':
        algorithm = DFSAlgorithm<PuzzleState>();
        break;
      case 'A*':
        algorithm = AStarAlgorithm<PuzzleState>();
        break;
      case 'Dijkstra':
        algorithm = DijkstraAlgorithm<PuzzleState>();
        break;
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

          setState(() {
            stepCount = step.stepCount;
            nodesExplored = executor!.exploredSet.length;
            exploredStates = executor!.exploredSet.map((s) => s.toString()).toSet();

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
              _statusMessage =
                  'Solution found! Path length: ${currentPath.length} moves';
            }
          });
        },
        onError: (error) {
          if (mounted) {
            ScaffoldMessenger.of(context)
                .showSnackBar(SnackBar(content: Text('Error: $error')));
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
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text('Error: $e')));
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

  void _step() {
    if (isSolving) return;

    if (executor == null) {
      late SearchAlgorithm<PuzzleState> algorithm;
      switch (selectedAlgorithm) {
        case 'BFS':
          algorithm = BFSAlgorithm<PuzzleState>();
          break;
        case 'DFS':
          algorithm = DFSAlgorithm<PuzzleState>();
          break;
        case 'A*':
          algorithm = AStarAlgorithm<PuzzleState>();
          break;
        case 'Dijkstra':
          algorithm = DijkstraAlgorithm<PuzzleState>();
          break;
      }
      executor = AlgorithmExecutor<PuzzleState>(
        algorithm: algorithm,
        problem: problem,
      stepDelayMs: _stepDelay.inMilliseconds,
    );
      executor!.start();
      _stepSubscription?.cancel();
      _stepSubscription = executor!.stepStream.listen((step) {
        if (!mounted) return;
        setState(() {
          stepCount = step.stepCount;
          nodesExplored = executor!.exploredSet.length;
          exploredStates = executor!.exploredSet.map((s) => s.toString()).toSet();

          if (step.path.isNotEmpty) {
            currentPath = step.path;
            currentState = step.path.last;
          } else if (step.newlyExplored.isNotEmpty) {
            currentState = step.newlyExplored.last;
          }

          if (step.isGoalReached) {
            isSolved = true;
            isSolving = false;
          }
        });
      });
    }

    executor?.stepOnce();
  }

  void _handleTileTap(int index) {
    if (isSolving) return;

    final emptyIndex = currentState.tiles.indexOf(0);
    final emptyRow = emptyIndex ~/ 3;
    final emptyCol = emptyIndex % 3;

    final tapRow = index ~/ 3;
    final tapCol = index % 3;

    final isAdjacent = (emptyRow == tapRow && (emptyCol - tapCol).abs() == 1) ||
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
        _statusMessage = isSolved ? 'Goal reached manually!' : 'Playing manually';
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
            return ClipRect(
              child: BackdropFilter(
                filter: ImageFilter.blur(sigmaX: 16, sigmaY: 16),
                child: Container(
                  padding: EdgeInsets.fromLTRB(20, 20, 20, MediaQuery.of(context).viewInsets.bottom + 20),
                  decoration: BoxDecoration(
                    color: AppTheme.surfaceVariant.withValues(alpha: 0.8),
                    borderRadius: BorderRadius.vertical(top: Radius.circular(24.r)),
                    border: Border(top: BorderSide(color: Colors.white.withValues(alpha: 0.1))),
                  ),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Center(
                        child: Container(
                          width: 40.w, height: 4.h,
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
                ),
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
          style: Theme.of(context).textTheme.labelSmall?.copyWith(color: AppTheme.textMuted),
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
                    padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 10.h),
                    decoration: BoxDecoration(
                      color: isSelected ? AppTheme.accent.withValues(alpha: 0.15) : AppTheme.surfaceHigh,
                      borderRadius: BorderRadius.circular(8.r),
                      border: Border.all(
                        color: isSelected ? AppTheme.accent : Colors.white.withValues(alpha: 0.05),
                      ),
                    ),
                    child: Text(
                      algo,
                      style: Theme.of(context).textTheme.labelLarge?.copyWith(
                        color: isSelected ? AppTheme.accentLight : AppTheme.textMuted,
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
              style: Theme.of(context).textTheme.labelSmall?.copyWith(color: AppTheme.textMuted),
            ),
            Text(
              '${executionSpeed.toStringAsFixed(1)}x',
              style: Theme.of(context).textTheme.labelLarge?.copyWith(color: AppTheme.accentLight),
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
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12.r)),
            ),
            child: const Text('AUTO SOLVE', style: TextStyle(letterSpacing: 1.5, fontWeight: FontWeight.bold)),
          ),
        ),
      ],
    );
  }

  @override
  void dispose() {
    _stepSubscription?.cancel();
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
                  Expanded(child: GlassStatCard(label: 'STEPS', value: stepCount)),
                  const SizedBox(width: 10),
                  Expanded(child: GlassStatCard(label: 'EXPLORED', value: nodesExplored)),
                  const SizedBox(width: 10),
                  Expanded(child: GlassStatCard(label: 'PATH', value: currentPath.length)),
                ],
              ),
              const SizedBox(height: 14),

              Center(
                child: StatusBanner(
                  message: _statusMessage,
                  isSolved: isSolved,
                  isSolving: isSolving,
                ),
              ),
              const SizedBox(height: 20),

              _buildPuzzleVisualization(),
              const SizedBox(height: 24),

              VisualizerControls(
                isSolving: isSolving,
                isSolved: isSolved,
                stepCount: stepCount,
                onSolve: _showAISolveMenu,
                onPauseResume: _pauseResume,
                onStep: _step,
                onReset: _reset,
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
                style: Theme.of(context).textTheme.labelSmall?.copyWith(color: AppTheme.textMuted),
              ),
              const SizedBox(height: 12),
              ClipRRect(
                borderRadius: BorderRadius.circular(16.r),
                child: BackdropFilter(
                  filter: ImageFilter.blur(sigmaX: 8, sigmaY: 8),
                  child: Container(
                    padding: EdgeInsets.all(12.r),
                    decoration: AppTheme.glassCardAccent(radius: 16),
                    child: _buildPuzzleGrid(currentState, isInteractive: true),
                  ),
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
                style: Theme.of(context).textTheme.labelSmall?.copyWith(color: AppTheme.textMuted),
              ),
              const SizedBox(height: 12),
              Container(
                padding: EdgeInsets.all(8.r),
                decoration: AppTheme.glassCard(radius: 12),
                child: _buildPuzzleGrid(problem.goalState, isInteractive: false),
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
        return GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 3,
            childAspectRatio: 1,
            mainAxisSpacing: 6,
            crossAxisSpacing: 6,
          ),
          itemCount: 9,
          itemBuilder: (context, index) {
            final tile = state.tiles[index];
            final isEmpty = tile == 0;

            final isExplored = exploredStates.contains(state.toString());
            final isPath = currentPath.contains(state);

            final tileColor = isEmpty
                ? Colors.transparent
                : isPath
                    ? AppTheme.cellPath
                    : isExplored
                        ? AppTheme.cellExplored
                        : AppTheme.surfaceHigh;

            final content = AnimatedContainer(
              duration: const Duration(milliseconds: 300),
              decoration: BoxDecoration(
                color: tileColor,
                borderRadius: BorderRadius.circular(isInteractive ? 8 : 4),
                border: Border.all(
                  color: isEmpty
                      ? Colors.white.withValues(alpha: 0.05)
                      : (isPath || isExplored)
                          ? Colors.transparent
                          : Colors.white.withValues(alpha: 0.1),
                ),
                boxShadow: (isPath && !isEmpty)
                    ? [
                        BoxShadow(color: AppTheme.cellPath.withValues(alpha: 0.5), blurRadius: 8),
                      ]
                    : [],
              ),
              child: isEmpty
                  ? null
                  : Center(
                      child: Text(
                        '$tile',
                        style: isInteractive
                            ? Theme.of(context).textTheme.headlineMedium?.copyWith(fontWeight: FontWeight.bold)
                            : Theme.of(context).textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.bold),
                      ),
                    ),
            );

            if (!isInteractive) return content;

            return GestureDetector(
              onTap: () => _handleTileTap(index),
              child: content,
            );
          },
        );
      }
    );
  }
}
