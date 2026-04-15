import 'dart:ui';
import 'package:flutter/material.dart';
import '../core/app_theme.dart';
import '../widgets/animated_number_display.dart';

/// Reusable glassmorphism stat card used in visualizers.
class GlassStatCard extends StatelessWidget {
  const GlassStatCard({
    super.key,
    required this.label,
    required this.value,
  });

  final String label;
  final dynamic value;

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(12),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
        child: Container(
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: 0.04),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: Colors.white.withValues(alpha: 0.08)),
          ),
          child: Row(
            children: [
              // Left accent bar — separate child so borderRadius still works
              Container(
                width: 3,
                decoration: const BoxDecoration(
                  color: AppTheme.accent,
                  borderRadius: BorderRadius.only(
                    topLeft: Radius.circular(12),
                    bottomLeft: Radius.circular(12),
                  ),
                ),
              ),
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(11, 14, 12, 14),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        label,
                        style: Theme.of(context).textTheme.labelSmall?.copyWith(
                              color: AppTheme.textSecondary,
                              letterSpacing: 1.2,
                            ),
                      ),
                      const SizedBox(height: 6),
                      value is int ? AnimatedNumberDisplay(
                        value: value as int,
                        duration: const Duration(milliseconds: 600),
                        curve: Curves.easeOutCubic,
                        textStyle: const TextStyle(
                          fontSize: 22,
                          fontWeight: FontWeight.w800,
                          color: AppTheme.onBackground,
                          fontFamily: 'Inter',
                        ),
                      ) : Text(
                        value.toString(),
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w800,
                          color: AppTheme.onBackground,
                          fontFamily: 'Inter',
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}


/// Status banner pill with colored dot indicator.
class StatusBanner extends StatelessWidget {
  const StatusBanner({
    super.key,
    required this.message,
    required this.isSolved,
    required this.isSolving,
  });

  final String message;
  final bool isSolved;
  final bool isSolving;

  Color get _dotColor {
    if (isSolved) return AppTheme.success;
    if (isSolving) return AppTheme.warning;
    return AppTheme.textSecondary;
  }

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(30),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: 0.04),
            borderRadius: BorderRadius.circular(30),
            border: Border.all(
              color: isSolved
                  ? AppTheme.success.withValues(alpha: 0.45)
                  : isSolving
                      ? AppTheme.warning.withValues(alpha: 0.45)
                      : Colors.white.withValues(alpha: 0.10),
            ),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 8,
                height: 8,
                decoration: BoxDecoration(
                  color: _dotColor,
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(
                      color: _dotColor.withValues(alpha: 0.6),
                      blurRadius: 6,
                      spreadRadius: 1,
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 10),
              Flexible(
                child: Text(
                  message,
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: isSolved
                            ? AppTheme.success
                            : isSolving
                                ? AppTheme.warning
                                : AppTheme.textSecondary,
                      ),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Legend row showing cell color meanings.
class GridLegend extends StatelessWidget {
  const GridLegend({
    super.key,
    required this.exploredColor,
    required this.pathColor,
  });

  final Color exploredColor;
  final Color pathColor;

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(12),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          decoration: AppTheme.glassCard(radius: 12),
          child: Wrap(
            spacing: 16,
            runSpacing: 10,
            alignment: WrapAlignment.center,
            children: [
              _LegendDot(color: AppTheme.cellStart, label: 'Start'),
              _LegendDot(color: AppTheme.cellGoal, label: 'Goal'),
              _LegendDot(color: AppTheme.cellWall.withValues(alpha: 1), label: 'Wall'),
              _LegendDot(color: exploredColor, label: 'Explored'),
              _LegendDot(color: pathColor, label: 'Path'),
            ],
          ),
        ),
      ),
    );
  }
}

class _LegendDot extends StatelessWidget {
  const _LegendDot({required this.color, required this.label});
  final Color color;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 10,
          height: 10,
          decoration: BoxDecoration(
            color: color,
            borderRadius: BorderRadius.circular(3),
          ),
        ),
        const SizedBox(width: 6),
        Text(label, style: Theme.of(context).textTheme.bodySmall),
      ],
    );
  }
}

/// Visualizer header with back button and title.
class VisualizerHeader extends StatelessWidget {
  const VisualizerHeader({
    super.key,
    required this.title,
    required this.subtitle,
    this.onBackTap,
  });

  final String title;
  final String subtitle;
  final VoidCallback? onBackTap;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        GestureDetector(
          onTap: onBackTap ?? () => Navigator.pop(context),
          child: Container(
            width: 36,
            height: 36,
            decoration: AppTheme.glassCard(radius: 10),
            child: const Icon(
              Icons.arrow_back_ios_new_rounded,
              size: 16,
              color: AppTheme.onBackground,
            ),
          ),
        ),
        const SizedBox(width: 14),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      color: AppTheme.accent,
                    ),
              ),
              Text(
                subtitle,
                style: Theme.of(context).textTheme.labelMedium,
              ),
            ],
          ),
        ),
        Container(
          width: 36,
          height: 36,
          decoration: AppTheme.glassCard(radius: 10),
          child: const Icon(
            Icons.settings_rounded,
            size: 16,
            color: AppTheme.textSecondary,
          ),
        ),
      ],
    );
  }
}

