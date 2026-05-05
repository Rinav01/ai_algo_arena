import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:algo_arena/core/app_theme.dart';
import 'package:algo_arena/state/replay_provider.dart';

class ReplayControls extends ConsumerWidget {
  const ReplayControls({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(replayProvider);
    final notifier = ref.read(replayProvider.notifier);

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: AppTheme.ambientPanel(radius: 24).copyWith(
        border: Border.all(color: Colors.white.withValues(alpha: 0.1)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Playback Progress (Simple slider for seeking)
          Slider(
            value: state.currentStep.clamp(0, state.totalSteps).toDouble(),
            min: 0,
            max: state.totalSteps.toDouble(),
            onChanged: (v) => notifier.seek(v.toInt()),
            activeColor: AppTheme.accent,
            inactiveColor: AppTheme.surfaceHighest,
          ),
          const SizedBox(height: 10),
          Builder(
            builder: (context) {
              final isNarrow = MediaQuery.sizeOf(context).width < 480;
              
              if (isNarrow) {
                return Column(
                  children: [
                    // Main Playback Buttons (Center)
                    _buildPlaybackRow(state, notifier),
                    const SizedBox(height: 16),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        _SpeedSelector(
                          currentSpeed: state.speed,
                          onSpeedChanged: notifier.setSpeed,
                        ),
                        _HeuristicsToggle(
                          isActive: state.showHeuristics,
                          onToggle: notifier.toggleHeuristics,
                        ),
                      ],
                    ),
                  ],
                );
              }

              return Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  // Speed Control
                  _SpeedSelector(
                    currentSpeed: state.speed,
                    onSpeedChanged: notifier.setSpeed,
                  ),

                  // Main Playback Buttons
                  _buildPlaybackRow(state, notifier),

                  // Heuristics Toggle
                  _HeuristicsToggle(
                    isActive: state.showHeuristics,
                    onToggle: notifier.toggleHeuristics,
                  ),
                ],
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _buildPlaybackRow(dynamic state, dynamic notifier) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        _ReplayIconButton(
          icon: Icons.replay_rounded,
          onTap: notifier.reset,
        ),
        const SizedBox(width: 15),
        _PlayPauseButton(
          isPlaying: state.isPlaying,
          onTap: notifier.togglePlay,
        ),
        const SizedBox(width: 15),
        _ReplayIconButton(
          icon: Icons.skip_next_rounded,
          onTap: () {
            if (state.currentStep < state.totalSteps) {
              notifier.seek(state.currentStep + 1);
            }
          },
        ),
      ],
    );
  }
}

class _SpeedSelector extends StatelessWidget {
  final double currentSpeed;
  final ValueChanged<double> onSpeedChanged;

  const _SpeedSelector({
    required this.currentSpeed,
    required this.onSpeedChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 4),
      decoration: BoxDecoration(
        color: AppTheme.surfaceLow,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.white.withValues(alpha: 0.05)),
      ),
      child: Row(
        children: [1.0, 2.0, 4.0].map((speed) {
          final isSelected = speed == currentSpeed;
          return GestureDetector(
            onTap: () => onSpeedChanged(speed),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: isSelected ? AppTheme.accent : Colors.transparent,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                '${speed.toInt()}x',
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                  color: isSelected ? Colors.white : AppTheme.textMuted,
                ),
              ),
            ),
          );
        }).toList(),
      ),
    );
  }
}

class _PlayPauseButton extends StatelessWidget {
  final bool isPlaying;
  final VoidCallback onTap;

  const _PlayPauseButton({required this.isPlaying, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 60,
        height: 60,
        decoration: BoxDecoration(
          gradient: AppTheme.ctaGradient,
          shape: BoxShape.circle,
          boxShadow: [
            BoxShadow(
              color: AppTheme.accent.withValues(alpha: 0.4),
              blurRadius: 15,
              spreadRadius: 2,
            ),
          ],
        ),
        child: Icon(
          isPlaying ? Icons.pause_rounded : Icons.play_arrow_rounded,
          color: Colors.white,
          size: 35,
        ),
      ),
    );
  }
}

class _ReplayIconButton extends StatelessWidget {
  final IconData icon;
  final VoidCallback onTap;

  const _ReplayIconButton({required this.icon, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(10),
        decoration: AppTheme.glassCard(radius: 12),
        child: Icon(icon, color: AppTheme.onBackground, size: 22),
      ),
    );
  }
}

class _HeuristicsToggle extends StatelessWidget {
  final bool isActive;
  final VoidCallback onToggle;

  const _HeuristicsToggle({required this.isActive, required this.onToggle});

  @override
  Widget build(BuildContext context) {
    return Tooltip(
      message: 'HEURISTIC: Estimated cost to goal based on Manhattan distance',
      decoration: AppTheme.glassCard(radius: 8).copyWith(
        color: AppTheme.surfaceVariant.withValues(alpha: 0.95),
      ),
      textStyle: const TextStyle(color: Colors.white, fontSize: 12),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          GestureDetector(
            onTap: onToggle,
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 300),
              width: 48,
              height: 28,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(14),
                color: isActive ? AppTheme.accent.withValues(alpha: 0.2) : AppTheme.surfaceLow,
                border: Border.all(
                  color: isActive ? AppTheme.accent : Colors.white.withValues(alpha: 0.1),
                ),
                boxShadow: isActive ? [
                  BoxShadow(
                    color: AppTheme.accent.withValues(alpha: 0.3),
                    blurRadius: 10,
                    spreadRadius: 1,
                  )
                ] : null,
              ),
              child: Stack(
                children: [
                  AnimatedPositioned(
                    duration: const Duration(milliseconds: 200),
                    curve: Curves.easeOutBack,
                    left: isActive ? 22 : 4,
                    top: 4,
                    child: Container(
                      width: 18,
                      height: 18,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: isActive ? AppTheme.accent : AppTheme.textMuted,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 4),
          Text(
            'HEURISTICS',
            style: TextStyle(
              fontSize: 8,
              fontWeight: FontWeight.bold,
              letterSpacing: 0.5,
              color: isActive ? AppTheme.accentLight : AppTheme.textMuted,
            ),
          ),
        ],
      ),
    );
  }
}
