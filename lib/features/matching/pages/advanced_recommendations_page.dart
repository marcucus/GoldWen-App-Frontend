import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../core/models/models.dart';
import '../../../core/services/api_service.dart';
import '../../../core/theme/app_theme.dart';
import '../../../shared/widgets/loading_animation.dart';
import '../widgets/score_breakdown_card.dart';
import '../widgets/match_reasons_widget.dart';

class AdvancedRecommendationsPage extends StatefulWidget {
  final String? userId;
  final List<String>? candidateIds;

  const AdvancedRecommendationsPage({
    super.key,
    this.userId,
    this.candidateIds,
  });

  @override
  State<AdvancedRecommendationsPage> createState() => _AdvancedRecommendationsPageState();
}

class _AdvancedRecommendationsPageState extends State<AdvancedRecommendationsPage> {
  List<CompatibilityScoreV2>? _compatibilityScores;
  bool _isLoading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _loadAdvancedRecommendations();
  }

  Future<void> _loadAdvancedRecommendations() async {
    if (widget.userId == null || widget.candidateIds == null || widget.candidateIds!.isEmpty) {
      setState(() {
        _error = 'Paramètres invalides';
        _isLoading = false;
      });
      return;
    }

    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final response = await ApiService.calculateCompatibilityV2(
        userId: widget.userId!,
        candidateIds: widget.candidateIds!,
        personalityAnswers: {}, // TODO: Get from user profile
        preferences: {}, // TODO: Get from user preferences
        includeAdvancedScoring: true,
      );

      final scoresData = response['data']?['compatibilityScores'] ?? response['compatibilityScores'];
      
      if (scoresData is List) {
        setState(() {
          _compatibilityScores = scoresData
              .map((score) => CompatibilityScoreV2.fromJson(score as Map<String, dynamic>))
              .toList();
          _isLoading = false;
        });
      } else {
        throw Exception('Format de réponse invalide');
      }
    } catch (e) {
      setState(() {
        _error = e.toString();
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Recommandations Avancées'),
        backgroundColor: AppColors.primaryGold,
        foregroundColor: Colors.white,
        elevation: 0,
      ),
      body: _buildBody(),
    );
  }

  Widget _buildBody() {
    if (_isLoading) {
      return const LoadingAnimation(
        message: 'Calcul des compatibilités avancées...',
      );
    }

    if (_error != null) {
      return _buildErrorState();
    }

    if (_compatibilityScores == null || _compatibilityScores!.isEmpty) {
      return _buildEmptyState();
    }

    return _buildRecommendationsList();
  }

  Widget _buildErrorState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.error_outline,
              size: 64,
              color: AppColors.errorRed,
            ),
            const SizedBox(height: 16),
            Text(
              'Erreur de chargement',
              style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
            ),
            const SizedBox(height: 8),
            Text(
              _error ?? 'Une erreur est survenue',
              style: Theme.of(context).textTheme.bodyMedium,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
            ElevatedButton(
              onPressed: _loadAdvancedRecommendations,
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primaryGold,
                foregroundColor: Colors.white,
              ),
              child: const Text('Réessayer'),
            ),
          ],
        ),
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
            Icon(
              Icons.search_off,
              size: 64,
              color: AppColors.textSecondary,
            ),
            const SizedBox(height: 16),
            Text(
              'Aucune recommandation',
              style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
            ),
            const SizedBox(height: 8),
            Text(
              'Aucune recommandation avancée n\'est disponible pour le moment.',
              style: Theme.of(context).textTheme.bodyMedium,
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildRecommendationsList() {
    return RefreshIndicator(
      onRefresh: _loadAdvancedRecommendations,
      color: AppColors.primaryGold,
      child: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: _compatibilityScores!.length,
        itemBuilder: (context, index) {
          final scoreData = _compatibilityScores![index];
          return _buildRecommendationCard(scoreData);
        },
      ),
    );
  }

  Widget _buildRecommendationCard(CompatibilityScoreV2 scoreData) {
    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header with final score
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Score de compatibilité',
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 8,
                  ),
                  decoration: BoxDecoration(
                    gradient: AppColors.premiumGradient,
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    '${scoreData.score.toStringAsFixed(1)}%',
                    style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                        ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            
            // Score breakdown
            ScoreBreakdownCard(breakdown: scoreData.breakdown),
            
            const SizedBox(height: 16),
            
            // Match reasons
            if (scoreData.matchReasons.isNotEmpty) ...[
              const Divider(),
              const SizedBox(height: 16),
              Text(
                'Raisons du match',
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
              ),
              const SizedBox(height: 8),
              MatchReasonsWidget(matchReasons: scoreData.matchReasons),
            ],
          ],
        ),
      ),
    );
  }
}
