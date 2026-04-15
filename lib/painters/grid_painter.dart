import 'package:flutter/material.dart';

import '../models/grid_node.dart';

class GridPainter extends CustomPainter {
  GridPainter({required this.grid, required this.cellSize});

  final List<List<GridNode>> grid;
  final double cellSize;

  @override
  void paint(Canvas canvas, Size size) {
    final cellPaint = Paint()..style = PaintingStyle.fill;
    final linePaint = Paint()
      ..style = PaintingStyle.stroke
      ..color = const Color(0xFF17314A)
      ..strokeWidth = 1;

    for (final row in grid) {
      for (final node in row) {
        final rect = Rect.fromLTWH(
          node.column * cellSize,
          node.row * cellSize,
          cellSize,
          cellSize,
        );

        cellPaint.color = _fillColor(node.type);
        canvas.drawRRect(
          RRect.fromRectAndRadius(rect.deflate(0.8), const Radius.circular(4)),
          cellPaint,
        );

        if (node.type == NodeType.start || node.type == NodeType.goal) {
          final markerPaint = Paint()
            ..style = PaintingStyle.fill
            ..color = Colors.white.withOpacity(0.92);
          canvas.drawCircle(rect.center, cellSize * 0.18, markerPaint);
        }
      }
    }

    for (var row = 0; row <= grid.length; row++) {
      final dy = row * cellSize;
      canvas.drawLine(Offset(0, dy), Offset(size.width, dy), linePaint);
    }

    for (var column = 0; column <= grid.first.length; column++) {
      final dx = column * cellSize;
      canvas.drawLine(Offset(dx, 0), Offset(dx, size.height), linePaint);
    }
  }

  Color _fillColor(NodeType type) {
    return switch (type) {
      NodeType.empty => const Color(0xFF0A1A28),
      NodeType.wall => const Color(0xFFEF4444),
      NodeType.start => const Color(0xFF14B8A6),
      NodeType.goal => const Color(0xFFF59E0B),
    };
  }

  @override
  bool shouldRepaint(covariant GridPainter oldDelegate) {
    return oldDelegate.grid != grid || oldDelegate.cellSize != cellSize;
  }
}
