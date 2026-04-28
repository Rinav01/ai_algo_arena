import 'dart:math' as math;
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../core/app_theme.dart';
import 'home_screen.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> with TickerProviderStateMixin {
  late AnimationController _mainController;
  late AnimationController _pulseController;
  late AnimationController _progressController;
  late AnimationController _glowController;
  
  late Animation<double> _fadeAnimation;
  late Animation<double> _scaleAnimation;
  late Animation<double> _progressAnimation;
  late Animation<double> _pulseAnimation;
  late Animation<double> _glowAnimation;
  late Animation<double> _logoRotationAnimation;

  @override
  void initState() {
    super.initState();

    _mainController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2000),
    );

    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 3000),
    )..repeat(reverse: true);

    _progressController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 5500),
    );

    _glowController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 8),
    )..repeat();

    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _mainController, curve: const Interval(0.0, 0.5, curve: Curves.easeIn)),
    );

    _scaleAnimation = Tween<double>(begin: 0.8, end: 1.0).animate(
      CurvedAnimation(parent: _mainController, curve: const Interval(0.0, 0.6, curve: Curves.easeOutBack)),
    );

    _pulseAnimation = Tween<double>(begin: 1.0, end: 1.04).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut),
    );

    _progressAnimation = TweenSequence<double>([
      TweenSequenceItem(
        tween: Tween<double>(begin: 0.0, end: 0.867).chain(CurveTween(curve: Curves.easeOut)),
        weight: 36.4, // 2 seconds
      ),
      TweenSequenceItem(
        tween: ConstantTween<double>(0.867),
        weight: 45.4, // 2.5 seconds wait
      ),
      TweenSequenceItem(
        tween: Tween<double>(begin: 0.867, end: 1.0).chain(CurveTween(curve: Curves.easeIn)),
        weight: 18.2, // 1 second finish
      ),
    ]).animate(_progressController);

    _progressController.addStatusListener((status) {
      if (status == AnimationStatus.completed) {
        _navigateToHome();
      }
    });

    _glowAnimation = Tween<double>(begin: 0.0, end: 2 * math.pi).animate(_glowController);
    _logoRotationAnimation = Tween<double>(begin: 0.0, end: 2 * math.pi).animate(_glowController);

    _mainController.forward();
    _progressController.forward();
  }

  void _navigateToHome() {
    if (!mounted) return;
    Navigator.of(context).pushReplacement(
      PageRouteBuilder(
        pageBuilder: (context, animation, secondaryAnimation) => const HomeScreen(),
        transitionsBuilder: (context, animation, secondaryAnimation, child) {
          return FadeTransition(opacity: animation, child: child);
        },
        transitionDuration: const Duration(milliseconds: 1200),
      ),
    );
  }

  @override
  void dispose() {
    _mainController.dispose();
    _pulseController.dispose();
    _progressController.dispose();
    _glowController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;
    final isTablet = size.shortestSide > 600;
    final hexagonWidth = (size.width * (isTablet ? 0.5 : 0.85)).clamp(280.0, 450.0);
    final hexagonHeight = hexagonWidth * 1.4;

    return Scaffold(
      backgroundColor: AppTheme.background,
      body: Stack(
        children: [
          // 1. Perspective Grid Background
          Positioned.fill(
            child: CustomPaint(
              painter: GridBackgroundPainter(),
            ),
          ),

          // 1b. Kinetic Data Streams
          Positioned.fill(
            child: const DataStreamParticles(),
          ),

          // 2. Dynamic Ambient Glow
          _buildDynamicGlow(size),

          // 3. Central Content
          Center(
            child: FadeTransition(
              opacity: _fadeAnimation,
              child: ScaleTransition(
                scale: _scaleAnimation,
                child: AnimatedBuilder(
                  animation: _pulseAnimation,
                  builder: (context, child) {
                    return Transform.scale(
                      scale: _pulseAnimation.value,
                      child: child,
                    );
                  },
                  child: _buildCentralShield(hexagonWidth, hexagonHeight),
                ),
              ),
            ),
          ),

          // 4. Progress & Stats (Sticky to bottom)
          _buildResponsiveBottomLayout(size),

          // 5. Shader Prewarmer (Invisible but forces GPU compilation)
          const _ShaderPrewarmer(),
        ],
      ),
    );
  }

  Widget _buildDynamicGlow(Size size) {
    return AnimatedBuilder(
      animation: _glowAnimation,
      builder: (context, child) {
        final xOffset = math.sin(_glowAnimation.value) * 30;
        final yOffset = math.cos(_glowAnimation.value) * 30;

        return Stack(
          children: [
            Positioned(
              top: size.height * 0.15 + yOffset,
              left: -50 + xOffset,
              child: _glowingCircle(size.width * 0.7, AppTheme.accent.withValues(alpha: 0.08)),
            ),
            Positioned(
              bottom: size.height * 0.1 + yOffset,
              right: -80 - xOffset,
              child: _glowingCircle(size.width * 0.8, AppTheme.cyan.withValues(alpha: 0.08)),
            ),
          ],
        );
      },
    );
  }

  Widget _glowingCircle(double size, Color color) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        gradient: RadialGradient(
          colors: [
            color,
            color.withValues(alpha: 0.0),
          ],
        ),
      ),
    );
  }

  Widget _buildCentralShield(double width, double height) {
    return SizedBox(
      width: width,
      height: height,
      child: Stack(
        children: [
          // Hexagon Glass Background
          ClipPath(
            clipper: HexagonClipper(),
            child: BackdropFilter(
              filter: ImageFilter.blur(sigmaX: 5, sigmaY: 5),
              child: Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [
                      Colors.white.withValues(alpha: 0.12),
                      Colors.white.withValues(alpha: 0.04),
                    ],
                  ),
                  border: Border.all(
                    color: Colors.white.withValues(alpha: 0.15),
                    width: 1.5,
                  ),
                ),
              ),
            ),
          ),
          
          // Hexagon Outline
          CustomPaint(
            size: Size(width, height),
            painter: HexagonPainter(
              color: AppTheme.accent.withValues(alpha: 0.4),
            ),
          ),

          // Content inside Hexagon
          Padding(
            padding: EdgeInsets.symmetric(
              horizontal: width * 0.12,
              vertical: height * 0.1,
            ),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                _buildLogo(width * 0.2),
                SizedBox(height: height * 0.03),
                
                Text(
                  "QUANTUM PROTOCOL",
                  style: GoogleFonts.spaceGrotesk(
                    fontSize: (width * 0.045).clamp(10.0, 14.0),
                    fontWeight: FontWeight.w600,
                    letterSpacing: 4.0,
                    color: AppTheme.onBackground.withValues(alpha: 0.7),
                  ),
                ),
                SizedBox(height: height * 0.04),
                
                Text(
                  "ALGO\nARENA",
                  textAlign: TextAlign.center,
                  style: GoogleFonts.spaceGrotesk(
                    fontSize: (width * 0.12).clamp(24.0, 42.0),
                    fontWeight: FontWeight.w800,
                    height: 1.0,
                    letterSpacing: -1.0,
                    color: AppTheme.onBackground,
                  ),
                ),
                SizedBox(height: height * 0.05),
                
                Text(
                  "Symphonizing complex search heuristics through the kinetic observation of neural data streams.",
                  textAlign: TextAlign.center,
                  style: GoogleFonts.manrope(
                    fontSize: (width * 0.04).clamp(11.0, 14.0),
                    fontWeight: FontWeight.w400,
                    height: 1.6,
                    color: AppTheme.onBackground.withValues(alpha: 0.6),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLogo(double size) {
    return AnimatedBuilder(
      animation: Listenable.merge([_glowController, _pulseController]),
      builder: (context, child) {
        return Transform.rotate(
          angle: _logoRotationAnimation.value,
          child: SizedBox(
            width: size,
            height: size,
            child: Stack(
              children: [
                // Connecting Lines
                CustomPaint(
                  size: Size(size, size),
                  painter: LogoPainter(color: AppTheme.accent),
                ),
                
                // Central Node with performant RadialGradient glow instead of BoxShadow
                Center(
                  child: Container(
                    width: size * 0.25 * _pulseAnimation.value * 1.5,
                    height: size * 0.25 * _pulseAnimation.value * 1.5,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      gradient: RadialGradient(
                        colors: [
                          AppTheme.accent.withValues(alpha: 0.8),
                          AppTheme.accent.withValues(alpha: 0.2),
                          Colors.transparent,
                        ],
                        stops: const [0.3, 0.6, 1.0],
                      ),
                    ),
                  ),
                ),
                
                // Outer Nodes
                ...List.generate(5, (index) {
                  final angle = (index * 2 * math.pi / 5) - math.pi / 2;
                  // Add a slight individual wobble to each node
                  final wobble = math.sin(_glowAnimation.value + index) * 2;
                  
                  return Positioned(
                    top: (size / 2) + (size * 0.35) * math.sin(angle) - (size * 0.1) + wobble,
                    left: (size / 2) + (size * 0.35) * math.cos(angle) - (size * 0.1) + wobble,
                    child: Container(
                      width: size * 0.2 * (0.9 + 0.2 * math.sin(_glowAnimation.value * 2 + index)) * 1.5,
                      height: size * 0.2 * (0.9 + 0.2 * math.sin(_glowAnimation.value * 2 + index)) * 1.5,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        gradient: RadialGradient(
                          colors: [
                            AppTheme.accent.withValues(alpha: 0.9),
                            AppTheme.accent.withValues(alpha: 0.3),
                            Colors.transparent,
                          ],
                          stops: const [0.4, 0.7, 1.0],
                        ),
                      ),
                    ),
                  );
                }),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildResponsiveBottomLayout(Size size) {
    final horizontalPadding = (size.width * 0.1).clamp(24.0, 60.0);
    
    return Positioned(
      left: horizontalPadding,
      right: horizontalPadding,
      bottom: size.height * 0.06,
      child: FadeTransition(
        opacity: _fadeAnimation,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            _buildProgressBar(),
            SizedBox(height: size.height * 0.05),
            _buildBottomStats(size),
          ],
        ),
      ),
    );
  }

  Widget _buildProgressBar() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              "SYNCING WITH NEURAL NEXUS...",
              style: GoogleFonts.spaceGrotesk(
                fontSize: 11,
                fontWeight: FontWeight.w600,
                letterSpacing: 1.5,
                color: AppTheme.onBackground.withValues(alpha: 0.8),
              ),
            ),
            AnimatedBuilder(
              animation: _progressAnimation,
              builder: (context, child) {
                return Text(
                  "${(_progressAnimation.value * 100).toStringAsFixed(1)}%",
                  style: GoogleFonts.spaceGrotesk(
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                    color: AppTheme.onBackground.withValues(alpha: 0.8),
                  ),
                );
              },
            ),
          ],
        ),
        const SizedBox(height: 12),
        Container(
          height: 3,
          width: double.infinity,
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: 0.05),
            borderRadius: BorderRadius.circular(2),
          ),
          child: AnimatedBuilder(
            animation: _progressAnimation,
            builder: (context, child) {
              return FractionallySizedBox(
                alignment: Alignment.centerLeft,
                widthFactor: _progressAnimation.value,
                child: Container(
                  decoration: BoxDecoration(
                    color: AppTheme.cyan,
                    boxShadow: [
                      BoxShadow(
                        color: AppTheme.cyan.withValues(alpha: 0.6),
                        blurRadius: 10,
                        spreadRadius: 1,
                      ),
                    ],
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _buildBottomStats(Size size) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceAround,
      children: [
        _buildStatItem("LATENCY", "0.002ms"),
        _buildStatItem("NODES", "1.2B"),
        _buildStatItem("ENTROPY", "Low"),
      ],
    );
  }

  Widget _buildStatItem(String label, String value) {
    return Column(
      children: [
        Text(
          label,
          style: GoogleFonts.spaceGrotesk(
            fontSize: 10,
            fontWeight: FontWeight.w600,
            letterSpacing: 1.0,
            color: AppTheme.onBackground.withValues(alpha: 0.5),
          ),
        ),
        const SizedBox(height: 4),
        Text(
          value,
          style: GoogleFonts.spaceGrotesk(
            fontSize: 14,
            fontWeight: FontWeight.w700,
            color: AppTheme.onBackground,
          ),
        ),
      ],
    );
  }
}

class GridBackgroundPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = AppTheme.cyan.withValues(alpha: 0.1)
      ..strokeWidth = 1.2;

    final horizonY = size.height * 0.55;
    const numLines = 24;

    // Vertical Perspective Lines
    for (int i = 0; i <= numLines; i++) {
      final x = (size.width / numLines) * i;
      final start = Offset(size.width / 2, horizonY);
      final end = Offset(x * 2.2 - (size.width * 0.6), size.height);
      canvas.drawLine(start, end, paint);
    }

    // Horizontal Lines (Perspective)
    for (int i = 0; i < 18; i++) {
      final yProgress = i / 17;
      final y = horizonY + (size.height - horizonY) * math.pow(yProgress, 2.2);
      final xOffset = (size.width / 2) * (1 - yProgress) * 0.5;
      canvas.drawLine(Offset(xOffset, y), Offset(size.width - xOffset, y), paint);
    }
    
    // Static Background Grid (Faint)
    final topPaint = Paint()
      ..color = AppTheme.cyan.withValues(alpha: 0.04)
      ..strokeWidth = 0.6;
    
    for (int i = 0; i < 12; i++) {
      final y = (horizonY / 12) * i;
      canvas.drawLine(Offset(0, y), Offset(size.width, y), topPaint);
    }
    for (int i = 0; i < 8; i++) {
      final x = (size.width / 8) * i;
      canvas.drawLine(Offset(x, 0), Offset(x, horizonY), topPaint);
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

class HexagonClipper extends CustomClipper<Path> {
  @override
  Path getClip(Size size) {
    final path = Path();
    final width = size.width;
    final height = size.height;
    
    path.moveTo(width / 2, 0);
    path.lineTo(width, height * 0.25);
    path.lineTo(width, height * 0.75);
    path.lineTo(width / 2, height);
    path.lineTo(0, height * 0.75);
    path.lineTo(0, height * 0.25);
    path.close();
    
    return path;
  }

  @override
  bool shouldReclip(covariant CustomClipper<Path> oldDelegate) => false;
}

class HexagonPainter extends CustomPainter {
  final Color color;
  HexagonPainter({required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.0;

    final path = Path();
    final width = size.width;
    final height = size.height;
    
    path.moveTo(width / 2, 0);
    path.lineTo(width, height * 0.25);
    path.lineTo(width, height * 0.75);
    path.lineTo(width / 2, height);
    path.lineTo(0, height * 0.75);
    path.lineTo(0, height * 0.25);
    path.close();
    
    canvas.drawPath(path, paint);
    
    // Highlighted glowing edges
    final glowPaint = Paint()
      ..color = color.withValues(alpha: 0.6)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 4.0
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 6);
      
    canvas.drawPath(path, glowPaint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

class LogoPainter extends CustomPainter {
  final Color color;
  LogoPainter({required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color.withValues(alpha: 0.35)
      ..strokeWidth = 1.2;

    final center = Offset(size.width / 2, size.height / 2);
    final radius = size * 0.35;
    
    for (int i = 0; i < 5; i++) {
      final angle = (i * 2 * math.pi / 5) - math.pi / 2;
      final outer = Offset(
        size.width / 2 + radius.width * math.cos(angle),
        size.height / 2 + radius.height * math.sin(angle),
      );
      canvas.drawLine(center, outer, paint);
    }
    
    for (int i = 0; i < 5; i++) {
      final angle1 = (i * 2 * math.pi / 5) - math.pi / 2;
      final angle2 = ((i + 1) * 2 * math.pi / 5) - math.pi / 2;
      final p1 = Offset(
        size.width / 2 + radius.width * math.cos(angle1),
        size.height / 2 + radius.height * math.sin(angle1),
      );
      final p2 = Offset(
        size.width / 2 + radius.width * math.cos(angle2),
        size.height / 2 + radius.height * math.sin(angle2),
      );
      canvas.drawLine(p1, p2, paint);
    }
  }
  
  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

class DataStreamParticles extends StatefulWidget {
  const DataStreamParticles({super.key});

  @override
  State<DataStreamParticles> createState() => _DataStreamParticlesState();
}

class _DataStreamParticlesState extends State<DataStreamParticles> with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  final List<Particle> _particles = List.generate(20, (index) => Particle());

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 10),
    )..repeat();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        for (var p in _particles) {
          p.update();
        }
        return CustomPaint(
          painter: ParticlePainter(particles: _particles),
        );
      },
    );
  }
}

class Particle {
  late double x, y, speed, opacity;
  final math.Random random = math.Random();

  Particle() {
    reset();
  }

  void reset() {
    x = random.nextDouble() * 1.0; 
    y = random.nextDouble() * 1.0; 
    speed = 0.002 + random.nextDouble() * 0.005;
    opacity = 0.05 + random.nextDouble() * 0.25;
  }

  void update() {
    y += speed;
    if (y > 1.0) {
      y = -0.05;
      x = random.nextDouble();
    }
  }
}

class ParticlePainter extends CustomPainter {
  final List<Particle> particles;
  ParticlePainter({required this.particles});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()..strokeCap = StrokeCap.round;

    for (var p in particles) {
      paint.color = AppTheme.cyan.withValues(alpha: p.opacity);
      paint.strokeWidth = 1.8;
      canvas.drawLine(
        Offset(p.x * size.width, p.y * size.height),
        Offset(p.x * size.width, (p.y + 0.02) * size.height),
        paint,
      );
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}
/// Invisible widget that renders common expensive UI elements once
/// during the splash screen to pre-compile GPU shaders.
class _ShaderPrewarmer extends StatelessWidget {
  const _ShaderPrewarmer();

  @override
  Widget build(BuildContext context) {
    return Opacity(
      opacity: 0.001, // Nearly invisible but still part of the paint tree
      child: SizedBox(
        width: 1,
        height: 1,
        child: Stack(
          children: [
            // Prewarm Glass Shader
            Container(decoration: AppTheme.glassDecoration),
            // Prewarm Accent Glass Shader
            Container(decoration: AppTheme.glassDecorationAccent),
            // Prewarm standard glass card
            Container(decoration: AppTheme.glassCard()),
            // Prewarm a blur filter
            BackdropFilter(filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10), child: Container()),
          ],
        ),
      ),
    );
  }
}

