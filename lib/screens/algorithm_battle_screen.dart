import 'dart:async';

import 'package:flutter/material.dart';

import '../core/grid_problem.dart';
import '../core/problem_definition.dart';
import '../core/search_algorithms.dart';
import '../models/grid_node.dart';
import '../services/algorithm_executor.dart';
import '../services/battle_analyzer.dart';
import '../state/grid_controller.dart';
import '../widgets/battle_results_panel.dart';

class AlgorithmBattleScreen extends StatefulWidget {
  const AlgorithmBattleScreen({super.key});

  @override
  State<AlgorithmBattleScreen> createState() => _AlgorithmBattleScreenState();
}

class _AlgorithmBattleScreenState extends State<AlgorithmBattleScreen> {
  late final GridController _controller;
  AlgorithmExecutor<GridCoordinate>? _bfsExecutor;
  AlgorithmExecutor<GridCoordinate>? _dfsExecutor;
  AlgorithmStep<GridCoordinate>? _bfsStep;
  AlgorithmStep<GridCoordinate>? _dfsStep;
  AlgorithmMetrics? _bfsMetrics;
  AlgorithmMetrics? _dfsMetrics;
  bool _isRunning = false;

  @override
  void initState() {
    super.initState();
    _controller = GridController(rows: 8, columns: 20);
  }

  @override
  void dispose() {
    _bfsExecutor?.dispose();
    _dfsExecutor?.dispose();
    _controller.dispose();
    super.dispose();
  }

