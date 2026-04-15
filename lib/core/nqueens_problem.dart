import '../core/problem_definition.dart';

/// Position of a queen on the board
class QueenPosition {
  final int row;
  final int col;

  const QueenPosition(this.row, this.col);

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is QueenPosition &&
          runtimeType == other.runtimeType &&
          row == other.row &&
          col == other.col;

  @override
  int get hashCode => row.hashCode ^ col.hashCode;

  @override
  String toString() => 'Q($row,$col)';
}

/// Queens state: List of (row, col) for placed queens
/// Index represents queen number, value represents column
class QueensState {
  final List<int> placement; // placement[i] = column of queen in row i
  final int n; // board size

  const QueensState({required this.placement, required this.n});

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is QueensState &&
          runtimeType == other.runtimeType &&
          n == other.n &&
          _listEquals(placement, other.placement);

  bool _listEquals(List a, List b) {
    if (identical(a, b)) return true;
    if (a.length != b.length) return false;
    for (int i = 0; i < a.length; i++) {
      if (a[i] != b[i]) return false;
    }
    return true;
  }

  @override
  int get hashCode => placement.hashCode ^ n.hashCode;

  @override
  String toString() => 'QueensState($placement)';
}

/// N-Queens Problem
class NQueensProblem extends Problem<QueensState> {
  final int n;
  final List<int>? initialPlacement;

  NQueensProblem({required this.n, this.initialPlacement});

  @override
  QueensState get initialState =>
      QueensState(placement: initialPlacement ?? List.filled(n, -1), n: n);

  @override
  QueensState get goalState =>
      throw UnimplementedError('Goal state is implicit (all queens placed)');

  @override
  bool isGoal(QueensState state) {
    // All queens placed and no conflicts
    for (int i = 0; i < n; i++) {
      if (state.placement[i] == -1) return false;
    }
    return isSafe(state, n - 1, state.placement[n - 1]);
  }

  @override
  List<QueensState> getNeighbors(QueensState state) {
    final neighbors = <QueensState>[];

    // Find first row with unplaced queen
    int row = -1;
    for (int i = 0; i < n; i++) {
      if (state.placement[i] == -1) {
        row = i;
        break;
      }
    }

    // No more rows to fill (prune branches with conflicts)
    if (row == -1) return neighbors;

    // Try placing queen in each column of this row
    for (int col = 0; col < n; col++) {
      if (_canPlace(state, row, col)) {
        final newPlacement = [...state.placement];
        newPlacement[row] = col;
        neighbors.add(QueensState(placement: newPlacement, n: n));
      }
    }

    return neighbors;
  }

  @override
  bool isValid(QueensState state) {
    // Check if current placement is valid
    for (int i = 0; i < n; i++) {
      if (state.placement[i] != -1) {
        if (!isSafe(state, i, state.placement[i])) {
          return false;
        }
      }
    }
    return true;
  }

  @override
  String stateToString(QueensState state) {
    final queensPlaced = state.placement.where((c) => c != -1).length;
    return 'Queens: $queensPlaced/$n Placement: ${state.placement}';
  }

  /// Check if queen can be placed at (row, col)
  bool _canPlace(QueensState state, int row, int col) {
    // Check column
    for (int i = 0; i < row; i++) {
      if (state.placement[i] == col) return false;
    }

    // Check diagonals
    for (int i = 0; i < row; i++) {
      final placedCol = state.placement[i];
      if (placedCol != -1) {
        if ((row - i).abs() == (col - placedCol).abs()) return false;
      }
    }

    return true;
  }

  /// Check if queen at (row, col) is safe
  bool isSafe(QueensState state, int row, int col) {
    // Check column
    for (int i = 0; i < n; i++) {
      if (i != row && state.placement[i] == col) return false;
    }

    // Check diagonals
    for (int i = 0; i < n; i++) {
      if (i != row) {
        final placedCol = state.placement[i];
        if (placedCol != -1) {
          if ((row - i).abs() == (col - placedCol).abs()) return false;
        }
      }
    }

    return true;
  }

  /// Get board visualization
  String getBoardString(QueensState state) {
    final board = List.generate(n, (i) => List.filled(n, '.'));

    for (int row = 0; row < n; row++) {
      if (state.placement[row] != -1) {
        board[row][state.placement[row]] = 'Q';
      }
    }

    return board.map((row) => row.join(' ')).join('\n');
  }
}
