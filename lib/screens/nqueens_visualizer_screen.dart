import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'dart:async';
import '../core/nqueens_problem.dart';
import '../core/search_algorithms.dart';
import '../services/algorithm_executor.dart';
import '../core/problem_definition.dart';

class NQueensVisualizerScreen extends StatefulWidget {
  const NQueensVisualizerScreen({Key? key}) : super(key: key);

  @override
  State<NQueensVisualizerScreen> createState() =>
      _NQueensVisualizerScreenState();
}

class _NQueensVisualizerScreenState extends State<NQueensVisualizerScreen>
    with SingleTickerProviderStateMixin {
  late NQueensProblem problem;
  late QueensState currentState;
  AlgorithmExecutor<QueensState>? executor;
  StreamSubscription<AlgorithmStep<QueensState>>? _stepSubscription;
  late AnimationController _animationController;

  List<QueensState> currentPath = [];
  Set<String> exploredStates = {};
  int stepCount = 0;
  int nodesExplored = 0;
  bool isSolving = false;
  bool isSolved = false;
  String selectedAlgorithm = 'A*';
  int boardSize = 8;
  double executionSpeed = 1.0;
  QueensState? currentNode;

  final Color backgroundColor = const Color(0xFF07131F);
  final Color cardColor = const Color(0xFF0E2233);
  final Color accentColor = const Color(0xFFFFA500);
  final Color successColor = const Color(0xFF4CAF50);
  final Color exploringColor = const Color(0xFF2196F3);
  final Color conflictColor = const Color(0xFFFF5252);

  final List<String> algorithms = ['BFS', 'DFS', 'A*'];

  Duration get _stepDelay {
    final milliseconds = (220 / executionSpeed).round().clamp(10, 2200);
    return Duration(milliseconds: milliseconds);
  }

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );
    _initializeProblem();
  }

  void _initializeProblem() {
    problem = NQueensProblem(n: boardSize);
    currentState = problem.initialState;
    currentPath = [currentState];
    exploredStates.clear();
  }

  Future<void> _solvePuzzle() async {
    if (isSolving) return;

    _initializeProblem();

    setState(() {
      isSolving = true;
      isSolved = false;
      exploredStates.clear();
      currentPath = [problem.initialState];
      stepCount = 0;
      nodesExplored = 0;
      currentNode = null;
      _animationController.forward();
    });

    late SearchAlgorithm<QueensState> algorithm;
    switch (selectedAlgorithm) {
      case 'BFS':
        algorithm = BFSAlgorithm<QueensState>(stepDelay: _stepDelay);
        break;
      case 'DFS':
        algorithm = DFSAlgorithm<QueensState>(stepDelay: _stepDelay);
        break;
      case 'A*':
        algorithm = AStarAlgorithm<QueensState>(stepDelay: _stepDelay);
        break;
    }

    executor = AlgorithmExecutor<QueensState>(
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
            currentNode = step.explored.isNotEmpty ? step.explored.last : null;

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
        },
        onError: (error) {
          if (mounted) {
            ScaffoldMessenger.of(
              context,
            ).showSnackBar(SnackBar(content: Text('Error: $error')));
            setState(() {
              isSolving = false;
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
        setState(() {
          isSolving = false;
        });
      }
    }
  }

  Future<void> _autoSolve() async {
    await _solvePuzzle();
  }

  void _pauseResume() {
    if (isSolving) {
      executor?.pause();
      setState(() {
        isSolving = false;
      });
    } else if (stepCount > 0) {
      executor?.resume();
      setState(() {
        isSolving = true;
      });
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
    _animationController.reset();
    setState(() {
      _initializeProblem();
      isSolving = false;
      isSolved = false;
      stepCount = 0;
      nodesExplored = 0;
      currentNode = null;
    });
  }

  void _stepOnce() {
    if (isSolving) return;

    if (executor == null) {
      late SearchAlgorithm<QueensState> algorithm;
      switch (selectedAlgorithm) {
        case 'BFS':
          algorithm = BFSAlgorithm<QueensState>(stepDelay: _stepDelay);
          break;
        case 'DFS':
          algorithm = DFSAlgorithm<QueensState>(stepDelay: _stepDelay);
          break;
        case 'A*':
          algorithm = AStarAlgorithm<QueensState>(stepDelay: _stepDelay);
          break;
      }

      executor = AlgorithmExecutor<QueensState>(
        algorithm: algorithm,
        problem: problem,
      );
      executor!.start();
      _stepSubscription = executor!.stepStream.listen((step) {
        if (!mounted) return;
        setState(() {
          stepCount = step.stepCount;
          nodesExplored = step.explored.length;
          exploredStates = step.explored.map((s) => s.toString()).toSet();
          currentNode = step.explored.isNotEmpty ? step.explored.last : null;

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

  void _handleSquareTap(int row, int col) {
    if (isSolving) return;

    setState(() {
      final newPlacement = List<int>.from(currentState.placement);
      if (newPlacement[row] == col) {
        newPlacement[row] = -1; // remove
      } else {
        newPlacement[row] = col; // place
        
        // Vibrate if the placement violates safe rules
        if (!problem.isSafe(QueensState(placement: newPlacement, n: boardSize), row, col)) {
          HapticFeedback.heavyImpact();
        }
      }

      currentState = QueensState(placement: newPlacement, n: boardSize);
      problem = NQueensProblem(n: boardSize, initialPlacement: newPlacement);
      
      stepCount = 0;
      nodesExplored = 0;
      currentPath = [currentState];
      exploredStates.clear();
      isSolved = problem.isGoal(currentState);
    });
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
                  _stepOnce();
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
            _reset();
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
    if (isSolving) {
      executor?.stop();
    }
    _stepSubscription?.cancel();
    executor?.dispose();
    _animationController.dispose();
    super.dispose();
  }

  Color _getSquareColor(int row, int col) {
    final hasQueen =
        currentState.placement.length > row &&
        currentState.placement[row] == col;

    if (hasQueen) {
      if (!problem.isSafe(currentState, row, col)) {
        return Colors.red.withOpacity(0.8);
      }
      return successColor.withOpacity(0.8);
    }

    // Checkerboard pattern
    if ((row + col) % 2 == 0) {
      return Colors.white24;
    }
    return Colors.black26;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: backgroundColor,
      appBar: AppBar(
        backgroundColor: cardColor,
        title: const Text('N-Queens Visualizer'),
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
                  'Tap on grid squares to place or remove queens manually, or use the AI Solver.',
                  style: TextStyle(color: Colors.white, fontSize: 13),
                  textAlign: TextAlign.center,
                ),
              ),
              const SizedBox(height: 16),
              // Board Size Selector
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: cardColor,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Board Size: $boardSize',
                      style: TextStyle(color: Colors.grey[400], fontSize: 12),
                    ),
                    const SizedBox(height: 8),
                    Slider(
                      value: boardSize.toDouble(),
                      min: 4,
                      max: 10,
                      divisions: 6,
                      onChanged: isSolving
                          ? null
                          : (value) {
                              setState(() {
                                boardSize = value.toInt();
                                _initializeProblem();
                              });
                            },
                      activeColor: accentColor,
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),

              // Chessboard
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: cardColor,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: accentColor.withOpacity(0.3)),
                ),
                child: Column(
                  children: [
                    Text(
                      'Current State',
                      style: Theme.of(
                        context,
                      ).textTheme.labelSmall?.copyWith(color: Colors.grey[400]),
                    ),
                    const SizedBox(height: 12),
                    GridView.builder(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                        crossAxisCount: boardSize,
                        childAspectRatio: 1,
                        mainAxisSpacing: 1,
                        crossAxisSpacing: 1,
                      ),
                      itemCount: boardSize * boardSize,
                      itemBuilder: (context, index) {
                        final row = index ~/ boardSize;
                        final col = index % boardSize;

                        return GestureDetector(
                          onTap: () => _handleSquareTap(row, col),
                          child: AnimatedContainer(
                            duration: const Duration(milliseconds: 300),
                            decoration: BoxDecoration(
                              color: _getSquareColor(row, col),
                              border: Border.all(
                                color: Colors.grey[800]!.withOpacity(0.5),
                                width: 0.5,
                              ),
                            ),
                            child: Center(child: _buildSquareContent(row, col)),
                          ),
                        );
                      },
                    ),
                    const SizedBox(height: 12),
                    Text(
                      'Queens Placed: ${currentState.placement.where((p) => p != -1).length}/$boardSize',
                      style: TextStyle(
                        color: successColor,
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ),


              if (isSolved)
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: successColor.withOpacity(0.15),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: successColor, width: 2),
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
                            style: TextStyle(
                              color: successColor,
                              fontWeight: FontWeight.bold,
                              fontSize: 14,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      Text(
                        'Steps: $stepCount | Nodes Explored: $nodesExplored',
                        style: TextStyle(color: Colors.grey[300], fontSize: 12),
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

  Widget _buildSquareContent(int row, int col) {
    final hasQueen =
        currentState.placement.length > row &&
        currentState.placement[row] == col;

    if (hasQueen) {
      return Text(
        '♕',
        style: TextStyle(
          fontSize: 32,
          color: successColor,
          shadows: [
            Shadow(color: successColor.withOpacity(0.5), blurRadius: 8),
          ],
        ),
      );
    }

    return const SizedBox.shrink();
  }

  Widget _buildStatCard(String label, String value) {
    return Container(
      padding: const EdgeInsets.all(8),
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
              fontSize: 9,
              fontWeight: FontWeight.bold,
              color: Colors.grey[400],
            ),
          ),
          const SizedBox(height: 2),
          Text(
            value,
            style: const TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
        ],
      ),
    );
  }
}
