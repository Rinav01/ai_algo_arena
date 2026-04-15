// Generic algorithm step that works with any state type
class AlgorithmStep<State> {
  final List<State> explored;
  final List<State> path;
  final int stepCount;
  final String? message;
  final DateTime timestamp;
  final bool isGoalReached;

  AlgorithmStep({
    required this.explored,
    required this.path,
    required this.stepCount,
    this.message,
    DateTime? timestamp,
    this.isGoalReached = false,
  }) : timestamp = timestamp ?? DateTime.now();

  AlgorithmStep<State> copyWith({
    List<State>? explored,
    List<State>? path,
    int? stepCount,
    String? message,
    DateTime? timestamp,
    bool? isGoalReached,
  }) {
    return AlgorithmStep<State>(
      explored: explored ?? this.explored,
      path: path ?? this.path,
      stepCount: stepCount ?? this.stepCount,
      message: message ?? this.message,
      timestamp: timestamp ?? this.timestamp,
      isGoalReached: isGoalReached ?? this.isGoalReached,
    );
  }
}

// Generic algorithm result
class AlgorithmResult<State> {
  final List<State> path;
  final List<State> explored;
  final int steps;
  final double cost;
  final Duration executionTime;
  final String algorithmName;
  final bool succeeded;

  AlgorithmResult({
    required this.path,
    required this.explored,
    required this.steps,
    required this.cost,
    required this.executionTime,
    required this.algorithmName,
    this.succeeded = true,
  });
}

// Abstract problem definition - can be implemented for any domain
abstract class Problem<State> {
  /// Initial state of the problem
  State get initialState;

  /// Goal state of the problem
  State get goalState;

  /// Check if a state is the goal
  bool isGoal(State state);

  /// Get all valid neighbor states
  List<State> getNeighbors(State state);

  /// Heuristic function for informed search (return 0 for uninformed)
  double heuristic(State state) => 0.0;

  /// Cost to move from one state to another (default: 1)
  double moveCost(State from, State to) => 1.0;

  /// Check if a state is valid/walkable
  bool isValid(State state) => true;

  /// Get a string representation for debugging
  String stateToString(State state);
}

// Abstract search algorithm - works with any problem
abstract class SearchAlgorithm<State> {
  /// Solve the problem and emit steps as they happen
  Stream<AlgorithmStep<State>> solve(Problem<State> problem);

  /// Name of the algorithm
  String get name;

  /// Category/type of algorithm
  String get category;
}
