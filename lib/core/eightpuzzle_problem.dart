import 'package:ai_algo_app/core/problem_definition.dart';

/// 8-Puzzle state: [0,1,2,3,4,5,6,7,8] where 0 = empty
/// Layout:
/// 0 1 2
/// 3 4 5
/// 6 7 8
class PuzzleState {
  final List<int> tiles; // 0 = empty space

  const PuzzleState(this.tiles);

  /// Get position of tile value
  int _getPosition(int value) {
    for (int i = 0; i < tiles.length; i++) {
      if (tiles[i] == value) return i;
    }
    return -1;
  }

  /// Get row and column for position
  (int, int) _getRowCol(int pos) {
    return (pos ~/ 3, pos % 3);
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is PuzzleState &&
          runtimeType == other.runtimeType &&
          _listEquals(tiles, other.tiles);

  bool _listEquals(List a, List b) {
    if (a.length != b.length) return false;
    for (int i = 0; i < a.length; i++) {
      if (a[i] != b[i]) return false;
    }
    return true;
  }

  @override
  int get hashCode => Object.hashAll(tiles);

  @override
  String toString() => 'PuzzleState(${tiles.join("")})';

  /// Get board visualization
  String toBoard() {
    final rows = <String>[];
    for (int i = 0; i < 3; i++) {
      final row = tiles.sublist(i * 3, (i + 1) * 3);
      rows.add(row.map((t) => t == 0 ? ' ' : t).join(' '));
    }
    return rows.join('\n');
  }
}

/// 8-Puzzle Problem
class EightPuzzleProblem extends Problem<PuzzleState> {
  static final defaultGoalState = PuzzleState([1, 2, 3, 4, 5, 6, 7, 8, 0]);
  static final initialExampleState = PuzzleState([0, 1, 2, 3, 4, 5, 6, 7, 8]);

  final PuzzleState _initialState;

  EightPuzzleProblem({PuzzleState? initialState})
    : _initialState = initialState ?? initialExampleState;

  @override
  PuzzleState get initialState => _initialState;

  @override
  PuzzleState get goalState => EightPuzzleProblem.defaultGoalState;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is EightPuzzleProblem &&
          runtimeType == other.runtimeType &&
          _initialState == other._initialState;

  @override
  int get hashCode => _initialState.hashCode;

  @override
  bool isGoal(PuzzleState state) => state == goalState;

  @override
  List<PuzzleState> getNeighbors(PuzzleState state) {
    final neighbors = <PuzzleState>[];
    final emptyPos = state._getPosition(0);
    final (row, col) = state._getRowCol(emptyPos);

    // Possible moves: up, down, left, right
    const directions = [
      (-1, 0), // up
      (1, 0), // down
      (0, -1), // left
      (0, 1), // right
    ];

    for (final (dRow, dCol) in directions) {
      final newRow = row + dRow;
      final newCol = col + dCol;

      if (newRow >= 0 && newRow < 3 && newCol >= 0 && newCol < 3) {
        // Create new state with tiles swapped
        final newPos = newRow * 3 + newCol;
        final newTiles = [...state.tiles];

        // Swap empty with neighbor
        final temp = newTiles[emptyPos];
        newTiles[emptyPos] = newTiles[newPos];
        newTiles[newPos] = temp;

        neighbors.add(PuzzleState(newTiles));
      }
    }

    return neighbors;
  }

  @override
  double heuristic(PuzzleState state) {
    // Manhattan distance heuristic
    int distance = 0;
    for (int i = 0; i < 9; i++) {
      if (state.tiles[i] != 0 && state.tiles[i] != i + 1) {
        final currentRow = i ~/ 3;
        final currentCol = i % 3;
        final goalRow = (state.tiles[i] - 1) ~/ 3;
        final goalCol = (state.tiles[i] - 1) % 3;
        distance += (currentRow - goalRow).abs() + (currentCol - goalCol).abs();
      }
    }
    return distance.toDouble();
  }

  @override
  String stateToString(PuzzleState state) {
    return state.toString();
  }

  /// Check if puzzle is solvable (use inversion count)
  static bool isSolvable(PuzzleState state) {
    int inversionCount = 0;
    for (int i = 0; i < 9; i++) {
      for (int j = i + 1; j < 9; j++) {
        if (state.tiles[i] > state.tiles[j] &&
            state.tiles[i] != 0 &&
            state.tiles[j] != 0) {
          inversionCount++;
        }
      }
    }
    return inversionCount % 2 == 0;
  }

  /// Scramble puzzle n times
  static PuzzleState scramble(int times) {
    PuzzleState state = defaultGoalState;
    final random = DateTime.now().millisecondsSinceEpoch;

    for (int i = 0; i < times; i++) {
      final neighbors = EightPuzzleProblem()._getNeighborsForState(state);
      state = neighbors[(random + i) % neighbors.length];
    }

    return isSolvable(state) ? state : scramble(times + 1);
  }

  List<PuzzleState> _getNeighborsForState(PuzzleState state) {
    // Same as getNeighbors but for scrambling
    final neighbors = <PuzzleState>[];
    final emptyPos = state._getPosition(0);
    final (row, col) = state._getRowCol(emptyPos);

    const directions = [(-1, 0), (1, 0), (0, -1), (0, 1)];

    for (final (dRow, dCol) in directions) {
      final newRow = row + dRow;
      final newCol = col + dCol;

      if (newRow >= 0 && newRow < 3 && newCol >= 0 && newCol < 3) {
        final newPos = newRow * 3 + newCol;
        final newTiles = [...state.tiles];
        final temp = newTiles[emptyPos];
        newTiles[emptyPos] = newTiles[newPos];
        newTiles[newPos] = temp;

        neighbors.add(PuzzleState(newTiles));
      }
    }

    return neighbors;
  }
}
