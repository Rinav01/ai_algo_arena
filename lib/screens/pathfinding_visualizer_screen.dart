import 'package:ai_algo_app/core/problem_definition.dart';
import 'package:flutter/material.dart';
import 'dart:async';
import '../core/grid_problem.dart';
import '../core/search_algorithms.dart';
import '../services/algorithm_executor.dart';
// removed unused import
import '../widgets/algorithm_recommendation_card.dart';
import '../widgets/animated_number_display.dart';
import '../models/grid_node.dart';
import '../state/grid_controller.dart';

class PathfindingVisualizerScreen extends StatefulWidget {
  final String algorithmId;
  final String title;

  const PathfindingVisualizerScreen({
    super.key,
    required this.algorithmId,
    required this.title,
  });

  @override
  State<PathfindingVisualizerScreen> createState() => _PathfindingVisualizerScreenState();
}

class _PathfindingVisualizerScreenState extends State<PathfindingVisualizerScreen> {
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

  final Color backgroundColor = const Color(0xFF07131F);
  final Color cardColor = const Color(0xFF0E2233);
  final Color accentColor = const Color(0xFFFFA500);
  final Color exploredColor = const Color(0xFF2196F3);
  final Color pathColor = const Color(0xFF4CAF50);

  Duration get _stepDelay {
    final milliseconds = (180 / _executionSpeed).round().clamp(10, 1800);
    return Duration(milliseconds: milliseconds);
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
      _statusMessage = 'Starting A* search...';
    });

    SearchAlgorithm<GridCoordinate> algo;
    switch (widget.algorithmId) {
      case 'BFS':
        algo = BFSAlgorithm<GridCoordinate>(stepDelay: _stepDelay);
        break;
      case 'DFS':
        algo = DFSAlgorithm<GridCoordinate>(stepDelay: _stepDelay);
        break;
      case 'Dijkstra':
        algo = DijkstraAlgorithm<GridCoordinate>(stepDelay: _stepDelay);
        break;
      case 'A*':
      default:
        algo = AStarAlgorithm<GridCoordinate>(stepDelay: _stepDelay);
    }

    _executor = AlgorithmExecutor<GridCoordinate>(
      algorithm: algo,
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
            ScaffoldMessenger.of(
              context,
            ).showSnackBar(SnackBar(content: Text('Error: $error')));
          }
        },
        onDone: () {
          if (mounted) {
            setState(() {
              _isSolving = false;
            });
          }
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
    if (_isSolving) {
      _executor?.stop();
    }
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

  Future<void> _autoSolve() async {
    // Run through entire solve without manual step control
    if (_isSolving) return;

    _solvePuzzle();
    // Continue automatically - the stream listener will handle updates
    // Auto mode just means never pausing the executor
  }

  @override
  void dispose() {
    if (_isSolving) {
      _executor?.stop();
    }
    _stepSubscription?.cancel();
    _executor?.dispose();
    _controller.dispose();
    super.dispose();
  }

  Color _getCellColor(int row, int col) {
    final node = _controller.grid[row][col];

    // Check if in path (solution) - highest priority
    if (_path.any((coord) => coord.row == row && coord.column == col)) {
      return pathColor;
    }

    // Check if explored
    if (_explored.any((coord) => coord.row == row && coord.column == col)) {
      return exploredColor;
    }

    // Map node type to color
    if (node.type == NodeType.wall) {
      return const Color(0xFF1a3a3a);
    } else if (node.type == NodeType.start) {
      return Colors.amber.withOpacity(0.6);
    } else if (node.type == NodeType.goal) {
      return Colors.red.withOpacity(0.6);
    }

    return cardColor;
  }

  bool _isCurrentNode(int row, int col) {
    if (_explored.isEmpty) return false;
    final lastExplored = _explored.last;
    return lastExplored.row == row && lastExplored.column == col;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: backgroundColor,
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [Color(0xFF08111B), Color(0xFF0B1D2C), Color(0xFF07131F)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
        child: SafeArea(
          child: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // Header
                Padding(
                  padding: const EdgeInsets.all(16),
                  child: Row(
                    children: [
                      IconButton(
                        onPressed: () => Navigator.pop(context),
                        icon: const Icon(Icons.arrow_back),
                      ),
                      const SizedBox(width: 12),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            widget.title,
                            style: const TextStyle(
                              fontSize: 24,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          Text(
                            'Pathfinding Visualizer',
                            style: TextStyle(
                              fontSize: 12,
                              color: Colors.grey[400],
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),

                // AI Recommendation Card
                (_problem.grid.length * _problem.grid.first.length) > 50 && _problem.obstacleDensity < 0.1
                    ? AlgorithmRecommendationCard(
                        problem: _problem,
                        onUseRecommended: _solvePuzzle,
                        accentColor: accentColor,
                        cardColor: cardColor,
                      )
                    : const SizedBox.shrink(),

                // Statistics
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: Row(
                    children: [
                      Expanded(
                        child: _buildAnimatedStatCard('STEPS', _stepCount),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: _buildAnimatedStatCard(
                          'EXPLORED',
                          _nodesExplored,
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: _buildAnimatedStatCard(
                          'PATH LENGTH',
                          _path.length,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),

                // Status Message
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: cardColor,
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: accentColor.withOpacity(0.3)),
                    ),
                    child: Text(
                      _statusMessage,
                      style: TextStyle(
                        color: _isSolved ? Colors.green[300] : Colors.grey[300],
                        fontSize: 12,
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 16),

                // Legend
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: cardColor,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: accentColor.withOpacity(0.2),
                        width: 1,
                      ),
                    ),
                    child: Wrap(
                      spacing: 16,
                      runSpacing: 12,
                      children: [
                        _buildLegendItem(Colors.amber, 'Start'),
                        _buildLegendItem(Colors.red, 'Goal'),
                        _buildLegendItem(Colors.grey, 'Wall'),
                        _buildLegendItem(exploredColor, 'Explored'),
                        _buildLegendItem(pathColor, 'Path'),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 16),

                // Grid Visualization
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: Container(
                    decoration: BoxDecoration(
                      border: Border.all(
                        color: accentColor.withOpacity(0.4),
                        width: 2,
                      ),
                      borderRadius: BorderRadius.circular(16),
                    ),
                    padding: const EdgeInsets.all(8),
                    child: GridView.builder(
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
                        final col = index % _controller.columns;
                        final isCurrent = _isCurrentNode(row, col);

                        return AnimatedContainer(
                          duration: const Duration(milliseconds: 300),
                          decoration: BoxDecoration(
                            color: _getCellColor(row, col),
                            border: Border.all(
                              color: Colors.grey[800]!.withOpacity(0.5),
                              width: 0.5,
                            ),
                            boxShadow: isCurrent
                                ? [
                                    BoxShadow(
                                      color: exploredColor.withOpacity(0.8),
                                      blurRadius: 8,
                                      spreadRadius: 2,
                                    ),
                                  ]
                                : null,
                          ),
                        );
                      },
                    ),
                  ),
                ),
                const SizedBox(height: 16),

                // Speed Control
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Speed: ${_executionSpeed.toStringAsFixed(1)}x',
                        style: TextStyle(color: Colors.grey[400], fontSize: 12),
                      ),
                      const SizedBox(height: 8),
                      Slider(
                        value: _executionSpeed,
                        min: 0.1,
                        max: 5.0,
                        onChanged: _isSolving
                            ? null
                            : (value) {
                                setState(() {
                                  _executionSpeed = value;
                                });
                              },
                        activeColor: accentColor,
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),

                // Control Buttons
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    alignment: WrapAlignment.center,
                    children: [
                      ElevatedButton.icon(
                        onPressed: _isSolving ? null : _solvePuzzle,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: accentColor,
                          foregroundColor: Colors.black,
                        ),
                        icon: const Icon(Icons.play_arrow),
                        label: const Text('Solve'),
                      ),
                      ElevatedButton.icon(
                        onPressed: _isSolving ? null : _autoSolve,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.green,
                          foregroundColor: Colors.white,
                        ),
                        icon: const Icon(Icons.fast_forward),
                        label: const Text('Auto'),
                      ),
                      ElevatedButton.icon(
                        onPressed: _stepCount > 0 ? _pauseResume : null,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.blue,
                          foregroundColor: Colors.white,
                        ),
                        icon: Icon(_isSolving ? Icons.pause : Icons.play_arrow),
                        label: Text(_isSolving ? 'Pause' : 'Resume'),
                      ),
                      ElevatedButton.icon(
                        onPressed: _stepCount > 0 ? _stepOnce : null,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.cyan,
                          foregroundColor: Colors.black,
                        ),
                        icon: const Icon(Icons.skip_next),
                        label: const Text('Step'),
                      ),
                      ElevatedButton.icon(
                        onPressed: _reset,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.grey[700],
                          foregroundColor: Colors.white,
                        ),
                        icon: const Icon(Icons.refresh),
                        label: const Text('Reset'),
                      ),
                      ElevatedButton.icon(
                        onPressed: _clearWalls,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.red[700],
                          foregroundColor: Colors.white,
                        ),
                        icon: const Icon(Icons.delete_outline),
                        label: const Text('Clear'),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 24),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildStatCard(String label, String value) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: cardColor,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: accentColor.withOpacity(0.2)),
      ),
      child: Column(
        children: [
          Text(
            label,
            style: TextStyle(
              fontSize: 10,
              fontWeight: FontWeight.bold,
              color: Colors.grey[400],
              letterSpacing: 1,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            value,
            style: const TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAnimatedStatCard(String label, int value) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: cardColor,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: accentColor.withOpacity(0.2)),
      ),
      child: Column(
        children: [
          Text(
            label,
            style: TextStyle(
              fontSize: 10,
              fontWeight: FontWeight.bold,
              color: Colors.grey[400],
              letterSpacing: 1,
            ),
          ),
          const SizedBox(height: 4),
          AnimatedNumberDisplay(
            value: value,
            duration: const Duration(milliseconds: 600),
            curve: Curves.easeOutCubic,
            textStyle: const TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLegendItem(Color color, String label) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 12,
          height: 12,
          decoration: BoxDecoration(
            color: color,
            borderRadius: BorderRadius.circular(2),
          ),
        ),
        const SizedBox(width: 6),
        Text(label, style: TextStyle(fontSize: 12, color: Colors.grey[300])),
      ],
    );
  }
}
