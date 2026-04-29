import 'package:flutter/material.dart';
import 'package:algo_arena/core/app_theme.dart';
import 'package:algo_arena/models/algo_info.dart';
import 'package:algo_arena/widgets/premium_glass_container.dart';
import 'package:algo_arena/widgets/info_cards.dart';

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
      barrierColor: AppTheme.barrier,
      builder: (context) => AlgoInfoModal(
        info: info,
        comparisonInfos: comparisonInfos,
        initialKey: initialKey,
      ),
    );
  }

  static void showComparison(
    BuildContext context,
    Map<String, AlgoInfo> comparisonInfos, {
    String? initialKey,
  }) {
    show(
      context,
      comparisonInfos: comparisonInfos,
      initialKey: initialKey,
    );
  }

  @override
  Widget build(BuildContext context) {
    final showTabs = comparisonInfos != null && (comparisonInfos?.length ?? 0) > 1;

    if (showTabs) {
      final keys = comparisonInfos!.keys.toList();
      final initialIndex = initialKey != null ? keys.indexOf(initialKey!) : 0;
      final isScrollable = keys.length > 3;

      return PremiumGlassContainer(
        radius: 32,
        opacity: 0.9,
        padding: EdgeInsets.zero,
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            AppTheme.accent.withValues(alpha: 0.12),
            AppTheme.accentContainer.withValues(alpha: 0.05),
          ],
        ),
        child: DefaultTabController(
          length: keys.length,
          initialIndex: initialIndex != -1 ? initialIndex : 0,
          child: Container(
            constraints: BoxConstraints(
              maxHeight: MediaQuery.of(context).size.height * 0.85,
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const SizedBox(height: 12),
                _buildHandle(),
                const SizedBox(height: 16),
                _buildTabBar(context, keys, isScrollable: isScrollable),
                Flexible(
                  child: TabBarView(
                    children: keys
                        .map(
                          (k) => _buildUnifiedView(
                            context,
                            comparisonInfos![k]!,
                            isTab: true,
                          ),
                        )
                        .toList(),
                  ),
                ),
              ],
            ),
          ),
        ),
      );
    }

    final targetInfo = info ?? comparisonInfos?.values.first;
    if (targetInfo == null) return const SizedBox.shrink();

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        _buildHandle(),
        _buildUnifiedView(context, targetInfo, isTab: false),
      ],
    );
  }

  Widget _buildUnifiedView(BuildContext context, AlgoInfo info, {required bool isTab}) {
    return UnifiedInfoCard(
      title: info.title,
      subtitle: 'Technical Profile',
      description: info.description,
      headerIcon: Icons.auto_awesome_mosaic_rounded,
      conceptType: info.conceptType,
      features: info.keyFeatures,
      complexity: info.complexity,
      isOptimal: info.isOptimal,
      radius: isTab ? 0 : 32, // Modal handles the radius
      padding: const EdgeInsets.all(24),
      animate: true,
      onAcknowledge: isTab ? null : () => Navigator.pop(context),
    );
  }

  Widget _buildHandle() {
    return Center(
      child: Container(
        width: 40,
        height: 4,
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: 0.2),
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
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 20),
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: Colors.black.withValues(alpha: 0.3),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: AppTheme.accent.withValues(alpha: 0.2),
          width: 1.0,
        ),
      ),
      child: TabBar(
        isScrollable: isScrollable,
        padding: EdgeInsets.zero,
        tabAlignment: isScrollable ? TabAlignment.start : TabAlignment.fill,
        indicatorPadding: const EdgeInsets.all(2),
        indicatorSize: TabBarIndicatorSize.tab,
        indicator: BoxDecoration(
          color: AppTheme.accent.withValues(alpha: 0.2),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: AppTheme.accent.withValues(alpha: 0.4),
          ),
        ),
        dividerColor: Colors.transparent,
        labelColor: Colors.white,
        unselectedLabelColor: AppTheme.textMuted,
        labelStyle: const TextStyle(
          fontWeight: FontWeight.bold,
          fontSize: 12,
          letterSpacing: 0.5,
        ),
        tabs: labels.map((l) => Tab(text: l)).toList(),
      ),
    );
  }
}
