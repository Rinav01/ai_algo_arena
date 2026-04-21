import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:ai_algo_app/core/app_theme.dart';
import 'package:ai_algo_app/services/stats_service.dart';
import 'package:ai_algo_app/widgets/bottom_nav_bar.dart';

// ─── Home Screen ─────────────────────────────────────────────────────────────
class HomeScreen extends ConsumerStatefulWidget {
  const HomeScreen({super.key});
  @override
  ConsumerState<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends ConsumerState<HomeScreen>
    with SingleTickerProviderStateMixin {
  int _selectedCategory = 0;
  late AnimationController _pulseCtrl;
  late Animation<double> _pulse;

  static const _categories = ['Pathfinding', 'Puzzle', 'Search', 'Maze'];

  @override
  void initState() {
    super.initState();
    _pulseCtrl = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 3),
    )..repeat(reverse: true);
    _pulse = Tween<double>(begin: 0.6, end: 1.0).animate(
      CurvedAnimation(parent: _pulseCtrl, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _pulseCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.background,
      extendBody: true,
      body: CustomScrollView(
        physics: const BouncingScrollPhysics(),
        slivers: [
          _buildHeroSliver(context, ref),
          _buildCategoryChips(),
          _buildAlgorithmGrid(context),
          _buildStatsSection(ref),
          const SliverToBoxAdapter(child: SizedBox(height: 100)),
        ],
      ),
      bottomNavigationBar: const ArenaBottomNavBar(currentIndex: 0),
    );
  }

