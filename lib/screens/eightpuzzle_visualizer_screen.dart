import 'package:flutter/material.dart';
import 'dart:async';
import '../core/eightpuzzle_problem.dart';
import '../core/search_algorithms.dart';
import '../services/algorithm_executor.dart';
import '../core/problem_definition.dart';

class EightPuzzleVisualizerScreen extends StatefulWidget {
  const EightPuzzleVisualizerScreen({Key? key}) : super(key: key);

  @override
  State<EightPuzzleVisualizerScreen> createState() =>
      _EightPuzzleVisualizerScreenState();
}

class _EightPuzzleVisualizerScreenState
    extends State<EightPuzzleVisualizerScreen> {
  late EightPuzzleProblem problem;
  late PuzzleState currentState;
  AlgorithmExecutor<PuzzleState>? executor;
  StreamSubscription<AlgorithmStep<PuzzleState>>? _stepSubscription;

  final Color backgroundColor = const Color(0xFF07131F);
  final Color cardColor = const Color(0xFF0E2233);
  final Color accentColor = const Color(0xFFFFA500);
  final Color successColor = const Color(0xFF4CAF50);
  final Color exploringColor = const Color(0xFF2196F3);

  List<PuzzleState> currentPath = [];
  Set<String> exploredStates = {};
  int stepCount = 0;
  int nodesExplored = 0;
  bool isSolving = false;
  bool isSolved = false;
  String selectedAlgorithm = 'A*';
  double executionSpeed = 1.0;
  String _statusMessage = 'Ready to solve';

  final List<String> algorithms = ['BFS', 'DFS', 'A*', 'Dijkstra'];

  Duration get _stepDelay {
    final milliseconds = (220 / executionSpeed).round().clamp(10, 2200);
    return Duration(milliseconds: milliseconds);
  }

  @override
  void initState() {
    super.initState();
    _resetPuzzle();
  }

  void _resetPuzzle() {
    _stepSubscription?.cancel();
    _stepSubscription = null;
    if (executor != null) {
      executor!.stop();
      executor!.dispose();
      executor = null;
    }
    // Create slightly scrambled puzzle for testing
    final scrambled = EightPuzzleProblem.scramble(5);
    problem = EightPuzzleProblem(initialState: scrambled);
    currentState = problem.initialState;
    currentPath = [currentState];
    exploredStates.clear();
    stepCount = 0;
    nodesExplored = 0;
    isSolving = false;
    isSolved = false;
    selectedAlgorithm = 'A*';
    _statusMessage = 'Ready to solve';
  }

  Future<void> _solvePuzzle() async {
    if (isSolving) return;

    setState(() {
      isSolving = true;
      isSolved = false;
      exploredStates.clear();
      currentPath = [problem.initialState];
      stepCount = 0;
      nodesExplored = 0;
      _statusMessage = 'Starting ${selectedAlgorithm}...';
    });

    // Create appropriate algorithm with step delay
    late SearchAlgorithm<PuzzleState> algorithm;
    switch (selectedAlgorithm) {
      case 'BFS':
        algorithm = BFSAlgorithm<PuzzleState>(stepDelay: _stepDelay);
        break;
      case 'DFS':
        algorithm = DFSAlgorithm<PuzzleState>(stepDelay: _stepDelay);
        break;
      case 'A*':
        algorithm = AStarAlgorithm<PuzzleState>(stepDelay: _stepDelay);
        break;
      case 'Dijkstra':
        algorithm = DijkstraAlgorithm<PuzzleState>(stepDelay: _stepDelay);
        break;
    }

    // create executor
    executor = AlgorithmExecutor<PuzzleState>(
      algorithm: algorithm,
      problem: problem,
    );

    try {
      await executor!.start();

      await _stepSubscription?.cancel();
      _stepSubscription = executor!.stepStream.listen(
        (step) {
          if (!mounted) return;

          setState(() {
            stepCount = step.stepCount;
            nodesExplored = step.explored.length;
            exploredStates = step.explored.map((s) => s.toString()).toSet();

            if (step.path.isNotEmpty) {
              currentPath = step.path;
              currentState = step.path.last;
            } else if (step.explored.isNotEmpty) {
              currentState = step.explored.last;
            }

            _statusMessage = step.message ?? _statusMessage;

            if (step.isGoalReached) {
              isSolved = true;
              isSolving = false;
              _statusMessage =
                  'Solution found! Path length: ${currentPath.length} moves';
            }
          });
        },
        onError: (error) {
          if (mounted) {
            ScaffoldMessenger.of(
              context,
            ).showSnackBar(SnackBar(content: Text('Error: $error')));
            setState(() {
              isSolving = false;
              _statusMessage = 'Error: $error';
            });
          }
        },
        onDone: () {
          if (mounted) {
            setState(() {
              isSolving = false;
            });
          }
        },
      );
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Error: $e')));
        setState(() {
          isSolving = false;
          _statusMessage = 'Error: $e';
        });
      }
    }
  }

  void _reset() {
    if (isSolving) {
      executor?.stop();
    }
    _stepSubscription?.cancel();
    _stepSubscription = null;
    if (executor != null) {
      executor!.stop();
      executor!.dispose();
      executor = null;
    }
    setState(() {
      _resetPuzzle();
    });
  }

  void _pauseResume() {
    if (isSolving) {
      executor?.pause();
      setState(() {
        isSolving = false;
        _statusMessage = 'Paused';
      });
    } else if (stepCount > 0) {
      executor?.resume();
      setState(() {
        isSolving = true;
        _statusMessage = 'Resumed';
      });
    }
  }

  void _step() {
    if (isSolving) return;

    if (executor == null) {
      // create executor with currently selected algorithm but don't auto-run
      late SearchAlgorithm<PuzzleState> algorithm;
      switch (selectedAlgorithm) {
        case 'BFS':
          algorithm = BFSAlgorithm<PuzzleState>(stepDelay: _stepDelay);
          break;
        case 'DFS':
          algorithm = DFSAlgorithm<PuzzleState>(stepDelay: _stepDelay);
          break;
        case 'A*':
          algorithm = AStarAlgorithm<PuzzleState>(stepDelay: _stepDelay);
          break;
        case 'Dijkstra':
          algorithm = DijkstraAlgorithm<PuzzleState>(stepDelay: _stepDelay);
          break;
      }
      executor = AlgorithmExecutor<PuzzleState>(
        algorithm: algorithm,
        problem: problem,
      );
      executor!.start();
      _stepSubscription?.cancel();
      _stepSubscription = executor!.stepStream.listen((step) {
        if (!mounted) return;
        setState(() {
          stepCount = step.stepCount;
          nodesExplored = step.explored.length;
          exploredStates = step.explored.map((s) => s.toString()).toSet();

          if (step.path.isNotEmpty) {
            currentPath = step.path;
            currentState = step.path.last;
          } else if (step.explored.isNotEmpty) {
            currentState = step.explored.last;
          }

          if (step.isGoalReached) {
            isSolved = true;
            isSolving = false;
          }
        });
      });
    }

    executor?.stepOnce();
  }

  Future<void> _autoSolve() async {
    // Run through entire solve without manual step control
    if (isSolving) return;

    _solvePuzzle();
    // Continue automatically - the stream listener will handle updates
  }

  void _handleTileTap(int index) {
    if (isSolving) return;

    final emptyIndex = currentState.tiles.indexOf(0);
    final emptyRow = emptyIndex ~/ 3;
    final emptyCol = emptyIndex % 3;

    final tapRow = index ~/ 3;
    final tapCol = index % 3;

    final isAdjacent = (emptyRow == tapRow && (emptyCol - tapCol).abs() == 1) ||
        (emptyCol == tapCol && (emptyRow - tapRow).abs() == 1);

    if (isAdjacent) {
      setState(() {
        final newTiles = List<int>.from(currentState.tiles);
        newTiles[emptyIndex] = newTiles[index];
        newTiles[index] = 0;
        currentState = PuzzleState(newTiles);
        
        // Update the problem for AI starting point
        problem = EightPuzzleProblem(initialState: currentState);
        
        // Reset tracking since this is a manual move
        stepCount = 0;
        nodesExplored = 0;
        currentPath = [currentState];
        exploredStates.clear();
        isSolved = problem.isGoal(currentState);
        _statusMessage = isSolved ? 'Goal reached manually!' : 'Playing randomly';
      });
    }
  }

  void _showAISolveMenu() {
    showModalBottomSheet(
      context: context,
      backgroundColor: cardColor,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setModalState) {
            return Padding(
              padding: EdgeInsets.only(
                bottom: MediaQuery.of(context).viewInsets.bottom,
              ),
              child: Container(
                padding: const EdgeInsets.all(16.0),
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
              final isSelected = selectedAlgorithm == algo;
              return Padding(
                padding: const EdgeInsets.only(right: 8),
                child: FilterChip(
                  label: Text(algo),
                  selected: isSelected,
                  onSelected: (selected) {
                    if (!isSolving) {
                      setState(() {
                        selectedAlgorithm = algo;
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
          'Execution Speed: ${executionSpeed.toStringAsFixed(1)}x',
          style: Theme.of(context).textTheme.titleSmall?.copyWith(color: Colors.white),
        ),
        const SizedBox(height: 8),
        Slider(
          value: executionSpeed,
          min: 0.1,
          max: 5.0,
          onChanged: isSolving
              ? null
              : (value) {
                  setState(() {
                    executionSpeed = value;
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
        _buildStatCard('Explored', '$nodesExplored'),
        _buildStatCard(
          'Status',
          isSolved ? 'Solved!' : isSolving ? 'Solving...' : 'Idle',
        ),
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
                  _solvePuzzle().then((_) => setModalState(() {}));
                },
          icon: const Icon(Icons.play_arrow),
          label: const Text('Solve'),
          style: ElevatedButton.styleFrom(
            backgroundColor: accentColor,
            foregroundColor: Colors.black,
          ),
        ),
        ElevatedButton.icon(
          onPressed: stepCount > 0
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
          onPressed: stepCount > 0
              ? () {
                  _step();
                  setModalState(() {});
                }
              : null,
          icon: const Icon(Icons.skip_next),
          label: const Text('Step'),
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.cyan,
            foregroundColor: Colors.black,
          ),
        ),
        ElevatedButton.icon(
          onPressed: () {
            _resetPuzzle();
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

  @override
  void dispose() {
    _stepSubscription?.cancel();
    executor?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: backgroundColor,
      appBar: AppBar(
        backgroundColor: cardColor,
        title: const Text('8-Puzzle Visualizer'),
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            tooltip: 'Reset Board',
            onPressed: isSolving ? null : _reset,
          ),
        ],
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Notice for manual play
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: exploringColor.withOpacity(0.1),
                  border: Border.all(color: exploringColor),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Text(
                  'Tap on tiles adjacent to the empty space to play manually, or use the AI Solver.',
                  style: TextStyle(color: Colors.white, fontSize: 13),
                  textAlign: TextAlign.center,
                ),
              ),
              const SizedBox(height: 16),
              // Puzzle Visualization
              _buildPuzzleVisualization(),
              const SizedBox(height: 24),
              // Solution Path Info
              if (isSolved) _buildSolutionInfo(),
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

  Widget _buildPuzzleVisualization() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: cardColor,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Current State',
            style: Theme.of(
              context,
            ).textTheme.titleMedium?.copyWith(color: Colors.white),
          ),
          const SizedBox(height: 12),
          _buildPuzzleGrid(currentState),
          const SizedBox(height: 16),
          Text(
            'Goal State',
            style: Theme.of(
              context,
            ).textTheme.titleMedium?.copyWith(color: Colors.white),
          ),
          const SizedBox(height: 12),
          _buildPuzzleGrid(problem.goalState),
        ],
      ),
    );
  }

  Widget _buildPuzzleGrid(PuzzleState state) {
    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 3,
        childAspectRatio: 1,
        mainAxisSpacing: 8,
        crossAxisSpacing: 8,
      ),
      itemCount: 9,
      itemBuilder: (context, index) {
        final tile = state.tiles[index];
        final isExplored = exploredStates.contains(state.toString());
        final isPath = currentPath.contains(state);
        final isEmpty = tile == 0;

        return GestureDetector(
          onTap: () => _handleTileTap(index),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 300),
            decoration: BoxDecoration(
              color: isEmpty
                  ? backgroundColor
                  : isPath
                  ? successColor
                  : isExplored
                  ? exploringColor
                  : Colors.grey[800],
              borderRadius: BorderRadius.circular(8),
              border: Border.all(
                color: isEmpty ? Colors.transparent : accentColor,
                width: isEmpty ? 0 : 2,
              ),
            ),
            child: isEmpty
                ? const SizedBox()
                : Center(
                    child: Text(
                      '$tile',
                      style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                        color: isEmpty ? Colors.transparent : Colors.white,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
          ),
        );
      },
    );
  }



  Widget _buildStatCard(String label, String value) {
    return Expanded(
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 4),
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: backgroundColor,
          borderRadius: BorderRadius.circular(8),
        ),
        child: Column(
          children: [
            Text(
              label,
              style: Theme.of(
                context,
              ).textTheme.labelSmall?.copyWith(color: Colors.grey[400]),
            ),
            const SizedBox(height: 4),
            Text(
              value,
              style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                color: accentColor,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSolutionInfo() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: cardColor.withOpacity(0.7),
        border: Border.all(color: successColor, width: 2),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.check_circle, color: successColor),
              const SizedBox(width: 8),
              Text(
                'Solution Found!',
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  color: successColor,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            'Path Length: ${currentPath.length} moves',
            style: Theme.of(
              context,
            ).textTheme.bodySmall?.copyWith(color: Colors.grey[300]),
          ),
          const SizedBox(height: 4),
          Text(
            'Nodes Explored: $nodesExplored',
            style: Theme.of(
              context,
            ).textTheme.bodySmall?.copyWith(color: Colors.grey[300]),
          ),
        ],
      ),
    );
  }
}
