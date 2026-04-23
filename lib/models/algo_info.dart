enum ConceptType {
  expandingRipple, // Dijkstra
  wavefrontGrid, // BFS
  snakingLine, // DFS
  greedyProbe, // Greedy
  focusedTarget, // A*
  backtrackingMini,
  nQueensMRV, // New: MRV heuristic
  nQueensFC, // New: Forward Checking heatmap
  puzzleBFS, // New: Brute force shuffle
  puzzleAStar, // New: A* heuristic numbers
  puzzleGreedy, // New: Greedy jump
  battleConcept,
}

class AlgoInfo {
  final String title;
  final String description;
  final List<String> keyFeatures;
  final String complexity;
  final bool isOptimal;
  final ConceptType conceptType;

  const AlgoInfo({
    required this.title,
    required this.description,
    required this.keyFeatures,
    required this.complexity,
    required this.isOptimal,
    required this.conceptType,
  });

  static const Map<String, AlgoInfo> pathfinding = {
    'BFS': AlgoInfo(
      title: 'Breadth-First Search (BFS)',
      description:
          'BFS explores the neighbor nodes first, before moving to the next level of neighbors. It treats all edges as having equal weight.',
      keyFeatures: [
        'Guarantees the shortest path in unweighted grids.',
        'Explores layers level by level.',
        'Uses a Queue (First-In, First-Out).',
      ],
      complexity: 'O(V + E)',
      isOptimal: true,
      conceptType: ConceptType.wavefrontGrid,
    ),
    'DFS': AlgoInfo(
      title: 'Depth-First Search (DFS)',
      description:
          'DFS explores as far as possible along each branch before backtracking. It is efficient for memory but poor for finding shortest paths.',
      keyFeatures: [
        'Excellent for maze exploration.',
        'Does NOT guarantee the shortest path.',
        'Uses a Stack or Recursion (Last-In, First-Out).',
      ],
      complexity: 'O(V + E)',
      isOptimal: false,
      conceptType: ConceptType.snakingLine,
    ),
    'Dijkstra': AlgoInfo(
      title: "Dijkstra's Algorithm",
      description:
          "Dijkstra's explores paths in strictly increasing order of cost. It is the gold standard for finding shortest paths in weighted environments.",
      keyFeatures: [
        'Guarantees the shortest path.',
        'Handles varying weights (terrain cost).',
        'Uses a Priority Queue.',
      ],
      complexity: 'O(E log V)',
      isOptimal: true,
      conceptType: ConceptType.expandingRipple,
    ),
    'Greedy': AlgoInfo(
      title: 'Greedy Best-First Search',
      description:
          'Greedy search uses a heuristic to "guess" which node is closest to the goal. It is very fast but often takes sub-optimal paths.',
      keyFeatures: [
        'Extremely fast execution.',
        'Can be easily fooled by obstacles.',
        'Focuses purely on the goal distance.',
      ],
      complexity: 'O(b^m)',
      isOptimal: false,
      conceptType: ConceptType.greedyProbe,
    ),
    'A*': AlgoInfo(
      title: 'A* Search Algorithm',
      description:
          'A* combines the precision of Dijkstra\'s with the speed of Greedy search. It uses both path cost and a heuristic to find the optimal path efficiently.',
      keyFeatures: [
        'The most popular pathfinding algorithm.',
        'Guaranteed optimal if using an admissible heuristic.',
        'Balances exploration and exploitation.',
      ],
      complexity: 'O(E log V)',
      isOptimal: true,
      conceptType: ConceptType.focusedTarget,
    ),
  };

  static const Map<String, AlgoInfo> nQueens = {
    'Backtracking': AlgoInfo(
      title: 'N-Queens: Backtracking',
      description:
          'Explores the board row-by-row. If a row has no valid column for a queen, it returns to the previous row and tries a different column.',
      keyFeatures: [
        'Classic Depth-First Search strategy.',
        'Uses pruning to avoid exploring invalid sub-trees.',
        'Foundational algorithm for constraint problems.',
      ],
      complexity: 'O(N!)',
      isOptimal: true,
      conceptType: ConceptType.backtrackingMini,
    ),
    'Backtracking + MRV': AlgoInfo(
      title: 'Backtracking with MRV',
      description:
          'Selects the "most constrained" row first—the one with the fewest remaining legal positions. This reduces the search space significantly.',
      keyFeatures: [
        'Uses Minimum Remaining Values (MRV) heuristic.',
        'Dramatically reduces the number of backtracks.',
        'Prioritizes difficult choices early.',
      ],
      complexity: 'O(N!) (Faster in practice)',
      isOptimal: true,
      conceptType: ConceptType.nQueensMRV,
    ),
    'Forward Checking': AlgoInfo(
      title: 'Forward Checking',
      description:
          'Whenever a queen is placed, it proactively removes illegal positions from all future rows. If a row’s domain becomes empty, it backtracks immediately.',
      keyFeatures: [
        'Proactive constraint propagation.',
        'Senses "failure" before it happens.',
        'Maintains domains for unassigned variables.',
      ],
      complexity: 'O(N!)',
      isOptimal: true,
      conceptType: ConceptType.nQueensFC,
    ),
  };

  static const Map<String, AlgoInfo> eightPuzzle = {
    'A*': AlgoInfo(
      title: 'A* Search (Manhattan)',
      description:
          'Uses the Manhattan distance heuristic to guide the search toward the goal. It evaluates states based on (moves made + estimated moves remaining).',
      keyFeatures: [
        'Guarantees the shortest solution path.',
        'Efficiently solves complex puzzle boards.',
        'Uses Priority Queue to manage the Open Set.',
      ],
      complexity: 'O(b^d)',
      isOptimal: true,
      conceptType: ConceptType.puzzleAStar,
    ),
    'BFS': AlgoInfo(
      title: 'Breadth-First Search',
      description:
          'Explores every possible board state level-by-level. It checks all possible 1-move states, then all 2-move states, and so on.',
      keyFeatures: [
        'Guarantees the shortest path.',
        'Extremely memory intensive.',
        'Exhaustive search without heuristics.',
      ],
      complexity: 'O(b^d)',
      isOptimal: true,
      conceptType: ConceptType.puzzleBFS,
    ),
    'Greedy': AlgoInfo(
      title: 'Greedy Search',
      description:
          'Focuses only on the heuristic cost (distance to goal). It always picks the move that looks best "right now," which can lead to longer paths.',
      keyFeatures: [
        'Usually faster to find A solution.',
        'Does NOT guarantee the shortest path.',
        'Susceptible to being trapped in local optima.',
      ],
      complexity: 'O(b^m)',
      isOptimal: false,
      conceptType: ConceptType.puzzleGreedy,
    ),
  };

  static const AlgoInfo battleArena = AlgoInfo(
    title: 'Algorithm Battle Arena',
    description:
        'A real-time race between two search algorithms. Watch how different strategies handle the same obstacles and grid layout.',
    keyFeatures: [
      'Compares search speed (nodes per second).',
      'Visualizes path optimality side-by-side.',
      'Displays computational efficiency trends.',
    ],
    complexity: 'N/A',
    isOptimal: true,
    conceptType: ConceptType.battleConcept,
  );
}
