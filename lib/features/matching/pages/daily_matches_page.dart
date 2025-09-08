import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/widgets/animated_widgets.dart';
import '../../../core/widgets/modern_cards.dart';
import '../providers/matching_provider.dart';
import '../../../core/models/profile.dart';
import '../../subscription/pages/subscription_page.dart';

class DailyMatchesPage extends StatefulWidget {
  const DailyMatchesPage({super.key});

  @override
  State<DailyMatchesPage> createState() => _DailyMatchesPageState();
}

class _DailyMatchesPageState extends State<DailyMatchesPage> with TickerProviderStateMixin {
  PageController _pageController = PageController();
  int _currentIndex = 0;
  late AnimationController _backgroundController;
  late AnimationController _cardController;
  late Animation<double> _backgroundAnimation;

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
      duration: AppAnimations.verySlow,
      vsync: this,
    );
    _cardController = AnimationController(
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
    _pageController.dispose();
    super.dispose();
  }

  void _loadDailyMatches() {
    final matchingProvider = Provider.of<MatchingProvider>(context, listen: false);
    matchingProvider.loadDailySelection();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            AppColors.gradientStart,
            AppColors.gradientMiddle,
            AppColors.gradientEnd.withOpacity(0.8),
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
    );
  }

  Widget _buildAnimatedHeader() {
    return FadeInAnimation(
      delay: const Duration(milliseconds: 200),
      child: Container(
        margin: const EdgeInsets.all(AppSpacing.lg),
        child: GlassCard(
          borderRadius: AppBorderRadius.xLarge,
          padding: const EdgeInsets.all(AppSpacing.lg),
          child: Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Découverte',
                      style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                        color: AppColors.textDark,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Trouvez votre match parfait',
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: AppColors.textSecondary,
                      ),
                    ),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.all(AppSpacing.sm),
                decoration: BoxDecoration(
                  gradient: AppColors.premiumGradient,
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
    return Consumer<MatchingProvider>(
      builder: (context, matchingProvider, child) {
        if (matchingProvider.isLoading) {
          return _buildLoadingState();
        }

        final profiles = _generateSampleProfiles(); // Using sample data for demo
        
        if (profiles.isEmpty) {
          return _buildEmptyState();
        }

        return Column(
          children: [
            // Profile counter
            _buildProfileCounter(profiles.length),
            
            const SizedBox(height: AppSpacing.lg),
            
            // Swipeable cards
            Expanded(
              child: _buildSwipeableCards(profiles),
            ),
            
            // Action buttons
            _buildActionButtons(),
            
            const SizedBox(height: AppSpacing.lg),
          ],
        );
      },
    );
  }

  Widget _buildProfileCounter(int totalProfiles) {
    return SlideInAnimation(
      delay: const Duration(milliseconds: 400),
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
        padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.lg,
          vertical: AppSpacing.sm,
        ),
        decoration: BoxDecoration(
          color: Colors.white.withOpacity(0.2),
          borderRadius: BorderRadius.circular(AppBorderRadius.large),
        ),
        child: Text(
          '${_currentIndex + 1} / $totalProfiles',
          style: Theme.of(context).textTheme.titleMedium?.copyWith(
            color: AppColors.textLight,
            fontWeight: FontWeight.w600,
          ),
          textAlign: TextAlign.center,
        ),
      ),
    );
  }

  Widget _buildSwipeableCards(List<Map<String, dynamic>> profiles) {
    return Container(
      height: MediaQuery.of(context).size.height * 0.6,
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
      child: PageView.builder(
        controller: _pageController,
        onPageChanged: (index) {
          setState(() {
            _currentIndex = index;
          });
        },
        itemCount: profiles.length,
        itemBuilder: (context, index) {
          final profile = profiles[index];
          return SlideInAnimation(
            delay: Duration(milliseconds: 500 + (index * 100)),
            child: _buildProfileCard(profile, index),
          );
        },
      ),
    );
  }

  Widget _buildProfileCard(Map<String, dynamic> profile, int index) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: AppSpacing.sm),
      child: Stack(
        children: [
          // Main card
          Container(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(AppBorderRadius.xLarge),
              boxShadow: AppShadows.floating,
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(AppBorderRadius.xLarge),
              child: Stack(
                fit: StackFit.expand,
                children: [
                  // Background image/gradient
                  Container(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: [
                          profile['color'].withOpacity(0.3),
                          profile['color'].withOpacity(0.8),
                          profile['color'],
                        ],
                      ),
                    ),
                    child: const Center(
                      child: Icon(
                        Icons.person,
                        size: 120,
                        color: Colors.white,
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
                      padding: const EdgeInsets.all(AppSpacing.xl),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Row(
                            children: [
                              Expanded(
                                child: Text(
                                  '${profile['name']}, ${profile['age']}',
                                  style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                                    color: Colors.white,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                              if (profile['isPremium'])
                                Container(
                                  padding: const EdgeInsets.all(6),
                                  decoration: const BoxDecoration(
                                    gradient: AppColors.premiumGradient,
                                    shape: BoxShape.circle,
                                  ),
                                  child: const Icon(
                                    Icons.star,
                                    color: Colors.white,
                                    size: 16,
                                  ),
                                ),
                            ],
                          ),
                          const SizedBox(height: AppSpacing.sm),
                          Row(
                            children: [
                              const Icon(
                                Icons.location_on,
                                color: Colors.white,
                                size: 16,
                              ),
                              const SizedBox(width: 4),
                              Text(
                                '${profile['distance']} km',
                                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                                  color: Colors.white.withOpacity(0.9),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: AppSpacing.sm),
                          Text(
                            profile['bio'],
                            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                              color: Colors.white.withOpacity(0.9),
                            ),
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                          ),
                          const SizedBox(height: AppSpacing.md),
                          _buildInterestTags(profile['interests']),
                        ],
                      ),
                    ),
                  ),
                  
                  // Quick action buttons
                  Positioned(
                    top: AppSpacing.lg,
                    right: AppSpacing.lg,
                    child: Column(
                      children: [
                        _buildQuickActionButton(
                          icon: Icons.info_outline,
                          onPressed: () => _showProfileDetails(profile),
                        ),
                        const SizedBox(height: AppSpacing.sm),
                        _buildQuickActionButton(
                          icon: Icons.share,
                          onPressed: () => _shareProfile(profile),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInterestTags(List<String> interests) {
    return Wrap(
      spacing: AppSpacing.sm,
      runSpacing: AppSpacing.xs,
      children: interests.take(3).map((interest) {
        return Container(
          padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.sm,
            vertical: 4,
          ),
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.2),
            borderRadius: BorderRadius.circular(AppBorderRadius.small),
            border: Border.all(
              color: Colors.white.withOpacity(0.3),
              width: 1,
            ),
          ),
          child: Text(
            interest,
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
              color: Colors.white,
              fontWeight: FontWeight.w500,
            ),
          ),
        );
      }).toList(),
    );
  }

  Widget _buildQuickActionButton({
    required IconData icon,
    required VoidCallback onPressed,
  }) {
    return AnimatedPressable(
      onPressed: onPressed,
      child: Container(
        padding: const EdgeInsets.all(AppSpacing.sm),
        decoration: BoxDecoration(
          color: Colors.black.withOpacity(0.3),
          shape: BoxShape.circle,
          border: Border.all(
            color: Colors.white.withOpacity(0.3),
            width: 1,
          ),
        ),
        child: Icon(
          icon,
          color: Colors.white,
          size: 20,
        ),
      ),
    );
  }

  Widget _buildActionButtons() {
    return SlideInAnimation(
      delay: const Duration(milliseconds: 600),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: AppSpacing.xl),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: [
            _buildActionButton(
              icon: Icons.close,
              color: AppColors.errorRed,
              size: 56,
              onPressed: () => _handleReject(),
            ),
            _buildActionButton(
              icon: Icons.star,
              color: AppColors.infoBlue,
              size: 48,
              onPressed: () => _handleSuperLike(),
            ),
            _buildActionButton(
              icon: Icons.favorite,
              color: AppColors.successGreen,
              size: 56,
              onPressed: () => _handleLike(),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildActionButton({
    required IconData icon,
    required Color color,
    required double size,
    required VoidCallback onPressed,
  }) {
    return AnimatedPressable(
      onPressed: onPressed,
      child: Container(
        width: size,
        height: size,
        decoration: BoxDecoration(
          color: color,
          shape: BoxShape.circle,
          boxShadow: AppShadows.medium,
        ),
        child: Icon(
          icon,
          color: Colors.white,
          size: size * 0.4,
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
            padding: const EdgeInsets.all(AppSpacing.md),
            decoration: BoxDecoration(
              gradient: AppColors.premiumGradient,
              shape: BoxShape.circle,
            ),
            child: const CircularProgressIndicator(
              valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
              strokeWidth: 3,
            ),
          ),
          const SizedBox(height: AppSpacing.lg),
          Text(
            'Préparation de vos matchs...',
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
              color: AppColors.textLight,
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
        padding: const EdgeInsets.all(AppSpacing.xl),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(AppSpacing.xl),
              decoration: BoxDecoration(
                gradient: AppColors.premiumGradient,
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.favorite_outline,
                size: 60,
                color: Colors.white,
              ),
            ),
            const SizedBox(height: AppSpacing.xl),
            Text(
              'Plus de profils pour aujourd\'hui',
              style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                color: AppColors.textLight,
                fontWeight: FontWeight.bold,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: AppSpacing.md),
            Text(
              'Revenez demain pour découvrir de nouveaux profils ou explorez avec GoldWen Plus',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: AppColors.textLight.withOpacity(0.8),
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: AppSpacing.xl),
            PremiumButton(
              text: 'Découvrir GoldWen Plus',
              onPressed: () => context.go('/subscription'),
              gradient: LinearGradient(
                colors: [
                  Colors.white.withOpacity(0.9),
                  Colors.white,
                ],
              ),
              textColor: AppColors.primaryGold,
            ),
          ],
        ),
      ),
    );
  }

  void _handleLike() {
    _animateToNextProfile();
    // Handle like logic
  }

  void _handleReject() {
    _animateToNextProfile();
    // Handle reject logic
  }

  void _handleSuperLike() {
    _animateToNextProfile();
    // Handle super like logic
  }

  void _animateToNextProfile() {
    if (_currentIndex < _generateSampleProfiles().length - 1) {
      _pageController.nextPage(
        duration: AppAnimations.medium,
        curve: AppAnimations.easeInOut,
      );
    }
  }

  void _showProfileDetails(Map<String, dynamic> profile) {
    // Show detailed profile view
  }

  void _shareProfile(Map<String, dynamic> profile) {
    // Handle profile sharing
  }

  List<Map<String, dynamic>> _generateSampleProfiles() {
    return [
      {
        'name': 'Sarah',
        'age': 25,
        'distance': 2,
        'bio': 'Amoureuse de voyages et de bonne cuisine. Toujours partante pour de nouvelles aventures !',
        'interests': ['Voyage', 'Cuisine', 'Yoga', 'Photographie'],
        'isPremium': true,
        'color': AppColors.errorRed,
      },
      {
        'name': 'Marie',
        'age': 28,
        'distance': 5,
        'bio': 'Passionnée d\'art et de musique. Cherche quelqu\'un pour partager de beaux moments.',
        'interests': ['Art', 'Musique', 'Lecture', 'Cinéma'],
        'isPremium': false,
        'color': AppColors.infoBlue,
      },
      {
        'name': 'Julie',
        'age': 26,
        'distance': 3,
        'bio': 'Sportive et aventurière. J\'adore l\'escalade et les randonnées en montagne.',
        'interests': ['Sport', 'Escalade', 'Randonnée', 'Nature'],
        'isPremium': true,
        'color': AppColors.successGreen,
      },
      {
        'name': 'Emma',
        'age': 24,
        'distance': 7,
        'bio': 'Étudiante en médecine. Recherche une relation sérieuse et authentique.',
        'interests': ['Médecine', 'Lecture', 'Café', 'Animaux'],
        'isPremium': false,
        'color': AppColors.warningAmber,
      },
    ];
  }
}
                    ),
                  ),
                  Container(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                        colors: [
                          AppColors.cardOverlay.withOpacity(0.3),
                          AppColors.cardOverlay.withOpacity(0.2),
                        ],
                      ),
                      shape: BoxShape.circle,
                      boxShadow: [
                        BoxShadow(
                          color: AppColors.cardOverlay.withOpacity(0.2),
                          blurRadius: 8,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    child: IconButton(
                      onPressed: () => Navigator.of(context).push(
                        MaterialPageRoute(
                          builder: (context) => const SubscriptionPage(),
                        ),
                      ),
                      icon: const Icon(
                        Icons.star,
                        color: AppColors.textLight,
                        size: 26,
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