  // ── Hero Header ─────────────────────────────────────────────────────────────
  Widget _buildHeroSliver(BuildContext context, WidgetRef ref) {
    // Dynamic counts
    final categoriesCount = _categories.length;
    final uniqueAlgosCount = _algorithmsByCategory.values
        .expand((list) => list)
        .map((info) => info.name)
        .toSet()
        .length;

    return SliverToBoxAdapter(
      child: Container(
        color: AppTheme.background,
        child: Stack(
          children: [
            // Node-graph ambient background
            Positioned.fill(child: _NodeGraphPainterWidget(pulse: _pulse)),
            // Glow orb behind title
            Positioned(
              top: -30, right: -40,
              child: AnimatedBuilder(
                animation: _pulse,
                builder: (_, _) => Container(
                  width: 220.0,
                  height: 220.0,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: RadialGradient(
                      colors: [
                        AppTheme.accentContainer.withValues(alpha: 0.35 * _pulse.value),
                        Colors.transparent,
                      ],
                    ),
                  ),
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 60, 20, 24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Tag line
                  Container(
                    padding: EdgeInsets.symmetric(horizontal: 10.0, vertical: 4.0),
                    decoration: BoxDecoration(
                      color: AppTheme.accentContainer.withValues(alpha: 0.25),
                      borderRadius: BorderRadius.circular(6.0),
                      border: Border.all(color: AppTheme.accent.withValues(alpha: 0.4)),
                    ),
                    child: Text(
                      'NEURAL ARENA  v1.0',
                      style: Theme.of(context).textTheme.labelSmall?.copyWith(
                            color: AppTheme.accentLight,
                            letterSpacing: 2,
                          ),
                    ),
                  ),
                  const SizedBox(height: 14),
                  Text(
                    'AI Algorithm\nArena',
                    style: Theme.of(context).textTheme.displayLarge?.copyWith(
                          height: 1.1,
                        ),
                  ),
                  const SizedBox(height: 10),
                  // Animated subtitle
                  AnimatedBuilder(
                    animation: _pulse,
                    builder: (_, _) => Text(
                      'Visualize · Learn · Compete',
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                            color: AppTheme.accentLight
                                .withValues(alpha: 0.6 + 0.4 * _pulse.value),
                            letterSpacing: 1.0,
                          ),
                    ),
                  ),
                  const SizedBox(height: 20),
                  // Quick-stats row
                  Wrap(
                    spacing: 12,
                    runSpacing: 12,
                    children: [
                      _QuickStat(label: 'ALGORITHMS', value: '$uniqueAlgosCount+'),
                      _QuickStat(label: 'CATEGORIES', value: '$categoriesCount'),
                      _QuickStat(label: 'REAL-TIME VIZ', value: '✓',
                          accent: AppTheme.cyan),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ── Category Chips ──────────────────────────────────────────────────────────
  Widget _buildCategoryChips() {
    return SliverToBoxAdapter(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(20, 4, 0, 16),
        child: SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          physics: const BouncingScrollPhysics(),
          child: Row(
            children: List.generate(_categories.length, (i) {
              final isActive = i == _selectedCategory;
              return Padding(
                padding: EdgeInsets.only(right: 10.0),
                child: GestureDetector(
                  onTap: () => setState(() => _selectedCategory = i),
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 250),
                    curve: Curves.easeOut,
                    padding: EdgeInsets.symmetric(horizontal: 18.0, vertical: 9.0),
                    decoration: BoxDecoration(
                      color: isActive
                          ? AppTheme.accentContainer
                          : AppTheme.surfaceHighest,
                      borderRadius: BorderRadius.circular(8.0),
                      border: Border.all(
                        color: isActive
                            ? AppTheme.accent
                            : Colors.white.withValues(alpha: 0.08),
                      ),
                      boxShadow: isActive
                          ? [
                              BoxShadow(
                                color: AppTheme.accent.withValues(alpha: 0.35),
                                blurRadius: 12,
                                spreadRadius: 0,
                              )
                            ]
                          : [],
                    ),
                    child: Text(
                      _categories[i],
                      style: Theme.of(context).textTheme.labelLarge?.copyWith(
                            color: isActive
                                ? Colors.white
                                : AppTheme.textMuted,
                          ),
                    ),
                  ),
                ),
              );
            }),
          ),
        ),
      ),
    );
  }

  Widget _buildAlgorithmGrid(BuildContext context) {
    final algorithms = _algorithmsByCategory[_selectedCategory] ?? [];
    
    // Just add media query everywhere dynamically! 
    final screenWidth = MediaQuery.of(context).size.width;
    
    int crossAxisCount = 2;
    if (screenWidth > 800) crossAxisCount = 4;
    else if (screenWidth > 600) crossAxisCount = 3;
    else crossAxisCount = 2;

    double availableWidth = screenWidth - 32.0 - (crossAxisCount - 1) * 12;
    double cardWidth = availableWidth / crossAxisCount;
    
    // We enforce a minimum explicit safe height of 270 logical pixels independently of card scaling width.
    double safeHeight = 270;
    double cardAspectRatio = cardWidth / safeHeight;

    return SliverPadding(
      padding: EdgeInsets.symmetric(horizontal: 16.0),
      sliver: SliverGrid(
        delegate: SliverChildBuilderDelegate(
          (ctx, i) => _AlgoCard(algo: algorithms[i]),
          childCount: algorithms.length,
        ),
        gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: crossAxisCount,
          crossAxisSpacing: 12,
          mainAxisSpacing: 12,
          childAspectRatio: cardAspectRatio,
        ),
      ),
    );
  }

  // ── Stats Section ───────────────────────────────────────────────────────────
  Widget _buildStatsSection(WidgetRef ref) {
    final stats = ref.watch(arenaStatsProvider);

    return SliverToBoxAdapter(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 24, 16, 0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _SectionHeader(label: 'ARENA STATS', icon: Icons.bar_chart_rounded),
            const SizedBox(height: 14),
            Row(
              children: [
                Expanded(child: _ArenaStatCard(
                  label: 'Battles Run', value: stats.battlesRun > 0 ? stats.battlesRun.toString() : '—',
                  icon: Icons.sports_kabaddi_rounded,
                  color: AppTheme.accent)),
                const SizedBox(width: 12),
                Expanded(child: _ArenaStatCard(
                  label: 'Best Algo', value: stats.bestAlgorithm ?? '—',
                  icon: Icons.emoji_events_rounded,
                  color: AppTheme.cyan)),
              ],
            ),
            const SizedBox(height: 12),
            _BattlePromoBanner(),
          ],
        ),
      ),
    );
  }
}

