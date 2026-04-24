import 'dart:math' as math;
import 'package:algo_arena/core/grid_problem.dart';
import 'package:algo_arena/core/problem_definition.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:algo_arena/core/app_theme.dart';
import 'package:algo_arena/widgets/grid_visualizer_canvas.dart';
import 'package:algo_arena/widgets/replay_controls.dart';
import 'package:algo_arena/state/grid_controller.dart';
import 'package:algo_arena/state/replay_provider.dart';
import 'package:algo_arena/widgets/visualizer_widgets.dart';

class ReplayScreen extends ConsumerStatefulWidget {
  const ReplayScreen({super.key});

  @override
  ConsumerState<ReplayScreen> createState() => _ReplayScreenState();
}

class _ReplayScreenState extends ConsumerState<ReplayScreen> {
  late GridController _controller;

  @override
  void initState() {
    super.initState();
    // Initialize with a default 15x25 grid, will be updated if data exists
    _controller = GridController(rows: 15, columns: 25);
    
    // Defer loading to build phase to access ModalRoute arguments
    WidgetsBinding.instance.addPostFrameCallback((_) => _loadRunData());
  }

  String? _algoName;
  List<AlgorithmStep<GridCoordinate>> _runSteps = [];
  bool _isBattle = false;
  List<dynamic> _competitors = [];
  int _selectedCompetitorIndex = 0;

  void _loadRunData() {
    final args = ModalRoute.of(context)?.settings.arguments;
    if (args is Map<String, dynamic>) {
      final isBattle = args['isBattle'] == true;
      final snapshot = args['snapshot'] as Map<String, dynamic>?;
      
      if (snapshot != null) {
        _controller.loadFromSnapshot(snapshot);
      }

      setState(() {
        _isBattle = isBattle;
        _algoName = args['algorithm'] as String?;
        
        if (isBattle) {
          _competitors = args['competitors'] as List<dynamic>? ?? [];
          if (_competitors.isNotEmpty) {
            _loadCompetitor(0);
          }
        } else {
          final steps = args['steps'] as List<dynamic>?;
          if (steps != null) {
            _runSteps = steps.map((s) => AlgorithmStep<GridCoordinate>.fromJson(s, (json) => GridCoordinate.fromJson(json))).toList();
            ref.read(replayProvider.notifier).setTotalSteps(_runSteps.length);
          }
        }
      });
    }
  }

  void _loadCompetitor(int index) {
    if (index < 0 || index >= _competitors.length) return;
    
    final comp = _competitors[index];
    final stepsRaw = comp['steps'] as List<dynamic>?;
    
    if (stepsRaw != null) {
      _runSteps = stepsRaw.map((s) => AlgorithmStep<GridCoordinate>.fromJson(s, (json) => GridCoordinate.fromJson(json))).toList();
      
      // Reset playback state for the new competitor
      final notifier = ref.read(replayProvider.notifier);
      notifier.reset();
      notifier.seek(0);
      notifier.setTotalSteps(_runSteps.length);
      
      setState(() {
        _selectedCompetitorIndex = index;
      });
    }
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
      backgroundColor: AppTheme.background,
      body: SafeArea(
        child: Column(
          children: [
            // ── Top Bar ──────────────────────────────────────────────────
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
                      child: const Icon(Icons.arrow_back_ios_new_rounded, size: 18),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'REPLAY MODE',
                        style: Theme.of(context).textTheme.labelSmall?.copyWith(
                          color: AppTheme.accentLight,
                          letterSpacing: 1.5,
                        ),
                      ),
                      Text(
                        '${_algoName ?? 'A*'} Algorithm Run',
                        style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                  const Spacer(),
                  // Algorithm Badge
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                      color: AppTheme.accent.withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(color: AppTheme.accent.withValues(alpha: 0.4)),
                    ),
                    child: Text(
                      _algoName ?? 'A*',
                      style: const TextStyle(
                        color: AppTheme.accentLight,
                        fontWeight: FontWeight.bold,
                        fontSize: 12,
                      ),
                    ),
                  ),
                ],
              ),
            ),

            // ── Battle Selector ──────────────────────────────────────────
            if (_isBattle && _competitors.isNotEmpty)
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
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
                            padding: const EdgeInsets.symmetric(vertical: 8),
                            decoration: BoxDecoration(
                              color: isSelected ? AppTheme.accent.withOpacity(0.2) : Colors.transparent,
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Center(
                              child: Text(
                                comp['name'] ?? 'Algo ${index + 1}',
                                style: TextStyle(
                                  color: isSelected ? AppTheme.accentLight : AppTheme.textMuted,
                                  fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
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

            // ── Grid Area ───────────────────────────────────────────────
            Expanded(
              child: Center(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16.0),
                  child: AspectRatio(
                    aspectRatio: 25 / 15,
                    child: Container(
                      decoration: AppTheme.glassCardAccent(radius: 20),
                      padding: const EdgeInsets.all(4),
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(16),
                        child: GridVisualizerCanvas(
                          controller: _controller,
                          isInteractive: false,
                          showHeuristics: replayState.showHeuristics,
                          exploredNodes: _runSteps.isEmpty || replayState.currentStep == 0
                              ? []
                              : _runSteps
                                  .take(replayState.currentStep)
                                  .expand((step) => step.newlyExplored)
                                  .toList(),
                          pathNodes: _runSteps.isEmpty || replayState.currentStep == 0
                              ? []
                              : _runSteps[math.min(replayState.currentStep - 1, _runSteps.length - 1)].path,
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ),

            // ── Metrics Overlay (Bottom part of Expanded) ─────────────
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
              child: Row(
                children: [
                  Expanded(
                    child: GlassStatCard(
                      label: 'EXPLORED', 
                      value: _runSteps.isEmpty || replayState.currentStep == 0
                          ? 0
                          : _runSteps.take(replayState.currentStep).expand((s) => s.newlyExplored).length,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: GlassStatCard(
                      label: 'PATH LEN', 
                      value: _runSteps.isEmpty || replayState.currentStep == 0
                          ? 0
                          : _runSteps[math.min(replayState.currentStep - 1, _runSteps.length - 1)].path.length,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: GlassStatCard(
                      label: 'NODES', 
                      value: _runSteps.isEmpty ? 0 : _runSteps.last.stepCount,
                    ),
                  ),
                ],
              ),
            ),

            // ── Playback Controls ──────────────────────────────────────
            const Padding(
              padding: EdgeInsets.all(16.0),
              child: ReplayControls(),
            ),
          ],
        ),
      ),
    );
  }
}
