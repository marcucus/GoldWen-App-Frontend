import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/services/accessibility_service.dart';
import '../../core/theme/app_theme.dart';

/// Parallax scrolling container with multiple layers
class ParallaxScrollView extends StatefulWidget {
  final List<ParallaxLayer> layers;
  final ScrollController? controller;
  final Widget? child;
  final EdgeInsetsGeometry? padding;

  const ParallaxScrollView({
    super.key,
    required this.layers,
    this.controller,
    this.child,
    this.padding,
  });

  @override
  State<ParallaxScrollView> createState() => _ParallaxScrollViewState();
}

class _ParallaxScrollViewState extends State<ParallaxScrollView> {
  late ScrollController _scrollController;
  double _scrollOffset = 0.0;

  @override
  void initState() {
    super.initState();
    _scrollController = widget.controller ?? ScrollController();
    _scrollController.addListener(_onScroll);
  }

  @override
  void dispose() {
    if (widget.controller == null) {
      _scrollController.dispose();
    } else {
      _scrollController.removeListener(_onScroll);
    }
    super.dispose();
  }

  void _onScroll() {
    setState(() {
      _scrollOffset = _scrollController.offset;
    });
  }

  @override
  Widget build(BuildContext context) {
    final accessibilityService = context.watch<AccessibilityService>();
    
    if (accessibilityService.reducedMotion) {
      return SingleChildScrollView(
        controller: _scrollController,
        padding: widget.padding,
        child: widget.child,
      );
    }

    return Stack(
      children: [
        // Parallax layers
        ...widget.layers.map((layer) => _buildParallaxLayer(layer)),
        
        // Main scrollable content
        SingleChildScrollView(
          controller: _scrollController,
          padding: widget.padding,
          child: widget.child,
        ),
      ],
    );
  }

  Widget _buildParallaxLayer(ParallaxLayer layer) {
    final offset = _scrollOffset * layer.speed;
    
    return Positioned.fill(
      child: Transform.translate(
        offset: Offset(0, offset),
        child: layer.child,
      ),
    );
  }
}

/// Individual parallax layer configuration
class ParallaxLayer {
  final Widget child;
  final double speed; // 0.0 = no movement, 1.0 = normal scroll speed, 0.5 = half speed
  final Alignment alignment;

  const ParallaxLayer({
    required this.child,
    this.speed = 0.5,
    this.alignment = Alignment.center,
  });
}

/// Parallax background widget for hero sections
class ParallaxBackground extends StatefulWidget {
  final Widget child;
  final String? backgroundImage;
  final Gradient? gradient;
  final Color? backgroundColor;
  final double parallaxStrength;
  final bool enableParallax;

  const ParallaxBackground({
    super.key,
    required this.child,
    this.backgroundImage,
    this.gradient,
    this.backgroundColor,
    this.parallaxStrength = 0.5,
    this.enableParallax = true,
  });

  @override
  State<ParallaxBackground> createState() => _ParallaxBackgroundState();
}

class _ParallaxBackgroundState extends State<ParallaxBackground> {
  final GlobalKey _childKey = GlobalKey();
  double _scrollOffset = 0.0;

  @override
  Widget build(BuildContext context) {
    final accessibilityService = context.watch<AccessibilityService>();
    
    return NotificationListener<ScrollNotification>(
      onNotification: (notification) {
        if (widget.enableParallax && !accessibilityService.reducedMotion) {
          final RenderBox? renderBox = 
              _childKey.currentContext?.findRenderObject() as RenderBox?;
          
          if (renderBox != null) {
            final position = renderBox.localToGlobal(Offset.zero);
            setState(() {
              _scrollOffset = -position.dy * widget.parallaxStrength;
            });
          }
        }
        return false;
      },
      child: Container(
        key: _childKey,
        child: Stack(
          children: [
            // Parallax background
            if (widget.backgroundImage != null || 
                widget.gradient != null || 
                widget.backgroundColor != null)
              Positioned.fill(
                child: Transform.translate(
                  offset: widget.enableParallax && !accessibilityService.reducedMotion
                      ? Offset(0, _scrollOffset)
                      : Offset.zero,
                  child: Container(
                    decoration: BoxDecoration(
                      color: widget.backgroundColor,
                      gradient: widget.gradient,
                      image: widget.backgroundImage != null
                          ? DecorationImage(
                              image: AssetImage(widget.backgroundImage!),
                              fit: BoxFit.cover,
                            )
                          : null,
                    ),
                  ),
                ),
              ),
            
            // Content
            widget.child,
          ],
        ),
      ),
    );
  }
}

