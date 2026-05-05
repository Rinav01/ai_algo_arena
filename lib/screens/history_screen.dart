import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:algo_arena/core/app_theme.dart';
import 'package:algo_arena/state/api_provider.dart';
import 'package:algo_arena/widgets/bottom_nav_bar.dart';
import 'package:algo_arena/widgets/feature_tour.dart';

enum SortMode { latest, time, efficiency }
enum FilterType { all, single, battle }
enum GridSize { all, small, medium, large }

final sortModeProvider = StateProvider<SortMode>((ref) => SortMode.latest);
final filterTypeProvider = StateProvider<FilterType>((ref) => FilterType.all);
final filterGridSizeProvider = StateProvider<GridSize>((ref) => GridSize.all);

/// Reactive provider that handles filtering and sorting off the main thread
final processedRunsProvider = Provider<AsyncValue<List<dynamic>>>((ref) {
  final runsAsync = ref.watch(runsProvider);
  final sortMode = ref.watch(sortModeProvider);
  final filterType = ref.watch(filterTypeProvider);
  final gridSize = ref.watch(filterGridSizeProvider);

  return runsAsync.whenData((runs) {
    // This logic is now cached and only re-runs when inputs change
    return _processRunsInternal(runs, sortMode, filterType, gridSize);
  });
});

/// Extracted static logic for processing
List<dynamic> _processRunsInternal(
  List<dynamic> runs,
  SortMode sortMode,
  FilterType filterType,
  GridSize gridSizeFilter,
) {
  var processed = List<dynamic>.from(runs);

  // Filter by Type
  if (filterType != FilterType.all) {
    processed = processed.where((r) {
      final isBattle = r['type'] == 'battle';
      return filterType == FilterType.battle ? isBattle : !isBattle;
    }).toList();
  }

  // Filter by Grid Size
  if (gridSizeFilter != GridSize.all) {
    processed = processed.where((r) {
      final meta = r['metadata'] as Map<String, dynamic>?;
      final size = (meta?['gridSize'] as String?) ?? '';
      if (size.contains('x')) {
        final parts = size.split('x');
        final area = (int.tryParse(parts[0]) ?? 0) * (int.tryParse(parts[1]) ?? 0);
        if (gridSizeFilter == GridSize.small) return area < 225;
        if (gridSizeFilter == GridSize.medium) return area >= 225 && area <= 900;
        if (gridSizeFilter == GridSize.large) return area > 900;
      }
      return false;
    }).toList();
  }

  // Pre-calculate values for sorting to avoid parsing overhead during O(n log n) sort
  final sortCache = <dynamic, dynamic>{};
  for (var r in processed) {
    final meta = r['metadata'] as Map<String, dynamic>?;
    if (sortMode == SortMode.latest) {
      sortCache[r] = DateTime.tryParse(r['timestamp'] ?? '')?.millisecondsSinceEpoch ?? 0;
    } else if (sortMode == SortMode.time) {
      sortCache[r] = (meta?['durationMs'] as num? ?? 999999).toInt();
    } else if (sortMode == SortMode.efficiency) {
      sortCache[r] = (meta?['steps'] as num? ?? 999999).toInt();
    }
  }

  processed.sort((a, b) {
    final valA = sortCache[a] as int;
    final valB = sortCache[b] as int;
    return sortMode == SortMode.latest ? valB.compareTo(valA) : valA.compareTo(valB);
  });

  return processed;
}

class HistoryScreen extends ConsumerStatefulWidget {
  const HistoryScreen({super.key});

  @override
  ConsumerState<HistoryScreen> createState() => _HistoryScreenState();
}

