enum NodeType { empty, wall, start, goal }

class GridNode {
  const GridNode({
    required this.row,
    required this.column,
    required this.type,
  });

  final int row;
  final int column;
  final NodeType type;

  bool get isWalkable => type != NodeType.wall;

  GridNode copyWith({
    int? row,
    int? column,
    NodeType? type,
  }) {
    return GridNode(
      row: row ?? this.row,
      column: column ?? this.column,
      type: type ?? this.type,
    );
  }
}

enum PaintTool { wall, erase, start, goal }
