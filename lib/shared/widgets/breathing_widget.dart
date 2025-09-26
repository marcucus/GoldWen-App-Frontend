import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/services/accessibility_service.dart';
import '../../core/theme/app_theme.dart';

/// Breathing animation widget for calm idle states
/// Implements subtle scaling animation that respects accessibility settings
class BreathingWidget extends StatefulWidget {
  final Widget child;
  final Duration duration;
  final double minScale;
  final double maxScale;
  final bool enabled;
  final Curve curve;

  const BreathingWidget({
    super.key,
    required this.child,
    this.duration = const Duration(milliseconds: 3000),
    this.minScale = 0.98,
    this.maxScale = 1.02,
    this.enabled = true,
    this.curve = Curves.easeInOut,
  });

  @override
  State<BreathingWidget> createState() => _BreathingWidgetState();
}

class _BreathingWidgetState extends State<BreathingWidget>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();
    
    final accessibilityService = context.read<AccessibilityService>();
    
    _controller = AnimationController(
      duration: accessibilityService.getAnimationDuration(widget.duration),
      vsync: this,
    );

    _scaleAnimation = Tween<double>(
      begin: widget.minScale,
      end: widget.maxScale,
    ).animate(CurvedAnimation(
      parent: _controller,
      curve: widget.curve,
    ));

    _startBreathing();
  }

  void _startBreathing() {
    final accessibilityService = context.read<AccessibilityService>();
    
    if (widget.enabled && !accessibilityService.reducedMotion) {
      _controller.repeat(reverse: true);
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final accessibilityService = context.watch<AccessibilityService>();
    
    if (!widget.enabled || accessibilityService.reducedMotion) {
      return widget.child;
    }

    return AnimatedBuilder(
      animation: _scaleAnimation,
      builder: (context, child) {
        return Transform.scale(
          scale: _scaleAnimation.value,
          child: widget.child,
        );
      },
    );
  }
}

/// Pulsing glow effect for important elements
class PulsingGlow extends StatefulWidget {
  final Widget child;
  final Color glowColor;
  final double maxGlowRadius;
  final Duration duration;
  final bool enabled;

  const PulsingGlow({
    super.key,
    required this.child,
    this.glowColor = AppColors.primaryGold,
    this.maxGlowRadius = 8.0,
    this.duration = const Duration(milliseconds: 2000),
    this.enabled = true,
  });

  @override
  State<PulsingGlow> createState() => _PulsingGlowState();
}

class _PulsingGlowState extends State<PulsingGlow>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _glowAnimation;

  @override
  void initState() {
    super.initState();
    
    final accessibilityService = context.read<AccessibilityService>();
    
    _controller = AnimationController(
      duration: accessibilityService.getAnimationDuration(widget.duration),
      vsync: this,
    );

    _glowAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _controller,
      curve: Curves.easeInOut,
    ));

    _startPulsing();
  }

  void _startPulsing() {
    final accessibilityService = context.read<AccessibilityService>();
    
    if (widget.enabled && !accessibilityService.reducedMotion) {
      _controller.repeat(reverse: true);
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final accessibilityService = context.watch<AccessibilityService>();
    
    if (!widget.enabled || accessibilityService.reducedMotion) {
      return widget.child;
    }

    return AnimatedBuilder(
      animation: _glowAnimation,
      builder: (context, child) {
        return Container(
          decoration: BoxDecoration(
            boxShadow: [
              BoxShadow(
                color: widget.glowColor.withOpacity(0.3 * _glowAnimation.value),
                blurRadius: widget.maxGlowRadius * _glowAnimation.value,
                spreadRadius: (widget.maxGlowRadius * 0.5) * _glowAnimation.value,
              ),
            ],
          ),
          child: widget.child,
        );
      },
    );
  }
}

/// Gentle floating animation for floating elements
class FloatingWidget extends StatefulWidget {
  final Widget child;
  final double amplitude;
  final Duration duration;
  final bool enabled;
  final Axis direction;

  const FloatingWidget({
    super.key,
    required this.child,
    this.amplitude = 4.0,
    this.duration = const Duration(milliseconds: 4000),
    this.enabled = true,
    this.direction = Axis.vertical,
  });

  @override
  State<FloatingWidget> createState() => _FloatingWidgetState();
}

