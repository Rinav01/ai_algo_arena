import 'package:flutter/foundation.dart';

import 'package:algo_arena/models/grid_node.dart';
import 'package:algo_arena/models/app_settings.dart';

class GridController extends ChangeNotifier {
  GridController({int rows = 18, int columns = 28})
    : _rows = rows,
      _columns = columns {
    _start = (row: (rows / 2).floor(), column: (columns * 0.2).floor());
    _goal = null; // Goal must be placed manually
    _buildGrid();
  }

  int _rows;
  int _columns;
  late List<List<GridNode>> _grid;
  PaintTool _selectedTool = PaintTool.wall;
  ({int row, int column}) _start = (row: 0, column: 0);
  ({int row, int column})? _goal;

  int get rows => _rows;
  int get columns => _columns;
  PaintTool get selectedTool => _selectedTool;
  List<List<GridNode>> get grid => _grid;
  ({int row, int column}) get start => _start;
  ({int row, int column})? get goal => _goal;
  bool get hasGoal => _goal != null;

  int get totalNodes => _rows * _columns;
  int get wallCount => _grid
      .expand((row) => row)
      .where((node) => node.type == NodeType.wall)
      .length;
  int get walkableCount =>
      _grid.expand((row) => row).where((node) => node.isWalkable).length;

  void updateDimensions({int? rows, int? columns}) {
    final nextRows = rows ?? _rows;
    final nextColumns = columns ?? _columns;

    if (nextRows == _rows && nextColumns == _columns) {
      return;
    }

    _rows = nextRows;
    _columns = nextColumns;
    _start = (row: (_rows / 2).floor(), column: (_columns * 0.2).floor());
    _goal = (row: (_rows / 2).floor(), column: (_columns * 0.8).floor());
    _buildGrid();
    notifyListeners();
  }

  void setTool(PaintTool tool) {
    if (_selectedTool == tool) {
      return;
    }

    _selectedTool = tool;
    notifyListeners();
  }

  void handleCellInteraction(int row, int column) {
    if (!_isInBounds(row, column)) {
      return;
    }

    switch (_selectedTool) {
      case PaintTool.wall:
        _setNodeType(row, column, NodeType.wall);
      case PaintTool.erase:
        _setNodeType(row, column, NodeType.empty);
      case PaintTool.start:
        _moveAnchor(isStart: true, row: row, column: column);
      case PaintTool.goal:
        _moveAnchor(isStart: false, row: row, column: column);
      case PaintTool.weight:
        _setNodeType(row, column, NodeType.weight, weight: 5.0);
    }

    notifyListeners();
  }

  void clearWalls() {
    for (var row = 0; row < _rows; row++) {
      for (var column = 0; column < _columns; column++) {
        final current = _grid[row][column];
        if (current.type == NodeType.wall || current.type == NodeType.weight) {
          final type = _resolveNodeType(row, column);
          _grid[row][column] = current.copyWith(type: type, weight: 1.0);
        }
      }
    }
    notifyListeners();
  }

  void resetGrid() {
    _goal = null;
    _buildGrid();
    notifyListeners();
  }

  NodeType _resolveNodeType(int row, int column) {
    if (row == _start.row && column == _start.column) {
      return NodeType.start;
    }
    if (_goal != null && row == _goal!.row && column == _goal!.column) {
      return NodeType.goal;
    }
    return NodeType.empty;
  }

  void moveAnchor({
    required bool isStart,
    required int row,
    required int column,
  }) {
    _moveAnchor(isStart: isStart, row: row, column: column);
    notifyListeners();
  }

  void _moveAnchor({
    required bool isStart,
    required int row,
    required int column,
  }) {
    // Ensure the target coordinates are within grid bounds
    if (!_isInBounds(row, column)) {
      return;
    }
    if (isStart) {
      // Prevent moving start onto goal
      if (_goal != null && row == _goal!.row && column == _goal!.column) {
        return;
      }
      if (row == _start.row && column == _start.column) {
        return;
      }

      final previous = _start;
      _start = (row: row, column: column);

      // Update grid states correctly
      _grid[previous.row][previous.column] =
          _grid[previous.row][previous.column].copyWith(type: NodeType.empty);
      _grid[row][column] = _grid[row][column].copyWith(type: NodeType.start);
      return;
    }

    // Initialize or Moving goal anchor
    if (row == _start.row && column == _start.column) {
      return;
    }

    if (_goal != null && row == _goal!.row && column == _goal!.column) {
      return;
    }

    final previous = _goal;
    _goal = (row: row, column: column);

    if (previous != null) {
      _grid[previous.row][previous.column] =
          _grid[previous.row][previous.column].copyWith(type: NodeType.empty);
    }
    _grid[row][column] = _grid[row][column].copyWith(type: NodeType.goal);
  }