class _HistoryScreenState extends ConsumerState<HistoryScreen> {
  final GlobalKey _summaryKey = GlobalKey();
  final GlobalKey _controlsKey = GlobalKey();
  final GlobalKey _runsKey = GlobalKey();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      FeatureTour.startTour(
        context: context,
        tourKey: 'history_screen',
        steps: [
          TourStep(
            targetKey: _summaryKey,
            title: 'Summary Stats',
            description: 'Check your overall algorithm run statistics including Total Runs, Average Steps, and your Most Used algorithm.',
          ),
          TourStep(
            targetKey: _controlsKey,
            title: 'Sort & Filter Options',
            description: 'Sort your past runs by Latest, Fastest, or Efficiency, and use the filter button to drill down by types or grid sizes.',
          ),
          TourStep(
            targetKey: _runsKey,
            title: 'Detailed Runs',
            description: 'View the complete breakdown of each algorithm run including time, steps, and grid details.',
          ),
        ],
      );
    });
  }

  @override
  Widget build(BuildContext context) {
    final processedRunsAsync = ref.watch(processedRunsProvider);
    final runsAsync = ref.watch(runsProvider);

    return Scaffold(
      backgroundColor: AppTheme.background,
      body: SafeArea(
        child: RefreshIndicator(
          color: AppTheme.accent,
          backgroundColor: AppTheme.surface,
          onRefresh: () => ref.refresh(runsProvider.future),
          child: CustomScrollView(
            physics: const AlwaysScrollableScrollPhysics(
              parent: BouncingScrollPhysics(),
            ),
            slivers: [
              _buildHeader(context, runsAsync),
              _buildControlBar(context),
              processedRunsAsync.when(
                data: (processedRuns) {
                  return _buildRunsList(context, processedRuns);
                },
                loading: () => const SliverFillRemaining(
                  child: Center(child: CircularProgressIndicator(color: AppTheme.accent)),
                ),
                error: (err, stack) => SliverFillRemaining(
                  child: Center(
                    child: Padding(
                      padding: const EdgeInsets.all(24.0),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Icon(Icons.error_outline_rounded, color: AppTheme.error, size: 48),
                          const SizedBox(height: 16),
                          Text(
                            'Failed to load history',
                            style: Theme.of(context).textTheme.titleMedium,
                          ),
                          const SizedBox(height: 8),
                          Text(
                            err.toString(),
                            textAlign: TextAlign.center,
                            style: Theme.of(context).textTheme.bodySmall?.copyWith(color: AppTheme.textMuted),
                          ),
                          const SizedBox(height: 24),
                          ElevatedButton(
                            onPressed: () => ref.refresh(runsProvider),
                            style: ElevatedButton.styleFrom(backgroundColor: AppTheme.accent),
                            child: const Text('RETRY'),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
              const SliverToBoxAdapter(child: SizedBox(height: 100)),
            ],
          ),
        ),
      ),
      bottomNavigationBar: const ArenaBottomNavBar(currentIndex: 2),
    );
  }

  Widget _buildHeader(BuildContext context, AsyncValue<List<dynamic>> runsAsync) {
    return SliverToBoxAdapter(
      child: ClipRect(
        child: Stack(
          children: [
            Positioned(
              left: -50,
              bottom: -50,
              child: IgnorePointer(
                child: Icon(
                  Icons.history_rounded,
                  size: 400,
                  color: AppTheme.accent.withValues(alpha: 0.02),
                ),
              ),
            ),
            Positioned(
              right: -20,
              top: -10,
              child: IgnorePointer(
                child: Icon(
                  Icons.history_rounded,
                  size: 180,
                  color: AppTheme.accent.withValues(alpha: 0.05),
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsetsDirectional.fromSTEB(
                20,
                40,
                20,
                16,
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'RUN HISTORY',
                    style: Theme.of(context).textTheme.labelLarge?.copyWith(
                      color: AppTheme.accentLight,
                      letterSpacing: 2,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Past Executions',
                    style: Theme.of(context).textTheme.displaySmall?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                  const SizedBox(height: 24),
                  runsAsync.when(
                    data: (runs) => _buildSummarySection(context, runs),
                    loading: () => const SizedBox(height: 80),
                    error: (err, stack) => const SizedBox(),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSummarySection(BuildContext context, List<dynamic> runs) {
    if (runs.isEmpty) return const SizedBox();

    final totalRuns = runs.length;
    final algoCounts = <String, int>{};
    int totalSteps = 0;
    
    for (var r in runs) {
      final name = r['algorithm'] ?? 'Unknown';
      algoCounts[name] = (algoCounts[name] ?? 0) + 1;
      final meta = r['metadata'] as Map<String, dynamic>?;
      totalSteps += (meta?['steps'] as num? ?? 0).toInt();
    }
    
    final avgSteps = totalRuns > 0 ? totalSteps / totalRuns : 0.0;
    final mostUsed = algoCounts.entries.isEmpty 
        ? 'N/A' 
        : algoCounts.entries.reduce((a, b) => a.value > b.value ? a : b).key;

    return KeyedSubtree(
      key: _summaryKey,
      child: Row(
        children: [
          Expanded(child: _buildSummaryItem(context, 'Total Runs', totalRuns.toString())),
          const SizedBox(width: 8),
          Expanded(child: _buildSummaryItem(context, 'Avg. Steps', avgSteps.toStringAsFixed(0))),
          const SizedBox(width: 8),
          Expanded(child: _buildSummaryItem(context, 'Most Used', mostUsed)),
        ],
      ),
    );
  }

  Widget _buildSummaryItem(BuildContext context, String label, String value) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.03),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.white.withValues(alpha: 0.05)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            label.toUpperCase(),
            style: TextStyle(
              color: AppTheme.accentLight.withValues(alpha: 0.6),
              fontSize: 10,
              fontWeight: FontWeight.bold,
              letterSpacing: 1,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            value,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 14,
              fontWeight: FontWeight.bold,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }

  Widget _buildControlBar(BuildContext context) {
    return SliverToBoxAdapter(
      child: KeyedSubtree(
        key: _controlsKey,
        child: Container(
          margin: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: 0.05),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: Colors.white.withValues(alpha: 0.1)),
          ),
          child: Row(
            children: [
              Expanded(
                child: SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Row(
                    children: [
                      _buildSortChip(SortMode.latest, 'Latest'),
                      _buildSortChip(SortMode.time, 'Fastest'),
                      _buildSortChip(SortMode.efficiency, 'Efficiency'),
                    ],
                  ),
                ),
              ),
              Container(
                height: 24,
                width: 1,
                color: Colors.white.withValues(alpha: 0.1),
                margin: const EdgeInsets.symmetric(horizontal: 8),
              ),
              IconButton(
                icon: const Icon(Icons.tune_rounded, color: AppTheme.accentLight, size: 20),
                onPressed: () => _showFilterSheet(context),
                visualDensity: VisualDensity.compact,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSortChip(SortMode mode, String label) {
    final currentMode = ref.watch(sortModeProvider);
    final isSelected = currentMode == mode;

    return GestureDetector(
      onTap: () => ref.read(sortModeProvider.notifier).state = mode,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        margin: const EdgeInsets.only(right: 8),
        decoration: BoxDecoration(
          color: isSelected ? AppTheme.accent.withValues(alpha: 0.2) : Colors.transparent,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(
            color: isSelected ? AppTheme.accent.withValues(alpha: 0.5) : Colors.transparent,
          ),
        ),
        child: Text(
          label,
          style: TextStyle(
            color: isSelected ? Colors.white : Colors.white.withValues(alpha: 0.5),
            fontSize: 13,
            fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
          ),
        ),
      ),
    );
  }

  void _showFilterSheet(BuildContext context) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) => _FilterSheet(ref: ref),
    );
  }

  Widget _buildRunsList(BuildContext context, List<dynamic> runs) {
    if (runs.isEmpty) {
      return SliverFillRemaining(
        hasScrollBody: false,
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.history_toggle_off_rounded, size: 64, color: Colors.white.withValues(alpha: 0.2)),
              const SizedBox(height: 16),
              Text(
                'No runs found yet',
                style: TextStyle(color: Colors.white.withValues(alpha: 0.5)),
              ),
            ],
          ),
        ),
      );
    }

    return SliverPadding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      sliver: SliverList(
        delegate: SliverChildBuilderDelegate(
          (context, index) {
            final run = runs[index];
            if (index == 0) {
              return KeyedSubtree(
                key: _runsKey,
                child: _RunCard(run: run),
              );
            }
            return _RunCard(run: run);
          },
          childCount: runs.length,
        ),
      ),
    );
  }
}

class _RunCard extends ConsumerWidget {
  final dynamic run;
  const _RunCard({required this.run});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isBattle = run['isBattle'] == true || run['type'] == 'battle';
    final algo = run['algorithm'] ?? 'Unknown';
    final timestamp = run['timestamp'] ?? '';
    final metadata = run['metadata'] as Map<String, dynamic>?;
    final density = (metadata?['obstacleDensity'] as num?)?.toDouble();

    final competitors = run['competitors'] as List<dynamic>?;
    int steps = 0;
    int duration = 0;

    // Extract metrics
    if (isBattle && competitors != null && competitors.isNotEmpty) {
      // For battles, identify the winner and show their metrics
      String? winnerName = (run['metadata'] as Map?)?['winner'];
      var winnerComp = competitors.firstWhere(
        (c) => c['isWinner'] == true || (winnerName != null && c['name'] == winnerName), 
        orElse: () => competitors.first
      );
      
      duration = (winnerComp['durationMs'] as num? ?? 0).toInt();
      final compSteps = winnerComp['steps'];
      if (compSteps is List) {
        steps = compSteps.length;
      } else {
        steps = (winnerComp['totalSteps'] as num? ?? 0).toInt();
      }
    } else {
      // For single runs or fallback
      duration = (run['durationMs'] as num? ?? 0).toInt();
      final stepsRaw = run['steps'];
      if (stepsRaw is List) {
        steps = stepsRaw.length;
      } else {
        steps = (run['totalSteps'] as num? ?? 0).toInt();
      }
    }

    // Extract competitive insights for battles
    int deltaSteps = 0;
    int deltaTime = 0;
    if (isBattle && competitors != null && competitors.length >= 2) {
      final winnerName = (run['metadata'] as Map?)?['winner'];
      final winnerComp = competitors.firstWhere(
        (c) => c['isWinner'] == true || (winnerName != null && c['name'] == winnerName), 
        orElse: () => competitors.first
      );
      final loserComp = competitors.firstWhere((c) => c != winnerComp, orElse: () => competitors.last);
      
      final winnerS = (winnerComp['steps'] is List) ? (winnerComp['steps'] as List).length : (winnerComp['totalSteps'] as num? ?? 0).toInt();
      final loserS = (loserComp['steps'] is List) ? (loserComp['steps'] as List).length : (loserComp['totalSteps'] as num? ?? 0).toInt();
      
      deltaSteps = (loserS - winnerS);
      deltaTime = ((loserComp['durationMs'] as num? ?? 0).toInt()) - ((winnerComp['durationMs'] as num? ?? 0).toInt());
    }

    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: 0.03),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: Colors.white.withValues(alpha: 0.05)),
        ),
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: () {
            debugPrint('HistoryScreen: Tapped card for run ${run['_id'] ?? run['id']}');
            debugPrint('HistoryScreen: Arguments: $run');
            Navigator.pushNamed(context, '/replay', arguments: run);
          },
          child: IntrinsicHeight(
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // Left Accent Bar (Asymmetry)
                Container(
                  width: 6,
                  color: isBattle ? AppTheme.error : AppTheme.accent,
                ),
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Icon(
                              isBattle ? Icons.bolt_rounded : Icons.psychology_rounded,
                              size: 16,
                              color: isBattle ? AppTheme.error : AppTheme.accent,
                            ),
                            const SizedBox(width: 8),
                            Text(
                              isBattle ? 'BATTLE ARENA' : 'SOLO EXECUTION',
                              style: TextStyle(
                                color: (isBattle ? AppTheme.error : AppTheme.accent).withValues(alpha: 0.7),
                                fontSize: 10,
                                fontWeight: FontWeight.bold,
                                letterSpacing: 1.5,
                              ),
                            ),
                            const Spacer(),
                            Text(
                              _formatDate(timestamp),
                              style: TextStyle(
                                color: Colors.white.withValues(alpha: 0.3),
                                fontSize: 10,
                                fontFamily: 'monospace',
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),
                        Text(
                          isBattle ? '$algo' : algo,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 12),
                        if (isBattle && deltaSteps > 0)
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                            margin: const EdgeInsets.only(bottom: 12),
                            decoration: BoxDecoration(
                              color: AppTheme.accent.withValues(alpha: 0.1),
                              borderRadius: BorderRadius.circular(8),
                              border: Border.all(color: AppTheme.accent.withValues(alpha: 0.2)),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                const Icon(Icons.stars_rounded, color: AppTheme.accent, size: 14),
                                const SizedBox(width: 6),
                                Text(
                                  'Won by $deltaSteps steps • ${deltaTime}ms faster',
                                  style: const TextStyle(
                                    color: AppTheme.accentLight,
                                    fontSize: 11,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        Row(
                          children: [
                            Expanded(child: _buildMetric(context, Icons.grid_view_rounded, '$steps', 'Nodes')),
                            Expanded(child: _buildMetric(context, Icons.timer_outlined, '${duration}ms', 'Duration')),
                            if (density != null)
                              Expanded(child: _buildMetric(context, Icons.grain_rounded, '${(density * 100).toInt()}%', 'Density')),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
                // Action Area
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.02),
                    border: Border(left: BorderSide(color: Colors.white.withValues(alpha: 0.05))),
                  ),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      IconButton(
                        icon: const Icon(Icons.play_arrow_rounded, color: AppTheme.accentLight),
                        onPressed: () {
                          debugPrint('HistoryScreen: Pressed play button for run ${run['_id'] ?? run['id']}');
                          Navigator.pushNamed(context, '/replay', arguments: run);
                        },
                      ),
                      IconButton(
                        icon: Icon(Icons.delete_outline_rounded, color: AppTheme.error.withValues(alpha: 0.5), size: 20),
                        onPressed: () => _confirmDelete(context, ref),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildMetric(BuildContext context, IconData icon, String value, String label) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(icon, size: 12, color: Colors.white.withValues(alpha: 0.4)),
            const SizedBox(width: 4),
            Text(
              value,
              style: const TextStyle(color: Colors.white, fontSize: 13, fontWeight: FontWeight.bold),
            ),
          ],
        ),
        Text(
          label.toUpperCase(),
          style: TextStyle(color: Colors.white.withValues(alpha: 0.3), fontSize: 9, fontWeight: FontWeight.bold),
        ),
      ],
    );
  }

  void _confirmDelete(BuildContext context, WidgetRef ref) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: AppTheme.surface,
        title: const Text('Delete Run?'),
        content: const Text('This action cannot be undone. Are you sure?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('CANCEL', style: TextStyle(color: AppTheme.textMuted)),
          ),
          TextButton(
            onPressed: () async {
              final id = run['_id'];
              Navigator.pop(context); // Close dialog
              
              if (id != null) {
                try {
                  await ref.read(apiServiceProvider).deleteRun(id);
                  ref.invalidate(runsProvider);
                } catch (e) {
                  if (context.mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text('Error: $e')),
                    );
                  }
                }
              }
            },
            child: const Text('DELETE', style: TextStyle(color: AppTheme.error)),
          ),
        ],
      ),
    );
  }

  String _formatDate(String isoString) {
    try {
      final dt = DateTime.parse(isoString);
      return '${dt.day}/${dt.month}/${dt.year} ${dt.hour}:${dt.minute.toString().padLeft(2, '0')}';
    } catch (_) {
      return isoString;
    }
  }
}

