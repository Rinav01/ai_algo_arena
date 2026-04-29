import 'dart:collection';
import 'package:collection/collection.dart';
import 'package:algo_arena/core/problem_definition.dart';

/// Registry to map algorithm IDs to their concrete implementations.
class AlgorithmRegistry {
  static SearchAlgorithm<State> create<State>(String id) {
    switch (id) {
      case 'BFS':
        return BFSAlgorithm<State>();
      case 'DFS':
        return DFSAlgorithm<State>();
      case 'A*':
        return AStarAlgorithm<State>();
      case 'Dijkstra':
        return DijkstraAlgorithm<State>();
      case 'Greedy':
        return GreedyBestFirstAlgorithm<State>();
      default:
        return AStarAlgorithm<State>();
    }
  }

  static List<String> get pathfindingIds => ['BFS', 'DFS', 'Dijkstra', 'Greedy', 'A*'];
  static List<String> get puzzleIds => ['BFS', 'A*', 'Greedy'];
  static List<String> get nqueensIds => ['BFS', 'DFS'];
}

/// Generic BFS algorithm that works with any Problem
class BFSAlgorithm<State> extends SearchAlgorithm<State> {
  BFSAlgorithm();

  @override
  String get name => 'Breadth-First Search';

  @override
  String get category => 'Uninformed Search';

  @override
  Iterable<AlgorithmStep<State>> solve(Problem<State> problem) sync* {
    final visited = <State>{};
    final queue = Queue<State>();
    final parent = <State, State>{};
    final explored = <State>[];

    final startState = problem.initialState;
    queue.add(startState);
    visited.add(startState);

    int stepCount = 0;

    while (queue.isNotEmpty) {
      final current = queue.removeFirst();
      explored.add(current);
      stepCount++;

      // Check if goal is reached
      if (problem.isGoal(current)) {
        final path = _reconstructPath(parent, current, startState);
        yield AlgorithmStep<State>(
          newlyExplored: [current],
          currentState: current,
          path: path,
          stepCount: stepCount,
          message: 'Goal found!',
          reason: 'This node is the goal state.',
          isGoalReached: true,
        );
        return;
      }

      // Emit current state with partial path
      final path = _reconstructPath(parent, current, startState);
      final parentNode = parent[current];
      final depth = path.length - 1;
      yield AlgorithmStep<State>(
        newlyExplored: [current],
        currentState: current,
        path: path,
        stepCount: stepCount,
        message: 'Exploring ${problem.stateToString(current)}',
        reason: 'BFS is exploring Layer $depth. This node was discovered from ${parentNode != null ? problem.stateToString(parentNode) : 'the start'}. It will check all nodes at this depth before moving further.',
        isGoalReached: false,
        frontierSize: queue.length,
        meta: {
          'layer': depth,
          'isOptimal': true, // BFS is optimal for unweighted graphs
          'searchType': 'Layer-by-Layer',
        },
      );

      // Explore neighbors
      final neighbors = problem.getNeighbors(current);
      for (final neighbor in neighbors) {
        if (!visited.contains(neighbor)) {
          visited.add(neighbor);
          queue.add(neighbor);
          parent[neighbor] = current;
        }
      }
    }

    // No path found
    yield AlgorithmStep<State>(
      newlyExplored: [],
      path: [],
      stepCount: stepCount,
      message: 'No path found',
      isGoalReached: false,
    );
  }

  List<State> _reconstructPath(
    Map<State, State> parent,
    State goal,
    State start,
  ) {
    final path = <State>[goal];
    var current = goal;

    while (current != start && parent.containsKey(current)) {
      current = parent[current] as State;
      path.add(current);
    }

    return path.reversed.toList();
  }
}

/// Generic DFS algorithm that works with any Problem
class DFSAlgorithm<State> extends SearchAlgorithm<State> {
  DFSAlgorithm();

  @override
  String get name => 'Depth-First Search';

  @override
  String get category => 'Uninformed Search';

