import 'dart:typed_data';
import 'dart:math' as math;
import 'package:algo_arena/core/problem_definition.dart';
import 'package:algo_arena/models/grid_node.dart';
import 'package:algo_arena/models/app_settings.dart';

// Coordinate state for grid-based problems
class GridCoordinate {
  final int row;
  final int column;

  const GridCoordinate({required this.row, required this.column});

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is GridCoordinate && row == other.row && column == other.column;

  @override
  int get hashCode => row.hashCode ^ column.hashCode;

  @override
  String toString() => 'GridCoordinate($row, $column)';

  Map<String, dynamic> toJson() => {
    'row': row,
    'column': column,
  };

  factory GridCoordinate.fromJson(Map<String, dynamic> json) => GridCoordinate(
    row: json['row'] as int,
    column: json['column'] as int,
  );
}

// Grid problem implementation
class GridProblem extends Problem<GridCoordinate> {
  final int rows;
  final int cols;

  final List<List<GridNode>>? _grid;
  final Uint8List _types;
  final Float32List _weights;
  final GridCoordinate _start;
  final GridCoordinate _goal;
  final AppSettings settings;

  int? _cachedHashCode;

  GridProblem({
    required List<List<GridNode>> grid,
    required GridCoordinate start,
    required GridCoordinate goal,
    this.settings = const AppSettings(),
  }) : rows = grid.length,
       cols = grid[0].length,
       _types = Uint8List(grid.length * grid[0].length),
       _weights = Float32List(grid.length * grid[0].length),
       _start = start,
       _goal = goal,
       _grid = grid {
    for (int r = 0; r < rows; r++) {
      for (int c = 0; c < cols; c++) {
        final node = grid[r][c];
        final index = r * cols + c;
        _types[index] = node.type.index;
        _weights[index] = node.weight;
      }
    }
  }

  /// Get the full grid object graph (may be null if reconstructed from snapshot)
  List<List<GridNode>> get grid {
    if (_grid != null) return _grid;
    throw StateError(
      'Grid object graph is not available for snapshotted problems. Use getNeighbors/isValid instead.',
    );
  }

  /// Reconstruct from a background processing snapshot
  GridProblem.fromSnapshot(Map<String, dynamic> snapshot)
    : rows = snapshot['rows'] as int,
      cols = snapshot['columns'] as int,
      _types = snapshot['types'] as Uint8List,
      _weights = snapshot['weights'] as Float32List,
      _start = GridCoordinate(
        row: (snapshot['start'] as dynamic).row as int,
        column: (snapshot['start'] as dynamic).column as int,
      ),
      _goal = GridCoordinate(
        row: (snapshot['goal'] as dynamic).row as int,
        column: (snapshot['goal'] as dynamic).column as int,
      ),
      settings = AppSettings.fromJson(
        snapshot['settings'] as Map<String, dynamic>,
      ),
      _grid = null;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is GridProblem &&
          rows == other.rows &&
          cols == other.cols &&
          _start == other._start &&
          _goal == other._goal &&
          settings == other.settings &&
          _isGridEqual(other);

  @override
  int get hashCode {
    if (_cachedHashCode != null) return _cachedHashCode!;

    // Efficient hashing for flat buffers
    int hash = _start.hashCode ^ _goal.hashCode ^ settings.hashCode;
    hash = Object.hash(hash, rows, cols);
    hash = Object.hash(hash, Object.hashAll(_types));
    // Weights are often 1.0, so hashAll is fine
    hash = Object.hash(hash, Object.hashAll(_weights));

    _cachedHashCode = hash;
    return hash;
  }

  bool _isGridEqual(GridProblem other) {
    if (rows != other.rows || cols != other.cols) return false;
    for (int i = 0; i < _types.length; i++) {
      if (_types[i] != other._types[i]) return false;
      if (_weights[i] != other._weights[i]) return false;
    }
    return true;
  }

  @override
  Map<String, dynamic> toSnapshot() {
    return {
      'type': 'grid',
      'rows': rows,
      'columns': cols,
      'types': _types,
      'weights': _weights,
      'start': (row: _start.row, column: _start.column),
      'goal': (row: _goal.row, column: _goal.column),
      'settings': settings.toJson(),
    };
  }

  @override
  GridCoordinate get initialState => _start;

  @override
  GridCoordinate get goalState => _goal;

  @override
  bool isGoal(GridCoordinate state) => state == _goal;

  @override
  List<GridCoordinate> getNeighbors(GridCoordinate state) {
    final neighbors = <GridCoordinate>[];

    final directions = [
      (-1, 0), // up
      (0, 1), // right
      (1, 0), // down
      (0, -1), // left
      if (settings.allowDiagonalMoves) ...[
        (-1, -1), // up-left
        (-1, 1), // up-right
        (1, -1), // down-left
        (1, 1), // down-right
      ],
    ];

    for (final (rowOffset, colOffset) in directions) {
      final newRow = state.row + rowOffset;
      final newCol = state.column + colOffset;

      if (newRow >= 0 && newRow < rows && newCol >= 0 && newCol < cols) {
        final index = newRow * cols + newCol;
        if (_types[index] != NodeType.wall.index) {
          neighbors.add(GridCoordinate(row: newRow, column: newCol));
        }
      }
    }

    return neighbors;
  }

  @override
  bool isValid(GridCoordinate state) {
    if (state.row < 0 ||
        state.row >= rows ||
        state.column < 0 ||
        state.column >= cols) {
      return false;
    }

    final index = state.row * cols + state.column;
    return _types[index] != NodeType.wall.index;
  }

  @override
  double heuristic(GridCoordinate state) {
    final dy = (_goal.row - state.row).abs();
    final dx = (_goal.column - state.column).abs();

    if (settings.allowDiagonalMoves) {
      // Octile distance: 1 for cardinal, sqrt(2) for diagonal
      const d1 = 1.0;
      final d2 = math.sqrt(2.0);
      return (d1 * (dx + dy) + (d2 - 2 * d1) * math.min(dx, dy)) *
          settings.heuristicWeight;
    }

    // Manhattan distance
    return (dx + dy).toDouble() * settings.heuristicWeight;
  }

  @override
  double moveCost(GridCoordinate from, GridCoordinate to) {
    final index = to.row * cols + to.column;
    final baseCost = _weights[index];

    // If diagonal move, multiply by sqrt(2)
    if (from.row != to.row && from.column != to.column) {
      return baseCost * math.sqrt(2.0);
    }

    return baseCost;
  }

  @override
  String stateToString(GridCoordinate state) {
    return '(${state.row},${state.column})';
  }

  int get walkableNodes {
    int count = 0;
    for (final type in _types) {
      if (type != NodeType.wall.index) count++;
    }
    return count;
  }

  int get wallNodes {
    int count = 0;
    for (final type in _types) {
      if (type == NodeType.wall.index) count++;
    }
    return count;
  }

  double get obstacleDensity => wallNodes / (rows * cols);

  GridSize get gridSize {
    final total = rows * cols;
    if (total < 400) return GridSize.small;
    if (total < 1000) return GridSize.medium;
    return GridSize.large;
  }
}

enum GridSize { small, medium, large }
