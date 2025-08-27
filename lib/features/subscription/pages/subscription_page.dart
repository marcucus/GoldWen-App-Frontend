import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../../core/theme/app_theme.dart';

class SubscriptionPage extends StatefulWidget {
  const SubscriptionPage({super.key});

  @override
  State<SubscriptionPage> createState() => _SubscriptionPageState();
}

class _SubscriptionPageState extends State<SubscriptionPage> {
  int _selectedPlanIndex = 1; // Default to quarterly plan

  final List<Map<String, dynamic>> _plans = [
    {
      'duration': 'Mensuel',
      'price': '19,99 €',
      'pricePerMonth': '19,99 €/mois',
      'saving': null,
      'popular': false,
    },
    {
      'duration': 'Trimestriel',
      'price': '49,99 €',
      'pricePerMonth': '16,66 €/mois',
      'saving': 'Économisez 17%',
      'popular': true,
    },
    {
      'duration': 'Semestriel',
      'price': '89,99 €',
      'pricePerMonth': '14,99 €/mois',
      'saving': 'Économisez 25%',
      'popular': false,
    },
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('GoldWen Plus'),
        leading: IconButton(
          icon: const Icon(Icons.close),
          onPressed: () => context.pop(),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(AppSpacing.lg),
        child: Column(
          children: [
            // Header
            Container(
              padding: const EdgeInsets.all(AppSpacing.lg),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    AppColors.primaryGold.withOpacity(0.1),
                    AppColors.accentCream,
                  ],
                ),
                borderRadius: BorderRadius.circular(AppBorderRadius.large),
              ),
              child: Column(
                children: [
                  Container(
                    width: 80,
                    height: 80,
                    decoration: BoxDecoration(
                      color: AppColors.primaryGold,
                      shape: BoxShape.circle,
                      boxShadow: [
                        BoxShadow(
                          color: AppColors.primaryGold.withOpacity(0.3),
                          blurRadius: 20,
                          offset: const Offset(0, 10),
                        ),
                      ],
                    ),
                    child: const Icon(
                      Icons.star,
                      size: 40,
                      color: Colors.white,
                    ),
                  ),
                  const SizedBox(height: AppSpacing.lg),
                  Text(
                    'Passez à GoldWen Plus',
                    style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                          color: AppColors.primaryGold,
                        ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: AppSpacing.sm),
                  Text(
                    'Maximisez vos chances de trouver la bonne personne',
                    style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                          color: AppColors.textSecondary,
                        ),
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            ),

            const SizedBox(height: AppSpacing.xl),

            // Features
            _buildFeaturesList(),

            const SizedBox(height: AppSpacing.xl),

            // Plans
            Text(
              'Choisissez votre formule',
              style: Theme.of(context).textTheme.headlineSmall,
            ),

            const SizedBox(height: AppSpacing.lg),

            Column(
              children: _plans.asMap().entries.map((entry) {
                final index = entry.key;
                final plan = entry.value;
                return _buildPlanCard(index, plan);
              }).toList(),
            ),

            const SizedBox(height: AppSpacing.xl),

            // Subscribe button
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _subscribe,
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 18),
                ),
                child: Text(
                  'Commencer mon abonnement',
                  style: const TextStyle(fontSize: 16),
                ),
              ),
            ),

            const SizedBox(height: AppSpacing.md),

            // Terms
            Text(
              'Votre abonnement sera automatiquement renouvelé. Vous pouvez l\'annuler à tout moment dans les réglages.',
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: AppColors.textSecondary,
                  ),
              textAlign: TextAlign.center,
            ),

            const SizedBox(height: AppSpacing.lg),

            // Links
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                TextButton(
                  onPressed: () {
                    // TODO: Show terms
                  },
                  child: const Text('Conditions d\'utilisation'),
                ),
                TextButton(
                  onPressed: () {
                    // TODO: Show privacy policy
                  },
                  child: const Text('Confidentialité'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFeaturesList() {
    final features = [
      {
        'icon': Icons.favorite,
        'title': '3 sélections par jour',
        'description':
            'Choisissez jusqu\'à 3 profils dans votre sélection quotidienne',
      },
      {
        'icon': Icons.priority_high,
        'title': 'Profil mis en avant',
        'description': 'Votre profil apparaît en priorité dans les sélections',
      },
      {
        'icon': Icons.visibility,
        'title': 'Voir qui vous a choisi',
        'description': 'Découvrez les personnes qui vous ont sélectionné',
      },
      {
        'icon': Icons.undo,
        'title': 'Annuler une sélection',
        'description': 'Changez d\'avis et récupérez une sélection',
      },
    ];

    return Column(
      children: features.map((feature) {
        return Padding(
          padding: const EdgeInsets.only(bottom: AppSpacing.lg),
          child: Row(
            children: [
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: AppColors.primaryGold.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(AppBorderRadius.medium),
                ),
                child: Icon(
                  feature['icon'] as IconData,
                  color: AppColors.primaryGold,
                  size: 24,
                ),
              ),
              const SizedBox(width: AppSpacing.md),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      feature['title'] as String,
                      style: Theme.of(context).textTheme.labelLarge,
                    ),
                    Text(
                      feature['description'] as String,
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            color: AppColors.textSecondary,
                          ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        );
      }).toList(),
    );
  }

  Widget _buildPlanCard(int index, Map<String, dynamic> plan) {
    final isSelected = index == _selectedPlanIndex;
    final isPopular = plan['popular'] as bool;

    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.md),
      child: GestureDetector(
        onTap: () {
          setState(() {
            _selectedPlanIndex = index;
          });
        },
        child: Container(
          padding: const EdgeInsets.all(AppSpacing.lg),
          decoration: BoxDecoration(
            color: isSelected
                ? AppColors.primaryGold.withOpacity(0.1)
                : AppColors.backgroundWhite,
            border: Border.all(
              color:
                  isSelected ? AppColors.primaryGold : AppColors.dividerLight,
              width: isSelected ? 2 : 1,
            ),
            borderRadius: BorderRadius.circular(AppBorderRadius.large),
          ),
          child: Stack(
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Radio<int>(
                        value: index,
                        groupValue: _selectedPlanIndex,
                        onChanged: (value) {
                          setState(() {
                            _selectedPlanIndex = value!;
                          });
                        },
                        activeColor: AppColors.primaryGold,
                      ),
                      const SizedBox(width: AppSpacing.sm),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              plan['duration'] as String,
                              style: Theme.of(context)
                                  .textTheme
                                  .labelLarge
                                  ?.copyWith(
                                    color: isSelected
                                        ? AppColors.primaryGold
                                        : null,
                                  ),
                            ),
                            Text(
                              plan['pricePerMonth'] as String,
                              style: Theme.of(context)
                                  .textTheme
                                  .bodySmall
                                  ?.copyWith(
                                    color: AppColors.textSecondary,
                                  ),
                            ),
                          ],
                        ),
                      ),
                      Text(
                        plan['price'] as String,
                        style: Theme.of(context)
                            .textTheme
                            .headlineSmall
                            ?.copyWith(
                              color: isSelected ? AppColors.primaryGold : null,
                            ),
                      ),
                    ],
                  ),
                  if (plan['saving'] != null) ...[
                    const SizedBox(height: AppSpacing.sm),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: AppSpacing.sm,
                        vertical: AppSpacing.xs,
                      ),
                      decoration: BoxDecoration(
                        color: AppColors.successGreen.withOpacity(0.1),
                        borderRadius:
                            BorderRadius.circular(AppBorderRadius.small),
                      ),
                      child: Text(
                        plan['saving'] as String,
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                              color: AppColors.successGreen,
                              fontWeight: FontWeight.w600,
                            ),
                      ),
                    ),
                  ],
                ],
              ),
              if (isPopular)
                Positioned(
                  top: 0,
                  right: 0,
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: AppSpacing.sm,
                      vertical: AppSpacing.xs,
                    ),
                    decoration: BoxDecoration(
                      color: AppColors.primaryGold,
                      borderRadius:
                          BorderRadius.circular(AppBorderRadius.small),
                    ),
                    child: Text(
                      'Populaire',
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            color: Colors.white,
                            fontWeight: FontWeight.w600,
                          ),
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }

  void _subscribe() {
    final selectedPlan = _plans[_selectedPlanIndex];

    // TODO: Implement actual subscription logic with in-app purchases
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppBorderRadius.large),
          ),
          title: Row(
            children: [
              Icon(
                Icons.star,
                color: AppColors.primaryGold,
              ),
              const SizedBox(width: AppSpacing.sm),
              const Text('Abonnement activé'),
            ],
          ),
          content: Text(
            'Félicitations ! Vous avez souscrit au plan ${selectedPlan['duration']} de GoldWen Plus. Profitez de vos nouvelles fonctionnalités !',
          ),
          actions: [
            ElevatedButton(
              onPressed: () {
                Navigator.of(context).pop();
                context.go('/home');
              },
              child: const Text('Commencer'),
            ),
          ],
        );
      },
    );
  }
}
