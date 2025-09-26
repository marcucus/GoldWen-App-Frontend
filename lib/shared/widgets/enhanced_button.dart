import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import '../../core/services/accessibility_service.dart';
import '../../core/theme/app_theme.dart';
import 'animated_pressable.dart';

/// Enhanced button with sophisticated micro-interactions following Calm Technology principles
class EnhancedButton extends StatefulWidget {
  final String text;
  final VoidCallback? onPressed;
  final IconData? icon;
  final bool isPrimary;
  final bool isLoading;
  final EdgeInsetsGeometry? padding;
  final double borderRadius;
  final bool enableFloatingEffect;
  final bool enablePulseEffect;

  const EnhancedButton({
    super.key,
    required this.text,
    this.onPressed,
    this.icon,
    this.isPrimary = true,
    this.isLoading = false,
    this.padding,
    this.borderRadius = 12.0,
    this.enableFloatingEffect = true,
    this.enablePulseEffect = false,
  });

  @override
  State<EnhancedButton> createState() => _EnhancedButtonState();
}

class _EnhancedButtonState extends State<EnhancedButton>
    with TickerProviderStateMixin {
  late AnimationController _hoverController;
  late AnimationController _pulseController;
  late Animation<double> _hoverAnimation;
  late Animation<double> _pulseAnimation;
  
  bool _isHovered = false;

  @override
  void initState() {
    super.initState();
    
    final accessibilityService = context.read<AccessibilityService>();
    
    _hoverController = AnimationController(
      duration: accessibilityService.getAnimationDuration(
        const Duration(milliseconds: 200)
      ),
      vsync: this,
    );
    
    _pulseController = AnimationController(
      duration: accessibilityService.getAnimationDuration(
        const Duration(milliseconds: 1200)
      ),
      vsync: this,
    );

    _hoverAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _hoverController,
      curve: Curves.easeInOut,
    ));

    _pulseAnimation = Tween<double>(
      begin: 1.0,
      end: 1.05,
    ).animate(CurvedAnimation(
      parent: _pulseController,
      curve: Curves.easeInOut,
    ));

    if (widget.enablePulseEffect && !accessibilityService.reducedMotion) {
      _startPulseAnimation();
    }
  }

  void _startPulseAnimation() {
    _pulseController.repeat(reverse: true);
  }

  @override
  void dispose() {
    _hoverController.dispose();
    _pulseController.dispose();
    super.dispose();
  }

  void _onHover(bool isHovered) {
    if (widget.onPressed == null) return;
    
    setState(() => _isHovered = isHovered);
    
    final accessibilityService = context.read<AccessibilityService>();
    if (!accessibilityService.reducedMotion) {
      if (isHovered) {
        _hoverController.forward();
      } else {
        _hoverController.reverse();
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final accessibilityService = context.watch<AccessibilityService>();
    
    return AnimatedBuilder(
      animation: Listenable.merge([_hoverAnimation, _pulseAnimation]),
      builder: (context, child) {
        return Transform.scale(
          scale: widget.enablePulseEffect && !accessibilityService.reducedMotion
              ? _pulseAnimation.value
              : 1.0,
          child: Container(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(widget.borderRadius),
              boxShadow: widget.enableFloatingEffect && _isHovered
                  ? [
                      BoxShadow(
                        color: widget.isPrimary
                            ? AppColors.primaryGold.withOpacity(0.3)
                            : AppColors.shadowMedium,
                        blurRadius: 12.0 + (8.0 * _hoverAnimation.value),
                        offset: Offset(0, 4.0 + (2.0 * _hoverAnimation.value)),
                        spreadRadius: 1.0 * _hoverAnimation.value,
                      ),
                    ]
                  : null,
            ),
            child: AnimatedPressable(
              onPressed: widget.isLoading ? null : widget.onPressed,
              enableGlowEffect: true,
              glowColor: widget.isPrimary ? AppColors.primaryGold : AppColors.secondaryBeige,
              child: MouseRegion(
                onEnter: (_) => _onHover(true),
                onExit: (_) => _onHover(false),
                child: Container(
                  padding: widget.padding ?? const EdgeInsets.symmetric(
                    horizontal: 24.0,
                    vertical: 16.0,
                  ),
                  decoration: BoxDecoration(
                    gradient: widget.isPrimary
                        ? AppColors.primaryGradient
                        : null,
                    color: widget.isPrimary
                        ? null
                        : theme.colorScheme.surface,
                    border: widget.isPrimary
                        ? null
                        : Border.all(
                            color: AppColors.primaryGold.withOpacity(0.3),
                            width: 1.5,
                          ),
                    borderRadius: BorderRadius.circular(widget.borderRadius),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      if (widget.isLoading) ...[
                        SizedBox(
                          width: 16,
                          height: 16,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            valueColor: AlwaysStoppedAnimation<Color>(
                              widget.isPrimary
                                  ? AppColors.textLight
                                  : AppColors.primaryGold,
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                      ] else if (widget.icon != null) ...[
                        AnimatedRotation(
                          duration: const Duration(milliseconds: 200),
                          turns: _isHovered && !accessibilityService.reducedMotion ? 0.05 : 0.0,
                          child: Icon(
                            widget.icon,
                            color: widget.isPrimary
                                ? AppColors.textLight
                                : AppColors.primaryGold,
                            size: 18,
                          ),
                        ),
                        const SizedBox(width: 8),
                      ],
                      AnimatedDefaultTextStyle(
                        duration: const Duration(milliseconds: 200),
                        style: theme.textTheme.labelLarge!.copyWith(
                          color: widget.isPrimary
                              ? AppColors.textLight
                              : AppColors.primaryGold,
                          fontWeight: FontWeight.w600,
                          letterSpacing: _isHovered && !accessibilityService.reducedMotion
                              ? 0.8
                              : 0.5,
                        ),
                        child: Text(widget.text),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}

/// Floating Action Button with enhanced micro-interactions
class EnhancedFAB extends StatefulWidget {
  final VoidCallback? onPressed;
  final IconData icon;
  final String? tooltip;
  final bool mini;
  final Color? backgroundColor;

  const EnhancedFAB({
    super.key,
    required this.onPressed,
    required this.icon,
    this.tooltip,
    this.mini = false,
    this.backgroundColor,
  });

  @override
  State<EnhancedFAB> createState() => _EnhancedFABState();
}

class _EnhancedFABState extends State<EnhancedFAB>
    with TickerProviderStateMixin {
  late AnimationController _breathingController;
  late AnimationController _rotationController;
  late Animation<double> _breathingAnimation;
  late Animation<double> _rotationAnimation;

  @override
  void initState() {
    super.initState();
    
    final accessibilityService = context.read<AccessibilityService>();
    
    _breathingController = AnimationController(
      duration: accessibilityService.getAnimationDuration(
        const Duration(milliseconds: 2000)
      ),
      vsync: this,
    );
    
    _rotationController = AnimationController(
      duration: accessibilityService.getAnimationDuration(
        const Duration(milliseconds: 300)
      ),
      vsync: this,
    );

    _breathingAnimation = Tween<double>(
      begin: 1.0,
      end: 1.02,
    ).animate(CurvedAnimation(
      parent: _breathingController,
      curve: Curves.easeInOut,
    ));

    _rotationAnimation = Tween<double>(
      begin: 0.0,
      end: 0.25,
    ).animate(CurvedAnimation(
      parent: _rotationController,
      curve: Curves.elasticOut,
    ));

    if (!accessibilityService.reducedMotion) {
      _breathingController.repeat(reverse: true);
    }
  }

  @override
  void dispose() {
    _breathingController.dispose();
    _rotationController.dispose();
    super.dispose();
  }

  void _onPressed() {
    final accessibilityService = context.read<AccessibilityService>();
    
    if (!accessibilityService.reducedMotion) {
      _rotationController.reset();
      _rotationController.forward();
    }
    
    HapticFeedback.mediumImpact();
    widget.onPressed?.call();
  }

  @override
  Widget build(BuildContext context) {
    final accessibilityService = context.watch<AccessibilityService>();
    
    return AnimatedBuilder(
      animation: Listenable.merge([_breathingAnimation, _rotationAnimation]),
      builder: (context, child) {
        return Transform.scale(
          scale: accessibilityService.reducedMotion
              ? 1.0
              : _breathingAnimation.value,
          child: Transform.rotate(
            angle: accessibilityService.reducedMotion
                ? 0.0
                : _rotationAnimation.value * 2 * 3.14159,
            child: FloatingActionButton(
              onPressed: widget.onPressed != null ? _onPressed : null,
              tooltip: widget.tooltip,
              mini: widget.mini,
              backgroundColor: widget.backgroundColor ?? AppColors.primaryGold,
              foregroundColor: AppColors.textLight,
              elevation: 8,
              child: Icon(
                widget.icon,
                size: widget.mini ? 20 : 24,
              ),
            ),
          ),
        );
      },
    );
  }
}