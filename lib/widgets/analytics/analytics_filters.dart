import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:algo_arena/core/app_theme.dart';
import 'package:algo_arena/state/analytics_provider.dart';

class AnalyticsFiltersBar extends ConsumerWidget {
  const AnalyticsFiltersBar({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final filters = ref.watch(analyticsFiltersProvider);

    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      physics: const BouncingScrollPhysics(),
      child: Row(
        children: [
          _FilterDropdown(
            label: "Algorithm",
            value: filters.algorithm ?? "All",
            items: const ["All", "BFS", "DFS", "A*", "Dijkstra", "Greedy"],
            onChanged: (val) {
              ref.read(analyticsFiltersProvider.notifier).state = 
                filters.copyWith(algorithm: val);
            },
          ),
          const SizedBox(width: 12),
          _FilterDropdown(
            label: "Metric",
            value: filters.metric ?? "nodes",
            items: const ["nodes", "time"],
            onChanged: (val) {
              ref.read(analyticsFiltersProvider.notifier).state = 
                filters.copyWith(metric: val);
            },
          ),
          const SizedBox(width: 12),
          // ─── Date Range Picker ───────────────────────────────────────────────
          GestureDetector(
            onTap: () async {
              final DateTimeRange? picked = await showDateRangePicker(
                context: context,
                firstDate: DateTime(2023),
                lastDate: DateTime.now(),
                initialDateRange: filters.startDate != null && filters.endDate != null
                    ? DateTimeRange(
                        start: DateTime.parse(filters.startDate!),
                        end: DateTime.parse(filters.endDate!),
                      )
                    : null,
                builder: (context, child) {
                  return Theme(
                    data: Theme.of(context).copyWith(
                      colorScheme: const ColorScheme.dark(
                        primary: AppTheme.accent,
                        onPrimary: Colors.white,
                        surface: AppTheme.surfaceHigh,
                        onSurface: Colors.white,
                        secondary: AppTheme.accent,
                      ),
                      dialogBackgroundColor: AppTheme.background,
                      textButtonTheme: TextButtonThemeData(
                        style: TextButton.styleFrom(foregroundColor: AppTheme.accentLight),
                      ),
                    ),
                    child: child!,
                  );
                },
              );

              if (picked != null) {
                ref.read(analyticsFiltersProvider.notifier).state = filters.copyWith(
                  startDate: picked.start.toIso8601String(),
                  endDate: picked.end.toIso8601String(),
                );
              }
            },
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              decoration: BoxDecoration(
                color: (filters.startDate != null) 
                    ? AppTheme.accent.withValues(alpha: 0.15) 
                    : AppTheme.surfaceVariant.withValues(alpha: 0.3),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(
                  color: (filters.startDate != null) 
                      ? AppTheme.accent.withValues(alpha: 0.3) 
                      : Colors.white.withValues(alpha: 0.08)
                ),
              ),
              child: Row(
                children: [
                  Icon(
                    Icons.calendar_today_rounded, 
                    size: 14, 
                    color: (filters.startDate != null) ? AppTheme.accentLight : AppTheme.textMuted
                  ),
                  const SizedBox(width: 8),
                  Text(
                    (filters.startDate != null && filters.endDate != null)
                        ? "${_formatDate(filters.startDate!)} - ${_formatDate(filters.endDate!)}"
                        : "Date Range",
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: (filters.startDate != null) ? Colors.white : AppTheme.textMuted,
                      fontWeight: (filters.startDate != null) ? FontWeight.bold : FontWeight.normal,
                    ),
                  ),
                  if (filters.startDate != null) ...[
                    const SizedBox(width: 8),
                    GestureDetector(
                      onTap: () {
                        ref.read(analyticsFiltersProvider.notifier).state = filters.copyWith(
                          startDate: null,
                          endDate: null,
                        );
                      },
                      child: const Icon(Icons.close_rounded, size: 14, color: Colors.white70),
                    ),
                  ],
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _FilterDropdown extends StatelessWidget {
  final String label;
  final String value;
  final List<String> items;
  final Function(String) onChanged;

  const _FilterDropdown({
    required this.label,
    required this.value,
    required this.items,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
      decoration: BoxDecoration(
        color: AppTheme.surfaceVariant.withValues(alpha: 0.3),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: Colors.white.withValues(alpha: 0.08)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            "$label: ",
            style: Theme.of(context).textTheme.bodySmall?.copyWith(color: AppTheme.textMuted),
          ),
          DropdownButton<String>(
            value: value,
            underline: const SizedBox(),
            icon: const Icon(Icons.keyboard_arrow_down_rounded, size: 14, color: AppTheme.accent),
            dropdownColor: AppTheme.surfaceHigh,
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: AppTheme.accentLight,
                  fontWeight: FontWeight.bold,
                ),
            items: items.map((String item) {
              return DropdownMenuItem<String>(
                value: item,
                child: Text(item),
              );
            }).toList(),
            onChanged: (val) {
              if (val != null) onChanged(val);
            },
          ),
        ],
      ),
    );
  }
}

String _formatDate(String isoDate) {
  try {
    final date = DateTime.parse(isoDate);
    return DateFormat('MMM dd').format(date);
  } catch (e) {
    return 'Invalid Date';
  }
}
