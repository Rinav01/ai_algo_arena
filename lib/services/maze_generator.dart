import 'dart:math' as math;
import 'package:ai_algo_app/models/grid_node.dart';
import 'package:ai_algo_app/state/grid_controller.dart';

class MazeGenerator {
  /// Generates a maze using Randomized Prim's Algorithm.
  /// If [includeWeights] is true, some passages will be weighted nodes (slower to cross).
  static void generatePrims(GridController controller, {bool includeWeights = false}) {
    final rows = controller.rows;
    final cols = controller.columns;
    final random = math.Random();

    // 1. Fill everything with walls
    for (int r = 0; r < rows; r++) {
      for (int c = 0; c < cols; c++) {
        controller.setNodeType(r, c, NodeType.wall);
      }
    }

    final List<({int r, int c})> walls = [];
    
    // 2. Pick a random starting cell (ensure it's on an even coordinate)
    final startR = (random.nextInt(rows ~/ 2) * 2).clamp(0, rows - 1);
    final startC = (random.nextInt(cols ~/ 2) * 2).clamp(0, cols - 1);

    _makePassage(controller, startR, startC, includeWeights, random);
    _addPotentialWalls(startR, startC, rows, cols, walls, controller);

    while (walls.isNotEmpty) {
      final index = random.nextInt(walls.length);
      final wall = walls.removeAt(index);

      // A wall connects two cells. Find the unvisited neighbor.
      final neighbors = _getDividedCells(wall.r, wall.c, rows, cols);
      final unvisited = neighbors.where((pos) => controller.grid[pos.r][pos.c].type == NodeType.wall).toList();

      if (unvisited.length == 1) {
        final target = unvisited.first;
        // Make both the wall and the target cell passages
        _makePassage(controller, wall.r, wall.c, includeWeights, random);
        _makePassage(controller, target.r, target.c, includeWeights, random);
        _addPotentialWalls(target.r, target.c, rows, cols, walls, controller);
      }
    }

    // 3. Ensure Start and Goal are correctly set and accessible
    controller.setNodeType(controller.start.row, controller.start.column, NodeType.start);
    _ensurePassage(controller, controller.start.row, controller.start.column);

    if (controller.goal != null) {
      controller.setNodeType(controller.goal!.row, controller.goal!.column, NodeType.goal);
      _ensurePassage(controller, controller.goal!.row, controller.goal!.column);
    }
  }

  static void _makePassage(GridController controller, int r, int c, bool includeWeights, math.Random random) {
    NodeType type = NodeType.empty;
    double weight = 1.0;

    if (includeWeights && random.nextDouble() < 0.25) {
      type = NodeType.weight;
      weight = 5.0; // Standard weight cost
    }

    controller.setNodeType(r, c, type, weight: weight);
  }

  static void _addPotentialWalls(int r, int c, int rows, int cols, List<({int r, int c})> walls, GridController controller) {
    final dr = [-1, 1, 0, 0];
    final dc = [0, 0, -1, 1];

    for (int i = 0; i < 4; i++) {
      final wr = r + dr[i];
      final wc = c + dc[i];

      if (wr >= 0 && wr < rows && wc >= 0 && wc < cols) {
        if (controller.grid[wr][wc].type == NodeType.wall) {
          walls.add((r: wr, c: wc));
        }
      }
    }
  }

  static List<({int r, int c})> _getDividedCells(int r, int c, int rows, int cols) {
    final List<({int r, int c})> neighbors = [];
    
    // Check vertical wall (divides horizontal cells)
    if (r % 2 == 0) {
      if (c - 1 >= 0) neighbors.add((r: r, c: c - 1));
      if (c + 1 < cols) neighbors.add((r: r, c: c + 1));
    } else {
      // Check horizontal wall (divides vertical cells)
      if (r - 1 >= 0) neighbors.add((r: r - 1, c: c));
      if (r + 1 < rows) neighbors.add((r: r + 1, c: c));
    }
    
    return neighbors;
  }

  static void _ensurePassage(GridController controller, int r, int c) {
    final dr = [0, 0, 1, -1];
    final dc = [1, -1, 0, 0];
    
    for (int i = 0; i < 4; i++) {
      final nr = r + dr[i];
      final nc = c + dc[i];
      if (nr >= 0 && nr < controller.rows && nc >= 0 && nc < controller.columns) {
        if (controller.grid[nr][nc].type == NodeType.wall) {
          controller.setNodeType(nr, nc, NodeType.empty);
          return;
        }
      }
    }
  }
}
