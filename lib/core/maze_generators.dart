import 'dart:math';

import '../state/grid_controller.dart';
import '../models/grid_node.dart';

class MazeGenerator {
  final Random _random = Random();

  /// Generates a procedural maze using Recursive Division.
  /// Expects a clear grid to start with.
  void generateRecursiveDivision(GridController controller) {
    controller.clearWalls();
    
    // Add border walls
    for (int i = 0; i < controller.rows; i++) {
        controller.setNodeType(i, 0, NodeType.wall);
        controller.setNodeType(i, controller.columns - 1, NodeType.wall);
    }
    for (int j = 0; j < controller.columns; j++) {
        controller.setNodeType(0, j, NodeType.wall);
        controller.setNodeType(controller.rows - 1, j, NodeType.wall);
    }

    _divide(
      controller,
      1, 
      1, 
      controller.columns - 2, 
      controller.rows - 2, 
      _chooseOrientation(controller.columns - 2, controller.rows - 2)
    );
    
    // Ensure start is open
    controller.setNodeType(controller.start.row, controller.start.column, NodeType.start);
    _clearNeighbors(controller, controller.start.row, controller.start.column);

    // Ensure goal is open if it exists
    if (controller.goal != null) {
      controller.setNodeType(controller.goal!.row, controller.goal!.column, NodeType.goal);
      _clearNeighbors(controller, controller.goal!.row, controller.goal!.column);
    }
  }

  void _divide(GridController controller, int x, int y, int width, int height, bool isHorizontal) {
    if (width < 2 || height < 2) return;

    final isHorizontalDiv = isHorizontal;

    int wx = x + (isHorizontalDiv ? 0 : _random.nextInt(width - 1));
    int wy = y + (isHorizontalDiv ? _random.nextInt(height - 1) : 0);

    int px = wx + (isHorizontalDiv ? _random.nextInt(width) : 0);
    int py = wy + (isHorizontalDiv ? 0 : _random.nextInt(height));

    int dx = isHorizontalDiv ? 1 : 0;
    int dy = isHorizontalDiv ? 0 : 1;

    int length = isHorizontalDiv ? width : height;


    for (int i = 0; i < length; i++) {
      if (wx != px || wy != py) {
          // don't overwrite start/goal
          final currentType = controller.grid[wy][wx].type;
          if (currentType != NodeType.start && currentType != NodeType.goal) {
              controller.setNodeType(wy, wx, NodeType.wall);
          }
      }
      wx += dx;
      wy += dy;
    }

    int nx = x;
    int ny = y;
    int w = isHorizontalDiv ? width : wx - x + 1;
    int h = isHorizontalDiv ? wy - y + 1 : height;
    _divide(controller, nx, ny, w, h, _chooseOrientation(w, h));

    nx = isHorizontalDiv ? x : wx + 1;
    ny = isHorizontalDiv ? wy + 1 : y;
    w = isHorizontalDiv ? width : x + width - wx - 1;
    h = isHorizontalDiv ? y + height - wy - 1 : height;
    _divide(controller, nx, ny, w, h, _chooseOrientation(w, h));
  }

  bool _chooseOrientation(int width, int height) {
    if (width < height) {
      return true; // Horizontal
    } else if (height < width) {
      return false; // Vertical
    } else {
      return _random.nextBool();
    }
  }
  
  void _clearNeighbors(GridController controller, int r, int c) {
      final moves = [[0,1], [1,0], [0,-1], [-1,0]];
      for (var m in moves) {
          final nr = r + m[0];
          final nc = c + m[1];
          if (nr >= 0 && nr < controller.rows && nc >= 0 && nc < controller.columns) {
             if (controller.grid[nr][nc].type == NodeType.wall) {
                 controller.setNodeType(nr, nc, NodeType.empty);
                 break; // Only clear one direct path
             } 
          }
      }
  }

  /// Generates a maze using Randomized Prim's Algorithm.
  /// Creates organic-looking paths with many dead ends and more branching.
  void generateRandomizedPrims(GridController controller) {
    controller.clearWalls();
    
    // 1. Start with everything as walls
    for (int r = 0; r < controller.rows; r++) {
      for (int c = 0; c < controller.columns; c++) {
        controller.setNodeType(r, c, NodeType.wall);
      }
    }

    final List<Point<int>> frontier = [];
    final Set<Point<int>> inMaze = {};

    // 2. Start at (1, 1) or a random odd coordinate
    const startPoint = Point(1, 1);
    controller.setNodeType(startPoint.y, startPoint.x, NodeType.empty);
    inMaze.add(startPoint);

    // 3. Add neighbors at distance 2 to frontier
    _addPrimsFrontier(controller, startPoint, frontier, inMaze);

    while (frontier.isNotEmpty) {
      // Pick random frontier node
      final index = _random.nextInt(frontier.length);
      final current = frontier.removeAt(index);

      // Find neighbors that are already in maze
      final List<Point<int>> neighbors = _getInMazeNeighbors(controller, current, inMaze);
      
      if (neighbors.isNotEmpty) {
        final neighbor = neighbors[_random.nextInt(neighbors.length)];
        
        // Connect current to neighbor by clearing the wall between them
        final midY = (current.y + neighbor.y) ~/ 2;
        final midX = (current.x + neighbor.x) ~/ 2;
        
        controller.setNodeType(current.y, current.x, NodeType.empty);
        controller.setNodeType(midY, midX, NodeType.empty);
        inMaze.add(current);

        // Add new frontier nodes
        _addPrimsFrontier(controller, current, frontier, inMaze);
      }
    }

    // 4. Cleanup: Ensure start is open
    controller.setNodeType(controller.start.row, controller.start.column, NodeType.start);
    _clearNeighbors(controller, controller.start.row, controller.start.column);

    // Ensure goal is open if it exists
    if (controller.goal != null) {
      controller.setNodeType(controller.goal!.row, controller.goal!.column, NodeType.goal);
      _clearNeighbors(controller, controller.goal!.row, controller.goal!.column);
    }
  }

  void _addPrimsFrontier(GridController controller, Point<int> p, List<Point<int>> frontier, Set<Point<int>> inMaze) {
    final dirs = [const Point(0, 2), const Point(0, -2), const Point(2, 0), const Point(-2, 0)];
    for (final d in dirs) {
      final np = p + d;
      if (np.y > 0 && np.y < controller.rows - 1 && np.x > 0 && np.x < controller.columns - 1) {
        if (!inMaze.contains(np) && !frontier.contains(np)) {
          frontier.add(np);
        }
      }
    }
  }

  List<Point<int>> _getInMazeNeighbors(GridController controller, Point<int> p, Set<Point<int>> inMaze) {
    final List<Point<int>> neighbors = [];
    final dirs = [const Point(0, 2), const Point(0, -2), const Point(2, 0), const Point(-2, 0)];
    for (final d in dirs) {
      final np = p + d;
      if (inMaze.contains(np)) {
        neighbors.add(np);
      }
    }
    return neighbors;
  }
}
