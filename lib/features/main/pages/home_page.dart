import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';
import '../../../core/theme/app_theme.dart';
import '../../auth/providers/auth_provider.dart';
import '../../matching/providers/matching_provider.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadData();
    });
  }

  void _loadData() {
    final matchingProvider = Provider.of<MatchingProvider>(context, listen: false);
    matchingProvider.loadDailySelection();
  }

  String _getGreeting() {
    final hour = DateTime.now().hour;
    if (hour < 12) {
      return 'Bon matin';
    } else if (hour < 17) {
      return 'Bon après-midi';
    } else {
      return 'Bonsoir';
    }
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
              _buildHeader(),
              Expanded(
                child: _buildContent(),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Consumer<AuthProvider>(
      builder: (context, authProvider, child) {
        final user = authProvider.user;
        return Padding(
          padding: const EdgeInsets.all(AppSpacing.lg),
          child: Row(
            children: [
              // Profile Avatar
              Container(
                width: 50,
                height: 50,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: AppColors.cardOverlay,
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.1),
                      blurRadius: 8,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: user?.photoUrl != null
                    ? ClipOval(
                        child: Image.network(
                          user!.photoUrl!,
                          fit: BoxFit.cover,
                          errorBuilder: (context, error, stackTrace) {
                            return const Icon(
                              Icons.person,
                              color: AppColors.primaryGold,
                              size: 30,
                            );
                          },
                        ),
                      )
                    : const Icon(
                        Icons.person,
                        color: AppColors.primaryGold,
                        size: 30,
                      ),
              ),
              
              const SizedBox(width: AppSpacing.md),
              
              // Greeting and Name
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      _getGreeting(),
                      style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                        color: AppColors.textLight,
                        fontWeight: FontWeight.w300,
                      ),
                    ),
                    Text(
                      user?.displayName ?? user?.email?.split('@').first ?? 'Utilisateur',
                      style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                        color: AppColors.textLight,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ),
              
              // Settings Button
              Container(
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: AppColors.cardOverlay.withOpacity(0.2),
                ),
                child: IconButton(
                  onPressed: () {
                    // Open settings or user profile
                    _showSettingsBottomSheet();
                  },
                  icon: const Icon(
                    Icons.settings,
                    color: AppColors.textLight,
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildContent() {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.backgroundWhite,
        borderRadius: const BorderRadius.only(
          topLeft: Radius.circular(AppBorderRadius.xLarge),
          topRight: Radius.circular(AppBorderRadius.xLarge),
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.lg),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: AppSpacing.md),
            
            // How are you feeling section
            _buildMoodSection(),
            
            const SizedBox(height: AppSpacing.xl),
            
            // Daily Matches section
            _buildDailyMatchesSection(),
            
            const SizedBox(height: AppSpacing.xl),
            
            // Quick Actions section
            _buildQuickActionsSection(),
          ],
        ),
      ),
    );
  }

  Widget _buildMoodSection() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(AppSpacing.lg),
      decoration: BoxDecoration(
        gradient: AppColors.cardGradient,
        borderRadius: BorderRadius.circular(AppBorderRadius.large),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(AppSpacing.sm),
            decoration: BoxDecoration(
              color: AppColors.primaryGold.withOpacity(0.1),
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.sentiment_satisfied_alt,
              color: AppColors.primaryGold,
              size: 24,
            ),
          ),
          const SizedBox(width: AppSpacing.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Comment vous sentez-vous ?',
                  style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: AppSpacing.xs),
                Text(
                  'Partagez votre humeur d\'aujourd\'hui',
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: AppColors.textSecondary,
                  ),
                ),
              ],
            ),
          ),
          const Icon(
            Icons.arrow_forward_ios,
            color: AppColors.textSecondary,
            size: 16,
          ),
        ],
      ),
    );
  }

  Widget _buildDailyMatchesSection() {
    return Consumer<MatchingProvider>(
      builder: (context, matchingProvider, child) {
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Vos sélections du jour',
                  style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                ),
                TextButton(
                  onPressed: () {
                    // Navigate to full matches page
                    DefaultTabController.of(context)?.animateTo(0);
                  },
                  child: const Text('Voir tout'),
                ),
              ],
            ),
            
            const SizedBox(height: AppSpacing.md),
            
            SizedBox(
              height: 120,
              child: matchingProvider.isLoading
                  ? const Center(child: CircularProgressIndicator())
                  : matchingProvider.dailyProfiles.isEmpty
                      ? _buildEmptyMatchesCard()
                      : ListView.builder(
                          scrollDirection: Axis.horizontal,
                          itemCount: matchingProvider.dailyProfiles.length.clamp(0, 3),
                          itemBuilder: (context, index) {
                            final profile = matchingProvider.dailyProfiles[index];
                            return _buildMatchCard(profile);
                          },
                        ),
            ),
          ],
        );
      },
    );
  }

  Widget _buildMatchCard(dynamic profile) {
    return Container(
      width: 100,
      margin: const EdgeInsets.only(right: AppSpacing.md),
      decoration: BoxDecoration(
        gradient: AppColors.cardGradient,
        borderRadius: BorderRadius.circular(AppBorderRadius.large),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: 50,
            height: 50,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: LinearGradient(
                colors: [
                  AppColors.primaryGold.withOpacity(0.3),
                  AppColors.primaryGold.withOpacity(0.6),
                ],
              ),
            ),
            child: const Icon(
              Icons.person,
              color: Colors.white,
              size: 30,
            ),
          ),
          const SizedBox(height: AppSpacing.sm),
          Text(
            'Profil',
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
              fontWeight: FontWeight.w600,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyMatchesCard() {
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        gradient: AppColors.cardGradient,
        borderRadius: BorderRadius.circular(AppBorderRadius.large),
        border: Border.all(
          color: AppColors.dividerLight,
          style: BorderStyle.solid,
        ),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.schedule,
            color: AppColors.textSecondary,
            size: 32,
          ),
          const SizedBox(height: AppSpacing.sm),
          Text(
            'Vos sélections arrivent bientôt',
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              fontWeight: FontWeight.w600,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: AppSpacing.xs),
          Text(
            'Revenez à 12h00',
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
              color: AppColors.textSecondary,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildQuickActionsSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Actions rapides',
          style: Theme.of(context).textTheme.headlineSmall?.copyWith(
            fontWeight: FontWeight.w600,
          ),
        ),
        
        const SizedBox(height: AppSpacing.md),
        
        Row(
          children: [
            Expanded(
              child: _buildQuickActionCard(
                'Messages',
                Icons.chat_bubble_outline,
                () => DefaultTabController.of(context)?.animateTo(1),
              ),
            ),
            const SizedBox(width: AppSpacing.md),
            Expanded(
              child: _buildQuickActionCard(
                'Profil',
                Icons.person_outline,
                () => DefaultTabController.of(context)?.animateTo(2),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildQuickActionCard(String title, IconData icon, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(AppSpacing.lg),
        decoration: BoxDecoration(
          gradient: AppColors.cardGradient,
          borderRadius: BorderRadius.circular(AppBorderRadius.large),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 4,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Column(
          children: [
            Container(
              padding: const EdgeInsets.all(AppSpacing.md),
              decoration: BoxDecoration(
                color: AppColors.primaryGold.withOpacity(0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(
                icon,
                color: AppColors.primaryGold,
                size: 24,
              ),
            ),
            const SizedBox(height: AppSpacing.sm),
            Text(
              title,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                fontWeight: FontWeight.w600,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  void _showSettingsBottomSheet() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        decoration: const BoxDecoration(
          color: AppColors.backgroundWhite,
          borderRadius: BorderRadius.only(
            topLeft: Radius.circular(AppBorderRadius.xLarge),
            topRight: Radius.circular(AppBorderRadius.xLarge),
          ),
        ),
        child: Padding(
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
                leading: const Icon(Icons.person),
                title: const Text('Mon profil'),
                onTap: () {
                  Navigator.of(context).pop();
                  DefaultTabController.of(context)?.animateTo(2);
                },
              ),
              
              ListTile(
                leading: const Icon(Icons.star),
                title: const Text('Abonnement'),
                onTap: () {
                  Navigator.of(context).pop();
                  context.go('/subscription');
                },
              ),
              
              ListTile(
                leading: const Icon(Icons.privacy_tip),
                title: const Text('Confidentialité'),
                onTap: () {
                  Navigator.of(context).pop();
                  context.go('/privacy');
                },
              ),
              
              ListTile(
                leading: const Icon(Icons.help),
                title: const Text('Aide'),
                onTap: () {
                  Navigator.of(context).pop();
                  // Show help dialog
                },
              ),
              
              const SizedBox(height: AppSpacing.lg),
            ],
          ),
        ),
      ),
    );
  }
}