// ─── Algorithm data ────────────────────────────────────────────────────────
class _AlgoInfo {
  final String name;
  final String subtitle;
  final String difficulty;
  final IconData icon;
  final Color color;
  final String route;

  const _AlgoInfo({
    required this.name,
    required this.subtitle,
    required this.difficulty,
    required this.icon,
    required this.color,
    required this.route,
  });
}

const _algorithmsByCategory = <int, List<_AlgoInfo>>{
  0: [ // Pathfinding
    _AlgoInfo(name: 'BFS', subtitle: 'Breadth-First Search',
        difficulty: 'EASY', icon: Icons.account_tree_rounded,
        color: AppTheme.success, route: '/bfs'),
    _AlgoInfo(name: 'DFS', subtitle: 'Depth-First Search',
        difficulty: 'EASY', icon: Icons.fork_right_rounded,
        color: AppTheme.cyan, route: '/dfs'),
    _AlgoInfo(name: 'A*', subtitle: 'Heuristic Pathfinder',
        difficulty: 'MEDIUM', icon: Icons.star_rounded,
        color: AppTheme.accent, route: '/astar'),
    _AlgoInfo(name: 'Dijkstra', subtitle: 'Weighted Shortest Path',
        difficulty: 'HARD', icon: Icons.hub_rounded,
        color: AppTheme.warning, route: '/dijkstra'),
    _AlgoInfo(name: 'Greedy BFS', subtitle: 'Speed-First Search',
        difficulty: 'MEDIUM', icon: Icons.bolt_rounded,
        color: AppTheme.accentLight, route: '/greedy'),
  ],
  1: [ // Puzzle
    _AlgoInfo(name: '8-Puzzle', subtitle: 'Sliding Tile Solver',
        difficulty: 'MEDIUM', icon: Icons.grid_view_rounded,
        color: AppTheme.accent, route: '/eightpuzzle'),
    _AlgoInfo(name: 'N-Queens', subtitle: 'Backtracking Solver',
        difficulty: 'HARD', icon: Icons.change_history_rounded,
        color: AppTheme.warning, route: '/nqueens'),
  ],
  2: [ // Search
    _AlgoInfo(name: 'BFS', subtitle: 'Level-Order Traversal',
        difficulty: 'EASY', icon: Icons.account_tree_rounded,
        color: AppTheme.success, route: '/bfs'),
    _AlgoInfo(name: 'A*', subtitle: 'Best-First Search',
        difficulty: 'MEDIUM', icon: Icons.star_rounded,
        color: AppTheme.accent, route: '/astar'),
  ],
  3: [ // Maze
    _AlgoInfo(name: 'Maze Gen', subtitle: 'Procedural Maze',
        difficulty: 'MEDIUM', icon: Icons.route_rounded,
        color: AppTheme.cyan, route: '/maze'),
  ],
};

// ─── Algorithm Card ───────────────────────────────────────────────────────────
class _AlgoCard extends StatelessWidget {
  const _AlgoCard({required this.algo});
  final _AlgoInfo algo;

