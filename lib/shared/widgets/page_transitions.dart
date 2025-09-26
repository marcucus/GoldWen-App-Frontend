import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/services/accessibility_service.dart';
import '../../core/theme/app_theme.dart';

/// Custom page transitions that respect accessibility settings
class EnhancedPageTransitions {
  /// Fade transition with scaling
  static PageRouteBuilder fadeScale({
    required Widget page,
    Duration duration = const Duration(milliseconds: 300),
    Curve curve = Curves.easeInOut,
  }) {
    return PageRouteBuilder(
      pageBuilder: (context, animation, secondaryAnimation) => page,
      transitionDuration: duration,
      transitionsBuilder: (context, animation, secondaryAnimation, child) {
        final accessibilityService = context.read<AccessibilityService>();
        
        if (accessibilityService.reducedMotion) {
          return child;
        }

        return FadeTransition(
          opacity: animation,
          child: ScaleTransition(
            scale: Tween<double>(
              begin: 0.95,
              end: 1.0,
            ).animate(CurvedAnimation(
              parent: animation,
              curve: curve,
            )),
            child: child,
          ),
        );
      },
    );
  }

  /// Slide transition from right
  static PageRouteBuilder slideFromRight({
    required Widget page,
    Duration duration = const Duration(milliseconds: 300),
    Curve curve = Curves.easeOut,
  }) {
    return PageRouteBuilder(
      pageBuilder: (context, animation, secondaryAnimation) => page,
      transitionDuration: duration,
      transitionsBuilder: (context, animation, secondaryAnimation, child) {
        final accessibilityService = context.read<AccessibilityService>();
        
        if (accessibilityService.reducedMotion) {
          return child;
        }

        return SlideTransition(
          position: Tween<Offset>(
            begin: const Offset(1.0, 0.0),
            end: Offset.zero,
          ).animate(CurvedAnimation(
            parent: animation,
            curve: curve,
          )),
          child: child,
        );
      },
    );
  }

  /// Slide transition from bottom
  static PageRouteBuilder slideFromBottom({
    required Widget page,
    Duration duration = const Duration(milliseconds: 300),
    Curve curve = Curves.easeOut,
  }) {
    return PageRouteBuilder(
      pageBuilder: (context, animation, secondaryAnimation) => page,
      transitionDuration: duration,
      transitionsBuilder: (context, animation, secondaryAnimation, child) {
        final accessibilityService = context.read<AccessibilityService>();
        
        if (accessibilityService.reducedMotion) {
          return child;
        }

        return SlideTransition(
          position: Tween<Offset>(
            begin: const Offset(0.0, 1.0),
            end: Offset.zero,
          ).animate(CurvedAnimation(
            parent: animation,
            curve: curve,
          )),
          child: child,
        );
      },
    );
  }

  /// Card-style transition with depth
  static PageRouteBuilder cardTransition({
    required Widget page,
    Duration duration = const Duration(milliseconds: 400),
  }) {
    return PageRouteBuilder(
      pageBuilder: (context, animation, secondaryAnimation) => page,
      transitionDuration: duration,
      transitionsBuilder: (context, animation, secondaryAnimation, child) {
        final accessibilityService = context.read<AccessibilityService>();
        
        if (accessibilityService.reducedMotion) {
          return child;
        }

        return Transform(
          alignment: Alignment.center,
          transform: Matrix4.identity()
            ..setEntry(3, 2, 0.001)
            ..rotateX(0.3 * (1 - animation.value))
            ..scale(0.8 + (0.2 * animation.value)),
          child: FadeTransition(
            opacity: animation,
            child: child,
          ),
        );
      },
    );
  }

