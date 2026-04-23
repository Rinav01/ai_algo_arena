import 'dart:async';
import 'dart:isolate';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

import 'package:algo_arena/core/grid_problem.dart';
import 'package:algo_arena/core/problem_definition.dart';
import 'package:algo_arena/core/search_algorithms.dart';
import 'package:algo_arena/models/app_settings.dart';

/// Messaging for real-time streaming from isolates (Batched for performance)
class _StreamMessage<State> {
  final List<AlgorithmStep<State>>? batch;
  final bool isDone;
  final String? error;

  _StreamMessage.batch(this.batch) : isDone = false, error = null;
  _StreamMessage.done() : batch = null, isDone = true, error = null;
  _StreamMessage.error(this.error) : batch = null, isDone = false;
}

/// Request message sent to the isolate for streaming
class _StreamRequest {
  final SendPort sendPort;
  final String algorithmId;
  final Map<String, dynamic> snapshot;

  _StreamRequest(this.sendPort, this.algorithmId, this.snapshot);
}

/// The actual entry point for the isolate (Streaming version)
Future<void> _streamInIsolate(_StreamRequest request) async {
  try {
    final problem = GridProblem.fromSnapshot(request.snapshot);

    // Instantiate the algorithm inside the isolate to avoid non-sendable object issues
    final SearchAlgorithm<GridCoordinate> algorithm = switch (request
        .algorithmId) {
      'Breadth-First Search' => BFSAlgorithm<GridCoordinate>(),
      'Depth-First Search' => DFSAlgorithm<GridCoordinate>(),
      'Dijkstra\'s Algorithm' => DijkstraAlgorithm<GridCoordinate>(),
      'A* Search' => AStarAlgorithm<GridCoordinate>(),
      'Greedy Best-First Search' => GreedyBestFirstAlgorithm<GridCoordinate>(),
      _ => throw Exception('Unknown algorithm ID: ${request.algorithmId}'),
    };

    final List<AlgorithmStep<GridCoordinate>> buffer = [];
    const int batchSize = 100;

    for (final step in algorithm.solve(problem)) {
      buffer.add(step);
      if (buffer.length >= batchSize) {
        request.sendPort.send(
          _StreamMessage<GridCoordinate>.batch(List.from(buffer)),
        );
        buffer.clear();
      }
    }

    if (buffer.isNotEmpty) {
      request.sendPort.send(_StreamMessage<GridCoordinate>.batch(buffer));
    }
    request.sendPort.send(_StreamMessage<GridCoordinate>.done());
  } catch (e) {
    request.sendPort.send(_StreamMessage<GridCoordinate>.error(e.toString()));
  }
}

/// Controls execution of algorithm steps and manages playback via timer.
/// Now optimized to accumulate incremental steps into a full state and use caching.
class AlgorithmExecutor<State> with ChangeNotifier {
  final SearchAlgorithm<State> algorithm;
  final Problem<State>? _problem;
  final Map<String, dynamic>? _problemSnapshot;

  Duration _stepDelay;

  final _stepController = StreamController<AlgorithmStep<State>>.broadcast();

  List<AlgorithmStep<State>>? _fullHistory;
  int _currentIndex = 0;
  Timer? _playbackTimer;

  bool _isPaused = false;
  bool _isStopped = false;
  bool _isComputing = false;

  AlgorithmStep<State>? _lastStep;

  // Cumulative state tracked during playback for UI performance
  final Set<State> _exploredSet = {};
  final Set<State> _pathSet = {};
  List<State> _currentPath = [];
  int _frontierSize = 0;

  // Result caching: Stores (History, Final Explored Set, Final Path)
  static final Map<
    String,
    (List<AlgorithmStep<dynamic>>, Set<dynamic>, List<dynamic>)
  >
  _resultCache = {};
  static const int _maxCacheSize = 50;

  /// Stream of algorithm steps played back over time
  Stream<AlgorithmStep<State>> get stepStream => _stepController.stream;

  /// Full precomputed history (available after computing finishes)
  List<AlgorithmStep<State>>? get history => _fullHistory;

  /// Get cumulative explored set
  Set<State> get exploredSet => _exploredSet;

  /// Get current path as a set for O(1) lookup
  Set<State> get pathSet => _pathSet;

  /// Get current path as a list for ordered traversal if needed
  List<State> get currentPath => _currentPath;

  /// Get current frontier size
  int get frontierSize => _frontierSize;

  /// Current execution state
  bool get isPaused => _isPaused;
  bool get isStopped => _isStopped;
  bool get isComputing => _isComputing;
  bool get isRunning =>
      _fullHistory != null &&
      !_isPaused &&
      !_isStopped &&
      _currentIndex < _fullHistory!.length;
  AlgorithmStep<State>? get lastStep => _lastStep;

