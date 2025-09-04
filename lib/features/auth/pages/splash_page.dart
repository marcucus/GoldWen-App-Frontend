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
      // For now, just check if the user is already authenticated in memory
      // In a full implementation, this would check for stored tokens
      if (authProvider.isAuthenticated && authProvider.user != null) {
        final user = authProvider.user!;

        // User is authenticated, check location permission first
        bool hasLocationPermission = await LocationService.checkLocationPermission();
        
        if (!hasLocationPermission) {
          // No location permission, redirect to location setup regardless of profile completion
          if (mounted) {
            context.go('/welcome'); // Start fresh onboarding to handle location
          }
          return;
        }

        // Has location permission, check completion status
        if (user.isProfileCompleted == true) {
          // Profile completed and has location, initialize location service and go to main app
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
