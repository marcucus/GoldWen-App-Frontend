import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import '../../core/services/accessibility_service.dart';
import '../../core/theme/app_theme.dart';
import 'animated_pressable.dart';

/// Enhanced bottom navigation bar with smooth transitions and micro-interactions
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
  late AnimationController _indicatorController;
  late Animation<double> _indicatorAnimation;
  
  List<AnimationController> _iconControllers = [];
  List<Animation<double>> _iconAnimations = [];

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
      curve: Curves.elasticOut,
    );

    // Initialize icon controllers
    for (int i = 0; i < widget.items.length; i++) {
      final controller = AnimationController(
        duration: accessibilityService.getAnimationDuration(
          const Duration(milliseconds: 200)
        ),
        vsync: this,
      );
      
      final animation = Tween<double>(
        begin: 1.0,
        end: 1.2,
      ).animate(CurvedAnimation(
        parent: controller,
        curve: Curves.easeOut,
      ));

      _iconControllers.add(controller);
      _iconAnimations.add(animation);
    }

    _indicatorController.forward();
  }

  @override
  void dispose() {
    _indicatorController.dispose();
    for (final controller in _iconControllers) {
      controller.dispose();
    }
    super.dispose();
  }

  void _onItemTap(int index) {
    if (index == widget.currentIndex) return;

    final accessibilityService = context.read<AccessibilityService>();
    
    // Animate icon
    if (!accessibilityService.reducedMotion) {
      _iconControllers[index].forward().then((_) {
        _iconControllers[index].reverse();
      });
    }
    
    // Haptic feedback
    HapticFeedback.selectionClick();
    
    widget.onTap(index);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final accessibilityService = context.watch<AccessibilityService>();
    
    return Container(
      height: widget.height,
      decoration: BoxDecoration(
        color: widget.backgroundColor ?? AppColors.backgroundWhite,
        boxShadow: [
          BoxShadow(
            color: AppColors.shadowLight,
            blurRadius: 20,
            offset: const Offset(0, -5),
          ),
        ],
      ),
      child: SafeArea(
        child: Row(
          children: widget.items.asMap().entries.map((entry) {
            final int index = entry.key;
            final BottomNavigationItem item = entry.value;
            final bool isSelected = index == widget.currentIndex;

            return Expanded(
              child: AnimatedBuilder(
                animation: _iconAnimations[index],
                builder: (context, child) {
                  return Transform.scale(
                    scale: accessibilityService.reducedMotion 
                        ? 1.0 
                        : _iconAnimations[index].value,
                    child: AnimatedPressable(
                      onPressed: () => _onItemTap(index),
                      enableGlowEffect: isSelected,
                      glowColor: AppColors.primaryGold,
                      child: Container(
                        padding: const EdgeInsets.symmetric(vertical: 8),
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            // Icon with indicator
                            Stack(
                              alignment: Alignment.center,
                              children: [
                                // Background indicator
                                if (isSelected)
                                  AnimatedBuilder(
                                    animation: _indicatorAnimation,
                                    builder: (context, child) {
                                      return Container(
                                        width: 40 * _indicatorAnimation.value,
                                        height: 40 * _indicatorAnimation.value,
                                        decoration: BoxDecoration(
                                          color: AppColors.primaryGold.withOpacity(0.1),
                                          shape: BoxShape.circle,
                                        ),
                                      );
                                    },
                                  ),
                                // Icon
                                AnimatedContainer(
                                  duration: const Duration(milliseconds: 200),
                                  padding: const EdgeInsets.all(8),
                                  child: Icon(
                                    isSelected ? item.activeIcon : item.icon,
                                    color: isSelected 
                                        ? AppColors.primaryGold 
                                        : AppColors.textSecondary,
                                    size: 24,
                                  ),
                                ),
                              ],
                            ),
                            
                            // Label
                            const SizedBox(height: 4),
                            AnimatedDefaultTextStyle(
                              duration: const Duration(milliseconds: 200),
                              style: theme.textTheme.labelSmall!.copyWith(
                                color: isSelected 
                                    ? AppColors.primaryGold 
                                    : AppColors.textSecondary,
                                fontWeight: isSelected 
                                    ? FontWeight.w600 
                                    : FontWeight.normal,
                              ),
                              child: Text(item.label),
                            ),
                          ],
                        ),
                      ),
                    ),
                  );
                },
              ),
            );
          }).toList(),
        ),
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