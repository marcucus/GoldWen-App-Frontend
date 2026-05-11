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

class _SplashPageState extends State<SplashPage>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _fadeAnim;
  late Animation<double> _scaleAnim;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: AppAnimations.verySlow,
      vsync: this,
    );
    _fadeAnim = CurvedAnimation(parent: _controller, curve: Curves.easeIn);
    _scaleAnim = Tween<double>(begin: 0.85, end: 1.0).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeOut),
    );
    _controller.forward();

    WidgetsBinding.instance.addPostFrameCallback((_) {
      _checkAuthStatus();
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _checkAuthStatus() async {
    final authProvider = Provider.of<AuthProvider>(context, listen: false);

    await Future.delayed(const Duration(milliseconds: 1800));

    try {
      await authProvider.checkAuthStatus();

      if (authProvider.isAuthenticated && authProvider.user != null) {
        await authProvider.refreshUser();
        final user = authProvider.user!;

        final bool hasLocationPermission =
            await LocationService.checkLocationPermission();

        if (!hasLocationPermission) {
          if (mounted) context.go('/welcome');
          return;
        }

        if (user.isOnboardingCompleted == true &&
            user.isProfileCompleted == true) {
          LocationService().initialize();
          if (mounted) context.go('/home');
          return;
        } else if (user.isOnboardingCompleted == true) {
          if (mounted) context.go('/profile-setup');
          return;
        } else {
          if (mounted) context.go('/questionnaire');
          return;
        }
      }
    } catch (e) {
      debugPrint('Splash: auth check error: $e');
    }

    if (mounted) context.go('/welcome');
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: BoxDecoration(gradient: AppColors.welcomeGradient),
        child: FadeTransition(
          opacity: _fadeAnim,
          child: ScaleTransition(
            scale: _scaleAnim,
            child: Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  // Logo circle
                  Container(
                    width: 100,
                    height: 100,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      gradient: AppColors.premiumGradient,
                      boxShadow: AppShadows.gold(),
                    ),
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Image.asset(
                        'assets/images/logo_light.png',
                        fit: BoxFit.contain,
                      ),
                    ),
                  ),
                  const SizedBox(height: AppSpacing.lg),
                  // App name
                  Text(
                    'GoldWen',
                    style: Theme.of(context).textTheme.headlineLarge?.copyWith(
                          color: AppColors.textDark,
                          fontWeight: FontWeight.bold,
                          fontSize: 38,
                        ),
                  ),
                  const SizedBox(height: AppSpacing.sm),
                  // Tagline
                  Text(
                    '« Prenez le temps. »',
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          color: AppColors.textSecondary,
                          fontStyle: FontStyle.italic,
                          fontSize: 15,
                        ),
                  ),
                  const SizedBox(height: AppSpacing.xxl),
                  // Loading indicator
                  SizedBox(
                    width: 24,
                    height: 24,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      valueColor: AlwaysStoppedAnimation<Color>(
                        AppColors.primaryGold.withOpacity(0.6),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
