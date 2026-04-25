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
    return SummaryData(
      algorithm: json['algorithm'] ?? 'Unknown',
      avgNodes: (json['avgNodes'] ?? 0).toDouble(),
      avgTime: (json['avgTime'] ?? 0).toDouble(),
      runCount: json['runCount'] ?? 0,
    );
  }
}

class TrendPoint {
  final DateTime date;
  final double value;

  TrendPoint({required this.date, required this.value});

  factory TrendPoint.fromJson(Map<String, dynamic> json) {
    return TrendPoint(
      date: DateTime.parse(json['date']),
      value: (json['value'] ?? 0).toDouble(),
    );
  }
}

class TrendData {
  final String algorithm;
  final List<TrendPoint> points;

  TrendData({required this.algorithm, required this.points});

  factory TrendData.fromJson(Map<String, dynamic> json) {
    return TrendData(
      algorithm: json['algorithm'] ?? 'Unknown',
      points: (json['points'] as List? ?? [])
          .map((p) => TrendPoint.fromJson(p))
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

  factory BattleInsight.fromJson(Map<String, dynamic> json) {
    return BattleInsight(
      title: json['title'] ?? '',
      description: json['description'] ?? '',
      type: json['type'] ?? 'general',
      impact: json['impact'] ?? '',
    );
  }
}

class AnalyticsResponse<T> {
  final List<T> data;
  final Map<String, dynamic> meta;
  final List<BattleInsight> insights;

  AnalyticsResponse({
    required this.data,
    required this.meta,
    required this.insights,
  });
}
