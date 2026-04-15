import 'dart:async';
import 'dart:collection';
import 'package:collection/collection.dart';

import '../core/problem_definition.dart';

/// Generic BFS algorithm that works with any Problem
class BFSAlgorithm<State> extends SearchAlgorithm<State> {
  final Duration stepDelay;

  BFSAlgorithm({this.stepDelay = const Duration(milliseconds: 5)});

  @override
  String get name => 'Breadth-First Search';

  @override
  String get category => 'Uninformed Search';

  @override
  Stream<AlgorithmStep<State>> solve(Problem<State> problem) async* {
    final visited = <State>{};
    final queue = Queue<State>();
    final parent = <State, State>{};
    final explored = <State>[];

    final startState = problem.initialState;
    queue.add(startState);
    visited.add(startState);

    int stepCount = 0;

    while (queue.isNotEmpty) {
      // Emit current state
      yield AlgorithmStep<State>(
        explored: explored.toList(),
        path: [],
        stepCount: stepCount,
        message: 'Exploring ${problem.stateToString(queue.first)}',
        isGoalReached: false,
      );

      // Add delay for visualization
      if (stepDelay.inMilliseconds > 0) {
        await Future.delayed(stepDelay);
      }

      final current = queue.removeFirst();
      explored.add(current);
      stepCount++;

      // Check if goal is reached
      if (problem.isGoal(current)) {
        final path = _reconstructPath(parent, current, startState);
        yield AlgorithmStep<State>(
          explored: explored,
          path: path,
          stepCount: stepCount,
          message: 'Goal found!',
          isGoalReached: true,
        );
        return;
      }

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
      explored: explored,
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
      current = parent[current]!;
      path.add(current);
    }

    return path.reversed.toList();
  }
}

/// Generic DFS algorithm that works with any Problem
class DFSAlgorithm<State> extends SearchAlgorithm<State> {
  final Duration stepDelay;

  DFSAlgorithm({this.stepDelay = const Duration(milliseconds: 5)});

  @override
  String get name => 'Depth-First Search';

  @override
  String get category => 'Uninformed Search';

  @override
  Stream<AlgorithmStep<State>> solve(Problem<State> problem) async* {
    final visited = <State>{};
    final stack = <State>[problem.initialState];
    final parent = <State, State>{};
    final explored = <State>[];

    visited.add(problem.initialState);
    int stepCount = 0;

    while (stack.isNotEmpty) {
      final current = stack.removeLast();

      if (visited.contains(current)) continue;

      explored.add(current);
      stepCount++;

      // Emit current state
      yield AlgorithmStep<State>(
        explored: explored.toList(),
        path: [],
        stepCount: stepCount,
        message: 'Exploring ${problem.stateToString(current)}',
        isGoalReached: false,
      );

      // Add delay for visualization
      if (stepDelay.inMilliseconds > 0) {
        await Future.delayed(stepDelay);
      }

      visited.add(current);

      // Check if goal is reached
      if (problem.isGoal(current)) {
        final path = _reconstructPath(parent, current, problem.initialState);
        yield AlgorithmStep<State>(
          explored: explored,
          path: path,
          stepCount: stepCount,
          message: 'Goal found!',
          isGoalReached: true,
        );
        return;
      }

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
      explored: explored,
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
      current = parent[current]!;
      path.add(current);
    }

    return path.reversed.toList();
  }
}

/// Generic A* algorithm that works with any Problem
class AStarAlgorithm<State> extends SearchAlgorithm<State> {
  final Duration stepDelay;

  AStarAlgorithm({this.stepDelay = const Duration(milliseconds: 5)});

  @override
  String get name => 'A* Search';

  @override
  String get category => 'Informed Search';

  @override
  Stream<AlgorithmStep<State>> solve(Problem<State> problem) async* {
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

      // Emit current state
      yield AlgorithmStep<State>(
        explored: explored.toList(),
        path: [],
        stepCount: stepCount,
        message:
            'Evaluating ${problem.stateToString(current)} (f=${(fScore[current] ?? 0).toStringAsFixed(1)})',
        isGoalReached: false,
      );

      // Add delay for visualization
      if (stepDelay.inMilliseconds > 0) {
        await Future.delayed(stepDelay);
      }

      visited.add(current);
      explored.add(current);
      stepCount++;

      if (problem.isGoal(current)) {
        final path = _reconstructPath(parent, current, startState);
        yield AlgorithmStep<State>(
          explored: explored,
          path: path,
          stepCount: stepCount,
          message:
              'Goal found with f=${(fScore[current] ?? 0).toStringAsFixed(1)}!',
          isGoalReached: true,
        );
        return;
      }

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

          if (!inOpen.contains(neighbor)) {
            openQueue.add(neighbor);
            inOpen.add(neighbor);
          } else {
            // Need to remove and re-insert to update priority
            openQueue.remove(neighbor);
            openQueue.add(neighbor);
          }
        }
      }
    }

    // No path found
    yield AlgorithmStep<State>(
      explored: explored,
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
      current = parent[current]!;
      path.add(current);
    }

    return path.reversed.toList();
  }
}

/// Dijkstra's algorithm - weighted version of BFS
class DijkstraAlgorithm<State> extends SearchAlgorithm<State> {
  final Duration stepDelay;

  DijkstraAlgorithm({this.stepDelay = const Duration(milliseconds: 5)});

  @override
  String get name => 'Dijkstra\'s Algorithm';

  @override
  String get category => 'Weighted Search';

  @override
  Stream<AlgorithmStep<State>> solve(Problem<State> problem) async* {
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

      // Emit current state
      yield AlgorithmStep<State>(
        explored: explored.toList(),
        path: [],
        stepCount: stepCount,
        message:
            'Visiting ${problem.stateToString(current)} (distance=${minDistance.toStringAsFixed(1)})',
        isGoalReached: false,
      );

      // Add delay for visualization
      if (stepDelay.inMilliseconds > 0) {
        await Future.delayed(stepDelay);
      }

      visited.add(current);
      explored.add(current);
      stepCount++;

      if (problem.isGoal(current)) {
        final path = _reconstructPath(parent, current, startState);
        yield AlgorithmStep<State>(
          explored: explored,
          path: path,
          stepCount: stepCount,
          message:
              'Goal found with distance=${minDistance.toStringAsFixed(1)}!',
          isGoalReached: true,
        );
        return;
      }

      final neighbors = problem.getNeighbors(current);
      for (final neighbor in neighbors) {
        if (visited.contains(neighbor)) continue;

        final newDistance =
            (distances[current] ?? 0) + problem.moveCost(current, neighbor);
        if (!distances.containsKey(neighbor) ||
            newDistance < distances[neighbor]!) {
          distances[neighbor] = newDistance;
          parent[neighbor] = current;
          
          if (!inOpen.contains(neighbor)) {
            openQueue.add(neighbor);
            inOpen.add(neighbor);
          } else {
            openQueue.remove(neighbor);
            openQueue.add(neighbor);
          }
        }
      }
    }

    // No path found
    yield AlgorithmStep<State>(
      explored: explored,
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
      current = parent[current]!;
      path.add(current);
    }

    return path.reversed.toList();
  }
}