  /// Generate a cache key for the current problem and algorithm
  String get _cacheKey {
    if (_problemSnapshot != null) {
      final tempProblem = GridProblem.fromSnapshot(_problemSnapshot);
      return '${algorithm.runtimeType}_${tempProblem.hashCode}';
    }
    return '${algorithm.runtimeType}_${_problem.hashCode}';
  }

  AlgorithmExecutor({
    required this.algorithm,
    Problem<State>? problem,
    Map<String, dynamic>? problemSnapshot,
    int? stepDelayMs,
  }) : _problem = problem,
       _problemSnapshot = problemSnapshot,
       _stepDelay = Duration(milliseconds: stepDelayMs ?? 50) {
    assert(
      _problem != null || _problemSnapshot != null,
      'Either problem or problemSnapshot must be provided',
    );
  }

  /// Start execution: compute via isolate, then start playback
  Future<void> start() async {
    if (_isStopped) {
      throw StateError('Cannot restart a stopped executor');
    }

    _isComputing = true;
    _currentIndex = 0;
    _exploredSet.clear();
    _currentPath = [];

    try {
      final cacheKey = _cacheKey;
      if (_resultCache.containsKey(cacheKey)) {
        final cached = _resultCache[cacheKey]!;
        _fullHistory = cached.$1.cast<AlgorithmStep<State>>();
        // If instant playback is requested, we can use the cached sets directly
        if (_stepDelay.inMilliseconds == 0) {
          _exploredSet.addAll(cached.$2.cast<State>());
          _currentPath = cached.$3.cast<State>();
          _pathSet.addAll(_currentPath);
        }
      } else if (_problemSnapshot != null) {
        // 1. Offload the search to a background isolate and stream results
        _fullHistory = [];
        final receivePort = ReceivePort();

        final request = _StreamRequest(
          receivePort.sendPort,
          algorithm.name,
          _problemSnapshot,
        );

        await Isolate.spawn(_streamInIsolate, request);

        // Listen to the stream and collect history while playback happens
        final completer = Completer<void>();
        receivePort.listen((message) {
          final streamMsg = message as _StreamMessage<State>;

          if (streamMsg.error != null) {
            _stepController.addError(streamMsg.error!);
            receivePort.close();
            completer.complete();
          } else if (streamMsg.isDone) {
            _isComputing = false;
            notifyListeners();
            receivePort.close();

            // Cache the finished result
            if (_fullHistory != null && _fullHistory!.isNotEmpty) {
              final finalStep = _fullHistory!.last;
              final finalExplored = _fullHistory!
                  .expand((s) => s.newlyExplored)
                  .toSet();

              if (_resultCache.length >= _maxCacheSize) {
                _resultCache.remove(_resultCache.keys.first);
              }
              _resultCache[cacheKey] = (
                _fullHistory!,
                finalExplored,
                finalStep.path,
              );
            }

            completer.complete();
          } else if (streamMsg.batch != null) {
            _fullHistory!.addAll(streamMsg.batch!);

            // Start playback immediately if not yet started
            if (_playbackTimer == null && !_isStopped && !_isPaused) {
              _startPlayback();
            }
          }
        });

        // Wait for the computation to fully finish
        await completer.future;
      } else if (_problem != null) {
        // 2. Fallback: Compute locally for non-snapshottable problems (e.g. Puzzles)
        // These are typically fast enough to run on the main thread for the visualization depths used
        _fullHistory = algorithm.solve(_problem).toList();

        // Cache the finished result
        if (_fullHistory!.isNotEmpty) {
          final finalStep = _fullHistory!.last;
          final finalExplored = _fullHistory!
              .expand((s) => s.newlyExplored)
              .toSet();

          if (_resultCache.length >= _maxCacheSize) {
            _resultCache.remove(_resultCache.keys.first);
          }
          _resultCache[cacheKey] = (
            _fullHistory!,
            finalExplored,
            finalStep.path,
          );
        }
      }

      _isComputing = false;

      // 2. Start timeline playback if not already running
      if (!_isPaused && !_isStopped && _playbackTimer == null) {
        _startPlayback();
      } else {
        // Just notify that computation is done so UI can show final stats
        notifyListeners();
      }
    } catch (e, stack) {
      debugPrint('Error starting executor: $e\n$stack');
      _isComputing = false;
      _stepController.addError(e);
      _isStopped = true;
      notifyListeners();
    }
  }

