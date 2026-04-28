import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:algo_arena/core/problem_definition.dart';
import 'package:algo_arena/services/algorithm_executor.dart';
import 'package:algo_arena/core/search_algorithms.dart';
import 'package:fl_chart/fl_chart.dart';

mixin VisualizerBaseMixin<T extends ConsumerStatefulWidget, S> on ConsumerState<T>, TickerProvider {
  // --- Abstract Methods ---
  String get algorithmId;
  Map<String, dynamic> getProblemSnapshot();
  Future<void> onGoalReached(AlgorithmStep<S> step);
  Future<void> onStep(AlgorithmStep<S> step);
  Future<void> onAutoSave();

  // --- Common State ---
  AlgorithmExecutor<S>? executor;
  StreamSubscription<AlgorithmStep<S>>? stepSubscription;
  late AnimationController pulseController;
  
  bool isSolving = false;
  bool isSolved = false;
  int nodesExplored = 0;
  int stepCount = 0;
  double executionSpeed = 1.0;
  String statusMessage = 'Ready to solve';
  List<FlSpot> perfData = [const FlSpot(0, 0)];

  // --- Hydration State ---
  bool isShellReady = false;
  bool isGridReady = false;
  
  /// Prevents animations from starting during the "Cold Start" window
  bool get shouldAnimate => isGridReady;

  // Vsync-based throttle: buffer the latest step and flush once per frame
  AlgorithmStep<S>? _pendingStep;
  bool _frameCallbackScheduled = false;

  @override
  void initState() {
    super.initState();
    pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    );

    // Stage 1: Shell Ready (Instant)
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) setState(() => isShellReady = true);
    });

    // Stage 2: Adaptive Hydration (Grid Ready)
    // Instead of fixed 800ms, we wait for the engine to stabilize.
    _trackFrameStability();
  }

  void _trackFrameStability() {
    int stableFrames = 0;
    const int stabilityThreshold = 5; // Require 5 consecutive stable frames
    
    // We also set a safety timeout (e.g. 2 seconds) just in case
    final safetyTimeout = Timer(const Duration(seconds: 2), () {
      if (mounted && !isGridReady) {
        setState(() => isGridReady = true);
      }
    });

    WidgetsBinding.instance.addPersistentFrameCallback((timeStamp) {
      if (!mounted || isGridReady) return;

      // Heuristic: If we are rendering under 16ms, we have overhead budget
      // Note: SchedulerBinding.instance.currentFrameTimeStamp is better for this
      
      // Since we don't have direct access to the *last* frame time here easily 
      // without extra plumbing, we'll use a simpler heuristic: 
      // Wait for the first few frames after navigation to complete.
      stableFrames++;
      
      if (stableFrames >= stabilityThreshold) {
        safetyTimeout.cancel();
        setState(() => isGridReady = true);
      }
    });
  }

  @override
  void dispose() {
    executor?.stop();
    stepSubscription?.cancel();
    executor?.dispose();
    pulseController.dispose();
    super.dispose();
  }

  Duration get stepDelay {
    final ms = (180 / executionSpeed).round().clamp(10, 1800);
    return Duration(milliseconds: ms);
  }

  Future<void> solve({bool isLiveUpdate = false}) async {
    if (isSolving && !isLiveUpdate) return;

    setState(() {
      if (!isLiveUpdate) {
        isSolving = true;
        isSolved = false;
        statusMessage = 'Running $algorithmId...';
        pulseController.repeat(reverse: true);
      }
      stepCount = 0;
      nodesExplored = 0;
      perfData = [const FlSpot(0, 0)];
    });

    final algo = AlgorithmRegistry.create<S>(algorithmId);

    await executor?.dispose();
    await stepSubscription?.cancel();

    executor = AlgorithmExecutor<S>(
      algorithm: algo,
      algorithmId: algorithmId,
      problemSnapshot: getProblemSnapshot(),
      stepDelayMs: isLiveUpdate ? 0 : stepDelay.inMilliseconds,
    );

    try {
      // Small delay to ensure UI updates (like button state) are rendered 
      // before blocking the thread with Isolate initialization
      await Future.delayed(Duration.zero);
      await executor!.start();
      stepSubscription = executor!.stepStream.listen(
        (step) {
          if (!mounted) return;

          // Buffer the step — only the latest one matters for UI.
          // Actual processing happens once per vsync via _flushPendingStep.
          _pendingStep = step;

          // Always process goal steps immediately to avoid missing them
          if (step.isGoalReached) {
            _flushPendingStep();
            return;
          }

          // Schedule a frame callback to process this step at the next vsync
          if (!_frameCallbackScheduled) {
            _frameCallbackScheduled = true;
            SchedulerBinding.instance.addPostFrameCallback((_) {
              _frameCallbackScheduled = false;
              if (mounted && _pendingStep != null) {
                _flushPendingStep();
              }
            });
          }
        },
        onDone: () {
          if (mounted) {
            // Flush any remaining step before marking done
            if (_pendingStep != null) {
              _flushPendingStep();
            }
            setState(() {
              isSolving = false;
              pulseController.stop();
            });
            onAutoSave();
          }
        },
      );
    } catch (e) {
      if (mounted) {
        setState(() {
          isSolving = false;
          pulseController.stop();
          statusMessage = 'Error: $e';
        });
      }
    }
  }

  /// Process the buffered step and update UI exactly once.
  void _flushPendingStep() {
    final step = _pendingStep;
    if (step == null) return;
    _pendingStep = null;

    stepCount = step.stepCount;
    nodesExplored = executor!.exploredSet.length;
    statusMessage = step.message ?? statusMessage;

    if (stepCount % 20 == 0) {
      perfData.add(FlSpot(stepCount.toDouble(), nodesExplored.toDouble()));
    }

    onStep(step);

    if (step.isGoalReached) {
      isSolved = true;
      isSolving = false;
      pulseController.stop();
      perfData.add(FlSpot(stepCount.toDouble(), nodesExplored.toDouble()));
      onGoalReached(step);
    }

    setState(() {});
  }

  void pauseResume() {
    if (isSolving) {
      executor?.pause();
      pulseController.stop();
      setState(() {
        isSolving = false;
        statusMessage = 'Paused';
      });
    } else if (stepCount > 0) {
      executor?.resume();
      pulseController.repeat(reverse: true);
      setState(() {
        isSolving = true;
        statusMessage = 'Resumed';
      });
    }
  }

  void resetBase() {
    executor?.stop();
    pulseController.stop();
    stepSubscription?.cancel();
    stepSubscription = null;
    executor = null;
    _pendingStep = null;
    _frameCallbackScheduled = false;
    setState(() {
      stepCount = 0;
      nodesExplored = 0;
      isSolving = false;
      isSolved = false;
      statusMessage = 'Ready to solve';
      perfData = [const FlSpot(0, 0)];
    });
  }
}
