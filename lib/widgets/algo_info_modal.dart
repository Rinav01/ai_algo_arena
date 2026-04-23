import 'package:flutter/material.dart';
import 'package:algo_arena/core/app_theme.dart';
import 'package:algo_arena/models/algo_info.dart';
import 'package:algo_arena/widgets/concept_visualizer.dart';

class AlgoInfoModal extends StatelessWidget {
  final AlgoInfo? info;
  final Map<String, AlgoInfo>? comparisonInfos;
  final String? initialKey;

  const AlgoInfoModal({
    super.key,
    this.info,
    this.comparisonInfos,
    this.initialKey,
  });

  static void show(
    BuildContext context, {
    AlgoInfo? info,
    Map<String, AlgoInfo>? comparisonInfos,
    String? initialKey,
  }) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (context) => AlgoInfoModal(
        info: info,
        comparisonInfos: comparisonInfos,
        initialKey: initialKey,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    // If comparisonInfos is provided and has > 1 item, show tabs
    final showTabs =
        comparisonInfos != null && (comparisonInfos?.length ?? 0) > 1;

    if (showTabs) {
      final keys = comparisonInfos!.keys.toList();
      final initialIndex = initialKey != null ? keys.indexOf(initialKey!) : 0;
      // Space evenly if we have a small number of tabs (3 or fewer)
      final isScrollable = keys.length > 3;

      return DefaultTabController(
        length: keys.length,
        initialIndex: initialIndex != -1 ? initialIndex : 0,
        child: Container(
          height: MediaQuery.of(context).size.height * 0.75,
          decoration: BoxDecoration(
            color: AppTheme.surfaceHigh.withValues(alpha: 0.95),
            borderRadius: const BorderRadius.vertical(
              top: Radius.circular(24.0),
            ),
            border: Border.all(color: Colors.white.withValues(alpha: 0.1)),
          ),
          child: Column(
            children: [
              const SizedBox(height: 12),
              _buildHandle(),
              const SizedBox(height: 16),
              _buildTabBar(context, keys, isScrollable: isScrollable),
              Expanded(
                child: TabBarView(
                  children: keys
                      .map(
                        (k) => _AlgoInfoView(
                          info: comparisonInfos![k]!,
                          isTab: true,
                        ),
                      )
                      .toList(),
                ),
              ),
            ],
          ),
        ),
      );
    }

    // Single info view (Fallback or Battle Arena)
    final targetInfo = info ?? comparisonInfos?.values.first;
    if (targetInfo == null) return const SizedBox.shrink();

    return Container(
      decoration: BoxDecoration(
        color: AppTheme.surfaceHigh.withValues(alpha: 0.95),
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24.0)),
        border: Border.all(color: Colors.white.withValues(alpha: 0.1)),
      ),
      padding: const EdgeInsets.fromLTRB(24, 12, 24, 32),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          _buildHandle(),
          const SizedBox(height: 24),
          _AlgoInfoView(info: targetInfo, isTab: false),
        ],
      ),
    );
  }

  Widget _buildHandle() {
    return Center(
      child: Container(
        width: 40,
        height: 4,
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(2),
        ),
      ),
    );
  }

  Widget _buildTabBar(
    BuildContext context,
    List<String> labels, {
    required bool isScrollable,
  }) {
    final screenWidth = MediaQuery.of(context).size.width;
    final isSmall = screenWidth < 400;

    // Dynamic styling based on media query
    final horizontalMargin = screenWidth * 0.05; // 5% margin
    final fontSize = isSmall ? 10.0 : 12.0;
    final labelPadding = isSmall ? 8.0 : 16.0;

    return Container(
      margin: EdgeInsets.symmetric(horizontal: horizontalMargin),
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: AppTheme.surfaceHighest.withValues(alpha: 0.5),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: AppTheme.accent.withValues(alpha: 0.4),
          width: 2.0,
        ),
      ),
      child: TabBar(
        isScrollable: isScrollable,
        padding: EdgeInsets.zero,
        tabAlignment: isScrollable ? TabAlignment.start : TabAlignment.fill,
        indicatorPadding: const EdgeInsets.symmetric(
          horizontal: 8, // Uniform gap from the tab edges
          vertical: 2,
        ),
        indicatorSize: TabBarIndicatorSize.tab,
        indicator: BoxDecoration(
          color: AppTheme.accent.withValues(alpha: 0.8),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: AppTheme.accentLight.withValues(alpha: 0.8),
            width: 2.0,
          ),
          boxShadow: [
            BoxShadow(
              color: AppTheme.accent.withValues(alpha: 0.4),
              blurRadius: 10,
              spreadRadius: 1,
            ),
          ],
        ),
        dividerColor: Colors.transparent,
        labelColor: Colors.white,
        unselectedLabelColor: AppTheme.textMuted,
        labelPadding: EdgeInsets.symmetric(horizontal: labelPadding),
        labelStyle: TextStyle(
          fontWeight: FontWeight.bold,
          fontSize: fontSize,
          letterSpacing: 0.5,
        ),
        tabs: labels.map((l) => Tab(text: l)).toList(),
      ),
    );
  }
}

class _AlgoInfoView extends StatelessWidget {
  final AlgoInfo info;
  final bool isTab;

  const _AlgoInfoView({required this.info, required this.isTab});

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: EdgeInsets.fromLTRB(24, 24, 24, isTab ? 32 : 0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      info.title,
                      style: Theme.of(context).textTheme.headlineSmall
                          ?.copyWith(
                            color: AppTheme.accent,
                            fontWeight: FontWeight.bold,
                          ),
                    ),
                    const SizedBox(height: 4),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 4,
                      ),
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
          ...info.keyFeatures.map(
            (feature) => Padding(
              padding: const EdgeInsets.only(bottom: 12.0),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Icon(
                    Icons.check_circle_outline,
                    size: 16,
                    color: AppTheme.success,
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      feature,
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: AppTheme.onBackground,
                        height: 1.3,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
          if (!isTab) const SizedBox(height: 24),
          if (!isTab)
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () => Navigator.pop(context),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppTheme.surfaceHighest,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
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