  @override
  Widget build(BuildContext context) {
    final diff = algo.difficulty;
    final diffColor = switch (diff) {
      'EASY'   => AppTheme.success,
      'HARD'   => AppTheme.error,
      _        => AppTheme.warning,
    };

    return GestureDetector(
      onTap: () => Navigator.pushNamed(context, algo.route),
      child: RepaintBoundary(
        child: Container(
          decoration: AppTheme.glassCard(radius: 16),
          child: Stack(
            children: [
                // Background icon watermark
                Positioned(
                  right: -10, bottom: -10,
                  child: Icon(algo.icon,
                      size: 80.0,
                      color: algo.color.withValues(alpha: 0.07)),
                ),
                // Left accent bar
                Positioned(
                  left: 0, top: 0, bottom: 0,
                  child: Container(
                    width: 3.0,
                    decoration: BoxDecoration(
                      color: algo.color,
                      borderRadius: BorderRadius.only(
                        topLeft: Radius.circular(16.0),
                        bottomLeft: Radius.circular(16.0),
                      ),
                    ),
                  ),
                ),
                // Content
                Padding(
                  padding:
                      const EdgeInsets.fromLTRB(16, 16, 12, 16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Icon badge
                      Container(
                        width: 42.0, height: 42.0,
                        decoration: BoxDecoration(
                          color: algo.color.withValues(alpha: 0.15),
                          borderRadius: BorderRadius.circular(10.0),
                          border: Border.all(
                              color: algo.color.withValues(alpha: 0.30)),
                        ),
                        child: Icon(algo.icon,
                            color: algo.color, size: 20),
                      ),
                      const Spacer(),
                      // Difficulty badge
                      Container(
                        padding: EdgeInsets.symmetric(horizontal: 7.0, vertical: 3.0),
                        decoration: BoxDecoration(
                          color: diffColor.withValues(alpha: 0.15),
                          borderRadius: BorderRadius.circular(4.0),
                          border: Border.all(
                              color: diffColor.withValues(alpha: 0.35)),
                        ),
                        child: Text(
                          diff,
                          style: Theme.of(context)
                              .textTheme
                              .labelSmall
                              ?.copyWith(
                                color: diffColor,
                                letterSpacing: 1.2,
                              ),
                        ),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        algo.name,
                        style: Theme.of(context)
                            .textTheme
                            .headlineSmall
                            ?.copyWith(fontWeight: FontWeight.w800),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        algo.subtitle,
                        style: Theme.of(context)
                            .textTheme
                            .bodySmall
                            ?.copyWith(color: AppTheme.textMuted),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
                // Tap ripple overlay
                Positioned.fill(
                  child: Material(
                    color: Colors.transparent,
                    child: InkWell(
                      borderRadius: BorderRadius.circular(16.0),
                      onTap: () =>
                          Navigator.pushNamed(context, algo.route),
                      splashColor:
                          algo.color.withValues(alpha: 0.12),
                      highlightColor:
                          algo.color.withValues(alpha: 0.06),
                    ),
                  ),
                ),
              ],
            ),
          ),
    ));
  }
}

// ─── Quick Stat ────────────────────────────────────────────────────────────────
class _QuickStat extends StatelessWidget {
  const _QuickStat({
    required this.label,
    required this.value,
    this.accent = AppTheme.accentLight,
  });
  final String label;
  final String value;
  final Color accent;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 12.0, vertical: 7.0),
      decoration: BoxDecoration(
        color: AppTheme.surfaceHigh,
        borderRadius: BorderRadius.circular(8.0),
        border: Border.all(color: Colors.white.withValues(alpha: 0.07)),
      ),
      child: Column(
        children: [
          Text(value,
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    color: accent, fontWeight: FontWeight.w800)),
          const SizedBox(height: 2),
          Text(label,
              style: Theme.of(context)
                  .textTheme
                  .labelSmall
                  ?.copyWith(letterSpacing: 1.5)),
        ],
      ),
    );
  }
}

// ─── Section Header ────────────────────────────────────────────────────────────
class _SectionHeader extends StatelessWidget {
  const _SectionHeader({required this.label, required this.icon});
  final String label;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    return Row(children: [
      Icon(icon, size: 16.0, color: AppTheme.accent),
      const SizedBox(width: 8),
      Text(label,
          style: Theme.of(context).textTheme.labelLarge?.copyWith(
                color: AppTheme.accentLight, letterSpacing: 2)),
      const SizedBox(width: 8),
      Expanded(
          child: Container(height: 1.0,
              color: Colors.white.withValues(alpha: 0.06))),
    ]);
  }
}

