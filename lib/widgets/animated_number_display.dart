import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

/// Animated number display widget that smoothly transitions between values
/// with configurable duration and curve
class AnimatedNumberDisplay extends StatefulWidget {
  final int value;
  final Duration duration;
  final Curve curve;
  final TextStyle? textStyle;
  final String? prefix;
  final String? suffix;

  const AnimatedNumberDisplay({
    super.key,
    required this.value,
    this.duration = const Duration(milliseconds: 800),
    this.curve = Curves.easeOutCubic,
    this.textStyle,
    this.prefix,
    this.suffix,
  });

  @override
  State<AnimatedNumberDisplay> createState() => _AnimatedNumberDisplayState();
}

class _AnimatedNumberDisplayState extends State<AnimatedNumberDisplay>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _animation;
  late int _previousValue;

  @override
  void initState() {
    super.initState();
    _previousValue = widget.value;
    _controller = AnimationController(duration: widget.duration, vsync: this);
    _setupAnimation();
  }

  void _setupAnimation() {
    _animation = Tween<double>(
      begin: _previousValue.toDouble(),
      end: widget.value.toDouble(),
    ).animate(CurvedAnimation(parent: _controller, curve: widget.curve));

    _controller.forward(from: 0.0);
  }

  @override
  void didUpdateWidget(AnimatedNumberDisplay oldWidget) {
    super.didUpdateWidget(oldWidget);

    if (oldWidget.value != widget.value) {
      _previousValue = oldWidget.value;
      _controller.duration = widget.duration;
      _setupAnimation();
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _animation,
      builder: (context, child) {
        final displayValue = _animation.value.toInt();
        final displayText =
            '${widget.prefix ?? ''}$displayValue${widget.suffix ?? ''}';

        final defaultStyle = TextStyle(
          fontSize: 16.sp,
          fontWeight: FontWeight.bold,
          color: Colors.white,
        );

        return Text(displayText, style: widget.textStyle ?? defaultStyle);
      },
    );
  }
}
