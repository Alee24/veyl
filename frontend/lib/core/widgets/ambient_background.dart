import 'package:flutter/material.dart';
import 'dart:math' as math;

class AmbientBackground extends StatefulWidget {
  final Widget child;

  const AmbientBackground({super.key, required this.child});

  @override
  State<AmbientBackground> createState() => _AmbientBackgroundState();
}

class _AmbientBackgroundState extends State<AmbientBackground> with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  final List<_Particle> _particles = [];
  final math.Random _random = math.Random();

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 15),
    )..repeat();

    // Initialize 8 subtle floating particles
    for (int i = 0; i < 8; i++) {
      _particles.add(
        _Particle(
          x: _random.nextDouble(),
          y: _random.nextDouble(),
          radius: _random.nextDouble() * 3 + 1,
          speedY: _random.nextDouble() * 0.015 + 0.005,
          opacity: _random.nextDouble() * 0.15 + 0.05,
        ),
      );
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        // Update particles position slowly
        for (final p in _particles) {
          p.y -= p.speedY * 0.05; // float upward
          if (p.y < -0.1) {
            p.y = 1.1; // reset below screen
            p.x = _random.nextDouble();
          }
        }

        return Stack(
          children: [
            // Base background color
            Positioned.fill(
              child: Container(color: theme.scaffoldBackgroundColor),
            ),

            // Animated light rays and particles
            Positioned.fill(
              child: CustomPaint(
                painter: _AmbientPainter(
                  particles: _particles,
                  rayAngle: _controller.value * 2 * math.pi,
                  isDark: isDark,
                  accentColor: theme.colorScheme.secondary,
                ),
              ),
            ),

            // Subtle noise pattern overlay (semi-transparent)
            Positioned.fill(
              child: Opacity(
                opacity: isDark ? 0.015 : 0.008,
                child: Image.network(
                  'https://images.unsplash.com/photo-1618005182384-a83a8bd57fbe?q=80&w=256&auto=format&fit=crop',
                  fit: BoxFit.cover,
                  colorBlendMode: BlendMode.dstATop,
                ),
              ),
            ),

            Positioned.fill(child: widget.child),
          ],
        );
      },
    );
  }
}

class _Particle {
  double x;
  double y;
  final double radius;
  final double speedY;
  final double opacity;

  _Particle({
    required this.x,
    required this.y,
    required this.radius,
    required this.speedY,
    required this.opacity,
  });
}

class _AmbientPainter extends CustomPainter {
  final List<_Particle> particles;
  final double rayAngle;
  final bool isDark;
  final Color accentColor;

  _AmbientPainter({
    required this.particles,
    required this.rayAngle,
    required this.isDark,
    required this.accentColor,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width;
    final h = size.height;

    // 1. Soft radial glow in the center
    final Paint radialPaint = Paint()
      ..shader = RadialGradient(
        colors: [
          accentColor.withOpacity(isDark ? 0.08 : 0.04),
          accentColor.withOpacity(0.0),
        ],
      ).createShader(Rect.fromCircle(center: Offset(w / 2, h / 2), radius: w * 0.8));
    canvas.drawRect(Rect.fromLTWH(0, 0, w, h), radialPaint);

    // 2. Slow-moving translucent light rays
    final Paint rayPaint = Paint()
      ..color = accentColor.withOpacity(isDark ? 0.015 : 0.006)
      ..style = PaintingStyle.fill;
    
    final int numRays = 4;
    for (int i = 0; i < numRays; i++) {
      final double angle = rayAngle / 10 + (i * math.pi / 2);
      final Path path = Path();
      path.moveTo(w / 2, h / 2);
      path.lineTo(w / 2 + math.cos(angle - 0.15) * w * 1.5, h / 2 + math.sin(angle - 0.15) * h * 1.5);
      path.lineTo(w / 2 + math.cos(angle + 0.15) * w * 1.5, h / 2 + math.sin(angle + 0.15) * h * 1.5);
      path.close();
      canvas.drawPath(path, rayPaint);
    }

    // 3. Floating particles
    for (final p in particles) {
      final Paint particlePaint = Paint()
        ..color = (isDark ? Colors.white : accentColor).withOpacity(p.opacity)
        ..style = PaintingStyle.fill;
      canvas.drawCircle(Offset(p.x * w, p.y * h), p.radius, particlePaint);
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}
