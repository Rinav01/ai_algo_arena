import 'dart:async';
import 'dart:isolate';
import 'package:flutter/foundation.dart';

import '../core/problem_definition.dart';

/// Response message from the isolate
class _SolveResponse<State> {
  final List<AlgorithmStep<State>> history;
  final Set<State> finalExplored;
  final List<State> finalPath;

  _SolveResponse(this.history, this.finalExplored, this.finalPath);
}

/// Request message sent to the isolate
class _SolveRequest<State> {
  final SearchAlgorithm<State> algorithm;
  final Problem<State> problem;

  _SolveRequest(this.algorithm, this.problem);
}

/// The actual entry point for the isolate
_SolveResponse<State> _solveInIsolate<State>(_SolveRequest<State> request) {
  final history = request.algorithm.solve(request.problem).toList();
  final finalExplored = history.expand((s) => s.newlyExplored).toSet();
  final finalPath = history.isEmpty ? <State>[] : history.last.path;
  return _SolveResponse<State>(history, finalExplored, finalPath);
}

/// Controls execution of algorithm steps and manages playback via timer.
/// Now optimized to accumulate incremental steps into a full state and use caching.
class AlgorithmExecutor<State> with ChangeNotifier {
  final SearchAlgorithm<State> algorithm;
  final Problem<State> problem;
  
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

  // Result caching: Stores (History, Final Explored Set, Final Path)
  static final Map<String, (List<AlgorithmStep<dynamic>>, Set<dynamic>, List<dynamic>)> _resultCache = {};
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

  /// Current execution state
  bool get isPaused => _isPaused;
  bool get isStopped => _isStopped;
  bool get isComputing => _isComputing;
  bool get isRunning => _fullHistory != null && !_isPaused && !_isStopped && _currentIndex < _fullHistory!.length;
  AlgorithmStep<State>? get lastStep => _lastStep;

  /// Generate a cache key for the current problem and algorithm
  String get _cacheKey => '${algorithm.runtimeType}_${problem.hashCode}';

  AlgorithmExecutor({
    required this.algorithm,
    required this.problem,
    int? stepDelayMs,
  }) : _stepDelay = Duration(milliseconds: stepDelayMs ?? 16); // Default to roughly 60fps

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
      } else {
        // 1. Offload the search and the heavy set processing to a background isolate
        final response = await Isolate.run(
          () => _solveInIsolate(
            _SolveRequest<State>(algorithm, problem)
          )
        );
        
        _fullHistory = response.history;
        final finalExplored = response.finalExplored;
        final finalPath = response.finalPath;
        
        // Cache management: LRU-ish eviction
        if (_resultCache.length >= _maxCacheSize) {
          _resultCache.remove(_resultCache.keys.first);
        }
        
        _resultCache[cacheKey] = (_fullHistory!, finalExplored, finalPath);
        
        if (_stepDelay.inMilliseconds == 0) {
          _exploredSet.addAll(finalExplored);
          _currentPath = finalPath;
          _pathSet.addAll(_currentPath);
        }
      }
      
      _isComputing = false;
      notifyListeners();
      
      // 2. Start timeline playback
      if (!_isPaused && !_isStopped) {
        _startPlayback();
      }
    } catch (e) {
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
      stepsPerTick = (minDelay.inMicroseconds / _stepDelay.inMicroseconds).ceil();
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
        
        // Notify UI on the last step of the batch
        if (i == stepsPerTick - 1 || _currentIndex == _fullHistory!.length - 1) {
          _stepController.add(_lastStep!);
          notifyListeners();
        }
        
        _currentIndex++;
      }
      
      if (_currentIndex >= _fullHistory!.length) {
        _finishPlayback();
      }
    });
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
    if (_isPaused && _fullHistory != null && _currentIndex < _fullHistory!.length) {
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
  double _speed = 1.0; 
  final Duration _baseStepDelay;

  AdvancedAlgorithmExecutor({
    required super.algorithm,
    required super.problem,
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
        microseconds: (_baseStepDelay.inMicroseconds / _speed).round()
      );
    }
    
    // Restart timer with new speed if running
    if (isRunning && !isPaused) {
      _startPlayback();
    }
  }

  double get speed => _speed;
}
