import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import '../../core/services/accessibility_service.dart';
import '../../core/theme/app_theme.dart';

/// Service for showing success feedback animations and messages
class SuccessFeedbackService {
  static OverlayEntry? _overlayEntry;

  /// Show a success message with animation
  static void showSuccess(
    BuildContext context, {
    required String message,
    IconData icon = Icons.check_circle,
    Color color = AppColors.successGreen,
    Duration duration = const Duration(seconds: 2),
  }) {
    _removeExistingOverlay();

    final overlay = Overlay.of(context);
    _overlayEntry = OverlayEntry(
      builder: (context) => SuccessOverlay(
        message: message,
        icon: icon,
        color: color,
        duration: duration,
        onComplete: _removeExistingOverlay,
      ),
    );

    overlay.insert(_overlayEntry!);
    HapticFeedback.lightImpact();
  }

  /// Show a floating success notification
  static void showFloatingSuccess(
    BuildContext context, {
    required String message,
    IconData icon = Icons.favorite,
    Color color = AppColors.primaryGold,
    Duration duration = const Duration(seconds: 1),
  }) {
    _removeExistingOverlay();

    final overlay = Overlay.of(context);
    _overlayEntry = OverlayEntry(
      builder: (context) => FloatingSuccessNotification(
        message: message,
        icon: icon,
        color: color,
        duration: duration,
        onComplete: _removeExistingOverlay,
      ),
    );

    overlay.insert(_overlayEntry!);
    HapticFeedback.mediumImpact();
  }

  static void _removeExistingOverlay() {
    _overlayEntry?.remove();
    _overlayEntry = null;
  }
}

/// Success overlay widget with sophisticated animations
class SuccessOverlay extends StatefulWidget {
  final String message;
  final IconData icon;
  final Color color;
  final Duration duration;
  final VoidCallback onComplete;

  const SuccessOverlay({
    super.key,
    required this.message,
    required this.icon,
    required this.color,
    required this.duration,
    required this.onComplete,
  });

  @override
  State<SuccessOverlay> createState() => _SuccessOverlayState();
}

