import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:algo_arena/core/problem_definition.dart';
import 'package:algo_arena/services/algorithm_executor.dart';
import 'package:algo_arena/core/search_algorithms.dart';
import 'package:fl_chart/fl_chart.dart';

mixin VisualizerBaseMixin<T extends ConsumerStatefulWidget, S> on ConsumerState<T>, SingleTickerProviderStateMixin<T> {
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
  
  DateTime lastUiUpdate = DateTime.now();

  @override
  void initState() {
    super.initState();
    pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    );
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
      problemSnapshot: getProblemSnapshot(),
      stepDelayMs: isLiveUpdate ? 0 : stepDelay.inMilliseconds,
    );

    try {
      await executor!.start();
      stepSubscription = executor!.stepStream.listen(
        (step) {
          if (!mounted) return;
          
          _handleStep(step, isLiveUpdate);
        },
        onDone: () {
          if (mounted) {
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

  void _handleStep(AlgorithmStep<S> step, bool isLiveUpdate) {
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

    // Performance Optimization: Throttle UI updates
    final now = DateTime.now();
    if (isLiveUpdate || step.isGoalReached || now.difference(lastUiUpdate) >= const Duration(milliseconds: 32)) {
      lastUiUpdate = now;
      setState(() {});
    }
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
