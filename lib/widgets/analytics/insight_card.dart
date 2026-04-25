import 'package:flutter/material.dart';
import 'package:algo_arena/core/app_theme.dart';
import 'package:algo_arena/models/analytics_models.dart';
import 'package:flutter_animate/flutter_animate.dart';

class InsightCard extends StatelessWidget {
  final BattleInsight insight;

  const InsightCard({super.key, required this.insight});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 280,
      margin: const EdgeInsets.only(right: 16),
      decoration: AppTheme.glassCardAccent(radius: 20),
      clipBehavior: Clip.antiAlias,
      child: Stack(
        children: [
          // Ambient Glow Background
          Positioned(
            top: -20,
            right: -20,
            child: Icon(
              _getIconForType(insight.type),
              size: 100,
              color: AppTheme.accent.withValues(alpha: 0.05),
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(20.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: AppTheme.accent.withValues(alpha: 0.15),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Icon(
                        _getIconForType(insight.type),
                        color: AppTheme.accentLight,
                        size: 20,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        insight.title,
                        style: Theme.of(context).textTheme.titleMedium?.copyWith(
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                            ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                Text(
                  insight.description,
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: AppTheme.textSecondary,
                        height: 1.4,
                      ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
                const Spacer(),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                  decoration: BoxDecoration(
                    color: AppTheme.cyan.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: AppTheme.cyan.withValues(alpha: 0.2)),
                  ),
                  child: Text(
                    insight.impact,
                    style: Theme.of(context).textTheme.labelSmall?.copyWith(
                          color: AppTheme.cyan,
                          fontWeight: FontWeight.w900,
                        ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    ).animate().fadeIn(duration: 600.ms).slideX(begin: 0.2, end: 0);
  }

  IconData _getIconForType(String type) {
    switch (type.toLowerCase()) {
      case 'efficiency':
        return Icons.psychology_rounded;
      case 'speed':
        return Icons.bolt_rounded;
      case 'complexity':
        return Icons.hub_rounded;
      case 'memory':
        return Icons.memory_rounded;
      default:
        return Icons.analytics_rounded;
    }
  }
}
