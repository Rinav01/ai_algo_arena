import 'package:ai_algo_app/services/maze_generator.dart';
import 'package:ai_algo_app/screens/algorithm_battle_screen.dart';
import 'package:ai_algo_app/widgets/grid_visualizer_canvas.dart';
import 'package:ai_algo_app/widgets/visualizer_widgets.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:ai_algo_app/core/problem_definition.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'dart:async';
import 'package:ai_algo_app/core/app_theme.dart';
import 'package:ai_algo_app/core/grid_problem.dart';
import 'package:ai_algo_app/core/search_algorithms.dart';
import 'package:ai_algo_app/services/algorithm_executor.dart';
import 'package:ai_algo_app/services/map_persistence.dart';
import 'package:ai_algo_app/widgets/algorithm_recommendation_card.dart';
import 'package:ai_algo_app/models/grid_node.dart';
import 'package:ai_algo_app/state/grid_controller.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:ai_algo_app/state/settings_provider.dart';
import 'package:ai_algo_app/models/algo_info.dart';

class PathfindingVisualizerScreen extends ConsumerStatefulWidget {
  final String algorithmId;
  final String title;

  const PathfindingVisualizerScreen({
    super.key,
    required this.algorithmId,
    required this.title,
  });

  @override
  ConsumerState<PathfindingVisualizerScreen> createState() =>
      _PathfindingVisualizerScreenState();
}

class _PathfindingVisualizerScreenState
    extends ConsumerState<PathfindingVisualizerScreen> with SingleTickerProviderStateMixin {
  late final GridController _controller;
  AlgorithmExecutor<GridCoordinate>? _executor;
  StreamSubscription<AlgorithmStep<GridCoordinate>>? _stepSubscription;
  GridProblem? _problem;
  late AnimationController _pulseController;

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
    _controller = GridController(rows: 15, columns: 25);
    _initializeProblem();
    
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
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
    final goal = _controller.goal;
    if (goal == null) {
      _problem = null;
      return;
    }

    final settings = ref.read(settingsProvider);
    
    _problem = GridProblem(
      grid: _controller.grid,
      start: GridCoordinate(
        row: _controller.start.row,
        column: _controller.start.column,
      ),
      goal: GridCoordinate(
        row: goal.row,
        column: goal.column,
      ),
      settings: settings,
    );
  }

  Future<void> _solvePuzzle({bool isLiveUpdate = false}) async {
    if (_isSolving && !isLiveUpdate) return;
    
    if (_controller.goal == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please place a Goal node first!'),
          backgroundColor: AppTheme.error,
        ),
      );
      return;
    }

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

    // Dispose previous executor and cancel its subscription
    await _executor?.dispose();
    await _stepSubscription?.cancel();

    _executor = AlgorithmExecutor<GridCoordinate>(
      algorithm: algo,
      problemSnapshot: _controller.toOptimizedSnapshot(ref.read(settingsProvider)),
      stepDelayMs: isLiveUpdate ? 0 : _stepDelay.inMilliseconds,
    );

    try {
      await _executor!.start();
      await _stepSubscription?.cancel();
      _stepSubscription = _executor!.stepStream.listen(
        (step) {
          if (!mounted) return;
          // UI updates only for metrics; Canvas handles grid painting via addListener in initState/CustomPaint
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

  void _generateMaze() {
    if (_isSolving) return;
    _reset();
    
    MazeGenerator.generatePrims(_controller, includeWeights: true);
    
    setState(() {
      _statusMessage = 'Maze generated (Randomized Prim\'s)';
    });
  }

  void _exportMap() {
    final json = MapPersistence.exportMap(
      grid: _controller.grid,
      start: GridCoordinate(
          row: _controller.start.row, column: _controller.start.column),
      goal: _controller.goal != null ? GridCoordinate(
          row: _controller.goal!.row, column: _controller.goal!.column) : null,
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

  void _handlePointerDown(int row, int col) {
    if (_isSolving && !_isSolved) return; 

    // Check for anchor dragging
    final node = _controller.grid[row][col];
    if (node.type == NodeType.start) {
      setState(() => _isDraggingStart = true);
    } else if (node.type == NodeType.goal) {
      setState(() => _isDraggingGoal = true);
    } else {
      _controller.handleCellInteraction(row, col);
    }
  }

  void _handlePointerUpdate(int row, int col) {
    if (_isSolving && !_isSolved) return;

    if (_isDraggingStart) {
      _controller.moveAnchor(isStart: true, row: row, column: col);
      _triggerImmediateReSolve();
    } else if (_isDraggingGoal) {
      _controller.moveAnchor(isStart: false, row: row, column: col);
      _triggerImmediateReSolve();
    } else {
      _controller.handleCellInteraction(row, col);
      if (_isSolved) _triggerImmediateReSolve();
    }
  }

  void _handlePointerUp() {
    setState(() {
      _isDraggingStart = false;
      _isDraggingGoal = false;
    });
  }

  void _triggerImmediateReSolve() {
    if (!_isSolved && _path.isEmpty) return; 
    
    _reSolveTimer?.cancel();
    _reSolveTimer = Timer(const Duration(milliseconds: 50), () {
      if (!mounted) return;
      
      final oldHash = _problem.hashCode;
      _initializeProblem(); 
      if (_problem == null || _problem!.hashCode == oldHash) return;

      _solvePuzzle(isLiveUpdate: true);
    });
  }


  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.background,
      body: SafeArea(
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // ── Header ──────────────────────────────────────────────────
              VisualizerHeader(
                title: widget.title,
                subtitle: 'PATHFINDING VISUALIZER',
                info: AlgoInfo.pathfinding[widget.algorithmId],
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
              ToolButton(
                label: 'Generate Maze (Randomized Prim\'s)',
                icon: Icons.grain_rounded,
                onPressed: _generateMaze,
                color: AppTheme.warning,
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
              if (_problem != null)
                AlgorithmRecommendationCard(
                  problem: _problem!,
                  onUseRecommended: _solvePuzzle,
                ),
              const SizedBox(height: 16),

              // ── Grid ─────────────────────────────────────────────────────
              ClipRRect(
                borderRadius: BorderRadius.circular(16.0),
                child: Container(
                  decoration: AppTheme.glassCardAccent(radius: 16),
                  padding: EdgeInsets.all(8.0),
                  child: AspectRatio(
                    aspectRatio: 25 / 15, // Native ratio based on cols and rows
                    child: GridVisualizerCanvas(
                      controller: _controller,
                      executor: _executor,
                      isInteractive: true,
                      onPointerDown: _handlePointerDown,
                      onPointerUpdate: _handlePointerUpdate,
                      onPointerUp: _handlePointerUp,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 16),

              // ── Speed ───────────────────────────────────────────────────
              Container(
                padding: const EdgeInsets.fromLTRB(16, 12, 16, 4),
                decoration: AppTheme.glassCard(radius: 12),
                child: SpeedControl(
                  speed: _executionSpeed,
                  isSolving: _isSolving,
                  onChanged: (v) => setState(() => _executionSpeed = v),
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
                        goal: _controller.goal != null ? GridCoordinate(
                          row: _controller.goal!.row,
                          column: _controller.goal!.column,
                        ) : GridCoordinate(row: -1, column: -1), // Should ideally handle null in BattleScreen
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
