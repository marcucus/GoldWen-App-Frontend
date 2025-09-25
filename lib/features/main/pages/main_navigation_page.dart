import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';
import '../../../core/services/location_service.dart';
import '../../auth/providers/auth_provider.dart';
import 'home_page.dart';
import '../../matching/pages/daily_matches_page.dart';
import '../../chat/pages/chat_list_page.dart';
import '../../subscription/pages/subscription_page.dart';

class MainNavigationPage extends StatefulWidget {
  const MainNavigationPage({super.key});

  @override
  State<MainNavigationPage> createState() => _MainNavigationPageState();
}

class _MainNavigationPageState extends State<MainNavigationPage>
    with TickerProviderStateMixin {
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
      duration: const Duration(milliseconds: 600),
      vsync: this,
    );

    _scaleAnimation = Tween<double>(
      begin: 0.8,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _navigationController,
      curve: Curves.elasticOut,
    ));

    _slideAnimation = Tween<Offset>(
      begin: const Offset(0, 1),
      end: Offset.zero,
    ).animate(CurvedAnimation(
      parent: _navigationController,
      curve: Curves.easeOut,
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
        color: Colors.amber,
      ),
      NavigationItem(
        icon: Icons.favorite_outline,
        activeIcon: Icons.favorite,
        label: 'Découvrir',
        color: Colors.red,
      ),
      NavigationItem(
        icon: Icons.chat_bubble_outline,
        activeIcon: Icons.chat_bubble,
        label: 'Messages',
        color: Colors.blue,
      ),
      NavigationItem(
        icon: Icons.star_outline,
        activeIcon: Icons.star,
        label: 'Premium',
        color: Colors.purple,
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

  Future<void> _initializeLocationService() async {
    try {
      // Try to get location service from provider if available
      if (mounted) {
        final context = this.context;
        final locationService = context.read<LocationService?>();
        await locationService?.initialize();
      }
    } catch (e) {
      debugPrint(
          'MainNavigationPage: Failed to initialize location service: $e');
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
  void dispose() {
    _tabController.dispose();
    _navigationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<AuthProvider>(
      builder: (context, authProvider, child) {
        // Check if profile is completed - if not, redirect to complete it
        final user = authProvider.user;
        if (user != null && (user.isProfileCompleted != true)) {
          WidgetsBinding.instance.addPostFrameCallback((_) {
            if (mounted) {
              context.go('/profile-setup');
            }
          });
          return const Scaffold(
            body: Center(child: CircularProgressIndicator()),
          );
        }

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
      },
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
                margin: const EdgeInsets.all(16.0),
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
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Colors.amber.shade700,
            Colors.amber.shade800,
          ],
        ),
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: Colors.amber.withOpacity(0.3),
            blurRadius: 15,
            offset: const Offset(0, 8),
          ),
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
        border: Border.all(
          color: Colors.white.withOpacity(0.2),
          width: 1,
        ),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(24),
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

    return Expanded(
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () => _navigateToTab(index),
          borderRadius: BorderRadius.circular(16),
          child: Container(
            padding: const EdgeInsets.symmetric(
              horizontal: 12,
              vertical: 8,
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Icon with animation
                AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: isSelected
                        ? Colors.white.withOpacity(0.2)
                        : Colors.transparent,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: AnimatedSwitcher(
                    duration: const Duration(milliseconds: 200),
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
                  duration: const Duration(milliseconds: 200),
                  opacity: isSelected ? 1.0 : 0.7,
                  child: Text(
                    item.label,
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: Colors.white,
                          fontWeight:
                              isSelected ? FontWeight.w600 : FontWeight.w500,
                          fontSize: 11,
                        ),
                  ),
                ),

                // Selection indicator
                const SizedBox(height: 4),
                AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
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
