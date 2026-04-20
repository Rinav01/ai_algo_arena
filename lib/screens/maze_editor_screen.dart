import 'package:flutter/material.dart';
import 'dart:async';
import 'package:ai_algo_app/models/grid_node.dart';
import 'package:ai_algo_app/state/grid_controller.dart';
import 'package:ai_algo_app/core/grid_problem.dart';
import 'package:ai_algo_app/core/search_algorithms.dart';
import 'package:ai_algo_app/services/algorithm_executor.dart';
import 'package:ai_algo_app/core/problem_definition.dart';
import 'package:ai_algo_app/core/app_theme.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:ai_algo_app/core/maze_generators.dart';

import 'package:ai_algo_app/widgets/grid_visualizer_canvas.dart';

class MazeEditorScreen extends StatefulWidget {
  const MazeEditorScreen({super.key});

  @override
  State<MazeEditorScreen> createState() => _MazeEditorScreenState();
}

class _MazeEditorScreenState extends State<MazeEditorScreen> {
  late final GridController _controller;

  @override
  void initState() {
    super.initState();
    _controller = GridController(rows: 10, columns: 10);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.background,
      body: SafeArea(
        child: Column(
            children: [
              // Header
              Padding(
                padding: EdgeInsets.all(16.r),
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
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Arena Architect',
                              style: TextStyle(
                                fontSize: 20.sp,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            Text(
                              'Editor Mode',
                              style: TextStyle(
                                fontSize: 12.sp,
                                color: Colors.grey[400],
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                    ElevatedButton.icon(
                      onPressed: _saveArena,
                      icon: const Icon(Icons.save),
                      label: const Text('Save'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFFFFA500),
                        foregroundColor: Colors.black,
                      ),
                    ),
                  ],
                ),
              ),
              // Tabs
              Padding(
                padding: EdgeInsets.symmetric(horizontal: 16.w),
                child: Row(
                  children: [
                    _buildTab('Grid Editor', true),
                    const SizedBox(width: 16),
                    _buildTab('Constraints', false),
                    const SizedBox(width: 16),
                    _buildTab('Settings', false),
                  ],
                ),
              ),
              const SizedBox(height: 16),
              // Grid Editor
              Expanded(
                child: SingleChildScrollView(
                  padding: EdgeInsets.all(16.r),
                  child: AnimatedBuilder(
                    animation: _controller,
                    builder: (context, _) {
                      return Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Grid Canvas
                          Center(
                            child: Container(
                              decoration: BoxDecoration(
                                border: Border.all(
                                  color: const Color(0xFFD4A574),
                                  width: 2.w,
                                ),
                                borderRadius: BorderRadius.circular(16.r),
                              ),
                              child: _buildGrid(),
                            ),
                          ),
                          const SizedBox(height: 24),
                          // Toolbar
                          _buildToolbar(context),
                        ],
                      );
                    },
                  ),
                ),
              ),
            ],
          ),
        ),
    );
  }

  Widget _buildTab(String label, bool isActive) {
    return Column(
      children: [
        Text(
          label,
          style: TextStyle(
            color: isActive ? Colors.white : Colors.grey[600],
            fontWeight: isActive ? FontWeight.bold : FontWeight.normal,
          ),
        ),
        const SizedBox(height: 8),
        if (isActive)
          Container(height: 3.h, width: 80.w, color: const Color(0xFFFFA500)),
      ],
    );
  }

  Widget _buildGrid() {
    return Container(
      constraints: BoxConstraints(maxWidth: 350.w, maxHeight: 350.h),
      child: GridVisualizerCanvas(
        controller: _controller,
        isInteractive: true,
      ),
    );
  }


  Widget _buildToolbar(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Tools', style: Theme.of(context).textTheme.titleMedium),
        const SizedBox(height: 12),
        Wrap(
          spacing: 12,
          runSpacing: 12,
          children: [
            _buildToolButton(
              icon: '🧱',
              label: 'Wall',
              isSelected: _controller.selectedTool == PaintTool.wall,
              onTap: () => _controller.setTool(PaintTool.wall),
            ),
            _buildToolButton(
              icon: '▶',
              label: 'Start',
              isSelected: _controller.selectedTool == PaintTool.start,
              onTap: () => _controller.setTool(PaintTool.start),
            ),
            _buildToolButton(
              icon: '🚩',
              label: 'End',
              isSelected: _controller.selectedTool == PaintTool.goal,
              onTap: () => _controller.setTool(PaintTool.goal),
            ),
            _buildToolButton(
              icon: '🗑',
              label: 'Clear',
              isSelected: _controller.selectedTool == PaintTool.erase,
              onTap: () => _controller.setTool(PaintTool.erase),
            ),
            // Random Maze generation button
            ElevatedButton.icon(
              onPressed: _generateRandomMaze,
              icon: const Icon(Icons.shuffle),
              label: const Text('Random Maze'),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF6A5ACD),
                foregroundColor: Colors.white,
              ),
            ),
            ElevatedButton.icon(
              onPressed: _solveMaze,
              icon: const Icon(Icons.play_arrow),
              label: const Text('Solve'),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFFFFA500),
                foregroundColor: Colors.black,
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildToolButton({
    required String icon,
    required String label,
    required bool isSelected,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 12.h),
        decoration: BoxDecoration(
          color: isSelected ? const Color(0xFFFFA500) : const Color(0xFF0E2233),
          borderRadius: BorderRadius.circular(12.r),
          border: Border.all(
            color: isSelected
                ? const Color(0xFFFFA500)
                : Colors.white.withValues(alpha: 0.06),
          ),
        ),
        child: Column(
          children: [
            Text(icon, style: const TextStyle(fontSize: 24)),
            const SizedBox(height: 4),
            Text(
              label,
              style: TextStyle(
                fontSize: 12.sp,
                fontWeight: FontWeight.bold,
                color: isSelected ? Colors.black : Colors.white,
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _saveArena() {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Arena saved successfully!'),
        backgroundColor: Color(0xFFFFA500),
      ),
    );
  }

  // Generate a random maze using Prim's algorithm
  void _generateRandomMaze() {
    final generator = MazeGenerator();
    generator.generateRandomizedPrims(_controller);
    setState(() {});
  }

  Future<void> _solveMaze() async {
    // Find start and goal positions
    GridCoordinate? start;
    GridCoordinate? goal;

    for (int row = 0; row < _controller.rows; row++) {
      for (int col = 0; col < _controller.columns; col++) {
        final node = _controller.grid[row][col];
        if (node.type == NodeType.start) {
          start = GridCoordinate(row: row, column: col);
        } else if (node.type == NodeType.goal) {
          goal = GridCoordinate(row: row, column: col);
        }
      }
    }

    if (start == null || goal == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please set both start and goal nodes'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    // Create grid problem from current maze
    final problem = GridProblem(
      grid: _controller.grid,
      start: start,
      goal: goal,
    );

    // Navigate to solver screen with animation; the solver screen will
    // create and control the executor so the user can choose when to run.
    await Navigator.push(
      context,
      PageRouteBuilder(
        pageBuilder: (context, animation, secondaryAnimation) {
          return _MazeSolverScreen(problem: problem, mazeName: 'Custom Maze');
        },
        transitionsBuilder: (context, animation, secondaryAnimation, child) {
          return SlideTransition(
            position: Tween<Offset>(
              begin: const Offset(1, 0),
              end: Offset.zero,
            ).animate(animation),
            child: child,
          );
        },
      ),
    );
  }
}

// Embedded solver screen for the maze
class _MazeSolverScreen extends StatefulWidget {
  final GridProblem problem;
  final String mazeName;

  const _MazeSolverScreen({required this.problem, required this.mazeName});

  @override
  State<_MazeSolverScreen> createState() => _MazeSolverScreenState();
}

class _MazeSolverScreenState extends State<_MazeSolverScreen> {
  List<GridCoordinate> explored = [];
  List<GridCoordinate> path = [];
  int stepCount = 0;
  bool isSolved = false;
  bool isSolving = false;
  StreamSubscription<AlgorithmStep<GridCoordinate>>? _stepSubscription;
  AlgorithmExecutor<GridCoordinate>? _executor;
  double _executionSpeed = 1.0;

  final Color backgroundColor = const Color(0xFF07131F);
  final Color cardColor = const Color(0xFF0E2233);
  final Color accentColor = const Color(0xFFFFA500);
  final Color exploredColor = const Color(0xFF2196F3);
  final Color pathColor = const Color(0xFF4CAF50);

  String _selectedAlgorithm = 'A*';
  final List<String> algorithms = ['A*', 'BFS', 'DFS', 'Dijkstra'];

  @override
  void initState() {
    super.initState();
    // Do not auto-start. Wait for user to press Solve/Auto.
  }

  Duration get _stepDelay {
    final ms = (180 / _executionSpeed).round().clamp(10, 2000);
    return Duration(milliseconds: ms);
  }

  Future<void> _startSolving({bool autoRun = true}) async {
    if (_executor == null) {
      SearchAlgorithm<GridCoordinate> algo;
      switch (_selectedAlgorithm) {
        case 'BFS':
          algo = BFSAlgorithm<GridCoordinate>();
          break;
        case 'DFS':
          algo = DFSAlgorithm<GridCoordinate>();
          break;
        case 'Dijkstra':
          algo = DijkstraAlgorithm<GridCoordinate>();
          break;
        case 'A*':
        default:
          algo = AStarAlgorithm<GridCoordinate>();
      }

      _executor = AlgorithmExecutor<GridCoordinate>(
        algorithm: algo,
        problem: widget.problem,
      stepDelayMs: _stepDelay.inMilliseconds,
    );
    }

    setState(() {
      isSolving = true;
      isSolved = false;
      explored = [];
      path = [];
      stepCount = 0;
    });

    try {
      await _stepSubscription?.cancel();
      _stepSubscription = _executor!.stepStream.listen(
        (step) {
          if (!mounted) return;

          setState(() {
            explored = _executor!.exploredSet.toList();
            path = step.path;
            stepCount = step.stepCount;

            if (step.isGoalReached) {
              isSolved = true;
              isSolving = false;
            }
          });
        },
        onDone: () {
          if (mounted) {
            setState(() {
              isSolving = false;
            });
          }
        },
        onError: (e) {
          if (mounted) {
            ScaffoldMessenger.of(
              context,
            ).showSnackBar(SnackBar(content: Text('Error: $e')));
            setState(() {
              isSolving = false;
            });
          }
        },
      );

      if (autoRun) {
        await _executor!.start();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Error: $e')));
        setState(() {
          isSolving = false;
        });
      }
    }
  }

  Future<void> _stepOnce() async {
    _executor ??= AlgorithmExecutor<GridCoordinate>(
        algorithm: AStarAlgorithm<GridCoordinate>(),
        problem: widget.problem,
      stepDelayMs: _stepDelay.inMilliseconds,
    );

    try {
      await _executor!.start();
      _executor!.stepOnce();
      setState(() {});
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Error: $e')));
      }
    }
  }

  void _pauseResume() {
    if (_executor == null) return;
    if (isSolving) {
      _executor?.pause();
      setState(() {
        isSolving = false;
      });
    } else {
      _executor?.resume();
      setState(() {
        isSolving = true;
      });
    }
  }

  void _resetSolver() {
    _stepSubscription?.cancel();
    _stepSubscription = null;
    if (_executor != null) {
      _executor!.stop();
      _executor!.dispose();
      _executor = null;
    }
    setState(() {
      explored = [];
      path = [];
      stepCount = 0;
      isSolved = false;
      isSolving = false;
    });
  }

  void _handleCellTap(int row, int col) {
    if (isSolving) return;

    final node = widget.problem.grid[row][col];
    if (node.type == NodeType.wall) return;

    setState(() {
      final coord = GridCoordinate(row: row, column: col);
      if (path.contains(coord)) {
        path.remove(coord);
      } else {
        path.add(coord);
      }
      
      // If the path touches the goal, we can say it's manually connected
      isSolved = path.any((c) => c.row == widget.problem.goalState.row && c.column == widget.problem.goalState.column) &&
                 path.any((c) => c.row == widget.problem.initialState.row && c.column == widget.problem.initialState.column);
      
      stepCount = 0;
      explored.clear();
    });
  }

  void _showAISolveMenu() {
    showModalBottomSheet(
      context: context,
      backgroundColor: cardColor,
      isScrollControlled: true,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16.r)),
      ),
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setModalState) {
            return Padding(
              padding: EdgeInsets.only(
                bottom: MediaQuery.of(context).viewInsets.bottom,
              ),
              child: Container(
                padding: EdgeInsets.all(16.0.r),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Text(
                      'AI Solver Panel',
                      style: Theme.of(context).textTheme.titleLarge?.copyWith(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 16),
                    _buildAlgorithmSelectorModal(setModalState),
                    const SizedBox(height: 16),
                    _buildSpeedControlModal(setModalState),
                    const SizedBox(height: 16),
                    _buildStatisticsModal(),
                    const SizedBox(height: 16),
                    const SizedBox(height: 20),
                    _buildSolverGrid(),
                    const SizedBox(height: 16),
                    _buildControlButtonsModal(setModalState),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  Widget _buildSolverGrid() {
    return Container(
      constraints: BoxConstraints(maxWidth: 320.w, maxHeight: 320.h),
      child: GridVisualizerCanvas(
        controller: GridController(
          rows: widget.problem.grid.length,
          columns: widget.problem.grid[0].length,
        )..loadFromGrid(widget.problem.grid),
        executor: _executor,
        isInteractive: false,
      ),
    );
  }

  Widget _buildAlgorithmSelectorModal(StateSetter setModalState) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Select Algorithm',
          style: Theme.of(context).textTheme.titleSmall?.copyWith(color: Colors.white),
        ),
        const SizedBox(height: 8),
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: Row(
            children: algorithms.map((algo) {
              final isSelected = _selectedAlgorithm == algo;
              return Padding(
                padding: EdgeInsets.only(right: 8.w),
                child: FilterChip(
                  label: Text(algo),
                  selected: isSelected,
                  onSelected: (selected) {
                    if (!isSolving) {
                      setState(() {
                        _selectedAlgorithm = algo;
                        _resetSolver();
                      });
                      setModalState(() {});
                    }
                  },
                  backgroundColor: Colors.grey[800],
                  selectedColor: accentColor,
                  labelStyle: TextStyle(
                    color: isSelected ? Colors.black : Colors.white,
                  ),
                ),
              );
            }).toList(),
          ),
        ),
      ],
    );
  }

  Widget _buildSpeedControlModal(StateSetter setModalState) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Execution Speed: ${_executionSpeed.toStringAsFixed(1)}x',
          style: Theme.of(context).textTheme.titleSmall?.copyWith(color: Colors.white),
        ),
        const SizedBox(height: 8),
        Slider(
          value: _executionSpeed,
          min: 0.1,
          max: 5.0,
          onChanged: isSolving
              ? null
              : (value) {
                  setState(() {
                    _executionSpeed = value;
                  });
                  setModalState(() {});
                },
          activeColor: accentColor,
        ),
      ],
    );
  }

  Widget _buildStatisticsModal() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        _buildStatCard('Steps', '$stepCount'),
        _buildStatCard('Explored', '${explored.length}'),
        _buildStatCard('Path', '${path.length}'),
      ],
    );
  }

  Widget _buildControlButtonsModal(StateSetter setModalState) {
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      alignment: WrapAlignment.center,
      children: [
        ElevatedButton.icon(
          onPressed: isSolving
              ? null
              : () {
                  _startSolving(autoRun: true).then((_) => setModalState(() {}));
                },
          icon: const Icon(Icons.play_arrow),
          label: const Text('Solve'),
          style: ElevatedButton.styleFrom(
            backgroundColor: accentColor,
            foregroundColor: Colors.black,
          ),
        ),
        ElevatedButton.icon(
          onPressed: stepCount > 0 || isSolving
              ? () {
                  _pauseResume();
                  setModalState(() {});
                }
              : null,
          icon: Icon(isSolving ? Icons.pause : Icons.play_arrow),
          label: Text(isSolving ? 'Pause' : 'Resume'),
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.blue,
            foregroundColor: Colors.white,
          ),
        ),
        ElevatedButton.icon(
          onPressed: isSolving
              ? null
              : () {
                  _stepOnce();
                  setModalState(() {});
                },
          icon: const Icon(Icons.skip_next),
          label: const Text('Step'),
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.cyan,
            foregroundColor: Colors.black,
          ),
        ),
        ElevatedButton.icon(
          onPressed: () {
            _resetSolver();
            setModalState(() {});
          },
          icon: const Icon(Icons.refresh),
          label: const Text('Reset'),
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.grey[700],
            foregroundColor: Colors.white,
          ),
        ),
      ],
    );
  }

  Color _getCellColor(int row, int col) {
    final node = widget.problem.grid[row][col];

    // Check if in path (solution)
    if (path.any((coord) => coord.row == row && coord.column == col)) {
      return pathColor.withValues(alpha: 0.8);
    }

    // Check if explored
    if (explored.any((coord) => coord.row == row && coord.column == col)) {
      return exploredColor.withValues(alpha: 0.6);
    }

    // Map node type to color
    if (node.type == NodeType.wall) {
      return const Color(0xFF1a3a3a);
    } else if (node.type == NodeType.start) {
      return Colors.amber.withValues(alpha: 0.6);
    } else if (node.type == NodeType.goal) {
      return Colors.red.withValues(alpha: 0.6);
    }

    return cardColor;
  }

  @override
  void dispose() {
    _stepSubscription?.cancel();
    if (_executor != null) {
      _executor!.stop();
      _executor!.dispose();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: backgroundColor,
      appBar: AppBar(
        backgroundColor: cardColor,
        title: Text(widget.mazeName),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: EdgeInsets.all(16.0.r),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Grid Visualization
              Container(
                padding: EdgeInsets.all(16.r),
                decoration: BoxDecoration(
                  color: cardColor,
                  borderRadius: BorderRadius.circular(8.r),
                  border: Border.all(color: accentColor.withValues(alpha: 0.3)),
                ),
                child: SingleChildScrollView(
                  child: GridView.builder(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: widget.problem.grid.first.length,
                      childAspectRatio: 1,
                      crossAxisSpacing: 1,
                      mainAxisSpacing: 1,
                    ),
                    itemCount:
                        widget.problem.grid.length *
                        widget.problem.grid.first.length,
                    itemBuilder: (context, index) {
                      final row = index ~/ widget.problem.grid.first.length;
                      final col = index % widget.problem.grid.first.length;

                      return GestureDetector(
                        onTap: () => _handleCellTap(row, col),
                        child: AnimatedContainer(
                          duration: const Duration(milliseconds: 300),
                          decoration: BoxDecoration(
                            color: _getCellColor(row, col),
                            border: Border.all(
                              color: Colors.grey[800]!.withValues(alpha: 0.5),
                              width: 0.5.w,
                            ),
                          ),
                        ),
                      );
                    },
                  ),
                ),
              ),
              const SizedBox(height: 16),

              // Notice for manual play
              Container(
                padding: EdgeInsets.all(12.r),
                decoration: BoxDecoration(
                  color: exploredColor.withValues(alpha: 0.1),
                  border: Border.all(color: exploredColor),
                  borderRadius: BorderRadius.circular(8.r),
                ),
                child: const Text(
                  'Tap on grid cells to draw a path manually, or use the AI Solver.',
                  style: TextStyle(color: Colors.white, fontSize: 13),
                  textAlign: TextAlign.center,
                ),
              ),
              const SizedBox(height: 16),

              if (isSolved)
                Container(
                  padding: EdgeInsets.all(16.r),
                  decoration: BoxDecoration(
                    color: pathColor.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(8.r),
                    border: Border.all(color: pathColor, width: 2),
                  ),
                  child: Row(
                    children: [
                      Icon(Icons.check_circle, color: pathColor),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          'Maze Solved!',
                          style: TextStyle(
                            color: pathColor,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
            ],
          ),
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _showAISolveMenu,
        backgroundColor: accentColor,
        icon: const Icon(Icons.smart_toy, color: Colors.black),
        label: const Text(
          'AI Solve',
          style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold),
        ),
      ),
    );
  }

  Widget _buildStatCard(String label, String value) {
    return Container(
      padding: EdgeInsets.all(8.r),
      decoration: BoxDecoration(
        color: cardColor,
        borderRadius: BorderRadius.circular(8.r),
        border: Border.all(color: accentColor.withValues(alpha: 0.2)),
      ),
      child: Column(
        children: [
          Text(
            label,
            style: TextStyle(
              fontSize: 9.sp,
              fontWeight: FontWeight.bold,
              color: Colors.grey[400],
            ),
          ),
          const SizedBox(height: 2),
          Text(
            value,
            style: TextStyle(
              fontSize: 14.sp,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
        ],
      ),
    );
  }
}