/// Speed slider control.
class SpeedControl extends StatelessWidget {
  const SpeedControl({
    super.key,
    required this.speed,
    required this.isSolving,
    required this.onChanged,
  });

  final double speed;
  final bool isSolving;
  final ValueChanged<double> onChanged;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'SPEED: ${speed.toStringAsFixed(1)}x',
          style: Theme.of(context).textTheme.labelSmall?.copyWith(
                color: AppTheme.textSecondary,
                letterSpacing: 1.5,
              ),
        ),
        const SizedBox(height: 8),
        Slider(
          value: speed,
          min: 0.1,
          max: 5.0,
          onChanged: isSolving ? null : onChanged,
        ),
      ],
    );
  }
}

/// Control buttons row/grid for the visualizer.
class VisualizerControls extends StatelessWidget {
  const VisualizerControls({
    super.key,
    required this.isSolving,
    required this.isSolved,
    required this.stepCount,
    required this.onSolve,
    required this.onPauseResume,
    required this.onStep,
    required this.onReset,
    required this.onClear,
  });

  final bool isSolving;
  final bool isSolved;
  final int stepCount;
  final VoidCallback onSolve;
  final VoidCallback onPauseResume;
  final VoidCallback onStep;
  final VoidCallback onReset;
  final VoidCallback onClear;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        // Row 1: primary actions
        Row(
          children: [
            Expanded(
              flex: 3,
              child: _CtaButton(
                icon: Icons.play_arrow_rounded,
                label: 'Solve',
                enabled: !isSolving,
                primary: true,
                onTap: onSolve,
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              flex: 3,
              child: _CtaButton(
                icon: Icons.fast_forward_rounded,
                label: 'Auto',
                enabled: !isSolving,
                primary: false,
                onTap: onSolve,
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              flex: 2,
              child: _GhostBtn(
                icon: isSolving ? Icons.pause_rounded : Icons.play_arrow_rounded,
                label: isSolving ? 'Pause' : 'Resume',
                enabled: stepCount > 0,
                onTap: onPauseResume,
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        // Row 2: secondary actions
        Row(
          children: [
            Expanded(
              child: _GhostBtn(
                icon: Icons.skip_next_rounded,
                label: 'Step',
                enabled: stepCount > 0,
                onTap: onStep,
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: _GhostBtn(
                icon: Icons.refresh_rounded,
                label: 'Reset',
                enabled: true,
                onTap: onReset,
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: _GhostBtn(
                icon: Icons.delete_sweep_rounded,
                label: 'Clear',
                enabled: true,
                onTap: onClear,
                dangerColor: AppTheme.error,
              ),
            ),
          ],
        ),
      ],
    );
  }
}

class _CtaButton extends StatelessWidget {
  const _CtaButton({
    required this.icon,
    required this.label,
    required this.enabled,
    required this.primary,
    required this.onTap,
  });
  final IconData icon;
  final String label;
  final bool enabled;
  final bool primary;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return ElevatedButton.icon(
      onPressed: enabled ? onTap : null,
      style: ElevatedButton.styleFrom(
        backgroundColor: primary ? AppTheme.accent : AppTheme.surfaceHigh,
        foregroundColor: Colors.white,
        disabledBackgroundColor: AppTheme.surfaceHighest.withValues(alpha: 0.5),
        disabledForegroundColor: AppTheme.textSecondary,
        elevation: 0,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        padding: const EdgeInsets.symmetric(vertical: 13),
        side: primary
            ? null
            : BorderSide(color: Colors.white.withValues(alpha: 0.12)),
      ),
      icon: Icon(icon, size: 18),
      label: Text(
        label,
        style: const TextStyle(
          fontSize: 13,
          fontWeight: FontWeight.w700,
          fontFamily: 'Inter',
        ),
      ),
    );
  }
}

class _GhostBtn extends StatelessWidget {
  const _GhostBtn({
    required this.icon,
    required this.label,
    required this.enabled,
    required this.onTap,
    this.dangerColor,
  });
  final IconData icon;
  final String label;
  final bool enabled;
  final VoidCallback onTap;
  final Color? dangerColor;

  @override
  Widget build(BuildContext context) {
    final col = dangerColor ?? AppTheme.textSecondary;
    return OutlinedButton.icon(
      onPressed: enabled ? onTap : null,
      style: OutlinedButton.styleFrom(
        foregroundColor: col,
        side: BorderSide(
          color: enabled
              ? col.withValues(alpha: 0.5)
              : AppTheme.outline.withValues(alpha: 0.4),
        ),
        backgroundColor: Colors.white.withValues(alpha: 0.03),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        padding: const EdgeInsets.symmetric(vertical: 13),
        disabledForegroundColor: AppTheme.textSecondary.withValues(alpha: 0.4),
      ),
      icon: Icon(icon, size: 16),
      label: Text(
        label,
        style: const TextStyle(
          fontSize: 13,
          fontWeight: FontWeight.w600,
          fontFamily: 'Inter',
        ),
      ),
    );
  }
}
