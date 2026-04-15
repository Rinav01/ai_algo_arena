import 'package:flutter/material.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF07131F),
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [Color(0xFF08111B), Color(0xFF0B1D2C), Color(0xFF07131F)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
        child: SafeArea(
          child: Column(
            children: [
              Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'AI Algorithm Arena',
                      style: TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      'Master Algorithms',
                      style: Theme.of(context).textTheme.titleSmall?.copyWith(
                        color: Colors.grey[400],
                        fontSize: 14,
                      ),
                    ),
                  ],
                ),
              ),
              Expanded(
                child: ListView(
                  padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                  children: [
                    _buildSectionTitle(context, 'Pathfinding Algorithms'),
                    const SizedBox(height: 16),
                    _buildAlgorithmCard(
                      context,
                      icon: Icons.auto_graph,
                      title: 'A* Search',
                      description:
                          'Advanced pathfinding algorithm using heuristics',
                      tags: const ['O(b^d)', 'O(b^d)', 'OPTIMIZED'],
                      onTap: () => Navigator.pushNamed(context, '/a-star'),
                    ),
                    const SizedBox(height: 12),
                    _buildAlgorithmCard(
                      context,
                      icon: Icons.route,
                      title: 'Dijkstra\'s Algorithm',
                      description:
                          'Finds the shortest paths between nodes in a graph',
                      tags: const ['O(E log V)', 'O(V)', 'GRAPH'],
                      onTap: () => Navigator.pushNamed(context, '/dijkstra'),
                    ),
                    const SizedBox(height: 12),
                    _buildAlgorithmCard(
                      context,
                      icon: Icons.account_tree,
                      title: 'Breadth-First Search',
                      description:
                          'Explores neighbor nodes first, before moving onward',
                      tags: const ['O(V+E)', 'O(n)', 'FOUNDATIONAL'],
                      onTap: () => Navigator.pushNamed(context, '/bfs'),
                    ),
                    const SizedBox(height: 12),
                    _buildAlgorithmCard(
                      context,
                      icon: Icons.device_hub,
                      title: 'Depth-First Search',
                      description:
                          'Explores as far as possible along each branch',
                      tags: const ['O(V+E)', 'O(h)', 'RECURSIVE'],
                      onTap: () => Navigator.pushNamed(context, '/dfs'),
                    ),
                    const SizedBox(height: 24),
                    _buildSectionTitle(context, 'Learning Problems'),
                    const SizedBox(height: 16),
                    _buildProblemCard(
                      context,
                      icon: Icons.grid_on,
                      title: '8-Puzzle Solver',
                      description:
                          'Solve sliding tile puzzles with multiple algorithms',
                      difficulty: 'Medium',
                      onTap: () => Navigator.pushNamed(context, '/8-puzzle'),
                    ),
                    const SizedBox(height: 12),
                    _buildProblemCard(
                      context,
                      icon: Icons.psychology,
                      title: 'N-Queens Puzzle',
                      description:
                          'Place N chess queens on an N x N chessboard',
                      difficulty: 'Medium',
                      onTap: () => Navigator.pushNamed(context, '/n-queens'),
                    ),
                    const SizedBox(height: 12),
                    _buildProblemCard(
                      context,
                      icon: Icons.apps,
                      title: 'Sudoku Solver',
                      description:
                          'Complete number-placement puzzle automatically',
                      difficulty: 'Hard',
                      onTap: () => Navigator.pushNamed(context, '/sudoku'),
                    ),
                    const SizedBox(height: 12),
                    _buildProblemCard(
                      context,
                      icon: Icons.extension,
                      title: 'Maze Generator',
                      description: 'Create random mazes using various algorithms',
                      difficulty: 'Easy',
                      onTap: () =>
                          Navigator.pushNamed(context, '/maze-generator'),
                    ),
                    const SizedBox(height: 24),
                    _buildLeaderboardPreview(context),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSectionTitle(BuildContext context, String title) {
    return Text(
      title,
      style: Theme.of(
        context,
      ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
    );
  }

  Widget _buildAlgorithmCard(
    BuildContext context, {
    required IconData icon,
    required String title,
    required String description,
    required List<String> tags,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        decoration: BoxDecoration(
          color: const Color(0xFF0E2233),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: Colors.white.withOpacity(0.06)),
        ),
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(icon, size: 32, color: const Color(0xFFFFA500)),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        style: Theme.of(context).textTheme.titleMedium
                            ?.copyWith(fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        description,
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: Colors.grey[400],
                        ),
                      ),
                    ],
                  ),
                ),
                const Icon(Icons.arrow_forward, size: 20),
              ],
            ),
            const SizedBox(height: 12),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: tags.map((tag) {
                final isOptimized = tag == 'OPTIMIZED';
                final isGraph = tag == 'GRAPH';
                final color = isOptimized
                    ? Colors.green[900]
                    : isGraph
                    ? Colors.blue[900]
                    : const Color(0xFF1A3A3A);
                return Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: color,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: isOptimized
                          ? Colors.green[700]!
                          : isGraph
                          ? Colors.blue[700]!
                          : Colors.grey[700]!,
                      width: 0.5,
                    ),
                  ),
                  child: Text(
                    tag,
                    style: const TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                );
              }).toList(),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildProblemCard(
    BuildContext context, {
    required IconData icon,
    required String title,
    required String description,
    required String difficulty,
    required VoidCallback onTap,
  }) {
    final difficultyColor = difficulty == 'Easy'
        ? Colors.green
        : difficulty == 'Medium'
        ? Colors.orange
        : Colors.red;

    return GestureDetector(
      onTap: onTap,
      child: Container(
        decoration: BoxDecoration(
          color: const Color(0xFF0E2233),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: Colors.white.withOpacity(0.06)),
        ),
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            Icon(icon, size: 32, color: const Color(0xFFFFA500)),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    description,
                    style: Theme.of(
                      context,
                    ).textTheme.bodySmall?.copyWith(color: Colors.grey[400]),
                  ),
                ],
              ),
            ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: difficultyColor.withOpacity(0.15),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: difficultyColor),
              ),
              child: Text(
                difficulty,
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                  color: difficultyColor,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildLeaderboardPreview(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFF0E2233),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.white.withOpacity(0.06)),
      ),
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Top Contributors',
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
              TextButton(
                onPressed: () {},
                child: const Text('View Leaderboard'),
              ),
            ],
          ),
          const SizedBox(height: 12),
          _buildLeaderboardItem('Alex_Code', 2850, 1),
          _buildLeaderboardItem('DijkstraFan', 2640, 2),
          _buildLeaderboardItem('Astar_Dev', 2420, 3),
        ],
      ),
    );
  }

  Widget _buildLeaderboardItem(String name, int score, int rank) {
    final medalIcon = rank == 1
        ? Icons.emoji_events
        : rank == 2
        ? Icons.workspace_premium
        : Icons.military_tech;
    final medalColor = rank == 1
        ? Colors.amber
        : rank == 2
        ? Colors.blueGrey[200]!
        : const Color(0xFFCD7F32);

    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        children: [
          Icon(medalIcon, size: 18, color: medalColor),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              name,
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
          ),
          Text(
            '$score pts',
            style: const TextStyle(
              fontWeight: FontWeight.bold,
              color: Color(0xFFFFA500),
            ),
          ),
        ],
      ),
    );
  }
}
