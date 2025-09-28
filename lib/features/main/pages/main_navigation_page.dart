import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';
import '../../../core/services/location_service.dart';
import '../../../shared/widgets/enhanced_navigation.dart';
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
  late final List<BottomNavigationItem> _navigationItems;

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
      BottomNavigationItem(
        icon: Icons.home_outlined,
        activeIcon: Icons.home,
        label: 'Accueil',
      ),
      BottomNavigationItem(
        icon: Icons.favorite_outline,
        activeIcon: Icons.favorite,
        label: 'Découvrir',
      ),
      BottomNavigationItem(
        icon: Icons.chat_bubble_outline,
        activeIcon: Icons.chat_bubble,
        label: 'Messages',
      ),
      BottomNavigationItem(
        icon: Icons.star_outline,
        activeIcon: Icons.star,
        label: 'Premium',
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
              child: EnhancedBottomNavigation(
                currentIndex: _currentIndex,
                onTap: _navigateToTab,
                items: _navigationItems,
                height: 70.0,
              ),
            ),
          );
        },
      ),
    );
  }

}
