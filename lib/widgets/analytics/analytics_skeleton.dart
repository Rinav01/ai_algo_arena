import 'package:flutter/material.dart';
import 'package:algo_arena/core/app_theme.dart';
import 'package:flutter_animate/flutter_animate.dart';

class AnalyticsSkeleton extends StatelessWidget {
  const AnalyticsSkeleton({super.key});

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _SkeletonBox(width: 200, height: 32),
          const SizedBox(height: 24),
          _SkeletonBox(width: double.infinity, height: 40), // Filters
          const SizedBox(height: 32),
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: List.generate(3, (i) => const _SkeletonCard()),
            ),
          ),
          const SizedBox(height: 32),
          _SkeletonBox(width: double.infinity, height: MediaQuery.sizeOf(context).height * 0.35), // Bar Chart
          const SizedBox(height: 32),
          _SkeletonBox(width: double.infinity, height: MediaQuery.sizeOf(context).height * 0.4), // Line Chart
        ],
      ),
    );
  }
}

class _SkeletonBox extends StatelessWidget {
  final double width;
  final double height;
  const _SkeletonBox({required this.width, required this.height});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: width,
      height: height,
      decoration: BoxDecoration(
        color: AppTheme.surfaceVariant.withValues(alpha: 0.5),
        borderRadius: BorderRadius.circular(12),
      ),
    ).animate(onPlay: (controller) => controller.repeat())
     .shimmer(duration: 1500.ms, color: AppTheme.accent.withValues(alpha: 0.1));
  }
}

class _SkeletonCard extends StatelessWidget {
  const _SkeletonCard();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: (MediaQuery.sizeOf(context).width * 0.75).clamp(200.0, 350.0),
      height: (MediaQuery.sizeOf(context).height * 0.3).clamp(200.0, 300.0),
      margin: const EdgeInsets.only(right: 16),
      decoration: BoxDecoration(
        color: AppTheme.surfaceVariant.withValues(alpha: 0.5),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.white.withValues(alpha: 0.05)),
      ),
    ).animate(onPlay: (controller) => controller.repeat())
     .shimmer(duration: 1500.ms, color: AppTheme.accent.withValues(alpha: 0.1));
  }
}
