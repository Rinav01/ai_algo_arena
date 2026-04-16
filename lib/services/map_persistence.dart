import 'dart:convert';
import 'package:ai_algo_app/core/grid_problem.dart';

import '../models/grid_node.dart';


class MapPersistence {
  static String exportMap({
    required List<List<GridNode>> grid,
    required GridCoordinate start,
    required GridCoordinate goal,
  }) {
    final List<List<Map<String, dynamic>>> gridData = grid.map((row) {
      return row.map((node) => node.toJson()).toList();
    }).toList();

    final mapData = {
      'rows': grid.length,
      'columns': grid.first.length,
      'start': {'row': start.row, 'column': start.column},
      'goal': {'row': goal.row, 'column': goal.column},
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
