import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:algo_arena/core/app_theme.dart';
import 'package:algo_arena/models/analytics_models.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:algo_arena/widgets/premium_glass_container.dart';

class InsightCard extends StatelessWidget {
  final Insight insight;
  final VoidCallback? onTap;

  const InsightCard({super.key, required this.insight, this.onTap});

  @override
  Widget build(BuildContext context) {
    final severityColor = insight.getSeverityColor();
    final typeIcon = insight.getIcon();

    return GestureDetector(
      onTap: () {
        HapticFeedback.lightImpact();
        onTap?.call();
      },
      child: PremiumGlassContainer(
        width: MediaQuery.sizeOf(context).width * 0.75 > 350 ? 350 : MediaQuery.sizeOf(context).width * 0.75,
        radius: 24,
        margin: const EdgeInsets.only(right: 16),
        padding: EdgeInsets.zero,
        child: Stack(
          children: [
            Positioned(
              top: -20,
              right: -20,
              child: Icon(
                typeIcon,
                size: 120,
                color: severityColor.withValues(alpha: 0.05),
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: severityColor.withValues(alpha: 0.15),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Icon(
                          typeIcon,
                          color: severityColor,
                          size: 20,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          insight.title,
                          style: Theme.of(context).textTheme.titleSmall?.copyWith(
                                fontWeight: FontWeight.bold,
                                color: Colors.white,
                              ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Text(
                    insight.message,
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          color: AppTheme.textSecondary,
                          height: 1.4,
                        ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      Expanded(
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(4),
                          child: LinearProgressIndicator(
                            value: insight.confidence,
                            backgroundColor: Colors.white.withValues(alpha: 0.1),
                            valueColor: AlwaysStoppedAnimation<Color>(severityColor),
                            minHeight: 4,
                          ),
                        ),
                      ),
                      const SizedBox(width: 10),
                      Text(
                        "${(insight.confidence * 100).toInt()}%",
                        style: Theme.of(context).textTheme.labelSmall?.copyWith(
                              color: severityColor,
                              fontWeight: FontWeight.bold,
                            ),
                      ),
                    ],
                  ),
                  if (insight.reason != null) ...[
                    const SizedBox(height: 4),
                    Text(
                      "Reason: ${insight.reason}",
                      style: Theme.of(context).textTheme.labelSmall?.copyWith(
                            color: AppTheme.textMuted,
                            fontStyle: FontStyle.italic,
                          ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                  const Spacer(),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: [
                      if (insight.context?['algorithm'] != null)
                        _buildBadge(
                          context,
                          insight.context!['algorithm'],
                          AppTheme.accent,
                        ),
                      if (insight.context?['segment'] != null)
                        _buildBadge(
                          context,
                          insight.context!['segment'],
                          AppTheme.cyan,
                        ),
                      if (insight.metrics?['difference'] != null)
                        _buildBadge(
                          context,
                          "${insight.metrics!['difference']}${insight.metrics!['unit'] ?? ''}",
                          AppTheme.accentLight,
                          isBold: true,
                        ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    ).animate().fadeIn(duration: 600.ms).slideX(begin: 0.2, end: 0);
  }

  Widget _buildBadge(BuildContext context, String text, Color color, {bool isBold = false}) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: color.withValues(alpha: 0.2)),
      ),
      child: Text(
        text.toUpperCase(),
        style: Theme.of(context).textTheme.labelSmall?.copyWith(
              color: color,
              fontWeight: isBold ? FontWeight.w900 : FontWeight.bold,
              fontSize: 9,
            ),
      ),
    );
  }
}
