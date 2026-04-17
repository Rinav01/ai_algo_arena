import 'dart:math';
import 'package:flutter/material.dart';

/// Types of analytical insights
enum InsightType { info, success, winner, parity }

/// A single structured observation from the battle analyzer
class AnalysisInsight {
  final String text;
  final InsightType type;
  final IconData icon;

  AnalysisInsight({
    required this.text,
    required this.type,
    required this.icon,
  });
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

  /// Overall score (0-100) - weighted combination
  double get overallScore {
    if (!foundPath) return 0.0;

    // Score components:
    // 1. Efficiency: Path length vs explored nodes (weight: 40%)
    // 2. Speed: Fewer explored nodes (weight: 40%)
    // 3. Path optimality: Shorter path (weight: 20%)

    final maxExplored = max(200, exploredStates.length.toDouble());
    final exploredScore =
        (1.0 - (exploredStates.length / maxExplored).clamp(0.0, 1.0)) * 100;

    final pathScore = (efficiencyScore.clamp(0.0, 1.0)) * 100;

    return (exploredScore * 0.4) + (pathScore * 0.6);
  }
}

/// Comparison between two algorithm runs
class BattleResult {
  final AlgorithmMetrics algorithm1;
  final AlgorithmMetrics algorithm2;

  BattleResult({required this.algorithm1, required this.algorithm2});

  /// Winner: algorithm that found path with fewer explored nodes
  AlgorithmMetrics get winner {
    // First, both must have found paths
    if (algorithm1.foundPath && !algorithm2.foundPath) return algorithm1;
    if (algorithm2.foundPath && !algorithm1.foundPath) return algorithm2;

    // If neither found, return arbitrary
    if (!algorithm1.foundPath && !algorithm2.foundPath) return algorithm1;

    // Both found paths: winner is who explored fewer nodes
    if (algorithm1.exploredStates.length < algorithm2.exploredStates.length) {
      return algorithm1;
    } else if (algorithm2.exploredStates.length <
        algorithm1.exploredStates.length) {
      return algorithm2;
    }

    // If same explored, who has shorter path?
    if (algorithm1.path.length < algorithm2.path.length) {
      return algorithm1;
    }

    return algorithm2;
  }

  /// Loser
  AlgorithmMetrics get loser => winner == algorithm1 ? algorithm2 : algorithm1;

  /// Victory margin as percentage
  double get victoryMargin {
    if (!algorithm1.foundPath || !algorithm2.foundPath) return 0.0;

    final margin =
        ((algorithm2.exploredStates.length - algorithm1.exploredStates.length) /
            algorithm2.exploredStates.length) *
        100;

    return margin.abs();
  }

  /// Detailed comparison report
  String getDetailedReport() {
    final separator = List.filled(60, '━').join();

    final header =
        '''
╔$separator╗
║ ALGORITHM BATTLE RESULTS
║$separator║
    ''';

    final algo1Report = _formatAlgorithmReport(algorithm1);
    final algo2Report = _formatAlgorithmReport(algorithm2);

    final winnerLine =
        '''
╠$separator╣
║ WINNER: ${winner.algorithmName.padRight(40)} 🏆
║ Margin: ${victoryMargin.toStringAsFixed(1).padRight(5)}%
║$separator║
    ''';

    final analysis = _generateAnalysis();

    return '''
$header
$algo1Report

$algo2Report
$winnerLine
$analysis
╚$separator╝
    ''';
  }

  String _formatAlgorithmReport(AlgorithmMetrics metrics) {
    return '''
║ ${metrics.algorithmName.padRight(58)}║
║ ─────────────────────────────────────────────────────────── ║
║ Explored Nodes: ${metrics.exploredStates.length.toString().padRight(40)}║
║ Path Length:    ${metrics.path.length.toString().padRight(40)}║
║ Steps:          ${metrics.totalSteps.toString().padRight(40)}║
║ Time:           ${metrics.executionTime.inMilliseconds}ms${' '.padRight(45)}║
║ Efficiency:     ${metrics.efficiencyScore.toStringAsFixed(3).padRight(40)}║
║ Score:          ${metrics.overallScore.toStringAsFixed(1)}/100${' '.padRight(41)}║
    ''';
  }

  String _generateAnalysis() {
    final reasons = <String>[];
    final insights = getAnalysisInsights();
    
    for (final insight in insights) {
      reasons.add(insight.text);
    }

    return '''
║ ANALYSIS:
║${'─' * 58}║
${reasons.map((r) => '║ $r${' '.padRight(58 - r.length)}║').join('\n')}
    ''';
  }

  /// Returns a structured list of insights for premium UI rendering
  List<AnalysisInsight> getAnalysisInsights() {
    final insights = <AnalysisInsight>[];

    final nodeDiff = (algorithm2.exploredStates.length - algorithm1.exploredStates.length).abs();
    final maxNodes = max(algorithm1.exploredStates.length, algorithm2.exploredStates.length);
    final nodePercent = (nodeDiff / (maxNodes + 1) * 100);
    
    insights.add(
      AnalysisInsight(
        text: '${winner.algorithmName} explored $nodeDiff fewer nodes (${nodePercent.toStringAsFixed(1)}% reduction)',
        type: InsightType.winner,
        icon: Icons.auto_graph_rounded,
      ),
    );

    if (algorithm1.foundPath && algorithm2.foundPath) {
      if (algorithm1.path.length == algorithm2.path.length) {
        insights.add(
          AnalysisInsight(
            text: 'Both found the optimal path length (${algorithm1.path.length})',
            type: InsightType.parity,
            icon: Icons.check_circle_outline_rounded,
          ),
        );
      } else {
        final lengthDiff = (algorithm1.path.length - algorithm2.path.length).abs();
        insights.add(
          AnalysisInsight(
            text: '${winner.algorithmName} found a path with $lengthDiff fewer nodes',
            type: InsightType.success,
            icon: Icons.straighten_rounded,
          ),
        );
      }
    }

    if (winner.algorithmName.contains('A*') || winner.algorithmName.contains('Greedy')) {
      insights.add(
        AnalysisInsight(
          text: 'Heuristic guided search avoided unnecessary exploration',
          type: InsightType.info,
          icon: Icons.psychology_rounded,
        ),
      );
    } else if (winner.algorithmName.contains('Dijkstra')) {
      insights.add(
        AnalysisInsight(
          text: 'Cost-awareness ensured the global minimum path',
          type: InsightType.info,
          icon: Icons.balance_rounded,
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
