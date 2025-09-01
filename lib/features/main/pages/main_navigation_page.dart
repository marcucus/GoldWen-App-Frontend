import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/theme/theme_provider.dart';
import '../../matching/pages/daily_matches_page.dart';
import '../../chat/pages/chat_list_page.dart';
import '../../user/pages/user_profile_page.dart';

class MainNavigationPage extends StatefulWidget {
  const MainNavigationPage({super.key});

  @override
  State<MainNavigationPage> createState() => _MainNavigationPageState();
}

class _MainNavigationPageState extends State<MainNavigationPage> {
  int _currentIndex = 0;
  
  late final List<Widget> _pages;
  
  @override
  void initState() {
    super.initState();
    _pages = [
      const DailyMatchesPage(),
      const ChatListPage(),
      const UserProfilePage(),
    ];
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: IndexedStack(
        index: _currentIndex,
        children: _pages,
      ),
      bottomNavigationBar: Consumer<ThemeProvider>(
        builder: (context, themeProvider, child) {
          return BottomNavigationBar(
            currentIndex: _currentIndex,
            onTap: (index) {
              setState(() {
                _currentIndex = index;
              });
            },
            type: BottomNavigationBarType.fixed,
            selectedItemColor: themeProvider.isDarkMode 
                ? AppColors.primaryGoldDark 
                : AppColors.primaryGold,
            unselectedItemColor: themeProvider.isDarkMode 
                ? AppColors.textSecondaryDark 
                : AppColors.textSecondary,
            backgroundColor: themeProvider.isDarkMode 
                ? AppColors.backgroundDark 
                : AppColors.backgroundWhite,
            elevation: 8,
            items: const [
              BottomNavigationBarItem(
                icon: Icon(Icons.favorite),
                activeIcon: Icon(Icons.favorite),
                label: 'Découvrir',
              ),
              BottomNavigationBarItem(
                icon: Icon(Icons.chat_bubble_outline),
                activeIcon: Icon(Icons.chat_bubble),
                label: 'Messages',
              ),
              BottomNavigationBarItem(
                icon: Icon(Icons.person_outline),
                activeIcon: Icon(Icons.person),
                label: 'Profil',
              ),
            ],
          );
        },
      ),
    );
  }
}