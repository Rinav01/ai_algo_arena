import 'package:algo_arena/models/analytics_models.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:algo_arena/core/app_theme.dart';
import 'package:algo_arena/state/analytics_provider.dart';
import 'package:algo_arena/widgets/analytics/insight_card.dart';
import 'package:algo_arena/widgets/analytics/summary_chart.dart';
import 'package:algo_arena/widgets/analytics/trends_chart.dart';
import 'package:algo_arena/widgets/analytics/distribution_chart.dart';
import 'package:algo_arena/widgets/analytics/analytics_filters.dart';
import 'package:algo_arena/widgets/analytics/analytics_skeleton.dart';
import 'package:algo_arena/widgets/bottom_nav_bar.dart';
import 'package:algo_arena/widgets/analytics/versus_tab_widgets.dart';
import 'package:algo_arena/widgets/analytics/complexity_tab_widgets.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:algo_arena/widgets/info_cards.dart';
import 'package:algo_arena/widgets/premium_glass_container.dart';
import 'package:algo_arena/widgets/feature_tour.dart';

class AnalyticsScreen extends ConsumerStatefulWidget {
  const AnalyticsScreen({super.key});

  @override
  ConsumerState<AnalyticsScreen> createState() => _AnalyticsScreenState();
}

class _AnalyticsScreenState extends ConsumerState<AnalyticsScreen> {
  final GlobalKey _tabsKey = GlobalKey();
  final GlobalKey _filtersKey = GlobalKey();
  final GlobalKey _summaryKey = GlobalKey();
  final GlobalKey _distributionKey = GlobalKey();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      FeatureTour.startTour(
        context: context,
        tourKey: 'analytics_screen',
        steps: [
          TourStep(
            targetKey: _tabsKey,
            title: 'Analytics View tabs',
            description: 'Switch between General metrics, Versus (head-to-head algorithm comparisons), and Complexity classes.',
          ),
          TourStep(
            targetKey: _filtersKey,
            title: 'Refine Data with Filters',
            description: 'Filter analytics by Algorithm Type, specific Algorithm, Grid Scale, or selected metrics.',
          ),
          TourStep(
            targetKey: _summaryKey,
            title: 'Performance Summary',
            description: 'View run metrics breakdown across algorithms in a premium visual summary chart.',
          ),
          TourStep(
            targetKey: _distributionKey,
            title: 'Usage Distribution',
            description: 'Explore the breakdown of your past executions visually.',
          ),
        ],
      );
    });
  }

  void _showDashboardInfo(BuildContext context) {
    showDialog(
      context: context,
      barrierColor: AppTheme.barrier,
      builder: (context) => const Center(
        child: Padding(
          padding: EdgeInsets.symmetric(horizontal: 24),
          child: Material(
            color: Colors.transparent,
            child: DashboardInfoCard(),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 3,
      child: Scaffold(
        backgroundColor: AppTheme.background,
        appBar: AppBar(
          backgroundColor: AppTheme.background,
          elevation: 0,
          toolbarHeight: 100, // accommodate the header text
          flexibleSpace: ClipRect(
            child: Stack(
              children: [
                Positioned(
                  right: -20,
                  top: -10,
                  child: IgnorePointer(
                    child: Icon(
                      Icons.leaderboard_rounded,
                      size: 160,
                      color: AppTheme.accent.withValues(alpha: 0.05),
                    ),
                  ),
                ),
                SafeArea(
                  child: Padding(
                    padding: const EdgeInsetsDirectional.fromSTEB(72, 24, 20, 0),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              "Analytics Dashboard",
                              style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                                    fontWeight: FontWeight.w800,
                                    color: AppTheme.onBackground,
                                    letterSpacing: -0.5,
                                  ),
                            ),
                            Text(
                              "Algorithm Performance Metrics",
                              style: Theme.of(context).textTheme.labelMedium?.copyWith(
                                    color: AppTheme.textSecondary,
                                    letterSpacing: 1.2,
                                  ),
                            ),
                          ],
                        ),
                        IconButton(
                          icon: const Icon(Icons.info_outline_rounded, color: AppTheme.accentLight),
                          onPressed: () => _showDashboardInfo(context),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
          bottom: PreferredSize(
            preferredSize: const Size.fromHeight(48),
            child: KeyedSubtree(
              key: _tabsKey,
              child: const TabBar(
                indicatorColor: AppTheme.accent,
                labelColor: AppTheme.accent,
                unselectedLabelColor: AppTheme.textMuted,
                indicatorWeight: 3,
                tabs: [
                  Tab(text: "General"),
                  Tab(text: "Versus"),
                  Tab(text: "Complexity"),
                ],
              ),
            ),
          ),
        ),
        body: Stack(
          children: [
            // Background Watermark
            Positioned(
              left: -50,
              bottom: 100,
              child: Opacity(
                opacity: 0.03,
                child: Icon(
                  Icons.analytics_outlined,
                  size: 400,
                  color: AppTheme.accent,
                ),
              ),
            ),
            TabBarView(
              children: [
                _GeneralTab(
                  filtersKey: _filtersKey,
                  summaryKey: _summaryKey,
                  distributionKey: _distributionKey,
                ),
                const VersusTabContent(),
                const ComplexityTabContent(),
              ],
            ),
          ],
        ),
        bottomNavigationBar: const ArenaBottomNavBar(currentIndex: 3),
      ),
    );
  }
}

class _GeneralTab extends ConsumerWidget {
  final GlobalKey filtersKey;
  final GlobalKey summaryKey;
  final GlobalKey distributionKey;

  const _GeneralTab({
    required this.filtersKey,
    required this.summaryKey,
    required this.distributionKey,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final summaryAsync = ref.watch(summaryProvider);
    final trendsAsync = ref.watch(trendsProvider);
    final distributionAsync = ref.watch(distributionProvider);
    final filters = ref.watch(analyticsFiltersProvider);

    return RefreshIndicator(
      onRefresh: () async {
        ref.invalidate(summaryProvider);
        ref.invalidate(trendsProvider);
        ref.invalidate(distributionProvider);
      },
      color: AppTheme.accent,
      backgroundColor: AppTheme.surfaceHigh,
      child: CustomScrollView(
        physics: const BouncingScrollPhysics(),
        slivers: [
          // ─── Filters ────────────────────────────────────────────────────────
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
              child: KeyedSubtree(
                key: filtersKey,
                child: const AnalyticsFiltersBar(),
              ),
            ),
          ),

          // ─── Content ────────────────────────────────────────────────────────
          summaryAsync.when(
            loading: () => const SliverFillRemaining(child: AnalyticsSkeleton()),
            error: (err, stack) => SliverFillRemaining(
              child: _ErrorState(onRetry: () => ref.invalidate(summaryProvider)),
            ),
            data: (summaryRes) {
              if (summaryRes.data.isEmpty) {
                return const SliverFillRemaining(child: _EmptyState());
              }

              final selectedInsightCategory = ref.watch(insightCategoryFilterProvider);

              // Sort and filter insights
              final allInsights = [...summaryRes.insights];
              allInsights.sort((a, b) {
                // Prioritize High severity, then Confidence
                if (a.severity == 'high' && b.severity != 'high') return -1;
                if (a.severity != 'high' && b.severity == 'high') return 1;
                return b.confidence.compareTo(a.confidence);
              });

              final filteredInsights = selectedInsightCategory == "All"
                  ? allInsights
                  : allInsights.where((i) => i.type.toLowerCase() == selectedInsightCategory.toLowerCase()).toList();

              final topInsight = allInsights.isNotEmpty && allInsights.first.severity == 'high' ? allInsights.first : null;

              return SliverPadding(
                padding: EdgeInsets.symmetric(
                  horizontal: MediaQuery.of(context).size.width * 0.05,
                  vertical: 20,
                ),
                sliver: SliverList(
                  delegate: SliverChildListDelegate([
                    // ─── Insight Section ─────────────────────────────────────────
                    if (allInsights.isNotEmpty) ...[
                      const _SectionHeader(label: "SMART INSIGHTS"),
                      const SizedBox(height: 16),
                      
                      // Highlight Top Insight
                      if (topInsight != null) ...[
                        _TopInsightHighlight(insight: topInsight),
                        const SizedBox(height: 20),
                      ],

                      // Filter Chips
                      SingleChildScrollView(
                        scrollDirection: Axis.horizontal,
                        child: Row(
                          children: ["All", "Performance", "Warning", "Recommendation", "Trend"].map((cat) {
                            final isSelected = selectedInsightCategory == cat;
                            return Padding(
                              padding: const EdgeInsets.only(right: 8),
                              child: ChoiceChip(
                                label: Text(cat),
                                selected: isSelected,
                                onSelected: (val) {
                                  if (val) ref.read(insightCategoryFilterProvider.notifier).state = cat;
                                },
                                backgroundColor: AppTheme.surfaceVariant.withValues(alpha: 0.3),
                                selectedColor: AppTheme.accent.withValues(alpha: 0.2),
                                labelStyle: TextStyle(
                                  color: isSelected ? AppTheme.accentLight : AppTheme.textMuted,
                                  fontSize: 12,
                                  fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                                ),
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                                side: BorderSide(
                                  color: isSelected ? AppTheme.accent.withValues(alpha: 0.5) : Colors.transparent,
                                ),
                              ),
                            );
                          }).toList(),
                        ),
                      ),
                      const SizedBox(height: 16),

                      // Carousel
                      SizedBox(
                        height: (MediaQuery.sizeOf(context).height * 0.3).clamp(200.0, 300.0),
                        child: filteredInsights.isEmpty
                            ? Center(
                                child: Text(
                                  "No $selectedInsightCategory insights found",
                                  style: const TextStyle(color: AppTheme.textMuted),
                                ),
                              )
                            : ListView.builder(
                                scrollDirection: Axis.horizontal,
                                physics: const BouncingScrollPhysics(),
                                itemCount: filteredInsights.length,
                                itemBuilder: (context, index) {
                                  final insight = filteredInsights[index];
                                  return InsightCard(
                                    insight: insight,
                                    onTap: () => _showInsightDetails(context, insight),
                                  );
                                },
                              ),
                      ),
                      const SizedBox(height: 32),
                    ],

                    // ─── Summary Section ────────────────────────────────────────
                    const _SectionHeader(label: "PERFORMANCE SUMMARY"),
                    const SizedBox(height: 16),
                    KeyedSubtree(
                      key: summaryKey,
                      child: SummaryBarChart(
                        data: summaryRes.data,
                        metric: filters.metric ?? 'nodes',
                      ),
                    ),
                    const SizedBox(height: 32),

                    // ─── Trends Section ─────────────────────────────────────────
                    const _SectionHeader(label: "PERFORMANCE TRENDS"),
                    const SizedBox(height: 16),
                    trendsAsync.when(
                      data: (trendsRes) => TrendsLineChart(
                        data: trendsRes.data,
                        metric: filters.metric ?? 'nodes',
                      ),
                      loading: () => _SkeletonPlaceholder(
                        height: (MediaQuery.sizeOf(context).height * 0.4).clamp(300.0, 450.0),
                      ),
                      error: (err, stack) => const SizedBox.shrink(),
                    ),
                    const SizedBox(height: 32),

                    // ─── Distribution Section ────────────────────────────────────
                    const _SectionHeader(label: "USAGE DISTRIBUTION"),
                    const SizedBox(height: 16),
                    KeyedSubtree(
                      key: distributionKey,
                      child: distributionAsync.when(
                        data: (distRes) => DistributionPieChart(data: distRes.data),
                        loading: () => _SkeletonPlaceholder(
                          height: (MediaQuery.sizeOf(context).height * 0.35).clamp(250.0, 400.0),
                        ),
                        error: (err, stack) => const SizedBox.shrink(),
                      ),
                    ),
                    const SizedBox(height: 100),
                  ]),
                ),
              );
            },
          ),
        ],
      ),
    );
  }
}



class _SectionHeader extends StatelessWidget {
  final String label;
  const _SectionHeader({required this.label});

  @override
  Widget build(BuildContext context) {
    return Text(
      label,
      style: Theme.of(context).textTheme.labelSmall?.copyWith(
            color: AppTheme.accentLight,
            letterSpacing: 2,
            fontWeight: FontWeight.bold,
          ),
    );
  }
}

class _SkeletonPlaceholder extends StatelessWidget {
  final double height;
  const _SkeletonPlaceholder({required this.height});

  @override
  Widget build(BuildContext context) {
    return Container(
      height: height,
      decoration: BoxDecoration(
        color: AppTheme.surfaceVariant.withValues(alpha: 0.3),
        borderRadius: BorderRadius.circular(20),
      ),
    ).animate(onPlay: (c) => c.repeat()).shimmer(duration: 1500.ms);
  }
}

class _ErrorState extends StatelessWidget {
  final VoidCallback onRetry;
  const _ErrorState({required this.onRetry});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.cloud_off_rounded, size: 64, color: AppTheme.error),
          const SizedBox(height: 16),
          Text(
            "Failed to load analytics",
            style: Theme.of(context).textTheme.titleLarge,
          ),
          const SizedBox(height: 8),
          ElevatedButton(
            onPressed: onRetry,
            child: const Text("RETRY"),
          ),
        ],
      ),
    );
  }
}