  @override
  Iterable<AlgorithmStep<State>> solve(Problem<State> problem) sync* {
    final visited = <State>{};
    final stack = <State>[problem.initialState];
    final parent = <State, State>{};
    final explored = <State>[];

    int stepCount = 0;

    while (stack.isNotEmpty) {
      final current = stack.removeLast();

      if (visited.contains(current)) continue;

      visited.add(current);
      explored.add(current);
      stepCount++;

      // Check if goal is reached
      if (problem.isGoal(current)) {
        final path = _reconstructPath(parent, current, problem.initialState);
        yield AlgorithmStep<State>(
          newlyExplored: [current],
          currentState: current,
          path: path,
          stepCount: stepCount,
          message: 'Goal found!',
          reason: 'This node is the goal state.',
          isGoalReached: true,
        );
        return;
      }

      // Emit current state with partial path
      final path = _reconstructPath(parent, current, problem.initialState);
      final parentNode = parent[current];
      final depth = path.length - 1;
      yield AlgorithmStep<State>(
        newlyExplored: [current],
        currentState: current,
        path: path,
        stepCount: stepCount,
        message: 'Exploring ${problem.stateToString(current)}',
        reason: 'DFS is diving deeper into the graph (Depth: $depth). This node was the most recently discovered neighbor of ${parentNode != null ? problem.stateToString(parentNode) : 'the start'}. It prioritizes depth over finding the shortest path.',
        isGoalReached: false,
        meta: {
          'depth': depth,
          'isOptimal': false, // DFS is almost never optimal
          'searchType': 'Deep-Dive',
        },
      );

      // Explore neighbors
      final neighbors = problem.getNeighbors(current);
      for (final neighbor in neighbors.reversed) {
        if (!visited.contains(neighbor)) {
          stack.add(neighbor);
          parent[neighbor] = current;
        }
      }
    }

    // No path found
    yield AlgorithmStep<State>(
      newlyExplored: [],
      path: [],
      stepCount: stepCount,
      message: 'No path found',
      isGoalReached: false,
    );
  }

  List<State> _reconstructPath(
    Map<State, State> parent,
    State goal,
    State start,
  ) {
    final path = <State>[goal];
    var current = goal;

    while (current != start && parent.containsKey(current)) {
      current = parent[current] as State;
      path.add(current);
    }

    return path.reversed.toList();
  }
}

/// Generic A* algorithm that works with any Problem
class AStarAlgorithm<State> extends SearchAlgorithm<State> {
  AStarAlgorithm();

  @override
  String get name => 'A* Search';

  @override
  String get category => 'Informed Search';

  @override
  Iterable<AlgorithmStep<State>> solve(Problem<State> problem) sync* {
    final visited = <State>{};
    final gScore = <State, double>{};
    final fScore = <State, double>{};
    final parent = <State, State>{};
    final explored = <State>[];

    final startState = problem.initialState;
    gScore[startState] = 0;
    fScore[startState] = problem.heuristic(startState);

    final openQueue = PriorityQueue<State>((a, b) {
      final fa = fScore[a] ?? double.infinity;
      final fb = fScore[b] ?? double.infinity;
      return fa.compareTo(fb);
    });

    openQueue.add(startState);
    final inOpen = <State>{startState};

    int stepCount = 0;

    while (openQueue.isNotEmpty) {
      final current = openQueue.removeFirst();
      inOpen.remove(current);

      if (visited.contains(current)) continue;

      visited.add(current);
      explored.add(current);
      stepCount++;

      if (problem.isGoal(current)) {
        final path = _reconstructPath(parent, current, startState);
        yield AlgorithmStep<State>(
          newlyExplored: [current],
          currentState: current,
          path: path,
          stepCount: stepCount,
          message:
              'Goal found with f=${(fScore[current] ?? 0).toStringAsFixed(1)}!',
          reason: 'Goal reached with the lowest possible cost path.',
          meta: {
            'g': gScore[current],
            'h': problem.heuristic(current),
            'f': fScore[current],
            'isOptimal': true,
          },
          isGoalReached: true,
        );
        return;
      }

      // Emit current state with partial path
      final path = _reconstructPath(parent, current, startState);
      final parentNode = parent[current];
      final g = gScore[current] ?? 0.0;
      final h = problem.heuristic(current);
      final f = fScore[current] ?? 0.0;
      
      // Upgrade: Capture Frontier Alternatives
      final bestPossible = f; // Since it's a priority queue, current IS the best
      
      // Find alternatives from the open set
      final alternatives = inOpen
          .where((s) => s != current)
          .map((s) => {
                'state': problem.stateToString(s),
                'f': fScore[s] ?? 0.0,
                'diff': (fScore[s] ?? 0.0) - f,
              })
          .toList();
      
      // Sort alternatives by f-score and take top 3
      alternatives.sort((a, b) => (a['f'] as num).toDouble().compareTo((b['f'] as num).toDouble()));
      final topAlternatives = alternatives.take(3).toList();

      yield AlgorithmStep<State>(
        newlyExplored: [current],
        currentState: current,
        path: path,
        stepCount: stepCount,
        message:
            'Evaluating ${problem.stateToString(current)} (f=${f.toStringAsFixed(1)})',
        reason: 'A* selected this node because its total cost f = ${f.toStringAsFixed(1)} is the current minimum. It was reached from ${parentNode != null ? problem.stateToString(parentNode) : 'the start'} (g = ${g.toStringAsFixed(1)}) and is estimated to be ${h.toStringAsFixed(1)} units away from the goal (h).',
        meta: {
          'g': g,
          'h': h,
          'f': f,
          'bestPossible': bestPossible,
          'isOptimal': true, // Priority queue guarantees this is the minimum f in frontier
          'alternatives': topAlternatives,
        },
        isGoalReached: false,
        frontierSize: openQueue.length,
      );

      // Check all neighbors
      final neighbors = problem.getNeighbors(current);
      for (final neighbor in neighbors) {
        if (visited.contains(neighbor)) continue;

        final tentativeGScore =
            (gScore[current] ?? 0) + problem.moveCost(current, neighbor);

        if ((gScore[neighbor] ?? double.infinity) > tentativeGScore) {
          parent[neighbor] = current;
          gScore[neighbor] = tentativeGScore;
          fScore[neighbor] = tentativeGScore + problem.heuristic(neighbor);

          // Lazy update: Add the node again. The priority queue will
          // pop the cheapest instance first, and subsequent duplicate pops
          // will be ignored by the `visited.contains(current)` check above.
          openQueue.add(neighbor);
          inOpen.add(neighbor);
        }
      }
    }

    // No path found
    yield AlgorithmStep<State>(
      newlyExplored: [],
      path: [],
      stepCount: stepCount,
      message: 'No path found',
      isGoalReached: false,
    );
  }

