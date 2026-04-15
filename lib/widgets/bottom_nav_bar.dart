import 'dart:ui';
import 'package:flutter/material.dart';
import '../core/app_theme.dart';

/// Glassmorphism bottom navigation bar — Neural Arena design.
class ArenaBottomNavBar extends StatelessWidget {
  const ArenaBottomNavBar({super.key, required this.currentIndex});
  final int currentIndex;

  static const _items = [
    (icon: Icons.home_rounded, label: 'Home', route: '/home'),
    (icon: Icons.sports_kabaddi_rounded, label: 'Battle', route: '/battle'),
    (icon: Icons.leaderboard_rounded, label: 'Ranks', route: '/home'),
    (icon: Icons.settings_rounded, label: 'Settings', route: '/home'),
  ];

  @override
  Widget build(BuildContext context) {
    return ClipRect(
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 24, sigmaY: 24),
        child: Container(
          height: 70 + MediaQuery.of(context).padding.bottom,
          decoration: BoxDecoration(
            color: AppTheme.surfaceVariant.withValues(alpha: 0.85),
            border: Border(
              top: BorderSide(color: Colors.white.withValues(alpha: 0.08)),
            ),
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
                      Navigator.pushNamed(
                          context, item.route);
                    }
                  },
                );
              }),
            ),
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
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
        decoration: BoxDecoration(
          color: isActive
              ? AppTheme.accent.withValues(alpha: 0.15)
              : Colors.transparent,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isActive
                ? AppTheme.accent.withValues(alpha: 0.35)
                : Colors.transparent,
          ),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              icon,
              size: 22,
              color: isActive ? AppTheme.accent : AppTheme.textMuted,
            ),
            const SizedBox(height: 4),
            Text(
              label,
              style: Theme.of(context).textTheme.labelSmall?.copyWith(
                    color: isActive ? AppTheme.accentLight : AppTheme.textMuted,
                    letterSpacing: 0.5,
                  ),
            ),
          ],
        ),
      ),
    );
  }
}
