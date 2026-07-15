import 'package:flutter/material.dart';
import 'dart:math' as math;
import 'dart:ui';

class VeylLogoWidget extends StatefulWidget {
  final double size;
  final bool animateOnStart;

  const VeylLogoWidget({
    super.key,
    this.size = 120.0,
    this.animateOnStart = true,
  });

  @override
  State<VeylLogoWidget> createState() => _VeylLogoWidgetState();
}

class _VeylLogoWidgetState extends State<VeylLogoWidget> with TickerProviderStateMixin {
  // Entrance Animations
  late AnimationController _entranceController;
  late Animation<double> _opacity;
  late Animation<double> _scale;
  late Animation<double> _blur;
  late Animation<double> _rotation;
  late Animation<double> _glow;

  // Hover/Tap Interaction Animation
  late AnimationController _interactionController;
  late Animation<double> _interactionScale;
  late Animation<double> _interactionRotation;
  late Animation<double> _interactionGlow;

  bool _isHovered = false;

  @override
  void initState() {
    super.initState();

    // 1. Entrance Animation Setup (1.8 seconds)
    _entranceController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1800),
    );

    _opacity = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _entranceController,
        curve: const Interval(0.0, 0.6, curve: Curves.easeOut),
      ),
    );

    _scale = Tween<double>(begin: 0.7, end: 1.0).animate(
      CurvedAnimation(
        parent: _entranceController,
        curve: const Interval(0.0, 0.7, curve: Curves.easeOutCubic),
      ),
    );

    // Blur goes from 15.0 to 0.0
    _blur = Tween<double>(begin: 15.0, end: 0.0).animate(
      CurvedAnimation(
        parent: _entranceController,
        curve: const Interval(0.1, 0.8, curve: Curves.easeOut),
      ),
    );

    // Rotation < 2 degrees (approx. 0.035 radians)
    _rotation = Tween<double>(begin: 0.035, end: 0.0).animate(
      CurvedAnimation(
        parent: _entranceController,
        curve: const Interval(0.0, 0.8, curve: Curves.easeOutBack),
      ),
    );

    // Soft glow behind logo fades naturally
    _glow = Tween<double>(begin: 1.0, end: 0.0).animate(
      CurvedAnimation(
        parent: _entranceController,
        curve: const Interval(0.4, 1.0, curve: Curves.easeInOut),
      ),
    );

    // 2. Interactive Hover Setup (0.9 seconds)
    _interactionController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 900),
    );

    // Tap/Hover triggers brief scale up to 1.08x
    _interactionScale = TweenSequence<double>([
      TweenSequenceItem(
        tween: Tween<double>(begin: 1.0, end: 1.08).chain(CurveTween(curve: Curves.easeOutBack)),
        weight: 30,
      ),
      TweenSequenceItem(
        tween: Tween<double>(begin: 1.08, end: 1.0).chain(CurveTween(curve: Curves.elasticOut)),
        weight: 70,
      ),
    ]).animate(_interactionController);

    // Rapid micro-rotation (6-8 degrees -> approx 0.12 radians)
    _interactionRotation = TweenSequence<double>([
      TweenSequenceItem(
        tween: Tween<double>(begin: 0.0, end: 0.12).chain(CurveTween(curve: Curves.easeInOut)),
        weight: 20,
      ),
      TweenSequenceItem(
        tween: Tween<double>(begin: 0.12, end: -0.1).chain(CurveTween(curve: Curves.easeInOut)),
        weight: 20,
      ),
      TweenSequenceItem(
        tween: Tween<double>(begin: -0.1, end: 0.05).chain(CurveTween(curve: Curves.easeInOut)),
        weight: 20,
      ),
      TweenSequenceItem(
        tween: Tween<double>(begin: 0.05, end: 0.0).chain(CurveTween(curve: Curves.easeOut)),
        weight: 40,
      ),
    ]).animate(_interactionController);

    _interactionGlow = TweenSequence<double>([
      TweenSequenceItem(
        tween: Tween<double>(begin: 0.0, end: 1.0).chain(CurveTween(curve: Curves.easeOut)),
        weight: 30,
      ),
      TweenSequenceItem(
        tween: Tween<double>(begin: 1.0, end: 0.0).chain(CurveTween(curve: Curves.easeIn)),
        weight: 70,
      ),
    ]).animate(_interactionController);

    if (widget.animateOnStart) {
      _entranceController.forward();
    } else {
      _entranceController.value = 1.0;
    }
  }

  @override
  void dispose() {
    _entranceController.dispose();
    _interactionController.dispose();
    super.dispose();
  }

  void _triggerInteraction() {
    if (!_interactionController.isAnimating) {
      _interactionController.forward(from: 0.0);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final accentColor = theme.colorScheme.secondary;

    return MouseRegion(
      onEnter: (_) {
        setState(() => _isHovered = true);
        _triggerInteraction();
      },
      onExit: (_) => setState(() => _isHovered = false),
      child: GestureDetector(
        onTap: _triggerInteraction,
        child: AnimatedBuilder(
          animation: Listenable.merge([_entranceController, _interactionController]),
          builder: (context, child) {
            final double currentScale = _scale.value * _interactionScale.value;
            final double currentRotation = _rotation.value + _interactionRotation.value;
            final double currentBlur = _blur.value;
            final double glowOpacity = (isDark ? 0.35 : 0.15) * (_glow.value + _interactionGlow.value);

            return Stack(
              alignment: Alignment.center,
              children: [
                // Soft glow radial layer behind the logo
                if (glowOpacity > 0.01)
                  Container(
                    width: widget.size * 1.8,
                    height: widget.size * 1.8,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      gradient: RadialGradient(
                        colors: [
                          accentColor.withOpacity(glowOpacity),
                          accentColor.withOpacity(glowOpacity * 0.4),
                          Colors.transparent,
                        ],
                      ),
                    ),
                  ),
                
                // Crisp Vector Logo with Blur and Transform matrices applied
                Opacity(
                  opacity: _opacity.value,
                  child: ImageFiltered(
                    imageFilter: ImageFilter.blur(
                      sigmaX: currentBlur,
                      sigmaY: currentBlur,
                      tileMode: TileMode.decal,
                    ),
                    child: Transform(
                      transform: Matrix4.identity()
                        ..rotateZ(currentRotation)
                        ..scale(currentScale),
                      alignment: Alignment.center,
                      child: CustomPaint(
                        size: Size(widget.size, widget.size),
                        painter: _VeylLogoPainter(
                          color: isDark ? Colors.white : theme.colorScheme.primary,
                          accentColor: accentColor,
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            );
          },
        ),
      ),
    );
  }
}

class _VeylLogoPainter extends CustomPainter {
  final Color color;
  final Color accentColor;

  _VeylLogoPainter({required this.color, required this.accentColor});

  @override
  void paint(Canvas canvas, Size size) {
    final double w = size.width;
    final double h = size.height;
    final double radius = w * 0.28;
    final double cx = w / 2;
    final double cy = h / 2;

    // Draw background/accent geometric luxury shield backplate
    final Paint outlinePaint = Paint()
      ..color = accentColor.withOpacity(0.08)
      ..style = PaintingStyle.fill;
    
    final Path shieldPath = Path();
    shieldPath.moveTo(cx, cy - radius * 1.5);
    shieldPath.quadraticBezierTo(cx + radius * 1.5, cy - radius * 1.4, cx + radius * 1.4, cy);
    shieldPath.quadraticBezierTo(cx + radius * 1.2, cy + radius * 1.5, cx, cy + radius * 1.8);
    shieldPath.quadraticBezierTo(cx - radius * 1.2, cy + radius * 1.5, cx - radius * 1.4, cy);
    shieldPath.quadraticBezierTo(cx - radius * 1.5, cy - radius * 1.4, cx, cy - radius * 1.5);
    canvas.drawPath(shieldPath, outlinePaint);

    // Draw main premium geometric shape: Stylized Interlocking Key Loop / Infinity Shield
    final Paint paint = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = w * 0.08
      ..strokeCap = StrokeCap.round
      ..isAntiAlias = true;

    // Draw first interlocking loop (Left)
    canvas.drawCircle(Offset(cx - radius * 0.5, cy), radius, paint);

    // Draw second interlocking loop (Right)
    paint.color = accentColor;
    canvas.drawCircle(Offset(cx + radius * 0.5, cy), radius, paint);

    // Draw center core secure node
    final Paint nodePaint = Paint()
      ..color = color
      ..style = PaintingStyle.fill
      ..isAntiAlias = true;
    canvas.drawCircle(Offset(cx, cy), w * 0.05, nodePaint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
