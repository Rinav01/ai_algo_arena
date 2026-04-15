import '../core/grid_problem.dart';
import '../core/problem_definition.dart';
import '../core/search_algorithms.dart';
import '../models/grid_node.dart';

/// Adaptor to convert between old and new systems
class AlgorithmAdaptor {
  /// Convert old grid format to GridProblem
  static GridProblem gridToGridProblem({
    required List<List<GridNode>> grid,
    required ({int row, int column}) start,
    required ({int row, int column}) goal,
  }) {
    return GridProblem(
      grid: grid,
      start: GridCoordinate(row: start.row, column: start.column),
      goal: GridCoordinate(row: goal.row, column: goal.column),
    );
  }

  /// Create BFS algorithm instance
  static BFSAlgorithm<GridCoordinate> createBFS({
    Duration stepDelay = const Duration(milliseconds: 5),
  }) {
    return BFSAlgorithm(stepDelay: stepDelay);
  }

  /// Create DFS algorithm instance
  static DFSAlgorithm<GridCoordinate> createDFS({
    Duration stepDelay = const Duration(milliseconds: 5),
  }) {
    return DFSAlgorithm(stepDelay: stepDelay);
  }

  /// Create A* algorithm instance
  static AStarAlgorithm<GridCoordinate> createAStar({
    Duration stepDelay = const Duration(milliseconds: 5),
  }) {
    return AStarAlgorithm(stepDelay: stepDelay);
  }

  /// Create Dijkstra algorithm instance
  static DijkstraAlgorithm<GridCoordinate> createDijkstra({
    Duration stepDelay = const Duration(milliseconds: 5),
  }) {
    return DijkstraAlgorithm(stepDelay: stepDelay);
  }

  /// Convert GridCoordinate back to old tuple format (for legacy code)
  static ({int row, int column}) toCoordTuple(GridCoordinate coord) {
    return (row: coord.row, column: coord.column);
  }

  /// Convert list of GridCoordinate to old format
  static List<({int row, int column})> toCoordTuples(
    List<GridCoordinate> coords,
  ) {
    return coords.map(toCoordTuple).toList();
  }
}