class _EmptyState extends StatelessWidget {
  const _EmptyState();

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.bar_chart_rounded, size: 64, color: AppTheme.textMuted),
          const SizedBox(height: 16),
          Text(
            "No data yet",
            style: Theme.of(context).textTheme.titleLarge?.copyWith(color: AppTheme.textMuted),
          ),
          const SizedBox(height: 8),
          Text(
            "Run some algorithms to see insights",
            style: Theme.of(context).textTheme.bodySmall?.copyWith(color: AppTheme.textMuted),
          ),
        ],
      ),
    );
  }
}

class _TopInsightHighlight extends StatelessWidget {
  final Insight insight;
  const _TopInsightHighlight({required this.insight});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            AppTheme.error.withValues(alpha: 0.15),
            AppTheme.error.withValues(alpha: 0.05),
          ],
        ),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppTheme.error.withValues(alpha: 0.3)),
      ),
      child: Row(
        children: [
          const Icon(Icons.auto_awesome_rounded, color: AppTheme.error, size: 24),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  "TOP INSIGHT: ${insight.title}",
                  style: Theme.of(context).textTheme.labelSmall?.copyWith(
                        color: AppTheme.error,
                        fontWeight: FontWeight.w900,
                        letterSpacing: 1.2,
                      ),
                ),
                const SizedBox(height: 4),
                Text(
                  insight.message,
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: Colors.white.withValues(alpha: 0.9),
                      ),
                ),
              ],
            ),
          ),
        ],
      ));
  }
}

