import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/services/location_service.dart';
import '../providers/auth_provider.dart';

class SplashPage extends StatefulWidget {
  const SplashPage({super.key});

  @override
  State<SplashPage> createState() => _SplashPageState();
}

class _SplashPageState extends State<SplashPage> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _checkAuthStatus();
    });
  }

  Future<void> _checkAuthStatus() async {
    final authProvider = Provider.of<AuthProvider>(context, listen: false);

    // Wait a bit for visual effect
    await Future.delayed(const Duration(seconds: 1));

    try {
      // Check authentication status and refresh user data from backend
      await authProvider.checkAuthStatus();
      
      // After checking auth status, refresh user data to get latest completion flags from backend
      if (authProvider.isAuthenticated && authProvider.user != null) {
        await authProvider.refreshUser(); // Fetch fresh user data from backend
        final user = authProvider.user!;

        print('=== USER AUTHENTICATION STATUS ===');
        print('User ID: ${user.id}');
        print('User email: ${user.email}');
        print('isOnboardingCompleted: ${user.isOnboardingCompleted}');
        print('isProfileCompleted: ${user.isProfileCompleted}');
        print('==================================');

        // User is authenticated, check location permission first
        bool hasLocationPermission = await LocationService.checkLocationPermission();
        
        print('Location permission status: $hasLocationPermission');
        
        if (!hasLocationPermission) {
          // In development/debug mode, skip location requirement for testing authentication
          print('DEBUG: No location permission - would redirect to /welcome');
          // TODO: Uncomment the lines below after location setup is configured
          if (mounted) {
            context.go('/gender-selection'); // Start fresh onboarding to handle location
          }
          return;
        }

        // Has location permission, check completion status from backend
        // Backend automatically updates these flags based on user progress:
        // - isOnboardingCompleted: true when personality questionnaire is completed
        // - isProfileCompleted: true when all requirements met (photos, prompts, personality, profile fields)
        if (user.isOnboardingCompleted == true && user.isProfileCompleted == true) {
          // Both onboarding and profile completed, initialize location service and go to main app
          LocationService().initialize();
          if (mounted) {
            context.go('/home');
          }
          return;
        } else if (user.isOnboardingCompleted == true) {
          // Onboarding done but profile not completed, go to profile setup
          if (mounted) {
            context.go('/profile-setup');
          }
          return;
        } else {
          // Authenticated but onboarding not completed, go to questionnaire
          if (mounted) {
            context.go('/questionnaire');
          }
          return;
        }
      }
    } catch (e) {
      print('Error checking auth status: $e');
    }

    // Not authenticated or error, go to welcome
    if (mounted) {
      context.go('/welcome');
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
            const Icon(
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
