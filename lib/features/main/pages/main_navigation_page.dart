import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/services/location_service.dart';
import 'home_page.dart';
import '../../matching/pages/daily_matches_page.dart';
import '../../chat/pages/chat_list_page.dart';
import '../../user/pages/user_profile_page.dart';

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
      const DailyMatchesPage(),
      const ChatListPage(),
      const UserProfilePage(),
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
    return DefaultTabController(
      length: 4,
      child: Scaffold(
        body: Stack(
          children: [
            // Main content
            TabBarView(
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
      ),
    );
  }

  Widget _buildFloatingNavBar() {
    return Container(
      height: 70,
      decoration: BoxDecoration(
        color: AppColors.backgroundWhite,
        borderRadius: BorderRadius.circular(35),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 20,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: [
          _buildNavItem(0, Icons.home, Icons.home_outlined, 'Accueil'),
          _buildNavItem(1, Icons.favorite, Icons.favorite_outline, 'Découvrir'),
          _buildNavItem(2, Icons.chat_bubble, Icons.chat_bubble_outline, 'Messages'),
          _buildNavItem(3, Icons.person, Icons.person_outline, 'Profil'),
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
        child: Container(
          height: 70,
          decoration: BoxDecoration(
            color: isSelected ? AppColors.primaryGold : Colors.transparent,
            borderRadius: BorderRadius.circular(35),
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                isSelected ? activeIcon : inactiveIcon,
                color: isSelected ? AppColors.textLight : AppColors.textSecondary,
                size: 24,
              ),
              const SizedBox(height: 4),
              Text(
                label,
                style: TextStyle(
                  color: isSelected ? AppColors.textLight : AppColors.textSecondary,
                  fontSize: 12,
                  fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}