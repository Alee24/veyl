import 'package:flutter/material.dart';
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

  @override
  void initState() {
    super.initState();

    // Entrance Animation Setup (1.8 seconds)
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

    _blur = Tween<double>(begin: 15.0, end: 0.0).animate(
      CurvedAnimation(
        parent: _entranceController,
        curve: const Interval(0.1, 0.8, curve: Curves.easeOut),
      ),
    );

    _rotation = Tween<double>(begin: 0.035, end: 0.0).animate(
      CurvedAnimation(
        parent: _entranceController,
        curve: const Interval(0.0, 0.8, curve: Curves.easeOutBack),
      ),
    );

    _glow = Tween<double>(begin: 1.0, end: 0.0).animate(
      CurvedAnimation(
        parent: _entranceController,
        curve: const Interval(0.4, 1.0, curve: Curves.easeInOut),
      ),
    );

    // Interactive Hover Setup (0.9 seconds)
    _interactionController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 900),
    );

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

    _interactionRotation = TweenSequence<double>([
      TweenSequenceItem(
        tween: Tween<double>(begin: 0.0, end: 0.1).chain(CurveTween(curve: Curves.easeInOut)),
        weight: 20,
      ),
      TweenSequenceItem(
        tween: Tween<double>(begin: 0.1, end: -0.08).chain(CurveTween(curve: Curves.easeInOut)),
        weight: 20,
      ),
      TweenSequenceItem(
        tween: Tween<double>(begin: -0.08, end: 0.04).chain(CurveTween(curve: Curves.easeInOut)),
        weight: 20,
      ),
      TweenSequenceItem(
        tween: Tween<double>(begin: 0.04, end: 0.0).chain(CurveTween(curve: Curves.easeOut)),
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
    final accentColor = const Color(0xFF00F2FE); // Metallic Cyan

    return MouseRegion(
      onEnter: (_) => _triggerInteraction(),
      onExit: (_) {},
      child: GestureDetector(
        onTap: _triggerInteraction,
        child: AnimatedBuilder(
          animation: Listenable.merge([_entranceController, _interactionController]),
          builder: (context, child) {
            final double currentScale = _scale.value * _interactionScale.value;
            final double currentRotation = _rotation.value + _interactionRotation.value;
            final double currentBlur = _blur.value;
            final double glowOpacity = (isDark ? 0.3 : 0.1) * (_glow.value + _interactionGlow.value);

            return Stack(
              alignment: Alignment.center,
              children: [
                // Glowing aura behind logo
                if (glowOpacity > 0.01)
                  Container(
                    width: widget.size * 1.6,
                    height: widget.size * 1.6,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      gradient: RadialGradient(
                        colors: [
                          accentColor.withOpacity(glowOpacity),
                          const Color(0xFF8B5CF6).withOpacity(glowOpacity * 0.4),
                          Colors.transparent,
                        ],
                      ),
                    ),
                  ),
                
                // Crisp Ribbon Logo
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
                      child: Image.asset(
                        'assets/logo.png',
                        width: widget.size,
                        height: widget.size,
                        fit: BoxFit.contain,
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

