import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:algo_arena/core/app_theme.dart';

/// Glassmorphism bottom navigation bar — Neural Arena design.
class ArenaBottomNavBar extends StatelessWidget {
  const ArenaBottomNavBar({super.key, required this.currentIndex});
  final int currentIndex;

  static const _items = [
    (icon: Icons.home_rounded, label: 'Home', route: '/home'),
    (icon: Icons.sports_kabaddi_rounded, label: 'Battle', route: '/battle'),
    (icon: Icons.history_rounded, label: 'History', route: '/history'),
    (icon: Icons.leaderboard_rounded, label: 'Analytics', route: '/analytics'),
    (icon: Icons.settings_rounded, label: 'Settings', route: '/settings'),
  ];

  @override
  Widget build(BuildContext context) {
    return RepaintBoundary(
      child: Container(
        constraints: BoxConstraints(minHeight: 64.0, maxHeight: 120.0),
        decoration: BoxDecoration(
          color: AppTheme.surfaceVariant.withValues(alpha: 0.96),
          border: Border(
            top: BorderSide(color: Colors.white.withValues(alpha: 0.12)),
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.4),
              blurRadius: 20,
              offset: const Offset(0, -4),
            ),
          ],
        ),
        child: SafeArea(
          top: false,
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: List.generate(_items.length, (i) {
              final item = _items[i];
              final isActive = i == currentIndex;
              return _NavItem(
                icon: item.icon,
                label: item.label,
                isActive: isActive,
                onTap: () {
                  if (!isActive) {
                    Navigator.pushNamed(context, item.route);
                  }
                },
              );
            }),
          ),
        ),
      ),
    );
  }
}

class _NavItem extends StatelessWidget {
  const _NavItem({
    required this.icon,
    required this.label,
    required this.isActive,
    required this.onTap,
  });
  final IconData icon;
  final String label;
  final bool isActive;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 250),
        curve: Curves.easeOut,
        padding: EdgeInsets.symmetric(horizontal: 20.0, vertical: 8.0),
        decoration: BoxDecoration(
          color: isActive
              ? AppTheme.accent.withValues(alpha: 0.25)
              : Colors.transparent,
          borderRadius: BorderRadius.circular(12.0),
          border: Border.all(
            color: isActive
                ? AppTheme.accent.withValues(alpha: 0.5)
                : Colors.transparent,
          ),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              icon,
              size: 24.0,
              color: isActive ? AppTheme.accent : AppTheme.textMuted,
            ),
            const SizedBox(height: 4.0),
            Stack(
              clipBehavior: Clip.none,
              children: [
                FittedBox(
                  fit: BoxFit.scaleDown,
                  child: Text(
                    label,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: Theme.of(context).textTheme.labelSmall?.copyWith(
                      color: isActive
                          ? AppTheme.accentLight
                          : AppTheme.textMuted,
                      fontSize: math.min(10.0, 14.0),
                      letterSpacing: 0.5,
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
