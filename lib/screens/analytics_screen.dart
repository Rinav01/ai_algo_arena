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

class AnalyticsScreen extends ConsumerWidget {
  const AnalyticsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return DefaultTabController(
      length: 3,
      child: Scaffold(
        backgroundColor: AppTheme.background,
        appBar: AppBar(
          backgroundColor: AppTheme.background,
          elevation: 0,
          toolbarHeight: 100, // accommodate the header text
          flexibleSpace: SafeArea(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(20, 24, 20, 0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    "Analytics Dashboard",
                    style: Theme.of(context).textTheme.displayMedium,
                  ).animate().fadeIn().slideY(begin: 0.2),
                  const SizedBox(height: 8),
                  Text(
                    "Scan · Compare · Understand performance in seconds",
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          color: AppTheme.textMuted,
                        ),
                  ).animate().fadeIn(delay: 200.ms),
                ],
              ),
            ),
          ),
          bottom: const TabBar(
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
        body: TabBarView(
          children: [
            _GeneralTab(),
            VersusTabContent(),
            ComplexityTabContent(),
          ],
        ),
        bottomNavigationBar: const ArenaBottomNavBar(currentIndex: 3),
      ),
    );
  }
}

class _GeneralTab extends ConsumerWidget {

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
          const SliverToBoxAdapter(
            child: Padding(
              padding: EdgeInsets.fromLTRB(20, 16, 20, 0),
              child: AnalyticsFiltersBar(),
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

              return SliverPadding(
                padding: const EdgeInsets.all(20),
                sliver: SliverList(
                  delegate: SliverChildListDelegate([
                    // ─── Insight Cards ──────────────────────────────────────────
                    if (summaryRes.insights.isNotEmpty) ...[
                      const _SectionHeader(label: "🧠 SMART INSIGHTS"),
                      const SizedBox(height: 16),
                      SizedBox(
                        height: 180,
                        child: ListView.builder(
                          scrollDirection: Axis.horizontal,
                          itemCount: summaryRes.insights.length,
                          itemBuilder: (context, index) {
                            return InsightCard(insight: summaryRes.insights[index]);
                          },
                        ),
                      ),
                      const SizedBox(height: 32),
                    ],

                    // ─── Summary Section ────────────────────────────────────────
                    const _SectionHeader(label: "📊 PERFORMANCE SUMMARY"),
                    const SizedBox(height: 16),
                    SummaryBarChart(
                      data: summaryRes.data,
                      metric: filters.metric ?? 'nodes',
                    ),
                    const SizedBox(height: 32),

                    // ─── Trends Section ─────────────────────────────────────────
                    const _SectionHeader(label: "📈 PERFORMANCE TRENDS"),
                    const SizedBox(height: 16),
                    trendsAsync.when(
                      data: (trendsRes) => TrendsLineChart(
                        data: trendsRes.data,
                        metric: filters.metric ?? 'nodes',
                      ),
                      loading: () => const _SkeletonPlaceholder(height: 350),
                      error: (_, __) => const SizedBox.shrink(),
                    ),
                    const SizedBox(height: 32),

                    // ─── Distribution Section ────────────────────────────────────
                    const _SectionHeader(label: "🥧 USAGE DISTRIBUTION"),
                    const SizedBox(height: 16),
                    distributionAsync.when(
                      data: (distRes) => DistributionPieChart(data: distRes.data),
                      loading: () => const _SkeletonPlaceholder(height: 300),
                      error: (_, __) => const SizedBox.shrink(),
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