class _FloatingWidgetState extends State<FloatingWidget>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _floatAnimation;

  @override
  void initState() {
    super.initState();
    
    final accessibilityService = context.read<AccessibilityService>();
    
    _controller = AnimationController(
      duration: accessibilityService.getAnimationDuration(widget.duration),
      vsync: this,
    );

    _floatAnimation = Tween<double>(
      begin: -widget.amplitude,
      end: widget.amplitude,
    ).animate(CurvedAnimation(
      parent: _controller,
      curve: Curves.easeInOut,
    ));

    _startFloating();
  }

  void _startFloating() {
    final accessibilityService = context.read<AccessibilityService>();
    
    if (widget.enabled && !accessibilityService.reducedMotion) {
      _controller.repeat(reverse: true);
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final accessibilityService = context.watch<AccessibilityService>();
    
    if (!widget.enabled || accessibilityService.reducedMotion) {
      return widget.child;
    }

    return AnimatedBuilder(
      animation: _floatAnimation,
      builder: (context, child) {
        return Transform.translate(
          offset: widget.direction == Axis.vertical
              ? Offset(0, _floatAnimation.value)
              : Offset(_floatAnimation.value, 0),
          child: widget.child,
        );
      },
    );
  }
}

/// Gentle rotation animation for decorative elements
class GentleRotation extends StatefulWidget {
  final Widget child;
  final double maxRotation;
  final Duration duration;
  final bool enabled;
  final bool continuous;

  const GentleRotation({
    super.key,
    required this.child,
    this.maxRotation = 0.05, // ~3 degrees
    this.duration = const Duration(milliseconds: 8000),
    this.enabled = true,
    this.continuous = false,
  });

  @override
  State<GentleRotation> createState() => _GentleRotationState();
}

class _GentleRotationState extends State<GentleRotation>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _rotationAnimation;

  @override
  void initState() {
    super.initState();
    
    final accessibilityService = context.read<AccessibilityService>();
    
    _controller = AnimationController(
      duration: accessibilityService.getAnimationDuration(widget.duration),
      vsync: this,
    );

    _rotationAnimation = Tween<double>(
      begin: widget.continuous ? 0.0 : -widget.maxRotation,
      end: widget.continuous ? 1.0 : widget.maxRotation,
    ).animate(CurvedAnimation(
      parent: _controller,
      curve: widget.continuous ? Curves.linear : Curves.easeInOut,
    ));

    _startRotation();
  }

  void _startRotation() {
    final accessibilityService = context.read<AccessibilityService>();
    
    if (widget.enabled && !accessibilityService.reducedMotion) {
      if (widget.continuous) {
        _controller.repeat();
      } else {
        _controller.repeat(reverse: true);
      }
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final accessibilityService = context.watch<AccessibilityService>();
    
    if (!widget.enabled || accessibilityService.reducedMotion) {
      return widget.child;
    }

    return AnimatedBuilder(
      animation: _rotationAnimation,
      builder: (context, child) {
        return Transform.rotate(
          angle: widget.continuous 
              ? _rotationAnimation.value * 2 * 3.14159
              : _rotationAnimation.value,
          child: widget.child,
        );
      },
    );
  }
}

/// Success celebration animation
class SuccessRipple extends StatefulWidget {
  final Widget child;
  final bool trigger;
  final Color rippleColor;
  final Duration duration;

  const SuccessRipple({
    super.key,
    required this.child,
    required this.trigger,
    this.rippleColor = AppColors.successGreen,
    this.duration = const Duration(milliseconds: 800),
  });

  @override
  State<SuccessRipple> createState() => _SuccessRippleState();
}

class _SuccessRippleState extends State<SuccessRipple>
    with TickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _scaleAnimation;
  late Animation<double> _opacityAnimation;

  @override
  void initState() {
    super.initState();
    
    final accessibilityService = context.read<AccessibilityService>();
    
    _controller = AnimationController(
      duration: accessibilityService.getAnimationDuration(widget.duration),
      vsync: this,
    );

    _scaleAnimation = Tween<double>(
      begin: 0.0,
      end: 2.0,
    ).animate(CurvedAnimation(
      parent: _controller,
      curve: Curves.easeOut,
    ));

    _opacityAnimation = Tween<double>(
      begin: 0.8,
      end: 0.0,
    ).animate(CurvedAnimation(
      parent: _controller,
      curve: Curves.easeOut,
    ));
  }

  @override
  void didUpdateWidget(SuccessRipple oldWidget) {
    super.didUpdateWidget(oldWidget);
    
    if (widget.trigger && !oldWidget.trigger) {
      final accessibilityService = context.read<AccessibilityService>();
      if (!accessibilityService.reducedMotion) {
        _controller.reset();
        _controller.forward();
      }
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      alignment: Alignment.center,
      children: [
        widget.child,
        AnimatedBuilder(
          animation: Listenable.merge([_scaleAnimation, _opacityAnimation]),
          builder: (context, child) {
            return Transform.scale(
              scale: _scaleAnimation.value,
              child: Container(
                width: 80,
                height: 80,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: widget.rippleColor.withOpacity(_opacityAnimation.value),
                    width: 2,
                  ),
                ),
              ),
            );
          },
        ),
      ],
    );
  }
}