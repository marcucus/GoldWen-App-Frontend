import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/widgets/animated_widgets.dart';
import '../../../core/widgets/modern_cards.dart';
import '../../auth/providers/auth_provider.dart';
import '../../profile/providers/profile_provider.dart';

class UserProfilePage extends StatefulWidget {
  const UserProfilePage({super.key});

  @override
  State<UserProfilePage> createState() => _UserProfilePageState();
}

class _UserProfilePageState extends State<UserProfilePage> with TickerProviderStateMixin {
  late AnimationController _backgroundController;
  late AnimationController _contentController;
  late Animation<double> _backgroundAnimation;
  late Animation<Offset> _slideAnimation;
  late Animation<double> _fadeAnimation;

  @override
  void initState() {
    super.initState();
    _initializeAnimations();
    _loadProfile();
    _startAnimations();
  }

  void _initializeAnimations() {
    _backgroundController = AnimationController(
      duration: AppAnimations.verySlow,
      vsync: this,
    );
    _contentController = AnimationController(
      duration: AppAnimations.medium,
      vsync: this,
    );

    _backgroundAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _backgroundController,
      curve: AppAnimations.easeInOut,
    ));

    _slideAnimation = Tween<Offset>(
      begin: const Offset(0, 1),
      end: Offset.zero,
    ).animate(CurvedAnimation(
      parent: _contentController,
      curve: AppAnimations.elasticOut,
    ));

    _fadeAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _contentController,
      curve: AppAnimations.easeOut,
    ));
  }

  void _startAnimations() {
    _backgroundController.forward();
    Future.delayed(const Duration(milliseconds: 300), () {
      _contentController.forward();
    });
  }

  @override
  void dispose() {
    _backgroundController.dispose();
    _contentController.dispose();
    super.dispose();
  }

  void _loadProfile() {
    final profileProvider = Provider.of<ProfileProvider>(context, listen: false);
    profileProvider.loadProfile();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: AnimatedBuilder(
        animation: _backgroundAnimation,
        builder: (context, child) {
          return Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  AppColors.gradientStart,
                  AppColors.gradientMiddle,
                  AppColors.gradientEnd.withOpacity(0.7 + 0.3 * _backgroundAnimation.value),
                ],
                stops: const [0.0, 0.4, 1.0],
              ),
            ),
            child: SafeArea(
              child: Column(
                children: [
                  _buildAnimatedHeader(),
                  Expanded(
                    child: _buildAnimatedContent(),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildAnimatedHeader() {
    return FadeInAnimation(
      delay: const Duration(milliseconds: 200),
      child: _buildHeader(),
    );
  }

  Widget _buildHeader() {
    return Container(
      margin: const EdgeInsets.all(AppSpacing.lg),
      child: GlassCard(
        borderRadius: AppBorderRadius.xLarge,
        padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.lg,
          vertical: AppSpacing.md,
        ),
        child: Row(
          children: [
            Expanded(
              child: Text(
                'Mon profil',
                style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                  color: AppColors.textDark,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            AnimatedPressable(
              onPressed: () => context.go('/home'),
              child: Container(
                padding: const EdgeInsets.all(AppSpacing.sm),
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: AppColors.primaryGold.withOpacity(0.1),
                ),
                child: const Icon(
                  Icons.close,
                  color: AppColors.primaryGold,
                  size: 24,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAnimatedContent() {
    return AnimatedBuilder(
      animation: _contentController,
      builder: (context, child) {
        return SlideTransition(
          position: _slideAnimation,
          child: FadeTransition(
            opacity: _fadeAnimation,
            child: _buildContent(),
          ),
        );
      },
    );
  }

  Widget _buildContent() {
    return Consumer2<AuthProvider, ProfileProvider>(
      builder: (context, authProvider, profileProvider, child) {
        final user = authProvider.user;
        return SingleChildScrollView(
          physics: const BouncingScrollPhysics(),
          padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md),
          child: Column(
            children: [
              // Profile Header Card
              _buildProfileHeader(user, profileProvider),
              
              const SizedBox(height: AppSpacing.xl),
              
              // Profile Management Section
              _buildProfileManagement(),
              
              const SizedBox(height: AppSpacing.lg),
              
              // App Settings Section
              _buildAppSettings(),
              
              const SizedBox(height: AppSpacing.lg),
              
              // Account Section
              _buildAccountSection(authProvider),
              
              const SizedBox(height: AppSpacing.xxl),
            ],
          ),
        );
      },
    );
  }

  Widget _buildProfileHeader(dynamic user, ProfileProvider profileProvider) {
    return SlideInAnimation(
      delay: const Duration(milliseconds: 400),
      child: PremiumCard(
        gradient: AppColors.premiumGradient,
        child: Column(
          children: [
            // Profile Picture and Info
            Row(
              children: [
                Stack(
                  children: [
                    Container(
                      width: 80,
                      height: 80,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        border: Border.all(
                          color: Colors.white,
                          width: 3,
                        ),
                        boxShadow: AppShadows.medium,
                      ),
                      child: ClipOval(
                        child: user?.photoUrl != null
                            ? Image.network(
                                user!.photoUrl!,
                                fit: BoxFit.cover,
                                errorBuilder: (context, error, stackTrace) {
                                  return Container(
                                    color: Colors.white,
                                    child: const Icon(
                                      Icons.person,
                                      color: AppColors.primaryGold,
                                      size: 40,
                                    ),
                                  );
                                },
                              )
                            : Container(
                                color: Colors.white,
                                child: const Icon(
                                  Icons.person,
                                  color: AppColors.primaryGold,
                                  size: 40,
                                ),
                              ),
                      ),
                    ),
                    Positioned(
                      bottom: 0,
                      right: 0,
                      child: AnimatedPressable(
                        onPressed: () {
                          // Open photo picker
                        },
                        child: Container(
                          padding: const EdgeInsets.all(6),
                          decoration: const BoxDecoration(
                            shape: BoxShape.circle,
                            color: Colors.white,
                          ),
                          child: const Icon(
                            Icons.camera_alt,
                            color: AppColors.primaryGold,
                            size: 16,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
                
                const SizedBox(width: AppSpacing.lg),
                
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        user?.displayName ?? 'Utilisateur',
                        style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        user?.email ?? '',
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          color: Colors.white.withOpacity(0.8),
                        ),
                      ),
                      const SizedBox(height: AppSpacing.sm),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: AppSpacing.sm,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.2),
                          borderRadius: BorderRadius.circular(AppBorderRadius.small),
                        ),
                        child: Text(
                          'Profil complété à 75%',
                          style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            color: Colors.white,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            
            const SizedBox(height: AppSpacing.lg),
            
            // Profile completion bar
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Complétez votre profil pour plus de matchs',
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: Colors.white.withOpacity(0.9),
                  ),
                ),
                const SizedBox(height: AppSpacing.sm),
                Container(
                  height: 8,
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.3),
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: FractionallySizedBox(
                    alignment: Alignment.centerLeft,
                    widthFactor: 0.75,
                    child: Container(
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(4),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildProfileManagement() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: AppSpacing.sm),
          child: Text(
            'Gestion du profil',
            style: Theme.of(context).textTheme.headlineSmall?.copyWith(
              color: AppColors.textLight,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
        const SizedBox(height: AppSpacing.md),
        StaggeredList(
          itemDelay: const Duration(milliseconds: 100),
          children: [
            _buildMenuCard(
              icon: Icons.photo_library,
              title: 'Mes photos',
              subtitle: 'Gérer vos photos de profil',
              onTap: () {
                // Navigate to photo management
              },
              gradient: LinearGradient(
                colors: [
                  AppColors.infoBlue.withOpacity(0.8),
                  AppColors.infoBlue,
                ],
              ),
            ),
            _buildMenuCard(
              icon: Icons.favorite,
              title: 'Mes réponses',
              subtitle: 'Questions et réponses',
              onTap: () {
                // Navigate to responses
              },
              gradient: LinearGradient(
                colors: [
                  AppColors.errorRed.withOpacity(0.8),
                  AppColors.errorRed,
                ],
              ),
            ),
            _buildMenuCard(
              icon: Icons.tune,
              title: 'Préférences',
              subtitle: 'Critères de recherche',
              onTap: () {
                // Navigate to preferences
              },
              gradient: LinearGradient(
                colors: [
                  AppColors.successGreen.withOpacity(0.8),
                  AppColors.successGreen,
                ],
              ),
            ),
            _buildMenuCard(
              icon: Icons.star,
              title: 'GoldWen Plus',
              subtitle: 'Accédez aux fonctionnalités premium',
              onTap: () => context.go('/subscription'),
              gradient: AppColors.premiumGradient,
              isHighlighted: true,
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildAppSettings() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: AppSpacing.sm),
          child: Text(
            'Paramètres de l\'app',
            style: Theme.of(context).textTheme.headlineSmall?.copyWith(
              color: AppColors.textLight,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
        const SizedBox(height: AppSpacing.md),
        SlideInAnimation(
          delay: const Duration(milliseconds: 700),
          child: GlassCard(
            child: Column(
              children: [
                _buildSettingItem(
                  icon: Icons.description,
                  title: 'Conditions d\'utilisation',
                  onTap: () => context.go('/terms'),
                ),
                const Divider(height: 1),
                _buildSettingItem(
                  icon: Icons.privacy_tip,
                  title: 'Politique de confidentialité',
                  onTap: () => context.go('/privacy'),
                ),
                const Divider(height: 1),
                _buildSettingItem(
                  icon: Icons.help_outline,
                  title: 'Aide et support',
                  onTap: () {
                    // Show help dialog
                  },
                ),
                const Divider(height: 1),
                _buildSettingItem(
                  icon: Icons.notifications_outlined,
                  title: 'Notifications',
                  trailing: Switch(
                    value: true,
                    onChanged: (value) {
                      // Handle notification toggle
                    },
                    activeColor: AppColors.primaryGold,
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildAccountSection(AuthProvider authProvider) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: AppSpacing.sm),
          child: Text(
            'Compte',
            style: Theme.of(context).textTheme.headlineSmall?.copyWith(
              color: AppColors.textLight,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
        const SizedBox(height: AppSpacing.md),
        SlideInAnimation(
          delay: const Duration(milliseconds: 800),
          child: FloatingCard(
            backgroundColor: AppColors.errorRed.withOpacity(0.1),
            onTap: () => _showLogoutDialog(authProvider),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(AppSpacing.md),
                  decoration: BoxDecoration(
                    color: AppColors.errorRed.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(AppBorderRadius.medium),
                  ),
                  child: const Icon(
                    Icons.logout,
                    color: AppColors.errorRed,
                    size: 24,
                  ),
                ),
                const SizedBox(width: AppSpacing.md),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Se déconnecter',
                        style: Theme.of(context).textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.w600,
                          color: AppColors.errorRed,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        'Déconnectez-vous de votre compte',
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: AppColors.textSecondary,
                        ),
                      ),
                    ],
                  ),
                ),
                const Icon(
                  Icons.arrow_forward_ios,
                  size: 16,
                  color: AppColors.errorRed,
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildMenuCard({
    required IconData icon,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
    required Gradient gradient,
    bool isHighlighted = false,
  }) {
    return FloatingCard(
      onTap: onTap,
      backgroundColor: isHighlighted ? AppColors.primaryGold.withOpacity(0.1) : null,
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(AppSpacing.md),
            decoration: BoxDecoration(
              gradient: gradient,
              borderRadius: BorderRadius.circular(AppBorderRadius.medium),
              boxShadow: AppShadows.soft,
            ),
            child: Icon(
              icon,
              color: Colors.white,
              size: 24,
            ),
          ),
          const SizedBox(width: AppSpacing.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w600,
                    color: isHighlighted ? AppColors.primaryGold : AppColors.textDark,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  subtitle,
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: AppColors.textSecondary,
                  ),
                ),
              ],
            ),
          ),
          Icon(
            Icons.arrow_forward_ios,
            size: 16,
            color: isHighlighted ? AppColors.primaryGold : AppColors.textSecondary,
          ),
        ],
      ),
    );
  }

  Widget _buildSettingItem({
    required IconData icon,
    required String title,
    VoidCallback? onTap,
    Widget? trailing,
  }) {
    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.md),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(AppSpacing.sm),
              decoration: BoxDecoration(
                color: AppColors.primaryGold.withOpacity(0.1),
                borderRadius: BorderRadius.circular(AppBorderRadius.small),
              ),
              child: Icon(
                icon,
                color: AppColors.primaryGold,
                size: 20,
              ),
            ),
            const SizedBox(width: AppSpacing.md),
            Expanded(
              child: Text(
                title,
                style: Theme.of(context).textTheme.titleSmall?.copyWith(
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
            trailing ?? const Icon(
              Icons.arrow_forward_ios,
              size: 16,
              color: AppColors.textSecondary,
            ),
          ],
        ),
      ),
    );
  }

  void _showLogoutDialog(AuthProvider authProvider) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Se déconnecter'),
        content: const Text('Êtes-vous sûr de vouloir vous déconnecter ?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Annuler'),
          ),
          PremiumButton(
            text: 'Se déconnecter',
            width: 120,
            height: 40,
            onPressed: () async {
              Navigator.of(context).pop();
              await authProvider.signOut();
              if (mounted) {
                context.go('/auth');
              }
            },
          ),
        ],
      ),
    );
  }
}
                    Container(
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: AppColors.cardOverlay.withOpacity(0.2),
                      ),
                      child: IconButton(
                        onPressed: () {
                          // Return to home page
                          context.go('/home');
                        },
                        icon: const Icon(
                          Icons.close,
                          color: AppColors.textLight,
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
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.all(AppSpacing.lg),
                    child: Column(
                      children: [
                        const SizedBox(height: AppSpacing.lg),
                        _buildProfileHeader(),
                        const SizedBox(height: AppSpacing.xl),
                        _buildProfileSections(),
                        const SizedBox(height: AppSpacing.xl),
                        _buildSettingsSection(),
                        const SizedBox(height: AppSpacing.xl),
                        _buildLogoutSection(),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildProfileHeader() {
    return Consumer<ProfileProvider>(
      builder: (context, profileProvider, child) {
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
            if (profileProvider.bio?.isNotEmpty == true)
              Text(
                profileProvider.bio!,
                style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                  color: AppColors.textSecondary,
                ),
                textAlign: TextAlign.center,
              ),
          ],
        );
      },
    );
  }

  Widget _buildProfileSections() {
    return Consumer<ProfileProvider>(
      builder: (context, profileProvider, child) {
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Mon profil',
              style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: AppSpacing.lg),
            _buildSection(
              context,
              'Mes photos',
              profileProvider.photos.isEmpty
                  ? 'Aucune photo ajoutée'
                  : '${profileProvider.photos.length} photo(s)',
              Icons.photo_library,
              () {
                _navigateToPhotoManagement(context);
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
                _navigateToPromptsEditing(context);
              },
            ),
            
            _buildSection(
              context,
              'Préférences',
              'Gérer mes critères de recherche',
              Icons.tune,
              () {
                _navigateToPreferences(context);
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
      },
    );
  }

  Widget _buildSettingsSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Paramètres',
          style: Theme.of(context).textTheme.headlineSmall?.copyWith(
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: AppSpacing.lg),
        _buildSection(
          context,
          'Conditions d\'utilisation',
          'Consultez nos conditions',
          Icons.privacy_tip,
          () {
            context.go('/terms');
          },
        ),
        
        _buildSection(
          context,
          'Politique de confidentialité',
          'Protégez vos données',
          Icons.security,
          () {
            context.go('/privacy');
          },
        ),
        
        _buildSection(
          context,
          'Aide et support',
          'Besoin d\'aide ?',
          Icons.help,
          () {
            _showSupportDialog(context);
          },
        ),
      ],
    );
  }

  Widget _buildLogoutSection() {
    return Consumer<AuthProvider>(
      builder: (context, authProvider, child) {
        return Container(
          width: double.infinity,
          decoration: BoxDecoration(
            color: Colors.red.withOpacity(0.1),
            borderRadius: BorderRadius.circular(AppBorderRadius.large),
          ),
          child: Padding(
            padding: const EdgeInsets.all(AppSpacing.lg),
            child: Column(
              children: [
                Icon(
                  Icons.logout,
                  color: Colors.red,
                  size: 32,
                ),
                const SizedBox(height: AppSpacing.sm),
                ElevatedButton(
                  onPressed: () async {
                    await authProvider.signOut();
                    if (context.mounted) {
                      context.go('/welcome');
                    }
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.red,
                    foregroundColor: Colors.white,
                  ),
                  child: const Text('Se déconnecter'),
                ),
              ],
            ),
          ),
        );
      },
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

  // Navigation methods for button handlers
  void _navigateToPhotoManagement(BuildContext context) {
    // For now, navigate to profile setup where photos can be managed
    context.go('/profile-setup');
  }
  
  void _navigateToPromptsEditing(BuildContext context) {
    // Navigate to questionnaire page to edit prompts/responses
    context.go('/questionnaire');
  }
  
  void _navigateToPreferences(BuildContext context) {
    // Show preferences dialog or navigate to preferences page
    _showPreferencesDialog(context);
  }
  
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
                // Could navigate to chat or open email client
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
}