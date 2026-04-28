import 'package:algo_arena/widgets/skeleton_loaders.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'dart:async';
import 'package:algo_arena/core/app_theme.dart';
import 'package:algo_arena/core/nqueens_problem.dart';
import 'package:algo_arena/services/nqueens_solver.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:algo_arena/widgets/visualizer_widgets.dart';
import 'package:algo_arena/models/algo_info.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:algo_arena/screens/visualizer_base_mixin.dart';
import 'package:algo_arena/services/api_service.dart';
import 'package:algo_arena/core/problem_definition.dart';

class NQueensVisualizerScreen extends ConsumerStatefulWidget {
  const NQueensVisualizerScreen({super.key});

  @override
  ConsumerState<NQueensVisualizerScreen> createState() =>
      _NQueensVisualizerScreenState();
}

class _NQueensVisualizerScreenState extends ConsumerState<NQueensVisualizerScreen>
    with TickerProviderStateMixin, VisualizerBaseMixin<NQueensVisualizerScreen, QueensState> {
  late QueensState currentState;
  NQueensSolver? solver;
  StreamSubscription<NQueensStep>? _stepSubscription;

  int boardSize = 8;
  NQueensSolverMode selectedMode = NQueensSolverMode.backtracking;

  // Local throttle since NQueens uses its own solve loop, not the mixin's executor
  DateTime _lastUiUpdate = DateTime.now();

  @override
  String get algorithmId => selectedMode.label;

  @override
  void initState() {
    super.initState();
    _resetBoard();
  }

  @override
  void dispose() {
    _stopSolver();
    super.dispose();
  }

  @override
  Map<String, dynamic> getProblemSnapshot() {
    return {
      'boardSize': boardSize,
      'initialPlacement': currentState.placement,
    };
  }

  @override
  Future<void> onStep(AlgorithmStep<QueensState> step) async {
    // This is a bit different because NQueens doesn't use AlgorithmExecutor yet
    // But we'll try to keep it consistent
  }

  @override
  Future<void> onGoalReached(AlgorithmStep<QueensState> step) async {
    statusMessage = 'Solution Found!';
  }

  @override
  Future<void> onAutoSave() async {
    try {
      final runData = {
        'algorithm': selectedMode.label,
        'type': 'csp',
        'isBattle': false,
        'snapshot': getProblemSnapshot(),
        'metadata': {
          'boardSize': boardSize,
          'foundPath': isSolved,
          'steps': stepCount,
        },
        'durationMs': 0, // Need to track this
        'timestamp': DateTime.now().toIso8601String(),
      };
      await ApiService().saveRun(runData);
    } catch (e) {
      debugPrint('Error auto-saving N-Queens run: $e');
    }
  }

  void _resetBoard() {
    _stopSolver();
    resetBase();
    currentState = QueensState(
      placement: List.filled(boardSize, -1),
      n: boardSize,
    );
    statusMessage = 'Idle';
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
      stepDelay: Duration(milliseconds: (300 / executionSpeed).round().clamp(10, 3000)),
    );

    _stepSubscription = solver!.stepStream.listen((step) {
      if (!mounted) return;

      // Throttle UI updates
      stepCount = step.steps;
      // We'll treat backtracks as part of nodes explored for consistency in stats
      nodesExplored = step.steps + step.backtracks;
      
      final newState = QueensState(placement: step.board, n: boardSize);
      currentState = newState;

      if (step.isSolved) {
        isSolved = true;
        isSolving = false;
        statusMessage = 'Solution Found!';
        onGoalReached(AlgorithmStep(
          newlyExplored: [newState],
          path: [],
          stepCount: step.steps,
          isGoalReached: true,
        ));
        
        // Custom auto-save trigger since we aren't using base.solve()
        onAutoSave();
      } else {
        statusMessage = 'Solving... Row: ${step.currentRow + 1}';
      }

      // Manual throttle for NQueens since it doesn't use the mixin's executor stream
      final now = DateTime.now();
      if (now.difference(_lastUiUpdate) >= const Duration(milliseconds: 32)) {
        _lastUiUpdate = now;
        setState(() {});
      }
    });

    await solver!.solve();
  }

  void _pauseResumeCustom() {
    if (isSolving) {
      solver?.pause();
      setState(() {
        isSolving = false;
        statusMessage = 'Paused';
      });
    } else if (solver != null && !isSolved) {
      solver?.resume();
      setState(() {
        isSolving = true;
        statusMessage = 'Resumed';
      });
    }
  }

  void _handleSquareTap(int row, int col) {
    if (isSolving) return;

    final newPlacement = List<int>.from(currentState.placement);
    if (newPlacement[row] == col) {
      newPlacement[row] = -1;
    } else {
      newPlacement[row] = col;
      if (!NQueensUtils.isSafe(newPlacement, row, col)) {
        HapticFeedback.heavyImpact();
      }
    }

    final newState = QueensState(placement: newPlacement, n: boardSize);
    setState(() {
      currentState = newState;
      isSolved = NQueensUtils.isGoal(newState);
      if (isSolved) {
        HapticFeedback.vibrate();
        statusMessage = 'Goal reached manually!';
      } else {
        statusMessage = 'Playing manually';
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
                  _buildSpeedControlModal(setModalState),
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

  Widget _buildSpeedControlModal(StateSetter setModalState) {
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

  Widget _buildFullContent() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20.0),
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
          Row(
            children: [
              Expanded(
                child: GlassStatCard(
                  label: 'STEPS',
                  value: stepCount,
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: GlassStatCard(
                  label: 'BACKTRACKS',
                  value: solver != null ? nodesExplored - stepCount : 0,
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: GlassStatCard(
                  label: 'ROW',
                  value: !currentState.placement.contains(-1) ? boardSize : currentState.placement.indexOf(-1) + 1,
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          Center(
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
          ),
          const SizedBox(height: 20),
          !isGridReady 
              ? SkeletonGrid(rows: boardSize, columns: boardSize)
              : _buildBoard().animate().fadeIn(duration: 400.ms),
          const SizedBox(height: 24),
          VisualizerControls(
            isSolving: isSolving,
            isSolved: isSolved,
            stepCount: stepCount,
            onSolve: _showSolverConfig,
            onPauseResume: _pauseResumeCustom,
            onClear: _resetBoard,
          ),
        ],
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
          child: Center(
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
                    final hasQueen = currentState.placement[row] == col;
                    
                    bool isConflict = false;
                    if (hasQueen) {
                      isConflict = !NQueensUtils.isSafe(currentState.placement, row, col);
                    }

                    Color cellColor = ((row + col) % 2 == 0)
                        ? Colors.white.withValues(alpha: 0.05)
                        : Colors.black.withValues(alpha: 0.15);

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
                                : Colors.transparent,
                            width: hasQueen ? 2.0 : 1.0,
                          ),
                        ),
                        child: hasQueen
                            ? Center(
                                child: SvgPicture.asset(
                                  'assets/images/crown.svg',
                                  width: 28,
                                  height: 28,
                                  colorFilter: ColorFilter.mode(
                                    isConflict ? AppTheme.error : Colors.white,
                                    BlendMode.srcIn,
                                  ),
                                )
                                    .animate(target: isSolving ? 1 : 0)
                                    .tint(
                                      color: AppTheme.accent.withValues(alpha: 0.1),
                                      duration: 1.seconds,
                                    )
                                    .shake(hz: 2, rotation: 0.01, duration: 1.seconds)
                                    .animate(
                                      target: isSolved ? 1 : 0,
                                      onPlay: (c) => isSolved ? c.repeat(reverse: true) : c.stop(),
                                    )
                                    .shimmer(
                                      duration: 1.seconds,
                                      color: AppTheme.success.withValues(alpha: 0.4),
                                    )
                                    .scale(
                                      begin: const Offset(1, 1),
                                      end: const Offset(1.1, 1.1),
                                      duration: 1.seconds,
                                      curve: Curves.easeInOut,
                                    ),
                              )
                            : null,
                      ),
                    );
                  },
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }
}
