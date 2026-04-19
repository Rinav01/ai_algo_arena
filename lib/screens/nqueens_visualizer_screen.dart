import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'dart:async';
import 'dart:ui';
import 'package:ai_algo_app/core/app_theme.dart';
import 'package:ai_algo_app/core/nqueens_problem.dart';
import 'package:ai_algo_app/core/search_algorithms.dart';
import 'package:ai_algo_app/services/algorithm_executor.dart';
import 'package:ai_algo_app/core/problem_definition.dart';
import 'package:ai_algo_app/widgets/visualizer_widgets.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

class NQueensVisualizerScreen extends StatefulWidget {
  const NQueensVisualizerScreen({super.key});

  @override
  State<NQueensVisualizerScreen> createState() =>
      _NQueensVisualizerScreenState();
}

class _NQueensVisualizerScreenState extends State<NQueensVisualizerScreen>
    with SingleTickerProviderStateMixin {
  late NQueensProblem problem;
  late QueensState currentState;
  AlgorithmExecutor<QueensState>? executor;
  StreamSubscription<AlgorithmStep<QueensState>>? _stepSubscription;
  late AnimationController _animationController;

  List<QueensState> currentPath = [];
  Set<String> exploredStates = {};
  int stepCount = 0;
  int nodesExplored = 0;
  bool isSolving = false;
  bool isSolved = false;
  String selectedAlgorithm = 'A*';
  int boardSize = 8;
  double executionSpeed = 2.0;

  final List<String> algorithms = ['BFS', 'DFS', 'A*'];

  Duration get _stepDelay {
    final milliseconds = (220 / executionSpeed).round().clamp(10, 2200);
    return Duration(milliseconds: milliseconds);
  }

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );
    _initializeProblem();
  }

  void _initializeProblem() {
    problem = NQueensProblem(n: boardSize);
    currentState = problem.initialState;
    currentPath = [currentState];
    exploredStates.clear();
  }

  Future<void> _solvePuzzle() async {
    if (isSolving) return;

    _initializeProblem();

    setState(() {
      isSolving = true;
      isSolved = false;
      exploredStates.clear();
      currentPath = [problem.initialState];
      stepCount = 0;
      nodesExplored = 0;
      _animationController.forward();
    });

    late SearchAlgorithm<QueensState> algorithm;
    switch (selectedAlgorithm) {
      case 'BFS':
        algorithm = BFSAlgorithm<QueensState>();
        break;
      case 'DFS':
        algorithm = DFSAlgorithm<QueensState>();
        break;
      case 'A*':
        algorithm = AStarAlgorithm<QueensState>();
        break;
    }

    executor = AlgorithmExecutor<QueensState>(
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

            if (step.isGoalReached) {
              isSolved = true;
              isSolving = false;
            }
          });
        },
        onError: (error) {
          if (mounted) {
            ScaffoldMessenger.of(context)
                .showSnackBar(SnackBar(content: Text('Error: $error')));
            setState(() => isSolving = false);
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
        setState(() => isSolving = false);
      }
    }
  }

  void _pauseResume() {
    if (isSolving) {
      executor?.pause();
      setState(() => isSolving = false);
    } else if (stepCount > 0) {
      executor?.resume();
      setState(() => isSolving = true);
    }
  }

  void _reset() {
    if (isSolving) executor?.stop();
    _stepSubscription?.cancel();
    _stepSubscription = null;
    if (executor != null) {
      executor!.stop();
      executor!.dispose();
      executor = null;
    }
    _animationController.reset();
    setState(() {
      _initializeProblem();
      isSolving = false;
      isSolved = false;
      stepCount = 0;
      nodesExplored = 0;
    });
  }

  void _stepOnce() {
    if (isSolving) return;

    if (executor == null) {
      late SearchAlgorithm<QueensState> algorithm;
      switch (selectedAlgorithm) {
        case 'BFS':
          algorithm = BFSAlgorithm<QueensState>();
          break;
        case 'DFS':
          algorithm = DFSAlgorithm<QueensState>();
          break;
        case 'A*':
          algorithm = AStarAlgorithm<QueensState>();
          break;
      }

      executor = AlgorithmExecutor<QueensState>(
        algorithm: algorithm,
        problem: problem,
      stepDelayMs: _stepDelay.inMilliseconds,
    );
      executor!.start();
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

  void _handleSquareTap(int row, int col) {
    if (isSolving) return;

    setState(() {
      final newPlacement = List<int>.from(currentState.placement);
      if (newPlacement[row] == col) {
        newPlacement[row] = -1; // remove
      } else {
        newPlacement[row] = col; // place
        if (!problem.isSafe(QueensState(placement: newPlacement, n: boardSize), row, col)) {
          HapticFeedback.heavyImpact();
        }
      }

      currentState = QueensState(placement: newPlacement, n: boardSize);
      problem = NQueensProblem(n: boardSize, initialPlacement: newPlacement);
      
      stepCount = 0;
      nodesExplored = 0;
      currentPath = [currentState];
      exploredStates.clear();
      isSolved = problem.isGoal(currentState);
    });
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
                  padding: EdgeInsets.fromLTRB(20, 20, 20, MediaQuery.of(context).viewInsets.bottom + 20),
                  decoration: BoxDecoration(
                    color: AppTheme.surfaceVariant.withValues(alpha: 0.98),
                    borderRadius: BorderRadius.vertical(top: Radius.circular(24.r)),
                    border: Border(top: BorderSide(color: Colors.white.withValues(alpha: 0.12))),
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
    if (isSolving) executor?.stop();
    _stepSubscription?.cancel();
    executor?.dispose();
    _animationController.dispose();
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
                title: 'N-Queens',
                subtitle: 'CONSTRAINT VIZ',
                onBackTap: () => Navigator.pop(context),
              ),
              const SizedBox(height: 20),

              Row(
                children: [
                  Expanded(child: GlassStatCard(label: 'STEPS', value: stepCount)),
                  const SizedBox(width: 10),
                  Expanded(child: GlassStatCard(label: 'EXPLORED', value: nodesExplored)),
                  const SizedBox(width: 10),
                  Expanded(
                    child: GlassStatCard(
                      label: 'PLACED', 
                      value: currentState.placement.where((p) => p != -1).length,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 14),

              Center(
                child: StatusBanner(
                  message: isSolved ? 'Solution Found!' : isSolving ? 'Searching...' : 'Ready',
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
                onStep: _stepOnce,
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
    return Column(
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'BOARD SIZE: $boardSize',
              style: Theme.of(context).textTheme.labelSmall?.copyWith(color: AppTheme.textMuted),
            ),
            Expanded(
              child: SliderTheme(
                data: SliderTheme.of(context).copyWith(
                  activeTrackColor: AppTheme.accent,
                  inactiveTrackColor: AppTheme.surfaceHighest,
                  thumbColor: Colors.white,
                  overlayColor: AppTheme.accent.withValues(alpha: 0.2),
                ),
                child: Slider(
                  value: boardSize.toDouble(),
                  min: 4,
                  max: 10,
                  divisions: 6,
                  onChanged: isSolving
                      ? null
                      : (value) {
                          setState(() {
                            boardSize = value.toInt();
                            _initializeProblem();
                          });
                        },
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),
        ClipRRect(
          borderRadius: BorderRadius.circular(16.r),
          child: Container(
            padding: EdgeInsets.all(12.r),
            decoration: AppTheme.glassCardAccent(radius: 16),
            child: GridView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: boardSize,
                  childAspectRatio: 1,
                  mainAxisSpacing: 1,
                  crossAxisSpacing: 1,
                ),
                itemCount: boardSize * boardSize,
                itemBuilder: (context, index) {
                  final row = index ~/ boardSize;
                  final col = index % boardSize;

                  final depth = currentPath.length;
                  final hasQueen = currentState.placement[row] == col;
                  
                  // A queen is locked if it is a parent in the current search path 
                  // or if the entire puzzle has been solved.
                  final isLocked = hasQueen && (row < depth - 1 || isSolved);
                  final isSafe = hasQueen ? problem.isSafe(currentState, row, col) : true;
                  
                  Color squareColor = Colors.transparent;
                  Color borderColor = Colors.white.withValues(alpha: 0.05);
                  List<BoxShadow>? shadows;
                  
                  if (hasQueen) {
                    if (isLocked) {
                      // Confirmed/Locked Queen
                      squareColor = AppTheme.success;
                      borderColor = AppTheme.surfaceHigh;
                      shadows = [
                        BoxShadow(
                          color: AppTheme.success.withValues(alpha: 0.4),
                          blurRadius: 12,
                          spreadRadius: 2,
                        )
                      ];
                    } else {
                      // Trial Queen - Border Only with Search Glow
                      squareColor = Colors.transparent;
                      borderColor = isSafe ? AppTheme.success : AppTheme.error;
                      if (isSolving) {
                        shadows = [
                          BoxShadow(
                            color: (isSafe ? AppTheme.success : AppTheme.error).withValues(alpha: 0.2),
                            blurRadius: 8,
                            spreadRadius: 1,
                          )
                        ];
                      }
                    }
                  } else {
                    squareColor = ((row + col) % 2 == 0) 
                        ? Colors.white.withValues(alpha: 0.05) 
                        : Colors.black.withValues(alpha: 0.15);
                  }

                  return GestureDetector(
                    onTap: () => _handleSquareTap(row, col),
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 300),
                      decoration: BoxDecoration(
                        color: squareColor,
                        borderRadius: BorderRadius.circular(4.r),
                        boxShadow: shadows,
                        border: Border.all(
                          color: borderColor,
                          width: hasQueen ? 2.w : 0.5.w,
                        ),
                      ),
                      child: Stack(
                        children: [
                          if (hasQueen)
                            Center(
                              child: Opacity(
                                opacity: isLocked ? 1.0 : 0.7,
                                child: Text(
                                  '♕',
                                  style: TextStyle(
                                    fontSize: 32.sp,
                                    color: Colors.white,
                                    shadows: [
                                      Shadow(
                                        color: isLocked 
                                          ? Colors.white.withValues(alpha: 0.5)
                                          : (isSafe ? AppTheme.success : AppTheme.error).withValues(alpha: 0.5),
                                        blurRadius: isLocked ? 8 : 4,
                                      )
                                    ],
                                  ),
                                ),
                              ),
                            ),
                          if (isLocked)
                            Positioned(
                              bottom: 2.r,
                              right: 2.r,
                              child: Icon(
                                Icons.lock,
                                size: 10.r,
                                color: Colors.white.withValues(alpha: 0.8),
                              ),
                            ),
                        ],
                      ),
                    ),
                  );
                },
              ),
            ),
          ),
      ],
    );
  }
}
