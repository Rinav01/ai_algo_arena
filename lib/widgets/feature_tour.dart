import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:algo_arena/core/app_theme.dart';

class TourStep {
  final GlobalKey? targetKey;
  final String title;
  final String description;

  const TourStep({
    this.targetKey,
    required this.title,
    required this.description,
  });
}

class FeatureTour {
  static final Set<OverlayEntry> _activeEntries = {};

  static void clearAllTours() {
    for (final entry in _activeEntries) {
      try {
        entry.remove();
      } catch (_) {}
    }
    _activeEntries.clear();
  }

  static final Map<String, String> _tourFixedRoute = {
    'home_screen': '/bfs',
    'pathfinding': '/eightpuzzle',
    'eight_puzzle': '/nqueens',
    'n_queens': '/waterjug',
    'water_jug': '/battle',
    'algorithm_battle': '/history',
    'history_screen': '/analytics',
  };

  static Future<void> startTour({
    required BuildContext context,
    required String tourKey,
    required List<TourStep> steps,
    bool force = false,
  }) async {
    if (!context.mounted) return;

    final prefs = await SharedPreferences.getInstance();
    final isCompleted = prefs.getBool('tour_completed_$tourKey') ?? false;
    if (isCompleted && !force) return;

    if (!context.mounted) return;

    // First clear any previous tours
    clearAllTours();

    final allSteps = List<TourStep>.from(steps);
    final nextRoute = _tourFixedRoute[tourKey];
    final hasShownEndingCard = prefs.getBool('tour_ending_card_shown') ?? false;
    final shouldShowEndCard = nextRoute == null && !hasShownEndingCard;

    if (shouldShowEndCard) {
      allSteps.add(const TourStep(
        targetKey: null,
        title: 'Tour Completed!',
        description: 'You are all set! Remember to click on the "i" info cards wherever you see them to get additional explanations and details about the algorithm.',
      ));
    }

    OverlayState? overlay = Overlay.of(context);
    late OverlayEntry entry;

    entry = OverlayEntry(
      builder: (ctx) => _TourOverlay(
        steps: allSteps,
        onComplete: () {
          try {
            entry.remove();
          } catch (_) {}
          _activeEntries.remove(entry);
          prefs.setBool('tour_completed_$tourKey', true);
          if (shouldShowEndCard) {
            prefs.setBool('tour_ending_card_shown', true);
          }
          if (nextRoute != null) {
            _showTransitionOverlay(context, tourKey, nextRoute, () {
              if (context.mounted) {
                Navigator.pushNamed(context, nextRoute);
              }
            });
          }
        },
        onSkip: () {
          try {
            entry.remove();
          } catch (_) {}
          _activeEntries.remove(entry);
          prefs.setBool('tour_completed_$tourKey', true);
          if (shouldShowEndCard) {
            prefs.setBool('tour_ending_card_shown', true);
          }
        },
      ),
    );

    _activeEntries.add(entry);
    overlay.insert(entry);
  }

  static void _showTransitionOverlay(
    BuildContext context,
    String tourKey,
    String nextRoute,
    VoidCallback onComplete,
  ) {
    OverlayState overlay = Overlay.of(context);
    late OverlayEntry entry;

    entry = OverlayEntry(
      builder: (ctx) => _TourTransition(
        tourKey: tourKey,
        nextRoute: nextRoute,
        onComplete: () {
          try {
            entry.remove();
          } catch (_) {}
          _activeEntries.remove(entry);
          onComplete();
        },
      ),
    );

    _activeEntries.add(entry);
    overlay.insert(entry);
  }
}


class _TourOverlay extends StatefulWidget {
  final List<TourStep> steps;
  final VoidCallback onComplete;
  final VoidCallback onSkip;

  const _TourOverlay({
    required this.steps,
    required this.onComplete,
    required this.onSkip,
  });

  @override
  State<_TourOverlay> createState() => _TourOverlayState();
}

class _TourOverlayState extends State<_TourOverlay> with SingleTickerProviderStateMixin {
  int _currentIndex = 0;
  bool _isFinished = false;
  late AnimationController _fadeCtrl;
  late Animation<double> _fade;

