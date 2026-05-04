import 'package:flutter/foundation.dart';
import 'dart:math' as math;
import 'package:algo_arena/core/grid_problem.dart';
import 'package:algo_arena/core/problem_definition.dart';
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:algo_arena/core/app_theme.dart';
import 'package:algo_arena/widgets/grid_visualizer_canvas.dart';
import 'package:algo_arena/widgets/replay_controls.dart';
import 'package:algo_arena/state/grid_controller.dart';
import 'package:algo_arena/state/replay_provider.dart';
import 'package:algo_arena/services/run_optimizer.dart';
import 'package:algo_arena/widgets/trend_line.dart';
import 'package:algo_arena/widgets/visualizer_widgets.dart';
import 'package:algo_arena/widgets/explanation_bottom_sheet.dart';
import 'package:algo_arena/services/insight_service.dart';
import 'package:algo_arena/models/algo_info.dart';
import 'package:algo_arena/widgets/info_cards.dart';


class ReplayScreen extends ConsumerStatefulWidget {
  const ReplayScreen({super.key});

  @override
  ConsumerState<ReplayScreen> createState() => _ReplayScreenState();
}

class ReplayLoadResult {
  final List<AlgorithmStep<GridCoordinate>> steps;
  final List<GridCoordinate> fullExploredList;
  final List<int> exploredCountAtStep;
  final List<double> trend;
  final Map<GridCoordinate, int> stateToStep;

  ReplayLoadResult({
    required this.steps,
    required this.fullExploredList,
    required this.exploredCountAtStep,
    required this.trend,
    required this.stateToStep,
  });
}

class _ReplayScreenState extends ConsumerState<ReplayScreen> {
  late GridController _controller;

