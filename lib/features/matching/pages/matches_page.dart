import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/widgets/modern_cards.dart';
import '../../../core/widgets/animated_widgets.dart';
import '../../../core/models/models.dart';
import '../providers/matching_provider.dart';
import '../../subscription/providers/subscription_provider.dart';

class MatchesPage extends StatefulWidget {
  const MatchesPage({super.key});

  @override
  State<MatchesPage> createState() => _MatchesPageState();
}

class _MatchesPageState extends State<MatchesPage> with TickerProviderStateMixin {
  late AnimationController _fadeController;
  late Animation<double> _fadeAnimation;

  @override
  void initState() {
    super.initState();
    _initializeAnimations();
    _loadMatches();
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

  void _loadMatches() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final matchingProvider = Provider.of<MatchingProvider>(context, listen: false);
      matchingProvider.loadMatches();
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
      backgroundColor: AppColors.backgroundCream,
      appBar: AppBar(
        title: Text(
          'Mes Matches',
          style: Theme.of(context).textTheme.headlineSmall?.copyWith(
            fontWeight: FontWeight.bold,
            color: AppColors.textDark,
          ),
        ),
        backgroundColor: AppColors.backgroundCream,
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.arrow_back, color: AppColors.textDark),
          onPressed: () => context.pop(),
        ),
      ),
      body: Consumer<MatchingProvider>(
        builder: (context, matchingProvider, child) {
          if (matchingProvider.isLoading) {
            return _buildLoadingState();
          }

          if (matchingProvider.error != null) {
            return _buildErrorState(matchingProvider.error!, matchingProvider);
          }

          if (matchingProvider.matches.isEmpty) {
            return _buildEmptyState();
          }

          return _buildMatchesList(matchingProvider.matches);
        },
      ),
    );
  }

  Widget _buildLoadingState() {
    return const Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          CircularProgressIndicator(
            valueColor: AlwaysStoppedAnimation<Color>(AppColors.primaryGold),
          ),
          SizedBox(height: 16),
          Text(
            'Chargement de vos matches...',
            style: TextStyle(
              color: AppColors.textSecondary,
              fontSize: 16,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildErrorState(String error, MatchingProvider provider) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.error_outline,
              size: 80,
              color: Colors.red.shade300,
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
              onPressed: () => provider.loadMatches(),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primaryGold,
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

  Widget _buildEmptyState() {
    return FadeTransition(
      opacity: _fadeAnimation,
      child: Center(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.favorite_outline,
                size: 100,
                color: AppColors.primaryGold.withOpacity(0.5),
              ),
              const SizedBox(height: 24),
              Text(
                'Aucun match pour le moment',
                style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: AppColors.textDark,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 16),
              Text(
                'Continuez à faire des sélections quotidiennes pour trouver vos matches !',
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: AppColors.textSecondary,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 32),
              ElevatedButton(
                onPressed: () => context.go('/home'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primaryGold,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 32,
                    vertical: 16,
                  ),
                ),
                child: const Text('Découvrir des profils'),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildMatchesList(List<Match> matches) {
    return FadeTransition(
      opacity: _fadeAnimation,
      child: RefreshIndicator(
        onRefresh: () async {
          final provider = Provider.of<MatchingProvider>(context, listen: false);
          await provider.loadMatches();
        },
        child: ListView.builder(
          padding: const EdgeInsets.all(16),
          itemCount: matches.length,
          itemBuilder: (context, index) {
            final match = matches[index];
            return _buildMatchCard(match);
          },
        ),
      ),
    );
  }

  Widget _buildMatchCard(Match match) {
    final profile = match.otherProfile;
    final isActive = match.status == 'active';
    final isPending = match.status == 'pending';

    return GlassCard(
      margin: const EdgeInsets.only(bottom: 16),
      child: InkWell(
        onTap: () {
          if (match.chatId != null && isActive) {
            context.push('/chat/${match.chatId}');
          } else if (profile != null) {
            context.push('/profile/${profile.id}');
          }
        },
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              // Profile Photo
              Container(
                width: 60,
                height: 60,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: LinearGradient(
                    colors: [
                      AppColors.primaryGold.withOpacity(0.3),
                      AppColors.primaryGold.withOpacity(0.7),
                    ],
                  ),
                ),
                child: (profile?.photos != null && profile!.photos.isNotEmpty)
                    ? ClipOval(
                        child: Image.network(
                          profile.photos.first.url,
                          width: 60,
                          height: 60,
                          fit: BoxFit.cover,
                          errorBuilder: (context, error, stackTrace) {
                            return Icon(
                              Icons.person,
                              color: Colors.white,
                              size: 30,
                            );
                          },
                        ),
                      )
                    : const Icon(
                        Icons.person,
                        color: Colors.white,
                        size: 30,
                      ),
              ),
              const SizedBox(width: 16),

              // Profile Info
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      profile?.firstName ?? 'Utilisateur',
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                        color: AppColors.textDark,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Compatibilité: ${(match.compatibilityScore * 100).round()}%',
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: AppColors.textSecondary,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      _formatMatchDate(match.createdAt),
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: AppColors.textSecondary,
                      ),
                    ),
                  ],
                ),
              ),

              // Status and Action
              Column(
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: _getStatusColor(match.status),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      _getStatusText(match.status),
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 12,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                  const SizedBox(height: 8),
                  if (isActive && match.chatId != null)
                    Icon(
                      Icons.chat_bubble,
                      color: AppColors.primaryGold,
                      size: 20,
                    )
                  else if (isPending)
                    Icon(
                      Icons.hourglass_empty,
                      color: Colors.orange,
                      size: 20,
                    ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  String _formatMatchDate(DateTime date) {
    final now = DateTime.now();
    final difference = now.difference(date);

    if (difference.inDays > 0) {
      return 'Il y a ${difference.inDays} jour${difference.inDays > 1 ? 's' : ''}';
    } else if (difference.inHours > 0) {
      return 'Il y a ${difference.inHours} heure${difference.inHours > 1 ? 's' : ''}';
    } else {
      return 'Il y a ${difference.inMinutes} minute${difference.inMinutes > 1 ? 's' : ''}';
    }
  }

  Color _getStatusColor(String status) {
    switch (status.toLowerCase()) {
      case 'active':
        return Colors.green;
      case 'pending':
        return Colors.orange;
      case 'expired':
        return Colors.red;
      default:
        return Colors.grey;
    }
  }

  String _getStatusText(String status) {
    switch (status.toLowerCase()) {
      case 'active':
        return 'Actif';
      case 'pending':
        return 'En attente';
      case 'expired':
        return 'Expiré';
      default:
        return 'Inconnu';
    }
  }
}