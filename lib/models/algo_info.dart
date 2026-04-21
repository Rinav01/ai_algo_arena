enum ConceptType {
  expandingRipple, // Dijkstra
  wavefrontGrid,   // BFS
  snakingLine,     // DFS
  greedyProbe,     // Greedy
  focusedTarget,   // A*
  backtrackingMini,
  puzzleShuffle,
  battleConcept
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
      description: 'BFS explores the neighbor nodes first, before moving to the next level of neighbors. It treats all edges as having equal weight.',
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
      description: 'DFS explores as far as possible along each branch before backtracking. It is efficient for memory but poor for finding shortest paths.',
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
      description: "Dijkstra's explores paths in strictly increasing order of cost. It is the gold standard for finding shortest paths in weighted environments.",
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
      description: 'Greedy search uses a heuristic to "guess" which node is closest to the goal. It is very fast but often takes sub-optimal paths.',
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
      description: 'A* combines the precision of Dijkstra\'s with the speed of Greedy search. It uses both path cost and a heuristic to find the optimal path efficiently.',
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

  static const AlgoInfo nQueens = AlgoInfo(
    title: 'N-Queens Problem',
    description: 'A classic constraint satisfaction problem. The goal is to place N chess queens on an N×N board so that no two queens attack each other.',
    keyFeatures: [
      'Solved using Backtracking.',
      'Explores the state space tree.',
      'Demonstrates pruning (stopping early on invalid paths).',
    ],
    complexity: 'O(N!)',
    isOptimal: true,
    conceptType: ConceptType.backtrackingMini,
  );

  static const AlgoInfo eightPuzzle = AlgoInfo(
    title: '8-Puzzle Solver',
    description: 'A sliding tile puzzle consisting of a frame of numbered square tiles with one missing. The goal is to reach a specific target state with minimum moves.',
    keyFeatures: [
      'State-space search problem.',
      'Solved with A* and heuristics (Manhattan distance).',
      'Uses parity to determine if a state is solvable.',
    ],
    complexity: 'O(b^d)',
    isOptimal: true,
    conceptType: ConceptType.puzzleShuffle,
  );

  static const AlgoInfo battleArena = AlgoInfo(
    title: 'Algorithm Battle Arena',
    description: 'A real-time race between two search algorithms. Watch how different strategies handle the same obstacles and grid layout.',
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
