import 'package:flutter/material.dart';

/// Types of analytical insights
enum InsightType { info, success, winner, parity }

/// A single structured observation from the battle analyzer
class AnalysisInsight {
  final String text;
  final InsightType type;
  final IconData icon;

  AnalysisInsight({required this.text, required this.type, required this.icon});
}

/// Metrics for a single algorithm run
class AlgorithmMetrics {
  final String algorithmName;
  final List<dynamic> exploredStates;
  final List<dynamic> path;
  final int totalSteps;
  final Duration executionTime;
  final double pathCost;
  final bool foundPath;

  AlgorithmMetrics({
    required this.algorithmName,
    required this.exploredStates,
    required this.path,
    required this.totalSteps,
    required this.executionTime,
    required this.pathCost,
    required this.foundPath,
  });

  /// Path length / nodes explored ratio (lower is better)
  double get efficiencyScore {
    if (!foundPath || exploredStates.isEmpty) return 0.0;
    return path.length / exploredStates.length;
  }

  /// Time per node explored (lower is better)
  double get speedPerNode {
    if (exploredStates.isEmpty) return double.infinity;
    return executionTime.inMilliseconds / exploredStates.length;
  }

  double get overallScore {
    if (!foundPath) return 0.0;

    // Score components:
    // 1. Efficiency: Useful path nodes vs total explored (Weight: 60%)
    // 2. Parsimony: Total nodes explored (Weight: 20%)
    // 3. Optimality: How close to "perfect" the path is (Weight: 20%)

    final efficiencyPart = efficiencyScore.clamp(0.0, 1.0) * 60;

    // Parsimony: Penalize massive exploration
    final parsimonyRatio = (path.length / (exploredStates.length + 1));
    final parsimonyPart = (parsimonyRatio.clamp(0.0, 1.0)) * 20;

    // For grid problems, moveCost is usually length, but we use pathCost for flexibility
    final optimalityPart =
        20.0; // Currently assuming optimal if foundPath, can be refined

    return efficiencyPart + parsimonyPart + optimalityPart;
  }
}

/// Comparison between two algorithm runs
class BattleResult {
  final AlgorithmMetrics algorithm1;
  final AlgorithmMetrics algorithm2;

  BattleResult({required this.algorithm1, required this.algorithm2});

  /// Winner: prioritized by Path Cost (Optimality) then Explored Nodes (Efficiency)
  AlgorithmMetrics get winner {
    // First, both must have found paths
    if (algorithm1.foundPath && !algorithm2.foundPath) return algorithm1;
    if (algorithm2.foundPath && !algorithm1.foundPath) return algorithm2;

    // If neither found, return arbitrary
    if (!algorithm1.foundPath && !algorithm2.foundPath) return algorithm1;

    // Both found: Primary metric is Path Cost (is it optimal?)
    if (algorithm1.pathCost < algorithm2.pathCost) {
      return algorithm1;
    } else if (algorithm2.pathCost < algorithm1.pathCost) {
      return algorithm2;
    }

    // Tie-breaker: Who explored fewer nodes?
    if (algorithm1.exploredStates.length < algorithm2.exploredStates.length) {
      return algorithm1;
    } else if (algorithm2.exploredStates.length <
        algorithm1.exploredStates.length) {
      return algorithm2;
    }

    // Secondary tie-breaker: execution time
    if (algorithm1.executionTime < algorithm2.executionTime) {
      return algorithm1;
    }

    return algorithm2;
  }

  /// Loser
  AlgorithmMetrics get loser => winner == algorithm1 ? algorithm2 : algorithm1;

  /// Victory margin as percentage (based on nodes explored reduction)
  double get victoryMargin {
    if (!algorithm1.foundPath || !algorithm2.foundPath) return 0.0;

    final wNodes = winner.exploredStates.length;
    final lNodes = loser.exploredStates.length;

    if (lNodes == 0) return 0.0;
    return (((lNodes - wNodes) / lNodes) * 100).abs();
  }

  /// Detailed comparison report
  String getDetailedReport() {
    const separator =
        '━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━';

    final header =
        '''
╔$separator╗
║ ALGORITHM BATTLE RESULTS                                   ║
╠$separator╣
    ''';

    final algo1Report = _formatAlgorithmReport(algorithm1);
    final algo2Report = _formatAlgorithmReport(algorithm2);

    final winnerLine =
        '''
╠$separator╣
║ WINNER: ${winner.algorithmName.padRight(42)} 🏆 ║
║ MARGIN: ${victoryMargin.toStringAsFixed(1).padRight(5)}% exploration reduction${' '.padRight(16)}║
╠$separator╣
    ''';

    final analysis = _generateAnalysis();

    return '''
$header
$algo1Report
║${' '.padRight(60)}║
$algo2Report
$winnerLine
$analysis
╚$separator╝
    ''';
  }