  Future<void> _runBattle() async {
    if (_isRunning) return;

    setState(() {
      _isRunning = true;
      _bfsStep = null;
      _dfsStep = null;
      _bfsMetrics = null;
      _dfsMetrics = null;
    });

    await _bfsExecutor?.dispose();
    await _dfsExecutor?.dispose();

    final problem = GridProblem(
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

    _bfsExecutor = AlgorithmExecutor<GridCoordinate>(
      algorithm: BFSAlgorithm<GridCoordinate>(),
      problem: problem,
    );
    _dfsExecutor = AlgorithmExecutor<GridCoordinate>(
      algorithm: DFSAlgorithm<GridCoordinate>(),
      problem: problem,
    );

    try {
      final bfsDone = _runTrackedExecutor(
        executor: _bfsExecutor!,
        algorithmName: 'Breadth-First Search',
        onStep: (step) {
          if (!mounted) return;
          setState(() {
            _bfsStep = step;
          });
        },
        onFinished: (step, executionTime) {
          if (!mounted) return;
          setState(() {
            _bfsStep = step;
            _bfsMetrics = AlgorithmMetrics(
              algorithmName: 'Breadth-First Search',
              exploredStates: step.explored,
              path: step.path,
              totalSteps: step.stepCount,
              executionTime: executionTime,
              pathCost: step.path.length.toDouble(),
              foundPath: step.path.isNotEmpty,
            );
          });
        },
      );
      final dfsDone = _runTrackedExecutor(
        executor: _dfsExecutor!,
        algorithmName: 'Depth-First Search',
        onStep: (step) {
          if (!mounted) return;
          setState(() {
            _dfsStep = step;
          });
        },
        onFinished: (step, executionTime) {
          if (!mounted) return;
          setState(() {
            _dfsStep = step;
            _dfsMetrics = AlgorithmMetrics(
              algorithmName: 'Depth-First Search',
              exploredStates: step.explored,
              path: step.path,
              totalSteps: step.stepCount,
              executionTime: executionTime,
              pathCost: step.path.length.toDouble(),
              foundPath: step.path.isNotEmpty,
            );
          });
        },
      );

      await Future.wait([bfsDone, dfsDone]);
    } finally {
      if (mounted) {
        setState(() {
          _isRunning = false;
        });
      }
    }
  }

  Future<void> _runTrackedExecutor({
    required AlgorithmExecutor<GridCoordinate> executor,
    required String algorithmName,
    required void Function(AlgorithmStep<GridCoordinate> step) onStep,
    required void Function(
      AlgorithmStep<GridCoordinate> step,
      Duration executionTime,
    )
    onFinished,
  }) async {
    final completer = Completer<void>();
    final stopwatch = Stopwatch()..start();
    AlgorithmStep<GridCoordinate>? latestStep;

    await executor.start();

    executor.stepStream.listen(
      (step) {
        latestStep = step;
        onStep(step);
      },
      onDone: () {
        stopwatch.stop();
        final finalStep =
            latestStep ??
            AlgorithmStep<GridCoordinate>(
              explored: const [],
              path: const [],
              stepCount: 0,
              message: '$algorithmName did not emit steps.',
            );
        onFinished(finalStep, stopwatch.elapsed);
        if (!completer.isCompleted) {
          completer.complete();
        }
      },
      onError: (_) {
        stopwatch.stop();
        if (!completer.isCompleted) {
          completer.complete();
        }
      },
    );

    return completer.future;
  }

  void _randomizeMaze() {
    _controller.clearWalls();
    final randomSeed = DateTime.now().millisecondsSinceEpoch % 100;
    for (int i = 0; i < randomSeed; i++) {
      final row = (i * 7) % _controller.rows;
      final col = (i * 11) % _controller.columns;
      _controller.handleCellInteraction(row, col);
    }

    setState(() {
      _bfsStep = null;
      _dfsStep = null;
      _bfsMetrics = null;
      _dfsMetrics = null;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [Color(0xFF08111B), Color(0xFF0B1D2C), Color(0xFF07131F)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
        child: SafeArea(
          child: Column(
            children: [
              Padding(
                padding: const EdgeInsets.all(16),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Row(
                      children: [
                        IconButton(
                          onPressed: () => Navigator.pop(context),
                          icon: const Icon(Icons.arrow_back),
                        ),
                        const SizedBox(width: 8),
                        const Text(
                          'Algorithm Battle',
                          style: TextStyle(
                            fontSize: 22,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 6,
                      ),
                      decoration: BoxDecoration(
                        color: const Color(0xFFFFA500),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: const Text(
                        'LIVE DUEL',
                        style: TextStyle(
                          color: Colors.black,
                          fontWeight: FontWeight.bold,
                          fontSize: 12,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              Expanded(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: Column(
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: _buildAlgoInfo(
                              'BREADTH-FIRST SEARCH',
                              _bfsStep,
                              Colors.amber,
                            ),
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: _buildAlgoInfo(
                              'DEPTH-FIRST SEARCH',
                              _dfsStep,
                              Colors.red,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      BattleResultsPanel(
                        algorithmAMetrics: _bfsMetrics,
                        algorithmBMetrics: _dfsMetrics,
                        algorithmAName: 'BFS',
                        algorithmBName: 'DFS',
                        isLoading: _isRunning,
                      ),
                      const SizedBox(height: 16),
                      Container(
                        decoration: BoxDecoration(
                          border: Border.all(
                            color: const Color(0xFFD4A574),
                            width: 2,
                          ),
                          borderRadius: BorderRadius.circular(16),
                        ),
                        padding: const EdgeInsets.all(8),
                        child: AnimatedBuilder(
                          animation: _controller,
                          builder: (context, _) {
                            return _buildBattleGrid();
                          },
                        ),
                      ),
                      const SizedBox(height: 24),
                      Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: const Color(0xFF0E2233),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: Colors.white.withOpacity(0.06),
                          ),
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                          children: [
                            _buildStatItem(
                              'BFS EXPLORED',
                              '${_bfsStep?.explored.length ?? 0}',
                            ),
                            _buildStatItem(
                              'DFS EXPLORED',
                              '${_dfsStep?.explored.length ?? 0}',
                            ),
                            _buildStatItem(
                              'STATUS',
                              _isRunning ? 'Running' : 'Idle',
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 24),
                    ],
                  ),
                ),
              ),
              Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        _buildControlButton(
                          icon: Icons.replay,
                          onTap: _randomizeMaze,
                        ),
                        const SizedBox(width: 16),
                        SizedBox(
                          width: 200,
                          child: ElevatedButton(
                            onPressed: _isRunning ? null : _runBattle,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: const Color(0xFFFFA500),
                              foregroundColor: Colors.black,
                              disabledBackgroundColor: Colors.grey[600],
                              padding: const EdgeInsets.symmetric(vertical: 16),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                            ),
                            child: Text(
                              _isRunning ? 'BATTLING...' : 'START BATTLE',
                              style: const TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 14,
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 16),
                        _buildControlButton(
                          icon: Icons.skip_next,
                          onTap: () {},
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                      children: [
                        _buildModeButton('Maze Type', onTap: () {}),
                        _buildModeButton(
                          'Delay: 5ms',
                          isActive: true,
                          onTap: () {},
                        ),
                        _buildModeButton('Randomize', onTap: _randomizeMaze),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildAlgoInfo(
    String name,
    AlgorithmStep<GridCoordinate>? step,
    Color color,
  ) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withOpacity(0.5), width: 1),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            name,
            style: TextStyle(
              fontSize: 10,
              fontWeight: FontWeight.bold,
              color: color,
              letterSpacing: 1,
            ),
          ),
          const SizedBox(height: 8),
          if (step != null)
            Text(
              'Frontier: [${step.explored.take(3).map((e) => '${e.row},${e.column}').join(', ')}...]',
              style: const TextStyle(fontSize: 11),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            )
          else
            Text(
              'Ready to battle',
              style: TextStyle(fontSize: 11, color: Colors.grey[400]),
            ),
        ],
      ),
    );
  }

  Widget _buildBattleGrid() {
    final grid = _controller.grid;
    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: _controller.columns,
        childAspectRatio: 1,
        crossAxisSpacing: 1,
        mainAxisSpacing: 1,
      ),
      itemCount: _controller.rows * _controller.columns,
      itemBuilder: (context, index) {
        final row = index ~/ _controller.columns;
        final column = index % _controller.columns;
        final node = grid[row][column];

        bool isBfsExplored = false;
        bool isDfsExplored = false;
        bool isPath = false;

        if (_bfsStep != null) {
          isBfsExplored = _bfsStep!.explored.any(
            (e) => e.row == row && e.column == column,
          );
          isPath = _bfsStep!.path.any(
            (e) => e.row == row && e.column == column,
          );
        }

        if (_dfsStep != null && !isBfsExplored && !isPath) {
          isDfsExplored = _dfsStep!.explored.any(
            (e) => e.row == row && e.column == column,
          );
        }

        final cellColor = _getCellBattleColor(
          node,
          isPath,
          isBfsExplored,
          isDfsExplored,
        );

        return Container(
          decoration: BoxDecoration(
            color: cellColor,
            border: Border.all(color: Colors.grey[800]!, width: 0.5),
          ),
        );
      },
    );
  }

  Color _getCellBattleColor(
    GridNode node,
    bool isPath,
    bool isBfsExplored,
    bool isDfsExplored,
  ) {
    if (node.type == NodeType.wall) return const Color(0xFF1A3A3A);
    if (node.type == NodeType.start) return Colors.amber.withOpacity(0.5);
    if (node.type == NodeType.goal) return Colors.red.withOpacity(0.5);
    if (isPath) return Colors.green.withOpacity(0.6);
    if (isBfsExplored) return Colors.amber.withOpacity(0.3);
    if (isDfsExplored) return Colors.red.withOpacity(0.3);
    return const Color(0xFF0E2233);
  }

  Widget _buildStatItem(String label, String value) {
    return Column(
      children: [
        Text(
          label,
          style: TextStyle(
            fontSize: 10,
            color: Colors.grey[400],
            fontWeight: FontWeight.bold,
            letterSpacing: 1,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          value,
          style: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
            color: Color(0xFFFFA500),
          ),
        ),
      ],
    );
  }

  Widget _buildControlButton({
    required IconData icon,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: const Color(0xFF0E2233),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.white.withOpacity(0.06)),
        ),
        child: Icon(icon, color: const Color(0xFFFFA500)),
      ),
    );
  }

  Widget _buildModeButton(
    String label, {
    bool isActive = false,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
          color: isActive ? const Color(0xFFFFA500) : const Color(0xFF0E2233),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isActive
                ? const Color(0xFFFFA500)
                : Colors.white.withOpacity(0.06),
          ),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 11,
            color: isActive ? Colors.black : Colors.white,
          ),
        ),
      ),
    );
  }
}
