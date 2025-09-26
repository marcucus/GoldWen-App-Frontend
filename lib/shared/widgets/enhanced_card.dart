import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import '../../core/services/accessibility_service.dart';
import '../../core/theme/app_theme.dart';
import 'animated_pressable.dart';

/// Enhanced card widget with sophisticated hover effects and progressive disclosure
class EnhancedCard extends StatefulWidget {
  final Widget child;
  final VoidCallback? onTap;
  final EdgeInsetsGeometry? padding;
  final EdgeInsetsGeometry? margin;
  final double borderRadius;
  final bool enableHoverEffect;
  final bool enableParallax;
  final bool enableGlow;
  final double? elevation;
  final Color? backgroundColor;

  const EnhancedCard({
    super.key,
    required this.child,
    this.onTap,
    this.padding,
    this.margin,
    this.borderRadius = 16.0,
    this.enableHoverEffect = true,
    this.enableParallax = false,
    this.enableGlow = false,
    this.elevation,
    this.backgroundColor,
  });

  @override
  State<EnhancedCard> createState() => _EnhancedCardState();
}

class _EnhancedCardState extends State<EnhancedCard>
    with TickerProviderStateMixin {
  late AnimationController _hoverController;
  late AnimationController _parallaxController;
  late Animation<double> _elevationAnimation;
  late Animation<double> _scaleAnimation;
  late Animation<Offset> _parallaxAnimation;

  bool _isHovered = false;
  Offset _pointerPosition = Offset.zero;

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
    
    _parallaxController = AnimationController(
      duration: accessibilityService.getAnimationDuration(
        const Duration(milliseconds: 100)
      ),
      vsync: this,
    );

    _elevationAnimation = Tween<double>(
      begin: widget.elevation ?? 2.0,
      end: (widget.elevation ?? 2.0) + 8.0,
    ).animate(CurvedAnimation(
      parent: _hoverController,
      curve: Curves.easeOut,
    ));

    _scaleAnimation = Tween<double>(
      begin: 1.0,
      end: 1.02,
    ).animate(CurvedAnimation(
      parent: _hoverController,
      curve: Curves.easeOut,
    ));

    _parallaxAnimation = Tween<Offset>(
      begin: Offset.zero,
      end: const Offset(0.02, 0.02),
    ).animate(CurvedAnimation(
      parent: _parallaxController,
      curve: Curves.easeOut,
    ));
  }

  @override
  void dispose() {
    _hoverController.dispose();
    _parallaxController.dispose();
    super.dispose();
  }

  void _onHover(bool isHovered) {
    setState(() => _isHovered = isHovered);
    
    final accessibilityService = context.read<AccessibilityService>();
    if (!accessibilityService.reducedMotion && widget.enableHoverEffect) {
      if (isHovered) {
        _hoverController.forward();
      } else {
        _hoverController.reverse();
      }
    }
  }

  void _onPointerMove(PointerEvent details, Size size) {
    if (!widget.enableParallax) return;
    
    final accessibilityService = context.read<AccessibilityService>();
    if (accessibilityService.reducedMotion) return;

    setState(() {
      _pointerPosition = Offset(
        (details.localPosition.dx - size.width / 2) / size.width,
        (details.localPosition.dy - size.height / 2) / size.height,
      );
    });
    
    _parallaxController.forward();
  }

  void _onPointerExit() {
    if (!widget.enableParallax) return;
    
    final accessibilityService = context.read<AccessibilityService>();
    if (accessibilityService.reducedMotion) return;

    setState(() => _pointerPosition = Offset.zero);
    _parallaxController.reverse();
  }

  @override
  Widget build(BuildContext context) {
    final accessibilityService = context.watch<AccessibilityService>();
    
    return AnimatedBuilder(
      animation: Listenable.merge([
        _hoverController,
        _parallaxController,
      ]),
      builder: (context, child) {
        return Container(
          margin: widget.margin,
          child: Transform.scale(
            scale: accessibilityService.reducedMotion 
                ? 1.0 
                : _scaleAnimation.value,
            child: Transform.translate(
              offset: widget.enableParallax && !accessibilityService.reducedMotion
                  ? Offset(
                      _pointerPosition.dx * 10,
                      _pointerPosition.dy * 10,
                    )
                  : Offset.zero,
              child: Container(
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(widget.borderRadius),
                  boxShadow: [
                    if (widget.enableGlow && _isHovered)
                      BoxShadow(
                        color: AppColors.primaryGold.withOpacity(0.2),
                        blurRadius: 15.0,
                        spreadRadius: 2.0,
                      ),
                    BoxShadow(
                      color: AppColors.shadowMedium,
                      blurRadius: _elevationAnimation.value,
                      offset: Offset(0, _elevationAnimation.value / 2),
                    ),
                  ],
                ),
                child: MouseRegion(
                  onEnter: (_) => _onHover(true),
                  onExit: (_) {
                    _onHover(false);
                    _onPointerExit();
                  },
                  child: Listener(
                    onPointerMove: (event) {
                      final RenderBox renderBox = context.findRenderObject() as RenderBox;
                      _onPointerMove(event, renderBox.size);
                    },
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 200),
                      curve: Curves.easeOut,
                      padding: widget.padding,
                      decoration: BoxDecoration(
                        color: widget.backgroundColor ?? AppColors.cardBackground,
                        borderRadius: BorderRadius.circular(widget.borderRadius),
                        border: _isHovered && !accessibilityService.reducedMotion
                            ? Border.all(
                                color: AppColors.primaryGold.withOpacity(0.3),
                                width: 1.5,
                              )
                            : null,
                      ),
                      child: widget.onTap != null
                          ? AnimatedPressable(
                              onPressed: widget.onTap,
                              enableHapticFeedback: true,
                              child: widget.child,
                            )
                          : widget.child,
                    ),
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

/// Profile card with enhanced interactions for matching pages
class ProfileCard extends StatefulWidget {
  final String imageUrl;
  final String name;
  final int age;
  final String? subtitle;
  final List<String>? tags;
  final VoidCallback? onTap;
  final VoidCallback? onLike;
  final VoidCallback? onSkip;
  final bool showActions;
  final double aspectRatio;

  const ProfileCard({
    super.key,
    required this.imageUrl,
    required this.name,
    required this.age,
    this.subtitle,
    this.tags,
    this.onTap,
    this.onLike,
    this.onSkip,
    this.showActions = true,
    this.aspectRatio = 0.75,
  });

  @override
  State<ProfileCard> createState() => _ProfileCardState();
}

class _ProfileCardState extends State<ProfileCard>
    with TickerProviderStateMixin {
  late AnimationController _revealController;
  late AnimationController _heartController;
  late Animation<double> _revealAnimation;
  late Animation<double> _heartAnimation;

  bool _showDetails = false;

  @override
  void initState() {
    super.initState();
    
    final accessibilityService = context.read<AccessibilityService>();
    
    _revealController = AnimationController(
      duration: accessibilityService.getAnimationDuration(
        const Duration(milliseconds: 400)
      ),
      vsync: this,
    );
    
    _heartController = AnimationController(
      duration: accessibilityService.getAnimationDuration(
        const Duration(milliseconds: 600)
      ),
      vsync: this,
    );

    _revealAnimation = CurvedAnimation(
      parent: _revealController,
      curve: Curves.easeInOut,
    );

    _heartAnimation = Tween<double>(
      begin: 1.0,
      end: 1.3,
    ).animate(CurvedAnimation(
      parent: _heartController,
      curve: Curves.elasticOut,
    ));
  }

  @override
  void dispose() {
    _revealController.dispose();
    _heartController.dispose();
    super.dispose();
  }

  void _toggleDetails() {
    setState(() => _showDetails = !_showDetails);
    
    final accessibilityService = context.read<AccessibilityService>();
    if (!accessibilityService.reducedMotion) {
      if (_showDetails) {
        _revealController.forward();
      } else {
        _revealController.reverse();
      }
    }
  }

  void _onLike() {
    final accessibilityService = context.read<AccessibilityService>();
    
    if (!accessibilityService.reducedMotion) {
      _heartController.forward().then((_) {
        _heartController.reverse();
      });
    }
    
    HapticFeedback.mediumImpact();
    widget.onLike?.call();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final accessibilityService = context.watch<AccessibilityService>();
    
    return EnhancedCard(
      onTap: widget.onTap ?? _toggleDetails,
      enableHoverEffect: true,
      enableGlow: true,
      borderRadius: 24.0,
      child: AspectRatio(
        aspectRatio: widget.aspectRatio,
        child: ClipRRect(
          borderRadius: BorderRadius.circular(24.0),
          child: Stack(
            children: [
              // Background Image
              Positioned.fill(
                child: Image.network(
                  widget.imageUrl,
                  fit: BoxFit.cover,
                  errorBuilder: (context, error, stackTrace) {
                    return Container(
                      color: AppColors.backgroundGrey,
                      child: const Icon(
                        Icons.person,
                        size: 64,
                        color: AppColors.textMuted,
                      ),
                    );
                  },
                ),
              ),
              
              // Gradient Overlay
              Positioned.fill(
                child: Container(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: [
                        Colors.transparent,
                        Colors.black.withOpacity(0.7),
                      ],
                      stops: const [0.4, 1.0],
                    ),
                  ),
                ),
              ),
              
              // Basic Info
              Positioned(
                bottom: 16,
                left: 16,
                right: widget.showActions ? 80 : 16,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '${widget.name}, ${widget.age}',
                      style: theme.textTheme.headlineSmall?.copyWith(
                        color: AppColors.textLight,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    if (widget.subtitle != null) ...[
                      const SizedBox(height: 4),
                      Text(
                        widget.subtitle!,
                        style: theme.textTheme.bodyMedium?.copyWith(
                          color: AppColors.textLight.withOpacity(0.9),
                        ),
                      ),
                    ],
                  ],
                ),
              ),
              
              // Action Buttons
              if (widget.showActions)
                Positioned(
                  bottom: 16,
                  right: 16,
                  child: Column(
                    children: [
                      AnimatedBuilder(
                        animation: _heartAnimation,
                        builder: (context, child) {
                          return Transform.scale(
                            scale: _heartAnimation.value,
                            child: AnimatedPressable(
                              onPressed: _onLike,
                              enableGlowEffect: true,
                              glowColor: Colors.red,
                              child: Container(
                                padding: const EdgeInsets.all(12),
                                decoration: const BoxDecoration(
                                  color: Colors.white,
                                  shape: BoxShape.circle,
                                ),
                                child: const Icon(
                                  Icons.favorite,
                                  color: AppColors.primaryGold,
                                  size: 20,
                                ),
                              ),
                            ),
                          );
                        },
                      ),
                      const SizedBox(height: 8),
                      AnimatedPressable(
                        onPressed: widget.onSkip,
                        enableGlowEffect: true,
                        child: Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: Colors.white.withOpacity(0.9),
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(
                            Icons.close,
                            color: AppColors.textSecondary,
                            size: 20,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              
              // Progressive Disclosure Overlay
              if (_showDetails)
                AnimatedBuilder(
                  animation: _revealAnimation,
                  builder: (context, child) {
                    return Positioned.fill(
                      child: Container(
                        decoration: BoxDecoration(
                          color: Colors.black.withOpacity(
                            0.8 * _revealAnimation.value
                          ),
                        ),
                        child: Opacity(
                          opacity: _revealAnimation.value,
                          child: Padding(
                            padding: const EdgeInsets.all(24.0),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                  children: [
                                    Text(
                                      'À propos',
                                      style: theme.textTheme.headlineSmall?.copyWith(
                                        color: AppColors.textLight,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                    AnimatedPressable(
                                      onPressed: _toggleDetails,
                                      child: const Icon(
                                        Icons.close,
                                        color: AppColors.textLight,
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 16),
                                if (widget.tags != null && widget.tags!.isNotEmpty) ...[
                                  Wrap(
                                    spacing: 8,
                                    runSpacing: 8,
                                    children: widget.tags!.map((tag) {
                                      return Container(
                                        padding: const EdgeInsets.symmetric(
                                          horizontal: 12,
                                          vertical: 6,
                                        ),
                                        decoration: BoxDecoration(
                                          color: AppColors.primaryGold.withOpacity(0.2),
                                          borderRadius: BorderRadius.circular(16),
                                          border: Border.all(
                                            color: AppColors.primaryGold.withOpacity(0.5),
                                          ),
                                        ),
                                        child: Text(
                                          tag,
                                          style: theme.textTheme.bodySmall?.copyWith(
                                            color: AppColors.textLight,
                                          ),
                                        ),
                                      );
                                    }).toList(),
                                  ),
                                ],
                              ],
                            ),
                          ),
                        ),
                      ),
                    );
                  },
                ),
            ],
          ),
        ),
      ),
    );
  }
}