  String _formatAlgorithmReport(AlgorithmMetrics metrics) {
    return '''
║ ${metrics.algorithmName.padRight(58)} ║
║ ────────────────────────────────────────────────────────── ║
║ Explored Nodes: ${metrics.exploredStates.length.toString().padRight(42)} ║
║ Path Cost:      ${metrics.pathCost.toString().padRight(42)} ║
║ Time:           ${metrics.executionTime.inMilliseconds}ms${' '.padRight(47)} ║
║ Score:          ${metrics.overallScore.toStringAsFixed(1)}/100${' '.padRight(43)} ║
    ''';
  }

  String _generateAnalysis() {
    final insights = getAnalysisInsights();

    return '''
║ ANALYSIS:                                                  ║
║${'─' * 58}║
${insights.map((insight) => '║ • ${insight.text.padRight(56)} ║').join('\n')}
    ''';
  }

  /// Returns a structured list of insights for premium UI rendering
  List<AnalysisInsight> getAnalysisInsights() {
    final insights = <AnalysisInsight>[];

    final nodeDiff =
        (algorithm1.exploredStates.length - algorithm2.exploredStates.length)
            .abs();
    final lNodes = loser.exploredStates.length;
    final nodePercent = lNodes > 0 ? (nodeDiff / lNodes * 100) : 0.0;

    insights.add(
      AnalysisInsight(
        text:
            '${winner.algorithmName} reduced exploration by ${nodePercent.toStringAsFixed(1)}%',
        type: InsightType.winner,
        icon: Icons.auto_graph_rounded,
      ),
    );

    if (algorithm1.foundPath && algorithm2.foundPath) {
      if ((algorithm1.pathCost - algorithm2.pathCost).abs() < 0.001) {
        insights.add(
          AnalysisInsight(
            text: 'Both found the optimal path cost (${algorithm1.pathCost})',
            type: InsightType.parity,
            icon: Icons.check_circle_outline_rounded,
          ),
        );
      } else {
        final costDiff = (algorithm1.pathCost - algorithm2.pathCost).abs();
        insights.add(
          AnalysisInsight(
            text:
                '${winner.algorithmName} found a more optimal path (cost -$costDiff)',
            type: InsightType.success,
            icon: Icons.straighten_rounded,
          ),
        );
      }
    }

    if (winner.algorithmName.contains('A*')) {
      insights.add(
        AnalysisInsight(
          text: 'Heuristic guidance successfully pruned sub-optimal branches',
          type: InsightType.info,
          icon: Icons.psychology_rounded,
        ),
      );
    }

    if (loser.pathCost > winner.pathCost && loser.foundPath) {
      insights.add(
        AnalysisInsight(
          text:
              '${loser.algorithmName} found a sub-optimal path; speed over accuracy',
          type: InsightType.info,
          icon: Icons.warning_amber_rounded,
        ),
      );
    }

    return insights;
  }

  /// Summary for UI
  Map<String, dynamic> toUIData() {
    return {
      'algorithm1': {
        'name': algorithm1.algorithmName,
        'explored': algorithm1.exploredStates.length,
        'pathLength': algorithm1.path.length,
        'time': algorithm1.executionTime.inMilliseconds,
        'score': algorithm1.overallScore,
        'efficiency': algorithm1.efficiencyScore,
        'success': algorithm1.foundPath,
      },
      'algorithm2': {
        'name': algorithm2.algorithmName,
        'explored': algorithm2.exploredStates.length,
        'pathLength': algorithm2.path.length,
        'time': algorithm2.executionTime.inMilliseconds,
        'score': algorithm2.overallScore,
        'efficiency': algorithm2.efficiencyScore,
        'success': algorithm2.foundPath,
      },
      'winner': {
        'name': winner.algorithmName,
        'margin': victoryMargin,
        'reason':
            'Explored ${winner.exploredStates.length} nodes vs ${loser.exploredStates.length}',
      },
    };
  }
}

/// Battle orchestrator
class AlgorithmBattle {
  final String name;
  final BattleResult result;
  final DateTime timestamp;

  AlgorithmBattle({
    required this.name,
    required this.result,
    DateTime? timestamp,
  }) : timestamp = timestamp ?? DateTime.now();

  /// Save to replay
  Map<String, dynamic> toReplayData() {
    return {
      'name': name,
      'timestamp': timestamp.toIso8601String(),
      'result': result.toUIData(),
    };
  }
}
