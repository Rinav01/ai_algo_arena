import 'package:flutter/material.dart';
import 'package:ai_algo_app/core/app_theme.dart';
import 'package:ai_algo_app/models/algo_info.dart';
import 'package:ai_algo_app/widgets/concept_visualizer.dart';

class AlgoInfoModal extends StatelessWidget {
  final AlgoInfo info;

  const AlgoInfoModal({super.key, required this.info});

  static void show(BuildContext context, AlgoInfo info) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (context) => AlgoInfoModal(info: info),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: AppTheme.surfaceHigh.withValues(alpha: 0.95),
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24.0)),
        border: Border.all(color: Colors.white.withValues(alpha: 0.1)),
      ),
      padding: const EdgeInsets.fromLTRB(24, 12, 24, 32),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Handle
          Center(
            child: Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.1),
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
                    Text(
                      info.title,
                      style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                            color: AppTheme.accent,
                            fontWeight: FontWeight.bold,
                          ),
                    ),
                    const SizedBox(height: 4),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: AppTheme.accent.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Text(
                        'Complexity: ${info.complexity}',
                        style: Theme.of(context).textTheme.labelSmall?.copyWith(
                              color: AppTheme.accentLight,
                              fontWeight: FontWeight.w600,
                            ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 16),
              ConceptVisualizer(type: info.conceptType, size: 80),
            ],
          ),
          
          const SizedBox(height: 20),
          Text(
            info.description,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: AppTheme.onBackground.withValues(alpha: 0.8),
                  height: 1.5,
                ),
          ),
          
          const SizedBox(height: 24),
          Text(
            'KEY CHARACTERISTICS',
            style: Theme.of(context).textTheme.labelSmall?.copyWith(
                  color: AppTheme.textMuted,
                  letterSpacing: 1.5,
                ),
          ),
          const SizedBox(height: 12),
          ...info.keyFeatures.map((feature) => Padding(
            padding: const EdgeInsets.only(bottom: 8.0),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Icon(Icons.check_circle_outline, size: 16, color: AppTheme.success),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    feature,
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: AppTheme.onBackground,
                        ),
                  ),
                ),
              ],
            ),
          )),

          const SizedBox(height: 24),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: () => Navigator.pop(context),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppTheme.surfaceHighest,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                padding: const EdgeInsets.symmetric(vertical: 16),
              ),
              child: const Text('GOT IT'),
            ),
          ),
        ],
      ),
    );
  }
}
