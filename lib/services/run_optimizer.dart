import 'package:algo_arena/core/grid_problem.dart';
import 'package:algo_arena/core/problem_definition.dart';

class RunOptimizer {
  /// Compresses a GridCoordinate into a single integer: (row * cols) + col
  static int compress(GridCoordinate coord, int cols) {
    return (coord.row * cols) + coord.column;
  }

  /// Decompresses an integer back into a GridCoordinate
  static GridCoordinate decompress(int val, int cols) {
    return GridCoordinate(
      row: (val / cols).floor(),
      column: val % cols,
    );
  }

  /// Optimizes a list of steps using delta encoding and coordinate compression.
  /// Only stores newlyExplored and currentState per step. Path is excluded.
  static List<Map<String, dynamic>> optimizeSteps(
      List<AlgorithmStep<GridCoordinate>> steps, int cols) {
    return steps.map((step) {
      return {
        'e': step.newlyExplored.map((c) => compress(c, cols)).toList(),
        'c': step.currentState != null ? compress(step.currentState!, cols) : null,
        's': step.stepCount,
        if (step.isGoalReached) 'g': true,
      };
    }).toList();
  }

  /// Optimizes a single algorithm result for storage.
  static Map<String, dynamic> optimizeCompetitor(
      String name, List<AlgorithmStep<GridCoordinate>> steps, List<GridCoordinate> finalPath, Duration duration, int cols, {bool isWinner = false}) {
    return {
      'name': name,
      'durationMs': duration.inMilliseconds,
      'isWinner': isWinner,
      'path': finalPath.map((c) => compress(c, cols)).toList(),
      'steps': optimizeSteps(steps, cols),
    };
  }
}
