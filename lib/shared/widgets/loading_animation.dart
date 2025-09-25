import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/theme/app_theme.dart';
import '../../core/services/accessibility_service.dart';

class LoadingAnimation extends StatefulWidget {
  final String? message;
  final double size;
  final bool showProgressIndicator;
  final String? semanticLabel;

  const LoadingAnimation({
    super.key,
    this.message,
    this.size = 50,
    this.showProgressIndicator = true,
    this.semanticLabel,
  });

  @override
  State<LoadingAnimation> createState() => _LoadingAnimationState();
}

class _LoadingAnimationState extends State<LoadingAnimation>
    with TickerProviderStateMixin {
  late AnimationController _controller;
  late AnimationController _pulseController;
  late Animation<double> _rotationAnimation;
  late Animation<double> _pulseAnimation;

  @override
  void initState() {
    super.initState();
    
    _controller = AnimationController(
      duration: const Duration(milliseconds: 1200),
      vsync: this,
    );
    
    _pulseController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );

    _rotationAnimation = Tween<double>(
      begin: 0,
      end: 1,
    ).animate(CurvedAnimation(
      parent: _controller,
      curve: Curves.linear,
    ));

    _pulseAnimation = Tween<double>(
      begin: 0.8,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _pulseController,
      curve: Curves.easeInOut,
    ));

    _startAnimations();
  }

  void _startAnimations() {
    final accessibilityService = context.read<AccessibilityService>();
    
    if (!accessibilityService.reducedMotion) {
      _controller.repeat();
      _pulseController.repeat(reverse: true);
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    _pulseController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final accessibilityService = context.watch<AccessibilityService>();
    
    return Semantics(
      label: widget.semanticLabel ?? widget.message ?? 'Chargement en cours',
      liveRegion: true,
      child: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (widget.showProgressIndicator)
              _buildProgressIndicator(accessibilityService),
            if (widget.message != null) ...[
              const SizedBox(height: AppSpacing.md),
              _buildMessage(accessibilityService),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildProgressIndicator(AccessibilityService accessibilityService) {
    if (accessibilityService.reducedMotion) {
      return _buildStaticIndicator();
    }

    return AnimatedBuilder(
      animation: Listenable.merge([_rotationAnimation, _pulseAnimation]),
      builder: (context, child) {
        return Transform.rotate(
          angle: _rotationAnimation.value * 2 * 3.14159,
          child: Transform.scale(
            scale: _pulseAnimation.value,
            child: SizedBox(
              width: widget.size,
              height: widget.size,
              child: CircularProgressIndicator(
                valueColor: const AlwaysStoppedAnimation<Color>(AppColors.primaryGold),
                strokeWidth: widget.size <= 30 ? 2 : 3,
                backgroundColor: AppColors.primaryGold.withOpacity(0.2),
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildStaticIndicator() {
    return SizedBox(
      width: widget.size,
      height: widget.size,
      child: CircularProgressIndicator(
        valueColor: const AlwaysStoppedAnimation<Color>(AppColors.primaryGold),
        strokeWidth: widget.size <= 30 ? 2 : 3,
        backgroundColor: AppColors.primaryGold.withOpacity(0.2),
      ),
    );
  }

  Widget _buildMessage(AccessibilityService accessibilityService) {
    return AnimatedBuilder(
      animation: _pulseAnimation,
      builder: (context, child) {
        return Transform.scale(
          scale: accessibilityService.reducedMotion ? 1.0 : _pulseAnimation.value,
          child: Text(
            widget.message!,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              color: AppColors.textMuted,
              fontSize: Theme.of(context).textTheme.bodyMedium!.fontSize! * 
                  accessibilityService.textScaleFactor,
            ),
            textAlign: TextAlign.center,
          ),
        );
      },
    );
  }
}

/// Shimmer loading animation with accessibility support
class ShimmerLoading extends StatefulWidget {
  final Widget child;
  final Color baseColor;
  final Color highlightColor;
  final bool enabled;

  const ShimmerLoading({
    super.key,
    required this.child,
    this.baseColor = const Color(0xFFE0E0E0),
    this.highlightColor = const Color(0xFFF5F5F5),
    this.enabled = true,
  });

  @override
  State<ShimmerLoading> createState() => _ShimmerLoadingState();
}

class _ShimmerLoadingState extends State<ShimmerLoading>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _animation;

  @override
  void initState() {
    super.initState();
    
    _controller = AnimationController(
      duration: const Duration(milliseconds: 1500),
      vsync: this,
    );
    
    _animation = Tween<double>(
      begin: -2.0,
      end: 2.0,
    ).animate(CurvedAnimation(
      parent: _controller,
      curve: Curves.easeInOut,
    ));

    _startAnimation();
  }

  void _startAnimation() {
    final accessibilityService = context.read<AccessibilityService>();
    
    if (!accessibilityService.reducedMotion && widget.enabled) {
      _controller.repeat();
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
    
    if (accessibilityService.reducedMotion || !widget.enabled) {
      return Container(
        color: widget.baseColor,
        child: widget.child,
      );
    }

    return AnimatedBuilder(
      animation: _animation,
      builder: (context, child) {
        return ShaderMask(
          blendMode: BlendMode.srcATop,
          shaderCallback: (bounds) {
            return LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                widget.baseColor,
                widget.highlightColor,
                widget.baseColor,
              ],
              stops: [
                0.0,
                0.5,
                1.0,
              ],
              transform: GradientRotation(_animation.value),
            ).createShader(bounds);
          },
          child: widget.child,
        );
      },
    );
  }
}

/// Skeleton loader for profile cards
class ProfileCardSkeleton extends StatelessWidget {
  final double height;
  final double width;

  const ProfileCardSkeleton({
    super.key,
    this.height = 400,
    this.width = double.infinity,
  });

  @override
  Widget build(BuildContext context) {
    return Semantics(
      label: 'Chargement du profil',
      child: ShimmerLoading(
        child: Container(
          height: height,
          width: width,
          decoration: BoxDecoration(
            color: AppColors.backgroundGrey,
            borderRadius: BorderRadius.circular(24),
          ),
          child: Column(
            children: [
              // Image area
              Expanded(
                flex: 3,
                child: Container(
                  decoration: const BoxDecoration(
                    color: AppColors.backgroundGrey,
                    borderRadius: BorderRadius.only(
                      topLeft: Radius.circular(24),
                      topRight: Radius.circular(24),
                    ),
                  ),
                ),
              ),
              // Content area
              Expanded(
                flex: 1,
                child: Padding(
                  padding: const EdgeInsets.all(AppSpacing.lg),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Name line
                      Container(
                        height: 24,
                        width: 200,
                        decoration: BoxDecoration(
                          color: AppColors.backgroundGrey,
                          borderRadius: BorderRadius.circular(4),
                        ),
                      ),
                      const SizedBox(height: AppSpacing.sm),
                      // Bio lines
                      Container(
                        height: 16,
                        width: double.infinity,
                        decoration: BoxDecoration(
                          color: AppColors.backgroundGrey,
                          borderRadius: BorderRadius.circular(4),
                        ),
                      ),
                      const SizedBox(height: 4),
                      Container(
                        height: 16,
                        width: 150,
                        decoration: BoxDecoration(
                          color: AppColors.backgroundGrey,
                          borderRadius: BorderRadius.circular(4),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}