/// Parallax card that moves slightly on scroll
class ParallaxCard extends StatefulWidget {
  final Widget child;
  final double parallaxStrength;
  final EdgeInsetsGeometry? margin;
  final EdgeInsetsGeometry? padding;
  final BorderRadiusGeometry? borderRadius;
  final Color? backgroundColor;
  final List<BoxShadow>? boxShadow;

  const ParallaxCard({
    super.key,
    required this.child,
    this.parallaxStrength = 0.3,
    this.margin,
    this.padding,
    this.borderRadius,
    this.backgroundColor,
    this.boxShadow,
  });

  @override
  State<ParallaxCard> createState() => _ParallaxCardState();
}

class _ParallaxCardState extends State<ParallaxCard> {
  double _offsetY = 0.0;

  @override
  Widget build(BuildContext context) {
    final accessibilityService = context.watch<AccessibilityService>();
    
    return NotificationListener<ScrollNotification>(
      onNotification: (notification) {
        if (!accessibilityService.reducedMotion) {
          final RenderBox? renderBox = context.findRenderObject() as RenderBox?;
          if (renderBox != null) {
            final position = renderBox.localToGlobal(Offset.zero);
            final screenHeight = MediaQuery.of(context).size.height;
            final cardCenter = position.dy + renderBox.size.height / 2;
            final screenCenter = screenHeight / 2;
            
            setState(() {
              _offsetY = (screenCenter - cardCenter) * widget.parallaxStrength * 0.01;
            });
          }
        }
        return false;
      },
      child: Transform.translate(
        offset: accessibilityService.reducedMotion 
            ? Offset.zero 
            : Offset(0, _offsetY),
        child: Container(
          margin: widget.margin,
          padding: widget.padding,
          decoration: BoxDecoration(
            color: widget.backgroundColor ?? AppColors.cardBackground,
            borderRadius: widget.borderRadius ?? BorderRadius.circular(16),
            boxShadow: widget.boxShadow ?? [
              const BoxShadow(
                color: AppColors.shadowLight,
                blurRadius: 8,
                offset: Offset(0, 2),
              ),
            ],
          ),
          child: widget.child,
        ),
      ),
    );
  }
}

/// Staggered animation for lists with parallax effect
class StaggeredParallaxList extends StatefulWidget {
  final List<Widget> children;
  final double staggerDelay;
  final double parallaxStrength;
  final EdgeInsetsGeometry? padding;
  final ScrollController? controller;

  const StaggeredParallaxList({
    super.key,
    required this.children,
    this.staggerDelay = 100.0,
    this.parallaxStrength = 0.2,
    this.padding,
    this.controller,
  });

  @override
  State<StaggeredParallaxList> createState() => _StaggeredParallaxListState();
}

