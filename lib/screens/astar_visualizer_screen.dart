import 'dart:ui';
import 'package:ai_algo_app/core/problem_definition.dart';
import 'package:flutter/material.dart';
import 'dart:async';
import '../core/app_theme.dart';
import '../core/grid_problem.dart';
import '../core/search_algorithms.dart';
import '../services/algorithm_executor.dart';
import '../widgets/algorithm_recommendation_card.dart';
import '../models/grid_node.dart';
import '../state/grid_controller.dart';
import '../widgets/visualizer_widgets.dart';

class AStarVisualizerScreen extends StatefulWidget {
  const AStarVisualizerScreen({super.key});

  @override
  State<AStarVisualizerScreen> createState() => _AStarVisualizerScreenState();
}

class _AStarVisualizerScreenState extends State<AStarVisualizerScreen> {
  late final GridController _controller;
  AlgorithmExecutor<GridCoordinate>? _executor;
  StreamSubscription<AlgorithmStep<GridCoordinate>>? _stepSubscription;
  late GridProblem _problem;

  List<GridCoordinate> _explored = [];
  List<GridCoordinate> _path = [];
  bool _isSolving = false;
  bool _isSolved = false;
  int _stepCount = 0;
  int _nodesExplored = 0;
  double _executionSpeed = 1.0;
  String _statusMessage = 'Ready to solve';

  static const Color exploredColor = AppTheme.cellExplored;
  static const Color pathColor = AppTheme.cellPath;

  Duration get _stepDelay {
    final ms = (180 / _executionSpeed).round().clamp(10, 1800);
    return Duration(milliseconds: ms);
  }

  @override
  void initState() {
    super.initState();
    _controller = GridController(rows: 12, columns: 15);
    _initializeProblem();
  }

