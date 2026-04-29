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
  waterJugBFS,
  waterJugAStar,
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
          'A fundamental graph traversal algorithm that explores the search space level-by-level. It is mathematically guaranteed to find the shortest path in unweighted environments by maintaining a strict frontier of discovered nodes.',
      keyFeatures: [
        'Strict layer-by-level discovery.',
        'Guarantees optimality in unweighted grids.',
        'Uses FIFO (First-In, First-Out) queue strategy.',
        'Explores 360° wavefront from the origin.',
      ],
      complexity: 'O(V + E)',
      isOptimal: true,
      conceptType: ConceptType.wavefrontGrid,
    ),
    'DFS': AlgoInfo(
      title: 'Depth-First Search (DFS)',
      description:
          'A memory-efficient search strategy that dives as deep as possible into a branch before backtracking. While not optimal for pathfinding, it is exceptionally powerful for maze generation and connectivity analysis.',
      keyFeatures: [
        'Minimal memory overhead per level.',
        'Excellent for exhaustive maze exploration.',
        'Uses LIFO (Last-In, First-Out) stack strategy.',
        'Non-optimal: may return a significantly longer path.',
      ],
      complexity: 'O(V + E)',
      isOptimal: false,
      conceptType: ConceptType.snakingLine,
    ),
    'Dijkstra': AlgoInfo(
      title: "Dijkstra's Algorithm",
      description:
          "The definitive algorithm for finding shortest paths in weighted graphs. It expands the search frontier in order of increasing cumulative cost, ensuring that once a node is visited, the path to it is the cheapest possible.",
      keyFeatures: [
        'Weighted optimality guarantee.',
        'Dynamic cost-aware exploration.',
        'Priority-based frontier management.',
        'Foundation for modern GPS routing.',
      ],
      complexity: 'O(E log V)',
      isOptimal: true,
      conceptType: ConceptType.expandingRipple,
    ),
    'Greedy': AlgoInfo(
      title: 'Greedy Best-First Search',
      description:
          'A high-speed search algorithm that prioritizes exploration based purely on a heuristic estimate of the distance to the goal. It sacrifices optimality for extreme execution speed.',
      keyFeatures: [
        'Heuristic-driven directional search.',
        'Highly efficient execution time.',
        'Prone to local optima and "stalling" at walls.',
        'Pure goal-oriented behavior.',
      ],
      complexity: 'O(b^m)',
      isOptimal: false,
      conceptType: ConceptType.greedyProbe,
    ),
    'A*': AlgoInfo(
      title: 'A* Search Algorithm',
      description:
          'The industry standard for pathfinding. A* intelligently balances path cost (g) and heuristic distance (h) to find the optimal path with minimal exploration. It is functionally superior to both Dijkstra and Greedy search.',
      keyFeatures: [
        'Balanced f(n) = g(n) + h(n) evaluation.',
        'Provably optimal with admissible heuristics.',
        'Minimal node expansion for optimal solutions.',
        'Widely used in robotics and game AI.',
      ],
      complexity: 'O(E log V)',
      isOptimal: true,
      conceptType: ConceptType.focusedTarget,
    ),
  };

  static const Map<String, AlgoInfo> nQueens = {
    'Backtracking': AlgoInfo(
      title: 'Backtracking Search',
      description:
          'A recursive "trial and error" strategy that systematically builds a solution row-by-row. It uses depth-first exploration with pruning to discard invalid board configurations as early as possible.',
      keyFeatures: [
        'Systematic row-wise placement.',
        'Recursive state-space exploration.',
        'Pruning of invalid candidate branches.',
        'Guaranteed to find all possible solutions.',
      ],
      complexity: 'O(N!)',
      isOptimal: true,
      conceptType: ConceptType.backtrackingMini,
    ),
    'Backtracking + MRV': AlgoInfo(
      title: 'Backtracking with MRV',
      description:
          'An optimized search that employs the Minimum Remaining Values (MRV) heuristic. It prioritizes the most constrained variables first, dramatically reducing the branching factor and search time.',
      keyFeatures: [
        '"Most Constrained Variable" prioritization.',
        'Early conflict detection and resolution.',
        'Significantly reduced recursive depth.',
        'Dynamic row selection based on safety.',
      ],
      complexity: 'O(N!) (Optimized)',
      isOptimal: true,
      conceptType: ConceptType.nQueensMRV,
    ),
    'Forward Checking': AlgoInfo(
      title: 'Forward Checking',
      description:
          'A proactive constraint propagation technique. Every time a queen is placed, it "looks ahead" and eliminates illegal positions in future rows, allowing the search to fail faster and avoid useless work.',
      keyFeatures: [
        'Proactive domain reduction.',
        'Early failure detection via look-ahead.',
        'Maintains a "safe-zone" heatmap.',
        'Intelligent pruning of future search space.',
      ],
      complexity: 'O(N!)',
      isOptimal: true,
      conceptType: ConceptType.nQueensFC,
    ),
  };

  static const Map<String, AlgoInfo> eightPuzzle = {
    'A*': AlgoInfo(
      title: 'A* (Manhattan Distance)',
      description:
          'Solves the sliding puzzle by using the sum of Manhattan distances of all tiles from their goal positions as a heuristic. This provides a high-fidelity estimate that guides the search optimally.',
      keyFeatures: [
        'Optimal move-count guarantee.',
        'Informed state-space traversal.',
        'Uses admissible Manhattan heuristic.',
        'Efficiently solves complex shuffles.',
      ],
      complexity: 'O(b^d)',
      isOptimal: true,
      conceptType: ConceptType.puzzleAStar,
    ),
    'BFS': AlgoInfo(
      title: 'Breadth-First Search',
      description:
          'An uninformed search that explores every possible move combination level-by-level. While it guarantees the shortest solution, the exponential state-space growth makes it highly resource intensive.',
      keyFeatures: [
        'Blind, level-by-level exploration.',
        'Guarantees minimal move count.',
        'Memory-heavy state storage.',
        'No heuristic guidance (Uninformed).',
      ],
      complexity: 'O(b^d)',
      isOptimal: true,
      conceptType: ConceptType.puzzleBFS,
    ),
    'Greedy': AlgoInfo(
      title: 'Greedy Search (Heuristic)',
      description:
          'Prioritizes puzzle states based purely on how many tiles are out of place. It moves aggressively toward the goal but may take a circuitous path to get there.',
      keyFeatures: [
        'Direct goal-seeking behavior.',
        'Faster to reach a solution (usually).',
        'Non-optimal path length.',
        'Subject to local minima in state space.',
      ],
      complexity: 'O(b^m)',
      isOptimal: false,
      conceptType: ConceptType.puzzleGreedy,
    ),
  };

  static const AlgoInfo battleArena = AlgoInfo(
    title: 'Algorithm Battle Arena',
    description:
        'A high-stakes comparison of two search strategies operating on identical grid conditions. The arena measures not just speed, but computational efficiency and path optimality under pressure.',
    keyFeatures: [
      'Real-time NPS (Nodes Per Second) tracking.',
      'Side-by-side path optimality analysis.',
      'Hardware-aware performance metrics.',
      'Direct comparison of Informed vs Uninformed.',
    ],
    complexity: 'N/A',
    isOptimal: true,
    conceptType: ConceptType.battleConcept,
  );

  static const Map<String, AlgoInfo> waterJug = {
    'BFS': AlgoInfo(
      title: 'BFS: State-Space Search',
      description:
          'Treats the water jug problem as a traversal of the Phase Space of all possible volume combinations. BFS explores every possible action sequence to find the absolute minimum steps required.',
      keyFeatures: [
        'Optimal action-count guarantee.',
        'Exhaustive state-space discovery.',
        'Phase-space layer traversal.',
        'Uniform exploration of possibilities.',
      ],
      complexity: 'O(V + E)',
      isOptimal: true,
      conceptType: ConceptType.waterJugBFS,
    ),
    'A*': AlgoInfo(
      title: 'A*: Heuristic Phase Search',
      description:
          'Enhances the Phase Space search by using a mathematical heuristic representing the distance from the current volumes to the target. It prunes non-promising state transitions to solve the problem faster.',
      keyFeatures: [
        'Heuristic-guided state traversal.',
        'Pruning of distant phase-states.',
        'Balanced exploration of volumes.',
        'Typically explores 40-60% fewer states.',
      ],
      complexity: 'O(V + E)',
      isOptimal: true,
      conceptType: ConceptType.waterJugAStar,
    ),
  };
}
