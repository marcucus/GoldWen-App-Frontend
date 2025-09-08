import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';
import '../../../core/widgets/animated_widgets.dart';
import '../../../core/widgets/modern_cards.dart';
import '../providers/matching_provider.dart';

class DailyMatchesPage extends StatefulWidget {
  const DailyMatchesPage({super.key});

  @override
  State<DailyMatchesPage> createState() => _DailyMatchesPageState();
}

class _DailyMatchesPageState extends State<DailyMatchesPage>
    with TickerProviderStateMixin {
  PageController _pageController = PageController();
  int _currentIndex = 0;
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
    _pageController.dispose();
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
                      'Découverte',
                      style:
                          Theme.of(context).textTheme.headlineSmall?.copyWith(
                                fontWeight: FontWeight.bold,
                              ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Trouvez votre match parfait',
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
    return Consumer<MatchingProvider>(
      builder: (context, matchingProvider, child) {
        if (matchingProvider.isLoading) {
          return _buildLoadingState();
        }

        final profiles = _generateSampleProfiles();

        if (profiles.isEmpty) {
          return _buildEmptyState();
        }

        return Column(
          children: [
            _buildProfileCounter(profiles.length),
            const SizedBox(height: 16),
            Expanded(
              child: _buildSwipeableCards(profiles),
            ),
            _buildActionButtons(),
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
          '${_currentIndex + 1} / $totalProfiles',
          style: Theme.of(context).textTheme.titleMedium?.copyWith(
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
      padding: const EdgeInsets.symmetric(horizontal: 16),
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
      margin: const EdgeInsets.symmetric(horizontal: 8),
      child: Stack(
        children: [
          Container(
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
              child: Stack(
                fit: StackFit.expand,
                children: [
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
                                child: Text(
                                  '${profile['name']}, ${profile['age']}',
                                  style: Theme.of(context)
                                      .textTheme
                                      .headlineMedium
                                      ?.copyWith(
                                        color: Colors.white,
                                        fontWeight: FontWeight.bold,
                                      ),
                                ),
                              ),
                              if (profile['isPremium'])
                                Container(
                                  decoration: const BoxDecoration(
                                    gradient: LinearGradient(
                                      colors: [
                                        Colors.amber,
                                        Colors.orange,
                                      ],
                                    ),
                                    shape: BoxShape.circle,
                                  ),
                                  child: const Padding(
                                    padding: EdgeInsets.all(6),
                                    child: Icon(
                                      Icons.star,
                                      color: Colors.white,
                                      size: 16,
                                    ),
                                  ),
                                ),
                            ],
                          ),
                          const SizedBox(height: 8),
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
                                style: Theme.of(context)
                                    .textTheme
                                    .bodyMedium
                                    ?.copyWith(
                                      color: Colors.white.withOpacity(0.9),
                                    ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 8),
                          Text(
                            profile['bio'],
                            style: Theme.of(context)
                                .textTheme
                                .bodyMedium
                                ?.copyWith(
                                  color: Colors.white.withOpacity(0.9),
                                ),
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                          ),
                          const SizedBox(height: 12),
                          _buildInterestTags(profile['interests']),
                        ],
                      ),
                    ),
                  ),
                  Positioned(
                    top: 16,
                    right: 16,
                    child: Column(
                      children: [
                        _buildQuickActionButton(
                          icon: Icons.info_outline,
                          onPressed: () => _showProfileDetails(profile),
                        ),
                        const SizedBox(height: 8),
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
      spacing: 8,
      runSpacing: 4,
      children: interests.take(3).map<Widget>((interest) {
        return Container(
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.2),
            borderRadius: BorderRadius.circular(8),
            border: Border.all(
              color: Colors.white.withOpacity(0.3),
              width: 1,
            ),
          ),
          child: Padding(
            padding: const EdgeInsets.symmetric(
              horizontal: 8,
              vertical: 4,
            ),
            child: Text(
              interest,
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: Colors.white,
                    fontWeight: FontWeight.w500,
                  ),
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
        padding: const EdgeInsets.all(12),
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
        padding: const EdgeInsets.symmetric(horizontal: 24),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: [
            _buildActionButton(
              icon: Icons.close,
              color: Colors.red,
              size: 56,
              onPressed: () => _handleReject(),
            ),
            _buildActionButton(
              icon: Icons.star,
              color: Colors.blue,
              size: 48,
              onPressed: () => _handleSuperLike(),
            ),
            _buildActionButton(
              icon: Icons.favorite,
              color: Colors.green,
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
          boxShadow: [
            BoxShadow(
              color: color.withOpacity(0.3),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
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
                Icons.favorite_outline,
                size: 60,
                color: Colors.white,
              ),
            ),
            const SizedBox(height: 24),
            Text(
              'Plus de profils pour aujourd\'hui',
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
        duration: const Duration(milliseconds: 800),
        curve: Curves.easeInOut,
      );
    }
  }

  void _showProfileDetails(Map<String, dynamic> profile) {
    // Show detailed profile view
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Profil de ${profile['name']}'),
        content: Text(profile['bio']),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Fermer'),
          ),
        ],
      ),
    );
  }

  void _shareProfile(Map<String, dynamic> profile) {
    // Handle profile sharing
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Partage du profil de ${profile['name']}'),
      ),
    );
  }

  List<Map<String, dynamic>> _generateSampleProfiles() {
    return [
      {
        'name': 'Sarah',
        'age': 25,
        'distance': 2,
        'bio':
            'Amoureuse de voyages et de bonne cuisine. Toujours partante pour de nouvelles aventures !',
        'interests': ['Voyage', 'Cuisine', 'Yoga', 'Photographie'],
        'isPremium': true,
        'color': Colors.pink,
      },
      {
        'name': 'Marie',
        'age': 28,
        'distance': 5,
        'bio':
            'Passionnée d\'art et de musique. Cherche quelqu\'un pour partager de beaux moments.',
        'interests': ['Art', 'Musique', 'Lecture', 'Cinéma'],
        'isPremium': false,
        'color': Colors.blue,
      },
      {
        'name': 'Julie',
        'age': 26,
        'distance': 3,
        'bio':
            'Sportive et aventurière. J\'adore l\'escalade et les randonnées en montagne.',
        'interests': ['Sport', 'Escalade', 'Randonnée', 'Nature'],
        'isPremium': true,
        'color': Colors.green,
      },
      {
        'name': 'Emma',
        'age': 24,
        'distance': 7,
        'bio':
            'Étudiante en médecine. Recherche une relation sérieuse et authentique.',
        'interests': ['Médecine', 'Lecture', 'Café', 'Animaux'],
        'isPremium': false,
        'color': Colors.orange,
      },
    ];
  }
}
