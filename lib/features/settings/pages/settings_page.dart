import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';
import '../../../core/theme/app_theme.dart';
import '../../auth/providers/auth_provider.dart';
import '../../profile/providers/profile_provider.dart';

class SettingsPage extends StatefulWidget {
  const SettingsPage({super.key});

  @override
  State<SettingsPage> createState() => _SettingsPageState();
}

class _SettingsPageState extends State<SettingsPage> {
  @override
  void initState() {
    super.initState();
    _loadProfile();
  }

  void _loadProfile() {
    final profileProvider = Provider.of<ProfileProvider>(context, listen: false);
    profileProvider.loadProfile();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: BoxDecoration(
          gradient: AppColors.primaryGradient,
        ),
        child: SafeArea(
          child: Column(
            children: [
              // Header with back button
              Padding(
                padding: const EdgeInsets.all(AppSpacing.lg),
                child: Row(
                  children: [
                    Container(
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: AppColors.cardOverlay.withOpacity(0.2),
                      ),
                      child: IconButton(
                        onPressed: () => Navigator.of(context).pop(),
                        icon: const Icon(
                          Icons.arrow_back,
                          color: AppColors.textLight,
                        ),
                      ),
                    ),
                    const SizedBox(width: AppSpacing.md),
                    Expanded(
                      child: Text(
                        'Profil & Paramètres',
                        style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                          color: AppColors.textLight,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              
              // Content container
              Expanded(
                child: Container(
                  decoration: BoxDecoration(
                    color: AppColors.backgroundWhite,
                    borderRadius: const BorderRadius.only(
                      topLeft: Radius.circular(AppBorderRadius.xLarge),
                      topRight: Radius.circular(AppBorderRadius.xLarge),
                    ),
                  ),
                  child: Consumer<ProfileProvider>(
                    builder: (context, profileProvider, child) {
                      if (profileProvider.isLoading) {
                        return const Center(
                          child: CircularProgressIndicator(
                            valueColor: AlwaysStoppedAnimation<Color>(AppColors.primaryGold),
                          ),
                        );
                      }

                      return SingleChildScrollView(
                        padding: const EdgeInsets.all(AppSpacing.lg),
                        child: Column(
                          children: [
                            // Profile Header Section
                            _buildProfileHeader(profileProvider),
                            const SizedBox(height: AppSpacing.xl),
                            
                            // Profile Management Section
                            _buildSectionTitle('Mon Profil'),
                            const SizedBox(height: AppSpacing.md),
                            _buildProfileManagementSection(context, profileProvider),
                            const SizedBox(height: AppSpacing.xl),
                            
                            // Subscription Section
                            _buildSectionTitle('Abonnement'),
                            const SizedBox(height: AppSpacing.md),
                            _buildSubscriptionSection(context),
                            const SizedBox(height: AppSpacing.xl),
                            
                            // Settings Section
                            _buildSectionTitle('Paramètres'),
                            const SizedBox(height: AppSpacing.md),
                            _buildSettingsSection(context),
                            const SizedBox(height: AppSpacing.xl),
                            
                            // Help & Legal Section
                            _buildSectionTitle('Aide & Confidentialité'),
                            const SizedBox(height: AppSpacing.md),
                            _buildHelpSection(context),
                            const SizedBox(height: AppSpacing.xl),
                            
                            // Logout Section
                            _buildLogoutSection(context),
                            const SizedBox(height: AppSpacing.xl),
                          ],
                        ),
                      );
                    },
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildProfileHeader(ProfileProvider profileProvider) {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.lg),
      decoration: BoxDecoration(
        gradient: AppColors.cardGradient,
        borderRadius: BorderRadius.circular(AppBorderRadius.large),
        boxShadow: [
          BoxShadow(
            color: AppColors.primaryGold.withOpacity(0.1),
            blurRadius: 10,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Column(
        children: [
          // Profile photo
          Container(
            width: 100,
            height: 100,
            decoration: BoxDecoration(
              color: AppColors.primaryGold.withOpacity(0.3),
              shape: BoxShape.circle,
              border: Border.all(
                color: AppColors.primaryGold,
                width: 3,
              ),
            ),
            child: profileProvider.photos.isNotEmpty
                ? ClipOval(
                    child: Container(
                      color: AppColors.primaryGold.withOpacity(0.6),
                      child: const Icon(
                        Icons.person,
                        size: 50,
                        color: Colors.white,
                      ),
                    ),
                  )
                : const Icon(
                    Icons.person,
                    size: 50,
                    color: AppColors.primaryGold,
                  ),
          ),
          
          const SizedBox(height: AppSpacing.md),
          
          // Name and age
          Text(
            '${profileProvider.name}, ${profileProvider.age}',
            style: Theme.of(context).textTheme.headlineSmall?.copyWith(
              color: AppColors.primaryGold,
              fontWeight: FontWeight.bold,
            ),
          ),
          
          const SizedBox(height: AppSpacing.sm),
          
          // Bio
          if (profileProvider.bio?.isNotEmpty == true)
            Text(
              profileProvider.bio!,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: AppColors.textSecondary,
              ),
              textAlign: TextAlign.center,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
          
          // Stats row
          const SizedBox(height: AppSpacing.md),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _buildStatItem('Photos', '${profileProvider.photos.length}'),
              _buildStatItem('Matches', '3'),
              _buildStatItem('Messages', '2'),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildStatItem(String label, String value) {
    return Column(
      children: [
        Text(
          value,
          style: Theme.of(context).textTheme.titleMedium?.copyWith(
            color: AppColors.primaryGold,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 2),
        Text(
          label,
          style: Theme.of(context).textTheme.bodySmall?.copyWith(
            color: AppColors.textSecondary,
          ),
        ),
      ],
    );
  }

  Widget _buildSectionTitle(String title) {
    return Align(
      alignment: Alignment.centerLeft,
      child: Text(
        title,
        style: Theme.of(context).textTheme.titleLarge?.copyWith(
          color: AppColors.textDark,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }

  Widget _buildProfileManagementSection(BuildContext context, ProfileProvider profileProvider) {
    return Column(
      children: [
        _buildSettingItem(
          context,
          'Mes photos',
          '${profileProvider.photos.length} photo(s)',
          Icons.photo_library,
          () => _navigateToPhotoManagement(context),
        ),
        _buildSettingItem(
          context,
          'Mes réponses',
          profileProvider.prompts.isEmpty ? 'Non complété' : '${profileProvider.prompts.length} réponse(s)',
          Icons.quiz,
          () => _navigateToPromptsEditing(context),
        ),
        _buildSettingItem(
          context,
          'Préférences',
          'Critères de recherche',
          Icons.tune,
          () => _navigateToPreferences(context),
        ),
      ],
    );
  }

  Widget _buildSubscriptionSection(BuildContext context) {
    return Column(
      children: [
        _buildSettingItem(
          context,
          'GoldWen Plus',
          'Débloquez toutes les fonctionnalités',
          Icons.star,
          () => context.go('/subscription'),
          highlight: true,
        ),
      ],
    );
  }

  Widget _buildSettingsSection(BuildContext context) {
    return Column(
      children: [
        _buildSettingItem(
          context,
          'Notifications',
          'Gérer les notifications',
          Icons.notifications,
          () => _showNotificationSettings(context),
        ),
        _buildSettingItem(
          context,
          'Localisation',
          'Paramètres de géolocalisation',
          Icons.location_on,
          () => _showLocationSettings(context),
        ),
        _buildSettingItem(
          context,
          'Sécurité',
          'Mot de passe et sécurité',
          Icons.security,
          () => _showSecuritySettings(context),
        ),
      ],
    );
  }

  Widget _buildHelpSection(BuildContext context) {
    return Column(
      children: [
        _buildSettingItem(
          context,
          'Aide et support',
          'Besoin d\'aide ?',
          Icons.help,
          () => _showSupportDialog(context),
        ),
        _buildSettingItem(
          context,
          'Confidentialité',
          'Politique de confidentialité',
          Icons.privacy_tip,
          () => context.go('/privacy'),
        ),
        _buildSettingItem(
          context,
          'Conditions',
          'Conditions d\'utilisation',
          Icons.description,
          () => context.go('/terms'),
        ),
      ],
    );
  }

  Widget _buildLogoutSection(BuildContext context) {
    return Consumer<AuthProvider>(
      builder: (context, authProvider, child) {
        return _buildSettingItem(
          context,
          'Se déconnecter',
          'Déconnexion du compte',
          Icons.logout,
          () => _showLogoutDialog(context, authProvider),
          isDestructive: true,
        );
      },
    );
  }

  Widget _buildSettingItem(
    BuildContext context,
    String title,
    String subtitle,
    IconData icon,
    VoidCallback onTap, {
    bool highlight = false,
    bool isDestructive = false,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.sm),
      child: Card(
        elevation: 2,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppBorderRadius.medium),
        ),
        child: ListTile(
          leading: Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: isDestructive 
                  ? AppColors.errorRed.withOpacity(0.1)
                  : highlight 
                      ? AppColors.primaryGold.withOpacity(0.1)
                      : AppColors.primaryGold.withOpacity(0.1),
              borderRadius: BorderRadius.circular(AppBorderRadius.medium),
            ),
            child: Icon(
              icon,
              color: isDestructive 
                  ? AppColors.errorRed
                  : highlight 
                      ? AppColors.primaryGold
                      : AppColors.primaryGold,
            ),
          ),
          title: Text(
            title,
            style: TextStyle(
              color: isDestructive ? AppColors.errorRed : AppColors.textDark,
              fontWeight: FontWeight.w600,
            ),
          ),
          subtitle: Text(
            subtitle,
            style: TextStyle(
              color: isDestructive ? AppColors.errorRed.withOpacity(0.7) : AppColors.textSecondary,
            ),
          ),
          trailing: Icon(
            Icons.arrow_forward_ios, 
            size: 16,
            color: isDestructive ? AppColors.errorRed : AppColors.textSecondary,
          ),
          onTap: onTap,
        ),
      ),
    );
  }

  // Navigation methods
  void _navigateToPhotoManagement(BuildContext context) {
    context.go('/profile-setup');
  }
  
  void _navigateToPromptsEditing(BuildContext context) {
    context.go('/questionnaire');
  }
  
  void _navigateToPreferences(BuildContext context) {
    _showPreferencesDialog(context);
  }

  // Dialog methods
  void _showPreferencesDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Préférences'),
          content: const Text('Fonctionnalité de préférences en cours de développement. '
              'Vous pourrez bientôt personnaliser vos critères de recherche ici.'),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('OK'),
            ),
          ],
        );
      },
    );
  }

  void _showNotificationSettings(BuildContext context) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Notifications'),
          content: const Text('Paramètres de notification en cours de développement.'),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('OK'),
            ),
          ],
        );
      },
    );
  }

  void _showLocationSettings(BuildContext context) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Localisation'),
          content: const Text('Paramètres de géolocalisation en cours de développement.'),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('OK'),
            ),
          ],
        );
      },
    );
  }

  void _showSecuritySettings(BuildContext context) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Sécurité'),
          content: const Text('Paramètres de sécurité en cours de développement.'),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('OK'),
            ),
          ],
        );
      },
    );
  }
  
  void _showSupportDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Aide et Support'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('Pour toute question ou problème:'),
              const SizedBox(height: 12),
              const Text('📧 Email: support@goldwen.app'),
              const Text('💬 Chat: Disponible dans l\'app'),
              const Text('📱 Téléphone: +33 1 23 45 67 89'),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Fermer'),
            ),
            ElevatedButton(
              onPressed: () {
                Navigator.of(context).pop();
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Ouverture du chat support...')),
                );
              },
              child: const Text('Contacter'),
            ),
          ],
        );
      },
    );
  }

  void _showLogoutDialog(BuildContext context, AuthProvider authProvider) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Se déconnecter'),
          content: const Text('Êtes-vous sûr de vouloir vous déconnecter ?'),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Annuler'),
            ),
            ElevatedButton(
              onPressed: () {
                Navigator.of(context).pop();
                authProvider.signOut();
                context.go('/welcome');
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.errorRed,
              ),
              child: const Text('Se déconnecter'),
            ),
          ],
        );
      },
    );
  }
}