// ─── Arena Stat Card ──────────────────────────────────────────────────────────
class _ArenaStatCard extends StatelessWidget {
  const _ArenaStatCard({
    required this.label,
    required this.value,
    required this.icon,
    required this.color,
  });
  final String label;
  final String value;
  final IconData icon;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.all(16.0),
      decoration: AppTheme.glassCard(
        radius: 14,
        borderColor: color.withValues(alpha: 0.3),
      ),
      child: Row(
            children: [
              Container(
                width: 38.0, height: 38.0,
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(9.0),
                  border: Border.all(color: color.withValues(alpha: 0.3)),
                ),
                child: Icon(icon, color: color, size: 18),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(value,
                        style: Theme.of(context)
                            .textTheme
                            .headlineSmall
                            ?.copyWith(
                              fontWeight: FontWeight.w800,
                              color: color,
                            )),
                    Text(label,
                        style: Theme.of(context)
                            .textTheme
                            .labelSmall),
                  ],
                ),
              ),
            ],
      ),
    );
  }
}

// ─── Battle Promo Banner ───────────────────────────────────────────────────────
class _BattlePromoBanner extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => Navigator.pushNamed(context, '/battle'),
      child: Container(
        width: double.infinity,
        padding: EdgeInsets.all(20.0),
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [AppTheme.accentContainer, Color(0xFF1E0B4A)],
          ),
          borderRadius: BorderRadius.circular(16.0),
          border: Border.all(color: AppTheme.accent.withValues(alpha: 0.4)),
          boxShadow: [
            BoxShadow(
              color: AppTheme.accent.withValues(alpha: 0.20),
              blurRadius: 20,
            ),
          ],
        ),
        child: Row(
          children: [
            Container(
              width: 48.0, height: 48.0,
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(12.0),
              ),
              child: const Icon(Icons.sports_kabaddi_rounded,
                  color: Colors.white, size: 24),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('ALGORITHM BATTLE',
                      style: Theme.of(context)
                          .textTheme
                          .labelLarge
                          ?.copyWith(
                            color: AppTheme.accentLight,
                            letterSpacing: 1.5,
                          )),
                  const SizedBox(height: 4),
                  Text('Compare algorithms head-to-head in real time',
                      style: Theme.of(context)
                          .textTheme
                          .bodySmall
                          ?.copyWith(color: Colors.white70)),
                ],
              ),
            ),
            const Icon(Icons.arrow_forward_ios_rounded,
                color: Colors.white54, size: 16),
          ],
        ),
      ),
    );
  }
}

// ─── Ambient Node-Graph Painter ────────────────────────────────────────────────
class _NodeGraphPainterWidget extends StatelessWidget {
  const _NodeGraphPainterWidget({required this.pulse});
  final Animation<double> pulse;

  @override
  Widget build(BuildContext context) {
    return RepaintBoundary(
      child: AnimatedBuilder(
        animation: pulse,
        builder: (context, child) => Opacity(
          opacity: pulse.value * 0.06,
          child: const CustomPaint(
            painter: _NodeGraphPainter(), // No longer need to pass opacity
            size: Size(double.infinity, 240),
          ),
        ),
      ),
    );
  }
}

class _NodeGraphPainter extends CustomPainter {
  const _NodeGraphPainter();

  static final List<Offset> _nodes = [
    Offset(0.1, 0.15), Offset(0.3, 0.05), Offset(0.55, 0.20),
    Offset(0.75, 0.08), Offset(0.90, 0.30), Offset(0.20, 0.55),
    Offset(0.45, 0.65), Offset(0.70, 0.50), Offset(0.85, 0.70),
  ];
  static final List<List<int>> _edges = [
    [0, 1], [1, 2], [2, 3], [3, 4], [0, 5], [5, 6],
    [6, 7], [7, 8], [2, 6], [3, 7],
  ];

  @override
  void paint(Canvas canvas, Size size) {
    final linePaint = Paint()
      ..color = AppTheme.accent.withValues(alpha: 1.0)
      ..strokeWidth = 1.0;
    final nodePaint = Paint()
      ..color = AppTheme.accent.withValues(alpha: 1.0);

    final pts = _nodes.map((n) => Offset(n.dx * size.width, n.dy * size.height)).toList();
    for (final e in _edges) {
      canvas.drawLine(pts[e[0]], pts[e[1]], linePaint);
    }
    for (final p in pts) {
      canvas.drawCircle(p, 3.5, nodePaint);
    }
  }

  @override
  bool shouldRepaint(_NodeGraphPainter old) => false; // Static drawing, handled by Opacity
}
