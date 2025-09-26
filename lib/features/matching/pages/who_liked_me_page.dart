import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/widgets/modern_cards.dart';
import '../../../core/widgets/animated_widgets.dart';
import '../../../core/models/models.dart';
import '../providers/matching_provider.dart';
import '../../subscription/providers/subscription_provider.dart';

class WhoLikedMePage extends StatefulWidget {
  const WhoLikedMePage({super.key});

  @override
  State<WhoLikedMePage> createState() => _WhoLikedMePageState();
}

class _WhoLikedMePageState extends State<WhoLikedMePage>
    with TickerProviderStateMixin {
  late AnimationController _fadeController;
  late Animation<double> _fadeAnimation;

  @override
  void initState() {
    super.initState();
    _initializeAnimations();
    _loadData();
  }

  void _initializeAnimations() {
    _fadeController = AnimationController(
      duration: const Duration(milliseconds: 600),
      vsync: this,
    );

    _fadeAnimation = CurvedAnimation(
      parent: _fadeController,
      curve: Curves.easeInOut,
    );

    _fadeController.forward();
  }

  void _loadData() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final subscriptionProvider = Provider.of<SubscriptionProvider>(context, listen: false);
      subscriptionProvider.loadSubscriptionUsage();
      
      // Only load data if user has premium subscription
      if (subscriptionProvider.canSeeWhoLikedYou) {
        final matchingProvider = Provider.of<MatchingProvider>(context, listen: false);
        matchingProvider.loadWhoLikedMe();
      }
    });
  }

  @override
  void dispose() {
    _fadeController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: _buildAppBar(),
      backgroundColor: AppColors.backgroundDark,
      body: Consumer2<SubscriptionProvider, MatchingProvider>(
        builder: (context, subscriptionProvider, matchingProvider, child) {
          // Show premium gate for non-subscribers
          if (!subscriptionProvider.canSeeWhoLikedYou) {
            return _buildPremiumGate(context);
          }

          // Show loading state
          if (matchingProvider.isLoadingWhoLikedMe) {
            return _buildLoadingState();
          }

          // Show error state
          if (matchingProvider.error != null) {
            return _buildErrorState(matchingProvider.error!);
          }

          // Show content
          return _buildContent(matchingProvider.whoLikedMe);
        },
      ),
    );
  }

  PreferredSizeWidget _buildAppBar() {
    return AppBar(
      backgroundColor: AppColors.backgroundDark,
      elevation: 0,
      leading: IconButton(
        icon: const Icon(Icons.arrow_back_ios, color: Colors.white),
        onPressed: () => context.pop(),
      ),
      title: const Text(
        'Qui m\'a sélectionné',
        style: TextStyle(
          color: Colors.white,
          fontSize: 20,
          fontWeight: FontWeight.bold,
        ),
      ),
      centerTitle: true,
    );
  }

  Widget _buildPremiumGate(BuildContext context) {
    return FadeTransition(
      opacity: _fadeAnimation,
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.lg),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            SlideInAnimation(
              delay: const Duration(milliseconds: 200),
              child: Container(
                padding: const EdgeInsets.all(AppSpacing.xxl),
                decoration: BoxDecoration(
                  gradient: AppColors.premiumGradient,
                  borderRadius: BorderRadius.circular(AppBorderRadius.xLarge),
                ),
                child: Icon(
                  Icons.visibility,
                  size: 80,
                  color: Colors.white.withOpacity(0.9),
                ),
              ),
            ),
            const SizedBox(height: AppSpacing.xl),
            
            SlideInAnimation(
              delay: const Duration(milliseconds: 400),
              child: Text(
                'Fonctionnalité Premium',
                style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                    ),
                textAlign: TextAlign.center,
              ),
            ),
            
            const SizedBox(height: AppSpacing.md),
            
            SlideInAnimation(
              delay: const Duration(milliseconds: 600),
              child: Text(
                'Découvrez qui s\'intéresse à vous ! Avec GoldWen Plus, vous pouvez voir tous les profils qui vous ont sélectionné.',
                style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                      color: Colors.white.withOpacity(0.8),
                      height: 1.5,
                    ),
                textAlign: TextAlign.center,
              ),
            ),
            
            const SizedBox(height: AppSpacing.xl),
            
            SlideInAnimation(
              delay: const Duration(milliseconds: 800),
              child: _buildFeaturesList(),
            ),
            
            const SizedBox(height: AppSpacing.xl),
            
            SlideInAnimation(
              delay: const Duration(milliseconds: 1000),
              child: PremiumButton(
                text: 'Passer à GoldWen Plus',
                onPressed: () => context.push('/subscription'),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFeaturesList() {
    final features = [
      'Voir qui vous a sélectionné',
      'Jusqu\'à 3 choix par jour',
      'Chat illimité avec vos matches',
      'Profil mis en avant',
    ];

    return Container(
      padding: const EdgeInsets.all(AppSpacing.lg),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.1),
        borderRadius: BorderRadius.circular(AppBorderRadius.large),
        border: Border.all(
          color: Colors.white.withOpacity(0.2),
          width: 1,
        ),
      ),
      child: Column(
        children: features
            .map((feature) => Padding(
                  padding: const EdgeInsets.symmetric(vertical: AppSpacing.xs),
                  child: Row(
                    children: [
                      Icon(
                        Icons.check_circle,
                        color: AppColors.primaryGold,
                        size: 20,
                      ),
                      const SizedBox(width: AppSpacing.sm),
                      Expanded(
                        child: Text(
                          feature,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 14,
                          ),
                        ),
                      ),
                    ],
                  ),
                ))
            .toList(),
      ),
    );
  }

  Widget _buildLoadingState() {
    return FadeTransition(
      opacity: _fadeAnimation,
      child: const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            CircularProgressIndicator(color: AppColors.primaryGold),
            SizedBox(height: AppSpacing.lg),
            Text(
              'Chargement...',
              style: TextStyle(color: Colors.white70),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildErrorState(String error) {
    return FadeTransition(
      opacity: _fadeAnimation,
      child: Center(
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.lg),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.error_outline,
                color: AppColors.errorRed,
                size: 64,
              ),
              const SizedBox(height: AppSpacing.lg),
              Text(
                'Erreur',
                style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                    ),
              ),
              const SizedBox(height: AppSpacing.sm),
              Text(
                error,
                style: const TextStyle(color: Colors.white70),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: AppSpacing.lg),
              ElevatedButton(
                onPressed: _loadData,
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primaryGold,
                  foregroundColor: Colors.black,
                ),
                child: const Text('Réessayer'),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildContent(List<WhoLikedMeItem> whoLikedMe) {
    if (whoLikedMe.isEmpty) {
      return _buildEmptyState();
    }

    return FadeTransition(
      opacity: _fadeAnimation,
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.md),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            SlideInAnimation(
              delay: const Duration(milliseconds: 200),
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: AppSpacing.sm),
                child: Text(
                  '${whoLikedMe.length} ${whoLikedMe.length == 1 ? 'personne vous a sélectionné' : 'personnes vous ont sélectionné'}',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        color: Colors.white.withOpacity(0.8),
                      ),
                ),
              ),
            ),
            const SizedBox(height: AppSpacing.lg),
            
            Expanded(
              child: ListView.builder(
                itemCount: whoLikedMe.length,
                itemBuilder: (context, index) {
                  final item = whoLikedMe[index];
                  return SlideInAnimation(
                    delay: Duration(milliseconds: 400 + (index * 100)),
                    child: _buildProfileCard(item),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    return FadeTransition(
      opacity: _fadeAnimation,
      child: Center(
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.lg),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              SlideInAnimation(
                delay: const Duration(milliseconds: 200),
                child: Container(
                  padding: const EdgeInsets.all(AppSpacing.xl),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.1),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    Icons.favorite_border,
                    size: 64,
                    color: Colors.white.withOpacity(0.6),
                  ),
                ),
              ),
              const SizedBox(height: AppSpacing.xl),
              
              SlideInAnimation(
                delay: const Duration(milliseconds: 400),
                child: Text(
                  'Aucune sélection pour le moment',
                  style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                      ),
                  textAlign: TextAlign.center,
                ),
              ),
              
              const SizedBox(height: AppSpacing.md),
              
              SlideInAnimation(
                delay: const Duration(milliseconds: 600),
                child: Text(
                  'Soyez patient ! Votre profil sera bientôt découvert par d\'autres utilisateurs.',
                  style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                        color: Colors.white.withOpacity(0.7),
                        height: 1.5,
                      ),
                  textAlign: TextAlign.center,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildProfileCard(WhoLikedMeItem item) {
    return Container(
      margin: const EdgeInsets.only(bottom: AppSpacing.md),
      child: GlassCard(
        borderRadius: AppBorderRadius.large,
        child: InkWell(
          onTap: () => context.push('/profile/${item.userId}'),
          borderRadius: BorderRadius.circular(AppBorderRadius.large),
          child: Padding(
            padding: const EdgeInsets.all(AppSpacing.md),
            child: Row(
              children: [
                // Profile Image
                Container(
                  width: 80,
                  height: 80,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(AppBorderRadius.medium),
                    image: item.user.photos.isNotEmpty
                        ? DecorationImage(
                            image: NetworkImage(item.user.photos.first.url),
                            fit: BoxFit.cover,
                          )
                        : null,
                    color: item.user.photos.isEmpty
                        ? Colors.white.withOpacity(0.1)
                        : null,
                  ),
                  child: item.user.photos.isEmpty
                      ? Icon(
                          Icons.person,
                          size: 40,
                          color: Colors.white.withOpacity(0.5),
                        )
                      : null,
                ),
                
                const SizedBox(width: AppSpacing.md),
                
                // Profile Info
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        item.user.firstName,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      
                      if (item.user.age != null) ...[
                        const SizedBox(height: AppSpacing.xs),
                        Text(
                          '${item.user.age} ans',
                          style: TextStyle(
                            color: Colors.white.withOpacity(0.7),
                            fontSize: 14,
                          ),
                        ),
                      ],
                      
                      const SizedBox(height: AppSpacing.xs),
                      
                      Text(
                        'Vous a sélectionné ${_formatTimeAgo(item.likedAt)}',
                        style: TextStyle(
                          color: AppColors.primaryGold,
                          fontSize: 12,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                ),
                
                // Action Button
                Container(
                  padding: const EdgeInsets.all(AppSpacing.xs),
                  decoration: BoxDecoration(
                    color: AppColors.primaryGold.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(AppBorderRadius.small),
                  ),
                  child: Icon(
                    Icons.arrow_forward_ios,
                    color: AppColors.primaryGold,
                    size: 16,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  String _formatTimeAgo(DateTime dateTime) {
    final now = DateTime.now();
    final difference = now.difference(dateTime);

    if (difference.inDays > 0) {
      return 'il y a ${difference.inDays} ${difference.inDays == 1 ? 'jour' : 'jours'}';
    } else if (difference.inHours > 0) {
      return 'il y a ${difference.inHours} ${difference.inHours == 1 ? 'heure' : 'heures'}';
    } else if (difference.inMinutes > 0) {
      return 'il y a ${difference.inMinutes} ${difference.inMinutes == 1 ? 'minute' : 'minutes'}';
    } else {
      return 'à l\'instant';
    }
  }
}