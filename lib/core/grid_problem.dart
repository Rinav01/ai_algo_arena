import '../core/problem_definition.dart';
import '../models/grid_node.dart';

// Coordinate state for grid-based problems
class GridCoordinate {
  final int row;
  final int column;

  const GridCoordinate({required this.row, required this.column});

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is GridCoordinate &&
          runtimeType == other.runtimeType &&
          row == other.row &&
          column == other.column;

  @override
  int get hashCode => row.hashCode ^ column.hashCode;

  @override
  String toString() => 'GridCoordinate($row, $column)';
}

// Grid problem implementation
class GridProblem extends Problem<GridCoordinate> {
  final List<List<GridNode>> grid;
  final GridCoordinate _start;
  final GridCoordinate _goal;

  GridProblem({
    required this.grid,
    required GridCoordinate start,
    required GridCoordinate goal,
  }) : _start = start,
       _goal = goal;

  @override
  GridCoordinate get initialState => _start;

  @override
  GridCoordinate get goalState => _goal;

  @override
  bool isGoal(GridCoordinate state) => state == _goal;

  @override
  List<GridCoordinate> getNeighbors(GridCoordinate state) {
    final neighbors = <GridCoordinate>[];

    // 4-directional movement: up, right, down, left
    const directions = [
      (-1, 0), // up
      (0, 1),  // right
      (1, 0),  // down
      (0, -1), // left
    ];

    for (final (rowOffset, colOffset) in directions) {
      final newRow = state.row + rowOffset;
      final newCol = state.column + colOffset;

      final neighbor = GridCoordinate(row: newRow, column: newCol);
      if (isValid(neighbor)) {
        neighbors.add(neighbor);
      }
    }

    return neighbors;
  }

  @override
  bool isValid(GridCoordinate state) {
    if (state.row < 0 ||
        state.row >= grid.length ||
        state.column < 0 ||
        state.column >= grid[0].length) {
      return false;
    }

    return grid[state.row][state.column].isWalkable;
  }

  @override
  double heuristic(GridCoordinate state) {
    // Manhattan distance heuristic
    return ((_goal.row - state.row).abs() + (_goal.column - state.column).abs())
        .toDouble();
  }

  @override
  double moveCost(GridCoordinate from, GridCoordinate to) {
    return grid[to.row][to.column].weight;
  }

  @override
  String stateToString(GridCoordinate state) {
    return '(${state.row},${state.column})';
  }

  // Get grid dimensions
  int get rows => grid.length;
  int get cols => grid[0].length;

  // Get total walkable nodes
  int get walkableNodes =>
      grid.expand((row) => row).where((node) => node.isWalkable).length;

  // Get total wall nodes
  int get wallNodes => grid
      .expand((row) => row)
      .where((node) => node.type == NodeType.wall)
      .length;

  // Obstacle density 0.0 - 1.0
  double get obstacleDensity {
    final total = rows * cols;
    return wallNodes / total;
  }

  // Grid size classification
  GridSize get gridSize {
    final total = rows * cols;
    if (total < 100) return GridSize.small;
    if (total < 500) return GridSize.medium;
    return GridSize.large;
  }
}

enum GridSize { small, medium, large }
