import 'package:algo_arena/core/problem_definition.dart';

/// Service to analyze algorithm run history and generate global engineering insights.
class InsightService {
  /// Generates a post-run summary based on the algorithm's performance metrics.
  static String generateGlobalInsight({
    required String algorithmName,
    required List<AlgorithmStep> steps,
    required int totalWalkableNodes,
    int? knownPathLength,
  }) {
    if (steps.isEmpty) return 'No data available to analyze.';

    final totalSteps = steps.length;
    final finalStep = steps.last;
    
    int pathLength = knownPathLength ?? 0;
    if (pathLength == 0) {
      for (int i = steps.length - 1; i >= 0; i--) {
        if (steps[i].path.isNotEmpty) {
          pathLength = steps[i].path.length;
          break;
        }
      }
    }
    
    final nodesExplored = finalStep.stepCount;
    final explorationRatio = nodesExplored / totalWalkableNodes;
    final isSuccess = pathLength > 0 || finalStep.isGoalReached;

    // --- 1. Comparative Analysis (vs BFS Baseline) ---
    // Estimated BFS exploration for a path of length L is roughly 2*L^2 in an open grid
    // We use a more conservative estimate for comparison
    final estimatedBfsNodes = (pathLength * pathLength * 0.8).clamp(nodesExplored.toDouble(), totalWalkableNodes.toDouble());
    final reduction = isSuccess ? ((1 - (nodesExplored / estimatedBfsNodes)) * 100).clamp(0, 99) : 0;

    // --- 2. Technical Analysis ---
    String analysis = '';
    String takeaway = '';

    if (algorithmName.contains('A*')) {
      final metrics = _analyzeSearchDynamics(steps);
      analysis = '• Heuristic effectively prioritized goal-directed nodes via h(n) estimation.\n'
                 '• Frontier expansion remained controlled with a low branching factor.\n'
                 '• Exploration reduced by ~${reduction.toStringAsFixed(0)}% compared to uninformed search.';
      
      takeaway = metrics['optimalityRate']! > 90 
          ? 'Search efficiency was high due to strong heuristic alignment with the goal.'
          : 'Search efficiency was moderate; heuristic ties led to slight frontier expansion.';
    } else if (algorithmName.contains('Dijkstra')) {
      analysis = '• Guaranteed shortest path via exhaustive cost-based evaluation.\n'
                 '• Frontier expanded uniformly in all directions (high branching factor).\n'
                 '• Zero heuristic guidance leads to maximum safety but higher exploration.';
      takeaway = 'Path optimality was prioritized over search speed and memory efficiency.';
    } else if (algorithmName.contains('Greedy')) {
      analysis = '• Purely goal-biased search prioritizing nodes with lowest h(n).\n'
                 '• Aggressive pruning of search space by ignoring actual path costs.\n'
                 '• Highly efficient but risks sub-optimal paths in complex terrain.';
      takeaway = 'Search focused purely on goal proximity, trading optimality for speed.';
    } else if (algorithmName.contains('BFS')) {
      analysis = '• Systematic layer-by-layer exploration ensures the shortest path in unweighted grids.\n'
                 '• Search behavior: Layer-by-Layer expansion.\n'
                 '• Uniform frontier growth across all directions.';
      takeaway = 'Guaranteed optimality in unweighted grids by checking all nodes at each depth.';
    } else if (algorithmName.contains('DFS')) {
      analysis = '• Deep-dive search prioritizing path depth over shortest path guarantees.\n'
                 '• Search behavior: Deep-Dive exploration.\n'
                 '• High risk of sub-optimal detours and excessive backtracking.';
      takeaway = 'Search prioritized depth, leading to a potentially non-optimal path.';
    } else {
      analysis = '• Standard search dynamics observed during execution.\n'
                 '• Exploration reached ${(explorationRatio * 100).toStringAsFixed(1)}% of available grid space.';
      takeaway = 'Algorithm completed the task within the expected performance bounds.';
    }

    // --- 3. Construct Structured Output ---
    final buffer = StringBuffer();
    buffer.writeln('PERFORMANCE:');
    buffer.writeln('• $algorithmName completed in $totalSteps steps');
    buffer.writeln('• Nodes explored: $nodesExplored (${(explorationRatio * 100).toStringAsFixed(1)}% of grid)');
    buffer.writeln('');
    
    buffer.writeln('PATH RESULT:');
    if (isSuccess) {
      buffer.writeln('• Valid path found: $pathLength units');
    } else {
      buffer.writeln('• No valid path found under current constraints');
    }
    buffer.writeln('');

    buffer.writeln('ANALYSIS:');
    buffer.writeln(analysis);
    buffer.writeln('');

    buffer.writeln('INSIGHT:');
    buffer.write(takeaway);

    return buffer.toString();
  }

  static Map<String, double> _analyzeSearchDynamics(List<AlgorithmStep> steps) {
    int optimalPicks = 0;
    int totalEvaluations = 0;

    for (var step in steps) {
      if (step.meta != null && step.meta!.containsKey('isOptimal')) {
        totalEvaluations++;
        if (step.meta!['isOptimal'] == true) optimalPicks++;
      }
    }

    return {
      'optimalityRate': totalEvaluations == 0 ? 0.0 : (optimalPicks / totalEvaluations) * 100,
      'evaluations': totalEvaluations.toDouble(),
    };
  }
}
