import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../services/api_service.dart';
import '../models/analytics_models.dart';

final apiServiceProvider = Provider((ref) => ApiService());

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
  final api = ref.watch(apiServiceProvider);
  final filters = ref.watch(analyticsFiltersProvider);
  
  final res = await api.getSummary(
    algorithm: filters.algorithm,
    startDate: filters.startDate,
    endDate: filters.endDate,
  );

  try {
    final rawData = res['data'];
    debugPrint('Analytics Summary rawData: $rawData');
    final List listData = (rawData is Map) 
        ? (rawData['byAlgorithm'] as List? ?? []) 
        : (rawData as List? ?? []);

    debugPrint('Analytics Summary listData: $listData');

    final data = listData.map((item) {
      try {
        return SummaryData.fromJson(item);
      } catch (e) {
        debugPrint('Error parsing SummaryData item: $item - $e');
        rethrow;
      }
    }).toList();
    
    final insights = (res['insights'] as List? ?? []).map((item) {
      try {
        return BattleInsight.fromJson(item);
      } catch (e) {
        debugPrint('Error parsing BattleInsight item: $item - $e');
        rethrow;
      }
    }).toList();

    debugPrint('Analytics Summary parsed successfully: ${data.length} items');

    return AnalyticsResponse(
      data: data,
      meta: res['meta'] ?? {},
      insights: insights,
    );
  } catch (e, stack) {
    debugPrint('CRITICAL: Analytics Summary Provider Error: $e');
    debugPrint(stack.toString());
    rethrow;
  }
});

// ─── Trends Provider ─────────────────────────────────────────────────────────

final trendsProvider = FutureProvider<AnalyticsResponse<TrendData>>((ref) async {
  final api = ref.watch(apiServiceProvider);
  final filters = ref.watch(analyticsFiltersProvider);
  
  final res = await api.getTrends(
    algorithm: filters.algorithm,
    metric: filters.metric,
  );

  final rawData = res['data'];
  final List trendsList = (rawData is Map) 
      ? (rawData['trends'] as List? ?? []) 
      : (rawData as List? ?? []);

  // Map flat trends to a single TrendData object
  final points = trendsList
      .map((item) => TrendPoint.fromJson(item, filters.metric ?? 'nodes'))
      .toList();
      
  final data = points.isNotEmpty 
      ? [TrendData(algorithm: filters.algorithm ?? 'All Algorithms', points: points)]
      : <TrendData>[];
  
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
  final api = ref.watch(apiServiceProvider);
  
  final res = await api.getDistribution();

  final rawData = res['data'];
  debugPrint('Analytics Summary rawData: $rawData');
  final List listData = (rawData is Map) 
      ? (rawData['distribution'] as List? ?? []) 
      : (rawData as List? ?? []);

  final total = listData.fold<int>(0, (sum, item) => sum + (item['count'] as int? ?? 0));

  final data = listData.map((item) {
    final count = item['count'] as int? ?? 0;
    return DistributionData(
      algorithm: item['algorithm'] ?? 'Unknown',
      count: count,
      percentage: total > 0 ? (count / total * 100) : 0.0,
    );
  }).toList();
  
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
  final api = ref.watch(apiServiceProvider);
  final res = await api.getBattleInsights();
  
  return (res['insights'] as List? ?? [])
      .map((item) => BattleInsight.fromJson(item))
      .toList();
});
