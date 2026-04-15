import 'package:flutter/foundation.dart';

import '../models/grid_node.dart';

class GridController extends ChangeNotifier {
  GridController({
    int rows = 18,
    int columns = 28,
  })  : _rows = rows,
        _columns = columns {
    _buildGrid();
  }

  int _rows;
  int _columns;
  late List<List<GridNode>> _grid;
  PaintTool _selectedTool = PaintTool.wall;
  ({int row, int column}) _start = (row: 8, column: 5);
  ({int row, int column}) _goal = (row: 8, column: 22);

  int get rows => _rows;
  int get columns => _columns;
  PaintTool get selectedTool => _selectedTool;
  List<List<GridNode>> get grid => _grid;
  ({int row, int column}) get start => _start;
  ({int row, int column}) get goal => _goal;

  int get totalNodes => _rows * _columns;
  int get wallCount => _grid
      .expand((row) => row)
      .where((node) => node.type == NodeType.wall)
      .length;
  int get walkableCount => _grid
      .expand((row) => row)
      .where((node) => node.isWalkable)
      .length;

  void updateDimensions({
    int? rows,
    int? columns,
  }) {
    final nextRows = rows ?? _rows;
    final nextColumns = columns ?? _columns;

    if (nextRows == _rows && nextColumns == _columns) {
      return;
    }

    _rows = nextRows;
    _columns = nextColumns;
    _start = (
      row: (_rows / 2).floor(),
      column: (_columns * 0.2).floor(),
    );
    _goal = (
      row: (_rows / 2).floor(),
      column: (_columns * 0.8).floor(),
    );
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
    }

    notifyListeners();
  }

  void clearWalls() {
    for (var row = 0; row < _rows; row++) {
      for (var column = 0; column < _columns; column++) {
        final type = _resolveNodeType(row, column);
        _grid[row][column] = _grid[row][column].copyWith(type: type);
      }
    }
    notifyListeners();
  }

  void resetGrid() {
    _buildGrid();
    notifyListeners();
  }

  NodeType _resolveNodeType(int row, int column) {
    if (row == _start.row && column == _start.column) {
      return NodeType.start;
    }
    if (row == _goal.row && column == _goal.column) {
      return NodeType.goal;
    }
    return NodeType.empty;
  }

  void _moveAnchor({
    required bool isStart,
    required int row,
    required int column,
  }) {
    if (isStart) {
      if (row == _goal.row && column == _goal.column) {
        return;
      }
      final previous = _start;
      _start = (row: row, column: column);
      _grid[previous.row][previous.column] =
          _grid[previous.row][previous.column].copyWith(type: NodeType.empty);
      _grid[row][column] = _grid[row][column].copyWith(type: NodeType.start);
      return;
    }

    if (row == _start.row && column == _start.column) {
      return;
    }

    final previous = _goal;
    _goal = (row: row, column: column);
    _grid[previous.row][previous.column] =
        _grid[previous.row][previous.column].copyWith(type: NodeType.empty);
    _grid[row][column] = _grid[row][column].copyWith(type: NodeType.goal);
  }

  void _setNodeType(int row, int column, NodeType type) {
    final current = _grid[row][column];

    if (current.type == NodeType.start || current.type == NodeType.goal) {
      return;
    }

    _grid[row][column] = current.copyWith(type: type);
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
}
