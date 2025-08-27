import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';
import '../../../core/theme/app_theme.dart';
import '../providers/auth_provider.dart';

class AuthPage extends StatefulWidget {
  const AuthPage({super.key});

  @override
  State<AuthPage> createState() => _AuthPageState();
}

class _AuthPageState extends State<AuthPage> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => context.go('/welcome'),
        ),
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.lg),
          child: Column(
            children: [
              const Spacer(),
              
              // Title
              Text(
                'Connectez-vous',
                style: Theme.of(context).textTheme.headlineMedium,
                textAlign: TextAlign.center,
              ),
              
              const SizedBox(height: AppSpacing.md),
              
              Text(
                'Choisissez votre méthode de connexion préférée',
                style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                  color: AppColors.textSecondary,
                ),
                textAlign: TextAlign.center,
              ),
              
              const SizedBox(height: AppSpacing.xxl),
              
              // Email/Password Login Section
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () => context.go('/login'),
                  child: const Text('Se connecter avec email'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primaryGold,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                  ),
                ),
              ),
              
              const SizedBox(height: AppSpacing.md),
              
              SizedBox(
                width: double.infinity,
                child: OutlinedButton(
                  onPressed: () => context.go('/register'),
                  child: const Text('Créer un compte'),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: AppColors.primaryGold,
                    side: const BorderSide(color: AppColors.primaryGold),
                    padding: const EdgeInsets.symmetric(vertical: 16),
                  ),
                ),
              ),
              
              const SizedBox(height: AppSpacing.xl),
              
              // Divider
              Row(
                children: [
                  const Expanded(child: Divider()),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md),
                    child: Text(
                      'Ou continuer avec',
                      style: Theme.of(context).textTheme.bodySmall,
                    ),
                  ),
                  const Expanded(child: Divider()),
                ],
              ),
              
              const SizedBox(height: AppSpacing.xl),
              
              // Google Sign In
              Consumer<AuthProvider>(
                builder: (context, authProvider, child) {
                  return SizedBox(
                    width: double.infinity,
                    child: ElevatedButton.icon(
                      onPressed: authProvider.status == AuthStatus.loading
                          ? null
                          : () async {
                              await authProvider.signInWithGoogle();
                              if (authProvider.isAuthenticated && mounted) {
                                context.go('/questionnaire');
                              }
                            },
                      icon: authProvider.status == AuthStatus.loading
                          ? const SizedBox(
                              width: 20,
                              height: 20,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                              ),
                            )
                          : const Icon(Icons.g_mobiledata, size: 24),
                      label: Text(
                        authProvider.status == AuthStatus.loading
                            ? 'Connexion...'
                            : 'Continuer avec Google',
                      ),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.white,
                        foregroundColor: AppColors.textDark,
                        side: const BorderSide(color: AppColors.dividerLight),
                        padding: const EdgeInsets.symmetric(vertical: 16),
                      ),
                    ),
                  );
                },
              ),
              
              const SizedBox(height: AppSpacing.md),
              
              // Apple Sign In
              Consumer<AuthProvider>(
                builder: (context, authProvider, child) {
                  return SizedBox(
                    width: double.infinity,
                    child: ElevatedButton.icon(
                      onPressed: authProvider.status == AuthStatus.loading
                          ? null
                          : () async {
                              await authProvider.signInWithApple();
                              if (authProvider.isAuthenticated && mounted) {
                                context.go('/questionnaire');
                              }
                            },
                      icon: authProvider.status == AuthStatus.loading
                          ? const SizedBox(
                              width: 20,
                              height: 20,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                              ),
                            )
                          : const Icon(Icons.apple, size: 24),
                      label: Text(
                        authProvider.status == AuthStatus.loading
                            ? 'Connexion...'
                            : 'Continuer avec Apple',
                      ),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.black,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 16),
                      ),
                    ),
                  );
                },
              ),
              
              const SizedBox(height: AppSpacing.xxl),
              
              // Divider
              Row(
                children: [
                  const Expanded(child: Divider()),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md),
                    child: Text(
                      'Connexion rapide',
                      style: Theme.of(context).textTheme.bodySmall,
                    ),
                  ),
                  const Expanded(child: Divider()),
                ],
              ),
              
              const SizedBox(height: AppSpacing.lg),
              
              // Privacy note
              Container(
                padding: const EdgeInsets.all(AppSpacing.md),
                decoration: BoxDecoration(
                  color: AppColors.accentCream,
                  borderRadius: BorderRadius.circular(AppBorderRadius.medium),
                ),
                child: Column(
                  children: [
                    Icon(
                      Icons.security,
                      color: AppColors.primaryGold,
                      size: 32,
                    ),
                    const SizedBox(height: AppSpacing.sm),
                    Text(
                      'Vos données sont protégées',
                      style: Theme.of(context).textTheme.labelLarge,
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: AppSpacing.xs),
                    Text(
                      'Nous utilisons des méthodes de connexion sécurisées et ne stockons jamais vos mots de passe.',
                      style: Theme.of(context).textTheme.bodySmall,
                      textAlign: TextAlign.center,
                    ),
                  ],
                ),
              ),
              
              const Spacer(),
            ],
          ),
        ),
      ),
    );
  }
}