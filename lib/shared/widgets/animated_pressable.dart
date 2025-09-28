import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import '../../core/services/accessibility_service.dart';
import '../../core/theme/app_theme.dart';

class AnimatedPressable extends StatefulWidget {
  final Widget child;
  final VoidCallback? onPressed;
  final double scaleWhenPressed;
  final Duration duration;
  final bool enableHapticFeedback;
  final bool enableScaleAnimation;
  final bool enableGlowEffect;
  final Color? glowColor;
  final double? shadowSpread;

  const AnimatedPressable({
    super.key,
    required this.child,
    this.onPressed,
    this.scaleWhenPressed = 0.95,
    this.duration = const Duration(milliseconds: 150),
    this.enableHapticFeedback = true,
    this.enableScaleAnimation = true,
    this.enableGlowEffect = false,
    this.glowColor,
    this.shadowSpread = 4.0,
  });

  @override
  State<AnimatedPressable> createState() => _AnimatedPressableState();
}

class _AnimatedPressableState extends State<AnimatedPressable>
    with TickerProviderStateMixin {
  late AnimationController _scaleController;
  late AnimationController _glowController;
  late AnimationController _rippleController;
  
  late Animation<double> _scaleAnimation;
  late Animation<double> _glowAnimation;
  late Animation<double> _rippleAnimation;

  bool _isPressed = false;

  @override
  void initState() {
    super.initState();
    
    // Initialize controllers with safe accessibility fallback
    Duration getAnimationDuration(Duration defaultDuration) {
      try {
        final accessibilityService = context.read<AccessibilityService>();
        return accessibilityService.getAnimationDuration(defaultDuration);
      } catch (e) {
        return defaultDuration;
      }
    }
    
    _scaleController = AnimationController(
      duration: getAnimationDuration(widget.duration),
      vsync: this,
    );
    
    _glowController = AnimationController(
      duration: getAnimationDuration(const Duration(milliseconds: 300)),
      vsync: this,
    );
    
    _rippleController = AnimationController(
      duration: getAnimationDuration(const Duration(milliseconds: 400)),
      vsync: this,
    );

    // Create animations
    _scaleAnimation = Tween<double>(
      begin: 1.0,
      end: widget.scaleWhenPressed,
    ).animate(CurvedAnimation(
      parent: _scaleController,
      curve: Curves.easeInOut,
    ));

    _glowAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _glowController,
      curve: Curves.easeOutCubic,
    ));

    _rippleAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _rippleController,
      curve: Curves.easeOut,
    ));
  }

  @override
  void dispose() {
    _scaleController.dispose();
    _glowController.dispose();
    _rippleController.dispose();
    super.dispose();
  }

  void _onTapDown(TapDownDetails details) {
    if (widget.onPressed == null) return;
    
    setState(() => _isPressed = true);
    
    // Safe accessibility service access
    bool reducedMotion = false;
    try {
      final accessibilityService = context.read<AccessibilityService>();
      reducedMotion = accessibilityService.reducedMotion;
    } catch (e) {
      reducedMotion = false;
    }
    
    if (widget.enableScaleAnimation && !reducedMotion) {
      _scaleController.forward();
    }
    
    if (widget.enableGlowEffect && !reducedMotion) {
      _glowController.forward();
    }
  }

  void _onTapUp(TapUpDetails details) {
    if (widget.onPressed == null) return;
    
    _resetAnimations();
    
    // Add haptic feedback
    if (widget.enableHapticFeedback) {
      HapticFeedback.lightImpact();
    }
    
    // Trigger ripple effect
    bool reducedMotion = false;
    try {
      final accessibilityService = context.read<AccessibilityService>();
      reducedMotion = accessibilityService.reducedMotion;
    } catch (e) {
      reducedMotion = false;
    }
    
    if (!reducedMotion) {
      _rippleController.reset();
      _rippleController.forward();
    }
  }

  void _onTapCancel() {
    if (widget.onPressed == null) return;
    _resetAnimations();
  }

  void _resetAnimations() {
    setState(() => _isPressed = false);
    _scaleController.reverse();
    _glowController.reverse();
  }

  @override
  Widget build(BuildContext context) {
    // Safe accessibility service access
    bool reducedMotion = false;
    try {
      final accessibilityService = context.watch<AccessibilityService>();
      reducedMotion = accessibilityService.reducedMotion;
    } catch (e) {
      reducedMotion = false;
    }
    
    return GestureDetector(
      onTapDown: _onTapDown,
      onTapUp: _onTapUp,
      onTapCancel: _onTapCancel,
      onTap: widget.onPressed,
      child: AnimatedBuilder(
        animation: Listenable.merge([
          _scaleAnimation,
          _glowAnimation,
          _rippleAnimation,
        ]),
        builder: (context, child) {
          Widget content = widget.child;
          
          // Apply scale animation
          if (widget.enableScaleAnimation && !reducedMotion) {
            content = Transform.scale(
              scale: _scaleAnimation.value,
              child: content,
            );
          }
          
          // Apply glow effect
          if (widget.enableGlowEffect && !reducedMotion) {
            content = Container(
              decoration: BoxDecoration(
                boxShadow: [
                  BoxShadow(
                    color: (widget.glowColor ?? AppColors.primaryGold)
                        .withOpacity(0.3 * _glowAnimation.value),
                    blurRadius: (widget.shadowSpread ?? 4.0) * _glowAnimation.value,
                    spreadRadius: (widget.shadowSpread ?? 4.0) * _glowAnimation.value * 0.5,
                  ),
                ],
              ),
              child: content,
            );
          }
          
          // Apply ripple effect
          if (_rippleAnimation.value > 0 && !reducedMotion) {
            content = Stack(
              alignment: Alignment.center,
              children: [
                content,
                Positioned.fill(
                  child: Container(
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: (widget.glowColor ?? AppColors.primaryGold)
                            .withOpacity(0.6 * (1.0 - _rippleAnimation.value)),
                        width: 2.0,
                      ),
                    ),
                    transform: Matrix4.identity()
                      ..scale(0.5 + (_rippleAnimation.value * 0.5)),
                  ),
                ),
              ],
            );
          }
          
          return content;
        },
      ),
    );
  }
}