void _showInsightDetails(BuildContext context, Insight insight) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (context) => PremiumGlassContainer(
        radius: 32,
        height: MediaQuery.of(context).size.height * 0.65,
        padding: const EdgeInsets.all(24.0),
        child: Column(
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
                    children: [
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: insight.getSeverityColor().withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(16),
                        ),
                        child: Icon(
                          insight.getIcon(),
                          color: insight.getSeverityColor(),
                          size: 32,
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              insight.type.toUpperCase(),
                              style: const TextStyle(
                                color: AppTheme.accent,
                                fontSize: 12,
                                fontWeight: FontWeight.bold,
                                letterSpacing: 1.2,
                              ),
                            ),
                            Text(
                              insight.title,
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 22,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 24),
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.05),
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Text(
                      insight.message,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 16,
                        height: 1.4,
                      ),
                    ),
                  ),
                  const SizedBox(height: 24),
                  const Text(
                    "ENGINEERING ANALYSIS",
                    style: TextStyle(
                      color: AppTheme.textMuted,
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 1.1,
                    ),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    insight.reason ?? "No detailed reason provided for this insight.",
                    style: TextStyle(
                      color: Colors.white.withValues(alpha: 0.7),
                      fontSize: 15,
                      height: 1.5,
                    ),
                  ),
                  const Spacer(),
                  // Metrics Grid
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      _MetricDetail(
                        label: "CONFIDENCE",
                        value: "${(insight.confidence * 100).toInt()}%",
                        color: AppTheme.success,
                      ),
                      _MetricDetail(
                        label: "SEVERITY",
                        value: insight.severity.toUpperCase(),
                        color: insight.getSeverityColor(),
                      ),
                      if (insight.context?['algorithm'] != null)
                        _MetricDetail(
                          label: "TARGET",
                          value: insight.context!['algorithm'],
                          color: AppTheme.accent,
                        ),
                    ],
                  ),
                  const SizedBox(height: 32),
                ],
              ),
            ),
    );
  }


class _MetricDetail extends StatelessWidget {
  final String label;
  final String value;
  final Color color;

  const _MetricDetail({
    required this.label,
    required this.value,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(
            color: AppTheme.textMuted,
            fontSize: 10,
            fontWeight: FontWeight.bold,
            letterSpacing: 1,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          value,
          style: TextStyle(
            color: color,
            fontSize: 16,
            fontWeight: FontWeight.w900,
          ),
        ),
      ],
    );
  }
}