class _StaggeredParallaxListState extends State<StaggeredParallaxList>
    with TickerProviderStateMixin {
  late List<AnimationController> _controllers;
  late List<Animation<double>> _animations;
  late ScrollController _scrollController;
  double _scrollOffset = 0.0;

  @override
  void initState() {
    super.initState();
    
    _scrollController = widget.controller ?? ScrollController();
    _scrollController.addListener(_onScroll);
    
    final accessibilityService = context.read<AccessibilityService>();
    
    // Initialize stagger animations
    _controllers = List.generate(
      widget.children.length,
      (index) => AnimationController(
        duration: accessibilityService.getAnimationDuration(
          Duration(milliseconds: 600 + (index * widget.staggerDelay).round())
        ),
        vsync: this,
      ),
    );

    _animations = _controllers.map((controller) {
      return Tween<double>(
        begin: 0.0,
        end: 1.0,
      ).animate(CurvedAnimation(
        parent: controller,
        curve: Curves.easeOut,
      ));
    }).toList();

    _startStaggeredAnimations();
  }

  void _startStaggeredAnimations() async {
    final accessibilityService = context.read<AccessibilityService>();
    
    if (!accessibilityService.reducedMotion) {
      for (int i = 0; i < _controllers.length; i++) {
        Future.delayed(
          Duration(milliseconds: (i * widget.staggerDelay).round()),
          () => _controllers[i].forward(),
        );
      }
    } else {
      // Skip animations for reduced motion
      for (final controller in _controllers) {
        controller.forward();
      }
    }
  }

  void _onScroll() {
    setState(() {
      _scrollOffset = _scrollController.offset;
    });
  }

  @override
  void dispose() {
    for (final controller in _controllers) {
      controller.dispose();
    }
    if (widget.controller == null) {
      _scrollController.dispose();
    } else {
      _scrollController.removeListener(_onScroll);
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final accessibilityService = context.watch<AccessibilityService>();
    
    return ListView.builder(
      controller: _scrollController,
      padding: widget.padding,
      itemCount: widget.children.length,
      itemBuilder: (context, index) {
        final parallaxOffset = accessibilityService.reducedMotion 
            ? 0.0 
            : _scrollOffset * widget.parallaxStrength * (index % 3 - 1);
        
        return FadeTransition(
          opacity: _animations[index],
          child: SlideTransition(
            position: Tween<Offset>(
              begin: const Offset(0, 0.3),
              end: Offset.zero,
            ).animate(_animations[index]),
            child: Transform.translate(
              offset: Offset(0, parallaxOffset),
              child: widget.children[index],
            ),
          ),
        );
      },
    );
  }
}

/// Depth-based parallax effect for layered UI
class DepthParallax extends StatefulWidget {
  final List<DepthLayer> layers;
  final Widget child;
  final double sensitivity;

  const DepthParallax({
    super.key,
    required this.layers,
    required this.child,
    this.sensitivity = 0.02,
  });

  @override
  State<DepthParallax> createState() => _DepthParallaxState();
}

class _DepthParallaxState extends State<DepthParallax> {
  Offset _pointerPosition = Offset.zero;

  void _onPointerMove(PointerEvent details, Size size) {
    final accessibilityService = context.read<AccessibilityService>();
    if (!accessibilityService.reducedMotion) {
      setState(() {
        _pointerPosition = Offset(
          (details.localPosition.dx - size.width / 2) / size.width,
          (details.localPosition.dy - size.height / 2) / size.height,
        );
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final accessibilityService = context.watch<AccessibilityService>();
    
    return LayoutBuilder(
      builder: (context, constraints) {
        return MouseRegion(
          onHover: (event) => _onPointerMove(event, constraints.biggest),
          child: Stack(
            children: [
              // Depth layers
              ...widget.layers.map((layer) => _buildDepthLayer(layer)),
              
              // Main content
              widget.child,
            ],
          ),
        );
      },
    );
  }

  Widget _buildDepthLayer(DepthLayer layer) {
    final accessibilityService = context.watch<AccessibilityService>();
    
    if (accessibilityService.reducedMotion) {
      return Positioned.fill(child: layer.child);
    }

    final offsetX = _pointerPosition.dx * layer.depth * widget.sensitivity * 50;
    final offsetY = _pointerPosition.dy * layer.depth * widget.sensitivity * 50;

    return Positioned.fill(
      child: Transform.translate(
        offset: Offset(offsetX, offsetY),
        child: layer.child,
      ),
    );
  }
}

/// Individual depth layer for DepthParallax
class DepthLayer {
  final Widget child;
  final double depth; // Higher values move more, 0.0 = no movement

  const DepthLayer({
    required this.child,
    required this.depth,
  });
}