  @override
  void initState() {
    super.initState();
    // Initialize with a default 15x25 grid, will be updated if data exists
    _controller = GridController(rows: 15, columns: 25);

    // Reset replay state when entering the screen
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(replayProvider.notifier).reset();
      _loadRunData();
    });
  }

  String? _algoName;
  List<AlgorithmStep<GridCoordinate>> _runSteps = [];
  final Map<int, List<AlgorithmStep<GridCoordinate>>> _allCompetitorSteps = {};
  
  // Optimization: Pre-calculated lists for ultra-fast rendering
  final Map<int, List<GridCoordinate>> _fullExploredLists = {};
  final Map<int, List<int>> _exploredCountsAtStep = {};
  final Map<int, List<double>> _competitorTrends = {};
  final Map<int, Map<GridCoordinate, int>> _stateToStepMaps = {};

  bool _isBattle = false;
  bool _isSideBySide = false;
  List<dynamic> _competitors = [];
  Map<String, dynamic>? _metadata;
  int _selectedCompetitorIndex = 0;

  static ReplayLoadResult _processAlgorithmData(Map<String, dynamic> params) {
    final stepsRaw = params['stepsRaw'] as List<dynamic>;
    final finalPathRaw = params['finalPathRaw'] as List<dynamic>?;
    final cols = params['cols'] as int;

    if (stepsRaw.isEmpty) {
      return ReplayLoadResult(
        steps: [],
        fullExploredList: [],
        exploredCountAtStep: [0],
        trend: [],
        stateToStep: {},
      );
    }

    final isOptimized =
        stepsRaw.first is Map && (stepsRaw.first as Map).containsKey('e');

    List<AlgorithmStep<GridCoordinate>> steps = [];
    List<GridCoordinate> fullExplored = [];
    List<int> exploredCounts = [0];
    Map<GridCoordinate, int> stateToStep = {};

    if (!isOptimized) {
      steps = stepsRaw
          .map(
            (s) => AlgorithmStep<GridCoordinate>.fromJson(
              s as Map<String, dynamic>,
              (json) => GridCoordinate.fromJson(json as Map<String, dynamic>),
            ),
          )
          .toList();
      
      for (int i = 0; i < steps.length; i++) {
        final step = steps[i];
        fullExplored.addAll(step.newlyExplored);
        exploredCounts.add(fullExplored.length);
        if (step.currentState != null) {
          stateToStep[step.currentState!] = i;
        }
        // Also map newly explored if not already mapped (first discovery)
        for (final e in step.newlyExplored) {
          stateToStep.putIfAbsent(e, () => i);
        }
      }
    } else {
      final List<GridCoordinate> finalPath = finalPathRaw != null
          ? finalPathRaw
                .map((v) => RunOptimizer.decompress(v as int, cols))
                .toList()
          : [];

      for (int i = 0; i < stepsRaw.length; i++) {
        final s = stepsRaw[i];
        final map = s as Map<String, dynamic>;
        final explored = (map['e'] as List)
            .map((v) => RunOptimizer.decompress(v as int, cols))
            .toList();
        final current = map['c'] != null
            ? RunOptimizer.decompress(map['c'] as int, cols)
            : null;
        final isGoal = map['g'] == true;

        final step = AlgorithmStep<GridCoordinate>(
          newlyExplored: explored,
          currentState: current,
          path: isGoal ? finalPath : const [],
          stepCount: map['s'] as int,
          isGoalReached: isGoal,
          message: null, // Message is not currently optimized/stored
          reason: map['r'] as String?,
          meta: map['m'] != null ? Map<String, dynamic>.from(map['m'] as Map) : null,
        );
        
        steps.add(step);
        fullExplored.addAll(explored);
        exploredCounts.add(fullExplored.length);
        
        if (current != null) {
          stateToStep[current] = i;
        }
        for (final e in explored) {
          stateToStep.putIfAbsent(e, () => i);
        }
      }

      // Best effort: if the last step has no path but we have a final path, attach it
      if (steps.isNotEmpty && steps.last.path.isEmpty && finalPath.isNotEmpty) {
        steps[steps.length - 1] = steps.last.copyWith(path: finalPath);
      }
    }

    // Calculate Trend
    List<double> trend = [];
    int runningTotal = 0;
    final sampleRate = math.max(1, (steps.length / 100).ceil());
    for (int i = 0; i < steps.length; i++) {
      runningTotal += steps[i].newlyExplored.length;
      if (i % sampleRate == 0 || i == steps.length - 1) {
        trend.add(runningTotal.toDouble());
      }
    }

    return ReplayLoadResult(
      steps: steps,
      fullExploredList: fullExplored,
      exploredCountAtStep: exploredCounts,
      trend: trend,
      stateToStep: stateToStep,
    );
  }

  Future<void> _loadRunData() async {
    final args = ModalRoute.of(context)?.settings.arguments;
    if (args is Map<String, dynamic>) {
      final isBattle = args['isBattle'] == true || args['type'] == 'battle';
      final snapshot = args['snapshot'] as Map<String, dynamic>?;

      if (snapshot != null) {
        _controller.loadFromSnapshot(snapshot);
      }

      final cols = _controller.columns;

      if (isBattle) {
        final comps = args['competitors'] as List<dynamic>? ?? [];
        for (int i = 0; i < comps.length; i++) {
          final comp = comps[i];
          final result = await compute(_processAlgorithmData, {
            'stepsRaw': comp['steps'],
            'finalPathRaw': comp['path'],
            'cols': cols,
          });

          _allCompetitorSteps[i] = result.steps;
          _fullExploredLists[i] = result.fullExploredList;
          _exploredCountsAtStep[i] = result.exploredCountAtStep;
          _competitorTrends[i] = result.trend;
          _stateToStepMaps[i] = result.stateToStep;
        }
      } else {
        final result = await compute(_processAlgorithmData, {
          'stepsRaw': args['steps'],
          'finalPathRaw': args['path'],
          'cols': cols,
        });

        _runSteps = result.steps;
        _fullExploredLists[0] = result.fullExploredList;
        _exploredCountsAtStep[0] = result.exploredCountAtStep;
        _competitorTrends[0] = result.trend;
        _stateToStepMaps[0] = result.stateToStep;
      }

      if (mounted) {
        setState(() {
          _isBattle = isBattle;
          _isSideBySide = isBattle;
          _algoName = args['algorithm'] as String?;
          _competitors = isBattle ? (args['competitors'] as List<dynamic>? ?? []) : [];
          _metadata = args['metadata'] as Map<String, dynamic>?;

          final notifier = ref.read(replayProvider.notifier);
          if (isBattle) {
            int maxSteps = 0;
            for (final steps in _allCompetitorSteps.values) {
              if (steps.length > maxSteps) maxSteps = steps.length;
            }
            notifier.setTotalSteps(maxSteps);
            if (_allCompetitorSteps.isNotEmpty) {
              _loadCompetitor(0);
            }
          } else {
            notifier.setTotalSteps(_runSteps.length);
          }
        });
      }
    }
  }

  void _updateTotalSteps() {
    final notifier = ref.read(replayProvider.notifier);
    if (_isSideBySide && _isBattle) {
      int maxSteps = 0;
      for (final steps in _allCompetitorSteps.values) {
        if (steps.length > maxSteps) maxSteps = steps.length;
      }
      notifier.setTotalSteps(maxSteps);
    } else {
      notifier.setTotalSteps(_runSteps.length);
    }
  }

  void _loadCompetitor(int index) {
    if (index < 0 || !_allCompetitorSteps.containsKey(index)) return;

    final currentPos = ref.read(replayProvider).currentStep;

    _runSteps = _allCompetitorSteps[index]!;
    
    setState(() {
      _selectedCompetitorIndex = index;
    });

    // Update total steps based on current view mode
    _updateTotalSteps();
    
    if (!_isSideBySide) {
      ref.read(replayProvider.notifier).seek(math.min(currentPos, _runSteps.length));
    }
  }

  void _showNodeExplanation(int row, int col, {required int competitorIndex}) {
    final coord = GridCoordinate(row: row, column: col);
    final map = _stateToStepMaps[competitorIndex];
    final steps = _isBattle 
        ? (_allCompetitorSteps[competitorIndex] ?? []) 
        : _runSteps;

    if (map != null && map.containsKey(coord)) {
      final stepIndex = map[coord]!;
      final step = steps[stepIndex];
      
      showModalBottomSheet(
        context: context,
        isScrollControlled: true,
        backgroundColor: Colors.transparent,
        barrierColor: AppTheme.barrier,
        builder: (context) => ExplanationBottomSheet(
          step: step,
          onJumpToStep: () {
            ref.read(replayProvider.notifier).seek(stepIndex + 1);
          },
          stateFormatter: (p1) => '(${p1.row}, ${p1.column})',
        ),
      );
    } else {
      // Check if it's the start or goal
      final isStart = _controller.start.row == row && _controller.start.column == col;
      final isGoal = _controller.goal?.row == row && _controller.goal?.column == col;

      if (isStart) {
        _showStaticExplanation('START NODE', 'The algorithm began its search here.');
      } else if (isGoal) {
        _showStaticExplanation('GOAL NODE', 'The target destination of the search.');
      }
    }
  }

  void _showStaticExplanation(String title, String explanation) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      barrierColor: AppTheme.barrier,
      builder: (context) => ExplanationBottomSheet(
        step: AlgorithmStep<GridCoordinate>(
          newlyExplored: [],
          stepCount: 0,
          message: title,
          reason: explanation,
          path: [],
        ),
        stateFormatter: (p1) => '(${p1.row}, ${p1.column})',
      ),
    );
  }


  void _showAlgorithmInfo() {
    AlgoInfo? info;
    if (_isBattle) {
      info = AlgoInfo.battleArena;
    } else {
      info = AlgoInfo.pathfinding[_algoName];
    }

    if (info == null) return;

    showDialog(
      context: context,
      barrierColor: AppTheme.barrier,
      builder: (context) => Center(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Material(
            color: Colors.transparent,
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 500),
              child: AlgorithmInfoCard(info: info!),
            ),
          ),
        ),
      ),
    );
  }

  @override

  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final replayState = ref.watch(replayProvider);

    return Scaffold(
      body: SafeArea(
        child: SingleChildScrollView(
          child: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 1400),
              child: Column(
              children: [
                Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Row(
                    children: [
                      GestureDetector(
                        onTap: () => Navigator.pop(context),
                        child: Container(
                          width: 40,
                          height: 40,
                          decoration: AppTheme.glassCard(radius: 12),
                          child: const Icon(
                            Icons.arrow_back_ios_new_rounded,
                            size: 18,
                          ),
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'REPLAY MODE',
                              style: Theme.of(context).textTheme.labelSmall
                                  ?.copyWith(
                                    color: AppTheme.accentLight,
                                    letterSpacing: 1.5,
                                  ),
                            ),
                            Text(
                              _isSideBySide
                                  ? 'Comparison View'
                                  : '${_algoName ?? 'A*'} Run',
                              style: Theme.of(context).textTheme.headlineSmall
                                  ?.copyWith(
                                    fontWeight: FontWeight.bold,
                                    fontSize: 18,
                                  ),
                            ),
                          ],
                        ),
                      ),
                      GestureDetector(
                        onTap: _showAlgorithmInfo,
                        child: Container(
                          width: 36,
                          height: 36,
                          decoration: AppTheme.glassCard(radius: 10).copyWith(
                            color: AppTheme.accent.withValues(alpha: 0.1),
                          ),
                          child: const Icon(
                            Icons.info_outline_rounded,
                            size: 18,
                            color: AppTheme.accentLight,
                          ),
                        ),
                      ).animate().fadeIn(delay: 500.ms).scale(delay: 600.ms),
                      if (_isBattle) ...[
                        const SizedBox(width: 8),
                        IconButton(

                          icon: Icon(
                            _isSideBySide
                                ? Icons.view_agenda_rounded
                                : Icons.grid_view_rounded,
                            color: _isSideBySide
                                ? AppTheme.accent
                                : AppTheme.textMuted,
                          ),
                          onPressed: () {
                            setState(() {
                              _isSideBySide = !_isSideBySide;
                              _updateTotalSteps();
                            });
                          },
                          tooltip: 'Toggle Side-by-Side',
                        ),
                      ],
                    ],
                  ),
                ),

                if (_isBattle && _competitors.isNotEmpty && !_isSideBySide)
                  Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 8,
                    ),
                    child: Container(
                      padding: const EdgeInsets.all(4),
                      decoration: AppTheme.glassCard(radius: 12),
                      child: Row(
                        children: List.generate(_competitors.length, (index) {
                          final comp = _competitors[index];
                          final isSelected = _selectedCompetitorIndex == index;
                          return Expanded(
                            child: GestureDetector(
                              onTap: () => _loadCompetitor(index),
                              child: AnimatedContainer(
                                duration: const Duration(milliseconds: 200),
                                padding: const EdgeInsets.symmetric(
                                  vertical: 8,
                                ),
                                decoration: BoxDecoration(
                                  color: isSelected
                                      ? AppTheme.accent.withValues(alpha: 0.2)
                                      : Colors.transparent,
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: Center(
                                  child: Text(
                                    comp['name'] ?? 'Algo ${index + 1}',
                                    style: TextStyle(
                                      color: isSelected
                                          ? AppTheme.accentLight
                                          : AppTheme.textMuted,
                                      fontWeight: isSelected
                                          ? FontWeight.bold
                                          : FontWeight.normal,
                                    ),
                                  ),
                                ),
                              ),
                            ),
                          );
                        }),
                      ),
                    ),
                  ),

                // Upgrade: Global Insight Card
                if (replayState.currentStep >= _runSteps.length - 1 && _runSteps.isNotEmpty)
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    child: _buildGlobalInsightCard(),
                  ),



                if (_isBattle && _isSideBySide && _allCompetitorSteps.isNotEmpty)
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16.0),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Algorithm 1 Column
                        Flexible(
                          child: ConstrainedBox(
                            constraints: const BoxConstraints(maxWidth: 650),
                            child: Column(
                              children: [
                                _buildMainGrid(
                                  steps: _allCompetitorSteps[0] ?? [],
                                  currentStep: replayState.currentStep,
                                  label: _competitors[0]['name'] ?? 'Algo 1',
                                  color: AppTheme.accent,
                                  index: 0,
                                ),
                                const SizedBox(height: 16),
                                _buildSingleMetrics(
                                  replayState.currentStep,
                                  index: 0,
                                ),
                              ],
                            ),
                          ),
                        ),
                        const SizedBox(width: 80),
                        // Algorithm 2 Column
                        Flexible(
                          child: ConstrainedBox(
                            constraints: const BoxConstraints(maxWidth: 650),
                            child: Column(
                              children: [
                                _buildMainGrid(
                                  steps: _allCompetitorSteps[1] ?? [],
                                  currentStep: replayState.currentStep,
                                  label: _competitors[1]['name'] ?? 'Algo 2',
                                  color: AppTheme.error,
                                  index: 1,
                                ),
                                const SizedBox(height: 16),
                                _buildSingleMetrics(
                                  replayState.currentStep,
                                  index: 1,
                                ),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                  )
                else
                  // Single View
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16.0),
                    child: Column(
                      children: [
                        ConstrainedBox(
                          constraints: const BoxConstraints(maxWidth: 900),
                          child: _buildMainGrid(
                            steps: _runSteps,
                            currentStep: replayState.currentStep,
                            label: _algoName ?? 'Algorithm',
                            color: AppTheme.accent,
                            index: _selectedCompetitorIndex,
                          ),
                        ),
                        const SizedBox(height: 16),
                        ConstrainedBox(
                          constraints: const BoxConstraints(maxWidth: 900),
                          child: _buildSingleMetrics(replayState.currentStep),
                        ),
                      ],
                    ),
                  ),

                // ── Trend Visualization ───────────────────────────────────
                if (_competitorTrends.isNotEmpty)
                  Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 24,
                      vertical: 12,
                    ),
                    child: _isSideBySide && _isBattle
                        ? Column(
                            children: [
                              TrendLine(
                                data: _competitorTrends[0] ?? [0, 0],
                                color: AppTheme.accent,
                                currentProgress: (_allCompetitorSteps[0]?.isEmpty ?? true)
                                    ? 0
                                    : math.min(
                                        1.0,
                                        replayState.currentStep /
                                            (_allCompetitorSteps[0]?.length ?? 1),
                                      ),
                                label:
                                    '${_competitors[0]['name'] ?? 'P1'} Progress',
                              ),
                              const SizedBox(height: 12),
                              TrendLine(
                                data: _competitorTrends[1] ?? [0, 0],
                                color: AppTheme.error,
                                currentProgress: (_allCompetitorSteps[1]?.isEmpty ?? true)
                                    ? 0
                                    : math.min(
                                        1.0,
                                        replayState.currentStep /
                                            (_allCompetitorSteps[1]?.length ?? 1),
                                      ),
                                label:
                                    '${_competitors[1]['name'] ?? 'P2'} Progress',
                              ),
                            ],
                          )
                        : TrendLine(
                            data:
                                _competitorTrends[_selectedCompetitorIndex] ??
                                [0, 0],
                            color: AppTheme.accent,
                            currentProgress: (_allCompetitorSteps[_selectedCompetitorIndex]?.isEmpty ?? true)
                                ? 0
                                : math.min(
                                    1.0,
                                    replayState.currentStep /
                                        (_allCompetitorSteps[_selectedCompetitorIndex]?.length ?? 1),
                                  ),
                            label: 'Exploration Trend (Nodes vs Steps)',
                          ),
                  ),

                const Padding(
                  padding: EdgeInsets.symmetric(horizontal: 24.0, vertical: 20.0),
                  child: ReplayControls(),
                ),
                const SizedBox(height: 40), // Bottom padding for scroll
              ],
            ),
          ),
        ),
      ),
    ));
  }

  Widget _buildMainGrid({
    required List<AlgorithmStep<GridCoordinate>> steps,
    required int currentStep,
    required String label,
    required Color color,
    int? index,
    bool isMini = false,
  }) {
    final showHeuristics = ref.watch(replayProvider).showHeuristics;
    final step = steps.isEmpty || currentStep == 0
        ? null
        : steps[math.min(currentStep - 1, steps.length - 1)];

    final dynamicAspectRatio = _controller.columns / _controller.rows;

    return AspectRatio(
      aspectRatio: dynamicAspectRatio,
      child: Container(
        constraints: const BoxConstraints(maxWidth: 900),
        decoration: AppTheme.glassCard(
          radius: isMini ? 12 : 20,
          borderColor: color.withValues(alpha: isMini ? 0.5 : 0.2),
          glowColor: color,
        ),
        padding: EdgeInsets.all(isMini ? 2 : 4),
        child: Column(
          children: [
            if (!isMini)
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 4.0),
                child: Text(
                  label.toUpperCase(),
                  style: TextStyle(
                    color: color,
                    fontWeight: FontWeight.bold,
                    fontSize: 10,
                    letterSpacing: 1,
                  ),
                ),
              ),
            Expanded(
              child: ClipRRect(
                borderRadius: BorderRadius.circular(isMini ? 10 : 16),
                child: GridVisualizerCanvas(
                  controller: _controller,
                  isInteractive: true,
                  showHeuristics: showHeuristics,
                  accentColor: color,
                  exploredNodes: index == null
                      ? _fullExploredLists[0]
                      : _fullExploredLists[index],
                  exploredCount: (index == null
                      ? _exploredCountsAtStep[0]
                      : _exploredCountsAtStep[index]) != null 
                        ? (index == null ? _exploredCountsAtStep[0]! : _exploredCountsAtStep[index]!)[
                            math.min(currentStep, (index == null ? _exploredCountsAtStep[0]! : _exploredCountsAtStep[index]!).length - 1)
                          ]
                        : 0,
                  pathNodes: step?.path ?? [],
                  onPointerDown: (row, col) => _showNodeExplanation(row, col, competitorIndex: index ?? 0),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSingleMetrics(int currentStep, {int? index}) {
    final steps = index == null ? _runSteps : _allCompetitorSteps[index] ?? [];

    final step = steps.isEmpty || currentStep == 0
        ? null
        : steps[math.min(currentStep - 1, steps.length - 1)];

    final exploredCounts = (index == null ? _exploredCountsAtStep[0] : _exploredCountsAtStep[index]);
    final exploredCount = (exploredCounts != null && exploredCounts.isNotEmpty)
        ? exploredCounts[math.min(currentStep, exploredCounts.length - 1)]
        : 0;

    return Row(
      children: [
        Expanded(
          child: GlassStatCard(
            label: index == null ? 'EXPLORED' : 'EXP',
            value: exploredCount,
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: GlassStatCard(
            label: 'COST',
            value: (step?.meta?['g'] ?? 
                    step?.meta?['distance'] ?? 
                    (step != null && step.path.isNotEmpty ? step.path.length - 1 : 0)).toDouble(),
          ),
        ),
        if (index == null) ...[
          const SizedBox(width: 8),
          Expanded(
            child: GlassStatCard(label: 'STEP', value: currentStep),
          ),
        ],
      ],
    );
  }

  Widget _buildGlobalInsightCard() {
    final totalNodes = _controller.rows * _controller.columns;
    
    num? pathCost;
    if (_isBattle && _selectedCompetitorIndex < _competitors.length) {
      final comp = _competitors[_selectedCompetitorIndex];
      pathCost = comp['pathCost'] as num?;
      
      // Fallback for legacy runs: calculate cost from length
      if (pathCost == null) {
        final pathLength = comp['pathLength'] as num?;
        if (pathLength != null) {
          pathCost = pathLength.toInt() - 1;
        }
      }
    } else {
      pathCost = _metadata?['pathCost'] as num?;
      
      if (pathCost == null) {
        final pathLength = _metadata?['pathLength'] as num?;
        if (pathLength != null) {
          pathCost = pathLength.toInt() - 1;
        }
      }
    }

    final insight = InsightService.generateGlobalInsight(
      algorithmName: _algoName ?? 'Algorithm',
      steps: _runSteps,
      totalWalkableNodes: totalNodes,
      knownPathLength: pathCost?.toInt(),
    );

    return Container(
      padding: const EdgeInsets.all(24),
      decoration: AppTheme.glassCard(radius: 20).copyWith(
        border: Border.all(color: AppTheme.accent.withValues(alpha: 0.2)),
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            AppTheme.accent.withValues(alpha: 0.05),
            Colors.transparent,
          ],
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: AppTheme.accent.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Icon(Icons.psychology, color: AppTheme.accent, size: 20),
                  ),
                  const SizedBox(width: 12),
                  Text(
                    'ANALYTICAL INTELLIGENCE',
                    style: AppTheme.labelStyle.copyWith(
                      color: AppTheme.accent,
                      letterSpacing: 1.2,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
              const Icon(Icons.info_outline, color: Colors.white24, size: 16),
            ],
          ),
          const SizedBox(height: 24),
          ..._buildFormattedInsight(insight),
          const SizedBox(height: 20),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.03),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: Colors.white.withValues(alpha: 0.05)),
            ),
            child: Row(
              children: [
                const Icon(Icons.verified_user, color: Colors.white24, size: 14),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'Analysis generated via frontier expansion & heuristic telemetry.',
                    style: AppTheme.bodyStyle.copyWith(
                      fontSize: 11,
                      color: Colors.white38,
                      fontStyle: FontStyle.italic,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    ).animate().fadeIn(duration: 400.ms).slideY(begin: 0.05, curve: Curves.easeOutCubic);
  }

  List<Widget> _buildFormattedInsight(String text) {
    final sections = text.split('\n\n');
    final widgets = <Widget>[];

    for (final section in sections) {
      if (section.isEmpty) continue;

      final lines = section.split('\n');
      final header = lines[0].trim();
      
      IconData icon;
      Color color;
      
      if (header.startsWith('PERFORMANCE')) {
        icon = Icons.speed;
        color = Colors.blueAccent;
      } else if (header.startsWith('PATH RESULT')) {
        icon = Icons.route;
        color = Colors.greenAccent;
      } else if (header.startsWith('ANALYSIS')) {
        icon = Icons.analytics;
        color = Colors.orangeAccent;
      } else if (header.startsWith('INSIGHT')) {
        icon = Icons.tips_and_updates;
        color = AppTheme.accent;
      } else {
        widgets.add(Text(section, style: AppTheme.bodyStyle));
        continue;
      }

      widgets.add(
        Padding(
          padding: const EdgeInsets.only(bottom: 16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(icon, color: color.withValues(alpha: 0.7), size: 14),
                  const SizedBox(width: 8),
                  Text(
                    header.replaceAll(':', ''),
                    style: AppTheme.labelStyle.copyWith(
                      color: color.withValues(alpha: 0.8),
                      fontSize: 12,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              ...lines.skip(1).map((line) => Padding(
                padding: const EdgeInsets.only(left: 22, bottom: 4),
                child: _buildRichLine(line),
              )),
            ],
          ),
        ),
      );
    }

    return widgets;
  }

  Widget _buildRichLine(String line) {
    final content = line.startsWith('• ') ? line.substring(2) : line;
    
    // Simple regex-like splitting to bold numbers and percentages
    final words = content.split(' ');
    final spans = <TextSpan>[];

    for (final word in words) {
      final isMetric = RegExp(r'^-?\d+(\.\d+)?%?$').hasMatch(word.replaceAll(RegExp(r'[(),]'), ''));
      spans.add(TextSpan(
        text: '$word ',
        style: TextStyle(
          color: isMetric ? Colors.white : Colors.white70,
          fontWeight: isMetric ? FontWeight.bold : FontWeight.normal,
          fontSize: 14,
        ),
      ));
    }

    return RichText(
      text: TextSpan(
        children: [
          if (line.startsWith('• ')) 
            const TextSpan(text: '• ', style: TextStyle(color: Colors.white24)),
          ...spans,
        ],
        style: AppTheme.bodyStyle,
      ),
    );
  }
}
