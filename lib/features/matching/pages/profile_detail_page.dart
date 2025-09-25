import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';
import '../../../core/theme/app_theme.dart';
import '../models/match_profile.dart';
import '../providers/matching_provider.dart';
import '../providers/report_provider.dart';
import '../widgets/report_dialog.dart';

class ProfileDetailPage extends StatelessWidget {
  final String profileId;
  
  const ProfileDetailPage({
    super.key,
    required this.profileId,
  });

  @override
  Widget build(BuildContext context) {
    // Mock data - in a real app, this would come from a provider or API
    final profile = MatchProfile(
      id: profileId,
      name: 'Sophie',
      age: 29,
      bio: 'Passionnée par l\'art et les conversations significatives. J\'aime explorer de nouvelles cultures et créer des connexions authentiques.',
      photos: ['photo1.jpg', 'photo2.jpg', 'photo3.jpg'],
      prompts: [
        'Ce qui me rend vraiment heureuse, c\'est de découvrir un nouveau livre qui me transporte complètement.',
        'Je ne peux pas vivre sans mes séances de yoga matinales et mon café parfait.',
        'Ma passion secrète est de collectionner des vinyles de musique du monde entier.'
      ],
      compatibilityScore: 0.92,
    );

    return Scaffold(
      body: CustomScrollView(
        slivers: [
          // App bar with photo
          SliverAppBar(
            expandedHeight: 400,
            pinned: true,
            leading: IconButton(
              icon: Container(
                padding: const EdgeInsets.all(8),
                decoration: const BoxDecoration(
                  color: Colors.black54,
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.arrow_back,
                  color: Colors.white,
                ),
              ),
              onPressed: () => context.pop(),
            ),
            actions: [
              IconButton(
                icon: Container(
                  padding: const EdgeInsets.all(8),
                  decoration: const BoxDecoration(
                    color: Colors.black54,
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.flag,
                    color: Colors.white,
                  ),
                ),
                onPressed: () => _showReportDialog(context, profile),
              ),
            ],
            flexibleSpace: FlexibleSpaceBar(
              background: Stack(
                fit: StackFit.expand,
                children: [
                  // Photo placeholder
                  Container(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: [
                          AppColors.primaryGold.withOpacity(0.3),
                          AppColors.primaryGold.withOpacity(0.7),
                        ],
                      ),
                    ),
                    child: const Icon(
                      Icons.person,
                      size: 120,
                      color: Colors.white,
                    ),
                  ),
                  
                  // Gradient overlay
                  Positioned(
                    bottom: 0,
                    left: 0,
                    right: 0,
                    child: Container(
                      height: 100,
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.topCenter,
                          end: Alignment.bottomCenter,
                          colors: [
                            Colors.transparent,
                            Colors.black.withOpacity(0.7),
                          ],
                        ),
                      ),
                    ),
                  ),
                  
                  // Name and compatibility
                  Positioned(
                    bottom: 20,
                    left: 20,
                    right: 20,
                    child: Row(
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Text(
                                '${profile.name}, ${profile.age}',
                                style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                                  color: Colors.white,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ],
                          ),
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: AppSpacing.md,
                            vertical: AppSpacing.sm,
                          ),
                          decoration: BoxDecoration(
                            color: AppColors.primaryGold,
                            borderRadius: BorderRadius.circular(AppBorderRadius.medium),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              const Icon(
                                Icons.favorite,
                                color: Colors.white,
                                size: 16,
                              ),
                              const SizedBox(width: AppSpacing.xs),
                              Text(
                                '${(profile.compatibilityScore * 100).round()}% compatible',
                                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                  color: Colors.white,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
          
          // Content
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.all(AppSpacing.lg),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Bio section
                  _buildSection(
                    context,
                    'À propos',
                    profile.bio,
                    Icons.info_outline,
                  ),
                  
                  const SizedBox(height: AppSpacing.xl),
                  
                  // Prompts section
                  Text(
                    'En savoir plus',
                    style: Theme.of(context).textTheme.headlineSmall,
                  ),
                  
                  const SizedBox(height: AppSpacing.lg),
                  
                  ...profile.prompts.asMap().entries.map((entry) {
                    final index = entry.key;
                    final prompt = entry.value;
                    final questions = [
                      'Ce qui me rend vraiment heureux(se), c\'est...',
                      'Je ne peux pas vivre sans...',
                      'Ma passion secrète est...',
                    ];
                    
                    return Padding(
                      padding: const EdgeInsets.only(bottom: AppSpacing.lg),
                      child: Container(
                        padding: const EdgeInsets.all(AppSpacing.lg),
                        decoration: BoxDecoration(
                          color: AppColors.accentCream,
                          borderRadius: BorderRadius.circular(AppBorderRadius.large),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              questions[index],
                              style: Theme.of(context).textTheme.labelLarge?.copyWith(
                                color: AppColors.primaryGold,
                              ),
                            ),
                            const SizedBox(height: AppSpacing.sm),
                            Text(
                              prompt,
                              style: Theme.of(context).textTheme.bodyLarge,
                            ),
                          ],
                        ),
                      ),
                    );
                  }).toList(),
                  
                  const SizedBox(height: AppSpacing.xl),
                  
                  // Photo gallery placeholder
                  Text(
                    'Plus de photos',
                    style: Theme.of(context).textTheme.headlineSmall,
                  ),
                  
                  const SizedBox(height: AppSpacing.lg),
                  
                  SizedBox(
                    height: 120,
                    child: ListView.builder(
                      scrollDirection: Axis.horizontal,
                      itemCount: 3,
                      itemBuilder: (context, index) {
                        return Padding(
                          padding: EdgeInsets.only(
                            right: index < 2 ? AppSpacing.md : 0,
                          ),
                          child: Container(
                            width: 120,
                            decoration: BoxDecoration(
                              color: AppColors.primaryGold.withOpacity(0.3),
                              borderRadius: BorderRadius.circular(AppBorderRadius.medium),
                            ),
                            child: const Icon(
                              Icons.image,
                              size: 40,
                              color: Colors.white,
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                  
                  const SizedBox(height: AppSpacing.xxl),
                  
                  // Action buttons
                  Row(
                    children: [
                      Expanded(
                        child: ElevatedButton.icon(
                          onPressed: () {
                            _showSelectionDialog(context, profile);
                          },
                          icon: const Icon(Icons.favorite),
                          label: const Text('Choisir'),
                          style: ElevatedButton.styleFrom(
                            padding: const EdgeInsets.symmetric(vertical: 16),
                          ),
                        ),
                      ),
                      const SizedBox(width: AppSpacing.md),
                      Expanded(
                        child: OutlinedButton.icon(
                          onPressed: () => context.pop(),
                          icon: const Icon(Icons.close),
                          label: const Text('Passer'),
                          style: OutlinedButton.styleFrom(
                            padding: const EdgeInsets.symmetric(vertical: 16),
                            side: const BorderSide(color: AppColors.textSecondary),
                          ),
                        ),
                      ),
                    ],
                  ),
                  
                  const SizedBox(height: AppSpacing.lg),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSection(BuildContext context, String title, String content, IconData icon) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(
              icon,
              color: AppColors.primaryGold,
              size: 20,
            ),
            const SizedBox(width: AppSpacing.sm),
            Text(
              title,
              style: Theme.of(context).textTheme.headlineSmall,
            ),
          ],
        ),
        const SizedBox(height: AppSpacing.md),
        Text(
          content,
          style: Theme.of(context).textTheme.bodyLarge,
        ),
      ],
    );
  }

  void _showSelectionDialog(BuildContext context, MatchProfile profile) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppBorderRadius.large),
          ),
          title: Row(
            children: [
              Icon(
                Icons.favorite,
                color: AppColors.primaryGold,
              ),
              const SizedBox(width: AppSpacing.sm),
              const Text('Confirmer votre choix'),
            ],
          ),
          content: Text(
            'Voulez-vous vraiment choisir ${profile.name} ? Cette action terminera votre sélection du jour.',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Annuler'),
            ),
            ElevatedButton(
              onPressed: () {
                Navigator.of(context).pop();
                _selectProfile(context, profile);
              },
              child: const Text('Confirmer'),
            ),
          ],
        );
      },
    );
  }

  void _selectProfile(BuildContext context, MatchProfile profile) {
    final matchingProvider = Provider.of<MatchingProvider>(context, listen: false);
    
    // Add to selected profiles list
    matchingProvider.selectProfile(profile.id);
    
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Vous avez choisi ${profile.name} ! Revenez demain pour votre nouvelle sélection.'),
        backgroundColor: AppColors.successGreen,
        action: SnackBarAction(
          label: 'OK',
          textColor: Colors.white,
          onPressed: () {
            context.go('/home');
          },
        ),
      ),
    );
    
    // Navigate back to home after a delay
    Future.delayed(const Duration(seconds: 2), () {
      if (context.mounted) {
        context.go('/home');
      }
    });
  }

  void _showReportDialog(BuildContext context, MatchProfile profile) {
    ReportDialog.show(
      context,
      targetUserId: profile.id,
      targetUserName: profile.name,
    );
  }
}