import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';
import '../../../core/widgets/animated_widgets.dart';
import '../../../core/widgets/modern_cards.dart';
import '../../../core/models/models.dart';
import '../../../core/services/accessibility_service.dart';
import '../../../core/services/performance_cache_service.dart';
import '../../../shared/widgets/optimized_image.dart';
import '../../../shared/widgets/loading_animation.dart';
import '../../../shared/widgets/enhanced_card.dart';
import '../../../shared/widgets/enhanced_button.dart';
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
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadDailyMatches();
      _preloadProfileImages();
    });
  }

  void _initializeAnimations() {
    final accessibilityService = context.read<AccessibilityService>();
    
    _backgroundController = AnimationController(
      duration: accessibilityService.getAnimationDuration(const Duration(milliseconds: 2000)),
      vsync: this,
    );
    _cardController = AnimationController(
      duration: accessibilityService.getAnimationDuration(const Duration(milliseconds: 800)),
      vsync: this,
    );

    _startAnimations();
  }

  void _startAnimations() {
    final accessibilityService = context.read<AccessibilityService>();
    
    if (!accessibilityService.reducedMotion) {
      _backgroundController.forward();
      Future.delayed(const Duration(milliseconds: 300), () {
        if (mounted) _cardController.forward();
      });
    } else {
      // Skip animations for reduced motion
      _backgroundController.value = 1.0;
      _cardController.value = 1.0;
    }
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

  /// Preload profile images for better performance
  void _preloadProfileImages() async {
    final matchingProvider = Provider.of<MatchingProvider>(context, listen: false);
    final cacheService = Provider.of<PerformanceCacheService>(context, listen: false);
    
    // Wait a bit for the profiles to be loaded
    await Future.delayed(const Duration(milliseconds: 500));
    
    if (matchingProvider.dailyProfiles.isNotEmpty) {
      final imageUrls = matchingProvider.dailyProfiles
          .expand((profile) => profile.photos ?? [])
          .where((url) => url.isNotEmpty)
          .take(10) // Preload first 10 images
          .toList();
      
      for (final url in imageUrls) {
        cacheService.loadImageWithCache(url);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final accessibilityService = context.watch<AccessibilityService>();
    
    return Scaffold(
      body: Container(
        decoration: BoxDecoration(
          gradient: accessibilityService.highContrast ? null : LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              Theme.of(context).primaryColor.withOpacity(0.3),
              Theme.of(context).primaryColor.withOpacity(0.1),
              Colors.white,
            ],
          ),
          color: accessibilityService.highContrast ? Theme.of(context).scaffoldBackgroundColor : null,
        ),
        child: SafeArea(
          child: Semantics(
            label: 'Page de sélection quotidienne',
            child: Column(
              children: [
                _buildAnimatedHeader(accessibilityService),
                Expanded(
                  child: _buildMatchesContent(),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildAnimatedHeader(AccessibilityService accessibilityService) {
    Widget header = Container(
      margin: const EdgeInsets.all(16),
      child: GlassCard(
        borderRadius: 24,
        padding: const EdgeInsets.all(16),
        child: Semantics(
          label: 'En-tête de sélection quotidienne',
          child: Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Sélection du jour',
                      style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                      semanticsLabel: 'Titre: Sélection du jour',
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Découvrez vos matchs parfaits',
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: Colors.grey[600],
                      ),
                      semanticsLabel: 'Description: Découvrez vos matchs parfaits',
                    ),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  gradient: accessibilityService.highContrast ? null : LinearGradient(
                    colors: [
                      Theme.of(context).primaryColor,
                      Theme.of(context).primaryColor.withOpacity(0.8),
                    ],
                  ),
                  color: accessibilityService.highContrast ? Theme.of(context).primaryColor : null,
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  Icons.favorite,
                  color: Colors.white,
                  size: 24,
                  semanticLabel: 'Icône cœur',
                ),
              ),
            ],
          ),
        ),
      ),
    );

    if (accessibilityService.reducedMotion) {
      return header;
    }

    return FadeInAnimation(
      delay: const Duration(milliseconds: 200),
      child: header,
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

        return Semantics(
          label: '${availableProfiles.length} profils disponibles pour sélection',
          child: Column(
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
          ),
        );
      },
    );
  }

  Widget _buildProfileCounter(int totalProfiles) {
    final accessibilityService = context.watch<AccessibilityService>();
    final content = Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      padding: const EdgeInsets.symmetric(
        horizontal: 16,
        vertical: 8,
      ),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.2),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Semantics(
        label: '$totalProfiles profil${totalProfiles > 1 ? 's' : ''} disponible${totalProfiles > 1 ? 's' : ''}',
        child: Text(
          '$totalProfiles profil${totalProfiles > 1 ? 's' : ''} disponible${totalProfiles > 1 ? 's' : ''}',
          style: Theme.of(context).textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w600,
              ),
          textAlign: TextAlign.center,
        ),
      ),
    );

    if (accessibilityService.reducedMotion) {
      return content;
    }

    return SlideInAnimation(
      delay: const Duration(milliseconds: 400),
      child: content,
    );
  }

  Widget _buildSelectionInfo(MatchingProvider matchingProvider, SubscriptionProvider subscriptionProvider) {
    final accessibilityService = context.watch<AccessibilityService>();
    final remainingSelections = matchingProvider.remainingSelections;
    final maxSelections = matchingProvider.maxSelections;
    final hasSubscription = subscriptionProvider.hasActiveSubscription;
    
    final content = Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      padding: const EdgeInsets.symmetric(
        horizontal: 16,
        vertical: 12,
      ),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.2),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Semantics(
        label: 'Choix restants: $remainingSelections sur $maxSelections${hasSubscription ? ' avec abonnement GoldWen Plus' : ''}',
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
                      semanticsLabel: 'Abonné GoldWen Plus',
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

    if (accessibilityService.reducedMotion) {
      return content;
    }

    return SlideInAnimation(
      delay: const Duration(milliseconds: 300),
      child: content,
    );
  }

  Widget _buildProfileCards(List<Profile> profiles, MatchingProvider matchingProvider, SubscriptionProvider subscriptionProvider) {
    final accessibilityService = context.watch<AccessibilityService>();
    
    return ListView.builder(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      itemCount: profiles.length,
      itemBuilder: (context, index) {
        final profile = profiles[index];
        
        Widget card = _buildProfileCard(profile, matchingProvider, subscriptionProvider);
        
        if (accessibilityService.reducedMotion) {
          return card;
        }

        return SlideInAnimation(
          delay: Duration(milliseconds: 300 + (index * 100)),
          child: card,
        );
      },
    );
  }

  Widget _buildProfileCard(Profile profile, MatchingProvider matchingProvider, SubscriptionProvider subscriptionProvider) {
    return Semantics(
      label: 'Profil de ${profile.firstName ?? ''} ${profile.lastName ?? ''}, ${profile.age ?? 'âge non spécifié'} ans',
      hint: 'Appuyez pour voir les détails du profil',
      button: true,
      child: GestureDetector(
        onTap: () => _showProfileDetails(profile),
        child: Container(
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
              child: Stack(
                children: [
                // Optimized profile image
                Positioned.fill(
                  child: OptimizedImage(
                    imageUrl: profile.photos?.isNotEmpty == true ? profile.photos!.first.url : null,
                    semanticLabel: 'Photo de profil de ${profile.firstName ?? 'cette personne'}',
                    fit: BoxFit.cover,
                    lazyLoad: true,
                    fadeIn: true,
                    placeholder: Container(
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.topCenter,
                          end: Alignment.bottomCenter,
                          colors: [
                            Theme.of(context).primaryColor.withOpacity(0.3),
                            Theme.of(context).primaryColor.withOpacity(0.7),
                          ],
                        ),
                      ),
                      child: const Center(
                        child: ProfileCardSkeleton(),
                      ),
                    ),
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
                                    semanticsLabel: 'Nom: ${profile.firstName ?? ''} ${profile.lastName ?? ''}, Âge: ${profile.age ?? 'non spécifié'} ans',
                                  ),
                                  const SizedBox(height: 4),
                                  if (profile.location?.isNotEmpty == true)
                                    Row(
                                      children: [
                                        Icon(
                                          Icons.location_on,
                                          color: Colors.white.withOpacity(0.9),
                                          size: 16,
                                        ),
                                        const SizedBox(width: 4),
                                        Text(
                                          profile.location!,
                                          style: Theme.of(context)
                                              .textTheme
                                              .bodySmall
                                              ?.copyWith(
                                                color: Colors.white.withOpacity(0.9),
                                              ),
                                        ),
                                      ],
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
                                      semanticsLabel: 'Bio: ${profile.bio}',
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
                              child: Semantics(
                                label: 'Passer ce profil',
                                hint: 'Appuyez pour passer au profil suivant sans sélectionner',
                                button: true,
                                child: OutlinedButton.icon(
                                  onPressed: () {
                                    _passProfile(profile, matchingProvider, subscriptionProvider);
                                  },
                                  icon: const Icon(Icons.close),
                                  label: const Text('Passer'),
                                  style: OutlinedButton.styleFrom(
                                    foregroundColor: Colors.white,
                                    side: const BorderSide(color: Colors.white),
                                    padding: const EdgeInsets.symmetric(vertical: 12),
                                  ),
                                ),
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Semantics(
                                label: matchingProvider.canSelectMore 
                                    ? 'Choisir ${profile.firstName ?? 'ce profil'}'
                                    : 'Limite de sélection atteinte',
                                hint: matchingProvider.canSelectMore 
                                    ? 'Appuyez pour sélectionner ce profil'
                                    : 'Vous avez atteint votre limite quotidienne',
                                button: matchingProvider.canSelectMore,
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
      ),
    );
  }

  Widget _buildLoadingState() {
    return const LoadingAnimation(
      message: 'Préparation de vos matchs...',
      semanticLabel: 'Chargement des profils de la sélection quotidienne',
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Semantics(
          label: 'Aucun profil disponible aujourd\'hui',
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
                  semanticLabel: 'Icône de recherche',
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
              Semantics(
                label: 'Découvrir GoldWen Plus',
                hint: 'Appuyez pour voir les options d\'abonnement premium',
                button: true,
                child: ElevatedButton(
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
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildErrorState(String error) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Semantics(
          label: 'Erreur de chargement: $error',
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
                  semanticLabel: 'Icône d\'erreur',
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
              Semantics(
                label: 'Réessayer le chargement',
                hint: 'Appuyez pour recharger la sélection quotidienne',
                button: true,
                child: ElevatedButton(
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
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSelectionCompleteState(MatchingProvider matchingProvider, SubscriptionProvider subscriptionProvider) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Semantics(
          label: 'Sélection quotidienne terminée',
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
                  semanticLabel: 'Icône de validation',
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
                Semantics(
                  label: 'Découvrir GoldWen Plus pour plus d\'options',
                  hint: 'Appuyez pour voir les avantages de l\'abonnement premium',
                  button: true,
                  child: ElevatedButton(
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
                ),
            ],
          ),
        ),
      ),
    );
  }

  void _showProfileDetails(Profile profile) {
    // Navigate to profile detail page
    context.push('/profile-detail/${profile.id}');
  }

  Future<void> _passProfile(Profile profile, MatchingProvider matchingProvider, SubscriptionProvider subscriptionProvider) async {
    final result = await matchingProvider.selectProfile(
      profile.id,
      subscriptionProvider: subscriptionProvider,
      choice: 'pass',
    );
    
    if (result != null) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Profil passé. Continuez à explorer !'),
            backgroundColor: Colors.grey[700],
            duration: const Duration(seconds: 2),
          ),
        );
      }
    } else {
      final errorMessage = matchingProvider.error ?? 'Erreur lors du passage du profil';
      if (mounted) {
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

  void _showChoiceConfirmation(Profile profile, MatchingProvider matchingProvider, SubscriptionProvider subscriptionProvider) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return Semantics(
          label: 'Dialogue de confirmation de choix',
          child: AlertDialog(
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
            title: Row(
              children: [
                Icon(
                  Icons.favorite,
                  color: Theme.of(context).primaryColor,
                  semanticLabel: 'Icône cœur',
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
                            semanticLabel: 'Icône de mise à niveau',
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
              Semantics(
                label: 'Annuler la sélection',
                hint: 'Appuyez pour fermer sans sélectionner',
                button: true,
                child: TextButton(
                  onPressed: () => Navigator.of(context).pop(),
                  child: const Text('Annuler'),
                ),
              ),
              Semantics(
                label: 'Confirmer la sélection de ${profile.firstName ?? 'cette personne'}',
                hint: 'Appuyez pour finaliser votre choix',
                button: true,
                child: ElevatedButton(
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
              ),
            ],
          ),
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
      choice: 'like',
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