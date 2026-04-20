/// Queens state: List of column indices for placed queens
/// Index represents row, value represents column (-1 if empty)
class QueensState {
  final List<int> placement;
  final int n;

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
  int get hashCode => Object.hash(Object.hashAll(placement), n);

  @override
  String toString() => 'QueensState($placement)';

  QueensState copyWith({List<int>? placement, int? n}) {
    return QueensState(
      placement: placement ?? List.from(this.placement),
      n: n ?? this.n,
    );
  }
}

/// N-Queens Utility class for validation and safety checks
class NQueensUtils {
  /// Check if queen at (row, col) is safe given the current board
  static bool isSafe(List<int> board, int row, int col) {
    int n = board.length;
    
    // Check column
    for (int i = 0; i < n; i++) {
      if (i != row && board[i] == col) return false;
    }

    // Check diagonals
    for (int i = 0; i < n; i++) {
      if (i != row) {
        final placedCol = board[i];
        if (placedCol != -1) {
          if ((row - i).abs() == (col - placedCol).abs()) return false;
        }
      }
    }

    return true;
  }

  /// Check if the entire board is in a goal state
  static bool isGoal(QueensState state) {
    for (int i = 0; i < state.n; i++) {
      if (state.placement[i] == -1) return false;
      if (!isSafe(state.placement, i, state.placement[i])) return false;
    }
    return true;
  }
}
