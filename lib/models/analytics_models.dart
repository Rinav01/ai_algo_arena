/// Data models for the Analytics dashboard.

class SummaryData {
  final String algorithm;
  final double avgNodes;
  final double avgTime;
  final int runCount;

  SummaryData({
    required this.algorithm,
    required this.avgNodes,
    required this.avgTime,
    required this.runCount,
  });

  factory SummaryData.fromJson(Map<String, dynamic> json) {
    // Backend might return nodes at top level or nested in metrics
    final metrics = json['metrics'] ?? {};
    
    return SummaryData(
      algorithm: json['algorithm'] ?? 'Unknown',
      avgNodes: (json['avgNodes'] ?? metrics['nodes'] ?? 0).toDouble(),
      avgTime: (json['avgTime'] ?? metrics['time'] ?? 0).toDouble(),
      runCount: json['totalRuns'] ?? json['count'] ?? metrics['runs'] ?? 0,
    );
  }
}

class TrendPoint {
  final DateTime date;
  final double value;

  TrendPoint({required this.date, required this.value});

  factory TrendPoint.fromJson(Map<String, dynamic> json, String metric) {
    final metrics = json['metrics'] ?? {};
    final isNodes = metric == 'nodes';
    
    // Check various possible backend keys
    final value = isNodes 
      ? (json['avgNodes'] ?? json['nodes'] ?? metrics['nodes'] ?? 0)
      : (json['avgTime'] ?? json['time'] ?? metrics['time'] ?? 0);

    // Check various possible backend keys for date
    final dateStr = json['date'] ?? json['_id'] ?? json['createdAt'];
    if (dateStr == null) throw Exception('TrendPoint: Date field missing in $json');

    return TrendPoint(
      date: DateTime.parse(dateStr),
      value: value.toDouble(),
    );
  }
}

class TrendData {
  final String algorithm;
  final List<TrendPoint> points;

  TrendData({required this.algorithm, required this.points});

  factory TrendData.fromJson(Map<String, dynamic> json, String metric) {
    return TrendData(
      algorithm: json['algorithm'] ?? 'Unknown',
      points: (json['points'] as List? ?? [])
          .map((p) => TrendPoint.fromJson(p, metric))
          .toList(),
    );
  }
}

class DistributionData {
  final String algorithm;
  final double percentage;
  final int count;

  DistributionData({
    required this.algorithm,
    required this.percentage,
    required this.count,
  });

  factory DistributionData.fromJson(Map<String, dynamic> json) {
    return DistributionData(
      algorithm: json['algorithm'] ?? 'Unknown',
      percentage: (json['percentage'] ?? 0).toDouble(),
      count: json['count'] ?? 0,
    );
  }
}

class BattleInsight {
  final String title;
  final String description;
  final String type; // e.g., "efficiency", "speed", "complexity"
  final String impact; // e.g., "35% fewer nodes"

  BattleInsight({
    required this.title,
    required this.description,
    required this.type,
    required this.impact,
  });

  factory BattleInsight.fromJson(dynamic json) {
    if (json is String) {
      return BattleInsight(
        title: 'Quick Tip',
        description: json,
        type: 'general',
        impact: 'Insight',
      );
    }
    
    final map = json as Map<String, dynamic>;
    return BattleInsight(
      title: map['title'] ?? 'Insight',
      description: map['description'] ?? '',
      type: map['type'] ?? 'general',
      impact: map['impact'] ?? '',
    );
  }
}

class WinnerStat {
  final String winner;
  final int count;
  final double avgNodesDiff;
  final double avgTimeDiff;

  WinnerStat({
    required this.winner,
    required this.count,
    required this.avgNodesDiff,
    required this.avgTimeDiff,
  });

  factory WinnerStat.fromJson(Map<String, dynamic> json) {
    return WinnerStat(
      winner: json['winner'] ?? 'Unknown',
      count: json['count'] ?? 0,
      avgNodesDiff: (json['avgNodesDiff'] ?? 0).toDouble(),
      avgTimeDiff: (json['avgTimeDiff'] ?? 0).toDouble(),
    );
  }
}

class BattleInsightData {
  final int totalBattles;
  final List<WinnerStat> winnerDistribution;

  BattleInsightData({
    required this.totalBattles,
    required this.winnerDistribution,
  });

  factory BattleInsightData.fromJson(Map<String, dynamic> json) {
    return BattleInsightData(
      totalBattles: json['totalBattles'] ?? 0,
      winnerDistribution: (json['winnerDistribution'] as List? ?? [])
          .map((w) => WinnerStat.fromJson(w))
          .toList(),
    );
  }
}

class ComplexityDataPoint {
  final String algorithm;
  final String? heuristic;
  final double durationMs;
  final double obstacleDensity;

  ComplexityDataPoint({
    required this.algorithm,
    this.heuristic,
    required this.durationMs,
    required this.obstacleDensity,
  });

  factory ComplexityDataPoint.fromJson(Map<String, dynamic> json) {
    return ComplexityDataPoint(
      algorithm: json['algorithm'] ?? 'Unknown',
      heuristic: json['heuristic'],
      durationMs: (json['durationMs'] ?? 0).toDouble(),
      obstacleDensity: (json['obstacleDensity'] ?? 0).toDouble(),
    );
  }
}

class AnalyticsResponse<T> {
  final List<T> data;
  final Map<String, dynamic> meta;
  final List<BattleInsight> insights;
  final BattleInsightData? battleData; // Optional field for battle stats

  AnalyticsResponse({
    required this.data,
    required this.meta,
    required this.insights,
    this.battleData,
  });
}
