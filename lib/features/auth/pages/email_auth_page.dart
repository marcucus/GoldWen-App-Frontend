import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';
import '../../../core/theme/app_theme.dart';
import '../providers/auth_provider.dart';
import '../../../core/services/api_service.dart';
import '../../../core/widgets/rate_limit_dialog.dart';
import '../../../core/utils/form_validators.dart';

class EmailAuthPage extends StatefulWidget {
  const EmailAuthPage({super.key});

  @override
  State<EmailAuthPage> createState() => _EmailAuthPageState();
}

class _EmailAuthPageState extends State<EmailAuthPage> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();
  final _firstNameController = TextEditingController();
  final _lastNameController = TextEditingController();
  
  bool _isSignUp = false;
  bool _obscurePassword = true;
  bool _obscureConfirmPassword = true;
  String? _errorMessage;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    _firstNameController.dispose();
    _lastNameController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.of(context).pop(),
        ),
        backgroundColor: Colors.transparent,
        elevation: 0,
      ),
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              AppColors.backgroundWhite,
              AppColors.accentCream.withOpacity(0.3),
              AppColors.backgroundWhite,
            ],
            stops: const [0.0, 0.5, 1.0],
          ),
        ),
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: AppSpacing.xl, vertical: AppSpacing.lg),
            child: Form(
              key: _formKey,
              child: Column(
                children: [
                  const Spacer(),
                  
                  // Title with icon
                  Container(
                    padding: const EdgeInsets.all(AppSpacing.md),
                    decoration: BoxDecoration(
                      color: AppColors.primaryGold.withOpacity(0.1),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      _isSignUp ? Icons.person_add_outlined : Icons.lock_outline,
                      size: 32,
                      color: AppColors.primaryGold,
                    ),
                  ),
                  
                  const SizedBox(height: AppSpacing.lg),
                  
                  // Title
                  Text(
                    _isSignUp ? 'Créer un compte' : 'Se connecter',
                    style: Theme.of(context).textTheme.headlineLarge?.copyWith(
                      color: AppColors.primaryGold,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  
                  const SizedBox(height: AppSpacing.md),
                  
                  Text(
                    _isSignUp 
                      ? 'Rejoignez GoldWen pour des rencontres authentiques et significatives'
                      : 'Reconnectez-vous à votre parcours vers l\'amour',
                    style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                      color: AppColors.textSecondary,
                      height: 1.6,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  
                  const SizedBox(height: AppSpacing.xxl),
                
                // Sign up fields
                if (_isSignUp) ...[
                  Row(
                    children: [
                      Expanded(
                        child: TextFormField(
                          controller: _firstNameController,
                          decoration: const InputDecoration(
                            labelText: 'Prénom',
                            hintText: 'Votre prénom',
                          ),
                          textCapitalization: TextCapitalization.words,
                          validator: FormValidators.validateFirstName,
                        ),
                      ),
                      const SizedBox(width: AppSpacing.md),
                      Expanded(
                        child: TextFormField(
                          controller: _lastNameController,
                          decoration: const InputDecoration(
                            labelText: 'Nom',
                            hintText: 'Votre nom',
                          ),
                          textCapitalization: TextCapitalization.words,
                          validator: FormValidators.validateLastName,
                        ),
                      ),
                    ],
                  ),
                  
                  const SizedBox(height: AppSpacing.lg),
                ],
                
                // Email field
                TextFormField(
                  controller: _emailController,
                  decoration: const InputDecoration(
                    labelText: 'Email',
                    hintText: 'votre@email.com',
                    prefixIcon: Icon(Icons.email_outlined),
                  ),
                  keyboardType: TextInputType.emailAddress,
                  validator: FormValidators.validateEmail,
                ),
                
                const SizedBox(height: AppSpacing.lg),
                
                // Password field
                TextFormField(
                  controller: _passwordController,
                  decoration: InputDecoration(
                    labelText: 'Mot de passe',
                    hintText: _isSignUp ? 'Min 6 caractères, 1 majuscule, 1 caractère spécial' : 'Votre mot de passe',
                    prefixIcon: const Icon(Icons.lock_outline),
                    suffixIcon: IconButton(
                      icon: Icon(
                        _obscurePassword ? Icons.visibility_off : Icons.visibility,
                      ),
                      onPressed: () {
                        setState(() {
                          _obscurePassword = !_obscurePassword;
                        });
                      },
                    ),
                  ),
                  obscureText: _obscurePassword,
                  validator: (value) {
                    if (_isSignUp) return FormValidators.validatePassword(value);
                    if (value == null || value.isEmpty) return 'Veuillez entrer votre mot de passe';
                    return null;
                  },
                ),
                
                const SizedBox(height: AppSpacing.lg),
                
                // Confirm password field (only for sign up)
                if (_isSignUp)
                  TextFormField(
                    controller: _confirmPasswordController,
                    decoration: InputDecoration(
                      labelText: 'Confirmer le mot de passe',
                      hintText: 'Confirmez votre mot de passe',
                      prefixIcon: const Icon(Icons.lock_outline),
                      suffixIcon: IconButton(
                        icon: Icon(
                          _obscureConfirmPassword ? Icons.visibility_off : Icons.visibility,
                        ),
                        onPressed: () {
                          setState(() {
                            _obscureConfirmPassword = !_obscureConfirmPassword;
                          });
                        },
                      ),
                    ),
                    obscureText: _obscureConfirmPassword,
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'Veuillez confirmer votre mot de passe';
                      }
                      if (value != _passwordController.text) {
                        return 'Les mots de passe ne correspondent pas';
                      }
                      return null;
                    },
                  ),
                
                if (_isSignUp) const SizedBox(height: AppSpacing.lg),
                
                // Error message
                if (_errorMessage != null) ...[
                  Container(
                    padding: const EdgeInsets.all(AppSpacing.md),
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                        colors: [
                          AppColors.errorRed.withOpacity(0.1),
                          AppColors.errorRed.withOpacity(0.05),
                        ],
                      ),
                      borderRadius: BorderRadius.circular(AppBorderRadius.medium),
                      border: Border.all(
                        color: AppColors.errorRed.withOpacity(0.3),
                        width: 1,
                      ),
                    ),
                    child: Row(
                      children: [
                        Icon(
                          Icons.error_outline_rounded,
                          color: AppColors.errorRed,
                          size: 22,
                        ),
                        const SizedBox(width: AppSpacing.sm),
                        Expanded(
                          child: Text(
                            _errorMessage!,
                            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                              color: AppColors.errorRed,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: AppSpacing.lg),
                ],
                
                // Submit button
                Consumer<AuthProvider>(
                  builder: (context, authProvider, child) {
                    return Container(
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(AppBorderRadius.medium),
                        boxShadow: authProvider.status != AuthStatus.loading ? [
                          BoxShadow(
                            color: AppColors.primaryGold.withOpacity(0.3),
                            blurRadius: 12,
                            offset: const Offset(0, 4),
                          ),
                        ] : [],
                      ),
                      child: SizedBox(
                        width: double.infinity,
                        child: ElevatedButton(
                          onPressed: authProvider.status == AuthStatus.loading
                              ? null
                              : _submitForm,
                          style: ElevatedButton.styleFrom(
                            padding: const EdgeInsets.symmetric(vertical: 18),
                            elevation: 0,
                          ),
                          child: authProvider.status == AuthStatus.loading
                              ? const SizedBox(
                                  width: 20,
                                  height: 20,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                    valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                                  ),
                                )
                              : Text(
                                  _isSignUp ? 'Créer mon compte' : 'Se connecter',
                                  style: const TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                        ),
                      ),
                    );
                  },
                ),
                
                const SizedBox(height: AppSpacing.lg),
                
                // Switch between sign in and sign up
                TextButton(
                  onPressed: () {
                    setState(() {
                      _isSignUp = !_isSignUp;
                      _errorMessage = null;
                    });
                  },
                  child: Text(
                    _isSignUp 
                      ? 'Déjà un compte ? Se connecter'
                      : 'Pas encore de compte ? S\'inscrire',
                  ),
                ),
                
                const Spacer(),
              ],
            ),
          ),
        ),
      ),
      ),
    );
  }

  Future<void> _submitForm() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    setState(() {
      _errorMessage = null;
    });

    final authProvider = Provider.of<AuthProvider>(context, listen: false);

    try {
      if (_isSignUp) {
        await authProvider.registerWithEmail(
          email: _emailController.text.trim(),
          password: _passwordController.text,
          firstName: _firstNameController.text.trim(),
          lastName: _lastNameController.text.trim(),
        );
      } else {
        await authProvider.signInWithEmail(
          email: _emailController.text.trim(),
          password: _passwordController.text,
        );
      }

      if (authProvider.isAuthenticated && mounted) {
        context.go('/splash');
      }
    } catch (e) {
      setState(() {
        if (e is ApiException) {
          // Handle rate limit errors specially
          if (e.isRateLimitError) {
            // Show rate limit dialog instead of inline error
            if (mounted) {
              RateLimitDialog.show(
                context,
                e,
                onRetry: _submitForm,
              );
            }
            return;
          }
          
          _errorMessage = e.message;
          // Show more specific error messages for common issues
          if (e.statusCode == 0 || e.message.contains('connection')) {
            _errorMessage = 'Problème de connexion au serveur. Vérifiez votre connexion internet et que le serveur backend est démarré.';
          }
        } else {
          _errorMessage = 'Une erreur est survenue. Veuillez réessayer.';
          // Show connection issues more clearly
          if (e.toString().contains('Connection') || e.toString().contains('Network') || e.toString().contains('Socket')) {
            _errorMessage = 'Impossible de se connecter au serveur. Assurez-vous que le backend est démarré sur localhost:3000.';
          }
        }
        // Debug information for development
        if (mounted) {
          print('Auth error: $e');
        }
      });
    }
  }
}