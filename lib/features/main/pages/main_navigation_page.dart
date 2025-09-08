import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../core/theme/app_theme.dart';
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
  
  late final List<Widget> _pages;
  
  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 4, vsync: this);
    _pages = [
      HomePage(onNavigate: (index) {
        setState(() {
          _currentIndex = index;
        });
        _tabController.animateTo(index);
      }),
      DailyMatchesPage(),
      const ChatListPage(),
      const SubscriptionPage(),
    ];
    
    // Initialize location service to start background tracking
    _initializeLocationService();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _initializeLocationService() async {
    try {
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