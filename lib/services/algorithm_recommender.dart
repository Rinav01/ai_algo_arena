import '../core/grid_problem.dart';

enum RecommendedAlgorithm {
  bfs('BFS', 'Breadth-First Search - Unrestricted, explores evenly'),
  dfs('DFS', 'Depth-First Search - Good for memory, explores deeply'),
  dijkstra('Dijkstra', 'Dijkstra\'s Algorithm - Optimal with weights'),
  aStar('A*', 'A* Search - Most efficient with heuristic guidance');

  final String shortName;
  final String description;

  const RecommendedAlgorithm(this.shortName, this.description);
}

class RecommendationResult {
  final RecommendedAlgorithm algorithm;
  final String reason;
  final double confidence; // 0.0 to 1.0
  final List<String> considerations;

  RecommendationResult({
    required this.algorithm,
    required this.reason,
    required this.confidence,
    required this.considerations,
  });

  @override
  String toString() {
    return '''
Recommended: ${algorithm.shortName}
Reason: $reason
Confidence: ${(confidence * 100).toStringAsFixed(0)}%
Considerations: ${considerations.join(', ')}
    ''';
  }
}

class AlgorithmRecommender {
  /// Recommend an algorithm based on grid properties
  static RecommendationResult recommend(GridProblem problem) {
    final total = problem.rows * problem.cols;
    final obstacleDensity = problem.obstacleDensity;
    final gridSize = problem.gridSize;
    final isLargeGrid = total > 500;
    final isHighlyObstructed = obstacleDensity > 0.4;

    // Check if the grid has varied weights (costs > 1.0)
    bool hasWeights = false;
    for (int r = 0; r < problem.rows; r++) {
      for (int c = 0; c < problem.cols; c++) {
        if (problem.moveCost(
              GridCoordinate(row: 0, column: 0),
              GridCoordinate(row: r, column: c),
            ) >
            1.0) {
          hasWeights = true;
          break;
        }
      }
      if (hasWeights) break;
    }

    // Rule 1: Weighted grids → A* (Dijkstra is also optimal, but A* is faster)
    if (hasWeights) {
      return RecommendationResult(
        algorithm: RecommendedAlgorithm.aStar,
        reason:
            'Varied cell costs detected. A* ensures the cheapest path while using heuristics to minimize exploration.',
        confidence: 0.99,
        considerations: [
          'Guarantees optimal path in weighted environments',
          'Heuristic significantly outperforms Dijkstra\'s blind search',
        ],
      );
    }

    // Rule 2: Large grids or complex obstacles → A* (Efficiency King)
    if (isLargeGrid || isHighlyObstructed) {
      return RecommendationResult(
        algorithm: RecommendedAlgorithm.aStar,
        reason:
            'Large or complex map detected. A* avoids the "flood-fill" overhead of BFS, staying focused on the goal.',
        confidence: 0.95,
        considerations: [
          'Avoids unnecessary exploration of areas facing away from the target',
          'Mathematically proven to visit the minimum number of states',
        ],
      );
    }

    // Rule 3: Small, uniform-cost grids → BFS (Great for visualization)
    if (gridSize == GridSize.small && obstacleDensity < 0.2) {
      return RecommendationResult(
        algorithm: RecommendedAlgorithm.bfs,
        reason:
            'Small, simple grid. BFS is the perfect choice for visualizing how a shortest path is found layer-by-layer.',
        confidence: 0.80,
        considerations: [
          'Simple and intuitive visualization',
          'Guarantees shortest path for uniform costs',
          'Explores evenly in all directions',
        ],
      );
    }

    // Fallback: A* for everything else
    return RecommendationResult(
      algorithm: RecommendedAlgorithm.aStar,
      reason:
          'General optimization: A* provides the best balance of speed and optimality for this configuration.',
      confidence: 0.90,
      considerations: [
        'Minimal memory footprint',
        'Consistently outperforms non-heuristic searches',
      ],
    );
  }

  /// Get alternative recommendations
  static List<RecommendationResult> getAlternatives(GridProblem problem) {
    final primary = recommend(problem);
    final alternatives = <RecommendationResult>[];

    // If A* is recommended, suggest alternatives
    if (primary.algorithm == RecommendedAlgorithm.aStar) {
      alternatives.add(
        RecommendationResult(
          algorithm: RecommendedAlgorithm.bfs,
          reason:
              'Alternative: Guaranteed shortest path, easier to visualize step-by-step',
          confidence: 0.60,
          considerations: [
            'Best for learning',
            'May explore more nodes than A*',
          ],
        ),
      );
      alternatives.add(
        RecommendationResult(
          algorithm: RecommendedAlgorithm.dijkstra,
          reason:
              'Alternative: For weighted grids or when you need to modify costs',
          confidence: 0.50,
          considerations: [
            'Supports weighted edges',
            'Slightly slower than A*',
          ],
        ),
      );
    }

    // If BFS is recommended
    if (primary.algorithm == RecommendedAlgorithm.bfs) {
      alternatives.add(
        RecommendationResult(
          algorithm: RecommendedAlgorithm.aStar,
          reason: 'Alternative: Faster for open grids with heuristic guidance',
          confidence: 0.70,
          considerations: ['Explores fewer nodes', 'More complex algorithm'],
        ),
      );
    }

    return alternatives;
  }

  /// Get efficiency score (0.0 to 1.0) for a specific algorithm on this problem
  static double getEfficiencyScore(
    GridProblem problem,
    RecommendedAlgorithm algorithm,
  ) {
    final obstacleDensity = problem.obstacleDensity;

    switch (algorithm) {
      case RecommendedAlgorithm.aStar:
        // A* is the baseline for high efficiency
        return 0.95;

      case RecommendedAlgorithm.bfs:
        // BFS is highly inefficient due to uniform expansion (visits many nodes)
        // Its efficiency decreases as the grid gets larger/clearer
        return 0.4 + (obstacleDensity * 0.2); // 0.4 to 0.6

      case RecommendedAlgorithm.dijkstra:
        // Dijkstra is slightly better than BFS for weights but same exploration
        return 0.45 + (obstacleDensity * 0.1); // 0.45 to 0.55

      case RecommendedAlgorithm.dfs:
        // DFS is unpredictable and often highly inefficient for pathfinding
        return 0.3;
    }
  }
}
