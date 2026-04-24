import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:algo_arena/core/app_theme.dart';
import 'package:algo_arena/services/api_service.dart';
import 'package:algo_arena/widgets/bottom_nav_bar.dart';

final apiServiceProvider = Provider((ref) => ApiService());

final runsProvider = FutureProvider<List<dynamic>>((ref) async {
  final api = ref.watch(apiServiceProvider);
  debugPrint('Fetching run history...');
  final runs = await api.getRuns();
  debugPrint('Fetched ${runs.length} runs');
  return runs;
});

class HistoryScreen extends ConsumerWidget {
  const HistoryScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
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
              _buildHeader(context),
              runsAsync.when(
                data: (runs) => _buildRunsList(context, runs, ref),
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

  Widget _buildHeader(BuildContext context) {
    return SliverToBoxAdapter(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(20, 40, 20, 24),
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
          ],
        ),
      ),
    );
  }

  Widget _buildRunsList(BuildContext context, List<dynamic> runs, WidgetRef ref) {
    if (runs.isEmpty) {
      return SliverFillRemaining(
        hasScrollBody: false,
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.history_toggle_off_rounded, size: 64, color: Colors.white.withOpacity(0.2)),
              const SizedBox(height: 16),
              Text(
                'No runs found yet',
                style: TextStyle(color: Colors.white.withOpacity(0.5)),
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
    final isBattle = run['isBattle'] == true;
    final algo = run['algorithm'] ?? 'Unknown';
    final timestamp = run['timestamp'] ?? '';
    final stepsRaw = run['steps'];
    final int steps = stepsRaw is List ? stepsRaw.length : (stepsRaw ?? 0);
    final duration = run['durationMs'] ?? 0;

    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Container(
        decoration: AppTheme.glassCard(radius: 16),
        child: InkWell(
          borderRadius: BorderRadius.circular(16),
          onTap: () => Navigator.pushNamed(context, '/replay', arguments: run),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                Container(
                  width: 48,
                  height: 48,
                  decoration: BoxDecoration(
                    color: (isBattle ? AppTheme.error : AppTheme.accent).withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: (isBattle ? AppTheme.error : AppTheme.accent).withOpacity(0.2)),
                  ),
                  child: Icon(
                    isBattle ? Icons.compare_arrows_rounded : Icons.play_circle_outline_rounded, 
                    color: isBattle ? AppTheme.error : AppTheme.accent,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        isBattle ? 'BATTLE: $algo' : algo,
                        style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        _formatDate(timestamp),
                        style: Theme.of(context).textTheme.labelSmall,
                      ),
                    ],
                  ),
                ),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(
                      '$steps steps',
                      style: const TextStyle(color: AppTheme.cyan, fontWeight: FontWeight.w600),
                    ),
                    Text(
                      '${duration}ms',
                      style: Theme.of(context).textTheme.labelSmall,
                    ),
                  ],
                ),
                const SizedBox(width: 16),
                // Delete Button
                IconButton(
                  icon: Icon(Icons.delete_outline_rounded, color: AppTheme.error.withOpacity(0.6), size: 20),
                  onPressed: () => _confirmDelete(context, ref),
                ),
                const Icon(Icons.chevron_right_rounded, color: Colors.white24),
              ],
            ),
          ),
        ),
      ),
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
