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
    final isSparslyObstructed = obstacleDensity < 0.1;

    // Rule 1: Large grids with sparse obstacles → A*
    if (isLargeGrid && isSparslyObstructed) {
      return RecommendationResult(
        algorithm: RecommendedAlgorithm.aStar,
        reason:
            'Heuristic guidance is highly efficient for large sparse grids (${problem.rows}×${problem.cols}, ${(obstacleDensity * 100).toStringAsFixed(1)}% obstacles)',
        confidence: 0.95,
        considerations: [
          'A* explores fewer nodes than BFS/DFS',
          'Manhattan distance heuristic optimized for grid',
          'Guaranteed optimal path with admissible heuristic',
        ],
      );
    }

    // Rule 2: Medium grids with low obstacles → A*
    if (gridSize == GridSize.medium && isSparslyObstructed) {
      return RecommendationResult(
        algorithm: RecommendedAlgorithm.aStar,
        reason: 'A* provides optimal efficiency for medium-sized open grids',
        confidence: 0.85,
        considerations: [
          'Balanced between speed and accuracy',
          'Heuristic helps avoid exploring unnecessary nodes',
          'Perfect for interactive visualization',
        ],
      );
    }

    // Rule 3: Highly obstructed grids → BFS for guaranteed shortest
    if (isHighlyObstructed) {
      return RecommendationResult(
        algorithm: RecommendedAlgorithm.bfs,
        reason:
            'High obstacle density (${(obstacleDensity * 100).toStringAsFixed(1)}%) means many dead ends; BFS explores all options equally',
        confidence: 0.90,
        considerations: [
          'Guarantees shortest path in unweighted grids',
          'BFS systematic exploration handles dead ends well',
          'No heuristic bias needed',
        ],
      );
    }

    // Rule 4: Small grids → Any algorithm works, prefer BFS for clarity
    if (gridSize == GridSize.small) {
      return RecommendationResult(
        algorithm: RecommendedAlgorithm.bfs,
        reason:
            'Small grid (${problem.rows}×${problem.cols}); all algorithms are fast. BFS is most intuitive for learning',
        confidence: 0.70,
        considerations: [
          'Grid is small enough for any algorithm',
          'BFS is easiest to understand for beginners',
          'Try DFS or A* for comparison',
        ],
      );
    }

    // Rule 5: Default: A* for general purpose
    return RecommendationResult(
      algorithm: RecommendedAlgorithm.aStar,
      reason:
          'A* is generally the best choice for pathfinding; combines speed with optimality',
      confidence: 0.80,
      considerations: [
        'Heuristic-guided search reduces explored nodes',
        'Optimal path guaranteed',
        'Suitable for interactive applications',
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
    final total = problem.rows * problem.cols;
    final obstacleDensity = problem.obstacleDensity;

    switch (algorithm) {
      case RecommendedAlgorithm.aStar:
        // A* is best for sparse grids
        final sparsityFactor = 1.0 - obstacleDensity;
        return 0.7 + (sparsityFactor * 0.3); // 0.7 to 1.0

      case RecommendedAlgorithm.bfs:
        // BFS is good for all cases, but better for dense grids
        return 0.5 + (obstacleDensity * 0.4); // 0.5 to 0.9

      case RecommendedAlgorithm.dfs:
        // DFS is okay for most cases
        return 0.5;

      case RecommendedAlgorithm.dijkstra:
        // Dijkstra is like BFS but slightly slower
        return 0.45 + (obstacleDensity * 0.4); // 0.45 to 0.85
    }
  }
}