  void _startPlayback() {
    _playbackTimer?.cancel();

    if (_stepDelay.inMilliseconds == 0) {
      if (_fullHistory != null && _fullHistory!.isNotEmpty) {
        // Explored and Path already handled in start() for efficiency
        _currentIndex = _fullHistory!.length - 1;
        _lastStep = _fullHistory![_currentIndex];
        _frontierSize = _lastStep!.frontierSize ?? 0;
        _stepController.add(_lastStep!);
        notifyListeners();
      }
      _finishPlayback();
      return;
    }

    // Throttling Logic: If delay is too short, we process multiple steps per tick
    final minDelay = const Duration(milliseconds: 16);
    final Duration timerDuration;
    final int stepsPerTick;

    if (_stepDelay < minDelay) {
      timerDuration = minDelay;
      stepsPerTick = (minDelay.inMicroseconds / _stepDelay.inMicroseconds)
          .ceil();
    } else {
      timerDuration = _stepDelay;
      stepsPerTick = 1;
    }

    _playbackTimer = Timer.periodic(timerDuration, (timer) {
      if (_isPaused || _isStopped) {
        timer.cancel();
        return;
      }

      if (_fullHistory == null || _currentIndex >= _fullHistory!.length) {
        _finishPlayback();
        return;
      }

      // Batch process steps for performance
      for (int i = 0; i < stepsPerTick; i++) {
        if (_currentIndex >= _fullHistory!.length) break;

        _lastStep = _fullHistory![_currentIndex];
        _exploredSet.addAll(_lastStep!.newlyExplored);
        _currentPath = _lastStep!.path;
        _pathSet.clear();
        _pathSet.addAll(_currentPath);
        _frontierSize = _lastStep!.frontierSize ?? 0;

        // Notify UI on the last step of the batch
        if (i == stepsPerTick - 1 ||
            _currentIndex == _fullHistory!.length - 1) {
          _stepController.add(_lastStep!);
          _handleHaptics();
          notifyListeners();
        }

        _currentIndex++;
      }

      if (_currentIndex >= _fullHistory!.length) {
        _finishPlayback();
      }
    });
  }

  void _handleHaptics() {
    if (_lastStep == null) return;

    // Get settings from snapshot or problem
    AppSettings settings = const AppSettings();
    if (_problemSnapshot != null && _problemSnapshot.containsKey('settings')) {
      settings = AppSettings.fromJson(_problemSnapshot['settings']);
    } else if (_problem is GridProblem) {
      settings = (_problem as GridProblem).settings;
    }

    if (settings.executionPulse && _currentIndex % 5 == 0) {
      HapticFeedback.lightImpact();
    }

    if (settings.collisionVibration && _lastStep!.isGoalReached) {
      HapticFeedback.mediumImpact();
    }
  }

  void _finishPlayback() {
    _playbackTimer?.cancel();
    _isStopped = true;
    _stepController.close();
  }

  /// Pause playback
  void pause() {
    if (isRunning) {
      _isPaused = true;
      _playbackTimer?.cancel();
    }
  }

  /// Resume playback
  void resume() {
    if (_isPaused && !_isStopped && _fullHistory != null) {
      _isPaused = false;
      _startPlayback();
    }
  }

  /// Step once (requires being paused)
  void stepOnce() {
    if (_isPaused &&
        _fullHistory != null &&
        _currentIndex < _fullHistory!.length) {
      _lastStep = _fullHistory![_currentIndex];
      _exploredSet.addAll(_lastStep!.newlyExplored);
      _currentPath = _lastStep!.path;
      _pathSet.clear();
      _pathSet.addAll(_currentPath);
      _stepController.add(_lastStep!);
      _currentIndex++;
      notifyListeners();
    }
  }

  /// Stop execution instantly
  Future<void> stop() async {
    _isStopped = true;
    _playbackTimer?.cancel();
    if (!_stepController.isClosed) {
      await _stepController.close();
    }
  }

  @override
  Future<void> dispose() async {
    try {
      await stop();
    } catch (e) {
      // Already stopped or closed
    }
    super.dispose();
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

  /// Start both algorithms with a staggered delay to avoid memory spikes
  Future<void> start() async {
    await algo1.start();
    // Staggered startup to prevent simultaneous Isolate initialization spikes
    await Future.delayed(const Duration(milliseconds: 100));
    await algo2.start();
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
  double _speed = 1.0;
  final Duration _baseStepDelay;

  AdvancedAlgorithmExecutor({
    required super.algorithm,
    super.problem,
    super.problemSnapshot,
    super.stepDelayMs,
  }) : _baseStepDelay = Duration(milliseconds: stepDelayMs ?? 16);

  /// Set playback speed multiplier
  void setSpeed(double speedMultiplier) {
    _speed = speedMultiplier.clamp(0.1, 5.0);
    // Adjust internal step delay dynamically
    if (_speed >= 4.9) {
      // essentially instant mode at max speed slider
      _stepDelay = Duration.zero;
    } else {
      _stepDelay = Duration(
        microseconds: (_baseStepDelay.inMicroseconds / _speed).round(),
      );
    }

    // Restart timer with new speed if running
    if (isRunning && !isPaused) {
      _startPlayback();
    }
  }

  double get speed => _speed;
}
