import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:algo_arena/core/app_theme.dart';
import 'package:algo_arena/widgets/bottom_nav_bar.dart';
import 'package:algo_arena/state/settings_provider.dart';
import 'package:algo_arena/services/stats_service.dart';

import 'package:algo_arena/state/api_provider.dart';

class SettingsScreen extends ConsumerWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final settings = ref.watch(settingsProvider);
    final notifier = ref.read(settingsProvider.notifier);

    return Scaffold(
      body: CustomScrollView(
        slivers: [
          _buildSliverAppBar(context, notifier),
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(20, 0, 20, 100),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildSectionHeader('VISUAL ENGINE'),
                  _buildSettingTile(
                    title: 'Neon Glow Intensity',
                    subtitle: 'Control the bloom effect on path nodes',
                    trailing: SizedBox(
                      width: 140,
                      child: Slider(
                        value: settings.neonGlowIntensity,
                        onChanged: notifier.updateNeonGlow,
                      ),
                    ),
                  ),
                  _buildSettingTile(
                    title: 'Grid Transparency',
                    subtitle: 'Subtlety of background coordinate lines',
                    trailing: SizedBox(
                      width: 140,
                      child: Slider(
                        value: settings.gridTransparency,
                        onChanged: notifier.updateGridTransparency,
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),
                  _buildSectionHeader('ALGORITHM PARAMETERS'),
                  _buildSettingTile(
                    title: 'Allow Diagonal Moves',
                    subtitle: 'Enable 8-directional exploration in pathfinding',
                    trailing: Switch(
                      value: settings.allowDiagonalMoves,
                      onChanged: notifier.toggleDiagonalMoves,
                    ),
                  ),
                  _buildSettingTile(
                    title: 'Heuristic Weight',
                    subtitle: 'Bias factor for A* and Greedy search types',
                    trailing: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          '${settings.heuristicWeight.toStringAsFixed(1)}x',
                          style: const TextStyle(
                            color: AppTheme.accent,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(width: 8),
                        SizedBox(
                          width: 100,
                          child: Slider(
                            value: settings.heuristicWeight,
                            min: 0.5,
                            max: 3.0,
                            onChanged: notifier.updateHeuristicWeight,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 12),
                  _buildSectionHeader('HAPTICS & FEEDBACK'),
                  _buildSettingTile(
                    title: 'Collision Vibration',
                    subtitle: 'Tactile pulses when hitting walls/dead-ends',
                    trailing: Switch(
                      value: settings.collisionVibration,
                      onChanged: notifier.toggleCollisionVibration,
                    ),
                  ),
                  _buildSettingTile(
                    title: 'Execution Pulse',
                    subtitle: 'Ambient vibration during active solving',
                    trailing: Switch(
                      value: settings.executionPulse,
                      onChanged: notifier.toggleExecutionPulse,
                    ),
                  ),
                  const SizedBox(height: 12),
                  _buildSectionHeader('DATA MANAGEMENT'),
                  _buildSettingTile(
                    title: 'Delete Everything',
                    subtitle: 'Wipe all runs, statistics, and history',
                    trailing: IconButton(
                      icon: const Icon(
                        Icons.delete_forever_rounded,
                        color: AppTheme.error,
                      ),
                      onPressed: () => _confirmDeleteEverything(context, ref),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
      bottomNavigationBar: const ArenaBottomNavBar(currentIndex: 4),
    );
  }

  Widget _buildSliverAppBar(BuildContext context, SettingsNotifier notifier) {
    return SliverAppBar(
      expandedHeight: 140.0,
      backgroundColor: AppTheme.background,
      pinned: true,
      actions: [
        TextButton.icon(
          onPressed: () => notifier.resetToDefaults(),
          icon: const Icon(Icons.restore_rounded, size: 18),
          label: const Text('RESET'),
          style: TextButton.styleFrom(foregroundColor: AppTheme.textMuted),
        ),
      ],
      flexibleSpace: FlexibleSpaceBar(
        centerTitle: false,
        titlePadding: const EdgeInsetsDirectional.only(start: 72, bottom: 16),
        title: const Text(
          'SETTINGS',
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.w800,
            fontFamily: 'SpaceGrotesk',
            color: AppTheme.accentLight,
            letterSpacing: 2,
          ),
        ),
        background: IgnorePointer(
          child: Stack(
            children: [
              Positioned(
                right: -20,
                top: -20,
                child: Icon(
                  Icons.settings_rounded,
                  size: 180,
                  color: AppTheme.accent.withValues(alpha: 0.05),
                ),
              ),
              Positioned(
                left: -40,
                bottom: -20,
                child: Icon(
                  Icons.tune_rounded,
                  size: 200,
                  color: AppTheme.accent.withValues(alpha: 0.03),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSectionHeader(String title) {
    return Padding(
      padding: const EdgeInsets.only(top: 16, bottom: 12),
      child: Text(
        title,
        style: const TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.w700,
          color: AppTheme.textMuted,
          letterSpacing: 1.5,
        ),
      ),
    );
  }

  Widget _buildSettingTile({
    required String title,
    required String subtitle,
    required Widget trailing,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: AppTheme.glassCard(radius: 14),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  subtitle,
                  style: const TextStyle(
                    fontSize: 12,
                    color: AppTheme.textSecondary,
                  ),
                ),
              ],
            ),
          ),
          trailing,
        ],
      ),
    );
  }

  void _confirmDeleteEverything(BuildContext context, WidgetRef ref) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: AppTheme.surfaceHigh,
        title: const Text('Delete All Data?'),
        content: const Text(
          'This will permanently delete all algorithm runs, battle statistics, and execution history from the server and this device.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('CANCEL'),
          ),
          TextButton(
            onPressed: () async {
              try {
                // 1. Reset local stats
                await ref.read(arenaStatsProvider.notifier).resetStats();
                
                // 2. Delete backend data
                await ref.read(apiServiceProvider).deleteAllRuns();
                
                // 3. Invalidate runs provider
                ref.invalidate(runsProvider);
                
                if (context.mounted) {
                  Navigator.pop(context);
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('All history and statistics wiped')),
                  );
                }
              } catch (e) {
                if (context.mounted) {
                  Navigator.pop(context);
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('Error: $e'),
                      backgroundColor: AppTheme.error,
                    ),
                  );
                }
              }
            },
            child: const Text('DELETE ALL', style: TextStyle(color: AppTheme.error)),
          ),
        ],
      ),
    );
  }
}