class _SuccessOverlayState extends State<SuccessOverlay>
    with TickerProviderStateMixin {
  late AnimationController _controller;
  late AnimationController _pulseController;
  
  late Animation<double> _scaleAnimation;
  late Animation<double> _fadeAnimation;
  late Animation<double> _pulseAnimation;

  @override
  void initState() {
    super.initState();
    
    final accessibilityService = context.read<AccessibilityService>();
    
    _controller = AnimationController(
      duration: accessibilityService.getAnimationDuration(
        const Duration(milliseconds: 800)
      ),
      vsync: this,
    );
    
    _pulseController = AnimationController(
      duration: accessibilityService.getAnimationDuration(
        const Duration(milliseconds: 400)
      ),
      vsync: this,
    );

    _scaleAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _controller,
      curve: Curves.elasticOut,
    ));

    _fadeAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _controller,
      curve: const Interval(0.0, 0.3, curve: Curves.easeOut),
    ));

    _pulseAnimation = Tween<double>(
      begin: 1.0,
      end: 1.2,
    ).animate(CurvedAnimation(
      parent: _pulseController,
      curve: Curves.easeInOut,
    ));

    _startAnimations();
  }

  void _startAnimations() async {
    final accessibilityService = context.read<AccessibilityService>();
    
    if (!accessibilityService.reducedMotion) {
      await _controller.forward();
      _pulseController.repeat(reverse: true);
      
      await Future.delayed(widget.duration);
      
      _pulseController.stop();
      await _controller.reverse();
    } else {
      await Future.delayed(widget.duration);
    }
    
    widget.onComplete();
  }

  @override
  void dispose() {
    _controller.dispose();
    _pulseController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final accessibilityService = context.watch<AccessibilityService>();
    
    return Material(
      color: Colors.transparent,
      child: Center(
        child: AnimatedBuilder(
          animation: Listenable.merge([
            _scaleAnimation,
            _fadeAnimation,
            _pulseAnimation,
          ]),
          builder: (context, child) {
            return Transform.scale(
              scale: accessibilityService.reducedMotion 
                  ? 1.0 
                  : _scaleAnimation.value * _pulseAnimation.value,
              child: Opacity(
                opacity: accessibilityService.reducedMotion 
                    ? 1.0 
                    : _fadeAnimation.value,
                child: Container(
                  padding: const EdgeInsets.all(24),
                  decoration: BoxDecoration(
                    color: AppColors.cardBackground,
                    borderRadius: BorderRadius.circular(20),
                    boxShadow: [
                      BoxShadow(
                        color: widget.color.withOpacity(0.3),
                        blurRadius: 20,
                        spreadRadius: 5,
                      ),
                      const BoxShadow(
                        color: AppColors.shadowMedium,
                        blurRadius: 15,
                        offset: Offset(0, 5),
                      ),
                    ],
                  ),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: widget.color.withOpacity(0.1),
                          shape: BoxShape.circle,
                        ),
                        child: Icon(
                          widget.icon,
                          size: 48,
                          color: widget.color,
                        ),
                      ),
                      const SizedBox(height: 16),
                      Text(
                        widget.message,
                        style: theme.textTheme.headlineSmall?.copyWith(
                          color: AppColors.textDark,
                          fontWeight: FontWeight.bold,
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ],
                  ),
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}

/// Floating success notification for quick actions
class FloatingSuccessNotification extends StatefulWidget {
  final String message;
  final IconData icon;
  final Color color;
  final Duration duration;
  final VoidCallback onComplete;

  const FloatingSuccessNotification({
    super.key,
    required this.message,
    required this.icon,
    required this.color,
    required this.duration,
    required this.onComplete,
  });

  @override
  State<FloatingSuccessNotification> createState() => _FloatingSuccessNotificationState();
}

class _FloatingSuccessNotificationState extends State<FloatingSuccessNotification>
    with TickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<Offset> _slideAnimation;
  late Animation<double> _fadeAnimation;

  @override
  void initState() {
    super.initState();
    
    final accessibilityService = context.read<AccessibilityService>();
    
    _controller = AnimationController(
      duration: accessibilityService.getAnimationDuration(
        const Duration(milliseconds: 600)
      ),
      vsync: this,
    );

    _slideAnimation = Tween<Offset>(
      begin: const Offset(0, -1),
      end: Offset.zero,
    ).animate(CurvedAnimation(
      parent: _controller,
      curve: Curves.elasticOut,
    ));

    _fadeAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _controller,
      curve: Curves.easeOut,
    ));

    _startAnimation();
  }

  void _startAnimation() async {
    final accessibilityService = context.read<AccessibilityService>();
    
    if (!accessibilityService.reducedMotion) {
      await _controller.forward();
      await Future.delayed(widget.duration);
      await _controller.reverse();
    } else {
      await Future.delayed(widget.duration);
    }
    
    widget.onComplete();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final accessibilityService = context.watch<AccessibilityService>();
    
    return Positioned(
      top: 80,
      left: 16,
      right: 16,
      child: AnimatedBuilder(
        animation: Listenable.merge([_slideAnimation, _fadeAnimation]),
        builder: (context, child) {
          return SlideTransition(
            position: accessibilityService.reducedMotion 
                ? const AlwaysStoppedAnimation(Offset.zero)
                : _slideAnimation,
            child: FadeTransition(
              opacity: accessibilityService.reducedMotion 
                  ? const AlwaysStoppedAnimation(1.0)
                  : _fadeAnimation,
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 20,
                  vertical: 16,
                ),
                decoration: BoxDecoration(
                  color: AppColors.cardBackground,
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: [
                    BoxShadow(
                      color: widget.color.withOpacity(0.2),
                      blurRadius: 15,
                      spreadRadius: 2,
                    ),
                    const BoxShadow(
                      color: AppColors.shadowMedium,
                      blurRadius: 10,
                      offset: Offset(0, 3),
                    ),
                  ],
                  border: Border.all(
                    color: widget.color.withOpacity(0.3),
                    width: 1,
                  ),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: widget.color.withOpacity(0.1),
                        shape: BoxShape.circle,
                      ),
                      child: Icon(
                        widget.icon,
                        size: 20,
                        color: widget.color,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Flexible(
                      child: Text(
                        widget.message,
                        style: theme.textTheme.bodyMedium?.copyWith(
                          color: AppColors.textDark,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}

/// Enhanced snackbar with animations
class EnhancedSnackBar extends SnackBar {
  EnhancedSnackBar({
    Key? key,
    required String message,
    IconData? icon,
    Color? backgroundColor,
    Duration duration = const Duration(seconds: 3),
    SnackBarAction? action,
  }) : super(
          key: key,
          content: Row(
            children: [
              if (icon != null) ...[
                Icon(
                  icon,
                  color: AppColors.textLight,
                  size: 20,
                ),
                const SizedBox(width: 12),
              ],
              Expanded(
                child: Text(
                  message,
                  style: const TextStyle(
                    color: AppColors.textLight,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
            ],
          ),
          backgroundColor: backgroundColor ?? AppColors.primaryGold,
          duration: duration,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          margin: const EdgeInsets.all(16),
          action: action,
        );

  /// Success snackbar variant
  static EnhancedSnackBar success({
    required String message,
    Duration duration = const Duration(seconds: 3),
  }) {
    return EnhancedSnackBar(
      message: message,
      icon: Icons.check_circle,
      backgroundColor: AppColors.successGreen,
      duration: duration,
    );
  }

  /// Error snackbar variant
  static EnhancedSnackBar error({
    required String message,
    Duration duration = const Duration(seconds: 4),
  }) {
    return EnhancedSnackBar(
      message: message,
      icon: Icons.error,
      backgroundColor: AppColors.errorRed,
      duration: duration,
    );
  }

  /// Info snackbar variant
  static EnhancedSnackBar info({
    required String message,
    Duration duration = const Duration(seconds: 3),
  }) {
    return EnhancedSnackBar(
      message: message,
      icon: Icons.info,
      backgroundColor: AppColors.infoBlue,
      duration: duration,
    );
  }
}