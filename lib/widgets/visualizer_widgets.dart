import 'package:flutter/material.dart';
import 'package:algo_arena/core/app_theme.dart';
import 'package:algo_arena/widgets/animated_number_display.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:algo_arena/models/grid_node.dart';
import 'package:algo_arena/models/algo_info.dart';
import 'package:algo_arena/widgets/algo_info_modal.dart';

/// Reusable glassmorphism stat card used in visualizers.
class GlassStatCard extends StatelessWidget {
  const GlassStatCard({super.key, required this.label, required this.value});

  final String label;
  final dynamic value;

  @override
  Widget build(BuildContext context) {
    return RepaintBoundary(
      child: Container(
        decoration: AppTheme.glassCard(radius: 12),
        child: Row(
          children: [
            // Left accent bar — separate child so borderRadius still works
            Container(
              width: 3.0,
              decoration: BoxDecoration(
                color: AppTheme.accent,
                borderRadius: BorderRadius.only(
                  topLeft: Radius.circular(12.0),
                  bottomLeft: Radius.circular(12.0),
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
                    value is int
                        ? AnimatedNumberDisplay(
                            value: value as int,
                            duration: const Duration(milliseconds: 600),
                            curve: Curves.easeOutCubic,
                            textStyle: TextStyle(
                              fontSize: 22.0,
                              fontWeight: FontWeight.w800,
                              color: AppTheme.onBackground,
                              fontFamily: 'Inter',
                            ),
                          )
                        : Text(
                            value.toString(),
                            style: TextStyle(
                              fontSize: 18.0,
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
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 16.0, vertical: 10.0),
      decoration: AppTheme.glassCard(
        radius: 30,
        borderColor: isSolved
            ? AppTheme.success.withValues(alpha: 0.45)
            : isSolving
            ? AppTheme.warning.withValues(alpha: 0.45)
            : Colors.white.withValues(alpha: 0.10),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 8.0,
            height: 8.0,
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
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 16.0, vertical: 12.0),
      decoration: AppTheme.glassCard(radius: 12),
      child: Wrap(
        spacing: 16,
        runSpacing: 10,
        alignment: WrapAlignment.center,
        children: [
          _LegendDot(color: AppTheme.cellStart, label: 'Start'),
          _LegendDot(color: AppTheme.cellGoal, label: 'Goal'),
          _LegendDot(
            color: AppTheme.cellWall.withValues(alpha: 1),
            label: 'Wall',
          ),
          _LegendDot(
            color: AppTheme.cellWeight.withValues(alpha: 0.2),
            label: '2x',
          ),
          _LegendDot(
            color: AppTheme.cellWeight.withValues(alpha: 0.5),
            label: '5x',
          ),
          _LegendDot(
            color: AppTheme.cellWeight.withValues(alpha: 0.9),
            label: '10x',
          ),
          _LegendDot(color: exploredColor, label: 'Explored'),
          _LegendDot(color: pathColor, label: 'Path'),
        ],
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
          width: 10.0,
          height: 10.0,
          decoration: BoxDecoration(
            color: color,
            borderRadius: BorderRadius.circular(3.0),
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
    this.info,
    this.comparisonInfos,
    this.initialKey,
  });

  final String title;
  final String subtitle;
  final VoidCallback? onBackTap;
  final AlgoInfo? info;
  final Map<String, AlgoInfo>? comparisonInfos;
  final String? initialKey;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        GestureDetector(
          onTap: onBackTap ?? () => Navigator.pop(context),
          child: Container(
            width: 36.0,
            height: 36.0,
            decoration: AppTheme.glassCard(radius: 10),
            child: Icon(
              Icons.arrow_back_ios_new_rounded,
              size: 16.0,
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
                style: Theme.of(
                  context,
                ).textTheme.titleLarge?.copyWith(color: AppTheme.accent),
              ),
              Text(subtitle, style: Theme.of(context).textTheme.labelMedium),
            ],
          ),
        ),
        const SizedBox(width: 8),
        if (info != null || comparisonInfos != null)
          GestureDetector(
            onTap: () => AlgoInfoModal.show(
              context,
              info: info,
              comparisonInfos: comparisonInfos,
              initialKey: initialKey,
            ),
            child: Container(
              width: 36.0,
              height: 36.0,
              decoration: AppTheme.glassCard(radius: 10).copyWith(
                color: AppTheme.accent.withValues(alpha: 0.1),
                border: Border.all(
                  color: AppTheme.accent.withValues(alpha: 0.3),
                ),
              ),
              child: Icon(
                Icons.info_outline_rounded,
                size: 18.0,
                color: AppTheme.accentLight,
              ),
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
    required this.onClear,
    this.onVersus,
  });

  final bool isSolving;
  final bool isSolved;
  final int stepCount;
  final VoidCallback onSolve;
  final VoidCallback onPauseResume;
  final VoidCallback onClear;
  final VoidCallback? onVersus;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        // Row 1: primary actions
        Row(
          children: [
            Expanded(
              flex: 4,
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
              flex: 4,
              child: _GhostBtn(
                icon: isSolving
                    ? Icons.pause_rounded
                    : Icons.play_arrow_rounded,
                label: isSolving ? 'Pause' : 'Resume',
                enabled: stepCount > 0,
                onTap: onPauseResume,
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              flex: 3,
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
        if (onVersus != null) ...[
          const SizedBox(height: 12),
          _CtaButton(
            icon: Icons.compare_arrows_rounded,
            label: 'BATTLE ARENA — COMPARE ALGORITHMS',
            enabled: true,
            primary: true,
            accentColor: AppTheme.warning,
            onTap: onVersus!,
          ),
        ],
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
    this.accentColor,
  });
  final IconData icon;
  final String label;
  final bool enabled;
  final bool primary;
  final VoidCallback onTap;
  final Color? accentColor;

  @override
  Widget build(BuildContext context) {
    return ElevatedButton.icon(
      onPressed: enabled ? onTap : null,
      style: ElevatedButton.styleFrom(
        backgroundColor: primary
            ? (accentColor ?? AppTheme.accent)
            : AppTheme.surfaceHigh,
        foregroundColor: Colors.white,
        disabledBackgroundColor: AppTheme.surfaceHighest.withValues(alpha: 0.5),
        disabledForegroundColor: AppTheme.textSecondary,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(10.0),
        ),
        padding: EdgeInsets.symmetric(vertical: 13.0),
        side: primary
            ? null
            : BorderSide(color: Colors.white.withValues(alpha: 0.12)),
      ),
      icon: Icon(icon, size: 18),
      label: Text(
        label,
        style: TextStyle(
          fontSize: 13.0,
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
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(10.0),
        ),
        padding: EdgeInsets.symmetric(vertical: 13.0),
        disabledForegroundColor: AppTheme.textSecondary.withValues(alpha: 0.4),
      ),
      icon: Icon(icon, size: 16),
      label: Text(
        label,
        style: TextStyle(
          fontSize: 13.0,
          fontWeight: FontWeight.w600,
          fontFamily: 'Inter',
        ),
      ),
    );
  }
}

class ToolSelector extends StatelessWidget {
  const ToolSelector({
    super.key,
    required this.selectedTool,
    required this.onToolSelected,
    this.isSolving = false,
  });

  final dynamic
  selectedTool; // PaintTool but using dynamic to avoid import circularity if needed
  final Function(dynamic) onToolSelected;
  final bool isSolving;

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: [
          _ToolBtn(
            icon: Icons.square_rounded,
            label: 'Wall',
            isSelected: selectedTool == PaintTool.wall,
            onTap: () => onToolSelected(PaintTool.wall),
            color: AppTheme.cellWall,
          ),
          const SizedBox(width: 8),
          _ToolBtn(
            icon: Icons.landscape_rounded,
            label: 'Weight',
            isSelected: selectedTool == PaintTool.weight,
            onTap: () => onToolSelected(PaintTool.weight),
            color: AppTheme.cellWeight,
          ),
          const SizedBox(width: 8),
          _ToolBtn(
            icon: Icons.cleaning_services_rounded,
            label: 'Erase',
            isSelected: selectedTool == PaintTool.erase,
            onTap: () => onToolSelected(PaintTool.erase),
            color: AppTheme.textMuted,
          ),
          const SizedBox(width: 8),
          _ToolBtn(
            icon: Icons.play_circle_fill_rounded,
            label: 'Start',
            isSelected: selectedTool == PaintTool.start,
            onTap: () => onToolSelected(PaintTool.start),
            color: AppTheme.cellStart,
          ),
          const SizedBox(width: 8),
          _ToolBtn(
            icon: Icons.stars_rounded,
            label: 'Goal',
            isSelected: selectedTool == PaintTool.goal,
            onTap: () => onToolSelected(PaintTool.goal),
            color: AppTheme.cellGoal,
          ),
        ],
      ),
    );
  }
}

class _ToolBtn extends StatelessWidget {
  const _ToolBtn({
    required this.icon,
    required this.label,
    required this.isSelected,
    required this.onTap,
    required this.color,
  });

  final IconData icon;
  final String label;
  final bool isSelected;
  final VoidCallback onTap;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: EdgeInsets.symmetric(horizontal: 12.0, vertical: 8.0),
        decoration: BoxDecoration(
          color: isSelected
              ? color.withValues(alpha: 0.15)
              : Colors.white.withValues(alpha: 0.03),
          borderRadius: BorderRadius.circular(10.0),
          border: Border.all(
            color: isSelected
                ? color.withValues(alpha: 0.6)
                : Colors.white.withValues(alpha: 0.08),
            width: isSelected ? 1.5 : 1,
          ),
        ),
        child: Row(
          children: [
            Icon(
              icon,
              size: 14.0,
              color: isSelected ? color : AppTheme.textSecondary,
            ),
            const SizedBox(width: 6),
            Text(
              label,
              style: TextStyle(
                fontSize: 11.0,
                fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                color: isSelected ? Colors.white : AppTheme.textSecondary,
                fontFamily: 'SpaceGrotesk',
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class ToolButton extends StatelessWidget {
  const ToolButton({
    super.key,
    required this.label,
    required this.icon,
    required this.onPressed,
    required this.color,
  });

  final String label;
  final IconData icon;
  final VoidCallback onPressed;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onPressed,
      child: Container(
        padding: EdgeInsets.symmetric(vertical: 10.0),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(10.0),
          border: Border.all(color: color.withValues(alpha: 0.3)),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 16.0, color: color),
            const SizedBox(width: 8),
            Text(
              label,
              style: TextStyle(
                fontSize: 12.0,
                fontWeight: FontWeight.w700,
                color: Colors.white,
                fontFamily: 'SpaceGrotesk',
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class PerformanceChart extends StatelessWidget {
  const PerformanceChart({
    super.key,
    required this.dataPoints,
    required this.accentColor,
    this.onExpand,
  });

  final List<FlSpot> dataPoints;
  final Color accentColor;
  final VoidCallback? onExpand;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onExpand,
      child: Container(
        height: 200.0,
        padding: const EdgeInsets.fromLTRB(16.0, 16.0, 24.0, 8.0),
        decoration: AppTheme.glassCard(radius: 16).copyWith(
          color: AppTheme.surfaceVariant.withValues(alpha: 0.4),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    Text(
                      'COMPUTATIONAL TREND',
                      style: Theme.of(context).textTheme.labelSmall?.copyWith(
                        color: AppTheme.accentLight,
                        letterSpacing: 1.5,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Icon(
                      Icons.open_in_full_rounded,
                      size: 12,
                      color: AppTheme.accentLight.withValues(alpha: 0.5),
                    ),
                  ],
                ),
                Icon(Icons.query_stats_rounded, color: accentColor, size: 16.0),
              ],
            ),
            const SizedBox(height: 20),
            Expanded(
              child: LineChart(
                LineChartData(
                  lineTouchData: LineTouchData(
                    touchTooltipData: LineTouchTooltipData(
                      getTooltipColor: (spot) => AppTheme.surfaceHigh,
                      getTooltipItems: (List<LineBarSpot> touchedBarSpots) {
                        return touchedBarSpots.map((barSpot) {
                          return LineTooltipItem(
                            'Step: ${barSpot.x.toInt()}\nExplored: ${barSpot.y.toInt()}',
                            const TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                              fontSize: 12,
                            ),
                          );
                        }).toList();
                      },
                    ),
                  ),
                  gridData: FlGridData(
                    show: true,
                    drawVerticalLine: false,
                    getDrawingHorizontalLine: (value) => FlLine(
                      color: Colors.white.withValues(alpha: 0.05),
                      strokeWidth: 1,
                    ),
                  ),
                  titlesData: FlTitlesData(
                    show: true,
                    rightTitles: const AxisTitles(
                      sideTitles: SideTitles(showTitles: false),
                    ),
                    topTitles: const AxisTitles(
                      sideTitles: SideTitles(showTitles: false),
                    ),
                    leftTitles: AxisTitles(
                      sideTitles: SideTitles(
                        showTitles: true,
                        reservedSize: 30,
                        getTitlesWidget: (val, meta) => Text(
                          val.toInt().toString(),
                          style: const TextStyle(
                            color: AppTheme.textMuted,
                            fontSize: 10.0,
                          ),
                        ),
                      ),
                    ),
                    bottomTitles: AxisTitles(
                      sideTitles: SideTitles(
                        showTitles: true,
                        getTitlesWidget: (val, meta) => Padding(
                          padding: const EdgeInsets.only(top: 8.0),
                          child: Text(
                            val.toInt().toString(),
                            style: const TextStyle(
                              color: AppTheme.textMuted,
                              fontSize: 10.0,
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                  borderData: FlBorderData(show: false),
                  lineBarsData: [
                    LineChartBarData(
                      spots: dataPoints,
                      isCurved: true,
                      color: accentColor,
                      barWidth: 3,
                      isStrokeCapRound: true,
                      dotData: FlDotData(show: dataPoints.length < 10),
                      belowBarData: BarAreaData(
                        show: true,
                        gradient: LinearGradient(
                          begin: Alignment.topCenter,
                          end: Alignment.bottomCenter,
                          colors: [
                            accentColor.withValues(alpha: 0.2),
                            accentColor.withValues(alpha: 0.0),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
