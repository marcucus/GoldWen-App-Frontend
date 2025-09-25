import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/services/gdpr_service.dart';

class GdprConsentModal extends StatefulWidget {
  final VoidCallback? onConsentGiven;
  final bool canDismiss;

  const GdprConsentModal({
    super.key,
    this.onConsentGiven,
    this.canDismiss = false,
  });

  @override
  State<GdprConsentModal> createState() => _GdprConsentModalState();
}

class _GdprConsentModalState extends State<GdprConsentModal> {
  bool _dataProcessingConsent = false;
  bool _marketingConsent = false;
  bool _analyticsConsent = false;
  bool _isSubmitting = false;

  @override
  Widget build(BuildContext context) {
    return WillPopScope(
      onWillPop: () async => widget.canDismiss,
      child: Dialog(
        backgroundColor: Colors.transparent,
        child: Container(
          decoration: BoxDecoration(
            color: AppColors.backgroundWhite,
            borderRadius: BorderRadius.circular(AppBorderRadius.large),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.3),
                blurRadius: 20,
                offset: const Offset(0, 10),
              ),
            ],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Header
              Container(
                padding: const EdgeInsets.all(AppSpacing.lg),
                decoration: BoxDecoration(
                  gradient: AppColors.primaryGradient,
                  borderRadius: const BorderRadius.only(
                    topLeft: Radius.circular(AppBorderRadius.large),
                    topRight: Radius.circular(AppBorderRadius.large),
                  ),
                ),
                child: Row(
                  children: [
                    Icon(
                      Icons.privacy_tip,
                      color: AppColors.textLight,
                      size: 32,
                    ),
                    const SizedBox(width: AppSpacing.md),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Protection de vos données',
                            style: Theme.of(context).textTheme.titleLarge?.copyWith(
                              color: AppColors.textLight,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          Text(
                            'Conformité RGPD',
                            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                              color: AppColors.textLight.withOpacity(0.8),
                            ),
                          ),
                        ],
                      ),
                    ),
                    if (widget.canDismiss)
                      IconButton(
                        onPressed: () => Navigator.of(context).pop(),
                        icon: Icon(
                          Icons.close,
                          color: AppColors.textLight,
                        ),
                      ),
                  ],
                ),
              ),

              // Content
              Flexible(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.all(AppSpacing.lg),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Nous respectons votre vie privée et nous nous engageons à protéger vos données personnelles conformément au RGPD.',
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          color: AppColors.textSecondary,
                        ),
                      ),

                      const SizedBox(height: AppSpacing.xl),

                      // Required consent
                      _buildConsentSection(
                        title: 'Traitement des données (Obligatoire)',
                        description: 'Autorisation pour traiter vos données personnelles nécessaires au fonctionnement de l\'application (profil, matching, messagerie).',
                        value: _dataProcessingConsent,
                        onChanged: (value) {
                          setState(() {
                            _dataProcessingConsent = value ?? false;
                          });
                        },
                        isRequired: true,
                      ),

                      const SizedBox(height: AppSpacing.lg),

                      // Optional consents
                      _buildConsentSection(
                        title: 'Marketing et communications (Optionnel)',
                        description: 'Autorisation pour vous envoyer des informations promotionnelles, des conseils et des nouveautés.',
                        value: _marketingConsent,
                        onChanged: (value) {
                          setState(() {
                            _marketingConsent = value ?? false;
                          });
                        },
                        isRequired: false,
                      ),

                      const SizedBox(height: AppSpacing.lg),

                      _buildConsentSection(
                        title: 'Analyses et amélioration (Optionnel)',
                        description: 'Autorisation pour analyser votre utilisation de l\'app afin d\'améliorer nos services.',
                        value: _analyticsConsent,
                        onChanged: (value) {
                          setState(() {
                            _analyticsConsent = value ?? false;
                          });
                        },
                        isRequired: false,
                      ),

                      const SizedBox(height: AppSpacing.xl),

                      // Privacy policy link
                      Container(
                        padding: const EdgeInsets.all(AppSpacing.md),
                        decoration: BoxDecoration(
                          color: AppColors.primaryGold.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(AppBorderRadius.medium),
                          border: Border.all(
                            color: AppColors.primaryGold.withOpacity(0.3),
                          ),
                        ),
                        child: Row(
                          children: [
                            Icon(
                              Icons.info_outline,
                              color: AppColors.primaryGold,
                            ),
                            const SizedBox(width: AppSpacing.sm),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    'Plus d\'informations',
                                    style: TextStyle(
                                      fontWeight: FontWeight.w600,
                                      color: AppColors.primaryGold,
                                    ),
                                  ),
                                  GestureDetector(
                                    onTap: () {
                                      Navigator.of(context).pop();
                                      context.go('/privacy');
                                    },
                                    child: Text(
                                      'Consultez notre politique de confidentialité complète',
                                      style: TextStyle(
                                        color: AppColors.primaryGold,
                                        decoration: TextDecoration.underline,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),

              // Action buttons
              Container(
                padding: const EdgeInsets.all(AppSpacing.lg),
                child: Column(
                  children: [
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed: _dataProcessingConsent && !_isSubmitting
                            ? _submitConsent
                            : null,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.primaryGold,
                          foregroundColor: AppColors.textLight,
                          padding: const EdgeInsets.symmetric(vertical: AppSpacing.md),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(AppBorderRadius.medium),
                          ),
                        ),
                        child: _isSubmitting
                            ? const SizedBox(
                                height: 20,
                                width: 20,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  valueColor: AlwaysStoppedAnimation<Color>(
                                    AppColors.textLight,
                                  ),
                                ),
                              )
                            : const Text(
                                'Accepter et continuer',
                                style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 16,
                                ),
                              ),
                      ),
                    ),
                    
                    if (!_dataProcessingConsent)
                      Padding(
                        padding: const EdgeInsets.only(top: AppSpacing.sm),
                        child: Text(
                          'Le consentement pour le traitement des données est requis pour utiliser l\'application.',
                          style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            color: AppColors.errorRed,
                          ),
                          textAlign: TextAlign.center,
                        ),
                      ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildConsentSection({
    required String title,
    required String description,
    required bool value,
    required ValueChanged<bool?> onChanged,
    required bool isRequired,
  }) {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        border: Border.all(
          color: AppColors.borderColor,
        ),
        borderRadius: BorderRadius.circular(AppBorderRadius.medium),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Checkbox(
                value: value,
                onChanged: onChanged,
                activeColor: AppColors.primaryGold,
              ),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            title,
                            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                        if (isRequired)
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: AppSpacing.sm,
                              vertical: 2,
                            ),
                            decoration: BoxDecoration(
                              color: AppColors.errorRed,
                              borderRadius: BorderRadius.circular(AppBorderRadius.small),
                            ),
                            child: Text(
                              'REQUIS',
                              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                color: AppColors.textLight,
                                fontWeight: FontWeight.bold,
                                fontSize: 10,
                              ),
                            ),
                          ),
                      ],
                    ),
                    const SizedBox(height: AppSpacing.sm),
                    Text(
                      description,
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: AppColors.textSecondary,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Future<void> _submitConsent() async {
    setState(() {
      _isSubmitting = true;
    });

    final gdprService = Provider.of<GdprService>(context, listen: false);

    final success = await gdprService.submitConsent(
      dataProcessing: _dataProcessingConsent,
      marketing: _marketingConsent,
      analytics: _analyticsConsent,
    );

    setState(() {
      _isSubmitting = false;
    });

    if (success) {
      if (mounted) {
        Navigator.of(context).pop();
        widget.onConsentGiven?.call();
        
        // Show success message
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text('Vos préférences de confidentialité ont été enregistrées.'),
            backgroundColor: AppColors.successGreen,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } else {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(gdprService.error ?? 'Une erreur est survenue'),
            backgroundColor: AppColors.errorRed,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    }
  }
}