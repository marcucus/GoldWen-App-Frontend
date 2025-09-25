import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';
import '../../../core/widgets/animated_widgets.dart';
import '../../../core/widgets/modern_cards.dart';
import '../../../core/models/models.dart';
import '../providers/matching_provider.dart';
import '../../subscription/providers/subscription_provider.dart';
import '../../subscription/widgets/subscription_banner.dart';
import '../../chat/widgets/match_acceptance_dialog.dart';

class DailyMatchesPage extends StatefulWidget {
  const DailyMatchesPage({super.key});

  @override
  State<DailyMatchesPage> createState() => _DailyMatchesPageState();
}

class _DailyMatchesPageState extends State<DailyMatchesPage>
    with TickerProviderStateMixin {
  late AnimationController _backgroundController;
  late AnimationController _cardController;

  @override
  void initState() {
    super.initState();
    _initializeAnimations();
    _startAnimations();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadDailyMatches();
    });
  }

  void _initializeAnimations() {
    _backgroundController = AnimationController(
      duration: const Duration(milliseconds: 2000),
      vsync: this,
    );
    _cardController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );
  }

  void _startAnimations() {
    _backgroundController.forward();
    Future.delayed(const Duration(milliseconds: 300), () {
      _cardController.forward();
    });
  }

  @override
  void dispose() {
    _backgroundController.dispose();
    _cardController.dispose();
    super.dispose();
  }

  void _loadDailyMatches() {
    final matchingProvider =
        Provider.of<MatchingProvider>(context, listen: false);
    matchingProvider.loadDailySelection();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              Theme.of(context).primaryColor.withOpacity(0.3),
              Theme.of(context).primaryColor.withOpacity(0.1),
              Colors.white,
            ],
          ),
        ),
        child: SafeArea(
          child: Column(
            children: [
              _buildAnimatedHeader(),
              Expanded(
                child: _buildMatchesContent(),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildAnimatedHeader() {
    return FadeInAnimation(
      delay: const Duration(milliseconds: 200),
      child: Container(
        margin: const EdgeInsets.all(16),
        child: GlassCard(
          borderRadius: 24,
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Sélection du jour',
                      style:
                          Theme.of(context).textTheme.headlineSmall?.copyWith(
                                fontWeight: FontWeight.bold,
                              ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Découvrez vos matchs parfaits',
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                            color: Colors.grey[600],
                          ),
                    ),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      Theme.of(context).primaryColor,
                      Theme.of(context).primaryColor.withOpacity(0.8),
                    ],
                  ),
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.favorite,
                  color: Colors.white,
                  size: 24,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildMatchesContent() {
    return Consumer2<MatchingProvider, SubscriptionProvider>(
      builder: (context, matchingProvider, subscriptionProvider, child) {
        if (matchingProvider.isLoading) {
          return _buildLoadingState();
        }

        if (matchingProvider.error != null) {
          return _buildErrorState(matchingProvider.error!);
        }

        final profiles = matchingProvider.dailyProfiles;
        
        // If selection is complete, don't show any profiles
        if (matchingProvider.isSelectionComplete) {
          return _buildSelectionCompleteState(matchingProvider, subscriptionProvider);
        }
        
        final availableProfiles = profiles.where((profile) => 
          !matchingProvider.isProfileSelected(profile.id)
        ).toList();

        if (profiles.isEmpty) {
          return _buildEmptyState();
        }

        if (availableProfiles.isEmpty && profiles.isNotEmpty) {
          return _buildSelectionCompleteState(matchingProvider, subscriptionProvider);
        }

        return Column(
          children: [
            // Subscription status indicator for premium users
            if (subscriptionProvider.hasActiveSubscription)
              SubscriptionStatusIndicator(
                hasActiveSubscription: true,
                daysUntilExpiry: subscriptionProvider.daysUntilExpiry,
                compact: true,
              ),
            
            _buildProfileCounter(availableProfiles.length),
            _buildSelectionInfo(matchingProvider, subscriptionProvider),
            
            // Show upgrade banner for free users who have used their daily selection
            if (!subscriptionProvider.hasActiveSubscription && !matchingProvider.canSelectMore)
              SubscriptionPromoBanner(
                message: 'Limite atteinte ! Passez à GoldWen Plus pour 3 choix/jour',
                compact: true,
              ),
            
            const SizedBox(height: 16),
            Expanded(
              child: _buildProfileCards(availableProfiles, matchingProvider, subscriptionProvider),
            ),
            
            // Bottom banner for free users who still have selections
            if (!subscriptionProvider.hasActiveSubscription && matchingProvider.canSelectMore)
              SubscriptionPromoBanner(
                compact: true,
              ),
              
            const SizedBox(height: 16),
          ],
        );
      },
    );
  }

  Widget _buildProfileCounter(int totalProfiles) {
    return SlideInAnimation(
      delay: const Duration(milliseconds: 400),
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 16),
        padding: const EdgeInsets.symmetric(
          horizontal: 16,
          vertical: 8,
        ),
        decoration: BoxDecoration(
          color: Colors.white.withOpacity(0.2),
          borderRadius: BorderRadius.circular(16),
        ),
        child: Text(
          '$totalProfiles profil${totalProfiles > 1 ? 's' : ''} disponible${totalProfiles > 1 ? 's' : ''}',
          style: Theme.of(context).textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w600,
              ),
          textAlign: TextAlign.center,
        ),
      ),
    );
  }

  Widget _buildSelectionInfo(MatchingProvider matchingProvider, SubscriptionProvider subscriptionProvider) {
    final remainingSelections = matchingProvider.remainingSelections;
    final maxSelections = matchingProvider.maxSelections;
    final hasSubscription = subscriptionProvider.hasActiveSubscription;
    
    return SlideInAnimation(
      delay: const Duration(milliseconds: 300),
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 16),
        padding: const EdgeInsets.symmetric(
          horizontal: 16,
          vertical: 12,
        ),
        decoration: BoxDecoration(
          color: Colors.white.withOpacity(0.2),
          borderRadius: BorderRadius.circular(16),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Choix restants',
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    fontWeight: FontWeight.w500,
                  ),
                ),
                if (!hasSubscription)
                  Text(
                    'GoldWen Plus: 3 choix/jour',
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: Colors.grey[600],
                      fontStyle: FontStyle.italic,
                    ),
                  ),
              ],
            ),
            Row(
              children: [
                if (hasSubscription)
                  Container(
                    margin: const EdgeInsets.only(right: 8),
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                    decoration: BoxDecoration(
                      color: Colors.amber,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      'PLUS',
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                        fontSize: 10,
                      ),
                    ),
                  ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                  decoration: BoxDecoration(
                    color: remainingSelections > 0 
                      ? Theme.of(context).primaryColor
                      : Colors.grey[400],
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    '$remainingSelections/$maxSelections',
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
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

  Widget _buildProfileCards(List<Profile> profiles, MatchingProvider matchingProvider, SubscriptionProvider subscriptionProvider) {
    return ListView.builder(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      itemCount: profiles.length,
      itemBuilder: (context, index) {
        final profile = profiles[index];
        return SlideInAnimation(
          delay: Duration(milliseconds: 300 + (index * 100)),
          child: _buildProfileCard(profile, matchingProvider, subscriptionProvider),
        );
      },
    );
  }

  Widget _buildProfileCard(Profile profile, MatchingProvider matchingProvider, SubscriptionProvider subscriptionProvider) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 10,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(24),
        child: Container(
          height: 400,
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [
                Theme.of(context).primaryColor.withOpacity(0.3),
                Theme.of(context).primaryColor.withOpacity(0.8),
                Theme.of(context).primaryColor,
              ],
            ),
          ),
          child: Stack(
            children: [
              // Profile image placeholder
              const Center(
                child: Icon(
                  Icons.person,
                  size: 120,
                  color: Colors.white,
                ),
              ),
              // Gradient overlay
              Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [
                      Colors.transparent,
                      Colors.transparent,
                      Colors.black.withOpacity(0.7),
                    ],
                    stops: const [0.0, 0.5, 1.0],
                  ),
                ),
              ),
              // Profile info
              Positioned(
                bottom: 0,
                left: 0,
                right: 0,
                child: Container(
                  padding: const EdgeInsets.all(24),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  '${profile.firstName ?? ''} ${profile.lastName ?? ''}, ${profile.age ?? 'N/A'}',
                                  style: Theme.of(context)
                                      .textTheme
                                      .headlineMedium
                                      ?.copyWith(
                                        color: Colors.white,
                                        fontWeight: FontWeight.bold,
                                      ),
                                ),
                                const SizedBox(height: 4),
                                if (profile.bio?.isNotEmpty == true)
                                  Text(
                                    profile.bio!,
                                    style: Theme.of(context)
                                        .textTheme
                                        .bodyMedium
                                        ?.copyWith(
                                          color: Colors.white.withOpacity(0.9),
                                        ),
                                    maxLines: 2,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                              ],
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      // Action buttons
                      Row(
                        children: [
                          Expanded(
                            child: OutlinedButton.icon(
                              onPressed: () {
                                _showProfileDetails(profile);
                              },
                              icon: const Icon(Icons.info_outline),
                              label: const Text('Détails'),
                              style: OutlinedButton.styleFrom(
                                foregroundColor: Colors.white,
                                side: const BorderSide(color: Colors.white),
                                padding: const EdgeInsets.symmetric(vertical: 12),
                              ),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: ElevatedButton.icon(
                              onPressed: matchingProvider.canSelectMore
                                  ? () => _showChoiceConfirmation(profile, matchingProvider, subscriptionProvider)
                                  : null,
                              icon: const Icon(Icons.favorite),
                              label: const Text('Choisir'),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: matchingProvider.canSelectMore
                                    ? Colors.red
                                    : Colors.grey,
                                foregroundColor: Colors.white,
                                padding: const EdgeInsets.symmetric(vertical: 12),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildLoadingState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: 60,
            height: 60,
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  Theme.of(context).primaryColor,
                  Theme.of(context).primaryColor.withOpacity(0.8),
                ],
              ),
              shape: BoxShape.circle,
            ),
            child: const CircularProgressIndicator(
              valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
              strokeWidth: 3,
            ),
          ),
          const SizedBox(height: 16),
          Text(
            'Préparation de vos matchs...',
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w600,
                ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    Theme.of(context).primaryColor,
                    Theme.of(context).primaryColor.withOpacity(0.8),
                  ],
                ),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.search,
                color: Colors.white,
                size: 48,
              ),
            ),
            const SizedBox(height: 16),
            Text(
              'Aucun profil disponible',
              style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 12),
            Text(
              'Revenez demain pour découvrir de nouveaux profils ou explorez avec GoldWen Plus',
              style: Theme.of(context).textTheme.bodyMedium,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
            ElevatedButton(
              onPressed: () {
                // Navigation vers la page d'abonnement
                context.go('/subscription');
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: Theme.of(context).primaryColor,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(
                  horizontal: 24,
                  vertical: 12,
                ),
              ),
              child: const Text('Découvrir GoldWen Plus'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildErrorState(String error) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: Colors.red.withOpacity(0.2),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.error_outline,
                color: Colors.red,
                size: 48,
              ),
            ),
            const SizedBox(height: 16),
            Text(
              'Oups !',
              style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            Text(
              error,
              style: Theme.of(context).textTheme.bodyMedium,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
            ElevatedButton(
              onPressed: () {
                final matchingProvider = Provider.of<MatchingProvider>(context, listen: false);
                matchingProvider.loadDailySelection();
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: Theme.of(context).primaryColor,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(
                  horizontal: 24,
                  vertical: 12,
                ),
              ),
              child: const Text('Réessayer'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSelectionCompleteState(MatchingProvider matchingProvider, SubscriptionProvider subscriptionProvider) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    Theme.of(context).primaryColor,
                    Theme.of(context).primaryColor.withOpacity(0.8),
                  ],
                ),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.check,
                color: Colors.white,
                size: 48,
              ),
            ),
            const SizedBox(height: 16),
            Text(
              'Sélection terminée !',
              style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 12),
            Text(
              matchingProvider.selectionCompleteMessage ?? 
              'Vous avez fait vos choix pour aujourd\'hui. Revenez demain pour de nouveaux profils.',
              style: Theme.of(context).textTheme.bodyMedium,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
            if (!matchingProvider.hasSubscription)
              ElevatedButton(
                onPressed: () {
                  context.go('/subscription');
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: Theme.of(context).primaryColor,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 24,
                    vertical: 12,
                  ),
                ),
                child: const Text('Découvrir GoldWen Plus'),
              ),
          ],
        ),
      ),
    );
  }

  void _showProfileDetails(Profile profile) {
    // Navigate to profile detail page
    context.push('/profile-detail/${profile.id}');
  }

  void _showChoiceConfirmation(Profile profile, MatchingProvider matchingProvider, SubscriptionProvider subscriptionProvider) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          title: Row(
            children: [
              Icon(
                Icons.favorite,
                color: Theme.of(context).primaryColor,
              ),
              const SizedBox(width: 8),
              const Text('Confirmer votre choix'),
            ],
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Voulez-vous vraiment choisir ${profile.firstName ?? 'cette personne'} ?',
                style: Theme.of(context).textTheme.bodyLarge,
              ),
              const SizedBox(height: 8),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Theme.of(context).primaryColor.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  matchingProvider.remainingSelections - 1 <= 0
                      ? 'Ce sera votre dernier choix aujourd\'hui.'
                      : 'Il vous restera ${matchingProvider.remainingSelections - 1} choix après cette sélection.',
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: Theme.of(context).primaryColor,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
              if (matchingProvider.remainingSelections - 1 <= 0 && !subscriptionProvider.hasActiveSubscription)
                Padding(
                  padding: const EdgeInsets.only(top: 8.0),
                  child: Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: Colors.amber.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: Colors.amber.withOpacity(0.3)),
                    ),
                    child: Row(
                      children: [
                        Icon(
                          Icons.upgrade,
                          color: Colors.amber[700],
                          size: 16,
                        ),
                        const SizedBox(width: 6),
                        Expanded(
                          child: Text(
                            'GoldWen Plus : 3 choix/jour',
                            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                              color: Colors.amber[700],
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Annuler'),
            ),
            ElevatedButton(
              onPressed: () {
                Navigator.of(context).pop();
                _selectProfile(profile, matchingProvider, subscriptionProvider);
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: Theme.of(context).primaryColor,
                foregroundColor: Colors.white,
              ),
              child: const Text('Confirmer'),
            ),
          ],
        );
      },
    );
  }

  Future<void> _selectProfile(Profile profile, MatchingProvider matchingProvider, SubscriptionProvider subscriptionProvider) async {
    // Check if user can select more profiles
    if (!matchingProvider.canSelectMore) {
      if (!subscriptionProvider.hasActiveSubscription) {
        // Show upgrade dialog for free users
        showDialog(
          context: context,
          builder: (context) => SubscriptionLimitReachedDialog(
            currentSelections: matchingProvider.maxSelections - matchingProvider.remainingSelections,
            maxSelections: matchingProvider.maxSelections,
          ),
        );
        return;
      } else {
        // Premium user reached their limit
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Vous avez atteint votre limite quotidienne de 3 sélections'),
            backgroundColor: Colors.orange,
          ),
        );
        return;
      }
    }
    
    final result = await matchingProvider.selectProfile(
      profile.id, 
      subscriptionProvider: subscriptionProvider,
    );
    
    if (result != null) {
      final isMatch = result['isMatch'] ?? false;
      
      if (isMatch) {
        // Show match acceptance dialog
        final matchId = result['matchId'] as String?;
        final matchedProfile = result['profile'] as Profile?;
        
        if (matchId != null && matchedProfile != null && mounted) {
          await showDialog(
            context: context,
            barrierDismissible: false,
            builder: (context) => MatchAcceptanceDialog(
              matchId: matchId,
              otherUser: matchedProfile,
              onAccepted: () {
                // Chat will be created and user navigated to it
              },
              onDeclined: () {
                // Match declined, show appropriate feedback
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Match décliné'),
                    backgroundColor: Colors.orange,
                  ),
                );
              },
            ),
          );
        }
      } else {
        // No match, show regular success message
        final remaining = matchingProvider.remainingSelections;
        String message;
        
        if (remaining <= 0 || matchingProvider.isSelectionComplete) {
          message = '✨ Votre choix est fait ! Revenez demain pour de nouveaux profils.';
        } else {
          message = '💖 Vous avez choisi ${profile.firstName ?? 'cette personne'} ! Il vous reste $remaining choix.';
        }
        
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(message),
            backgroundColor: Colors.green,
            duration: const Duration(seconds: 4),
          ),
        );
      }
    } else {
      final errorMessage = matchingProvider.error ?? 'Erreur lors de la sélection';
      
      // Check if error suggests upgrade
      if (!subscriptionProvider.hasActiveSubscription && 
          errorMessage.contains('limite')) {
        showDialog(
          context: context,
          builder: (context) => SubscriptionLimitReachedDialog(
            currentSelections: matchingProvider.maxSelections - matchingProvider.remainingSelections,
            maxSelections: matchingProvider.maxSelections,
          ),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(errorMessage),
            backgroundColor: Colors.red,
            duration: const Duration(seconds: 3),
          ),
        );
      }
    }
  }
}