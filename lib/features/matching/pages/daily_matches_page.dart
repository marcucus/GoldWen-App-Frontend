import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';
import '../../../core/theme/app_theme.dart';
import '../providers/matching_provider.dart';
import '../../../core/models/profile.dart';
import '../../subscription/pages/subscription_page.dart';

class DailyMatchesPage extends StatefulWidget {
  const DailyMatchesPage({super.key});

  @override
  State<DailyMatchesPage> createState() => _DailyMatchesPageState();
}

class _DailyMatchesPageState extends State<DailyMatchesPage> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadDailyMatches();
    });
  }

  void _loadDailyMatches() {
    final matchingProvider = Provider.of<MatchingProvider>(context, listen: false);
    matchingProvider.loadDailySelection();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        gradient: AppColors.primaryGradient,
      ),
      child: SafeArea(
        child: Column(
          children: [
            // Header
            Padding(
              padding: const EdgeInsets.all(AppSpacing.lg),
              child: Row(
                children: [
                  Expanded(
                    child: Text(
                      'Votre sélection du jour',
                      style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                        color: AppColors.textLight,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  Container(
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: AppColors.cardOverlay.withOpacity(0.2),
                    ),
                    child: IconButton(
                      onPressed: () => Navigator.of(context).push(
                        MaterialPageRoute(
                          builder: (context) => const SubscriptionPage(),
                        ),
                      ),
                      icon: const Icon(
                        Icons.star_border,
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
                child: Consumer<MatchingProvider>(
                  builder: (context, matchingProvider, child) {
                    if (matchingProvider.isLoading) {
                      return const Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            CircularProgressIndicator(
                              valueColor: AlwaysStoppedAnimation<Color>(AppColors.primaryGold),
                            ),
                            SizedBox(height: AppSpacing.lg),
                            Text('Préparation de votre sélection...'),
                          ],
                        ),
                      );
                    }

                    if (matchingProvider.dailyProfiles.isEmpty) {
                      return _buildEmptyState();
                    }

                    return RefreshIndicator(
                      onRefresh: () async => _loadDailyMatches(),
                      child: Column(
                        children: [
                          _buildHeader(matchingProvider),
                          Expanded(
                            child: ListView.builder(
                              padding: const EdgeInsets.all(AppSpacing.md).copyWith(
                                bottom: 100, // Add space for floating nav
                              ),
                              itemCount: matchingProvider.dailyProfiles.length,
                              itemBuilder: (context, index) {
                                final profile = matchingProvider.dailyProfiles[index];
                                return _buildProfileCard(profile, matchingProvider);
                              },
                            ),
                          ),
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
    );
  }

  Widget _buildHeader(MatchingProvider matchingProvider) {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.lg),
      decoration: BoxDecoration(
        color: AppColors.accentCream,
        border: Border(
          bottom: BorderSide(color: AppColors.dividerLight),
        ),
      ),
      child: Column(
        children: [
          Row(
            children: [
              Icon(
                Icons.favorite,
                color: AppColors.primaryGold,
                size: 24,
              ),
              const SizedBox(width: AppSpacing.sm),
              Expanded(
                child: Text(
                  'Sélections disponibles: ${matchingProvider.maxSelections - matchingProvider.selectedProfileIds.length}/${matchingProvider.maxSelections}',
                  style: Theme.of(context).textTheme.labelLarge,
                ),
              ),
            ],
          ),
          if (!matchingProvider.hasSubscription) ...[
            const SizedBox(height: AppSpacing.sm),
            GestureDetector(
              onTap: () => Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (context) => const SubscriptionPage(),
                ),
              ),
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: AppSpacing.md,
                  vertical: AppSpacing.sm,
                ),
                decoration: BoxDecoration(
                  color: AppColors.primaryGold.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(AppBorderRadius.medium),
                  border: Border.all(color: AppColors.primaryGold),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      Icons.upgrade,
                      color: AppColors.primaryGold,
                      size: 16,
                    ),
                    const SizedBox(width: AppSpacing.xs),
                    Text(
                      'Passez à GoldWen Plus pour 3 sélections',
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: AppColors.primaryGold,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildProfileCard(Profile profile, MatchingProvider matchingProvider) {
    final isSelected = matchingProvider.isProfileSelected(profile.id);
    final canSelect = matchingProvider.canSelectMore || isSelected;

    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.lg),
      child: Card(
        elevation: isSelected ? 8 : 2,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Profile header with photo
            GestureDetector(
              onTap: () => context.go('/profile/${profile.id}'),
              child: Container(
                height: 200,
                decoration: BoxDecoration(
                  color: AppColors.primaryGold.withOpacity(0.3),
                  borderRadius: const BorderRadius.only(
                    topLeft: Radius.circular(AppBorderRadius.large),
                    topRight: Radius.circular(AppBorderRadius.large),
                  ),
                ),
                child: Stack(
                  children: [
                    // Photo placeholder
                    Container(
                      width: double.infinity,
                      height: double.infinity,
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.topCenter,
                          end: Alignment.bottomCenter,
                          colors: [
                            AppColors.primaryGold.withOpacity(0.3),
                            AppColors.primaryGold.withOpacity(0.6),
                          ],
                        ),
                        borderRadius: const BorderRadius.only(
                          topLeft: Radius.circular(AppBorderRadius.large),
                          topRight: Radius.circular(AppBorderRadius.large),
                        ),
                      ),
                      child: const Icon(
                        Icons.person,
                        size: 80,
                        color: Colors.white,
                      ),
                    ),
                    
                    // Selection indicator
                    if (isSelected)
                      Positioned(
                        top: AppSpacing.md,
                        left: AppSpacing.md,
                        child: Container(
                          padding: const EdgeInsets.all(AppSpacing.xs),
                          decoration: const BoxDecoration(
                            color: AppColors.primaryGold,
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(
                            Icons.check,
                            color: Colors.white,
                            size: 20,
                          ),
                        ),
                      ),
                  ],
                ),
              ),
            ),
            
            // Profile info
            Padding(
              padding: const EdgeInsets.all(AppSpacing.lg),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Name and age
                  Row(
                    children: [
                      Text(
                        'Profil ${profile.age != null ? ', ${profile.age}' : ''}',
                        style: Theme.of(context).textTheme.headlineSmall,
                      ),
                      const Spacer(),
                      TextButton.icon(
                        onPressed: () => context.go('/profile/${profile.id}'),
                        icon: const Icon(Icons.visibility),
                        label: const Text('Voir le profil'),
                      ),
                    ],
                  ),
                  
                  const SizedBox(height: AppSpacing.sm),
                  
                  // Bio
                  Text(
                    profile.bio ?? 'Aucune biographie disponible',
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: AppColors.textSecondary,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  
                  const SizedBox(height: AppSpacing.lg),
                  
                  // Action button
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton.icon(
                      onPressed: canSelect && !isSelected
                          ? () => _selectProfile(profile.id, matchingProvider)
                          : null,
                      icon: Icon(
                        isSelected ? Icons.check : Icons.favorite,
                      ),
                      label: Text(
                        isSelected
                            ? 'Sélectionné'
                            : canSelect
                                ? 'Choisir'
                                : 'Limite atteinte',
                      ),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: isSelected
                            ? AppColors.successGreen
                            : AppColors.primaryGold,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.lg),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.schedule,
              size: 80,
              color: AppColors.textSecondary,
            ),
            const SizedBox(height: AppSpacing.lg),
            Text(
              'Votre sélection arrive bientôt',
              style: Theme.of(context).textTheme.headlineSmall,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: AppSpacing.md),
            Text(
              'Revenez demain à 12h00 pour découvrir vos nouveaux profils compatibles.',
              style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                color: AppColors.textSecondary,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: AppSpacing.xl),
            ElevatedButton(
              onPressed: _loadDailyMatches,
              child: const Text('Actualiser'),
            ),
          ],
        ),
      ),
    );
  }

  void _selectProfile(String profileId, MatchingProvider matchingProvider) {
    matchingProvider.selectProfile(profileId).then((success) {
      if (success && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text('Profil sélectionné ! Revenez demain pour votre nouvelle sélection.'),
            backgroundColor: AppColors.successGreen,
            action: SnackBarAction(
              label: 'OK',
              textColor: Colors.white,
              onPressed: () {
                ScaffoldMessenger.of(context).hideCurrentSnackBar();
              },
            ),
          ),
        );
      }
    });
  }
}