  /// Morphing transition with custom hero-like effect
  static PageRouteBuilder morphTransition({
    required Widget page,
    Duration duration = const Duration(milliseconds: 500),
    BorderRadius? borderRadius,
  }) {
    return PageRouteBuilder(
      pageBuilder: (context, animation, secondaryAnimation) => page,
      transitionDuration: duration,
      transitionsBuilder: (context, animation, secondaryAnimation, child) {
        final accessibilityService = context.read<AccessibilityService>();
        
        if (accessibilityService.reducedMotion) {
          return child;
        }

        return AnimatedBuilder(
          animation: animation,
          builder: (context, child) {
            return ClipRRect(
              borderRadius: BorderRadius.lerp(
                borderRadius ?? BorderRadius.circular(24),
                BorderRadius.zero,
                animation.value,
              )!,
              child: Transform.scale(
                scale: 0.8 + (0.2 * animation.value),
                child: FadeTransition(
                  opacity: animation,
                  child: child,
                ),
              ),
            );
          },
          child: child,
        );
      },
    );
  }
}

/// Page wrapper with enhanced enter animations
class EnhancedPageWrapper extends StatefulWidget {
  final Widget child;
  final Duration delay;
  final Duration duration;
  final Curve curve;
  final bool enableStagger;

  const EnhancedPageWrapper({
    super.key,
    required this.child,
    this.delay = Duration.zero,
    this.duration = const Duration(milliseconds: 600),
    this.curve = Curves.easeOut,
    this.enableStagger = false,
  });

  @override
  State<EnhancedPageWrapper> createState() => _EnhancedPageWrapperState();
}

class _EnhancedPageWrapperState extends State<EnhancedPageWrapper>
    with TickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;
  late Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();
    
    final accessibilityService = context.read<AccessibilityService>();
    
    _controller = AnimationController(
      duration: accessibilityService.getAnimationDuration(widget.duration),
      vsync: this,
    );

    _fadeAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _controller,
      curve: const Interval(0.0, 0.7, curve: Curves.easeOut),
    ));

    _slideAnimation = Tween<Offset>(
      begin: const Offset(0, 0.1),
      end: Offset.zero,
    ).animate(CurvedAnimation(
      parent: _controller,
      curve: widget.curve,
    ));

    _scaleAnimation = Tween<double>(
      begin: 0.95,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _controller,
      curve: const Interval(0.3, 1.0, curve: Curves.easeOut),
    ));

    _startAnimation();
  }

  void _startAnimation() async {
    await Future.delayed(widget.delay);
    if (mounted) {
      _controller.forward();
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
    
    if (accessibilityService.reducedMotion) {
      return widget.child;
    }

    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        return FadeTransition(
          opacity: _fadeAnimation,
          child: SlideTransition(
            position: _slideAnimation,
            child: ScaleTransition(
              scale: _scaleAnimation,
              child: widget.child,
            ),
          ),
        );
      },
    );
  }
}

/// Staggered list animation for page elements
class StaggeredPageElements extends StatefulWidget {
  final List<Widget> children;
  final Duration staggerDelay;
  final Duration itemDuration;
  final Curve curve;
  final ScrollController? scrollController;

  const StaggeredPageElements({
    super.key,
    required this.children,
    this.staggerDelay = const Duration(milliseconds: 100),
    this.itemDuration = const Duration(milliseconds: 400),
    this.curve = Curves.easeOut,
    this.scrollController,
  });

  @override
  State<StaggeredPageElements> createState() => _StaggeredPageElementsState();
}

