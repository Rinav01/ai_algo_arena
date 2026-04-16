import 'dart:ui';
import 'package:ai_algo_app/core/maze_generators.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:ai_algo_app/core/problem_definition.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'dart:async';
import '../core/app_theme.dart';
import '../core/grid_problem.dart';
import '../core/search_algorithms.dart';
import '../services/algorithm_executor.dart';
import '../services/map_persistence.dart';
import '../widgets/algorithm_recommendation_card.dart';
import '../models/grid_node.dart';
import '../state/grid_controller.dart';
import '../widgets/visualizer_widgets.dart';
import 'algorithm_battle_screen.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

class PathfindingVisualizerScreen extends StatefulWidget {
  final String algorithmId;
  final String title;

  const PathfindingVisualizerScreen({
    super.key,
    required this.algorithmId,
    required this.title,
  });

  @override
  State<PathfindingVisualizerScreen> createState() =>
      _PathfindingVisualizerScreenState();
}

class _PathfindingVisualizerScreenState
    extends State<PathfindingVisualizerScreen> with SingleTickerProviderStateMixin {
  late final GridController _controller;
  AlgorithmExecutor<GridCoordinate>? _executor;
  StreamSubscription<AlgorithmStep<GridCoordinate>>? _stepSubscription;
  late GridProblem _problem;
  late AnimationController _pulseController;
  late Animation<double> _pulseAnimation;

  List<GridCoordinate> _path = [];
  bool _isSolving = false;
  bool _isSolved = false;
  int _nodesExplored = 0;
  double _executionSpeed = 1.0;
  String _statusMessage = 'Ready to solve';
  int _stepCount = 0;
  List<FlSpot> _perfData = []; // nodes explored vs time/steps

  // Dragging states
  bool _isDraggingStart = false;
  bool _isDraggingGoal = false;
  Timer? _reSolveTimer;

  static const Color exploredColor = AppTheme.cellExplored;
  static const Color pathColor = AppTheme.cellPath;

  @override
  void initState() {
    super.initState();
    _controller = GridController(rows: 12, columns: 15);
    _initializeProblem();
    
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    );
    _pulseAnimation = Tween<double>(begin: 4, end: 14).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    if (_isSolving) _executor?.stop();
    _stepSubscription?.cancel();
    _executor?.dispose();
    _controller.dispose();
    _pulseController.dispose();
    super.dispose();
  }
  
  Duration get _stepDelay {
    final ms = (180 / _executionSpeed).round().clamp(10, 1800);
    return Duration(milliseconds: ms);
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

  Future<void> _solvePuzzle({bool isLiveUpdate = false}) async {
    if (_isSolving && !isLiveUpdate) return;
    _initializeProblem();

    setState(() {
      if (!isLiveUpdate) {
        _isSolving = true;
        _isSolved = false;
        _statusMessage = 'Starting ${widget.algorithmId} search…';
        _pulseController.repeat(reverse: true);
      }
      _path = [];
      _stepCount = 0;
      _nodesExplored = 0;
      _perfData = [const FlSpot(0, 0)];
    });

    SearchAlgorithm<GridCoordinate> algo;
    switch (widget.algorithmId) {
      case 'BFS':
        algo = BFSAlgorithm<GridCoordinate>();
        break;
      case 'DFS':
        algo = DFSAlgorithm<GridCoordinate>();
        break;
      case 'Dijkstra':
        algo = DijkstraAlgorithm<GridCoordinate>();
        break;
      case 'Greedy':
        algo = GreedyBestFirstAlgorithm<GridCoordinate>();
        break;
      case 'A*':
      default:
        algo = AStarAlgorithm<GridCoordinate>();
    }

    _executor = AlgorithmExecutor<GridCoordinate>(
      algorithm: algo,
      problem: _problem,
      stepDelayMs: isLiveUpdate ? 0 : _stepDelay.inMilliseconds,
    );

    try {
      await _executor!.start();
      await _stepSubscription?.cancel();
      _stepSubscription = _executor!.stepStream.listen(
        (step) {
          if (!mounted) return;
          setState(() {
            _path = _executor!.currentPath;
            _stepCount = step.stepCount;
            _nodesExplored = _executor!.exploredSet.length;
            _statusMessage = step.message ?? _statusMessage;

            if (_stepCount % 20 == 0) {
              _perfData.add(FlSpot(_stepCount.toDouble(), _nodesExplored.toDouble()));
            }

            if (step.isGoalReached) {
              _isSolved = true;
              _isSolving = false;
              _pulseController.stop();
              _perfData.add(FlSpot(_stepCount.toDouble(), _nodesExplored.toDouble()));
              _statusMessage =
                  'Solution found! Path length: ${_path.length} moves';
            }
          });
        },
        onDone: () {
          if (mounted) {
            setState(() {
              _isSolving = false;
              _pulseController.stop();
            });
          }
        },
      );
    } catch (e) {
      if (mounted) {
        setState(() {
          _isSolving = false;
          _pulseController.stop();
          _statusMessage = 'Error: $e';
        });
      }
    }
  }

  void _pauseResume() {
    if (_isSolving) {
      _executor?.pause();
      _pulseController.stop();
      setState(() {
        _isSolving = false;
        _statusMessage = 'Paused';
      });
    } else if (_stepCount > 0) {
      _executor?.resume();
      _pulseController.repeat(reverse: true);
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
    _pulseController.stop();
    _stepSubscription?.cancel();
    _stepSubscription = null;
    _executor = null;
    setState(() {
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

  void _generateMaze({bool isPrims = false}) {
    if (_isSolving) return;
    _reset();
    
    final generator = MazeGenerator();
    if (isPrims) {
      generator.generateRandomizedPrims(_controller);
    } else {
      generator.generateRecursiveDivision(_controller);
    }
    
    setState(() {
      _statusMessage = 'Maze generated using ${isPrims ? "Randomized Prim's" : "Recursive Division"}';
    });
  }

  void _exportMap() {
    final json = MapPersistence.exportMap(
      grid: _controller.grid,
      start: GridCoordinate(
          row: _controller.start.row, column: _controller.start.column),
      goal: GridCoordinate(
          row: _controller.goal.row, column: _controller.goal.column),
    );
    Clipboard.setData(ClipboardData(text: json));
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Map JSON copied to clipboard!')),
    );
  }

  void _importMap() {
    final controller = TextEditingController();
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Import Map JSON'),
        content: TextField(
          controller: controller,
          maxLines: 5,
          decoration: const InputDecoration(hintText: 'Paste map JSON here...'),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              try {
                final data = MapPersistence.importMap(controller.text);
                _controller.loadFromJson(data);
                _reset();
                Navigator.pop(context);
                setState(() => _statusMessage = 'Map imported successfully');
              } catch (e) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text('Error: $e')),
                );
              }
            },
            child: const Text('Import'),
          ),
        ],
      ),
    );
  }

  Color _getCellColor(int row, int col) {
    final node = _controller.grid[row][col];
    final state = GridCoordinate(row: row, column: col);
    
    // Use O(1) lookups from executor if available
    final isPath = _executor?.currentPath.contains(state) ?? _path.contains(state);
    final isExplored = _executor?.exploredSet.contains(state) ?? false;
    
    if (isPath) return pathColor;
    if (isExplored) return exploredColor;
    
    if (node.type == NodeType.wall) return AppTheme.cellWall;
    if (node.type == NodeType.weight) return AppTheme.cellWeight;
    if (node.type == NodeType.start) return AppTheme.cellStart;
    if (node.type == NodeType.goal) return AppTheme.cellGoal;
    return AppTheme.surfaceLow;
  }

  void _handleGridGesture(Offset localPosition, Size size) {
    if (_isSolving && !_isSolved) return; // Prevent painting while solving

    final rowWidth = size.width / _controller.columns;
    final colHeight = size.height / _controller.rows;

    final col = (localPosition.dx / rowWidth).floor();
    final row = (localPosition.dy / colHeight).floor();

    if (row >= 0 && row < _controller.rows && col >= 0 && col < _controller.columns) {
      // Check for anchor dragging first
      if (!_isDraggingStart && !_isDraggingGoal) {
        final node = _controller.grid[row][col];
        if (node.type == NodeType.start) {
          setState(() => _isDraggingStart = true);
          return;
        } else if (node.type == NodeType.goal) {
          setState(() => _isDraggingGoal = true);
          return;
        }
      }

      if (_isDraggingStart) {
        _controller.moveAnchor(isStart: true, row: row, column: col);
        _triggerImmediateReSolve();
      } else if (_isDraggingGoal) {
        _controller.moveAnchor(isStart: false, row: row, column: col);
        _triggerImmediateReSolve();
      } else {
        // Normal painting
        _controller.handleCellInteraction(row, col);
        if (_isSolved) _triggerImmediateReSolve();
      }
    }
  }

  void _triggerImmediateReSolve() {
    if (!_isSolved && _path.isEmpty) return; 
    
    _reSolveTimer?.cancel();
    _reSolveTimer = Timer(const Duration(milliseconds: 50), () {
      if (!mounted) return;
      _solvePuzzle(isLiveUpdate: true);
    });
  }

  bool _isCurrentNode(int row, int col) {
    final currentState = _executor?.lastStep?.currentState;
    if (currentState == null) return false;
    return currentState.row == row && currentState.column == col;
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
              VisualizerHeader(
                title: widget.title,
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
              GridLegend(
                exploredColor: exploredColor,
                pathColor: pathColor,
              ),
              const SizedBox(height: 14),

              // ── Maze Generation ─────────────────────────────────────────
              Row(
                children: [
                  Expanded(
                    child: ToolButton(
                      label: 'Recursive',
                      icon: Icons.grid_goldenratio_rounded,
                      onPressed: () => _generateMaze(isPrims: false),
                      color: AppTheme.cyan,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: ToolButton(
                      label: 'Prim\'s',
                      icon: Icons.grain_rounded,
                      onPressed: () => _generateMaze(isPrims: true),
                      color: AppTheme.warning,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 14),

              // ── Tool Selector ───────────────────────────────────────────
              ToolSelector(
                selectedTool: _controller.selectedTool,
                onToolSelected: (tool) {
                  setState(() {
                    if (tool is PaintTool) {
                      _controller.setTool(tool);
                    }
                  });
                },
              ),
              const SizedBox(height: 14),

              // ── Persistence ───────────────────────────────────────────
              Row(
                children: [
                  Expanded(
                    child: ToolButton(
                      label: 'Export Map',
                      icon: Icons.ios_share_rounded,
                      onPressed: _exportMap,
                      color: AppTheme.accentLight,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: ToolButton(
                      label: 'Import Map',
                      icon: Icons.file_download_rounded,
                      onPressed: _importMap,
                      color: AppTheme.success,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),

              // ── AI Recommendation ────────────────────────────────────────
              AlgorithmRecommendationCard(
                problem: _problem,
                onUseRecommended: _solvePuzzle,
              ),
              const SizedBox(height: 16),

              // ── Grid ─────────────────────────────────────────────────────
              ClipRRect(
                borderRadius: BorderRadius.circular(16.r),
                child: BackdropFilter(
                  filter: ImageFilter.blur(sigmaX: 8, sigmaY: 8),
                  child: Container(
                    decoration: AppTheme.glassCardAccent(radius: 16),
                    padding: EdgeInsets.all(8.r),
                    child: LayoutBuilder(
                      builder: (context, constraints) {
                        return GestureDetector(
                          onPanStart: (details) => _handleGridGesture(
                            details.localPosition,
                            Size(constraints.maxWidth, constraints.maxHeight),
                          ),
                          onPanUpdate: (details) => _handleGridGesture(
                            details.localPosition,
                            Size(constraints.maxWidth, constraints.maxHeight),
                          ),
                          onPanEnd: (_) => setState(() {
                            _isDraggingStart = false;
                            _isDraggingGoal = false;
                          }),
                          child: AnimatedBuilder(
                            animation: _pulseAnimation,
                            builder: (context, child) => GridView.builder(
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
                                    borderRadius: BorderRadius.circular(2.r),
                                    boxShadow: isCurrent
                                        ? [
                                            BoxShadow(
                                              color: exploredColor.withValues(alpha: 0.9),
                                              blurRadius: _pulseAnimation.value,
                                              spreadRadius: _pulseAnimation.value / 4,
                                            ),
                                          ]
                                        : _path.any((c) =>
                                                c.row == row && c.column == col)
                                            ? [
                                                BoxShadow(
                                                  color:
                                                      pathColor.withValues(alpha: 0.5),
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
                        );
                      },
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 16),

              // ── Speed ───────────────────────────────────────────────────
              ClipRRect(
                borderRadius: BorderRadius.circular(12.r),
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

              // ── Analytics ────────────────────────────────────────────────
              PerformanceChart(
                dataPoints: _perfData,
                accentColor: AppTheme.accent,
              ),
              const SizedBox(height: 16),

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
                onVersus: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => AlgorithmBattleScreen(
                        initialGrid: _controller.grid,
                        start: GridCoordinate(
                          row: _controller.start.row,
                          column: _controller.start.column,
                        ),
                        goal: GridCoordinate(
                          row: _controller.goal.row,
                          column: _controller.goal.column,
                        ),
                      ),
                    ),
                  );
                },
              ),
            ],
          ),
        ),
      ),
    );
  }
}
