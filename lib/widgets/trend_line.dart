import 'dart:math' as math;
import 'package:flutter/material.dart';

class TrendLine extends StatelessWidget {
  final List<double> data;
  final Color color;
  final double currentProgress; // 0.0 to 1.0
  final String? label;

  const TrendLine({
    super.key,
    required this.data,
    required this.color,
    required this.currentProgress,
    this.label,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (label != null)
          Padding(
            padding: const EdgeInsets.only(bottom: 4),
            child: Text(
              label!,
              style: TextStyle(
                color: color.withValues(alpha: 0.7),
                fontSize: 10,
                fontWeight: FontWeight.bold,
                letterSpacing: 1,
              ),
            ),
          ),
        CustomPaint(
          size: const Size(double.infinity, 30),
          painter: _TrendLinePainter(
            data: data,
            color: color,
            progress: currentProgress,
          ),
        ),
      ],
    );
  }
}

class _TrendLinePainter extends CustomPainter {
  final List<double> data;
  final Color color;
  final double progress;

  _TrendLinePainter({
    required this.data,
    required this.color,
    required this.progress,
  });

  @override
  void paint(Canvas canvas, Size size) {
    if (data.length < 2) return;

    final paint = Paint()
      ..color = color.withValues(alpha: 0.15)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.5
      ..strokeCap = StrokeCap.round;

    final progressPaint = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.5
      ..strokeCap = StrokeCap.round;

    // Fill paint for the area under the curve
    final fillPaint = Paint()
      ..shader = LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: [
          color.withValues(alpha: 0.2),
          color.withValues(alpha: 0.0),
        ],
      ).createShader(Rect.fromLTRB(0, 0, size.width, size.height));

    final path = Path();
    final progressPath = Path();
    final fillPath = Path();

    final stepX = size.width / (data.length - 1);
    final maxVal = data.reduce((a, b) => a > b ? a : b);
    final scaleY = maxVal == 0 ? 1.0 : size.height / maxVal;

    for (int i = 0; i < data.length; i++) {
      final x = i * stepX;
      final y = size.height - (data[i] * scaleY);

      if (i == 0) {
        path.moveTo(x, y);
        progressPath.moveTo(x, y);
        fillPath.moveTo(x, size.height);
        fillPath.lineTo(x, y);
      } else {
        path.lineTo(x, y);
        if (i / (data.length - 1) <= progress) {
          progressPath.lineTo(x, y);
          fillPath.lineTo(x, y);
          if (i == data.length - 1 || (i + 1) / (data.length - 1) > progress) {
             fillPath.lineTo(x, size.height);
          }
        }
      }
    }

    canvas.drawPath(path, paint);
    canvas.drawPath(fillPath, fillPaint);
    canvas.drawPath(progressPath, progressPaint);
    
    // Draw indicator dot at current progress
    final currentIdx = (progress * (data.length - 1)).floor();
    if (currentIdx < data.length) {
      final dotX = progress * size.width;
      // Interpolate Y for smooth movement
      final idx = progress * (data.length - 1);
      final i1 = idx.floor();
      final i2 = math.min(i1 + 1, data.length - 1);
      final t = idx - i1;
      final y1 = size.height - (data[i1] * scaleY);
      final y2 = size.height - (data[i2] * scaleY);
      final dotY = y1 + (y2 - y1) * t;

      canvas.drawCircle(
        Offset(dotX, dotY), 
        4, 
        Paint()..color = Colors.white
      );
      canvas.drawCircle(
        Offset(dotX, dotY), 
        3, 
        Paint()..color = color
      );
    }
  }

  @override
  bool shouldRepaint(_TrendLinePainter oldDelegate) => 
      oldDelegate.progress != progress || oldDelegate.data != data;
}