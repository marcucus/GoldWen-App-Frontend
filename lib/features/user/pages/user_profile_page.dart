import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';
import '../../../core/theme/app_theme.dart';
import '../../auth/providers/auth_provider.dart';
import '../../profile/providers/profile_provider.dart';

class UserProfilePage extends StatefulWidget {
  const UserProfilePage({super.key});

  @override
  State<UserProfilePage> createState() => _UserProfilePageState();
}

class _UserProfilePageState extends State<UserProfilePage> {
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
      appBar: AppBar(
        title: const Text('Mon profil'),
        automaticallyImplyLeading: false,
        actions: [
          IconButton(
            icon: const Icon(Icons.settings),
            onPressed: () {
              _showSettingsBottomSheet(context);
            },
          ),
        ],
      ),
      body: Consumer<ProfileProvider>(
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
                _buildProfileHeader(profileProvider),
                const SizedBox(height: AppSpacing.xl),
                _buildProfileStats(),
                const SizedBox(height: AppSpacing.xl),
                _buildProfileSections(context, profileProvider),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildProfileHeader(ProfileProvider profileProvider) {
    return Column(
      children: [
        // Profile photo
        Container(
          width: 120,
          height: 120,
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
                      size: 60,
                      color: Colors.white,
                    ),
                  ),
                )
              : const Icon(
                  Icons.person,
                  size: 60,
                  color: AppColors.primaryGold,
                ),
        ),
        
        const SizedBox(height: AppSpacing.lg),
        
        // Name and age
        Text(
          '${profileProvider.name}, ${profileProvider.age}',
          style: Theme.of(context).textTheme.headlineMedium?.copyWith(
            color: AppColors.primaryGold,
          ),
        ),
        
        const SizedBox(height: AppSpacing.sm),
        
        // Bio
        if (profileProvider.bio.isNotEmpty)
          Text(
            profileProvider.bio,
            style: Theme.of(context).textTheme.bodyLarge?.copyWith(
              color: AppColors.textSecondary,
            ),
            textAlign: TextAlign.center,
          ),
      ],
    );
  }

  Widget _buildProfileStats() {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.lg),
      decoration: BoxDecoration(
        color: AppColors.accentCream,
        borderRadius: BorderRadius.circular(AppBorderRadius.large),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          _buildStatItem('Profils vus', '12'),
          _buildStatItem('Matches', '3'),
          _buildStatItem('Conversations', '2'),
        ],
      ),
    );
  }

  Widget _buildStatItem(String label, String value) {
    return Column(
      children: [
        Text(
          value,
          style: Theme.of(context).textTheme.headlineSmall?.copyWith(
            color: AppColors.primaryGold,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: AppSpacing.xs),
        Text(
          label,
          style: Theme.of(context).textTheme.bodySmall?.copyWith(
            color: AppColors.textSecondary,
          ),
        ),
      ],
    );
  }

  Widget _buildProfileSections(BuildContext context, ProfileProvider profileProvider) {
    return Column(
      children: [
        _buildSection(
          context,
          'Mes photos',
          profileProvider.photos.isEmpty
              ? 'Aucune photo ajoutée'
              : '${profileProvider.photos.length} photo(s)',
          Icons.photo_library,
          () {
            // TODO: Navigate to photo management
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Gestion des photos - À implémenter')),
            );
          },
        ),
        
        _buildSection(
          context,
          'Mes réponses',
          profileProvider.prompts.isEmpty
              ? 'Questionnaire non complété'
              : '${profileProvider.prompts.length} réponse(s)',
          Icons.quiz,
          () {
            // TODO: Navigate to prompts editing
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Édition des réponses - À implémenter')),
            );
          },
        ),
        
        _buildSection(
          context,
          'Préférences',
          'Gérer mes critères de recherche',
          Icons.tune,
          () {
            // TODO: Navigate to preferences
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Préférences - À implémenter')),
            );
          },
        ),
        
        _buildSection(
          context,
          'Abonnement',
          'GoldWen Plus',
          Icons.star,
          () {
            context.go('/subscription');
          },
        ),
      ],
    );
  }

  Widget _buildSection(
    BuildContext context,
    String title,
    String subtitle,
    IconData icon,
    VoidCallback onTap,
  ) {
    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.md),
      child: Card(
        child: ListTile(
          leading: Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: AppColors.primaryGold.withOpacity(0.1),
              borderRadius: BorderRadius.circular(AppBorderRadius.medium),
            ),
            child: Icon(
              icon,
              color: AppColors.primaryGold,
            ),
          ),
          title: Text(title),
          subtitle: Text(subtitle),
          trailing: const Icon(Icons.arrow_forward_ios, size: 16),
          onTap: onTap,
        ),
      ),
    );
  }

  void _showSettingsBottomSheet(BuildContext context) {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(
          top: Radius.circular(AppBorderRadius.large),
        ),
      ),
      builder: (BuildContext context) {
        return Container(
          padding: const EdgeInsets.all(AppSpacing.lg),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: AppColors.dividerLight,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              
              const SizedBox(height: AppSpacing.lg),
              
              Text(
                'Paramètres',
                style: Theme.of(context).textTheme.headlineSmall,
              ),
              
              const SizedBox(height: AppSpacing.lg),
              
              ListTile(
                leading: const Icon(Icons.privacy_tip),
                title: const Text('Conditions d\'utilisation'),
                onTap: () {
                  Navigator.of(context).pop();
                  context.go('/terms');
                },
              ),
              
              ListTile(
                leading: const Icon(Icons.security),
                title: const Text('Politique de confidentialité'),
                onTap: () {
                  Navigator.of(context).pop();
                  context.go('/privacy');
                },
              ),
              
              ListTile(
                leading: const Icon(Icons.help),
                title: const Text('Aide et support'),
                onTap: () {
                  Navigator.of(context).pop();
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Support - À implémenter')),
                  );
                },
              ),
              
              const Divider(),
              
              Consumer<AuthProvider>(
                builder: (context, authProvider, child) {
                  return ListTile(
                    leading: const Icon(Icons.logout, color: Colors.red),
                    title: const Text(
                      'Se déconnecter',
                      style: TextStyle(color: Colors.red),
                    ),
                    onTap: () {
                      Navigator.of(context).pop();
                      _showLogoutDialog(context, authProvider);
                    },
                  );
                },
              ),
              
              const SizedBox(height: AppSpacing.lg),
            ],
          ),
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
                backgroundColor: Colors.red,
              ),
              child: const Text('Se déconnecter'),
            ),
          ],
        );
      },
    );
  }
}