import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/widgets/animated_widgets.dart';
import '../../../core/widgets/modern_cards.dart';
import '../../auth/providers/auth_provider.dart';
import '../../matching/providers/matching_provider.dart';

class HomePage extends StatefulWidget {
  final void Function(int)? onNavigate;

  const HomePage({super.key, this.onNavigate});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> with TickerProviderStateMixin {
  late AnimationController _backgroundController;
  late AnimationController _headerController;
  late Animation<double> _backgroundAnimation;
  late Animation<Offset> _headerSlideAnimation;
  late Animation<double> _headerFadeAnimation;

  void Function(int)? get _navigateToTab => widget.onNavigate;

  @override
  void initState() {
    super.initState();
    _initializeAnimations();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadData();
      _startAnimations();
    });
  }

  void _initializeAnimations() {
    _backgroundController = AnimationController(
      duration: AppAnimations.verySlow,
      vsync: this,
    );
    _headerController = AnimationController(
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

    _headerSlideAnimation = Tween<Offset>(
      begin: const Offset(0, -1),
      end: Offset.zero,
    ).animate(CurvedAnimation(
      parent: _headerController,
      curve: AppAnimations.elasticOut,
    ));

    _headerFadeAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _headerController,
      curve: AppAnimations.easeOut,
    ));
  }

  void _startAnimations() {
    _backgroundController.forward();
    Future.delayed(const Duration(milliseconds: 200), () {
      _headerController.forward();
    });
  }

  @override
  void dispose() {
    _backgroundController.dispose();
    _headerController.dispose();
    super.dispose();
  }

  void _loadData() {
    final matchingProvider =
        Provider.of<MatchingProvider>(context, listen: false);
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
      body: AnimatedBuilder(
        animation: _backgroundAnimation,
        builder: (context, child) {
          return Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  AppColors.gradientStart,
                  AppColors.gradientMiddle,
                  AppColors.gradientEnd
                      .withOpacity(0.8 + 0.2 * _backgroundAnimation.value),
                ],
                stops: const [0.0, 0.5, 1.0],
              ),
            ),
            child: SafeArea(
              child: Column(
                children: [
                  _buildAnimatedHeader(),
                  Expanded(
                    child: _buildContent(),
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
    return AnimatedBuilder(
      animation: _headerController,
      builder: (context, child) {
        return SlideTransition(
          position: _headerSlideAnimation,
          child: FadeTransition(
            opacity: _headerFadeAnimation,
            child: _buildHeader(),
          ),
        );
      },
    );
  }

  Widget _buildHeader() {
    return Consumer<AuthProvider>(
      builder: (context, authProvider, child) {
        final user = authProvider.user;
        return Container(
          margin: const EdgeInsets.all(AppSpacing.lg),
          child: GlassCard(
            borderRadius: AppBorderRadius.xLarge,
            padding: const EdgeInsets.all(AppSpacing.lg),
            child: Row(
              children: [
                // Animated Profile Avatar
                AnimatedPressable(
                  onPressed: () => context.go('/profile'),
                  child: Container(
                    width: 60,
                    height: 60,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      gradient: AppColors.premiumGradient,
                      boxShadow: AppShadows.medium,
                    ),
                    padding: const EdgeInsets.all(3),
                    child: Container(
                      decoration: const BoxDecoration(
                        shape: BoxShape.circle,
                        color: AppColors.backgroundWhite,
                      ),
                      child: ClipOval(
                        child: user?.photoUrl != null
                            ? Image.network(
                                user!.photoUrl!,
                                fit: BoxFit.cover,
                                errorBuilder: (context, error, stackTrace) {
                                  return const Icon(
                                    Icons.person,
                                    color: AppColors.primaryGold,
                                    size: 30,
                                  );
                                },
                              )
                            : const Icon(
                                Icons.person,
                                color: AppColors.primaryGold,
                                size: 30,
                              ),
                      ),
                    ),
                  ),
                ),

                const SizedBox(width: AppSpacing.md),

                // Greeting and Name with animation
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      FadeInAnimation(
                        delay: const Duration(milliseconds: 300),
                        child: Text(
                          _getGreeting(),
                          style:
                              Theme.of(context).textTheme.bodyLarge?.copyWith(
                                    color: AppColors.textDark,
                                    fontWeight: FontWeight.w300,
                                  ),
                        ),
                      ),
                      FadeInAnimation(
                        delay: const Duration(milliseconds: 400),
                        child: Text(
                          user?.displayName ?? 'Utilisateur',
                          style: Theme.of(context)
                              .textTheme
                              .headlineSmall
                              ?.copyWith(
                                color: AppColors.textDark,
                                fontWeight: FontWeight.bold,
                              ),
                        ),
                      ),
                    ],
                  ),
                ),

                // Notification icon with badge
                FadeInAnimation(
                  delay: const Duration(milliseconds: 500),
                  child: AnimatedPressable(
                    onPressed: () {
                      // Navigate to notifications
                    },
                    child: Container(
                      padding: const EdgeInsets.all(AppSpacing.sm),
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: AppColors.primaryGold.withOpacity(0.1),
                      ),
                      child: Stack(
                        children: [
                          const Icon(
                            Icons.notifications_outlined,
                            color: AppColors.primaryGold,
                            size: 24,
                          ),
                          Positioned(
                            top: 0,
                            right: 0,
                            child: Container(
                              width: 8,
                              height: 8,
                              decoration: const BoxDecoration(
                                shape: BoxShape.circle,
                                color: AppColors.errorRed,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildContent() {
    return SingleChildScrollView(
      physics: const BouncingScrollPhysics(),
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Quick Stats Section
          _buildQuickStats(),

          const SizedBox(height: AppSpacing.xl),

          // Daily Matches Section
          _buildDailyMatches(),

          const SizedBox(height: AppSpacing.xl),

          // Quick Actions
          _buildQuickActions(),

          const SizedBox(height: AppSpacing.xl),

          // Recent Activity
          _buildRecentActivity(),

          const SizedBox(height: AppSpacing.xxl),
        ],
      ),
    );
  }

  Widget _buildQuickStats() {
    return SlideInAnimation(
      delay: const Duration(milliseconds: 600),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: AppSpacing.sm),
            child: Text(
              'Votre activité',
              style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                    color: AppColors.textLight,
                    fontWeight: FontWeight.bold,
                  ),
            ),
          ),
          const SizedBox(height: AppSpacing.md),
          Row(
            children: [
              Expanded(
                child: _buildStatCard(
                  icon: Icons.favorite,
                  value: '12',
                  label: 'Matchs',
                  gradient: LinearGradient(
                    colors: [
                      AppColors.errorRed.withOpacity(0.8),
                      AppColors.errorRed,
                    ],
                  ),
                ),
              ),
              const SizedBox(width: AppSpacing.sm),
              Expanded(
                child: _buildStatCard(
                  icon: Icons.chat_bubble_outline,
                  value: '8',
                  label: 'Messages',
                  gradient: LinearGradient(
                    colors: [
                      AppColors.infoBlue.withOpacity(0.8),
                      AppColors.infoBlue,
                    ],
                  ),
                ),
              ),
              const SizedBox(width: AppSpacing.sm),
              Expanded(
                child: _buildStatCard(
                  icon: Icons.visibility,
                  value: '24',
                  label: 'Vues',
                  gradient: AppColors.premiumGradient,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildStatCard({
    required IconData icon,
    required String value,
    required String label,
    required Gradient gradient,
  }) {
    return GlassCard(
      margin: EdgeInsets.zero,
      padding: const EdgeInsets.all(AppSpacing.md),
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(AppSpacing.sm),
            decoration: BoxDecoration(
              gradient: gradient,
              shape: BoxShape.circle,
            ),
            child: Icon(
              icon,
              color: Colors.white,
              size: 20,
            ),
          ),
          const SizedBox(height: AppSpacing.sm),
          Text(
            value,
            style: Theme.of(context).textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: AppColors.textDark,
                ),
          ),
          Text(
            label,
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: AppColors.textSecondary,
                ),
          ),
        ],
      ),
    );
  }

  Widget _buildDailyMatches() {
    return SlideInAnimation(
      delay: const Duration(milliseconds: 700),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: AppSpacing.sm),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Sélection du jour',
                  style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                        color: AppColors.textLight,
                        fontWeight: FontWeight.bold,
                      ),
                ),
                AnimatedPressable(
                  onPressed: () {
                    if (_navigateToTab != null) {
                      _navigateToTab!(1); // Navigate to discover tab
                    }
                  },
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: AppSpacing.md,
                      vertical: AppSpacing.sm,
                    ),
                    decoration: BoxDecoration(
                      color: AppColors.textLight.withOpacity(0.2),
                      borderRadius:
                          BorderRadius.circular(AppBorderRadius.large),
                    ),
                    child: Text(
                      'Voir tout',
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                            color: AppColors.textLight,
                            fontWeight: FontWeight.w600,
                          ),
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: AppSpacing.md),
          SizedBox(
            height: 200,
            child: Consumer<MatchingProvider>(
              builder: (context, matchingProvider, child) {
                if (matchingProvider.isLoading) {
                  return _buildMatchesShimmer();
                }

                // For now, create dummy data to avoid compilation errors
                final matches = <dynamic>[];
                if (matches.isEmpty) {
                  return _buildEmptyMatches();
                }

                return ListView.builder(
                  scrollDirection: Axis.horizontal,
                  physics: const BouncingScrollPhysics(),
                  padding:
                      const EdgeInsets.symmetric(horizontal: AppSpacing.sm),
                  itemCount: matches.length,
                  itemBuilder: (context, index) {
                    final match = matches[index];
                    return FadeInAnimation(
                      delay: Duration(milliseconds: 800 + (index * 100)),
                      child: _buildMatchCard(match, index),
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMatchCard(dynamic match, int index) {
    return Container(
      width: 150,
      margin: const EdgeInsets.only(right: AppSpacing.md),
      child: GlassCard(
        margin: EdgeInsets.zero,
        padding: EdgeInsets.zero,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: Container(
                decoration: BoxDecoration(
                  borderRadius: const BorderRadius.vertical(
                    top: Radius.circular(AppBorderRadius.large),
                  ),
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [
                      AppColors.primaryGold.withOpacity(0.3),
                      AppColors.primaryGold.withOpacity(0.1),
                    ],
                  ),
                ),
                child: const Center(
                  child: Icon(
                    Icons.person,
                    size: 50,
                    color: AppColors.primaryGold,
                  ),
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(AppSpacing.sm),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Profil ${index + 1}',
                    style: Theme.of(context).textTheme.titleSmall?.copyWith(
                          fontWeight: FontWeight.w600,
                        ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  Text(
                    '${20 + index} ans',
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: AppColors.textSecondary,
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

  Widget _buildMatchesShimmer() {
    return ListView.builder(
      scrollDirection: Axis.horizontal,
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.sm),
      itemCount: 3,
      itemBuilder: (context, index) {
        return Container(
          width: 150,
          margin: const EdgeInsets.only(right: AppSpacing.md),
          child: ShimmerLoading(
            isLoading: true,
            child: GlassCard(
              margin: EdgeInsets.zero,
              child: Container(
                decoration: BoxDecoration(
                  color: AppColors.backgroundGrey,
                  borderRadius: BorderRadius.circular(AppBorderRadius.large),
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildEmptyMatches() {
    return GlassCard(
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.favorite_outline,
              size: 48,
              color: AppColors.textSecondary.withOpacity(0.5),
            ),
            const SizedBox(height: AppSpacing.sm),
            Text(
              'Aucun match disponible',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: AppColors.textSecondary,
                  ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildQuickActions() {
    return SlideInAnimation(
      delay: const Duration(milliseconds: 800),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: AppSpacing.sm),
            child: Text(
              'Actions rapides',
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
              _buildActionCard(
                icon: Icons.search,
                title: 'Découvrir',
                subtitle: 'Trouvez votre match parfait',
                onTap: () {
                  if (_navigateToTab != null) {
                    _navigateToTab!(1);
                  }
                },
              ),
              _buildActionCard(
                icon: Icons.person,
                title: 'Profil',
                subtitle: 'Gérez votre profil et préférences',
                onTap: () => context.go('/profile'),
              ),
              _buildActionCard(
                icon: Icons.star,
                title: 'GoldWen Plus',
                subtitle: 'Accédez aux fonctionnalités premium',
                onTap: () => context.go('/subscription'),
                isHighlighted: true,
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildActionCard({
    required IconData icon,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
    bool isHighlighted = false,
  }) {
    return FloatingCard(
      onTap: onTap,
      backgroundColor:
          isHighlighted ? AppColors.primaryGold.withOpacity(0.1) : null,
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(AppSpacing.md),
            decoration: BoxDecoration(
              gradient: isHighlighted
                  ? AppColors.premiumGradient
                  : LinearGradient(
                      colors: [
                        AppColors.primaryGold.withOpacity(0.1),
                        AppColors.primaryGold.withOpacity(0.2),
                      ],
                    ),
              borderRadius: BorderRadius.circular(AppBorderRadius.medium),
            ),
            child: Icon(
              icon,
              color: isHighlighted ? Colors.white : AppColors.primaryGold,
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
                        color: isHighlighted
                            ? AppColors.primaryGold
                            : AppColors.textDark,
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
            color: AppColors.textSecondary,
          ),
        ],
      ),
    );
  }

  Widget _buildRecentActivity() {
    return SlideInAnimation(
      delay: const Duration(milliseconds: 900),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: AppSpacing.sm),
            child: Text(
              'Activité récente',
              style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                    color: AppColors.textLight,
                    fontWeight: FontWeight.bold,
                  ),
            ),
          ),
          const SizedBox(height: AppSpacing.md),
          GlassCard(
            child: Column(
              children: [
                _buildActivityItem(
                  icon: Icons.favorite,
                  title: 'Nouveau match',
                  subtitle: 'Vous avez un nouveau match avec Sarah',
                  time: 'Il y a 2h',
                  iconColor: AppColors.errorRed,
                ),
                const Divider(height: 1),
                _buildActivityItem(
                  icon: Icons.message,
                  title: 'Nouveau message',
                  subtitle: 'Marie vous a envoyé un message',
                  time: 'Il y a 5h',
                  iconColor: AppColors.infoBlue,
                ),
                const Divider(height: 1),
                _buildActivityItem(
                  icon: Icons.visibility,
                  title: 'Profil consulté',
                  subtitle: 'Votre profil a été consulté 3 fois aujourd\'hui',
                  time: 'Il y a 1j',
                  iconColor: AppColors.primaryGold,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildActivityItem({
    required IconData icon,
    required String title,
    required String subtitle,
    required String time,
    required Color iconColor,
  }) {
    return Padding(
      padding: const EdgeInsets.all(AppSpacing.md),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(AppSpacing.sm),
            decoration: BoxDecoration(
              color: iconColor.withOpacity(0.1),
              borderRadius: BorderRadius.circular(AppBorderRadius.small),
            ),
            child: Icon(
              icon,
              color: iconColor,
              size: 20,
            ),
          ),
          const SizedBox(width: AppSpacing.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: Theme.of(context).textTheme.titleSmall?.copyWith(
                        fontWeight: FontWeight.w600,
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
          Text(
            time,
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: AppColors.textTertiary,
                ),
          ),
        ],
      ),
    );
  }
}
