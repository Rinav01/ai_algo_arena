import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../services/analytics_api_service.dart';
import '../models/analytics_models.dart';

final analyticsApiServiceProvider = Provider((ref) => AnalyticsApiService());

// ─── Filters State ───────────────────────────────────────────────────────────

class AnalyticsFilters {
  final String? algorithm;
  final String? metric;
  final String? startDate;
  final String? endDate;

  AnalyticsFilters({
    this.algorithm = "All",
    this.metric = "nodes",
    this.startDate,
    this.endDate,
  });

  AnalyticsFilters copyWith({
    String? algorithm,
    String? metric,
    String? startDate,
    String? endDate,
  }) {
    return AnalyticsFilters(
      algorithm: algorithm ?? this.algorithm,
      metric: metric ?? this.metric,
      startDate: startDate ?? this.startDate,
      endDate: endDate ?? this.endDate,
    );
  }
}

final analyticsFiltersProvider = StateProvider<AnalyticsFilters>((ref) => AnalyticsFilters());

// ─── Summary Provider ────────────────────────────────────────────────────────

final summaryProvider = FutureProvider<AnalyticsResponse<SummaryData>>((ref) async {
  final api = ref.watch(analyticsApiServiceProvider);
  final filters = ref.watch(analyticsFiltersProvider);
  
  final res = await api.getSummary(
    algorithm: filters.algorithm,
    startDate: filters.startDate,
    endDate: filters.endDate,
  );

  final data = (res['data'] as List? ?? [])
      .map((item) => SummaryData.fromJson(item))
      .toList();
  
  final insights = (res['insights'] as List? ?? [])
      .map((item) => BattleInsight.fromJson(item))
      .toList();

  return AnalyticsResponse(
    data: data,
    meta: res['meta'] ?? {},
    insights: insights,
  );
});

// ─── Trends Provider ─────────────────────────────────────────────────────────

final trendsProvider = FutureProvider<AnalyticsResponse<TrendData>>((ref) async {
  final api = ref.watch(analyticsApiServiceProvider);
  final filters = ref.watch(analyticsFiltersProvider);
  
  final res = await api.getTrends(
    algorithm: filters.algorithm,
    metric: filters.metric,
  );

  final data = (res['data'] as List? ?? [])
      .map((item) => TrendData.fromJson(item))
      .toList();
  
  final insights = (res['insights'] as List? ?? [])
      .map((item) => BattleInsight.fromJson(item))
      .toList();

  return AnalyticsResponse(
    data: data,
    meta: res['meta'] ?? {},
    insights: insights,
  );
});

// ─── Distribution Provider ────────────────────────────────────────────────────

final distributionProvider = FutureProvider<AnalyticsResponse<DistributionData>>((ref) async {
  final api = ref.watch(analyticsApiServiceProvider);
  
  final res = await api.getDistribution();

  final data = (res['data'] as List? ?? [])
      .map((item) => DistributionData.fromJson(item))
      .toList();
  
  final insights = (res['insights'] as List? ?? [])
      .map((item) => BattleInsight.fromJson(item))
      .toList();

  return AnalyticsResponse(
    data: data,
    meta: res['meta'] ?? {},
    insights: insights,
  );
});

// ─── Battle Insights Provider ─────────────────────────────────────────────────

final battleInsightsProvider = FutureProvider<List<BattleInsight>>((ref) async {
  final api = ref.watch(analyticsApiServiceProvider);
  final res = await api.getBattleInsights();
  
  return (res['insights'] as List? ?? [])
      .map((item) => BattleInsight.fromJson(item))
      .toList();
});
