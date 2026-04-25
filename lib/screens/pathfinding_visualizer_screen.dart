import 'package:algo_arena/services/maze_generator.dart';
import 'package:algo_arena/services/map_persistence.dart';
import 'package:algo_arena/widgets/algorithm_recommendation_card.dart';
import 'package:algo_arena/screens/algorithm_battle_screen.dart';
import 'package:algo_arena/widgets/grid_visualizer_canvas.dart';
import 'package:algo_arena/widgets/visualizer_widgets.dart';
import 'package:algo_arena/core/problem_definition.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'dart:async';
import 'package:algo_arena/core/app_theme.dart';
import 'package:algo_arena/core/grid_problem.dart';
import 'package:algo_arena/models/grid_node.dart';
import 'package:algo_arena/state/grid_controller.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:algo_arena/state/settings_provider.dart';
import 'package:algo_arena/models/algo_info.dart';
import 'package:algo_arena/services/api_service.dart';
import 'package:algo_arena/services/run_optimizer.dart';
import 'package:algo_arena/screens/history_screen.dart';
import 'package:algo_arena/screens/visualizer_base_mixin.dart';
import 'dart:typed_data';

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
    extends ConsumerState<PathfindingVisualizerScreen>
    with SingleTickerProviderStateMixin, VisualizerBaseMixin<PathfindingVisualizerScreen, GridCoordinate> {
  late final GridController _controller;
  GridProblem? _problem;

  List<GridCoordinate> _path = [];

  // Dragging states
  bool _isDraggingStart = false;
  bool _isDraggingGoal = false;
  Timer? _reSolveTimer;

  static const Color exploredColor = AppTheme.cellExplored;
  static const Color pathColor = AppTheme.cellPath;

  @override
  String get algorithmId => widget.algorithmId;

  @override
  void initState() {
    super.initState();
    _controller = GridController(rows: 15, columns: 25);
    _initializeProblem();
  }

  @override
  void dispose() {
    _controller.dispose();
    _reSolveTimer?.cancel();
    super.dispose();
  }

  @override
  Map<String, dynamic> getProblemSnapshot() {
    return _controller.toOptimizedSnapshot(ref.read(settingsProvider));
  }

  @override
  Future<void> onStep(AlgorithmStep<GridCoordinate> step) async {
    _path = executor!.currentPath;
  }

  @override
  Future<void> onGoalReached(AlgorithmStep<GridCoordinate> step) async {
    statusMessage = 'Solution found! Path length: ${_path.length} moves';
  }

  @override
  Future<void> onAutoSave() async {
    await _autoSaveRun();
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
      goal: GridCoordinate(row: goal.row, column: goal.column),
      settings: settings,
    );
  }

  Future<void> _solvePuzzle({bool isLiveUpdate = false}) async {
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
    _path = [];
    await solve(isLiveUpdate: isLiveUpdate);
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

    // Convert Records to Maps for JSON serialization
    if (sanitized['start'] != null) {
      final s = sanitized['start'];
      sanitized['start'] = {'row': s.row, 'column': s.column};
    }
    if (sanitized['goal'] != null) {
      final g = sanitized['goal'];
      sanitized['goal'] = {'row': g.row, 'column': g.column};
    }

    return sanitized;
  }

  Future<void> _autoSaveRun() async {
    if (executor == null) return;
    
    debugPrint('Auto-save triggered for ${widget.algorithmId} with Phase 2 optimizations...');
    try {
      final cols = _controller.columns;
      final totalCells = _controller.rows * cols;
      final wallCount = _controller.grid.expand((r) => r).where((n) => n.type == NodeType.wall).length;
      final density = wallCount / totalCells;

      final runData = {
        'algorithm': widget.algorithmId,
        'type': 'single',
        'isBattle': false,
        'snapshot': _sanitizeSnapshot(executor!.problemSnapshot),
        'metadata': {
          'obstacleDensity': density,
          'foundPath': isSolved,
          'pathLength': _path.length,
          'nodesExplored': nodesExplored,
        },
        'steps': RunOptimizer.optimizeSteps(
          executor!.history!.cast<AlgorithmStep<GridCoordinate>>(),
          cols,
        ),
        'path': _path.map((c) => RunOptimizer.compress(c, cols)).toList(),
        'durationMs': executor!.executionTime.inMilliseconds,
        'timestamp': DateTime.now().toIso8601String(),
        'tags': [widget.algorithmId, density > 0.3 ? 'dense' : 'sparse'],
      };

      debugPrint('Sending optimized run data to: ${ApiService.baseUrl}/runs');
      await ApiService().saveRun(runData);
      
      if (mounted) {
        ref.invalidate(runsProvider);
      }
    } catch (e) {
      debugPrint('Error auto-saving run: $e');
    }
  }

  void _reset() {
    resetBase();
    setState(() {
      _path = [];
    });
  }

  void _clearWalls() {
    _controller.clearWalls();
    _reset();
  }

  void _generateMaze() {
    if (isSolving) return;
    _reset();

    MazeGenerator.generatePrims(_controller, includeWeights: true);

    setState(() {
      statusMessage = 'Maze generated (Randomized Prim\'s)';
    });
  }

  void _exportMap() {
    final json = MapPersistence.exportMap(
      grid: _controller.grid,
      start: GridCoordinate(
        row: _controller.start.row,
        column: _controller.start.column,
      ),
      goal: _controller.goal != null
          ? GridCoordinate(
              row: _controller.goal!.row,
              column: _controller.goal!.column,
            )
          : null,
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
                setState(() => statusMessage = 'Map imported successfully');
              } catch (e) {
                ScaffoldMessenger.of(
                  context,
                ).showSnackBar(SnackBar(content: Text('Error: $e')));
              }
            },
            child: const Text('Import'),
          ),
        ],
      ),
    );
  }

  void _handlePointerDown(int row, int col) {
    if (isSolving && !isSolved) return;

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
    if (isSolving && !isSolved) return;

    if (_isDraggingStart) {
      _controller.moveAnchor(isStart: true, row: row, column: col);
      _triggerImmediateReSolve();
    } else if (_isDraggingGoal) {
      _controller.moveAnchor(isStart: false, row: row, column: col);
      _triggerImmediateReSolve();
    } else {
      _controller.handleCellInteraction(row, col);
      if (isSolved) _triggerImmediateReSolve();
    }
  }

  void _handlePointerUp() {
    setState(() {
      _isDraggingStart = false;
      _isDraggingGoal = false;
    });
  }

  void _triggerImmediateReSolve() {
    if (!isSolved && _path.isEmpty) return;

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
                    child: GlassStatCard(label: 'STEPS', value: stepCount),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: GlassStatCard(
                      label: 'EXPLORED',
                      value: nodesExplored,
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: GlassStatCard(
                      label: 'PATH LEN',
                      value: _path.length,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 14),

              // ── Status ───────────────────────────────────────────────────
              Center(
                child: StatusBanner(
                  message: statusMessage,
                  isSolved: isSolved,
                  isSolving: isSolving,
                ),
              ),
              const SizedBox(height: 14),

              // ── Legend ───────────────────────────────────────────────────
              GridLegend(exploredColor: exploredColor, pathColor: pathColor),
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
                      executor: executor,
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
                  speed: executionSpeed,
                  isSolving: isSolving,
                  onChanged: (v) => setState(() => executionSpeed = v),
                ),
              ),
              const SizedBox(height: 14),

              // ── Analytics ────────────────────────────────────────────────
              PerformanceChart(
                dataPoints: perfData,
                accentColor: AppTheme.accent,
              ),
              const SizedBox(height: 16),

              // ── Controls ─────────────────────────────────────────────────
              VisualizerControls(
                isSolving: isSolving,
                isSolved: isSolved,
                stepCount: stepCount,
                onSolve: _solvePuzzle,
                onPauseResume: pauseResume,
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
                        goal: _controller.goal != null
                            ? GridCoordinate(
                                row: _controller.goal!.row,
                                column: _controller.goal!.column,
                              )
                            : GridCoordinate(
                                row: -1,
                                column: -1,
                              ), // Should ideally handle null in BattleScreen
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