  @override
  void initState() {
    super.initState();
    _fadeCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 300),
    );
    _fade = CurvedAnimation(parent: _fadeCtrl, curve: Curves.easeIn);
    _fadeCtrl.forward();
  }

  @override
  void dispose() {
    _fadeCtrl.dispose();
    super.dispose();
  }

  void _nextStep() {
    if (_isFinished) return;
    if (_currentIndex < widget.steps.length - 1) {
      setState(() {
        _currentIndex++;
        _fadeCtrl.reset();
        _fadeCtrl.forward();
      });
    } else {
      _isFinished = true;
      widget.onComplete();
    }
  }

  void _skipTour() {
    if (_isFinished) return;
    _isFinished = true;
    widget.onSkip();
  }

  @override
  Widget build(BuildContext context) {
    if (widget.steps.isEmpty) return const SizedBox.shrink();

    final step = widget.steps[_currentIndex];
    final screenWidth = MediaQuery.of(context).size.width;
    final screenHeight = MediaQuery.of(context).size.height;

    Rect? targetRect;
    if (step.targetKey != null && step.targetKey!.currentContext != null) {
      final renderBox = step.targetKey!.currentContext!.findRenderObject() as RenderBox?;
      if (renderBox != null && renderBox.hasSize) {
        final offset = renderBox.localToGlobal(Offset.zero);
        targetRect = offset & renderBox.size;
      }
    }

    // Determine tooltip vertical positioning
    double? top;
    double? bottom;

    if (targetRect != null) {
      if (targetRect.center.dy > screenHeight / 2) {
        // Target is in bottom half, position card above target
        bottom = (screenHeight - targetRect.top) + 16.0;
        // Make sure it doesn't go off top screen
        if (bottom > screenHeight - 200.0) {
          bottom = null;
          top = MediaQuery.of(context).padding.top + 24.0;
        }
      } else {
        // Target is in top half, position card below target
        top = targetRect.bottom + 16.0;
        if (top > screenHeight - 200.0) {
          top = null;
          bottom = MediaQuery.of(context).padding.bottom + 100.0;
        }
      }
    } else {
      // Fallback: center of screen
      top = screenHeight * 0.35;
    }

    return Scaffold(
      backgroundColor: Colors.transparent,
      body: Stack(
        children: [
          // Cutout Background Overlay
          Positioned.fill(
            child: CustomPaint(
              painter: _CutoutPainter(
                targetRect: targetRect,
                overlayColor: Colors.black.withValues(alpha: 0.72),
              ),
            ),
          ),
          // Interactive areas / tap to dismiss/next
          Positioned.fill(
            child: GestureDetector(
              onTap: _nextStep,
              behavior: HitTestBehavior.opaque,
              child: const SizedBox.shrink(),
            ),
          ),
          // Animated Tooltip Card
          AnimatedBuilder(
            animation: _fade,
            builder: (context, _) => Positioned(
              top: top,
              bottom: bottom,
              left: 20.0,
              right: 20.0,
              child: FadeTransition(
                opacity: _fade,
                child: Center(
                  child: Container(
                    constraints: BoxConstraints(maxWidth: screenWidth * 0.85),
                    decoration: AppTheme.glassCard(
                      radius: 16.0,
                      borderColor: AppTheme.accent.withValues(alpha: 0.4),
                      glowColor: AppTheme.accent,
                    ),
                    padding: const EdgeInsets.all(20.0),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 8,
                                vertical: 4,
                              ),
                              decoration: BoxDecoration(
                                color: AppTheme.accentContainer.withValues(alpha: 0.3),
                                borderRadius: BorderRadius.circular(6.0),
                                border: Border.all(
                                  color: AppTheme.accent.withValues(alpha: 0.3),
                                ),
                              ),
                              child: Text(
                                'STEP ${_currentIndex + 1} OF ${widget.steps.length}',
                                style: Theme.of(context).textTheme.labelSmall?.copyWith(
                                  color: AppTheme.accentLight,
                                  fontWeight: FontWeight.w700,
                                  letterSpacing: 1.5,
                                ),
                              ),
                            ),
                            IconButton(
                              icon: const Icon(Icons.close_rounded, size: 18, color: AppTheme.textMuted),
                              onPressed: _skipTour,
                              padding: EdgeInsets.zero,
                              constraints: const BoxConstraints(),
                            ),
                          ],
                        ),
                        const SizedBox(height: 12.0),
                        Text(
                          step.title,
                          style: Theme.of(context).textTheme.titleLarge?.copyWith(
                            color: Colors.white,
                            fontWeight: FontWeight.w800,
                            fontFamily: 'SpaceGrotesk',
                          ),
                        ),
                        const SizedBox(height: 8.0),
                        Text(
                          step.description,
                          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                            color: AppTheme.textSecondary,
                            height: 1.45,
                          ),
                        ),
                        const SizedBox(height: 20.0),
                        Row(
                          children: [
                            TextButton(
                              onPressed: _skipTour,
                              child: Text(
                                'Skip Tour',
                                style: Theme.of(context).textTheme.labelLarge?.copyWith(
                                  color: AppTheme.textMuted,
                                ),
                              ),
                            ),
                            const Spacer(),
                            ElevatedButton(
                              style: ElevatedButton.styleFrom(
                                backgroundColor: AppTheme.accent,
                                foregroundColor: Colors.white,
                                elevation: 4,
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 18.0,
                                  vertical: 11.0,
                                ),
                              ),
                              onPressed: _nextStep,
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Text(
                                    _currentIndex == widget.steps.length - 1 ? 'Finish' : 'Next',
                                    style: const TextStyle(fontWeight: FontWeight.bold),
                                  ),
                                  const SizedBox(width: 4),
                                  const Icon(Icons.arrow_forward_rounded, size: 16),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _CutoutPainter extends CustomPainter {
  final Rect? targetRect;
  final Color overlayColor;

  const _CutoutPainter({this.targetRect, required this.overlayColor});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()..color = overlayColor;
    if (targetRect == null) {
      canvas.drawRect(Offset.zero & size, paint);
      return;
    }

    final bgPath = Path()..addRect(Offset.zero & size);
    final holePath = Path()..addRRect(
      RRect.fromRectAndRadius(
        targetRect!.inflate(8.0),
        const Radius.circular(12.0),
      ),
    );

    final cutoutPath = Path.combine(PathOperation.difference, bgPath, holePath);
    canvas.drawPath(cutoutPath, paint);
  }

  @override
  bool shouldRepaint(covariant _CutoutPainter oldDelegate) =>
      oldDelegate.targetRect != targetRect || oldDelegate.overlayColor != overlayColor;
}

class _TourTransition extends StatefulWidget {
  final String tourKey;
  final String nextRoute;
  final VoidCallback onComplete;

  const _TourTransition({
    required this.tourKey,
    required this.nextRoute,
    required this.onComplete,
  });

  @override
  State<_TourTransition> createState() => _TourTransitionState();
}

class _TourTransitionState extends State<_TourTransition> with SingleTickerProviderStateMixin {
  late AnimationController _pulseCtrl;
  late Animation<double> _scale;
  late Animation<double> _fade;

  static final Map<String, String> _tourFixedRouteNames = {
    'home_screen': 'BFS Visualizer',
    'pathfinding': 'Eight Puzzle',
    'eight_puzzle': 'N-Queens Solver',
    'n_queens': 'Water Jug Visualizer',
    'water_jug': 'Algorithm Battle',
    'algorithm_battle': 'History Screen',
    'history_screen': 'Analytics Screen',
  };

  @override
  void initState() {
    super.initState();
    _pulseCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1000),
    )..repeat(reverse: true);

    _scale = Tween<double>(begin: 0.96, end: 1.04).animate(
      CurvedAnimation(parent: _pulseCtrl, curve: Curves.easeInOut),
    );

    _fade = Tween<double>(begin: 0.8, end: 1.0).animate(
      CurvedAnimation(parent: _pulseCtrl, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _pulseCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final nextName = _tourFixedRouteNames[widget.tourKey] ?? 'Next Stage';

    return Scaffold(
      backgroundColor: Colors.black.withValues(alpha: 0.78),
      body: Center(
        child: AnimatedBuilder(
          animation: _pulseCtrl,
          builder: (context, child) => Transform.scale(
            scale: _scale.value,
            child: Opacity(
              opacity: _fade.value,
              child: Container(
                margin: const EdgeInsets.symmetric(horizontal: 24.0),
                padding: const EdgeInsets.all(28.0),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      AppTheme.accent.withValues(alpha: 0.35),
                      const Color(0xFF1E1E2E).withValues(alpha: 0.8),
                    ],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(
                    color: AppTheme.accent.withValues(alpha: 0.6),
                    width: 2.0,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: AppTheme.accent.withValues(alpha: 0.4),
                      blurRadius: 24,
                      spreadRadius: 4,
                    )
                  ],
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: AppTheme.accent.withValues(alpha: 0.15),
                        shape: BoxShape.circle,
                        border: Border.all(
                          color: AppTheme.accent.withValues(alpha: 0.3),
                        ),
                      ),
                      child: const Icon(
                        Icons.rocket_launch_rounded,
                        color: AppTheme.accent,
                        size: 38,
                      ),
                    ),
                    const SizedBox(height: 20),
                    const Text(
                      'STAGE COMPLETED',
                      style: TextStyle(
                        color: AppTheme.accentLight,
                        fontSize: 12,
                        fontWeight: FontWeight.w800,
                        letterSpacing: 2.0,
                        fontFamily: 'SpaceGrotesk',
                      ),
                    ),
                    const SizedBox(height: 10),
                    Text(
                      'Next up: $nextName',
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 20,
                        fontWeight: FontWeight.w700,
                        letterSpacing: 0.5,
                      ),
                    ),
                    const SizedBox(height: 12),
                    const Text(
                      'Are you ready to continue to the next algorithmic stage?',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        color: AppTheme.textMuted,
                        fontSize: 13,
                        height: 1.4,
                      ),
                    ),
                    const SizedBox(height: 24),
                    ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppTheme.accent,
                        foregroundColor: Colors.white,
                        elevation: 4,
                        padding: const EdgeInsets.symmetric(
                          horizontal: 22.0,
                          vertical: 13.0,
                        ),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      onPressed: widget.onComplete,
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            'Continue to $nextName',
                            style: const TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 14,
                            ),
                          ),
                          const SizedBox(width: 8),
                          const Icon(Icons.arrow_forward_rounded, size: 18),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