  // Public method to set node type (used by maze generator)
  void setNodeType(int row, int column, NodeType type, {double weight = 1.0}) {
    _setNodeType(row, column, type, weight: weight);
    notifyListeners();
  }

  void _setNodeType(int row, int column, NodeType type, {double weight = 1.0}) {
    final current = _grid[row][column];

    if (current.type == NodeType.start || current.type == NodeType.goal) {
      return;
    }

    _grid[row][column] = current.copyWith(type: type, weight: weight);
  }

  void _buildGrid() {
    _grid = List.generate(
      _rows,
      (row) => List.generate(
        _columns,
        (column) => GridNode(
          row: row,
          column: column,
          type: _resolveNodeType(row, column),
        ),
      ),
    );
  }

  bool _isInBounds(int row, int column) {
    return row >= 0 && row < _rows && column >= 0 && column < _columns;
  }

  void loadFromJson(Map<String, dynamic> data) {
    final int nextRows = data['rows'] as int;
    final int nextCols = data['columns'] as int;

    _rows = nextRows;
    _columns = nextCols;

    final startData = data['start'] as Map<String, dynamic>;
    _start = (row: startData['row'] as int, column: startData['column'] as int);

    if (data['goal'] != null) {
      final goalData = data['goal'] as Map<String, dynamic>;
      _goal = (row: goalData['row'] as int, column: goalData['column'] as int);
    } else {
      _goal = null;
    }

    final List<dynamic> gridData = data['grid'] as List<dynamic>;
    _grid = List.generate(_rows, (r) {
      final List<dynamic> rowData = gridData[r] as List<dynamic>;
      return List.generate(_columns, (c) {
        return GridNode.fromJson(rowData[c] as Map<String, dynamic>);
      });
    });

    notifyListeners();
  }

  void loadFromSnapshot(Map<String, dynamic> snapshot) {
    _rows = snapshot['rows'] as int;
    _columns = snapshot['columns'] as int;

    // Handle both Uint8List (from local) and List<int> (from JSON)
    final typesRaw = snapshot['types'];
    final Uint8List types = typesRaw is Uint8List
        ? typesRaw
        : Uint8List.fromList((typesRaw as List).cast<int>());

    final weightsRaw = snapshot['weights'];
    final Float32List weights = weightsRaw is Float32List
        ? weightsRaw
        : Float32List.fromList((weightsRaw as List).cast<num>().map((e) => e.toDouble()).toList());

    final startRaw = snapshot['start'];
    if (startRaw is Map) {
      _start = (row: startRaw['row'] as int, column: startRaw['column'] as int);
    } else {
      // Handle record from local snapshot
      try {
        _start = (row: (startRaw as dynamic).row as int, column: startRaw.column as int);
      } catch(_) {
         _start = (row: 0, column: 0);
      }
    }

    final goalRaw = snapshot['goal'];
    if (goalRaw != null) {
      if (goalRaw is Map) {
        _goal = (row: goalRaw['row'] as int, column: goalRaw['column'] as int);
      } else {
        try {
          _goal = (row: (goalRaw as dynamic).row as int, column: goalRaw.column as int);
        } catch(_) {
          _goal = null;
        }
      }
    } else {
      _goal = null;
    }

    _grid = List.generate(_rows, (r) {
      return List.generate(_columns, (c) {
        final index = r * _columns + c;
        final typeIndex = types[index];
        final weight = weights[index];
        return GridNode(
          row: r,
          column: c,
          type: NodeType.values[typeIndex],
          weight: weight,
        );
      });
    });

    notifyListeners();
  }

  void loadFromGrid(List<List<GridNode>> newGrid) {
    _rows = newGrid.length;
    _columns = newGrid[0].length;

    // Deep copy the grid
    _goal = null; // Reset and let loop find it
    _grid = List.generate(_rows, (r) {
      return List.generate(_columns, (c) {
        final node = newGrid[r][c];
        if (node.type == NodeType.start) _start = (row: r, column: c);
        if (node.type == NodeType.goal) _goal = (row: r, column: c);
        return node.copyWith();
      });
    });

    notifyListeners();
  }

  /// Exports an optimized, flat representation of the grid for background processing.
  /// This avoids copying complex object graphs into isolates.
  Map<String, dynamic> toOptimizedSnapshot(AppSettings settings) {
    final types = Uint8List(rows * columns);
    final weights = Float32List(rows * columns);

    for (int r = 0; r < rows; r++) {
      for (int c = 0; c < columns; c++) {
        final node = _grid[r][c];
        final index = r * columns + c;
        types[index] = node.type.index;
        weights[index] = node.weight;
      }
    }

    return {
      'rows': rows,
      'columns': columns,
      'types': types,
      'weights': weights,
      'start': (row: _start.row, column: _start.column),
      'goal': _goal != null ? (row: _goal!.row, column: _goal!.column) : null,
      'settings': settings.toJson(),
    };
  }
}