class _FilterSheet extends ConsumerWidget {
  final WidgetRef ref;
  const _FilterSheet({required this.ref});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final currentType = ref.watch(filterTypeProvider);
    final currentGridSize = ref.watch(filterGridSizeProvider);

    return Container(
      decoration: BoxDecoration(
        color: AppTheme.background.withValues(alpha: 0.95),
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
        border: Border.all(color: Colors.white.withValues(alpha: 0.1)),
      ),
      padding: const EdgeInsets.fromLTRB(24, 12, 24, 40),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Center(
            child: Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.2),
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
          const SizedBox(height: 24),
          const Text(
            'ADVANCED FILTERS',
            style: TextStyle(
              color: AppTheme.accentLight,
              fontSize: 12,
              fontWeight: FontWeight.bold,
              letterSpacing: 2,
            ),
          ),
          const SizedBox(height: 24),
          _buildFilterSection(
            'Algorithm Type',
            [
              _FilterOption(FilterType.all, 'All', currentType == FilterType.all),
              _FilterOption(FilterType.single, 'Single', currentType == FilterType.single),
              _FilterOption(FilterType.battle, 'Battle', currentType == FilterType.battle),
            ],
            (val) => ref.read(filterTypeProvider.notifier).state = val as FilterType,
          ),
          const SizedBox(height: 24),
          _buildFilterSection(
            'Grid Scale',
            [
              _FilterOption(GridSize.all, 'All Sizes', currentGridSize == GridSize.all),
              _FilterOption(GridSize.small, 'Small', currentGridSize == GridSize.small),
              _FilterOption(GridSize.medium, 'Medium', currentGridSize == GridSize.medium),
              _FilterOption(GridSize.large, 'Large', currentGridSize == GridSize.large),
            ],
            (val) => ref.read(filterGridSizeProvider.notifier).state = val as GridSize,
          ),
        ],
      ),
    );
  }

  Widget _buildFilterSection(String label, List<_FilterOption> options, Function(dynamic) onSelected) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(color: Colors.white70, fontSize: 14, fontWeight: FontWeight.w500),
        ),
        const SizedBox(height: 12),
        Wrap(
          spacing: 8,
          children: options.map((opt) {
            return ChoiceChip(
              label: Text(opt.label),
              selected: opt.isSelected,
              onSelected: (selected) {
                if (selected) onSelected(opt.value);
              },
              backgroundColor: Colors.white.withValues(alpha: 0.05),
              selectedColor: AppTheme.accent.withValues(alpha: 0.3),
              labelStyle: TextStyle(
                color: opt.isSelected ? Colors.white : Colors.white60,
                fontSize: 13,
              ),
              side: BorderSide(
                color: opt.isSelected ? AppTheme.accent.withValues(alpha: 0.5) : Colors.white.withValues(alpha: 0.1),
              ),
            );
          }).toList(),
        ),
      ],
    );
  }
}

class _FilterOption {
  final dynamic value;
  final String label;
  final bool isSelected;
  _FilterOption(this.value, this.label, this.isSelected);
}
