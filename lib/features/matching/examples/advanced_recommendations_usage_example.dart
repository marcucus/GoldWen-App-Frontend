// Example: How to use Advanced Recommendations in your app

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';
import 'package:goldwen_app/features/matching/providers/matching_provider.dart';

/// Example 1: Navigate to Advanced Recommendations Page from Profile Details
void navigateToAdvancedRecommendations(BuildContext context, String userId, List<String> candidateIds) {
  context.go('/advanced-recommendations?userId=$userId&candidateIds=${candidateIds.join(',')}');
}

/// Example 2: Load advanced recommendations using the provider
class AdvancedRecommendationsExample extends StatefulWidget {
  const AdvancedRecommendationsExample({super.key});

  @override
  State<AdvancedRecommendationsExample> createState() => _AdvancedRecommendationsExampleState();
}

class _AdvancedRecommendationsExampleState extends State<AdvancedRecommendationsExample> {
  @override
  void initState() {
    super.initState();
    _loadRecommendations();
  }

  Future<void> _loadRecommendations() async {
    final matchingProvider = Provider.of<MatchingProvider>(context, listen: false);
    
    await matchingProvider.loadAdvancedRecommendations(
      userId: 'current-user-id',
      candidateIds: ['candidate-1', 'candidate-2', 'candidate-3'],
      includeAdvancedScoring: true,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<MatchingProvider>(
      builder: (context, matchingProvider, child) {
        if (matchingProvider.isLoadingAdvancedRecommendations) {
          return const Center(child: CircularProgressIndicator());
        }

        if (matchingProvider.error != null) {
          return Center(child: Text('Error: ${matchingProvider.error}'));
        }

        final recommendations = matchingProvider.advancedRecommendations;
        if (recommendations == null || recommendations.isEmpty) {
          return const Center(child: Text('No recommendations available'));
        }

        return ListView.builder(
          itemCount: recommendations.length,
          itemBuilder: (context, index) {
            final score = recommendations[index];
            return Card(
              child: ListTile(
                title: Text('Score: ${score.score.toStringAsFixed(1)}%'),
                subtitle: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Base: ${score.breakdown.baseScore.toStringAsFixed(1)}'),
                    Text('Bonuses: ${score.breakdown.totalBonuses.toStringAsFixed(1)}'),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }
}

/// Example 3: Add a button to existing profile detail page
class ProfileDetailWithAdvancedButton extends StatelessWidget {
  final String profileId;
  final String currentUserId;

  const ProfileDetailWithAdvancedButton({
    super.key,
    required this.profileId,
    required this.currentUserId,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Profile Details'),
      ),
      body: Column(
        children: [
          // Your existing profile content here
          const Expanded(
            child: Center(child: Text('Profile content...')),
          ),
          
          // Add button to view advanced recommendations
          Padding(
            padding: const EdgeInsets.all(16),
            child: ElevatedButton.icon(
              icon: const Icon(Icons.analytics),
              label: const Text('Voir le score avancé'),
              onPressed: () {
                context.go(
                  '/advanced-recommendations?userId=$currentUserId&candidateIds=$profileId',
                );
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFFD4AF37), // AppColors.primaryGold
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(
                  horizontal: 24,
                  vertical: 12,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// Example 4: Integrate with daily matches page
class DailyMatchesWithAdvancedScoring extends StatelessWidget {
  const DailyMatchesWithAdvancedScoring({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer<MatchingProvider>(
      builder: (context, matchingProvider, child) {
        final profiles = matchingProvider.dailyProfiles;
        
        return ListView.builder(
          itemCount: profiles.length,
          itemBuilder: (context, index) {
            final profile = profiles[index];
            
            return Card(
              child: ListTile(
                title: Text(profile.firstName ?? 'Unknown'),
                subtitle: Text('Age: ${profile.age}'),
                trailing: IconButton(
                  icon: const Icon(Icons.analytics),
                  tooltip: 'View Advanced Score',
                  onPressed: () {
                    // Get current user ID from auth provider or profile
                    final currentUserId = 'current-user-id'; // Replace with actual user ID
                    
                    context.go(
                      '/advanced-recommendations?userId=$currentUserId&candidateIds=${profile.id}',
                    );
                  },
                ),
              ),
            );
          },
        );
      },
    );
  }
}
