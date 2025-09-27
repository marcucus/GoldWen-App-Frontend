import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/widgets/animated_widgets.dart';
import '../../../core/widgets/modern_cards.dart';
import '../../../core/models/models.dart';
import '../providers/subscription_provider.dart';
import '../../legal/pages/terms_page.dart';
import '../../legal/pages/privacy_page.dart';

class SubscriptionPage extends StatefulWidget {
  const SubscriptionPage({super.key});

  @override
  State<SubscriptionPage> createState() => _SubscriptionPageState();
}

class _SubscriptionPageState extends State<SubscriptionPage>
    with TickerProviderStateMixin {
  int _selectedPlanIndex = 1; // Default to quarterly plan
  bool _isLoading = false;

  late AnimationController _backgroundController;
  late AnimationController _contentController;
  late Animation<double> _backgroundAnimation;
  late Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();
    _initializeAnimations();
    _startAnimations();
    _loadSubscriptionData();
  }

  void _loadSubscriptionData() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final subscriptionProvider = Provider.of<SubscriptionProvider>(context, listen: false);
      subscriptionProvider.loadSubscriptionPlans();
      subscriptionProvider.loadCurrentSubscription();
    });
  }

  final List<Map<String, dynamic>> _features = [
    {
      'icon': Icons.favorite,
      'title': '3 sélections par jour',
      'description': 'Choisissez jusqu\'à 3 profils dans votre sélection quotidienne',
    },
    {
      'icon': Icons.chat_bubble,
      'title': 'Chat illimité',
      'description': 'Échangez sans limite avec vos matches',
    },
    {
      'icon': Icons.visibility,
      'title': 'Voir qui vous a sélectionné',
      'description': 'Découvrez qui s\'intéresse à vous en priorité',
    },
    {
      'icon': Icons.star,
      'title': 'Profil prioritaire',
      'description': 'Votre profil apparaît en priorité dans les sélections',
    },
  ];

  void _initializeAnimations() {
    _backgroundController = AnimationController(
      duration: AppAnimations.verySlow,
      vsync: this,
    );
    _contentController = AnimationController(
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

    _scaleAnimation = Tween<double>(
      begin: 0.8,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _contentController,
      curve: AppAnimations.elasticOut,
    ));
  }

  void _startAnimations() {
    _backgroundController.forward();
    Future.delayed(const Duration(milliseconds: 300), () {
      _contentController.forward();
    });
  }

  @override
  void dispose() {
    _backgroundController.dispose();
    _contentController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<SubscriptionProvider>(
      builder: (context, subscriptionProvider, child) {
        return Scaffold(
          body: AnimatedBuilder(
            animation: _backgroundAnimation,
            builder: (context, child) {
              return Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [
                      AppColors.primaryGoldDark,
                      AppColors.primaryGold,
                      AppColors.primaryGoldLight
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
                        child: _buildAnimatedContent(subscriptionProvider),
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
        );
      },
    );
  }

  Widget _buildAnimatedHeader() {
    return FadeInAnimation(
      delay: const Duration(milliseconds: 200),
      child: _buildHeader(),
    );
  }

  Widget _buildHeader() {
    return Container(
      margin: const EdgeInsets.all(AppSpacing.lg),
      child: GlassCard(
        borderRadius: AppBorderRadius.xLarge,
        backgroundColor: Colors.white.withOpacity(0.15),
        padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.lg,
          vertical: AppSpacing.md,
        ),
        child: Row(
          children: [
            AnimatedPressable(
              onPressed: () => context.pop(),
              child: Container(
                padding: const EdgeInsets.all(AppSpacing.sm),
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: Colors.white.withOpacity(0.3),
                ),
                child: const Icon(
                  Icons.arrow_back,
                  color: Colors.white,
                  size: 24,
                ),
              ),
            ),
            Expanded(
              child: Center(
                child: Column(
                  children: [
                    Text(
                      'GoldWen Plus',
                      style:
                          Theme.of(context).textTheme.headlineSmall?.copyWith(
                                color: Colors.white,
                                fontWeight: FontWeight.bold,
                              ),
                    ),
                    Text(
                      'Débloquez votre potentiel',
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                            color: Colors.white.withOpacity(0.9),
                          ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(width: 48), // Balance the back button
          ],
        ),
      ),
    );
  }

  Widget _buildAnimatedContent(SubscriptionProvider subscriptionProvider) {
    if (subscriptionProvider.isLoading) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            CircularProgressIndicator(
              valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
            ),
            SizedBox(height: AppSpacing.lg),
            Text(
              'Chargement des plans...',
              style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                color: Colors.white,
              ),
            ),
          ],
        ),
      );
    }

    if (subscriptionProvider.error != null) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.error_outline,
              color: Colors.white,
              size: 48,
            ),
            SizedBox(height: AppSpacing.lg),
            Text(
              'Erreur lors du chargement',
              style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                color: Colors.white,
                fontWeight: FontWeight.bold,
              ),
            ),
            SizedBox(height: AppSpacing.sm),
            Text(
              subscriptionProvider.error!,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: Colors.white.withOpacity(0.8),
              ),
              textAlign: TextAlign.center,
            ),
            SizedBox(height: AppSpacing.xl),
            ElevatedButton(
              onPressed: () {
                subscriptionProvider.clearError();
                _loadSubscriptionData();
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.white,
                foregroundColor: AppColors.primaryGold,
              ),
              child: Text('Réessayer'),
            ),
          ],
        ),
      );
    }

    return AnimatedBuilder(
      animation: _scaleAnimation,
      builder: (context, child) {
        return Transform.scale(
          scale: _scaleAnimation.value,
          child: SingleChildScrollView(
            physics: const BouncingScrollPhysics(),
            padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md),
            child: Column(
              children: [
                // Premium Features Section
                _buildFeaturesSection(),

                const SizedBox(height: AppSpacing.xl),

                // Pricing Plans
                _buildPricingSection(subscriptionProvider),

                const SizedBox(height: AppSpacing.xl),

                // Subscribe Button
                _buildSubscribeButton(subscriptionProvider),

                const SizedBox(height: AppSpacing.lg),

                // Legal Links
                _buildLegalLinks(),

                const SizedBox(height: AppSpacing.xxl),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildFeaturesSection() {
    return SlideInAnimation(
      delay: const Duration(milliseconds: 400),
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(AppSpacing.sm),
            child: Text(
              'Fonctionnalités Premium',
              style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                  ),
              textAlign: TextAlign.center,
            ),
          ),
          const SizedBox(height: AppSpacing.md),
          StaggeredList(
            itemDelay: const Duration(milliseconds: 100),
            children: _features.map((feature) {
              return _buildFeatureCard(
                icon: feature['icon'],
                title: feature['title'],
                description: feature['description'],
              );
            }).toList(),
          ),
        ],
      ),
    );
  }

  Widget _buildFeatureCard({
    required IconData icon,
    required String title,
    required String description,
  }) {
    return GlassCard(
      backgroundColor: Colors.white.withOpacity(0.1),
      borderColor: Colors.white.withOpacity(0.3),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(AppSpacing.md),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  Colors.white.withOpacity(0.3),
                  Colors.white.withOpacity(0.1),
                ],
              ),
              borderRadius: BorderRadius.circular(AppBorderRadius.medium),
            ),
            child: Icon(
              icon,
              color: Colors.white,
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
                        color: Colors.white,
                        fontWeight: FontWeight.w600,
                      ),
                ),
                const SizedBox(height: 4),
                Text(
                  description,
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: Colors.white.withOpacity(0.8),
                      ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPricingSection(SubscriptionProvider subscriptionProvider) {
    final plans = subscriptionProvider.activePlans;
    
    if (plans.isEmpty) {
      return SlideInAnimation(
        delay: const Duration(milliseconds: 600),
        child: Column(
          children: [
            Text(
              'Plans d\'abonnement',
              style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                  ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: AppSpacing.lg),
            Container(
              padding: const EdgeInsets.all(AppSpacing.xl),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.1),
                borderRadius: BorderRadius.circular(AppBorderRadius.large),
                border: Border.all(
                  color: Colors.white.withOpacity(0.3),
                ),
              ),
              child: Text(
                'Aucun plan disponible pour le moment',
                style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                  color: Colors.white.withOpacity(0.8),
                ),
                textAlign: TextAlign.center,
              ),
            ),
          ],
        ),
      );
    }

    // Auto-select the most popular plan or first available
    if (_selectedPlanIndex >= plans.length) {
      _selectedPlanIndex = 0;
      for (int i = 0; i < plans.length; i++) {
        if (plans[i].metadata['popular'] == true) {
          _selectedPlanIndex = i;
          break;
        }
      }
    }

    return SlideInAnimation(
      delay: const Duration(milliseconds: 600),
      child: Column(
        children: [
          Text(
            'Choisissez votre plan',
            style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: AppSpacing.lg),
          ...List.generate(plans.length, (index) {
            return FadeInAnimation(
              delay: Duration(milliseconds: 700 + (index * 100)),
              child: _buildPlanCard(index, plans[index]),
            );
          }),
        ],
      ),
    );
  }

  Widget _buildPlanCard(int index, SubscriptionPlan plan) {
    final isSelected = _selectedPlanIndex == index;
    final isPopular = plan.metadata['popular'] == true;
    
    // Calculate monthly price for display
    double monthlyPrice = plan.price;
    if (plan.interval == 'month' && plan.intervalCount > 1) {
      monthlyPrice = plan.price / plan.intervalCount;
    } else if (plan.interval == 'year') {
      monthlyPrice = plan.price / (12 * plan.intervalCount);
    }
    
    String durationText = plan.name;
    String priceText = '${plan.price.toStringAsFixed(2)} ${plan.currency}';
    String monthlyPriceText = '${monthlyPrice.toStringAsFixed(2)} ${plan.currency}/mois';
    
    // Calculate savings percentage
    String? savingsText;
    if (plan.interval != 'month' || plan.intervalCount > 1) {
      double regularMonthlyPrice = 19.99; // Base monthly price
      double savingsPercent = ((regularMonthlyPrice - monthlyPrice) / regularMonthlyPrice * 100);
      if (savingsPercent > 0) {
        savingsText = 'Économisez ${savingsPercent.round()}%';
      }
    }

    return AnimatedPressable(
      onPressed: () {
        setState(() {
          _selectedPlanIndex = index;
        });
      },
      child: Container(
        margin: const EdgeInsets.only(bottom: AppSpacing.md),
        child: Stack(
          children: [
            Container(
              padding: const EdgeInsets.all(AppSpacing.lg),
              decoration: BoxDecoration(
                gradient: isSelected
                    ? LinearGradient(
                        colors: [
                          Colors.white.withOpacity(0.25),
                          Colors.white.withOpacity(0.15),
                        ],
                      )
                    : null,
                color: isSelected ? null : Colors.white.withOpacity(0.1),
                borderRadius: BorderRadius.circular(AppBorderRadius.large),
                border: Border.all(
                  color:
                      isSelected ? Colors.white : Colors.white.withOpacity(0.3),
                  width: isSelected ? 2 : 1,
                ),
                boxShadow: isSelected ? AppShadows.medium() : null,
              ),
              child: Row(
                children: [
                  // Duration and Popular badge
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Text(
                              durationText,
                              style: Theme.of(context)
                                  .textTheme
                                  .titleLarge
                                  ?.copyWith(
                                    color: Colors.white,
                                    fontWeight: FontWeight.bold,
                                  ),
                            ),
                            if (isPopular) ...[
                              const SizedBox(width: AppSpacing.sm),
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: AppSpacing.sm,
                                  vertical: 2,
                                ),
                                decoration: BoxDecoration(
                                  color: Colors.white,
                                  borderRadius: BorderRadius.circular(
                                      AppBorderRadius.small),
                                ),
                                child: Text(
                                  'POPULAIRE',
                                  style: Theme.of(context)
                                      .textTheme
                                      .bodySmall
                                      ?.copyWith(
                                        color: AppColors.primaryGold,
                                        fontWeight: FontWeight.bold,
                                        fontSize: 10,
                                      ),
                                ),
                              ),
                            ],
                          ],
                        ),
                        const SizedBox(height: 4),
                        Text(
                          monthlyPriceText,
                          style:
                              Theme.of(context).textTheme.bodyMedium?.copyWith(
                                    color: Colors.white.withOpacity(0.8),
                                  ),
                        ),
                        if (savingsText != null) ...[
                          const SizedBox(height: 4),
                          Text(
                            savingsText,
                            style:
                                Theme.of(context).textTheme.bodySmall?.copyWith(
                                      color: AppColors.successGreen,
                                      fontWeight: FontWeight.w600,
                                    ),
                          ),
                        ],
                      ],
                    ),
                  ),

                  // Price
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Text(
                        priceText,
                        style:
                            Theme.of(context).textTheme.headlineSmall?.copyWith(
                                  color: Colors.white,
                                  fontWeight: FontWeight.bold,
                                ),
                      ),
                      const SizedBox(height: 4),
                      Container(
                        width: 24,
                        height: 24,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          border: Border.all(
                            color: Colors.white,
                            width: 2,
                          ),
                          color: isSelected ? Colors.white : Colors.transparent,
                        ),
                        child: isSelected
                            ? const Icon(
                                Icons.check,
                                size: 16,
                                color: AppColors.primaryGold,
                              )
                            : null,
                      ),
                    ],
                  ),
                ],
              ),
            ),

            // Popular badge ribbon
            if (isPopular)
              Positioned(
                top: 0,
                right: 0,
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: AppSpacing.md,
                    vertical: 4,
                  ),
                  decoration: const BoxDecoration(
                    gradient: LinearGradient(
                      colors: [Colors.white, Colors.white],
                    ),
                    borderRadius: BorderRadius.only(
                      topRight: Radius.circular(AppBorderRadius.large),
                      bottomLeft: Radius.circular(AppBorderRadius.medium),
                    ),
                  ),
                  child: Text(
                    '🔥 Meilleur choix',
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: AppColors.primaryGold,
                          fontWeight: FontWeight.bold,
                        ),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildSubscribeButton(SubscriptionProvider subscriptionProvider) {
    final plans = subscriptionProvider.activePlans;
    final isLoading = _isLoading || subscriptionProvider.isLoading;
    
    return SlideInAnimation(
      delay: const Duration(milliseconds: 900),
      child: PremiumButton(
        text: isLoading ? 'Traitement...' : 'S\'abonner maintenant',
        isLoading: isLoading,
        gradient: LinearGradient(
          colors: [
            Colors.white,
            Colors.white.withOpacity(0.9),
          ],
        ),
        textColor: AppColors.primaryGold,
        onPressed: (isLoading || plans.isEmpty) ? null : () => _handleSubscription(subscriptionProvider),
      ),
    );
  }

  Widget _buildLegalLinks() {
    return FadeInAnimation(
      delay: const Duration(milliseconds: 1000),
      child: Column(
        children: [
          Text(
            'En vous abonnant, vous acceptez nos',
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: Colors.white.withOpacity(0.7),
                ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: AppSpacing.sm),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              GestureDetector(
                onTap: () => context.go('/terms'),
                child: Text(
                  'Conditions d\'utilisation',
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: Colors.white,
                        decoration: TextDecoration.underline,
                        fontWeight: FontWeight.w600,
                      ),
                ),
              ),
              Text(
                ' et ',
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: Colors.white.withOpacity(0.7),
                    ),
              ),
              GestureDetector(
                onTap: () => context.go('/privacy'),
                child: Text(
                  'Politique de confidentialité',
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: Colors.white,
                        decoration: TextDecoration.underline,
                        fontWeight: FontWeight.w600,
                      ),
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.lg),
          Text(
            'Annulez à tout moment depuis les paramètres de votre compte',
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: Colors.white.withOpacity(0.6),
                ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  void _handleSubscription(SubscriptionProvider subscriptionProvider) async {
    final plans = subscriptionProvider.activePlans;
    if (plans.isEmpty || _selectedPlanIndex >= plans.length) return;

    final selectedPlan = plans[_selectedPlanIndex];
    
    setState(() {
      _isLoading = true;
    });

    try {
      // TODO: Integrate RevenueCat for actual payment processing
      // For now, simulate subscription process
      await Future.delayed(const Duration(seconds: 2));

      // Simulate successful purchase
      final success = await subscriptionProvider.purchaseSubscription(
        planId: selectedPlan.id,
        platform: Theme.of(context).platform == TargetPlatform.iOS ? 'ios' : 'android',
        receiptData: 'simulated_receipt_data', // This would come from RevenueCat
      );

      if (mounted) {
        setState(() {
          _isLoading = false;
        });

        if (success) {
          _showSuccessDialog();
        } else {
          _showErrorDialog(subscriptionProvider.error ?? 'Une erreur est survenue lors de l\'abonnement');
        }
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
        _showErrorDialog('Une erreur est survenue lors de l\'abonnement: $e');
      }
    }
  }

  void _showSuccessDialog() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => Dialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppBorderRadius.xLarge),
        ),
        child: Container(
          padding: const EdgeInsets.all(AppSpacing.xl),
          decoration: BoxDecoration(
            gradient: AppColors.premiumGradient,
            borderRadius: BorderRadius.circular(AppBorderRadius.xLarge),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                padding: const EdgeInsets.all(AppSpacing.lg),
                decoration: const BoxDecoration(
                  shape: BoxShape.circle,
                  color: Colors.white,
                ),
                child: const Icon(
                  Icons.check,
                  color: AppColors.primaryGold,
                  size: 48,
                ),
              ),
              const SizedBox(height: AppSpacing.lg),
              Text(
                'Félicitations !',
                style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                    ),
              ),
              const SizedBox(height: AppSpacing.sm),
              Text(
                'Vous êtes maintenant membre GoldWen Plus\nVous pouvez désormais choisir jusqu\'à 3 profils par jour !',
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: Colors.white.withOpacity(0.9),
                    ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: AppSpacing.xl),
              PremiumButton(
                text: 'Commencer',
                gradient: LinearGradient(
                  colors: [
                    Colors.white,
                    Colors.white.withOpacity(0.9),
                  ],
                ),
                textColor: AppColors.primaryGold,
                onPressed: () {
                  Navigator.of(context).pop();
                  context.go('/home');
                },
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showErrorDialog(String message) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppBorderRadius.large),
        ),
        title: Row(
          children: [
            Icon(Icons.error_outline, color: AppColors.errorRed),
            SizedBox(width: AppSpacing.sm),
            Text('Erreur d\'abonnement'),
          ],
        ),
        content: Text(message),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: Text('OK'),
          ),
        ],
      ),
    );
  }
}
