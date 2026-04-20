import 'package:flutter/material.dart';
import 'package:ai_algo_app/core/grid_problem.dart';
import 'package:ai_algo_app/services/algorithm_recommender.dart';
import 'package:ai_algo_app/core/app_theme.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_animate/flutter_animate.dart';

class AlgorithmRecommendationCard extends StatelessWidget {
  final GridProblem problem;
  final VoidCallback onUseRecommended;

  const AlgorithmRecommendationCard({
    super.key,
    required this.problem,
    required this.onUseRecommended,
  });

  @override
  Widget build(BuildContext context) {
    final recommendation = AlgorithmRecommender.recommend(problem);

    return Container(
      decoration: AppTheme.glassCardAccent(radius: 20),
      child: Stack(
        children: [
          // Decorative AI Pulse
          Positioned(
            right: -10,
            top: -10,
            child: Container(
              width: 80.r,
              height: 80.r,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: AppTheme.accent.withValues(alpha: 0.1),
              ),
            ).animate(onPlay: (c) => c.repeat(reverse: true))
             .scale(begin: const Offset(0.8, 0.8), end: const Offset(1.2, 1.2), duration: 2.seconds),
          ),
          
          Padding(
            padding: EdgeInsets.all(20.r),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    const Text('🤖', style: TextStyle(fontSize: 26)),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'AI AGENT RECOMMENDATION',
                            style: Theme.of(context).textTheme.labelSmall?.copyWith(
                              letterSpacing: 2,
                              color: AppTheme.accent,
                              fontWeight: FontWeight.w900,
                            ),
                          ),
                          Row(
                            children: [
                              Text(
                                recommendation.algorithm.shortName,
                                style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 20.sp,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              const SizedBox(width: 8),
                              _buildConfidenceBadge(recommendation.confidence),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                
                // Reasoning & Efficiency Box
                Container(
                  padding: EdgeInsets.all(12.r),
                  decoration: BoxDecoration(
                    color: Colors.black.withValues(alpha: 0.2),
                    borderRadius: BorderRadius.circular(12.r),
                    border: Border.all(color: Colors.white.withValues(alpha: 0.05)),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            'WHY THIS CHOICE?',
                            style: Theme.of(context).textTheme.labelSmall?.copyWith(
                              color: AppTheme.textMuted,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          _buildEfficiencyIndicator(
                            AlgorithmRecommender.getEfficiencyScore(
                              problem, 
                              recommendation.algorithm,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Text(
                        recommendation.reason,
                        style: TextStyle(
                          color: Colors.white70,
                          fontSize: 13.sp,
                          height: 1.5,
                        ),
                      ),
                    ],
                  ),
                ),
                
                const SizedBox(height: 20),
                
                // Action Button
                GestureDetector(
                  onTap: onUseRecommended,
                  child: Container(
                    height: 52.h,
                    width: double.infinity,
                    decoration: BoxDecoration(
                      gradient: AppTheme.ctaGradient,
                      borderRadius: BorderRadius.circular(14.r),
                      boxShadow: [
                        BoxShadow(
                          color: AppTheme.accent.withValues(alpha: 0.3),
                          blurRadius: 12,
                          spreadRadius: -2,
                        )
                      ],
                    ),
                    child: Center(
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.auto_fix_high_rounded, size: 18.r, color: Colors.white),
                          const SizedBox(width: 8),
                          Text(
                            'APPLY RECOMMENDATION',
                            style: TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.w900,
                              fontSize: 14.sp,
                              letterSpacing: 1.5,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEfficiencyIndicator(double efficiency) {
    final percent = (efficiency * 100).toInt();
    final color = efficiency > 0.8
        ? AppTheme.success
        : (efficiency > 0.6 ? AppTheme.accent : AppTheme.error);

    return Container(
      padding: EdgeInsets.symmetric(horizontal: 6.w, vertical: 2.h),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(6.r),
        border: Border.all(color: color.withValues(alpha: 0.2)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.bolt_rounded, color: color, size: 12.r),
          const SizedBox(width: 4),
          Text(
            '$percent% EFFICIENCY',
            style: TextStyle(
              color: color,
              fontSize: 9.sp,
              fontWeight: FontWeight.w900,
              letterSpacing: 0.5,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildConfidenceBadge(double confidence) {
    final percent = (confidence * 100).toInt();
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 8.w, vertical: 2.h),
      decoration: BoxDecoration(
        color: AppTheme.success.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(20.r),
        border: Border.all(color: AppTheme.success.withValues(alpha: 0.3)),
      ),
      child: Text(
        '$percent% MATCH',
        style: TextStyle(
          color: AppTheme.success,
          fontSize: 10.sp,
          fontWeight: FontWeight.bold,
          letterSpacing: 0.5,
        ),
      ),
    );
  }
}
