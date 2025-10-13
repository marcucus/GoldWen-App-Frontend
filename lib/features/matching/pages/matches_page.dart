import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/widgets/modern_cards.dart';
import '../../../core/widgets/animated_widgets.dart';
import '../../../core/models/models.dart';
import '../providers/matching_provider.dart';
import '../../subscription/providers/subscription_provider.dart';
import '../widgets/match_card_widget.dart';

enum MatchFilter { active, expiringSoon, archived }

class MatchesPage extends StatefulWidget {
  const MatchesPage({super.key});

  @override
  State<MatchesPage> createState() => _MatchesPageState();
}

class _MatchesPageState extends State<MatchesPage> with TickerProviderStateMixin {
  late AnimationController _fadeController;
  late Animation<double> _fadeAnimation;
  MatchFilter _selectedFilter = MatchFilter.active;

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
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(60),
          child: _buildFilterTabs(),
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

          final filteredMatches = _filterMatches(matchingProvider.matches);

          if (filteredMatches.isEmpty) {
            return _buildEmptyState();
          }

          return _buildMatchesList(filteredMatches);
        },
      ),
    );
  }

  Widget _buildFilterTabs() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Row(
        children: [
          _buildFilterChip(
            label: 'Actifs',
            filter: MatchFilter.active,
            icon: Icons.favorite,
          ),
          const SizedBox(width: 8),
          _buildFilterChip(
            label: 'Expire bientôt',
            filter: MatchFilter.expiringSoon,
            icon: Icons.timer,
          ),
          const SizedBox(width: 8),
          _buildFilterChip(
            label: 'Archivés',
            filter: MatchFilter.archived,
            icon: Icons.archive,
          ),
        ],
      ),
    );
  }

  Widget _buildFilterChip({
    required String label,
    required MatchFilter filter,
    required IconData icon,
  }) {
    final isSelected = _selectedFilter == filter;
    
    return Expanded(
      child: FilterChip(
        selected: isSelected,
        label: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              icon,
              size: 16,
              color: isSelected ? Colors.white : AppColors.primaryGold,
            ),
            const SizedBox(width: 4),
            Flexible(
              child: Text(
                label,
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: isSelected ? Colors.white : AppColors.primaryGold,
                ),
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
        onSelected: (selected) {
          setState(() {
            _selectedFilter = filter;
          });
        },
        selectedColor: AppColors.primaryGold,
        backgroundColor: Colors.white,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
          side: BorderSide(
            color: isSelected ? AppColors.primaryGold : AppColors.primaryGold.withOpacity(0.3),
            width: 1,
          ),
        ),
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
      ),
    );
  }

  List<Match> _filterMatches(List<Match> matches) {
    switch (_selectedFilter) {
      case MatchFilter.active:
        return matches.where((match) {
          return match.status == 'active' && !match.isExpired;
        }).toList();
      case MatchFilter.expiringSoon:
        return matches.where((match) {
          if (match.expiresAt == null || match.isExpired) return false;
          final hoursRemaining = match.expiresAt!.difference(DateTime.now()).inHours;
          return hoursRemaining <= 3 && match.status == 'active';
        }).toList();
      case MatchFilter.archived:
        return matches.where((match) {
          return match.status == 'archived' || match.isExpired;
        }).toList();
    }
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
    String title;
    String message;
    IconData icon;
    
    switch (_selectedFilter) {
      case MatchFilter.active:
        title = 'Aucun match actif';
        message = 'Continuez à faire des sélections quotidiennes pour trouver vos matches !';
        icon = Icons.favorite_outline;
        break;
      case MatchFilter.expiringSoon:
        title = 'Aucun match expirant bientôt';
        message = 'Tous vos matches ont encore beaucoup de temps !';
        icon = Icons.timer;
        break;
      case MatchFilter.archived:
        title = 'Aucun match archivé';
        message = 'Vos matches archivés apparaîtront ici.';
        icon = Icons.archive_outlined;
        break;
    }
    
    return FadeTransition(
      opacity: _fadeAnimation,
      child: Center(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                icon,
                size: 100,
                color: AppColors.primaryGold.withOpacity(0.5),
              ),
              const SizedBox(height: 24),
              Text(
                title,
                style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: AppColors.textDark,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 16),
              Text(
                message,
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: AppColors.textSecondary,
                ),
                textAlign: TextAlign.center,
              ),
              if (_selectedFilter == MatchFilter.active) ...[
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
            return MatchCardWidget(
              match: match,
              onArchive: () {
                final provider = Provider.of<MatchingProvider>(context, listen: false);
                provider.deleteMatch(match.id);
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Match archivé'),
                    duration: Duration(seconds: 2),
                  ),
                );
              },
            );
          },
        ),
      ),
    );
  }
}