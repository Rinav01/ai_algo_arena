import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:algo_arena/core/app_theme.dart';
import 'package:algo_arena/models/algo_info.dart';

class ConceptVisualizer extends StatefulWidget {
  final ConceptType type;
  final double size;

  const ConceptVisualizer({super.key, required this.type, this.size = 120});

  @override
  State<ConceptVisualizer> createState() => _ConceptVisualizerState();
}

class _ConceptVisualizerState extends State<ConceptVisualizer>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 4),
    )..repeat();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return RepaintBoundary(
      child: Container(
        width: widget.size,
        height: widget.size,
        decoration: BoxDecoration(
          color: Colors.black.withValues(alpha: 0.2),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: Colors.white.withValues(alpha: 0.05)),
        ),
        child: CustomPaint(
          painter: _EnhancedConceptPainter(
            type: widget.type,
            animation: _controller,
          ),
        ),
      ),
    );
  }
}

class _EnhancedConceptPainter extends CustomPainter {
  final ConceptType type;
  final Animation<double> animation;

  _EnhancedConceptPainter({required this.type, required this.animation})
    : super(repaint: animation);

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);

    switch (type) {
      case ConceptType.expandingRipple:
        _drawDijkstra(canvas, size, center);
        break;
      case ConceptType.wavefrontGrid:
        _drawBFS(canvas, size, center);
        break;
      case ConceptType.snakingLine:
        _drawDFS(canvas, size, center);
        break;
      case ConceptType.greedyProbe:
        _drawGreedy(canvas, size, center);
        break;
      case ConceptType.focusedTarget:
        _drawAStar(canvas, size, center);
        break;
      case ConceptType.backtrackingMini:
        _drawNQueens(canvas, size, center);
        break;
      case ConceptType.nQueensMRV:
        _drawNQueensMRV(canvas, size, center);
        break;
      case ConceptType.nQueensFC:
        _drawNQueensFC(canvas, size, center);
        break;
      case ConceptType.puzzleBFS:
        _drawPuzzleBFS(canvas, size, center);
        break;
      case ConceptType.puzzleAStar:
        _drawPuzzleAStar(canvas, size, center);
        break;
      case ConceptType.puzzleGreedy:
        _drawPuzzleGreedy(canvas, size, center);
        break;
      case ConceptType.battleConcept:
        _drawBattle(canvas, size, center);
        break;
    }
  }

  void _drawBFS(Canvas canvas, Size size, Offset center) {
    final paint = Paint()..style = PaintingStyle.fill;
    final dotSpacing = size.width / 8;
    final t = animation.value * 12; // Time scale

    // Draw a 7x7 grid of dots
    for (int i = 0; i < 7; i++) {
      for (int j = 0; j < 7; j++) {
        double x = (i + 1) * dotSpacing;
        double y = (j + 1) * dotSpacing;
        Offset pos = Offset(x, y);

        // Manhattan distance from center [3,3]
        int distance = (i - 3).abs() + (j - 3).abs();

        double delay = distance * 1.2;
        double intensity = (t - delay).clamp(0, 2);
        if (intensity > 1.0) intensity = 2.0 - intensity; // Fade out
        intensity = intensity.clamp(0, 1);

        paint.color = intensity > 0
            ? AppTheme.accent.withValues(alpha: intensity * 0.8)
            : Colors.white.withValues(alpha: 0.1);

        canvas.drawCircle(pos, 2 + intensity * 2, paint);

        // Draw connections to neighbors
        if (intensity > 0.3) {
          final linePaint = Paint()
            ..color = paint.color.withValues(alpha: intensity * 0.2)
            ..strokeWidth = 1;
          if (i < 6) {
            canvas.drawLine(pos, Offset(x + dotSpacing, y), linePaint);
          }
          if (j < 6) {
            canvas.drawLine(pos, Offset(x, y + dotSpacing), linePaint);
          }
        }
      }
    }
  }

  void _drawDijkstra(Canvas canvas, Size size, Offset center) {
    final paint = Paint()..style = PaintingStyle.stroke;
    final maxRadius = size.width * 0.45;

    for (int i = 0; i < 3; i++) {
      double progress = (animation.value + (i * 0.33)) % 1.0;
      double radius = progress * maxRadius;

      // Non-uniform expansion (wobbly circle)
      final path = Path();
      for (double angle = 0; angle < 2 * math.pi; angle += 0.2) {
        double noise = math.sin(angle * 4 + animation.value * 10) * 3;
        double r = radius + noise;
        double dx = center.dx + math.cos(angle) * r;
        double dy = center.dy + math.sin(angle) * r;
        if (angle == 0) {
          path.moveTo(dx, dy);
        } else {
          path.lineTo(dx, dy);
        }
      }
      path.close();

      paint
        ..color = AppTheme.accent.withValues(alpha: (1.0 - progress) * 0.5)
        ..strokeWidth = 2;
      canvas.drawPath(path, paint);
    }
  }

  void _drawDFS(Canvas canvas, Size size, Offset center) {
    final paint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.0
      ..strokeCap = StrokeCap.round
      ..color = AppTheme.accent;

    final path = Path();
    List<Offset> points = [
      Offset(size.width * 0.2, size.height * 0.2),
      Offset(size.width * 0.2, size.height * 0.5),
      Offset(size.width * 0.5, size.height * 0.5),
      Offset(size.width * 0.5, size.height * 0.8),
      Offset(size.width * 0.8, size.height * 0.8),
      Offset(size.width * 0.8, size.height * 0.3),
      Offset(size.width * 0.6, size.height * 0.3),
    ];

    double t = animation.value;
    int visiblePoints;
    double partial;

    if (t < 0.6) {
      double searchT = t / 0.6;
      visiblePoints = (searchT * (points.length - 1)).floor();
      partial = (searchT * (points.length - 1)) % 1.0;
    } else {
      visiblePoints = points.length - 1;
      partial = 1.0 - (t - 0.6) / 0.4; // Backtrack
    }

    path.moveTo(points[0].dx, points[0].dy);
    for (int i = 0; i < visiblePoints; i++) {
      path.lineTo(points[i + 1].dx, points[i + 1].dy);
    }

    if (t < 0.6 && visiblePoints < points.length - 1) {
      Offset p1 = points[visiblePoints];
      Offset p2 = points[visiblePoints + 1];
      path.lineTo(
        p1.dx + (p2.dx - p1.dx) * partial,
        p1.dy + (p2.dy - p1.dy) * partial,
      );
    }

    canvas.drawPath(path, paint);

    // Draw current head
    paint.style = PaintingStyle.fill;
    canvas.drawCircle(
      points[visiblePoints],
      4,
      paint..color = AppTheme.accentLight,
    );
  }

  void _drawGreedy(Canvas canvas, Size size, Offset center) {
    final target = Offset(size.width * 0.8, size.height * 0.2);
    final start = Offset(size.width * 0.2, size.height * 0.8);
    final paint = Paint();

    // Greedy is "short-sighted" and moves directly.
    double t = animation.value;

    // Obstacle simulator
    final obstacle = Rect.fromCenter(center: center, width: 30, height: 10);
    paint
      ..color = Colors.white.withValues(alpha: 0.1)
      ..style = PaintingStyle.fill;
    canvas.drawRect(obstacle, paint);

    // Particle charging toward target
    Offset pos;
    if (t < 0.4) {
      // Charge straight
      pos = Offset.lerp(start, center, t / 0.4)!;
    } else if (t < 0.7) {
      // Hit obstacle and jitter
      double jitter = math.sin(t * 100) * 2;
      pos = Offset(center.dx + jitter, center.dy + jitter);
    } else {
      // Find way and dash
      pos = Offset.lerp(center + const Offset(20, 0), target, (t - 0.7) / 0.3)!;
    }

    paint
      ..color = AppTheme.accentLight
      ..style = PaintingStyle.fill;
    canvas.drawCircle(pos, 5, paint);

    // "Sight" line
    paint
      ..color = AppTheme.accent.withValues(alpha: 0.3)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1;
    canvas.drawLine(pos, target, paint);
  }

  void _drawAStar(Canvas canvas, Size size, Offset center) {
    final target = Offset(size.width * 0.8, size.height * 0.2);
    final start = Offset(size.width * 0.2, size.height * 0.8);

    final pathPaint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 3.0
      ..strokeCap = StrokeCap.round
      ..color = AppTheme.success;

    final path = Path()..moveTo(start.dx, start.dy);
    double t = (animation.value * 1.5).clamp(0.0, 1.0);

    Offset control = Offset(size.width * 0.7, size.height * 0.7);

    for (double i = 0; i <= t; i += 0.05) {
      double it = i;
      double x =
          math.pow(1 - it, 2) * start.dx +
          2 * (1 - it) * it * control.dx +
          math.pow(it, 2) * target.dx;
      double y =
          math.pow(1 - it, 2) * start.dy +
          2 * (1 - it) * it * control.dy +
          math.pow(it, 2) * target.dy;
      path.lineTo(x, y);
    }

    canvas.drawPath(path, pathPaint);

    // Pulse rings at start (Dijkstra influence)
    double r = (animation.value * 30) % 30;
    canvas.drawCircle(
      start,
      r,
      Paint()
        ..style = PaintingStyle.stroke
        ..color = AppTheme.success.withValues(alpha: (1 - r / 30) * 0.3),
    );

    canvas.drawCircle(target, 5, Paint()..color = AppTheme.error); // Target
  }

  void _drawNQueens(Canvas canvas, Size size, Offset center) {
    final cellSize = size.width / 4;
    final gridPaint = Paint()
      ..style = PaintingStyle.stroke
      ..color = Colors.white.withValues(alpha: 0.1);

    for (int i = 0; i <= 4; i++) {
      canvas.drawLine(
        Offset(i * cellSize, 0),
        Offset(i * cellSize, size.height),
        gridPaint,
      );
      canvas.drawLine(
        Offset(0, i * cellSize),
        Offset(size.width, i * cellSize),
        gridPaint,
      );
    }

    double t = animation.value;
    int step = (t * 6).floor() % 6;
    List<List<Offset>> frames = [
      [const Offset(0, 0)],
      [const Offset(0, 0), const Offset(1, 1)], // Conflict
      [const Offset(0, 0)], // Backtrack
      [const Offset(0, 0), const Offset(1, 2)],
      [const Offset(0, 0), const Offset(1, 2), const Offset(2, 0)], // Conflict
      [const Offset(0, 0), const Offset(1, 2)],
    ];

    final queenPaint = Paint()..style = PaintingStyle.fill;
    final conflictPaint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2
      ..color = AppTheme.error;

    for (var pos in frames[step]) {
      Offset drawPos = Offset(
        pos.dx * cellSize + cellSize / 2,
        pos.dy * cellSize + cellSize / 2,
      );
      queenPaint.color = AppTheme.success;
      canvas.drawCircle(drawPos, cellSize * 0.3, queenPaint);
    }

    if (step == 1 || step == 4) {
      int lastIdx = frames[step].length - 1;
      Offset p1 = Offset(
        frames[step][lastIdx - 1].dx * cellSize + cellSize / 2,
        frames[step][lastIdx - 1].dy * cellSize + cellSize / 2,
      );
      Offset p2 = Offset(
        frames[step][lastIdx].dx * cellSize + cellSize / 2,
        frames[step][lastIdx].dy * cellSize + cellSize / 2,
      );
      canvas.drawLine(p1, p2, conflictPaint);
    }
  }

  void _drawNQueensMRV(Canvas canvas, Size size, Offset center) {
    // Non-linear row jumping based on MRV heuristic
    final cellSize = size.width / 4;
    final t = animation.value;
    int step = (t * 4).floor() % 4;

    final gridPaint = Paint()
      ..style = PaintingStyle.stroke
      ..color = Colors.white.withValues(alpha: 0.1);
    for (int i = 0; i <= 4; i++) {
      canvas.drawLine(
        Offset(i * cellSize, 0),
        Offset(i * cellSize, size.height),
        gridPaint,
      );
      canvas.drawLine(
        Offset(0, i * cellSize),
        Offset(size.width, i * cellSize),
        gridPaint,
      );
    }

    // Sequence of placements showing Jumping rows (not 0,1,2,3)
    final order = [
      const Offset(2, 0),
      const Offset(0, 1),
      const Offset(3, 2),
      const Offset(1, 3),
    ];
    final queenPaint = Paint()..color = AppTheme.accent;

    for (int i = 0; i <= step; i++) {
      Offset pos = order[i];
      Offset drawPos = Offset(
        pos.dx * cellSize + cellSize / 2,
        pos.dy * cellSize + cellSize / 2,
      );
      canvas.drawCircle(drawPos, cellSize * 0.3, queenPaint);
    }
  }

  void _drawNQueensFC(Canvas canvas, Size size, Offset center) {
    // Heatmap showing constraint propagation
    final cellSize = size.width / 4;
    final t = animation.value;

    final paint = Paint()..style = PaintingStyle.fill;

    // Draw queen at (1,0)
    canvas.drawCircle(
      Offset(1 * cellSize + cellSize / 2, 0 * cellSize + cellSize / 2),
      cellSize * 0.3,
      paint..color = AppTheme.success,
    );

    // Fade out blocked cells (column 1, diagonals)
    double intensity = (math.sin(t * math.pi * 2) * 0.5 + 0.5) * 0.4;
    paint.color = AppTheme.error.withValues(alpha: intensity);

    // Column 1
    for (int r = 1; r < 4; r++) {
      canvas.drawRect(
        Rect.fromLTWH(
          1 * cellSize + 2,
          r * cellSize + 2,
          cellSize - 4,
          cellSize - 4,
        ),
        paint,
      );
    }
    // Diagonals
    canvas.drawRect(
      Rect.fromLTWH(
        0 * cellSize + 2,
        1 * cellSize + 2,
        cellSize - 4,
        cellSize - 4,
      ),
      paint,
    );
    canvas.drawRect(
      Rect.fromLTWH(
        2 * cellSize + 2,
        1 * cellSize + 2,
        cellSize - 4,
        cellSize - 4,
      ),
      paint,
    );
    canvas.drawRect(
      Rect.fromLTWH(
        3 * cellSize + 2,
        2 * cellSize + 2,
        cellSize - 4,
        cellSize - 4,
      ),
      paint,
    );
  }

  void _drawPuzzleBFS(Canvas canvas, Size size, Offset center) {
    // Brute force: many tiles shimmering/sliding rapidly
    final cellSize = size.width / 3;
    final paint = Paint()..style = PaintingStyle.fill;
    final t = animation.value;

    for (int i = 0; i < 9; i++) {
      if (i == 4) continue; // Hole in center
      int r = i % 3;
      int c = i ~/ 3;

      double shift = math.sin(t * 30 + i) * 2;
      double x = r * cellSize + 4 + shift;
      double y = c * cellSize + 4 - shift;

      paint.color = AppTheme.accent.withValues(
        alpha: 0.1 + (math.sin(t * 20 + i) * 0.1),
      );
      canvas.drawRRect(
        RRect.fromRectAndRadius(
          Rect.fromLTWH(x, y, cellSize - 8, cellSize - 8),
          const Radius.circular(4),
        ),
        paint,
      );
    }
  }

  void _drawPuzzleAStar(Canvas canvas, Size size, Offset center) {
    final cellSize = size.width / 3;
    final t = animation.value;

    // Draw grid
    final paint = Paint()..style = PaintingStyle.fill;
    for (int i = 0; i < 8; i++) {
      int r = i % 3;
      int c = i ~/ 3;
      Offset pos = Offset(r * cellSize, c * cellSize);

      // Animate movement of one tile
      if (i == 7) {
        double move =
            (math.sin(t * math.pi) * 0.5 + 0.5).clamp(0, 1) * cellSize;
        pos = Offset(pos.dx, pos.dy - move);
      }

      paint.color = AppTheme.accent.withValues(alpha: 0.2);
      canvas.drawRRect(
        RRect.fromRectAndRadius(
          Rect.fromLTWH(pos.dx + 4, pos.dy + 4, cellSize - 8, cellSize - 8),
          const Radius.circular(4),
        ),
        paint,
      );

      // Cost pulse line (heuristic influence)
      if (i == 7) {
        paint.color = AppTheme.success.withValues(
          alpha: (math.sin(t * 10) * 0.5 + 0.5) * 0.5,
        );
        canvas.drawCircle(
          Offset(pos.dx + cellSize / 2, pos.dy + cellSize / 2),
          6,
          paint,
        );
      }
    }
  }

  void _drawPuzzleGreedy(Canvas canvas, Size size, Offset center) {
    final cellSize = size.width / 3;
    final t = animation.value;

    // One tile charging toward a specific target slot
    final targetPos = Offset(cellSize * 2, cellSize * 2);
    final startPos = Offset(0, 0);

    final paint = Paint()
      ..style = PaintingStyle.fill
      ..color = AppTheme.error.withValues(alpha: 0.2);
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromLTWH(
          targetPos.dx + 4,
          targetPos.dy + 4,
          cellSize - 8,
          cellSize - 8,
        ),
        const Radius.circular(4),
      ),
      paint,
    );

    Offset pos = Offset.lerp(startPos, targetPos, (t * 2 % 1.0))!;
    paint.color = AppTheme.accentLight;
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromLTWH(pos.dx + 4, pos.dy + 4, cellSize - 8, cellSize - 8),
        const Radius.circular(4),
      ),
      paint,
    );
  }

  void _drawBattle(Canvas canvas, Size size, Offset center) {
    paintDynamicLine(canvas, size, 0.3, AppTheme.accent, animation.value);
    paintDynamicLine(canvas, size, 0.7, AppTheme.error, animation.value * 1.3);
  }

  void paintDynamicLine(
    Canvas canvas,
    Size size,
    double yFactor,
    Color color,
    double t,
  ) {
    final paint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 3.0
      ..strokeCap = StrokeCap.round
      ..color = color;
    double progress = t % 1.5;
    if (progress > 1.0) progress = 1.0;

    final path = Path();
    path.moveTo(size.width * 0.1, size.height * yFactor);
    for (double i = 0.1; i <= progress * 0.8 + 0.1; i += 0.05) {
      path.lineTo(
        size.width * i,
        size.height * yFactor + math.sin(i * 10 + t * 5) * 5,
      );
    }
    canvas.drawPath(path, paint);
    canvas.drawCircle(
      Offset(
        size.width * (progress * 0.8 + 0.1),
        size.height * yFactor +
            math.sin((progress * 0.8 + 0.1) * 10 + t * 5) * 5,
      ),
      4,
      paint..style = PaintingStyle.fill,
    );
  }

  @override
  bool shouldRepaint(covariant _EnhancedConceptPainter oldDelegate) => true;
}
