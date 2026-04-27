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

final insightCategoryFilterProvider = StateProvider<String>((ref) => "All");

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

    final List<SummaryData> rawItems = listData.map((item) {
      try {
        return SummaryData.fromJson(item);
      } catch (e) {
        debugPrint('Error parsing SummaryData item: $item - $e');
        rethrow;
      }
    }).toList();

    // Aggregate by Algorithm to avoid duplicate bars (e.g. from different segments)
    final Map<String, List<SummaryData>> grouped = {};
    for (var item in rawItems) {
      grouped.putIfAbsent(item.algorithm, () => []).add(item);
    }

    final data = grouped.entries.map((entry) {
      final algo = entry.key;
      final items = entry.value;
      
      int totalRuns = 0;
      double totalNodesWeight = 0;
      double totalTimeWeight = 0;
      
      for (var item in items) {
        totalRuns += item.runCount;
        totalNodesWeight += item.avgNodes * item.runCount;
        totalTimeWeight += item.avgTime * item.runCount;
      }
      
      return SummaryData(
        algorithm: algo,
        avgNodes: totalRuns > 0 ? totalNodesWeight / totalRuns : 0,
        avgTime: totalRuns > 0 ? totalTimeWeight / totalRuns : 0,
        runCount: totalRuns,
      );
    }).toList();
    
    final insights = (res['insights'] as List? ?? []).map((item) {
      try {
        return Insight.fromJson(item);
      } catch (e) {
        debugPrint('Error parsing Insight item: $item - $e');
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
      .map((item) => Insight.fromJson(item))
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
      .map((item) => Insight.fromJson(item))
      .toList();

  return AnalyticsResponse(
    data: data,
    meta: res['meta'] ?? {},
    insights: insights,
  );
});

// ─── Battle Insights Provider ─────────────────────────────────────────────────

final battleInsightsProvider = FutureProvider<AnalyticsResponse<WinnerStat>>((ref) async {
  final api = ref.watch(apiServiceProvider);
  final res = await api.getBattleInsights();
  
  // Backend wraps results in a 'data' object
  final rawData = res['data'] ?? res;
  final List listData = rawData['winnerDistribution'] as List? ?? [];
      
  final data = listData.map((item) => WinnerStat.fromJson(item)).toList();
  
  final insights = (res['insights'] as List? ?? [])
      .map((item) => Insight.fromJson(item))
      .toList();
      
  return AnalyticsResponse(
    data: data,
    meta: res['meta'] ?? {},
    insights: insights,
    battleData: BattleInsightData.fromJson(rawData),
  );
});

// ─── Complexity Provider ──────────────────────────────────────────────────────

final complexityProvider = FutureProvider<AnalyticsResponse<ComplexityDataPoint>>((ref) async {
  final api = ref.watch(apiServiceProvider);
  final res = await api.getComplexity();
  
  // The complexity API returns an array directly as res
  final List<dynamic> listData = (res is List) ? (res as List<dynamic>) : (res['data'] as List<dynamic>? ?? []);
      
  final data = listData.map((item) => ComplexityDataPoint.fromJson(item as Map<String, dynamic>)).toList();
  
  return AnalyticsResponse(
    data: data,
    meta: res['meta'] ?? {},
    insights: [], // No insights for complexity yet
  );
});
