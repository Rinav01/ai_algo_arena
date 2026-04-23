import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'dart:async';
import 'package:algo_arena/core/app_theme.dart';
import 'package:algo_arena/core/nqueens_problem.dart';
import 'package:algo_arena/services/nqueens_solver.dart';
import 'package:algo_arena/widgets/visualizer_widgets.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:algo_arena/models/algo_info.dart';

class NQueensVisualizerScreen extends StatefulWidget {
  const NQueensVisualizerScreen({super.key});

  @override
  State<NQueensVisualizerScreen> createState() =>
      _NQueensVisualizerScreenState();
}

class _NQueensVisualizerScreenState extends State<NQueensVisualizerScreen>
    with SingleTickerProviderStateMixin {
  late QueensState currentState;
  NQueensSolver? solver;
  StreamSubscription<NQueensStep>? _stepSubscription;
  final ValueNotifier<NQueensStep?> _currentStepNotifier = ValueNotifier(null);

  int boardSize = 8;
  double executionSpeed = 2.0;
  NQueensSolverMode selectedMode = NQueensSolverMode.backtracking;
  bool isSolving = false;
  bool isSolved = false;

  @override
  void initState() {
    super.initState();
    _resetBoard();
  }

  void _resetBoard() {
    _stopSolver();
    currentState = QueensState(
      placement: List.filled(boardSize, -1),
      n: boardSize,
    );
    _currentStepNotifier.value = NQueensStep(
      board: currentState.placement,
      currentRow: -1,
      steps: 0,
      backtracks: 0,
    );
    isSolved = false;
    isSolving = false;
  }

  Duration get _stepDelay {
    final milliseconds = (300 / executionSpeed).round().clamp(10, 3000);
    return Duration(milliseconds: milliseconds);
  }

  void _stopSolver() {
    solver?.stop();
    _stepSubscription?.cancel();
    solver = null;
    _stepSubscription = null;
  }

  Future<void> _startSolving() async {
    if (isSolving) return;

    _resetBoard();
    setState(() => isSolving = true);

    solver = NQueensSolver(
      n: boardSize,
      mode: selectedMode,
      stepDelay: _stepDelay,
    );

    _stepSubscription = solver!.stepStream.listen((step) {
      _currentStepNotifier.value = step;
      if (step.isSolved) {
        setState(() {
          isSolved = true;
          isSolving = false;
        });
      }
    });

    await solver!.solve();
  }

  void _pauseResume() {
    if (isSolving) {
      solver?.pause();
      setState(() => isSolving = false);
    } else if (_currentStepNotifier.value != null && !isSolved) {
      solver?.resume();
      setState(() => isSolving = true);
    }
  }

  void _reset() {
    setState(() {
      _resetBoard();
    });
  }

  void _handleSquareTap(int row, int col) {
    if (isSolving) return;

    final newPlacement = List<int>.from(
      _currentStepNotifier.value?.board ?? currentState.placement,
    );
    if (newPlacement[row] == col) {
      newPlacement[row] = -1;
    } else {
      newPlacement[row] = col;
      if (!NQueensUtils.isSafe(newPlacement, row, col)) {
        HapticFeedback.heavyImpact();
      }
    }

    final newState = QueensState(placement: newPlacement, n: boardSize);
    _currentStepNotifier.value = NQueensStep(
      board: newPlacement,
      currentRow: row,
      steps: 0,
      backtracks: 0,
    );
    setState(() {
      currentState = newState;
      isSolved = NQueensUtils.isGoal(newState);
      if (isSolved) {
        HapticFeedback.vibrate();
      }
    });
  }

  void _showSolverConfig() {
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
                    'Solver Configuration',
                    style: Theme.of(context).textTheme.headlineSmall,
                  ),
                  const SizedBox(height: 20),
                  _buildModeSelector(setModalState),
                  const SizedBox(height: 20),
                  _buildSpeedControl(setModalState),
                  const SizedBox(height: 24),
                  ElevatedButton(
                    onPressed: isSolving
                        ? null
                        : () {
                            Navigator.pop(context);
                            _startSolving();
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
                      style: TextStyle(
                        letterSpacing: 1.5,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  Widget _buildModeSelector(StateSetter setModalState) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'ALGORITHM MODE',
          style: Theme.of(
            context,
          ).textTheme.labelSmall?.copyWith(color: AppTheme.textMuted),
        ),
        const SizedBox(height: 12),
        Wrap(
          spacing: 10.0,
          runSpacing: 10.0,
          children: NQueensSolverMode.values.map((mode) {
            final isSelected = selectedMode == mode;
            return GestureDetector(
              onTap: () {
                setState(() => selectedMode = mode);
                setModalState(() {});
              },
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                padding: EdgeInsets.symmetric(horizontal: 16.0, vertical: 10.0),
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
                  mode.label,
                  style: Theme.of(context).textTheme.labelLarge?.copyWith(
                    color: isSelected
                        ? AppTheme.accentLight
                        : AppTheme.textMuted,
                  ),
                ),
              ),
            );
          }).toList(),
        ),
      ],
    );
  }

  Widget _buildSpeedControl(StateSetter setModalState) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'SPEED',
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
        Slider(
          value: executionSpeed,
          min: 0.5,
          max: 5.0,
          onChanged: (value) {
            setState(() => executionSpeed = value);
            setModalState(() {});
          },
        ),
      ],
    );
  }

  @override
  void dispose() {
    _stopSolver();
    _currentStepNotifier.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.background,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: EdgeInsets.all(20.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              VisualizerHeader(
                title: 'N-Queens',
                subtitle: 'CSP VISUALIZER',
                onBackTap: () => Navigator.pop(context),
                comparisonInfos: AlgoInfo.nQueens,
                initialKey: selectedMode.label,
              ),
              const SizedBox(height: 20),
              ValueListenableBuilder<NQueensStep?>(
                valueListenable: _currentStepNotifier,
                builder: (context, step, _) {
                  return Row(
                    children: [
                      Expanded(
                        child: GlassStatCard(
                          label: 'STEPS',
                          value: step?.steps ?? 0,
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: GlassStatCard(
                          label: 'BACKTRACKS',
                          value: step?.backtracks ?? 0,
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: GlassStatCard(
                          label: 'ROW',
                          value: (step?.currentRow ?? -1) + 1,
                        ),
                      ),
                    ],
                  );
                },
              ),
              const SizedBox(height: 14),
              Center(
                child:
                    StatusBanner(
                          message: isSolved
                              ? 'Solution Found!'
                              : isSolving
                              ? 'Solving...'
                              : 'Idle',
                          isSolved: isSolved,
                          isSolving: isSolving,
                        )
                        .animate(target: isSolved ? 1 : 0, autoPlay: false)
                        .scale(duration: 600.ms, curve: Curves.elasticOut)
                        .shimmer(
                          duration: 2.seconds,
                          color: AppTheme.success.withValues(alpha: 0.3),
                        ),
              ),
              const SizedBox(height: 20),
              _buildBoard(),
              const SizedBox(height: 24),
              VisualizerControls(
                isSolving: isSolving,
                isSolved: isSolved,
                stepCount: _currentStepNotifier.value?.steps ?? 0,
                onSolve: _showSolverConfig,
                onPauseResume: _pauseResume,
                onClear: _reset,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildBoard() {
    return Column(
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'BOARD SIZE: $boardSize',
              style: Theme.of(
                context,
              ).textTheme.labelSmall?.copyWith(color: AppTheme.textMuted),
            ),
            Expanded(
              child: Slider(
                value: boardSize.toDouble(),
                min: 4,
                max: 10,
                divisions: 6,
                onChanged: isSolving
                    ? null
                    : (v) => setState(() {
                        boardSize = v.toInt();
                        _resetBoard();
                      }),
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),
        RepaintBoundary(
          child: ValueListenableBuilder<NQueensStep?>(
            valueListenable: _currentStepNotifier,
            builder: (context, step, _) {
              final board = step?.board ?? List.filled(boardSize, -1);
              final activeRow = step?.currentRow ?? -1;

              return Center(
                child: ConstrainedBox(
                  constraints: BoxConstraints(maxWidth: 600.0),
                  child: Container(
                    padding: EdgeInsets.all(12.0),
                    decoration: AppTheme.glassCardAccent(radius: 16),
                    child: GridView.builder(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                        crossAxisCount: boardSize,
                        mainAxisSpacing: 2,
                        crossAxisSpacing: 2,
                      ),
                      itemCount: boardSize * boardSize,
                      itemBuilder: (context, index) {
                        final row = index ~/ boardSize;
                        final col = index % boardSize;
                        final hasQueen = board[row] == col;
                        final isActiveRow = row == activeRow;

                        bool isConflict = false;
                        if (hasQueen) {
                          isConflict = !NQueensUtils.isSafe(board, row, col);
                        }

                        Color cellColor = ((row + col) % 2 == 0)
                            ? Colors.white.withValues(alpha: 0.05)
                            : Colors.black.withValues(alpha: 0.15);

                        if (isActiveRow) {
                          cellColor = AppTheme.accent.withValues(alpha: 0.1);
                        }

                        return GestureDetector(
                          onTap: () => _handleSquareTap(row, col),
                          child: AnimatedContainer(
                            duration: const Duration(milliseconds: 200),
                            decoration: BoxDecoration(
                              color: cellColor,
                              borderRadius: BorderRadius.circular(4.0),
                              border: Border.all(
                                color: hasQueen
                                    ? (isConflict
                                          ? AppTheme.error
                                          : AppTheme.success)
                                    : (isActiveRow
                                          ? AppTheme.accent.withValues(
                                              alpha: 0.3,
                                            )
                                          : Colors.transparent),
                                width: hasQueen ? 2.0 : 1.0,
                              ),
                            ),
                            child: hasQueen
                                ? Center(
                                        child: Text(
                                          '♕',
                                          style: TextStyle(
                                            fontSize: 28.0,
                                            color: isConflict
                                                ? AppTheme.error
                                                : Colors.white,
                                            shadows: [
                                              Shadow(
                                                color: isConflict
                                                    ? AppTheme.error
                                                    : AppTheme.success,
                                                blurRadius: 10,
                                              ),
                                            ],
                                          ),
                                        ),
                                      )
                                      .animate()
                                      .scale(
                                        duration: 200.ms,
                                        curve: Curves.easeOut,
                                      )
                                      .animate(target: isSolved ? 1 : 0)
                                      .shimmer(
                                        duration: 1200.ms,
                                        color: AppTheme.success.withValues(
                                          alpha: 0.5,
                                        ),
                                      )
                                      .shake(
                                        duration: 400.ms,
                                        hz: 4,
                                        rotation: 0.05,
                                        delay: (index * 20).ms,
                                      )
                                      .scale(
                                        begin: const Offset(1, 1),
                                        end: const Offset(1.2, 1.2),
                                        duration: 400.ms,
                                        curve: Curves.easeOutBack,
                                      )
                                : null,
                          ),
                        );
                      },
                    ),
                  ),
                ),
              );
            },
          ),
        ),
      ],
    );
  }
}
