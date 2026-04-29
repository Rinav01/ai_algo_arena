// Generic algorithm step that works with any state type
class AlgorithmStep<State> {
  /// The states added to the explored set in this specific step
  final List<State> newlyExplored;

  /// The current state being evaluated
  final State? currentState;

  /// The best path found so far
  final List<State> path;
  final int stepCount;
  final String? message;
  final String? reason;
  final Map<String, dynamic>? meta;
  final DateTime timestamp;
  final bool isGoalReached;
  final int? frontierSize;

  AlgorithmStep({
    required this.newlyExplored,
    this.currentState,
    required this.path,
    required this.stepCount,
    this.message,
    this.reason,
    this.meta,
    DateTime? timestamp,
    this.isGoalReached = false,
    this.frontierSize,
  }) : timestamp = timestamp ?? DateTime.now();

  AlgorithmStep<State> copyWith({
    List<State>? newlyExplored,
    State? currentState,
    List<State>? path,
    int? stepCount,
    String? message,
    String? reason,
    Map<String, dynamic>? meta,
    DateTime? timestamp,
    bool? isGoalReached,
    int? frontierSize,
  }) {
    return AlgorithmStep<State>(
      newlyExplored: newlyExplored ?? this.newlyExplored,
      currentState: currentState ?? this.currentState,
      path: path ?? this.path,
      stepCount: stepCount ?? this.stepCount,
      message: message ?? this.message,
      reason: reason ?? this.reason,
      meta: meta ?? this.meta,
      timestamp: timestamp ?? this.timestamp,
      isGoalReached: isGoalReached ?? this.isGoalReached,
      frontierSize: frontierSize ?? this.frontierSize,
    );
  }

  Map<String, dynamic> toJson(dynamic Function(State) stateSerializer) => {
    'newlyExplored': newlyExplored.map((s) => stateSerializer(s)).toList(),
    'currentState': currentState != null ? stateSerializer(currentState as State) : null,
    'path': path.map((s) => stateSerializer(s)).toList(),
    'stepCount': stepCount,
    'message': message,
    'reason': reason,
    'meta': meta,
    'timestamp': timestamp.toIso8601String(),
    'isGoalReached': isGoalReached,
    'frontierSize': frontierSize,
  };

  factory AlgorithmStep.fromJson(Map<String, dynamic> json, State Function(dynamic) stateDeserializer) {
    return AlgorithmStep<State>(
      newlyExplored: (json['newlyExplored'] as List).map((s) => stateDeserializer(s)).toList(),
      currentState: json['currentState'] != null ? stateDeserializer(json['currentState']) : null,
      path: (json['path'] as List).map((s) => stateDeserializer(s)).toList(),
      stepCount: json['stepCount'],
      message: json['message'],
      reason: json['reason'],
      meta: json['meta'] != null ? Map<String, dynamic>.from(json['meta']) : null,
      timestamp: DateTime.parse(json['timestamp']),
      isGoalReached: json['isGoalReached'] ?? false,
      frontierSize: json['frontierSize'],
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
    this.maxFrontierSize,
  });

  final int? maxFrontierSize;
}

// Abstract problem definition - can be implemented for any domain
abstract class Problem<State> {
  /// Initial state of the problem
  State get initialState;

  /// Goal state of the problem
  State get goalState;

  /// Get a snapshot for background processing
  Map<String, dynamic> toSnapshot();

  /// Check if a state is the goal
  bool isGoal(State state);

  /// Get successors for a state
  List<State> getNeighbors(State state);

  /// Check if a state is valid (e.g. not a wall)
  bool isValid(State state);

  /// Heuristic function (distance to goal)
  double heuristic(State state);

  /// Cost to move from one state to another
  double moveCost(State from, State to);

  /// String representation of a state for debugging
  String stateToString(State state);
}

// Abstract search algorithm - works with any problem
abstract class SearchAlgorithm<State> {
  /// Solve the problem synchronously and emit steps as Iterable
  Iterable<AlgorithmStep<State>> solve(Problem<State> problem);

  /// Name of the algorithm
  String get name;

  /// Category/type of algorithm
  String get category;
}
