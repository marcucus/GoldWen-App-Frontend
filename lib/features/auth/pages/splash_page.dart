import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';
import '../../../core/theme/app_theme.dart';
import '../providers/auth_provider.dart';
import '../../onboarding/pages/welcome_page.dart';
import '../../onboarding/pages/personality_questionnaire_page.dart';
import '../../profile/pages/profile_setup_page.dart';
import '../../main/pages/main_navigation_page.dart';

class SplashPage extends StatefulWidget {
  const SplashPage({super.key});

  @override
  State<SplashPage> createState() => _SplashPageState();
}

class _SplashPageState extends State<SplashPage> {
  @override
  void initState() {
    super.initState();
    _checkAuthStatus();
  }

  Future<void> _checkAuthStatus() async {
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    
    // Wait a bit for visual effect
    await Future.delayed(const Duration(seconds: 1));
    
    try {
      // For now, just check if the user is already authenticated in memory
      // In a full implementation, this would check for stored tokens
      if (authProvider.isAuthenticated && authProvider.user != null) {
        final user = authProvider.user!;
        
        // User is authenticated, check completion status
        if (user.isProfileCompleted == true) {
          // Profile completed, go to main app
          if (mounted) {
            Navigator.of(context).pushReplacement(
              MaterialPageRoute(
                builder: (context) => const MainNavigationPage(),
              ),
            );
          }
          return;
        } else if (user.isOnboardingCompleted == true) {
          // Onboarding done but profile not completed, go to profile setup
          if (mounted) {
            Navigator.of(context).pushReplacement(
              MaterialPageRoute(
                builder: (context) => const ProfileSetupPage(),
              ),
            );
          }
          return;
        } else {
          // Authenticated but onboarding not completed, go to questionnaire
          if (mounted) {
            Navigator.of(context).pushReplacement(
              MaterialPageRoute(
                builder: (context) => const PersonalityQuestionnairePage(),
              ),
            );
          }
          return;
        }
      }
    } catch (e) {
      print('Error checking auth status: $e');
    }
    
    // Not authenticated or error, go to welcome
    if (mounted) {
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(
          builder: (context) => const WelcomePage(),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.backgroundWhite,
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // App logo or icon
            Icon(
              Icons.favorite,
              size: 80,
              color: AppColors.primaryGold,
            ),
            const SizedBox(height: AppSpacing.md),
            Text(
              'GoldWen',
              style: Theme.of(context).textTheme.headlineLarge?.copyWith(
                color: AppColors.primaryGold,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: AppSpacing.xxl),
            // Loading indicator
            const CircularProgressIndicator(
              valueColor: AlwaysStoppedAnimation<Color>(AppColors.primaryGold),
            ),
          ],
        ),
      ),
    );
  }
}