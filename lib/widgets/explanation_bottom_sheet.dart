import 'package:flutter/material.dart';
import 'package:algo_arena/core/app_theme.dart';
import 'package:algo_arena/core/problem_definition.dart';
import 'package:flutter_animate/flutter_animate.dart';

import 'package:algo_arena/widgets/premium_glass_container.dart';

class ExplanationBottomSheet<S> extends StatelessWidget {
  final AlgorithmStep<S> step;
  final String Function(S) stateFormatter;
  final VoidCallback? onJumpToStep;

  const ExplanationBottomSheet({
    super.key,
    required this.step,
    required this.stateFormatter,
    this.onJumpToStep,
  });

  @override
  Widget build(BuildContext context) {
    return PremiumGlassContainer(
      radius: 32,
      padding: const EdgeInsets.fromLTRB(24, 12, 24, 32),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Center(
            child: Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: Colors.white24,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
          const SizedBox(height: 24),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 8, vertical: 2),
                          decoration: BoxDecoration(
                            color: AppTheme.accent.withValues(alpha: 0.15),
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: Text(
                            'STEP #${step.stepCount}',
                            style: AppTheme.labelStyle.copyWith(
                              color: AppTheme.accentLight,
                              fontSize: 10,
                              fontWeight: FontWeight.bold,
                              letterSpacing: 1.0,
                            ),
                          ),
                        ),
                        if (step.meta?['isOptimal'] != null) ...[
                          const SizedBox(width: 8),
                          _buildQualityBadge(step.meta!['isOptimal'] as bool),
                        ],
                      ],
                    ),
                    const SizedBox(height: 12),
                    Text(
                      'Node Analysis',
                      style: AppTheme.labelStyle.copyWith(color: Colors.white38),
                    ),
                    Text(
                      stateFormatter(step.currentState as S),
                      style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                            fontWeight: FontWeight.bold,
                            fontFamily: 'SpaceGrotesk',
                          ),
                    ),
                  ],
                ),
              ),
              Container(
                width: 56,
                height: 56,
                decoration: BoxDecoration(
                  color: AppTheme.accent.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(16),
                  border:
                      Border.all(color: AppTheme.accent.withValues(alpha: 0.2)),
                ),
                child: const Icon(
                  Icons.psychology_outlined,
                  color: AppTheme.accentLight,
                  size: 32,
                ),
              )
                  .animate(onPlay: (c) => c.repeat())
                  .shimmer(duration: 3.seconds, color: Colors.white24),
            ],
          ),
          const SizedBox(height: 24),
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.05),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: Colors.white.withValues(alpha: 0.05)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'AI EXPLANATION',
                  style: AppTheme.labelStyle
                      .copyWith(color: AppTheme.accentLight, fontSize: 10),
                ),
                const SizedBox(height: 8),
                Text(
                  step.reason ??
                      'The algorithm selected this node as the most promising next step based on its internal evaluation function.',
                  style: AppTheme.bodyStyle.copyWith(
                    fontSize: 15,
                    height: 1.5,
                    color: Colors.white.withValues(alpha: 0.85),
                  ),
                ),
              ],
            ),
          ).animate().fadeIn(duration: 400.ms).slideY(begin: 0.1),
          if (step.meta != null && step.meta!.isNotEmpty) ...[
            const SizedBox(height: 24),
            Text(
              'METRICS & HEURISTICS',
              style: AppTheme.labelStyle
                  .copyWith(color: Colors.white38, fontSize: 10),
            ),
            const SizedBox(height: 12),
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              physics: const BouncingScrollPhysics(),
              child: Row(
                children: step.meta!.entries
                    .where((e) => ![
                          'isOptimal',
                          'alternatives',
                          'bestPossible'
                        ].contains(e.key))
                    .map((e) {
                  return Padding(
                    padding: const EdgeInsets.only(right: 12),
                    child: _buildMetricChip(
                      e.key.toUpperCase(),
                      e.value is double
                          ? e.value.toStringAsFixed(2)
                          : e.value.toString(),
                    ),
                  );
                }).toList(),
              ),
            ).animate().fadeIn(delay: 200.ms).slideX(begin: 0.05),
            if (step.meta!['alternatives'] != null) ...[
              const SizedBox(height: 24),
              _buildAlternativesSection(step.meta!['alternatives'] as List),
            ],
          ],
          const SizedBox(height: 32),
          Row(
            children: [
              if (onJumpToStep != null) ...[
                Expanded(
                  flex: 2,
                  child: ElevatedButton.icon(
                    onPressed: () {
                      onJumpToStep!();
                      Navigator.pop(context);
                    },
                    icon: const Icon(Icons.auto_fix_high_rounded, size: 18),
                    label: const Text('JUMP TO STATE'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppTheme.accent,
                      foregroundColor: Colors.white,
                      elevation: 0,
                      padding: const EdgeInsets.symmetric(vertical: 18),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
              ],
              Expanded(
                child: TextButton(
                  onPressed: () => Navigator.pop(context),
                  style: TextButton.styleFrom(
                    foregroundColor: Colors.white54,
                    padding: const EdgeInsets.symmetric(vertical: 18),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                      side:
                          BorderSide(color: Colors.white.withValues(alpha: 0.1)),
                    ),
                  ),
                  child: const Text('CLOSE'),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildQualityBadge(bool isOptimal) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: isOptimal
            ? Colors.green.withValues(alpha: 0.15)
            : Colors.amber.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: isOptimal
              ? Colors.green.withValues(alpha: 0.5)
              : Colors.amber.withValues(alpha: 0.5),
          width: 1,
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            isOptimal ? Icons.check_circle_outline : Icons.warning_amber_rounded,
            size: 14,
            color: isOptimal ? Colors.green : Colors.amber,
          ),
          const SizedBox(width: 6),
          Text(
            isOptimal ? 'OPTIMAL' : 'SUBOPTIMAL',
            style: AppTheme.labelStyle.copyWith(
              color: isOptimal ? Colors.green : Colors.amber,
              fontSize: 10,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAlternativesSection(List alternatives) {
    if (alternatives.isEmpty) return const SizedBox.shrink();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'REJECTED ALTERNATIVES',
          style: AppTheme.labelStyle.copyWith(color: Colors.white54),
        ),
        const SizedBox(height: 12),
        ...alternatives.map((alt) {
          final diff = (alt['diff'] as num).toDouble();
          return Padding(
            padding: const EdgeInsets.only(bottom: 8.0),
            child: Row(
              children: [
                const Icon(Icons.close_rounded, color: Colors.white24, size: 16),
                const SizedBox(width: 8),
                Text(
                  alt['state'].toString(),
                  style: AppTheme.bodyStyle
                      .copyWith(fontSize: 14, color: Colors.white70),
                ),
                const Spacer(),
                Text(
                  '+${diff.toStringAsFixed(1)} cost',
                  style: AppTheme.bodyStyle.copyWith(
                    fontSize: 12,
                    color: Colors.redAccent.withValues(alpha: 0.7),
                    fontStyle: FontStyle.italic,
                  ),
                ),
              ],
            ),
          );
        }),
      ],
    );
  }

  Widget _buildMetricChip(String label, String value) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.05),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.white10),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: AppTheme.labelStyle.copyWith(
              fontSize: 10,
              color: Colors.white38,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            value,
            style: AppTheme.titleStyle.copyWith(
              fontSize: 18,
              color: Colors.white,
            ),
          ),
        ],
      ),
    );
  }
}