class _StaggeredPageElementsState extends State<StaggeredPageElements>
    with TickerProviderStateMixin {
  late List<AnimationController> _controllers;
  late List<Animation<double>> _fadeAnimations;
  late List<Animation<Offset>> _slideAnimations;

  @override
  void initState() {
    super.initState();
    
    final accessibilityService = context.read<AccessibilityService>();
    
    _controllers = widget.children.map((child) {
      return AnimationController(
        duration: accessibilityService.getAnimationDuration(widget.itemDuration),
        vsync: this,
      );
    }).toList();

    _fadeAnimations = _controllers.map((controller) {
      return Tween<double>(
        begin: 0.0,
        end: 1.0,
      ).animate(CurvedAnimation(
        parent: controller,
        curve: widget.curve,
      ));
    }).toList();

    _slideAnimations = _controllers.map((controller) {
      return Tween<Offset>(
        begin: const Offset(0, 0.3),
        end: Offset.zero,
      ).animate(CurvedAnimation(
        parent: controller,
        curve: widget.curve,
      ));
    }).toList();

    _startStaggeredAnimations();
  }

  void _startStaggeredAnimations() async {
    final accessibilityService = context.read<AccessibilityService>();
    
    if (accessibilityService.reducedMotion) {
      // Skip stagger for reduced motion
      for (final controller in _controllers) {
        controller.forward();
      }
      return;
    }

    for (int i = 0; i < _controllers.length; i++) {
      Future.delayed(
        Duration(milliseconds: i * widget.staggerDelay.inMilliseconds),
        () {
          if (mounted) {
            _controllers[i].forward();
          }
        },
      );
    }
  }

  @override
  void dispose() {
    for (final controller in _controllers) {
      controller.dispose();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: List.generate(widget.children.length, (index) {
        return FadeTransition(
          opacity: _fadeAnimations[index],
          child: SlideTransition(
            position: _slideAnimations[index],
            child: widget.children[index],
          ),
        );
      }),
    );
  }
}

/// Hero-style transition for shared elements
class SharedElementTransition extends StatefulWidget {
  final String tag;
  final Widget child;
  final Duration duration;
  final Curve curve;

  const SharedElementTransition({
    super.key,
    required this.tag,
    required this.child,
    this.duration = const Duration(milliseconds: 300),
    this.curve = Curves.easeInOut,
  });

  @override
  State<SharedElementTransition> createState() => _SharedElementTransitionState();
}

class _SharedElementTransitionState extends State<SharedElementTransition>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _animation;

  @override
  void initState() {
    super.initState();
    
    final accessibilityService = context.read<AccessibilityService>();
    
    _controller = AnimationController(
      duration: accessibilityService.getAnimationDuration(widget.duration),
      vsync: this,
    );

    _animation = CurvedAnimation(
      parent: _controller,
      curve: widget.curve,
    );

    _controller.forward();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Hero(
      tag: widget.tag,
      child: FadeTransition(
        opacity: _animation,
        child: ScaleTransition(
          scale: Tween<double>(
            begin: 0.8,
            end: 1.0,
          ).animate(_animation),
          child: widget.child,
        ),
      ),
    );
  }
}

/// Loading transition for async content
class LoadingTransition extends StatefulWidget {
  final bool isLoading;
  final Widget child;
  final Widget? loadingWidget;
  final Duration duration;

  const LoadingTransition({
    super.key,
    required this.isLoading,
    required this.child,
    this.loadingWidget,
    this.duration = const Duration(milliseconds: 300),
  });

  @override
  State<LoadingTransition> createState() => _LoadingTransitionState();
}

class _LoadingTransitionState extends State<LoadingTransition>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _fadeAnimation;

  @override
  void initState() {
    super.initState();
    
    final accessibilityService = context.read<AccessibilityService>();
    
    _controller = AnimationController(
      duration: accessibilityService.getAnimationDuration(widget.duration),
      vsync: this,
    );

    _fadeAnimation = CurvedAnimation(
      parent: _controller,
      curve: Curves.easeInOut,
    );

    if (!widget.isLoading) {
      _controller.forward();
    }
  }

  @override
  void didUpdateWidget(LoadingTransition oldWidget) {
    super.didUpdateWidget(oldWidget);
    
    if (oldWidget.isLoading && !widget.isLoading) {
      _controller.forward();
    } else if (!oldWidget.isLoading && widget.isLoading) {
      _controller.reverse();
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedSwitcher(
      duration: widget.duration,
      child: widget.isLoading
          ? (widget.loadingWidget ?? const CircularProgressIndicator())
          : FadeTransition(
              opacity: _fadeAnimation,
              child: widget.child,
            ),
    );
  }
}