import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:ai_algo_app/core/app_theme.dart';
import 'package:ai_algo_app/widgets/bottom_nav_bar.dart';
import 'package:ai_algo_app/state/settings_provider.dart';
import 'package:ai_algo_app/services/stats_service.dart';

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
                         Text('${settings.heuristicWeight.toStringAsFixed(1)}x', 
                          style: const TextStyle(color: AppTheme.accent, fontWeight: FontWeight.bold)
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
                    title: 'Clear Battle History',
                    subtitle: 'Reset all comparison winners and records',
                    trailing: IconButton(
                      icon: const Icon(Icons.delete_outline_rounded, color: AppTheme.error),
                      onPressed: () => _confirmResetStats(context, ref),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
      bottomNavigationBar: const ArenaBottomNavBar(currentIndex: 3),
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
        titlePadding: const EdgeInsets.only(left: 20, bottom: 16),
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

  void _confirmResetStats(BuildContext context, WidgetRef ref) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: AppTheme.surfaceHigh,
        title: const Text('Clear History?'),
        content: const Text('This will permanently delete all battle statistics and records.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('CANCEL'),
          ),
          TextButton(
            onPressed: () {
              ref.read(arenaStatsProvider.notifier).resetStats();
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Statistics cleared')),
              );
            },
            child: const Text('CLEAR', style: TextStyle(color: AppTheme.error)),
          ),
        ],
      ),
    );
  }
}
