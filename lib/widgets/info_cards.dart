import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:algo_arena/core/app_theme.dart';
import 'package:algo_arena/widgets/premium_glass_container.dart';
import 'package:algo_arena/widgets/concept_visualizer.dart';
import 'package:algo_arena/models/algo_info.dart';

class InfoSectionData {
  final IconData icon;
  final String title;
  final String description;

  const InfoSectionData({
    required this.icon,
    required this.title,
    required this.description,
  });
}

/// A unified, premium glassmorphic information card used throughout the app.
/// It supports algorithm profiles, dashboard methodology, and general insights.
class UnifiedInfoCard extends StatelessWidget {
  final String title;
  final String subtitle;
  final String description;
  final IconData? headerIcon;
  final ConceptType? conceptType;
  final List<String>? features;
  final List<InfoSectionData>? sections;
  final String? complexity;
  final bool? isOptimal;
  final String? footerNote;
  final VoidCallback? onAcknowledge;
  final bool animate;
  final double radius;
  final EdgeInsetsGeometry padding;

  const UnifiedInfoCard({
    super.key,
    required this.title,
    required this.subtitle,
    required this.description,
    this.headerIcon,
    this.conceptType,
    this.features,
    this.sections,
    this.complexity,
    this.isOptimal,
    this.footerNote,
    this.onAcknowledge,
    this.animate = true,
    this.radius = 24,
    this.padding = const EdgeInsets.all(24),
  });

  @override
  Widget build(BuildContext context) {
    return PremiumGlassContainer(
      radius: radius,
      opacity: 1,
      padding: padding,
      gradient: LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: [
          AppTheme.accent.withValues(alpha: 0.5),
          AppTheme.accentContainer.withValues(alpha: 0.01),
        ],
      ),
      child: SingleChildScrollView(
        physics: const BouncingScrollPhysics(),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildHeader(context),
            const SizedBox(height: 24),
            if (conceptType != null) ...[
              _buildConceptVisualizer(),
              const SizedBox(height: 24),
            ],
            if (description.isNotEmpty) ...[
              _buildMainDescription(),
              const SizedBox(height: 24),
            ],
            if (sections != null && sections!.isNotEmpty) ...[
              ...sections!.asMap().entries.map(
                (entry) => Padding(
                  padding: const EdgeInsets.only(bottom: 16),
                  child: _buildInfoSection(context, entry.value, entry.key),
                ),
              ),
            ],
            if (features != null && features!.isNotEmpty) ...[
              const SizedBox(height: 8),
              _buildFeaturesGrid(context),
            ],
            if (complexity != null ||
                isOptimal != null ||
                footerNote != null) ...[
              const SizedBox(height: 24),
              _buildFooter(context),
            ],
            if (onAcknowledge != null) ...[
              const SizedBox(height: 32),
              _buildActionButton(context),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildHeader(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                    title.toUpperCase(),
                    style: AppTheme.labelStyle.copyWith(
                      color: AppTheme.accentLight,
                      letterSpacing: 1.5,
                      fontSize: 10,
                    ),
                  )
                  .animate(target: animate ? 1 : 0)
                  .fadeIn(duration: 400.ms)
                  .slideX(begin: -0.1),
              const SizedBox(height: 4),
              Text(
                    subtitle,
                    style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                      fontWeight: FontWeight.bold,
                      fontFamily: 'SpaceGrotesk',
                      fontSize: 18,
                    ),
                  )
                  .animate(target: animate ? 1 : 0)
                  .fadeIn(delay: 100.ms)
                  .slideX(begin: -0.05),
            ],
          ),
        ),
        if (headerIcon != null)
          Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: AppTheme.accent.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Icon(headerIcon, color: AppTheme.accentLight),
              )
              .animate(target: animate ? 1 : 0)
              .scale(delay: 200.ms, curve: Curves.easeOutBack),
      ],
    );
  }

  Widget _buildConceptVisualizer() {
    return Center(
      child:
          Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.black.withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(
                    color: Colors.white.withValues(alpha: 0.05),
                  ),
                ),
                child: ConceptVisualizer(type: conceptType!, size: 140),
              )
              .animate(target: animate ? 1 : 0)
              .shimmer(delay: 1.seconds, duration: 2.seconds)
              .fadeIn(delay: 300.ms),
    );
  }

  Widget _buildMainDescription() {
    return Text(
      description,
      style: AppTheme.bodyStyle.copyWith(
        color: AppTheme.textSecondary,
        height: 1.5,
        fontSize: 14,
      ),
    ).animate(target: animate ? 1 : 0).fadeIn(delay: 400.ms);
  }

  Widget _buildInfoSection(
    BuildContext context,
    InfoSectionData section,
    int index,
  ) {
    return Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.05),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(section.icon, size: 18, color: AppTheme.accentLight),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    section.title,
                    style: AppTheme.titleStyle.copyWith(fontSize: 16),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    section.description,
                    style: AppTheme.bodyStyle.copyWith(
                      fontSize: 12,
                      color: AppTheme.textSecondary,
                      height: 1.4,
                    ),
                  ),
                ],
              ),
            ),
          ],
        )
        .animate(target: animate ? 1 : 0)
        .fadeIn(delay: (400 + index * 100).ms)
        .slideY(begin: 0.1);
  }

  Widget _buildFeaturesGrid(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'KEY CHARACTERISTICS',
          style: AppTheme.labelStyle.copyWith(
            color: AppTheme.textMuted,
            letterSpacing: 2.0,
            fontSize: 9,
          ),
        ).animate(target: animate ? 1 : 0).fadeIn(delay: 500.ms),
        const SizedBox(height: 16),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: features!.asMap().entries.map((entry) {
            final index = entry.key;
            final feature = entry.value;
            return Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 6,
                  ),
                  decoration: BoxDecoration(
                    color: AppTheme.surfaceHigh.withValues(alpha: 0.4),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(
                      color: AppTheme.accent.withValues(alpha: 0.2),
                    ),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(
                        Icons.check_circle_outline_rounded,
                        size: 14,
                        color: AppTheme.success,
                      ),
                      const SizedBox(width: 6),
                      Text(
                        feature,
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          fontSize: 11,
                          color: Colors.white.withValues(alpha: 0.9),
                        ),
                      ),
                    ],
                  ),
                )
                .animate(target: animate ? 1 : 0)
                .fadeIn(delay: (600 + index * 50).ms)
                .slideY(begin: 0.1, curve: Curves.easeOut);
          }).toList(),
        ),
      ],
    );
  }

  Widget _buildFooter(BuildContext context) {
    if (footerNote != null && complexity == null && isOptimal == null) {
      return Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: AppTheme.accent.withValues(alpha: 0.05),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(
          children: [
            const Icon(
              Icons.info_outline_rounded,
              size: 16,
              color: AppTheme.accentLight,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                footerNote!,
                style: AppTheme.labelStyle.copyWith(
                  fontSize: 10,
                  color: Colors.white54,
                ),
              ),
            ),
          ],
        ),
      ).animate(target: animate ? 1 : 0).fadeIn(delay: 800.ms);
    }

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppTheme.accent.withValues(alpha: 0.05),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppTheme.accent.withValues(alpha: 0.1)),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          if (complexity != null)
            Row(
              children: [
                const Icon(
                  Icons.speed_rounded,
                  size: 18,
                  color: AppTheme.accentLight,
                ),
                const SizedBox(width: 10),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'COMPLEXITY',
                      style: AppTheme.labelStyle.copyWith(
                        fontSize: 8,
                        color: AppTheme.textMuted,
                      ),
                    ),
                    Text(
                      complexity!,
                      style: AppTheme.labelStyle.copyWith(
                        fontSize: 11,
                        color: Colors.white,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          if (isOptimal != null)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
              decoration: BoxDecoration(
                color: isOptimal!
                    ? AppTheme.success.withValues(alpha: 0.1)
                    : AppTheme.warning.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(
                  color: (isOptimal! ? AppTheme.success : AppTheme.warning)
                      .withValues(alpha: 0.3),
                ),
              ),
              child: Text(
                isOptimal! ? 'OPTIMAL' : 'SUB-OPTIMAL',
                style: TextStyle(
                  color: isOptimal! ? AppTheme.success : AppTheme.warning,
                  fontSize: 10,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 1.0,
                ),
              ),
            ),
        ],
      ),
    ).animate(target: animate ? 1 : 0).fadeIn(delay: 700.ms);
  }

  Widget _buildActionButton(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      child: ElevatedButton(
        onPressed: onAcknowledge,
        style: ElevatedButton.styleFrom(
          backgroundColor: AppTheme.accent.withValues(alpha: 0.2),
          foregroundColor: Colors.white,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
            side: BorderSide(color: AppTheme.accent.withValues(alpha: 0.4)),
          ),
          padding: const EdgeInsets.symmetric(vertical: 18),
          elevation: 0,
        ),
        child: const Text(
          'ACKNOWLEDGE',
          style: TextStyle(fontWeight: FontWeight.bold, letterSpacing: 1.2),
        ),
      ),
    ).animate(target: animate ? 1 : 0).fadeIn(delay: 900.ms).slideY(begin: 0.2);
  }
}

