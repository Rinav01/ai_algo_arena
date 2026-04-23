import 'dart:async';

enum NQueensSolverMode {
  backtracking('Backtracking'),
  backtrackingMRV('Backtracking + MRV'),
  forwardChecking('Forward Checking');

  final String label;
  const NQueensSolverMode(this.label);
}

class NQueensStep {
  final List<int> board;
  final int currentRow;
  final int steps;
  final int backtracks;
  final bool isSolved;
  final int? lastColumnTried;
  final bool isBacktracking;
  final List<int>? activeConflicts;

  NQueensStep({
    required this.board,
    required this.currentRow,
    required this.steps,
    required this.backtracks,
    this.isSolved = false,
    this.lastColumnTried,
    this.isBacktracking = false,
    this.activeConflicts,
  });
}

class NQueensSolver {
  final int n;
  final NQueensSolverMode mode;
  final Duration stepDelay;

  final _controller = StreamController<NQueensStep>.broadcast();
  Stream<NQueensStep> get stepStream => _controller.stream;

  bool _isPaused = false;
  bool _isStopped = false;
  bool _isStepping = false;
  Completer<void>? _pauseCompleter;
  Completer<void>? _stepCompleter;

  int _steps = 0;
  int _backtracks = 0;

  NQueensSolver({
    required this.n,
    required this.mode,
    this.stepDelay = const Duration(milliseconds: 100),
  });

  Future<void> solve() async {
    final board = List<int>.filled(n, -1);
    final domains = List.generate(n, (_) => List.generate(n, (i) => i));

    await _backtrack(board, 0, domains);

    if (!_isStopped) {
      _controller.add(
        NQueensStep(
          board: List.from(board),
          currentRow: n,
          steps: _steps,
          backtracks: _backtracks,
          isSolved: board.every((c) => c != -1),
        ),
      );
    }

    await _controller.close();
  }

  Future<bool> _backtrack(
    List<int> board,
    int queensPlaced,
    List<List<int>> domains,
  ) async {
    if (_isStopped) return false;
    if (queensPlaced == n) return true;

    // Find next row to assign
    int row = -1;
    if (mode == NQueensSolverMode.backtrackingMRV ||
        mode == NQueensSolverMode.forwardChecking) {
      int minDomainSize = n + 1;
      for (int i = 0; i < n; i++) {
        if (board[i] == -1) {
          int domainSize = domains[i].length;
          if (domainSize < minDomainSize) {
            minDomainSize = domainSize;
            row = i;
          }
        }
      }
    } else {
      // Basic backtracking: find first empty row
      for (int i = 0; i < n; i++) {
        if (board[i] == -1) {
          row = i;
          break;
        }
      }
    }

    if (row == -1) return true;

    // Wait if paused or stepping
    if (_isPaused || _isStepping) {
      if (_isStepping) {
        _stepCompleter = Completer<void>();
        await _stepCompleter!.future;
      } else {
        _pauseCompleter = Completer<void>();
        await _pauseCompleter!.future;
      }
    }

    final currentDomain = List<int>.from(domains[row]);

    for (final col in currentDomain) {
      if (_isStopped) return false;

      _steps++;
      board[row] = col;

      // Emit step
      _controller.add(
        NQueensStep(
          board: List.from(board),
          currentRow: row,
          steps: _steps,
          backtracks: _backtracks,
          lastColumnTried: col,
        ),
      );

      await Future.delayed(stepDelay);

      if (_isSafe(board, row, col)) {
        List<List<int>> nextDomains = domains;
        bool possible = true;

        if (mode == NQueensSolverMode.forwardChecking) {
          nextDomains = _forwardCheck(board, row, col, domains);
          // Check for empty domains in unplaced rows
          for (int i = 0; i < n; i++) {
            if (board[i] == -1 && nextDomains[i].isEmpty) {
              possible = false;
              break;
            }
          }
        }

        if (possible) {
          if (await _backtrack(board, queensPlaced + 1, nextDomains)) {
            return true;
          }
        }
      }

      // Backtrack
      _backtracks++;
      board[row] = -1;
      _controller.add(
        NQueensStep(
          board: List.from(board),
          currentRow: row,
          steps: _steps,
          backtracks: _backtracks,
          isBacktracking: true,
        ),
      );
      await Future.delayed(stepDelay);

      if (_isPaused) {
        _pauseCompleter = Completer<void>();
        await _pauseCompleter!.future;
      }
    }

    return false;
  }

  bool _isSafe(List<int> board, int row, int col) {
    for (int i = 0; i < n; i++) {
      if (i == row || board[i] == -1) continue;

      int otherCol = board[i];
      if (otherCol == col) return false; // same column
      if ((row - i).abs() == (col - otherCol).abs()) return false; // diagonal
    }
    return true;
  }

  List<List<int>> _forwardCheck(
    List<int> board,
    int row,
    int col,
    List<List<int>> currentDomains,
  ) {
    List<List<int>> newDomains = currentDomains
        .map((d) => List<int>.from(d))
        .toList();

    for (int r = row + 1; r < n; r++) {
      newDomains[r].removeWhere(
        (c) => c == col || (r - row).abs() == (c - col).abs(),
      );
    }

    return newDomains;
  }

  void pause() {
    _isPaused = true;
    _isStepping = false;
  }

  void resume() {
    _isPaused = false;
    _isStepping = false;
    _pauseCompleter?.complete();
    _stepCompleter?.complete();
  }

  void enableStepping() {
    _isStepping = true;
    _isPaused = false;
  }

  void step() {
    if (_isStepping) {
      _stepCompleter?.complete();
    }
  }

  void stop() {
    _isStopped = true;
    _pauseCompleter?.complete();
  }
}
