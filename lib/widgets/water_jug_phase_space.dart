import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:algo_arena/core/app_theme.dart';
import 'package:algo_arena/core/water_jug_problem.dart';

/// A painter that visualizes the state space of the Water Jug problem.
/// X-axis: Jug A amount
/// Y-axis: Jug B amount
class PhaseSpacePainter extends CustomPainter {
  final int capacityA;
  final int capacityB;
  final Set<WaterJugState> exploredStates;
  final List<WaterJugState> currentPath;
  final WaterJugState? currentState;
  final int target;
  final bool isExpanded;

  PhaseSpacePainter({
    required this.capacityA,
    required this.capacityB,
    required this.exploredStates,
    required this.currentPath,
    required this.target,
    this.currentState,
    this.isExpanded = false,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final double padding = 20.0;
    final double graphWidth = size.width - (padding * 2);
    final double graphHeight = size.height - (padding * 2);
    final double stepX = graphWidth / capacityA;
    final double stepY = graphHeight / capacityB;

    final Offset origin = Offset(padding, size.height - padding);

    // 1. Draw Grid Lines
    final gridPaint = Paint()
      ..color = Colors.white.withValues(alpha: 0.05)
      ..strokeWidth = 1.0;

    for (int i = 0; i <= capacityA; i++) {
      double x = origin.dx + (i * stepX);
      canvas.drawLine(Offset(x, origin.dy), Offset(x, origin.dy - graphHeight), gridPaint);
    }
    for (int i = 0; i <= capacityB; i++) {
      double y = origin.dy - (i * stepY);
      canvas.drawLine(Offset(origin.dx, y), Offset(origin.dx + graphWidth, y), gridPaint);
    }

    // 2. Draw Target Line (Any state where A or B == target)
    final targetPaint = Paint()
      ..color = AppTheme.warning.withValues(alpha: 0.2)
      ..strokeWidth = 2.0
      ..style = PaintingStyle.stroke;
    
    // Draw horizontal and vertical target lines
    if (target <= capacityA) {
      double x = origin.dx + (target * stepX);
      canvas.drawLine(Offset(x, origin.dy), Offset(x, origin.dy - graphHeight), targetPaint);
    }
    if (target <= capacityB) {
      double y = origin.dy - (target * stepY);
      canvas.drawLine(Offset(origin.dx, y), Offset(origin.dx + graphWidth, y), targetPaint);
    }

    // 3. Draw Explored Nodes
    if (exploredStates.isNotEmpty) {
      final exploredPaint = Paint()
        ..color = Colors.white.withValues(alpha: 0.2)
        ..strokeWidth = 3.0
        ..strokeCap = StrokeCap.round;

      final points = exploredStates.map((state) => _stateToOffset(state, origin, stepX, stepY)).toList();
      canvas.drawPoints(ui.PointMode.points, points, exploredPaint);
    }

    // 4. Draw Path
    if (currentPath.length > 1) {
      final pathPaint = Paint()
        ..color = AppTheme.accent
        ..strokeWidth = 2.0
        ..style = PaintingStyle.stroke
        ..strokeCap = StrokeCap.round;

      final path = Path();
      path.moveTo(origin.dx, origin.dy); // Start at (0,0)

      for (int i = 0; i < currentPath.length; i++) {
        final pos = _stateToOffset(currentPath[i], origin, stepX, stepY);
        path.lineTo(pos.dx, pos.dy);
      }
      canvas.drawPath(path, pathPaint);
    }

    // 5. Draw Current State Glow
    if (currentState != null) {
      final pos = _stateToOffset(currentState!, origin, stepX, stepY);
      
      final glowPaint = Paint()
        ..color = AppTheme.accent.withValues(alpha: 0.3)
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 8);
      canvas.drawCircle(pos, 10, glowPaint);

      final headPaint = Paint()..color = Colors.white;
      canvas.drawCircle(pos, 5, headPaint);
    }

    // 6. Draw Axes Labels
    final textPainter = TextPainter(textDirection: TextDirection.ltr);
    
    _drawText(canvas, textPainter, 'A', Offset(size.width - 15, size.height - 15));
    _drawText(canvas, textPainter, 'B', Offset(5, 5));
  }

  Offset _stateToOffset(WaterJugState state, Offset origin, double stepX, double stepY) {
    return Offset(
      origin.dx + (state.jugA * stepX),
      origin.dy - (state.jugB * stepY),
    );
  }

  void _drawText(Canvas canvas, TextPainter tp, String text, Offset pos) {
    tp.text = TextSpan(
      text: text,
      style: const TextStyle(color: AppTheme.textMuted, fontSize: 10, fontWeight: FontWeight.bold),
    );
    tp.layout();
    tp.paint(canvas, pos);
  }

  @override
  bool shouldRepaint(covariant PhaseSpacePainter oldDelegate) {
    return oldDelegate.currentState != currentState ||
           oldDelegate.exploredStates.length != exploredStates.length ||
           oldDelegate.currentPath.length != currentPath.length;
  }
}