  List<State> _reconstructPath(
    Map<State, State> parent,
    State goal,
    State start,
  ) {
    final path = <State>[goal];
    var current = goal;

    while (current != start && parent.containsKey(current)) {
      current = parent[current] as State;
      path.add(current);
    }

    return path.reversed.toList();
  }
}

/// Dijkstra's algorithm - weighted version of BFS
class DijkstraAlgorithm<State> extends SearchAlgorithm<State> {
  DijkstraAlgorithm();

  @override
  String get name => 'Dijkstra\'s Algorithm';

  @override
  String get category => 'Weighted Search';

  @override
  Iterable<AlgorithmStep<State>> solve(Problem<State> problem) sync* {
    final distances = <State, double>{};
    final visited = <State>{};
    final parent = <State, State>{};
    final explored = <State>[];

    final startState = problem.initialState;
    distances[startState] = 0;

    final openQueue = PriorityQueue<State>((a, b) {
      final da = distances[a] ?? double.infinity;
      final db = distances[b] ?? double.infinity;
      return da.compareTo(db);
    });

    openQueue.add(startState);
    final inOpen = <State>{startState};

    int stepCount = 0;

    while (openQueue.isNotEmpty) {
      final current = openQueue.removeFirst();
      inOpen.remove(current);

      if (visited.contains(current)) continue;

      final minDistance = distances[current] ?? double.infinity;

      visited.add(current);
      explored.add(current);
      stepCount++;

      if (problem.isGoal(current)) {
        final path = _reconstructPath(parent, current, startState);
        yield AlgorithmStep<State>(
          newlyExplored: [current],
          currentState: current,
          path: path,
          stepCount: stepCount,
          message:
              'Goal found with distance=${minDistance.toStringAsFixed(1)}!',
          reason: 'Shortest path found to the goal.',
          meta: {
            'distance': minDistance,
            'isOptimal': true,
          },
          isGoalReached: true,
        );
        return;
      }

      // Emit current state with partial path
      final path = _reconstructPath(parent, current, startState);
      final parentNode = parent[current];

      // Upgrade: Capture Frontier Alternatives
      final bestPossible = minDistance;
      final alternatives = inOpen
          .where((s) => s != current)
          .map((s) => {
                'state': problem.stateToString(s),
                'dist': distances[s] ?? 0.0,
                'diff': (distances[s] ?? 0.0) - minDistance,
              })
          .toList();
      alternatives.sort((a, b) => (a['dist'] as num).toDouble().compareTo((b['dist'] as num).toDouble()));
      final topAlternatives = alternatives.take(3).toList();

      yield AlgorithmStep<State>(
        newlyExplored: [current],
        currentState: current,
        path: path,
        stepCount: stepCount,
        message:
            'Visiting ${problem.stateToString(current)} (distance=${minDistance.toStringAsFixed(1)})',
        reason: 'This node has the absolute shortest path from the start (dist = ${minDistance.toStringAsFixed(1)}) among all frontier nodes. It was reached via ${parentNode != null ? problem.stateToString(parentNode) : 'the start'}.',
        meta: {
          'distance': minDistance,
          'bestPossible': bestPossible,
          'isOptimal': true,
          'alternatives': topAlternatives,
        },
        isGoalReached: false,
        frontierSize: openQueue.length,
      );

      final neighbors = problem.getNeighbors(current);
      for (final neighbor in neighbors) {
        if (visited.contains(neighbor)) continue;

        final newDistance =
            (distances[current] ?? 0) + problem.moveCost(current, neighbor);
        if (!distances.containsKey(neighbor) ||
            newDistance < distances[neighbor]!) {
          distances[neighbor] = newDistance;
          parent[neighbor] = current;

          // Lazy update pattern for priority queue
          openQueue.add(neighbor);
          inOpen.add(neighbor);
        }
      }
    }

    // No path found
    // No path found
    yield AlgorithmStep<State>(
      newlyExplored: [],
      path: [],
      stepCount: stepCount,
      message: 'No path found',
      isGoalReached: false,
    );
  }
}

