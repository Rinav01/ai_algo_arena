import 'dart:async';

import '../core/problem_definition.dart';

/// Controls execution of algorithm streams (pause, resume, step)
class AlgorithmExecutor<State> {
  final SearchAlgorithm<State> algorithm;
  final Problem<State> problem;

  late StreamSubscription<AlgorithmStep<State>> _subscription;
  final _stepController = StreamController<AlgorithmStep<State>>.broadcast();

  bool _isPaused = false;
  bool _isStopped = false;
  AlgorithmStep<State>? _lastStep;
  final _pauseCompleter = Completer<void>();

  /// Stream of algorithm steps
  Stream<AlgorithmStep<State>> get stepStream => _stepController.stream;

  /// Current execution state
  bool get isPaused => _isPaused;
  bool get isStopped => _isStopped;
  bool get isRunning => !_isPaused && !_isStopped;
  AlgorithmStep<State>? get lastStep => _lastStep;

  AlgorithmExecutor({
    required this.algorithm,
    required this.problem,
    int? stepDelayMs,
  });

  /// Start execution
  Future<void> start() async {
    if (_isStopped) {
      throw StateError('Cannot restart a stopped executor');
    }

    _subscription = algorithm
        .solve(problem)
        .listen(
          (step) {
            _lastStep = step;
            if (!_isPaused) {
              _stepController.add(step);
            }
          },
          onDone: () {
            _isStopped = true;
            _stepController.close();
          },
          onError: (error) {
            _stepController.addError(error);
          },
        );
  }

  /// Pause execution
  void pause() {
    if (isRunning) {
      _isPaused = true;
    }
  }

  /// Resume execution
  void resume() {
    if (_isPaused && !_isStopped) {
      _isPaused = false;
      // Emit last step if available
      if (_lastStep != null) {
        _stepController.add(_lastStep!);
      }
    }
  }

  /// Step once (requires being paused)
  void stepOnce() {
    if (_isPaused && _lastStep != null) {
      _stepController.add(_lastStep!);
    }
  }

  /// Stop execution
  Future<void> stop() async {
    _isStopped = true;
    await _subscription.cancel();
    await _stepController.close();
  }

  /// Cleanup
  Future<void> dispose() async {
    try {
      await stop();
    } catch (e) {
      // Already stopped or closed
    }
  }
}

/// Multi-algorithm executor for battles
class BattleExecutor {
  final AlgorithmExecutor algo1;
  final AlgorithmExecutor algo2;

  bool _isPaused = false;
  bool _isStopped = false;

  BattleExecutor({required this.algo1, required this.algo2});

  bool get isPaused => _isPaused;
  bool get isStopped => _isStopped;
  bool get isRunning => !_isPaused && !_isStopped;

  /// Start both algorithms simultaneously
  Future<void> start() async {
    await Future.wait([algo1.start(), algo2.start()]);
  }

  /// Pause both
  void pause() {
    if (isRunning) {
      _isPaused = true;
      algo1.pause();
      algo2.pause();
    }
  }

  /// Resume both
  void resume() {
    if (_isPaused && !_isStopped) {
      _isPaused = false;
      algo1.resume();
      algo2.resume();
    }
  }

  /// Step both once
  void stepOnce() {
    if (_isPaused && !_isStopped) {
      algo1.stepOnce();
      algo2.stepOnce();
    }
  }

  /// Stop both
  Future<void> stop() async {
    _isStopped = true;
    await Future.wait([algo1.stop(), algo2.stop()]);
  }

  /// Cleanup
  Future<void> dispose() async {
    await Future.wait([algo1.dispose(), algo2.dispose()]);
  }
}

/// Advanced executor with speed control
class AdvancedAlgorithmExecutor<State> extends AlgorithmExecutor<State> {
  double _speed = 1.0; // 1.0 = normal, 2.0 = 2x speed, 0.5 = 0.5x speed

  AdvancedAlgorithmExecutor({
    required SearchAlgorithm<State> algorithm,
    required Problem<State> problem,
  }) : super(algorithm: algorithm, problem: problem);

  /// Set playback speed multiplier
  void setSpeed(double speedMultiplier) {
    _speed = speedMultiplier.clamp(0.1, 5.0);
  }

  double get speed => _speed;
}
