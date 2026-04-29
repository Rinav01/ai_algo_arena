import 'package:algo_arena/screens/visualizer_base_mixin.dart';
import 'package:algo_arena/services/maze_generator.dart';
import 'package:algo_arena/services/map_persistence.dart';
import 'package:algo_arena/widgets/algorithm_recommendation_card.dart';
import 'package:algo_arena/screens/algorithm_battle_screen.dart';
import 'package:algo_arena/widgets/grid_visualizer_canvas.dart';
import 'package:algo_arena/widgets/skeleton_loaders.dart';
import 'package:algo_arena/widgets/visualizer_widgets.dart';
import 'package:algo_arena/core/problem_definition.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'dart:async';
import 'package:algo_arena/core/app_theme.dart';
import 'package:algo_arena/core/grid_problem.dart';
import 'package:algo_arena/models/grid_node.dart';
import 'package:algo_arena/state/grid_controller.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:algo_arena/state/settings_provider.dart';
import 'package:algo_arena/models/algo_info.dart';
import 'package:algo_arena/services/api_service.dart';
import 'package:algo_arena/services/run_optimizer.dart';
import 'package:algo_arena/state/api_provider.dart';
import 'package:algo_arena/state/performance_provider.dart';
import 'package:algo_arena/services/performance_monitor.dart';
import 'dart:typed_data';
import 'package:algo_arena/widgets/explanation_bottom_sheet.dart';
import 'package:algo_arena/widgets/performance_details_modal.dart';


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
    with
        TickerProviderStateMixin,
        VisualizerBaseMixin<PathfindingVisualizerScreen, GridCoordinate> {
  late final GridController _controller;
  GridProblem? _problem;

  List<GridCoordinate> _path = [];

  // Dragging states
  bool _isDraggingStart = false;
  bool _isDraggingGoal = false;
  Timer? _reSolveTimer;

  static const Color exploredColor = AppTheme.cellExplored;
  static const Color pathColor = AppTheme.cellPath;

  // Widget caching: static sections only rebuild when config changes
  Widget? _cachedHeader;
  Widget? _cachedStatsRow;
  Widget? _cachedTools;
  Widget? _cachedAnalytics;
  Widget? _cachedControls;
  int _lastConfigHash = 0;

  /// Hash of all config state that static widgets depend on
  int get _configHash => Object.hash(
    widget.algorithmId,
    isSolving,
    isSolved,
    stepCount,
    executionSpeed,
    _path.length,
    statusMessage,
    _controller.selectedTool,
  );

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

    return sanitized;
  }

  Future<void> _autoSaveRun() async {
    if (executor == null) return;

    debugPrint(
      'Auto-save triggered for ${widget.algorithmId} with Phase 2 optimizations...',
    );
    try {
      final cols = _controller.columns;
      final totalCells = _controller.rows * cols;
      final wallCount = _controller.grid
          .expand((r) => r)
          .where((n) => n.type == NodeType.wall)
          .length;
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
          'heuristic': ref.read(settingsProvider).allowDiagonalMoves
              ? 'Octile'
              : 'Manhattan',
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

    final node = _controller.grid[row][col];
    
    // If visualization is finished or paused, and user taps an explored node
    if ((isSolved || !isSolving) && stepCount > 0) {
      final tappedCoord = GridCoordinate(row: row, column: col);
      final step = executor?.getStepForState(tappedCoord);
      
      if (step != null && step.reason != null) {
        HapticFeedback.mediumImpact();
        _showExplanation(step);
        return;
      }
    }

    if (node.type == NodeType.start) {
      setState(() => _isDraggingStart = true);
    } else if (node.type == NodeType.goal) {
      setState(() => _isDraggingGoal = true);
    } else {
      _controller.handleCellInteraction(row, col);
    }
  }

  void _showExplanation(AlgorithmStep<GridCoordinate> step) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (context) => ExplanationBottomSheet<GridCoordinate>(
        step: step,
        stateFormatter: (coord) => '(${coord.row}, ${coord.column})',
      ),
    );
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
        child: !isShellReady
            ? const Center(child: CircularProgressIndicator())
            : _buildFullContent(),
      ),
    );
  }

  /// Full content built after the defer period.
  /// Uses ListView for viewport culling.
  Widget _buildFullContent() {
    // Rebuild cached widgets only when their dependencies change
    final currentConfigHash = _configHash;
    if (currentConfigHash != _lastConfigHash) {
      _lastConfigHash = currentConfigHash;
      _cachedHeader = _buildHeader();
      _cachedStatsRow = _buildStatsRow();
      _cachedTools = _buildToolsSection();
      _cachedAnalytics = _buildAnalyticsSection();
      _cachedControls = _buildControlsSection();
    }

    return ListView(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      children: [
        const SizedBox(height: 20),
        _cachedHeader!,
        const SizedBox(height: 20),
        _cachedStatsRow!,
        const SizedBox(height: 14),
        _buildStatusSection(),
        const SizedBox(height: 14),
        GridLegend(exploredColor: exploredColor, pathColor: pathColor),
        const SizedBox(height: 14),
        _cachedTools!,
        const SizedBox(height: 16),
        _buildAIRecommendation(),
        const SizedBox(height: 16),
        _buildGridSection(),
        const SizedBox(height: 16),
        _buildSpeedControl(),
        const SizedBox(height: 14),
        _cachedAnalytics!,
        const SizedBox(height: 16),
        _cachedControls!,
        const SizedBox(height: 32),
      ],
    );
  }

  Widget _buildHeader() {
    return VisualizerHeader(
      title: widget.title,
      subtitle: 'PATHFINDING VISUALIZER',
      info: AlgoInfo.pathfinding[widget.algorithmId],
    );
  }

  Widget _buildStatsRow() {
    return Row(
      children: [
        Expanded(
          child: GlassStatCard(label: 'STEPS', value: stepCount),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: GlassStatCard(label: 'EXPLORED', value: nodesExplored),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: GlassStatCard(label: 'PATH LEN', value: _path.length),
        ),
      ],
    );
  }

  Widget _buildStatusSection() {
    return StatusBanner(
          message: statusMessage,
          isSolved: isSolved,
          isSolving: isSolving,
        )
        .animate(
          target: isSolved ? 1 : 0,
          onPlay: (c) => isSolved ? c.repeat(reverse: true) : c.stop(),
        )
        .shimmer(
          duration: 1200.ms,
          color: AppTheme.success.withValues(alpha: 0.3),
        )
        .animate(
          target: isSolving ? 1 : 0,
          onPlay: (c) => isSolving ? c.repeat(reverse: true) : c.stop(),
        )
        .shimmer(
          duration: 2.seconds,
          color: AppTheme.warning.withValues(alpha: 0.2),
        )
        .shake(hz: 3, curve: Curves.easeInOut);
  }

  Widget _buildToolsSection() {
    return Column(
      children: [
        ToolButton(
          label: 'Generate Maze (Randomized Prim\'s)',
          icon: Icons.grain_rounded,
          onPressed: _generateMaze,
          color: AppTheme.warning,
        ),
        const SizedBox(height: 14),
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
        if (_controller.selectedTool == PaintTool.weight)
          Padding(
            padding: const EdgeInsets.only(top: 8.0),
            child: Text(
              'TIP: Tap weight nodes multiple times to cycle cost (2x → 5x → 10x)',
              style: AppTheme.labelStyle.copyWith(
                fontSize: 9,
                color: AppTheme.warning.withValues(alpha: 0.8),
              ),
              textAlign: TextAlign.center,
            ),
          ).animate().fadeIn().slideY(begin: 0.5),
        const SizedBox(height: 14),
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
      ],
    );
  }

  Widget _buildAIRecommendation() {
    if (_problem == null) return const SizedBox.shrink();
    return AlgorithmRecommendationCard(
      problem: _problem!,
      onUseRecommended: _solvePuzzle,
    );
  }

  Widget _buildGridSection() {
    final quality = ref.watch(qualityLevelProvider);
    final isLowFidelity = quality == QualityLevel.performance;

    return RepaintBoundary(
      child: ClipRRect(
        borderRadius: BorderRadius.circular(16.0),
        child:
            Container(
                  decoration: AppTheme.glassCardAccent(
                    radius: 16,
                    lowFidelity: isLowFidelity,
                  ),
                  padding: const EdgeInsets.all(8.0),
                  child: AspectRatio(
                    aspectRatio: 25 / 15,
                    child: !isGridReady
                        ? SkeletonGrid(
                            rows: _controller.rows,
                            columns: _controller.columns,
                          )
                        : GridVisualizerCanvas(
                            controller: _controller,
                            executor: executor,
                            isInteractive: true,
                            onPointerDown: _handlePointerDown,
                            onPointerUpdate: _handlePointerUpdate,
                            onPointerUp: _handlePointerUp,
                          ).animate().fadeIn(duration: 400.ms),
                  ),
                )
                .animate(
                  target: isSolving ? 1 : 0,
                  onPlay: (c) => isSolving ? c.repeat(reverse: true) : c.stop(),
                )
                .tint(
                  color: AppTheme.accent.withValues(alpha: 0.05),
                  duration: 1500.ms,
                ),
      ),
    );
  }

  Widget _buildSpeedControl() {
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 4),
      decoration: AppTheme.glassCard(radius: 12),
      child: SpeedControl(
        speed: executionSpeed,
        isSolving: isSolving,
        onChanged: (v) => setState(() => executionSpeed = v),
      ),
    );
  }



  Widget _buildAnalyticsSection() {
    return PerformanceChart(
      dataPoints: perfData,
      accentColor: AppTheme.accent,
      onExpand: () => PerformanceDetailsModal.show(context, perfData, AppTheme.accent),
    );
  }

  Widget _buildControlsSection() {
    return VisualizerControls(
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
                  : GridCoordinate(row: -1, column: -1),
            ),
          ),
        );
      },
    );
  }
}
