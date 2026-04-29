import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:algo_arena/core/app_theme.dart';
import 'package:algo_arena/services/performance_monitor.dart';
import 'package:algo_arena/state/performance_provider.dart';
import 'package:flutter_animate/flutter_animate.dart';

class PremiumGlassContainer extends ConsumerWidget {
  final Widget child;
  final double radius;
  final double blurSigma;
  final double opacity;
  final EdgeInsetsGeometry? padding;
  final BoxBorder? border;
  final Gradient? gradient;
  final double? width;
  final double? height;
  final EdgeInsetsGeometry? margin;
  final bool animate;

  const PremiumGlassContainer({
    super.key,
    required this.child,
    this.radius = 32,
    this.blurSigma = 20,
    this.opacity = 0.7,
    this.padding,
    this.width,
    this.height,
    this.margin,
    this.border,
    this.gradient,
    this.animate = true,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final quality = ref.watch(qualityLevelProvider);
    final isLowFidelity = quality == QualityLevel.performance;

    Widget current = Container(
      width: width,
      height: height,
      margin: margin,
      padding: padding,
      decoration: BoxDecoration(
        color: AppTheme.surfaceVariant.withValues(alpha: isLowFidelity ? 0.95 : opacity),
        borderRadius: BorderRadius.circular(radius),
        border: border ?? Border.all(color: Colors.white.withValues(alpha: 0.1)),
        gradient: gradient,
      ),
      child: child,
    );

    if (!isLowFidelity) {
      current = ClipRRect(
        borderRadius: BorderRadius.circular(radius),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: blurSigma, sigmaY: blurSigma),
          child: current,
        ),
      );
    } else {
      current = ClipRRect(
        borderRadius: BorderRadius.circular(radius),
        child: current,
      );
    }

    if (animate) {
      current = current
          .animate(onPlay: (controller) => controller.repeat())
          .shimmer(
            duration: 3.seconds,
            color: Colors.white.withValues(alpha: 0.05),
          );
    }

    return current;
  }
}