/// Specialized wrapper for Algorithm documentation.
class AlgorithmInfoCard extends StatelessWidget {
  final AlgoInfo info;
  final VoidCallback? onAcknowledge;
  final double radius;
  final bool animate;

  const AlgorithmInfoCard({
    super.key,
    required this.info,
    this.onAcknowledge,
    this.radius = 24,
    this.animate = true,
  });

  @override
  Widget build(BuildContext context) {
    return UnifiedInfoCard(
      title: info.title,
      subtitle: 'Technical Profile',
      description: info.description,
      headerIcon: Icons.auto_awesome_mosaic_rounded,
      conceptType: info.conceptType,
      features: info.keyFeatures,
      complexity: info.complexity,
      isOptimal: info.isOptimal,
      onAcknowledge: onAcknowledge,
      radius: radius,
      animate: animate,
    );
  }
}

/// Specialized wrapper for Analytics Dashboard methodology.
class DashboardInfoCard extends StatelessWidget {
  final VoidCallback? onAcknowledge;

  const DashboardInfoCard({super.key, this.onAcknowledge});

  @override
  Widget build(BuildContext context) {
    return UnifiedInfoCard(
      title: 'ANALYTICS ENGINE',
      subtitle: 'Insight Methodology',
      description: '',
      headerIcon: Icons.analytics_rounded,
      onAcknowledge: onAcknowledge,
      sections: const [
        InfoSectionData(
          icon: Icons.auto_awesome_rounded,
          title: 'Smart Insights',
          description:
              'AI-driven analysis that detects performance anomalies, suggests better algorithms for your specific problems, and identifies efficiency trends.',
        ),
        InfoSectionData(
          icon: Icons.bar_chart_rounded,
          title: 'Performance Metrics',
          description:
              'Comparing Node Exploration count and Success Rates across algorithms to determine which approach is most efficient for your current grid settings.',
        ),
        InfoSectionData(
          icon: Icons.timeline_rounded,
          title: 'Scalability Trends',
          description:
              'Visualizes how algorithms perform as the search space grows, helping you understand the time and space complexity in practice.',
        ),
      ],
      footerNote:
          'Data is synchronized across all your runs to provide an accurate engineering profile.',
    );
  }
}
