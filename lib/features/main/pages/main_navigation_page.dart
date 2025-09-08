import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/widgets/animated_widgets.dart';
import '../../../core/services/location_service.dart';
import 'home_page.dart';
import '../../matching/pages/daily_matches_page.dart';
import '../../chat/pages/chat_list_page.dart';
import '../../subscription/pages/subscription_page.dart';

class MainNavigationPage extends StatefulWidget {
  const MainNavigationPage({super.key});

  @override
  State<MainNavigationPage> createState() => _MainNavigationPageState();
}

class _MainNavigationPageState extends State<MainNavigationPage> with TickerProviderStateMixin {
  int _currentIndex = 0;
  late TabController _tabController;
  late AnimationController _navigationController;
  late Animation<double> _scaleAnimation;
  late Animation<Offset> _slideAnimation;
  
  late final List<Widget> _pages;
  late final List<NavigationItem> _navigationItems;
  
  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 4, vsync: this);
    _initializeAnimations();
    _initializePages();
    _initializeNavigationItems();
    _initializeLocationService();
    _startAnimations();
  }

  void _initializeAnimations() {
    _navigationController = AnimationController(
      duration: AppAnimations.medium,
      vsync: this,
    );

    _scaleAnimation = Tween<double>(
      begin: 0.8,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _navigationController,
      curve: AppAnimations.elasticOut,
    ));

    _slideAnimation = Tween<Offset>(
      begin: const Offset(0, 1),
      end: Offset.zero,
    ).animate(CurvedAnimation(
      parent: _navigationController,
      curve: AppAnimations.easeOut,
    ));
  }

  void _initializePages() {
    _pages = [
      HomePage(onNavigate: (index) {
        _navigateToTab(index);
      }),
      const DailyMatchesPage(),
      const ChatListPage(),
      const SubscriptionPage(),
    ];
  }

  void _initializeNavigationItems() {
    _navigationItems = [
      NavigationItem(
        icon: Icons.home_outlined,
        activeIcon: Icons.home,
        label: 'Accueil',
        color: AppColors.primaryGold,
      ),
      NavigationItem(
        icon: Icons.favorite_outline,
        activeIcon: Icons.favorite,
        label: 'Découvrir',
        color: AppColors.errorRed,
      ),
      NavigationItem(
        icon: Icons.chat_bubble_outline,
        activeIcon: Icons.chat_bubble,
        label: 'Messages',
        color: AppColors.infoBlue,
      ),
      NavigationItem(
        icon: Icons.star_outline,
        activeIcon: Icons.star,
        label: 'Premium',
        color: AppColors.warningAmber,
      ),
    ];
  }

  void _startAnimations() {
    Future.delayed(const Duration(milliseconds: 800), () {
      if (mounted) {
        _navigationController.forward();
      }
    });
  }

  @override
  void dispose() {
    _tabController.dispose();
    _navigationController.dispose();
    super.dispose();
  }

  Future<void> _initializeLocationService() async {
    try {
      final locationService = Provider.of<LocationService>(context, listen: false);
      await locationService.initialize();
    } catch (e) {
      // Handle location service initialization error
      debugPrint('Location service initialization failed: $e');
    }
  }

  void _navigateToTab(int index) {
    if (index >= 0 && index < _pages.length) {
      setState(() {
        _currentIndex = index;
      });
      _tabController.animateTo(index);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          // Main content
          TabBarView(
            controller: _tabController,
            physics: const NeverScrollableScrollPhysics(),
            children: _pages,
          ),
          
          // Floating bottom navigation
          _buildFloatingNavigation(),
        ],
      ),
    );
  }

  Widget _buildFloatingNavigation() {
    return Positioned(
      bottom: 0,
      left: 0,
      right: 0,
      child: AnimatedBuilder(
        animation: _navigationController,
        builder: (context, child) {
          return SlideTransition(
            position: _slideAnimation,
            child: Transform.scale(
              scale: _scaleAnimation.value,
              child: Container(
                margin: const EdgeInsets.all(AppSpacing.lg),
                child: _buildNavigationBar(),
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildNavigationBar() {
    return Container(
      height: 80,
      decoration: BoxDecoration(
        gradient: AppColors.premiumGradient,
        borderRadius: BorderRadius.circular(AppBorderRadius.xLarge),
        boxShadow: AppShadows.floating,
        border: Border.all(
          color: Colors.white.withOpacity(0.2),
          width: 1,
        ),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(AppBorderRadius.xLarge),
        child: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [
                Colors.white.withOpacity(0.1),
                Colors.transparent,
              ],
            ),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: List.generate(
              _navigationItems.length,
              (index) => _buildNavigationItem(index),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildNavigationItem(int index) {
    final item = _navigationItems[index];
    final isSelected = _currentIndex == index;

    return AnimatedPressable(
      onPressed: () => _navigateToTab(index),
      child: Container(
        padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.md,
          vertical: AppSpacing.sm,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Icon with animation
            AnimatedContainer(
              duration: AppAnimations.fast,
              padding: const EdgeInsets.all(AppSpacing.sm),
              decoration: BoxDecoration(
                color: isSelected 
                    ? Colors.white.withOpacity(0.2)
                    : Colors.transparent,
                borderRadius: BorderRadius.circular(AppBorderRadius.medium),
              ),
              child: AnimatedSwitcher(
                duration: AppAnimations.fast,
                child: Icon(
                  isSelected ? item.activeIcon : item.icon,
                  key: ValueKey('${index}_${isSelected}'),
                  color: Colors.white,
                  size: 24,
                ),
              ),
            ),
            
            const SizedBox(height: 4),
            
            // Label with fade animation
            AnimatedOpacity(
              duration: AppAnimations.fast,
              opacity: isSelected ? 1.0 : 0.7,
              child: Text(
                item.label,
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: Colors.white,
                  fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
                ),
              ),
            ),
            
            // Selection indicator
            const SizedBox(height: 4),
            AnimatedContainer(
              duration: AppAnimations.fast,
              width: isSelected ? 20 : 0,
              height: 2,
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(1),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class NavigationItem {
  final IconData icon;
  final IconData activeIcon;
  final String label;
  final Color color;

  NavigationItem({
    required this.icon,
    required this.activeIcon,
    required this.label,
    required this.color,
  });
}
      await LocationService().initialize();
    } catch (e) {
      debugPrint('MainNavigationPage: Failed to initialize location service: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          // Main content
          TabBarView(
            controller: _tabController,
            children: _pages,
          ),
          
          // Floating Bottom Navigation
          Positioned(
            bottom: AppSpacing.lg,
            left: AppSpacing.lg,
            right: AppSpacing.lg,
            child: _buildFloatingNavBar(),
          ),
        ],
      ),
    );
  }

  Widget _buildFloatingNavBar() {
    return Container(
      height: 75,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            AppColors.backgroundWhite,
            AppColors.backgroundWhite.withOpacity(0.95),
          ],
        ),
        borderRadius: BorderRadius.circular(37.5),
        boxShadow: [
          BoxShadow(
            color: AppColors.primaryGold.withOpacity(0.2),
            blurRadius: 25,
            offset: const Offset(0, 8),
          ),
          BoxShadow(
            color: Colors.black.withOpacity(0.08),
            blurRadius: 15,
            offset: const Offset(0, 3),
          ),
        ],
        border: Border.all(
          color: AppColors.primaryGold.withOpacity(0.1),
          width: 1,
        ),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: [
          _buildNavItem(0, Icons.home, Icons.home_outlined, 'Accueil'),
          _buildNavItem(1, Icons.favorite, Icons.favorite_outline, 'Découvrir'),
          _buildNavItem(2, Icons.chat_bubble, Icons.chat_bubble_outline, 'Messages'),
          _buildNavItem(3, Icons.star, Icons.star_outline, 'GoldWen+'),
        ],
      ),
    );
  }

  Widget _buildNavItem(int index, IconData activeIcon, IconData inactiveIcon, String label) {
    final isSelected = _currentIndex == index;
    
    return Expanded(
      child: GestureDetector(
        onTap: () {
          setState(() {
            _currentIndex = index;
          });
          _tabController.animateTo(index);
        },
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          curve: Curves.easeInOut,
          height: 75,
          decoration: BoxDecoration(
            gradient: isSelected ? LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                AppColors.primaryGold,
                AppColors.primaryGold.withOpacity(0.8),
              ],
            ) : null,
            borderRadius: BorderRadius.circular(37.5),
            boxShadow: isSelected ? [
              BoxShadow(
                color: AppColors.primaryGold.withOpacity(0.3),
                blurRadius: 8,
                offset: const Offset(0, 2),
              ),
            ] : null,
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                curve: Curves.easeInOut,
                child: Icon(
                  isSelected ? activeIcon : inactiveIcon,
                  color: isSelected ? AppColors.textLight : AppColors.textSecondary,
                  size: isSelected ? 26 : 24,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                label,
                style: TextStyle(
                  color: isSelected ? AppColors.textLight : AppColors.textSecondary,
                  fontSize: 11,
                  fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}