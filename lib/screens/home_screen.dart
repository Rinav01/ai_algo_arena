import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:ai_algo_app/core/app_theme.dart';
import 'package:ai_algo_app/widgets/bottom_nav_bar.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

// ─── Home Screen ─────────────────────────────────────────────────────────────
class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});
  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen>
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
          _buildHeroSliver(),
          _buildCategoryChips(),
          _buildAlgorithmGrid(),
          _buildStatsSection(),
          const SliverToBoxAdapter(child: SizedBox(height: 100)),
        ],
      ),
      bottomNavigationBar: const ArenaBottomNavBar(currentIndex: 0),
    );
  }

  // ── Hero Header ─────────────────────────────────────────────────────────────
  Widget _buildHeroSliver() {
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
                  width: 220.w,
                  height: 220.h,
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
                    padding: EdgeInsets.symmetric(horizontal: 10.w, vertical: 4.h),
                    decoration: BoxDecoration(
                      color: AppTheme.accentContainer.withValues(alpha: 0.25),
                      borderRadius: BorderRadius.circular(6.r),
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
                          height: 1.1.h,
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
                      _QuickStat(label: 'ALGORITHMS', value: '8+'),
                      _QuickStat(label: 'CATEGORIES', value: '4'),
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
                padding: EdgeInsets.only(right: 10.w),
                child: GestureDetector(
                  onTap: () => setState(() => _selectedCategory = i),
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 250),
                    curve: Curves.easeOut,
                    padding: EdgeInsets.symmetric(horizontal: 18.w, vertical: 9.h),
                    decoration: BoxDecoration(
                      color: isActive
                          ? AppTheme.accentContainer
                          : AppTheme.surfaceHighest,
                      borderRadius: BorderRadius.circular(8.r),
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

  // ── Algorithm Grid ──────────────────────────────────────────────────────────
  Widget _buildAlgorithmGrid() {
    final algorithms = _algorithmsByCategory[_selectedCategory] ?? [];
    return SliverPadding(
      padding: EdgeInsets.symmetric(horizontal: 16.w),
      sliver: SliverGrid(
        delegate: SliverChildBuilderDelegate(
          (ctx, i) => _AlgoCard(algo: algorithms[i]),
          childCount: algorithms.length,
        ),
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 2,
          crossAxisSpacing: 12,
          mainAxisSpacing: 12,
          childAspectRatio: 0.85,
        ),
      ),
    );
  }

  // ── Stats Section ───────────────────────────────────────────────────────────
  Widget _buildStatsSection() {
    return SliverToBoxAdapter(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 24, 16, 0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _SectionHeader(label: 'ARENA STATS', icon: Icons.bar_chart_rounded),
            const SizedBox(height: 14),
            Row(
              children: const [
                Expanded(child: _ArenaStatCard(
                  label: 'Battles Run', value: '—',
                  icon: Icons.sports_kabaddi_rounded,
                  color: AppTheme.accent)),
                SizedBox(width: 12),
                Expanded(child: _ArenaStatCard(
                  label: 'Best Algo', value: 'A*',
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
      child: ClipRRect(
        borderRadius: BorderRadius.circular(16.r),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 16, sigmaY: 16),
          child: Container(
            decoration: BoxDecoration(
              color: AppTheme.surfaceVariant.withValues(alpha: 0.55),
              borderRadius: BorderRadius.circular(16.r),
              border: Border.all(color: Colors.white.withValues(alpha: 0.07)),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.35),
                  blurRadius: 24, spreadRadius: -4,
                ),
              ],
            ),
            child: Stack(
              children: [
                // Background icon watermark
                Positioned(
                  right: -10, bottom: -10,
                  child: Icon(algo.icon,
                      size: 80.sp,
                      color: algo.color.withValues(alpha: 0.07)),
                ),
                // Left accent bar
                Positioned(
                  left: 0, top: 0, bottom: 0,
                  child: Container(
                    width: 3.w,
                    decoration: BoxDecoration(
                      color: algo.color,
                      borderRadius: BorderRadius.only(
                        topLeft: Radius.circular(16.r),
                        bottomLeft: Radius.circular(16.r),
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
                        width: 42.w, height: 42.h,
                        decoration: BoxDecoration(
                          color: algo.color.withValues(alpha: 0.15),
                          borderRadius: BorderRadius.circular(10.r),
                          border: Border.all(
                              color: algo.color.withValues(alpha: 0.30)),
                        ),
                        child: Icon(algo.icon,
                            color: algo.color, size: 20),
                      ),
                      const Spacer(),
                      // Difficulty badge
                      Container(
                        padding: EdgeInsets.symmetric(horizontal: 7.w, vertical: 3.h),
                        decoration: BoxDecoration(
                          color: diffColor.withValues(alpha: 0.15),
                          borderRadius: BorderRadius.circular(4.r),
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
                      borderRadius: BorderRadius.circular(16.r),
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
        ),
      ),
    );
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
      padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 7.h),
      decoration: BoxDecoration(
        color: AppTheme.surfaceHigh,
        borderRadius: BorderRadius.circular(8.r),
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
      Icon(icon, size: 16.sp, color: AppTheme.accent),
      const SizedBox(width: 8),
      Text(label,
          style: Theme.of(context).textTheme.labelLarge?.copyWith(
                color: AppTheme.accentLight, letterSpacing: 2)),
      const SizedBox(width: 8),
      Expanded(
          child: Container(height: 1.h,
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
    return ClipRRect(
      borderRadius: BorderRadius.circular(14.r),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
        child: Container(
          padding: EdgeInsets.all(16.r),
          decoration: BoxDecoration(
            color: AppTheme.surfaceVariant.withValues(alpha: 0.55),
            borderRadius: BorderRadius.circular(14.r),
            border: Border.all(color: Colors.white.withValues(alpha: 0.07)),
          ),
          child: Row(
            children: [
              Container(
                width: 38.w, height: 38.h,
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(9.r),
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
        ),
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
        padding: EdgeInsets.all(20.r),
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [AppTheme.accentContainer, Color(0xFF1E0B4A)],
          ),
          borderRadius: BorderRadius.circular(16.r),
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
              width: 48.w, height: 48.h,
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(12.r),
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
    return AnimatedBuilder(
      animation: pulse,
      builder: (context, child) => CustomPaint(
        painter: _NodeGraphPainter(opacity: pulse.value * 0.06),
        size: const Size(double.infinity, 240),
      ),
    );
  }
}

class _NodeGraphPainter extends CustomPainter {
  const _NodeGraphPainter({required this.opacity});
  final double opacity;

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
      ..color = AppTheme.accent.withValues(alpha: opacity)
      ..strokeWidth = 1.0;
    final nodePaint = Paint()
      ..color = AppTheme.accent.withValues(alpha: opacity * 2);

    final pts = _nodes.map((n) => Offset(n.dx * size.width, n.dy * size.height)).toList();
    for (final e in _edges) {
      canvas.drawLine(pts[e[0]], pts[e[1]], linePaint);
    }
    for (final p in pts) {
      canvas.drawCircle(p, 3.5, nodePaint);
    }
  }

  @override
  bool shouldRepaint(_NodeGraphPainter old) => old.opacity != opacity;
}
