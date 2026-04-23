import 'package:flutter/material.dart';

import 'package:algo_arena/models/grid_node.dart';
import 'package:algo_arena/state/grid_controller.dart';

class ControlPanel extends StatelessWidget {
  const ControlPanel({super.key, required this.controller});

  final GridController controller;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: EdgeInsets.all(20.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Control Panel',
              style: Theme.of(
                context,
              ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w700),
            ),
            const SizedBox(height: 10),
            Text(
              'Phase 1 focuses on the interaction layer. Paint walls, move the anchors, and resize the board.',
              style: Theme.of(
                context,
              ).textTheme.bodyMedium?.copyWith(color: Colors.white70),
            ),
            const SizedBox(height: 22),
            Wrap(
              spacing: 10,
              runSpacing: 10,
              children: PaintTool.values
                  .map(
                    (tool) => ChoiceChip(
                      label: Text(_toolLabel(tool)),
                      selected: controller.selectedTool == tool,
                      onSelected: (_) => controller.setTool(tool),
                    ),
                  )
                  .toList(),
            ),
            const SizedBox(height: 22),
            _SliderBlock(
              label: 'Rows',
              value: controller.rows.toDouble(),
              min: 10,
              max: 30,
              onChanged: (value) =>
                  controller.updateDimensions(rows: value.round()),
            ),
            const SizedBox(height: 12),
            _SliderBlock(
              label: 'Columns',
              value: controller.columns.toDouble(),
              min: 12,
              max: 40,
              onChanged: (value) =>
                  controller.updateDimensions(columns: value.round()),
            ),
            const SizedBox(height: 22),
            Wrap(
              spacing: 12,
              runSpacing: 12,
              children: [
                FilledButton.icon(
                  onPressed: controller.clearWalls,
                  icon: const Icon(Icons.layers_clear_rounded),
                  label: const Text('Clear Walls'),
                ),
                OutlinedButton.icon(
                  onPressed: controller.resetGrid,
                  icon: const Icon(Icons.refresh_rounded),
                  label: const Text('Reset Grid'),
                ),
              ],
            ),
            const SizedBox(height: 22),
            Wrap(
              spacing: 16,
              runSpacing: 12,
              children: const [
                _LegendChip(color: Color(0xFF14B8A6), label: 'Start'),
                _LegendChip(color: Color(0xFFF59E0B), label: 'Goal'),
                _LegendChip(color: Color(0xFFEF4444), label: 'Wall'),
              ],
            ),
          ],
        ),
      ),
    );
  }

  String _toolLabel(PaintTool tool) {
    return switch (tool) {
      PaintTool.wall => 'Draw Walls',
      PaintTool.erase => 'Erase',
      PaintTool.start => 'Move Start',
      PaintTool.goal => 'Move Goal',
      PaintTool.weight => 'Paint Terrain',
    };
  }
}

class _SliderBlock extends StatelessWidget {
  const _SliderBlock({
    required this.label,
    required this.value,
    required this.min,
    required this.max,
    required this.onChanged,
  });

  final String label;
  final double value;
  final double min;
  final double max;
  final ValueChanged<double> onChanged;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          '$label ${value.round()}',
          style: Theme.of(context).textTheme.titleMedium,
        ),
        Slider(
          value: value,
          min: min,
          max: max,
          divisions: (max - min).round(),
          onChanged: onChanged,
        ),
      ],
    );
  }
}

class _LegendChip extends StatelessWidget {
  const _LegendChip({required this.color, required this.label});

  final Color color;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 12.0, vertical: 10.0),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.04),
        borderRadius: BorderRadius.circular(16.0),
        border: Border.all(color: Colors.white.withValues(alpha: 0.08)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 12.0,
            height: 12.0,
            decoration: BoxDecoration(
              color: color,
              borderRadius: BorderRadius.circular(99.0),
            ),
          ),
          const SizedBox(width: 8),
          Text(label),
        ],
      ),
    );
  }
}
