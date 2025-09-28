import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'dart:ui';
import 'package:provider/provider.dart';
import '../../core/services/accessibility_service.dart';
import '../../core/theme/app_theme.dart';
import 'animated_pressable.dart';

/// Modern bottom navigation bar with glass morphism and premium animations
class EnhancedBottomNavigation extends StatefulWidget {
  final int currentIndex;
  final Function(int) onTap;
  final List<BottomNavigationItem> items;
  final Color? backgroundColor;
  final double height;

  const EnhancedBottomNavigation({
    super.key,
    required this.currentIndex,
    required this.onTap,
    required this.items,
    this.backgroundColor,
    this.height = 80.0,
  });

  @override
  State<EnhancedBottomNavigation> createState() => _EnhancedBottomNavigationState();
}

class _EnhancedBottomNavigationState extends State<EnhancedBottomNavigation>
    with TickerProviderStateMixin {
  late AnimationController _backgroundController;
  late AnimationController _selectionController;
  late Animation<double> _backgroundBlurAnimation;
  late Animation<double> _backgroundOpacityAnimation;
  late Animation<double> _selectionScaleAnimation;
  
  List<AnimationController> _iconControllers = [];
  List<Animation<double>> _iconScaleAnimations = [];
  List<Animation<double>> _iconRotationAnimations = [];

  @override
  void initState() {
    super.initState();
    _initializeAnimations();
  }

  void _initializeAnimations() {
    // Background glass effect animation
    _backgroundController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );
    
    // Selection animation
    _selectionController = AnimationController(
      duration: const Duration(milliseconds: 400),
      vsync: this,
    );

    _backgroundBlurAnimation = Tween<double>(
      begin: 8.0,
      end: 15.0,
    ).animate(CurvedAnimation(
      parent: _backgroundController,
      curve: Curves.easeInOut,
    ));

    _backgroundOpacityAnimation = Tween<double>(
      begin: 0.7,
      end: 0.9,
    ).animate(CurvedAnimation(
      parent: _backgroundController,
      curve: Curves.easeInOut,
    ));

    _selectionScaleAnimation = Tween<double>(
      begin: 1.0,
      end: 1.1,
    ).animate(CurvedAnimation(
      parent: _selectionController,
      curve: Curves.elasticOut,
    ));

    // Initialize per-item animations
    _iconControllers = List.generate(
      widget.items.length,
      (index) => AnimationController(
        duration: const Duration(milliseconds: 300),
        vsync: this,
      ),
    );

    _iconScaleAnimations = _iconControllers
        .map((controller) => Tween<double>(
              begin: 1.0,
              end: 1.2,
            ).animate(CurvedAnimation(
              parent: controller,
              curve: Curves.elasticOut,
            )))
        .toList();

    _iconRotationAnimations = _iconControllers
        .map((controller) => Tween<double>(
              begin: 0.0,
              end: 0.1,
            ).animate(CurvedAnimation(
              parent: controller,
              curve: Curves.easeInOut,
            )))
        .toList();

    // Start entrance animation
    Future.delayed(const Duration(milliseconds: 200), () {
      if (mounted) {
        _backgroundController.forward();
      }
    });
  }

  @override
  void dispose() {
    _backgroundController.dispose();
    _selectionController.dispose();
    for (final controller in _iconControllers) {
      controller.dispose();
    }
    super.dispose();
  }

  void _onItemTap(int index) {
    if (index == widget.currentIndex) return;

    final accessibilityService = context.read<AccessibilityService>();
    
    // Animate selection change
    if (!accessibilityService.reducedMotion) {
      _selectionController.forward().then((_) {
        _selectionController.reverse();
      });
      
      // Animate icon
      _iconControllers[index].forward().then((_) {
        _iconControllers[index].reverse();
      });
    }
    
    // Haptic feedback
    HapticFeedback.lightImpact();
    
    widget.onTap(index);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final accessibilityService = context.watch<AccessibilityService>();
    
    return Semantics(
      label: 'Barre de navigation principale',
      child: AnimatedBuilder(
        animation: Listenable.merge([_backgroundController, _selectionController]),
        builder: (context, child) {
          return Container(
            height: widget.height + MediaQuery.of(context).padding.bottom,
            child: Stack(
              children: [
                // Glass morphism background
                Positioned.fill(
                  child: ClipRRect(
                    child: BackdropFilter(
                      filter: ImageFilter.blur(
                        sigmaX: _backgroundBlurAnimation.value,
                        sigmaY: _backgroundBlurAnimation.value,
                      ),
                      child: Container(
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            begin: Alignment.topCenter,
                            end: Alignment.bottomCenter,
                            colors: [
                              AppColors.backgroundWhite.withOpacity(
                                _backgroundOpacityAnimation.value * 0.8,
                              ),
                              AppColors.backgroundWhite.withOpacity(
                                _backgroundOpacityAnimation.value * 0.9,
                              ),
                            ],
                          ),
                          border: Border(
                            top: BorderSide(
                              color: AppColors.primaryGold.withOpacity(0.3),
                              width: 1.5,
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                ),

                // Content
                SafeArea(
                  child: Container(
                    height: widget.height,
                    padding: const EdgeInsets.symmetric(
                      horizontal: AppSpacing.lg,
                      vertical: AppSpacing.sm,
                    ),
                    child: Row(
                      children: widget.items.asMap().entries.map((entry) {
                        final int index = entry.key;
                        final BottomNavigationItem item = entry.value;
                        final bool isSelected = index == widget.currentIndex;

                        return Expanded(
                          child: _buildNavItem(
                            index: index,
                            item: item,
                            isSelected: isSelected,
                            accessibilityService: accessibilityService,
                          ),
                        );
                      }).toList(),
                    ),
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildNavItem({
    required int index,
    required BottomNavigationItem item,
    required bool isSelected,
    required AccessibilityService accessibilityService,
  }) {
    return Semantics(
      label: '${item.label}, onglet ${index + 1} sur ${widget.items.length}',
      hint: isSelected ? 'Sélectionné' : 'Appuyer pour naviguer vers ${item.label}',
      button: true,
      selected: isSelected,
      child: AnimatedBuilder(
        animation: Listenable.merge([
          _iconScaleAnimations[index],
          _iconRotationAnimations[index],
        ]),
        builder: (context, child) {
          return Transform.scale(
            scale: accessibilityService.reducedMotion 
                ? 1.0 
                : isSelected 
                    ? _selectionScaleAnimation.value 
                    : _iconScaleAnimations[index].value,
            child: Transform.rotate(
              angle: accessibilityService.reducedMotion 
                  ? 0.0 
                  : _iconRotationAnimations[index].value,
              child: AnimatedPressable(
                onPressed: () => _onItemTap(index),
                enableGlowEffect: isSelected,
                glowColor: AppColors.primaryGold,
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: AppSpacing.xs,
                    vertical: AppSpacing.sm,
                  ),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      // Icon with modern background
                      Stack(
                        alignment: Alignment.center,
                        children: [
                          // Selection background with glass effect
                          if (isSelected)
                            Container(
                              width: 48,
                              height: 48,
                              decoration: BoxDecoration(
                                gradient: LinearGradient(
                                  begin: Alignment.topLeft,
                                  end: Alignment.bottomRight,
                                  colors: [
                                    AppColors.primaryGold.withOpacity(0.2),
                                    AppColors.primaryGold.withOpacity(0.1),
                                  ],
                                ),
                                borderRadius: BorderRadius.circular(16),
                                border: Border.all(
                                  color: AppColors.primaryGold.withOpacity(0.4),
                                  width: 1,
                                ),
                                boxShadow: [
                                  BoxShadow(
                                    color: AppColors.primaryGold.withOpacity(0.3),
                                    blurRadius: 12,
                                    offset: const Offset(0, 4),
                                  ),
                                ],
                              ),
                            ),

                          // Icon
                          AnimatedContainer(
                            duration: const Duration(milliseconds: 200),
                            padding: const EdgeInsets.all(12),
                            child: Icon(
                              isSelected ? item.activeIcon : item.icon,
                              color: isSelected 
                                  ? AppColors.primaryGold 
                                  : AppColors.textSecondary,
                              size: 24,
                              semanticLabel: '${item.label} icon',
                            ),
                          ),
                        ],
                      ),
                      
                      const SizedBox(height: AppSpacing.xs),
                      
                      // Label with animation
                      AnimatedDefaultTextStyle(
                        duration: const Duration(milliseconds: 200),
                        style: Theme.of(context).textTheme.labelSmall!.copyWith(
                          color: isSelected 
                              ? AppColors.primaryGold 
                              : AppColors.textSecondary,
                          fontWeight: isSelected 
                              ? FontWeight.w600 
                              : FontWeight.normal,
                          fontSize: isSelected ? 11 : 10,
                        ),
                        child: Text(
                          item.label,
                          textAlign: TextAlign.center,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          );
        },
      ),
    );
  }
      ),
    );
  }
}

class BottomNavigationItem {
  final IconData icon;
  final IconData activeIcon;
  final String label;

  const BottomNavigationItem({
    required this.icon,
    required this.activeIcon,
    required this.label,
  });
}

/// Enhanced app bar with smooth animations
class EnhancedAppBar extends StatefulWidget implements PreferredSizeWidget {
  final String? title;
  final List<Widget>? actions;
  final Widget? leading;
  final bool centerTitle;
  final Color? backgroundColor;
  final double elevation;
  final bool enableGradient;

  const EnhancedAppBar({
    super.key,
    this.title,
    this.actions,
    this.leading,
    this.centerTitle = true,
    this.backgroundColor,
    this.elevation = 0,
    this.enableGradient = false,
  });

  @override
  Size get preferredSize => const Size.fromHeight(kToolbarHeight);

  @override
  State<EnhancedAppBar> createState() => _EnhancedAppBarState();
}

class _EnhancedAppBarState extends State<EnhancedAppBar>
    with TickerProviderStateMixin {
  late AnimationController _slideController;
  late Animation<Offset> _slideAnimation;

  @override
  void initState() {
    super.initState();
    
    final accessibilityService = context.read<AccessibilityService>();
    
    _slideController = AnimationController(
      duration: accessibilityService.getAnimationDuration(
        const Duration(milliseconds: 400)
      ),
      vsync: this,
    );

    _slideAnimation = Tween<Offset>(
      begin: const Offset(0, -1),
      end: Offset.zero,
    ).animate(CurvedAnimation(
      parent: _slideController,
      curve: Curves.easeOut,
    ));

    _slideController.forward();
  }

  @override
  void dispose() {
    _slideController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final accessibilityService = context.watch<AccessibilityService>();
    
    return SlideTransition(
      position: accessibilityService.reducedMotion 
          ? AlwaysStoppedAnimation(Offset.zero)
          : _slideAnimation,
      child: Container(
        decoration: BoxDecoration(
          gradient: widget.enableGradient 
              ? AppColors.subtleGradient 
              : null,
          color: widget.enableGradient 
              ? null 
              : (widget.backgroundColor ?? AppColors.backgroundWhite),
        ),
        child: AppBar(
          title: widget.title != null
              ? AnimatedDefaultTextStyle(
                  duration: const Duration(milliseconds: 300),
                  style: theme.appBarTheme.titleTextStyle!,
                  child: Text(widget.title!),
                )
              : null,
          centerTitle: widget.centerTitle,
          backgroundColor: Colors.transparent,
          elevation: widget.elevation,
          leading: widget.leading,
          actions: widget.actions?.map((action) {
            return AnimatedPressable(
              enableGlowEffect: true,
              glowColor: AppColors.primaryGold,
              child: action,
            );
          }).toList(),
        ),
      ),
    );
  }
}

/// Enhanced tab bar with smooth indicator animations
class EnhancedTabBar extends StatefulWidget {
  final List<String> tabs;
  final int currentIndex;
  final Function(int) onTap;
  final bool isScrollable;

  const EnhancedTabBar({
    super.key,
    required this.tabs,
    required this.currentIndex,
    required this.onTap,
    this.isScrollable = false,
  });

  @override
  State<EnhancedTabBar> createState() => _EnhancedTabBarState();
}

class _EnhancedTabBarState extends State<EnhancedTabBar>
    with TickerProviderStateMixin {
  late AnimationController _indicatorController;
  late Animation<double> _indicatorAnimation;

  @override
  void initState() {
    super.initState();
    
    final accessibilityService = context.read<AccessibilityService>();
    
    _indicatorController = AnimationController(
      duration: accessibilityService.getAnimationDuration(
        const Duration(milliseconds: 300)
      ),
      vsync: this,
    );

    _indicatorAnimation = CurvedAnimation(
      parent: _indicatorController,
      curve: Curves.easeInOut,
    );

    _indicatorController.forward();
  }

  @override
  void didUpdateWidget(EnhancedTabBar oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.currentIndex != widget.currentIndex) {
      _indicatorController.reset();
      _indicatorController.forward();
    }
  }

  @override
  void dispose() {
    _indicatorController.dispose();
    super.dispose();
  }

  void _onTabTap(int index) {
    HapticFeedback.selectionClick();
    widget.onTap(index);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final accessibilityService = context.watch<AccessibilityService>();
    
    return Container(
      height: 48,
      child: widget.isScrollable
          ? SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: _buildTabRow(theme, accessibilityService),
            )
          : _buildTabRow(theme, accessibilityService),
    );
  }

  Widget _buildTabRow(ThemeData theme, AccessibilityService accessibilityService) {
    return Row(
      mainAxisSize: widget.isScrollable ? MainAxisSize.min : MainAxisSize.max,
      children: widget.tabs.asMap().entries.map((entry) {
        final int index = entry.key;
        final String tab = entry.value;
        final bool isSelected = index == widget.currentIndex;

        return Expanded(
          flex: widget.isScrollable ? 0 : 1,
          child: AnimatedPressable(
            onPressed: () => _onTabTap(index),
            enableHapticFeedback: true,
            child: Container(
              padding: EdgeInsets.symmetric(
                horizontal: widget.isScrollable ? 20 : 16,
                vertical: 12,
              ),
              child: Column(
                children: [
                  AnimatedDefaultTextStyle(
                    duration: const Duration(milliseconds: 200),
                    style: theme.textTheme.labelLarge!.copyWith(
                      color: isSelected 
                          ? AppColors.primaryGold 
                          : AppColors.textSecondary,
                      fontWeight: isSelected 
                          ? FontWeight.w600 
                          : FontWeight.normal,
                    ),
                    child: Text(tab),
                  ),
                  
                  const SizedBox(height: 8),
                  
                  // Animated indicator
                  AnimatedBuilder(
                    animation: _indicatorAnimation,
                    builder: (context, child) {
                      return Container(
                        height: 3,
                        width: isSelected 
                            ? 30 * _indicatorAnimation.value 
                            : 0,
                        decoration: BoxDecoration(
                          color: AppColors.primaryGold,
                          borderRadius: BorderRadius.circular(1.5),
                        ),
                      );
                    },
                  ),
                ],
              ),
            ),
          ),
        );
      }).toList(),
    );
  }
}