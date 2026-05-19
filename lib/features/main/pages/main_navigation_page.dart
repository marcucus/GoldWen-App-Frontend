import 'dart:async';
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
    with SingleTickerProviderStateMixin {
  int _currentIndex = 0;
  late AnimationController _navController;
  late Animation<Offset> _slideAnimation;
  bool _showTutorial = false;

  static const List<_NavItem> _navItems = [
    _NavItem(
      icon: Icons.diamond_outlined,
      activeIcon: Icons.diamond_rounded,
      label: 'Du jour',
    ),
    _NavItem(
      icon: Icons.chat_bubble_outline_rounded,
      activeIcon: Icons.chat_bubble_rounded,
      label: 'Messages',
    ),
    _NavItem(
      icon: Icons.person_outline_rounded,
      activeIcon: Icons.person_rounded,
      label: 'Profil',
    ),
    _NavItem(
      icon: Icons.tune_outlined,
      activeIcon: Icons.tune_rounded,
      label: 'Réglages',
    ),
  ];

  late final List<Widget> _pages;

  @override
  void initState() {
    super.initState();
    _navController = AnimationController(
      duration: const Duration(milliseconds: 600),
      vsync: this,
    );
    _slideAnimation = Tween<Offset>(
      begin: const Offset(0, 1.5),
      end: Offset.zero,
    ).animate(CurvedAnimation(parent: _navController, curve: Curves.easeOutCubic));

    _pages = [
      HomePage(onNavigate: _navigateToTab),
      const ChatListPage(),
      const UserProfilePage(),
      const SettingsPage(),
    ];

    unawaited(_initLocationService());
    unawaited(_checkTutorial());

    Future.delayed(const Duration(milliseconds: 400), () {
      if (mounted) _navController.forward();
    });
  }

  Future<void> _checkTutorial() async {
    final shouldShow = await OnboardingTutorialOverlay.shouldShow();
    if (mounted && shouldShow) {
      setState(() => _showTutorial = true);
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
      backgroundColor: AppColors.backgroundWhite,
      body: Stack(
        children: [
          IndexedStack(
            index: _currentIndex,
            children: _pages,
          ),
          Positioned(
            bottom: 0,
            left: 0,
            right: 0,
            child: SlideTransition(
              position: _slideAnimation,
              child: _buildNav(),
            ),
          ),
          if (_showTutorial)
            Positioned.fill(
              child: OnboardingTutorialOverlay(
                onDismiss: () => setState(() => _showTutorial = false),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildNav() {
    final bottomPadding = MediaQuery.of(context).padding.bottom;
    return Container(
      margin: EdgeInsets.fromLTRB(20, 0, 20, (bottomPadding > 0 ? bottomPadding : 16)),
      child: Container(
        height: 68,
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(22),
          border: Border.all(
            color: AppColors.primaryGold.withOpacity(0.18),
            width: 1.0,
          ),
          boxShadow: [
            BoxShadow(
              color: AppColors.primaryGold.withOpacity(0.10),
              blurRadius: 20,
              spreadRadius: 0,
              offset: const Offset(0, 6),
            ),
            BoxShadow(
              color: Colors.black.withOpacity(0.06),
              blurRadius: 10,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Row(
          children: List.generate(
            _navItems.length,
            (i) => _buildNavItem(i),
          ),
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
          mainAxisAlignment: MainAxisAlignment.center,
          mainAxisSize: MainAxisSize.min,
          children: [
            AnimatedContainer(
              duration: const Duration(milliseconds: 220),
              curve: Curves.easeOutCubic,
              width: 44,
              height: 38,
              decoration: BoxDecoration(
                color: isActive
                    ? AppColors.primaryGold.withOpacity(0.10)
                    : Colors.transparent,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Center(
                child: Icon(
                  isActive ? item.activeIcon : item.icon,
                  size: 22,
                  color: isActive
                      ? AppColors.primaryGold
                      : AppColors.textTertiary,
                ),
              ),
            ),
            const SizedBox(height: 3),
            AnimatedDefaultTextStyle(
              duration: const Duration(milliseconds: 220),
              style: TextStyle(
                fontFamily: 'Lato',
                fontSize: 10,
                fontWeight:
                    isActive ? FontWeight.w700 : FontWeight.w400,
                color: isActive
                    ? AppColors.primaryGold
                    : AppColors.textTertiary,
                letterSpacing: isActive ? 0.2 : 0,
                height: 1.0,
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
  const _NavItem({
    required this.icon,
    required this.activeIcon,
    required this.label,
  });
}
