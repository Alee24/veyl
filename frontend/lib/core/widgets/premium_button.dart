import 'package:flutter/material.dart';

class PremiumButton extends StatefulWidget {
  final Widget child;
  final VoidCallback? onPressed;
  final Color? backgroundColor;
  final Color? foregroundColor;
  final double borderRadius;
  final double height;

  const PremiumButton({
    super.key,
    required this.child,
    this.onPressed,
    this.backgroundColor,
    this.foregroundColor,
    this.borderRadius = 18.0,
    this.height = 56.0,
  });

  @override
  State<PremiumButton> createState() => _PremiumButtonState();
}

class _PremiumButtonState extends State<PremiumButton> with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _scaleAnimation;
  bool _isHovered = false;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 150),
    );

    // Spring-like overshoot curve when returning
    _scaleAnimation = Tween<double>(begin: 1.0, end: 0.97).animate(
      CurvedAnimation(
        parent: _controller,
        curve: Curves.easeInOut,
        reverseCurve: Curves.easeOutBack,
      ),
    );
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
    
    final bg = widget.backgroundColor ?? 
        (isDark ? theme.colorScheme.primary : theme.colorScheme.primary);
    final fg = widget.foregroundColor ?? 
        (isDark ? theme.scaffoldBackgroundColor : Colors.white);

    return MouseRegion(
      onEnter: (_) => setState(() => _isHovered = true),
      onExit: (_) => setState(() => _isHovered = false),
      child: GestureDetector(
        onTapDown: (_) {
          if (widget.onPressed != null) _controller.forward();
        },
        onTapUp: (_) {
          if (widget.onPressed != null) {
            _controller.reverse();
            widget.onPressed!();
          }
        },
        onTapCancel: () {
          if (widget.onPressed != null) _controller.reverse();
        },
        child: AnimatedBuilder(
          animation: _scaleAnimation,
          builder: (context, child) {
            return Transform.scale(
              scale: _scaleAnimation.value,
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 150),
                height: widget.height,
                decoration: BoxDecoration(
                  color: widget.onPressed == null
                      ? bg.withOpacity(0.4)
                      : (_isHovered ? bg.withOpacity(0.9) : bg),
                  borderRadius: BorderRadius.circular(widget.borderRadius),
                  boxShadow: widget.onPressed == null
                      ? []
                      : [
                          BoxShadow(
                            color: bg.withOpacity(isDark ? 0.15 : 0.08),
                            blurRadius: 16,
                            offset: const Offset(0, 4),
                          )
                        ],
                ),
                alignment: Alignment.center,
                child: child,
              ),
            );
          },
          child: DefaultTextStyle(
            style: TextStyle(
              color: fg,
              fontSize: 16,
              fontWeight: FontWeight.bold,
              letterSpacing: -0.2,
            ),
            child: widget.child,
          ),
        ),
      ),
    );
  }
}
