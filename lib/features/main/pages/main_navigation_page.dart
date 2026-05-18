import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/services/location_service.dart';
import 'home_page.dart';
import '../../chat/pages/chat_list_page.dart';
import '../../user/pages/user_profile_page.dart';
import '../../settings/pages/settings_page.dart';
import '../../onboarding/widgets/onboarding_tutorial_overlay.dart';

class MainNavigationPage extends StatefulWidget {
  const MainNavigationPage({super.key});

  @override
  State<MainNavigationPage> createState() => _MainNavigationPageState();
}

class _MainNavigationPageState extends State<MainNavigationPage>
    with TickerProviderStateMixin {
  int _currentIndex = 0;
  late AnimationController _navController;
  late Animation<Offset> _slideAnimation;
  bool _showTutorial = false;

  static const List<_NavItem> _navItems = [
    _NavItem(icon: Icons.favorite_border_rounded, activeIcon: Icons.favorite_rounded, label: 'Du jour'),
    _NavItem(icon: Icons.chat_bubble_outline_rounded, activeIcon: Icons.chat_bubble_rounded, label: 'Messages'),
    _NavItem(icon: Icons.person_outline_rounded, activeIcon: Icons.person_rounded, label: 'Profil'),
    _NavItem(icon: Icons.settings_outlined, activeIcon: Icons.settings_rounded, label: 'Réglages'),
  ];

  late final List<Widget> _pages;

  @override
  void initState() {
    super.initState();
    _navController = AnimationController(
      duration: const Duration(milliseconds: 500),
      vsync: this,
    );
    _slideAnimation = Tween<Offset>(
      begin: const Offset(0, 1.5),
      end: Offset.zero,
    ).animate(CurvedAnimation(parent: _navController, curve: Curves.easeOut));

    _pages = [
      HomePage(onNavigate: _navigateToTab),
      const ChatListPage(),
      const UserProfilePage(),
      const SettingsPage(),
    ];

    _initLocationService();
    _checkTutorial();

    Future.delayed(const Duration(milliseconds: 600), () {
      if (mounted) _navController.forward();
    });
  }

  Future<void> _checkTutorial() async {
    final shouldShow = await OnboardingTutorialOverlay.shouldShow();
    if (mounted && shouldShow) {
      setState(() {
        _showTutorial = true;
      });
    }
  }

  Future<void> _initLocationService() async {
    try {
      final locationService = context.read<LocationService?>();
      await locationService?.initialize();
    } catch (_) {}
  }

  void _navigateToTab(int index) {
    if (index >= 0 && index < _pages.length) {
      setState(() => _currentIndex = index);
    }
  }

  @override
  void dispose() {
    _navController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          // Page content
          IndexedStack(
            index: _currentIndex,
            children: _pages,
          ),
          // Floating dark glass bottom nav
          Positioned(
            bottom: 0,
            left: 0,
            right: 0,
            child: SlideTransition(
              position: _slideAnimation,
              child: _buildNav(),
            ),
          ),
          // First-login tutorial overlay
          if (_showTutorial)
            Positioned.fill(
              child: OnboardingTutorialOverlay(
                onDismiss: () {
                  setState(() {
                    _showTutorial = false;
                  });
                },
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildNav() {
    final bottomPadding = MediaQuery.of(context).padding.bottom;
    return Container(
      margin: const EdgeInsets.fromLTRB(16, 0, 16, 12),
      padding: EdgeInsets.fromLTRB(8, 8, 8, 8 + (bottomPadding > 0 ? 0 : 0)),
      decoration: BoxDecoration(
        color: const Color(0xEB1A1A1A),
        borderRadius: BorderRadius.circular(28),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.30),
            blurRadius: 30,
            offset: const Offset(0, 10),
          ),
          BoxShadow(
            color: AppColors.primaryGold.withOpacity(0.18),
            blurRadius: 0,
            spreadRadius: 1,
          ),
        ],
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: List.generate(
          _navItems.length,
          (i) => _buildNavItem(i),
        ),
      ),
    );
  }

  Widget _buildNavItem(int index) {
    final item = _navItems[index];
    final isActive = _currentIndex == index;

    return Expanded(
      child: GestureDetector(
        onTap: () => _navigateToTab(index),
        behavior: HitTestBehavior.opaque,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            AnimatedContainer(
              duration: AppAnimations.fast,
              width: 52,
              height: 52,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: isActive ? AppColors.premiumGradient : null,
                color: isActive ? null : Colors.transparent,
              ),
              child: Icon(
                isActive ? item.activeIcon : item.icon,
                size: 24,
                color: isActive
                    ? Colors.white
                    : Colors.white.withOpacity(0.55),
              ),
            ),
            const SizedBox(height: 4),
            AnimatedDefaultTextStyle(
              duration: AppAnimations.fast,
              style: TextStyle(
                fontFamily: 'Lato',
                fontSize: 11,
                fontWeight: isActive ? FontWeight.w700 : FontWeight.w500,
                color: isActive
                    ? AppColors.primaryGold
                    : Colors.white.withOpacity(0.55),
              ),
              child: Text(item.label),
            ),
          ],
        ),
      ),
    );
  }
}

class _NavItem {
  final IconData icon;
  final IconData activeIcon;
  final String label;
  const _NavItem({required this.icon, required this.activeIcon, required this.label});
}
