import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'dart:async';

class ReplayState {
  final bool isPlaying;
  final double speed;
  final bool showHeuristics;
  final int currentStep;
  final int totalSteps;

  ReplayState({
    this.isPlaying = false,
    this.speed = 1.0,
    this.showHeuristics = false,
    this.currentStep = 0,
    this.totalSteps = 0,
  });

  ReplayState copyWith({
    bool? isPlaying,
    double? speed,
    bool? showHeuristics,
    int? currentStep,
    int? totalSteps,
  }) {
    return ReplayState(
      isPlaying: isPlaying ?? this.isPlaying,
      speed: speed ?? this.speed,
      showHeuristics: showHeuristics ?? this.showHeuristics,
      currentStep: currentStep ?? this.currentStep,
      totalSteps: totalSteps ?? this.totalSteps,
    );
  }
}

class ReplayNotifier extends StateNotifier<ReplayState> {
  ReplayNotifier() : super(ReplayState());

  Timer? _timer;

  void togglePlay() {
    state = state.copyWith(isPlaying: !state.isPlaying);
    if (state.isPlaying) {
      _startPlayback();
    } else {
      _stopPlayback();
    }
  }

  void setSpeed(double speed) {
    state = state.copyWith(speed: speed);
    if (state.isPlaying) {
      _stopPlayback();
      _startPlayback();
    }
  }

  void toggleHeuristics() {
    state = state.copyWith(showHeuristics: !state.showHeuristics);
  }

  void reset() {
    _stopPlayback();
    state = state.copyWith(currentStep: 0, isPlaying: false);
  }

  void setTotalSteps(int total) {
    state = state.copyWith(totalSteps: total);
  }

  void seek(int step) {
    state = state.copyWith(currentStep: step);
  }

  void _startPlayback() {
    // Standard step interval at 1x is 500ms
    final targetIntervalMs = (500 / state.speed).round();
    
    if (targetIntervalMs >= 32) {
      // Normal speed: Tick every step
      _timer = Timer.periodic(Duration(milliseconds: targetIntervalMs), (timer) {
        if (state.currentStep < state.totalSteps) {
          state = state.copyWith(currentStep: state.currentStep + 1);
        } else {
          _stopPlayback();
          state = state.copyWith(isPlaying: false);
        }
      });
    } else {
      // High speed: Tick at 32ms and skip steps to maintain speed
      _timer = Timer.periodic(const Duration(milliseconds: 32), (timer) {
        final stepsToSkip = (32 / targetIntervalMs).round();
        final nextStep = (state.currentStep + stepsToSkip).clamp(0, state.totalSteps);
        
        state = state.copyWith(currentStep: nextStep);
        
        if (nextStep >= state.totalSteps) {
          _stopPlayback();
          state = state.copyWith(isPlaying: false);
        }
      });
    }
  }

  void _stopPlayback() {
    _timer?.cancel();
    _timer = null;
  }

  @override
  void dispose() {
    _stopPlayback();
    super.dispose();
  }
}

final replayProvider = StateNotifierProvider.autoDispose<ReplayNotifier, ReplayState>((ref) {
  return ReplayNotifier();
});
