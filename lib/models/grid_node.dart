enum NodeType { empty, wall, start, goal, weight }

class GridNode {
  const GridNode({
    required this.row,
    required this.column,
    required this.type,
    this.weight = 1.0,
  });

  final int row;
  final int column;
  final NodeType type;
  final double weight;

  bool get isWalkable => type != NodeType.wall;

  GridNode copyWith({
    int? row,
    int? column,
    NodeType? type,
    double? weight,
  }) {
    return GridNode(
      row: row ?? this.row,
      column: column ?? this.column,
      type: type ?? this.type,
      weight: weight ?? this.weight,
    );
  }

  Map<String, dynamic> toJson() => {
        'row': row,
        'column': column,
        'type': type.index,
        'weight': weight,
      };

  factory GridNode.fromJson(Map<String, dynamic> json) => GridNode(
        row: json['row'] as int,
        column: json['column'] as int,
        type: NodeType.values[json['type'] as int],
        weight: (json['weight'] as num).toDouble(),
      );
}

enum PaintTool { wall, erase, start, goal, weight }
