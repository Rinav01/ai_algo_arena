import 'dart:math' as math;
import 'package:algo_arena/core/problem_definition.dart';
import 'package:collection/collection.dart';

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
          const ListEquality<int>().equals(tiles, other.tiles);

  @override
  int get hashCode => Object.hashAll(tiles);

  @override
  String toString() => 'PuzzleState(${tiles.join(",")})';

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
    // Manhattan distance summed for all non-empty tiles
    int distance = 0;
    for (int i = 0; i < 9; i++) {
      final value = state.tiles[i];
      if (value != 0) {
        // Current position
        final curR = i ~/ 3;
        final curC = i % 3;

        // Target position for value 'v' (assuming goal [1,2,3,4,5,6,7,8,0])
        final targetIdx = value - 1;
        final tarR = targetIdx ~/ 3;
        final tarC = targetIdx % 3;

        distance += (curR - tarR).abs() + (curC - tarC).abs();
      }
    }
    return distance.toDouble();
  }

  @override
  double moveCost(PuzzleState from, PuzzleState to) => 1.0;

  @override
  bool isValid(PuzzleState state) => true;

  @override
  Map<String, dynamic> toSnapshot() => {
    'type': 'puzzle',
    'initialState': _initialState.tiles,
  };

  static EightPuzzleProblem fromSnapshot(Map<String, dynamic> snapshot) {
    return EightPuzzleProblem(
      initialState: PuzzleState(List<int>.from(snapshot['initialState'])),
    );
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
    final random = math.Random();

    // To prevent immediate backtracking during the random walk
    PuzzleState? previousState;

    for (int i = 0; i < times; i++) {
      final neighbors = EightPuzzleProblem()._getNeighborsForState(state);

      // Filter out immediate backtracking if possible for a better scramble
      final validNeighbors = neighbors
          .where((n) => n != previousState)
          .toList();

      previousState = state;

      if (validNeighbors.isNotEmpty) {
        state = validNeighbors[random.nextInt(validNeighbors.length)];
      } else {
        state = neighbors[random.nextInt(neighbors.length)];
      }
    }

    // Since we generate via legal moves from the goal state,
    // it is mathematically guaranteed to be solvable!
    return state;
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