List<State> _reconstructPath<State>(
  Map<State, State> parent,
  State goal,
  State start,
) {
  final path = <State>[goal];
  var current = goal;

  while (current != start && parent.containsKey(current)) {
    current = parent[current] as State;
    path.add(current);
  }

  return path.reversed.toList();
}

class StateNode<State> {
  final State state;
  final double f;
  final double g;

  StateNode({required this.state, required this.f, required this.g});
}

/// Greedy Best-First Search (GBFS)
/// Prioritizes speed by only considering heuristic estimates,
/// though it doesn't guarantee the shortest path.
class GreedyBestFirstAlgorithm<State> extends SearchAlgorithm<State> {
  @override
  String get name => 'Greedy Best-First Search';

  @override
  String get category => 'Informed Search';

  @override
  Iterable<AlgorithmStep<State>> solve(Problem<State> problem) sync* {
    final startState = problem.initialState;
    final parent = <State, State>{};
    final visited = <State>{};
    final List<State> explored = [];
    int stepCount = 0;

    final openSet = PriorityQueue<StateNode<State>>(
      (a, b) => a.f.compareTo(b.f),
    );
    final Map<State, double> hScores = {};

    openSet.add(
      StateNode<State>(
        state: startState,
        f: problem.heuristic(startState),
        g: 0,
      ),
    );
    hScores[startState] = problem.heuristic(startState);
    final inOpen = <State>{startState};

    while (openSet.isNotEmpty) {
      final StateNode<State> currentNode = openSet.removeFirst();
      final current = currentNode.state;
      inOpen.remove(current);

      if (visited.contains(current)) continue;

      visited.add(current);
      explored.add(current);
      stepCount++;

      if (problem.isGoal(current)) {
        final path = _reconstructPath(parent, current, startState);
        yield AlgorithmStep<State>(
          newlyExplored: [current],
          currentState: current,
          path: path,
          stepCount: stepCount,
          message: 'Goal found using Greedy BFS!',
          reason: 'Goal found by following heuristic estimates.',
          meta: {
            'h': currentNode.f,
            'isOptimal': true,
          },
          isGoalReached: true,
        );
        return;
      }

      // Emit current state with partial path
      final path = _reconstructPath(parent, current, startState);
      final parentNode = parent[current];
      final h = currentNode.f;

      // Upgrade: Capture Frontier Alternatives
      final alternatives = inOpen
          .map((s) => {
                'state': problem.stateToString(s),
                'h': hScores[s] ?? 0.0,
                'diff': (hScores[s] ?? 0.0) - h,
              })
          .toList();
      alternatives.sort((a, b) => (a['h'] as num).toDouble().compareTo((b['h'] as num).toDouble()));
      final topAlternatives = alternatives.take(3).toList();

      yield AlgorithmStep<State>(
        newlyExplored: [current],
        currentState: current,
        path: path,
        stepCount: stepCount,
        message:
            'Greedy evaluating ${problem.stateToString(current)} (h=${h.toStringAsFixed(1)})',
        reason: 'Greedy BFS is prioritizing this node because it has the lowest estimated distance to the goal (h = ${h.toStringAsFixed(1)}), ignoring the actual path cost from the start. It was discovered via ${parentNode != null ? problem.stateToString(parentNode) : 'the start'}.',
        meta: {
          'h': h,
          'bestPossible': h,
          'isOptimal': true,
          'alternatives': topAlternatives,
        },
        isGoalReached: false,
        frontierSize: openSet.length,
      );

      for (final neighbor in problem.getNeighbors(current)) {
        if (!visited.contains(neighbor)) {
          final hVal = problem.heuristic(neighbor);
          parent[neighbor] = current;
          hScores[neighbor] = hVal;
          openSet.add(
            StateNode<State>(
              state: neighbor,
              f: hVal,
              g: 0, // Ignored in GBFS
            ),
          );
          inOpen.add(neighbor);
        }
      }
    }

    yield AlgorithmStep<State>(
      newlyExplored: [],
      path: [],
      stepCount: stepCount,
      message: 'No path found.',
      isGoalReached: false,
    );
  }
}