  void _initializeProblem() {
    _problem = GridProblem(
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
  }

  Future<void> _solvePuzzle() async {
    if (_isSolving) return;
    _initializeProblem();

    setState(() {
      _isSolving = true;
      _isSolved = false;
      _explored = [];
      _path = [];
      _stepCount = 0;
      _nodesExplored = 0;
      _statusMessage = 'Starting A* search…';
    });

    _executor = AlgorithmExecutor<GridCoordinate>(
      algorithm: AStarAlgorithm<GridCoordinate>(stepDelay: _stepDelay),
      problem: _problem,
    );

    try {
      await _executor!.start();
      await _stepSubscription?.cancel();
      _stepSubscription = _executor!.stepStream.listen(
        (step) {
          if (!mounted) return;
          setState(() {
            _explored = step.explored;
            _path = step.path;
            _stepCount = step.stepCount;
            _nodesExplored = step.explored.length;
            _statusMessage = step.message ?? _statusMessage;

            if (step.isGoalReached) {
              _isSolved = true;
              _isSolving = false;
              _statusMessage =
                  'Solution found! Path length: ${_path.length} moves';
            }
          });
        },
        onError: (error) {
          if (mounted) {
            setState(() {
              _isSolving = false;
              _statusMessage = 'Error: $error';
            });
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text('Error: $error')),
            );
          }
        },
        onDone: () {
          if (mounted) setState(() => _isSolving = false);
        },
      );
    } catch (e) {
      if (mounted) {
        setState(() {
          _isSolving = false;
          _statusMessage = 'Error: $e';
        });
      }
    }
  }

  void _pauseResume() {
    if (_isSolving) {
      _executor?.pause();
      setState(() {
        _isSolving = false;
        _statusMessage = 'Paused';
      });
    } else if (_stepCount > 0) {
      _executor?.resume();
      setState(() {
        _isSolving = true;
        _statusMessage = 'Resumed';
      });
    }
  }

  void _stepOnce() {
    if (!_isSolving && _stepCount >= 0 && _executor != null) {
      _executor?.stepOnce();
    }
  }

  void _reset() {
    if (_isSolving) _executor?.stop();
    _stepSubscription?.cancel();
    _stepSubscription = null;
    _executor = null;
    setState(() {
      _explored = [];
      _path = [];
      _stepCount = 0;
      _nodesExplored = 0;
      _isSolving = false;
      _isSolved = false;
      _statusMessage = 'Ready to solve';
    });
  }

  void _clearWalls() {
    _controller.clearWalls();
    _reset();
  }

  @override
  void dispose() {
    if (_isSolving) _executor?.stop();
    _stepSubscription?.cancel();
    _executor?.dispose();
    _controller.dispose();
    super.dispose();
  }

  Color _getCellColor(int row, int col) {
    final node = _controller.grid[row][col];
    if (_path.any((c) => c.row == row && c.column == col)) return pathColor;
    if (_explored.any((c) => c.row == row && c.column == col)) {
      return exploredColor;
    }
    if (node.type == NodeType.wall) return AppTheme.cellWall;
    if (node.type == NodeType.start) return AppTheme.cellStart;
    if (node.type == NodeType.goal) return AppTheme.cellGoal;
    return AppTheme.surfaceLow;
  }

  bool _isCurrentNode(int row, int col) {
    if (_explored.isEmpty) return false;
    final last = _explored.last;
    return last.row == row && last.column == col;
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
              // ── Header ──────────────────────────────────────────────────
              const VisualizerHeader(
                title: 'A* Search',
                subtitle: 'PATHFINDING VISUALIZER',
              ),
              const SizedBox(height: 20),

              // ── Stats ────────────────────────────────────────────────────
              Row(
                children: [
                  Expanded(
                    child: GlassStatCard(label: 'STEPS', value: _stepCount),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: GlassStatCard(
                        label: 'EXPLORED', value: _nodesExplored),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: GlassStatCard(
                        label: 'PATH LEN', value: _path.length),
                  ),
                ],
              ),
              const SizedBox(height: 14),

              // ── Status ───────────────────────────────────────────────────
              Center(
                child: StatusBanner(
                  message: _statusMessage,
                  isSolved: _isSolved,
                  isSolving: _isSolving,
                ),
              ),
              const SizedBox(height: 14),

              // ── Legend ───────────────────────────────────────────────────
              const GridLegend(
                exploredColor: exploredColor,
                pathColor: pathColor,
              ),
              const SizedBox(height: 14),

              // ── AI Recommendation ────────────────────────────────────────
              if ((_problem.grid.length * _problem.grid.first.length) > 50 &&
                  _problem.obstacleDensity < 0.1)
                AlgorithmRecommendationCard(
                  problem: _problem,
                  onUseRecommended: _solvePuzzle,
                  accentColor: AppTheme.accent,
                  cardColor: AppTheme.surface,
                ),

              // ── Grid ─────────────────────────────────────────────────────
              ClipRRect(
                borderRadius: BorderRadius.circular(16),
                child: BackdropFilter(
                  filter: ImageFilter.blur(sigmaX: 8, sigmaY: 8),
                  child: Container(
                    decoration: AppTheme.glassCardAccent(radius: 16),
                    padding: const EdgeInsets.all(8),
                    child: GridView.builder(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      gridDelegate:
                          SliverGridDelegateWithFixedCrossAxisCount(
                        crossAxisCount: _controller.columns,
                        childAspectRatio: 1,
                        crossAxisSpacing: 1.5,
                        mainAxisSpacing: 1.5,
                      ),
                      itemCount: _controller.rows * _controller.columns,
                      itemBuilder: (context, index) {
                        final row = index ~/ _controller.columns;
                        final col = index % _controller.columns;
                        final isCurrent = _isCurrentNode(row, col);
                        final cellColor = _getCellColor(row, col);

                        return AnimatedContainer(
                          duration: const Duration(milliseconds: 250),
                          curve: Curves.easeOut,
                          decoration: BoxDecoration(
                            color: cellColor,
                            borderRadius: BorderRadius.circular(2),
                            boxShadow: isCurrent
                                ? [
                                    BoxShadow(
                                      color: exploredColor.withValues(alpha: 0.9),
                                      blurRadius: 10,
                                      spreadRadius: 2,
                                    ),
                                  ]
                                : _path.any(
                                        (c) => c.row == row && c.column == col)
                                    ? [
                                        BoxShadow(
                                          color: pathColor.withValues(alpha: 0.5),
                                          blurRadius: 6,
                                          spreadRadius: 1,
                                        ),
                                      ]
                                    : null,
                          ),
                        );
                      },
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 16),

              // ── Speed ───────────────────────────────────────────────────
              ClipRRect(
                borderRadius: BorderRadius.circular(12),
                child: BackdropFilter(
                  filter: ImageFilter.blur(sigmaX: 8, sigmaY: 8),
                  child: Container(
                    padding: const EdgeInsets.fromLTRB(16, 12, 16, 4),
                    decoration: AppTheme.glassCard(radius: 12),
                    child: SpeedControl(
                      speed: _executionSpeed,
                      isSolving: _isSolving,
                      onChanged: (v) => setState(() => _executionSpeed = v),
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 14),

              // ── Controls ─────────────────────────────────────────────────
              VisualizerControls(
                isSolving: _isSolving,
                isSolved: _isSolved,
                stepCount: _stepCount,
                onSolve: _solvePuzzle,
                onPauseResume: _pauseResume,
                onStep: _stepOnce,
                onReset: _reset,
                onClear: _clearWalls,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
