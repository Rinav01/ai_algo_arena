import 'dart:convert';
import 'package:algo_arena/core/grid_problem.dart';

import 'package:algo_arena/models/grid_node.dart';

class MapPersistence {
  static String exportMap({
    required List<List<GridNode>> grid,
    required GridCoordinate start,
    GridCoordinate? goal,
  }) {
    final List<List<Map<String, dynamic>>> gridData = grid.map((row) {
      return row.map((node) => node.toJson()).toList();
    }).toList();

    final mapData = {
      'rows': grid.length,
      'columns': grid.first.length,
      'start': {'row': start.row, 'column': start.column},
      'goal': goal != null ? {'row': goal.row, 'column': goal.column} : null,
      'grid': gridData,
    };

    return jsonEncode(mapData);
  }

  static Map<String, dynamic> importMap(String jsonString) {
    try {
      return jsonDecode(jsonString);
    } catch (e) {
      throw Exception('Invalid map JSON');
    }
  }
}
