import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';
import '../../../core/theme/app_theme.dart';
import '../providers/auth_provider.dart';
import '../../../core/services/api_service.dart';
import '../../onboarding/pages/personality_questionnaire_page.dart';

class EmailAuthPage extends StatefulWidget {
  const EmailAuthPage({super.key});

  @override
  State<EmailAuthPage> createState() => _EmailAuthPageState();
}

class _EmailAuthPageState extends State<EmailAuthPage> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _firstNameController = TextEditingController();
  final _lastNameController = TextEditingController();
  
  bool _isSignUp = false;
  bool _obscurePassword = true;
  String? _errorMessage;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
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
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.lg),
          child: Form(
            key: _formKey,
            child: Column(
              children: [
                const Spacer(),
                
                // Title
                Text(
                  _isSignUp ? 'Créer un compte' : 'Se connecter',
                  style: Theme.of(context).textTheme.headlineMedium,
                  textAlign: TextAlign.center,
                ),
                
                const SizedBox(height: AppSpacing.md),
                
                Text(
                  _isSignUp 
                    ? 'Rejoignez GoldWen pour des rencontres authentiques'
                    : 'Retrouvez votre compte GoldWen',
                  style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                    color: AppColors.textSecondary,
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
                          validator: (value) {
                            if (value == null || value.isEmpty) {
                              return 'Veuillez entrer votre prénom';
                            }
                            return null;
                          },
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
                          validator: (value) {
                            if (value == null || value.isEmpty) {
                              return 'Veuillez entrer votre nom';
                            }
                            return null;
                          },
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
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Veuillez entrer votre email';
                    }
                    if (!RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$').hasMatch(value)) {
                      return 'Veuillez entrer un email valide';
                    }
                    return null;
                  },
                ),
                
                const SizedBox(height: AppSpacing.lg),
                
                // Password field
                TextFormField(
                  controller: _passwordController,
                  decoration: InputDecoration(
                    labelText: 'Mot de passe',
                    hintText: _isSignUp ? 'Minimum 6 caractères' : 'Votre mot de passe',
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
                    if (value == null || value.isEmpty) {
                      return 'Veuillez entrer votre mot de passe';
                    }
                    if (_isSignUp && value.length < 6) {
                      return 'Le mot de passe doit contenir au moins 6 caractères';
                    }
                    return null;
                  },
                ),
                
                const SizedBox(height: AppSpacing.lg),
                
                // Error message
                if (_errorMessage != null) ...[
                  Container(
                    padding: const EdgeInsets.all(AppSpacing.md),
                    decoration: BoxDecoration(
                      color: Colors.red.shade50,
                      borderRadius: BorderRadius.circular(AppBorderRadius.medium),
                      border: Border.all(color: Colors.red.shade200),
                    ),
                    child: Row(
                      children: [
                        Icon(Icons.error_outline, color: Colors.red.shade600),
                        const SizedBox(width: AppSpacing.sm),
                        Expanded(
                          child: Text(
                            _errorMessage!,
                            style: TextStyle(color: Colors.red.shade600),
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
                    return SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed: authProvider.status == AuthStatus.loading
                            ? null
                            : _submitForm,
                        child: authProvider.status == AuthStatus.loading
                            ? const SizedBox(
                                width: 20,
                                height: 20,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                                ),
                              )
                            : Text(_isSignUp ? 'Créer mon compte' : 'Se connecter'),
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
        print('Starting sign in with email: ${_emailController.text.trim()}');
        await authProvider.signInWithEmail(
          email: _emailController.text.trim(),
          password: _passwordController.text,
        );
        print('Sign in completed. Auth status: ${authProvider.status}, isAuthenticated: ${authProvider.isAuthenticated}');
        
        // Wait a moment for the provider to notify listeners
        await Future.delayed(const Duration(milliseconds: 50));
        print('After delay - Auth status: ${authProvider.status}, isAuthenticated: ${authProvider.isAuthenticated}');
      }

      print('Checking authentication status...');
      print('authProvider.isAuthenticated: ${authProvider.isAuthenticated}');
      print('mounted: $mounted');
      
      if (authProvider.isAuthenticated && mounted) {
        print('Navigating to PersonalityQuestionnairePage...');
        Navigator.of(context).pushReplacement(
          MaterialPageRoute(
            builder: (context) => const PersonalityQuestionnairePage(),
          ),
        );
      } else {
        print('Not navigating: isAuthenticated=${authProvider.isAuthenticated}, mounted=$mounted');
        
        // If authentication succeeded but widget is not mounted, wait a bit and retry
        if (authProvider.isAuthenticated && !mounted) {
          print('Authentication succeeded but widget not mounted, retrying in 100ms...');
          await Future.delayed(const Duration(milliseconds: 100));
          if (mounted) {
            print('Widget now mounted, navigating...');
            Navigator.of(context).pushReplacement(
              MaterialPageRoute(
                builder: (context) => const PersonalityQuestionnairePage(),
              ),
            );
          }
        }
      }
    } catch (e) {
      setState(() {
        if (e is ApiException) {
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
          if (e is ApiException) {
            print('Status code: ${e.statusCode}');
            print('Error code: ${e.code}');
          }
          
          // Check if this might be a successful response that failed to parse
          if (e.toString().contains('201') || 
              e.toString().contains('200') || 
              e.toString().contains('JWT') ||
              e.toString().contains('token')) {
            _errorMessage = 'Connexion réussie mais erreur de traitement. Veuillez réessayer ou contacter le support si le problème persiste.';
          }
        }
      });
    }
  }
}