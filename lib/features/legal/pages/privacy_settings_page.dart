import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/services/gdpr_service.dart';
import '../../../core/models/gdpr_consent.dart';

class PrivacySettingsPage extends StatefulWidget {
  const PrivacySettingsPage({super.key});

  @override
  State<PrivacySettingsPage> createState() => _PrivacySettingsPageState();
}

class _PrivacySettingsPageState extends State<PrivacySettingsPage> {
  bool _analyticsEnabled = true;
  bool _marketingEnabled = false;
  bool _functionalCookiesEnabled = true;
  int? _dataRetentionDays;

  @override
  void initState() {
    super.initState();
    _loadPrivacySettings();
  }

  Future<void> _loadPrivacySettings() async {
    final gdprService = Provider.of<GdprService>(context, listen: false);
    final success = await gdprService.loadPrivacySettings();
    
    if (success && gdprService.currentPrivacySettings != null) {
      setState(() {
        _analyticsEnabled = gdprService.currentPrivacySettings!.analytics;
        _marketingEnabled = gdprService.currentPrivacySettings!.marketing;
        _functionalCookiesEnabled = gdprService.currentPrivacySettings!.functionalCookies;
        _dataRetentionDays = gdprService.currentPrivacySettings!.dataRetention;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: BoxDecoration(
          gradient: AppColors.primaryGradient,
        ),
        child: SafeArea(
          child: Column(
            children: [
              // Header
              Padding(
                padding: const EdgeInsets.all(AppSpacing.lg),
                child: Row(
                  children: [
                    Container(
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: AppColors.cardOverlay.withOpacity(0.2),
                      ),
                      child: IconButton(
                        onPressed: () => Navigator.of(context).pop(),
                        icon: const Icon(
                          Icons.arrow_back,
                          color: AppColors.textLight,
                        ),
                      ),
                    ),
                    const SizedBox(width: AppSpacing.md),
                    Expanded(
                      child: Text(
                        'Paramètres de confidentialité',
                        style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                          color: AppColors.textLight,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ],
                ),
              ),

              // Content
              Expanded(
                child: Container(
                  decoration: BoxDecoration(
                    color: AppColors.backgroundWhite,
                    borderRadius: const BorderRadius.only(
                      topLeft: Radius.circular(AppBorderRadius.xLarge),
                      topRight: Radius.circular(AppBorderRadius.xLarge),
                    ),
                  ),
                  child: Consumer<GdprService>(
                    builder: (context, gdprService, child) {
                      return SingleChildScrollView(
                        padding: const EdgeInsets.all(AppSpacing.lg),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            // Introduction
                            Container(
                              padding: const EdgeInsets.all(AppSpacing.lg),
                              decoration: BoxDecoration(
                                gradient: LinearGradient(
                                  colors: [
                                    AppColors.primaryGold.withOpacity(0.1),
                                    AppColors.primaryGold.withOpacity(0.05),
                                  ],
                                ),
                                borderRadius: BorderRadius.circular(AppBorderRadius.large),
                                border: Border.all(
                                  color: AppColors.primaryGold.withOpacity(0.3),
                                ),
                              ),
                              child: Row(
                                children: [
                                  Icon(
                                    Icons.privacy_tip,
                                    color: AppColors.primaryGold,
                                    size: 32,
                                  ),
                                  const SizedBox(width: AppSpacing.md),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          'Contrôlez vos données',
                                          style: Theme.of(context).textTheme.titleMedium?.copyWith(
                                            fontWeight: FontWeight.bold,
                                            color: AppColors.primaryGold,
                                          ),
                                        ),
                                        Text(
                                          'Vous pouvez modifier vos préférences à tout moment. Ces paramètres affectent la façon dont nous utilisons vos données.',
                                          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                                            color: AppColors.textSecondary,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                            ),

                            const SizedBox(height: AppSpacing.xl),

                            // Privacy Settings
                            _buildSectionTitle('Gestion des données'),
                            const SizedBox(height: AppSpacing.lg),

                            _buildPrivacyToggle(
                              title: 'Analyses et améliorations',
                              description: 'Autoriser l\'analyse de votre utilisation pour améliorer l\'application',
                              value: _analyticsEnabled,
                              onChanged: (value) {
                                setState(() {
                                  _analyticsEnabled = value;
                                });
                              },
                              icon: Icons.analytics,
                            ),

                            const SizedBox(height: AppSpacing.md),

                            _buildPrivacyToggle(
                              title: 'Communications marketing',
                              description: 'Recevoir des informations sur les nouveautés et promotions',
                              value: _marketingEnabled,
                              onChanged: (value) {
                                setState(() {
                                  _marketingEnabled = value;
                                });
                              },
                              icon: Icons.email,
                            ),

                            const SizedBox(height: AppSpacing.md),

                            _buildPrivacyToggle(
                              title: 'Cookies fonctionnels',
                              description: 'Cookies nécessaires au bon fonctionnement de l\'application',
                              value: _functionalCookiesEnabled,
                              onChanged: null, // Cannot be disabled
                              icon: Icons.cookie,
                              isRequired: true,
                            ),

                            const SizedBox(height: AppSpacing.xl),

                            // Data Management Section
                            _buildSectionTitle('Gestion de votre compte'),
                            const SizedBox(height: AppSpacing.lg),

                            _buildActionCard(
                              title: 'Exporter mes données',
                              description: 'Télécharger une copie complète de vos données',
                              icon: Icons.download,
                              onTap: _showDataExportDialog,
                            ),

                            const SizedBox(height: AppSpacing.md),

                            _buildActionCard(
                              title: 'Supprimer mon compte',
                              description: 'Supprimer définitivement votre compte et toutes vos données',
                              icon: Icons.delete_forever,
                              onTap: _showAccountDeletionDialog,
                              isDestructive: true,
                            ),

                            const SizedBox(height: AppSpacing.xl),

                            // Save button
                            SizedBox(
                              width: double.infinity,
                              child: ElevatedButton(
                                onPressed: gdprService.isLoading ? null : _savePrivacySettings,
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: AppColors.primaryGold,
                                  foregroundColor: AppColors.textLight,
                                  padding: const EdgeInsets.symmetric(vertical: AppSpacing.md),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(AppBorderRadius.medium),
                                  ),
                                ),
                                child: gdprService.isLoading
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
                                        'Enregistrer les modifications',
                                        style: TextStyle(
                                          fontWeight: FontWeight.bold,
                                          fontSize: 16,
                                        ),
                                      ),
                              ),
                            ),

                            const SizedBox(height: AppSpacing.xl),
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
      ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Text(
      title,
      style: Theme.of(context).textTheme.titleLarge?.copyWith(
        fontWeight: FontWeight.bold,
        color: AppColors.textDark,
      ),
    );
  }

  Widget _buildPrivacyToggle({
    required String title,
    required String description,
    required bool value,
    required ValueChanged<bool>? onChanged,
    required IconData icon,
    bool isRequired = false,
  }) {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.lg),
      decoration: BoxDecoration(
        color: AppColors.backgroundWhite,
        borderRadius: BorderRadius.circular(AppBorderRadius.large),
        border: Border.all(
          color: isRequired 
              ? AppColors.primaryGold.withOpacity(0.3)
              : AppColors.borderColor,
        ),
        boxShadow: [
          BoxShadow(
            color: AppColors.shadowColor.withOpacity(0.1),
            blurRadius: 8,
            offset: const Offset(0, 4),
          ),
        ],
      ),
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
              icon,
              color: AppColors.primaryGold,
            ),
          ),
          const SizedBox(width: AppSpacing.md),
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
                          color: AppColors.primaryGold,
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
          const SizedBox(width: AppSpacing.md),
          Switch(
            value: value,
            onChanged: onChanged,
            activeColor: AppColors.primaryGold,
          ),
        ],
      ),
    );
  }

  Widget _buildActionCard({
    required String title,
    required String description,
    required IconData icon,
    required VoidCallback onTap,
    bool isDestructive = false,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(AppSpacing.lg),
        decoration: BoxDecoration(
          color: AppColors.backgroundWhite,
          borderRadius: BorderRadius.circular(AppBorderRadius.large),
          border: Border.all(
            color: isDestructive 
                ? AppColors.errorRed.withOpacity(0.3)
                : AppColors.borderColor,
          ),
          boxShadow: [
            BoxShadow(
              color: AppColors.shadowColor.withOpacity(0.1),
              blurRadius: 8,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Row(
          children: [
            Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                color: isDestructive 
                    ? AppColors.errorRed.withOpacity(0.1)
                    : AppColors.primaryGold.withOpacity(0.1),
                borderRadius: BorderRadius.circular(AppBorderRadius.medium),
              ),
              child: Icon(
                icon,
                color: isDestructive ? AppColors.errorRed : AppColors.primaryGold,
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
                      color: isDestructive ? AppColors.errorRed : AppColors.textDark,
                    ),
                  ),
                  const SizedBox(height: AppSpacing.sm),
                  Text(
                    description,
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: isDestructive 
                          ? AppColors.errorRed.withOpacity(0.7)
                          : AppColors.textSecondary,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: AppSpacing.md),
            Icon(
              Icons.arrow_forward_ios,
              color: isDestructive ? AppColors.errorRed : AppColors.textSecondary,
              size: 16,
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _savePrivacySettings() async {
    final gdprService = Provider.of<GdprService>(context, listen: false);
    
    final success = await gdprService.updatePrivacySettings(
      analytics: _analyticsEnabled,
      marketing: _marketingEnabled,
      functionalCookies: _functionalCookiesEnabled,
      dataRetention: _dataRetentionDays,
    );

    if (mounted) {
      if (success) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text('Paramètres de confidentialité mis à jour avec succès'),
            backgroundColor: AppColors.successGreen,
            behavior: SnackBarBehavior.floating,
          ),
        );
      } else {
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

  void _showDataExportDialog() {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Row(
            children: [
              Icon(Icons.download, color: AppColors.primaryGold),
              const SizedBox(width: AppSpacing.sm),
              const Text('Exporter mes données'),
            ],
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Choisissez le format pour l\'export de vos données :',
              ),
              const SizedBox(height: AppSpacing.md),
              Row(
                children: [
                  Expanded(
                    child: ElevatedButton.icon(
                      onPressed: () {
                        Navigator.of(context).pop();
                        _exportUserData('json');
                      },
                      icon: const Icon(Icons.code),
                      label: const Text('JSON'),
                    ),
                  ),
                  const SizedBox(width: AppSpacing.sm),
                  Expanded(
                    child: ElevatedButton.icon(
                      onPressed: () {
                        Navigator.of(context).pop();
                        _exportUserData('pdf');
                      },
                      icon: const Icon(Icons.picture_as_pdf),
                      label: const Text('PDF'),
                    ),
                  ),
                ],
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Annuler'),
            ),
          ],
        );
      },
    );
  }

  Future<void> _exportUserData(String format) async {
    final gdprService = Provider.of<GdprService>(context, listen: false);

    try {
      // Show loading
      _showLoadingDialog('Export en cours...');
      
      final data = await gdprService.exportUserData(format: format);
      
      if (mounted) {
        Navigator.of(context).pop(); // Close loading dialog
        
        // Show success message
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Données exportées avec succès au format $format'),
            backgroundColor: AppColors.successGreen,
            behavior: SnackBarBehavior.floating,
          ),
        );
        
        // Here you would typically save the file or open a share dialog
        // For now, we'll just show the success message
      }
    } catch (e) {
      if (mounted) {
        Navigator.of(context).pop(); // Close loading dialog
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Erreur lors de l\'export: $e'),
            backgroundColor: AppColors.errorRed,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    }
  }

  void _showAccountDeletionDialog() {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Row(
            children: [
              Icon(Icons.delete_forever, color: AppColors.errorRed),
              const SizedBox(width: AppSpacing.sm),
              const Text('Supprimer mon compte'),
            ],
          ),
          content: const Text(
            'ATTENTION : Cette action est irréversible.\n\n'
            'Toutes vos données seront définitivement supprimées :\n'
            '• Votre profil et photos\n'
            '• Vos conversations\n'
            '• Vos matches\n'
            '• Votre historique\n\n'
            'Êtes-vous sûr de vouloir continuer ?',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Annuler'),
            ),
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
                _deleteAccount();
              },
              child: Text(
                'Supprimer définitivement',
                style: TextStyle(color: AppColors.errorRed),
              ),
            ),
          ],
        );
      },
    );
  }

  Future<void> _deleteAccount() async {
    final gdprService = Provider.of<GdprService>(context, listen: false);

    _showLoadingDialog('Suppression en cours...');

    final success = await gdprService.deleteAccountWithGdprCompliance();

    if (mounted) {
      Navigator.of(context).pop(); // Close loading dialog
      
      if (success) {
        // Navigate to welcome screen
        Navigator.of(context).pushNamedAndRemoveUntil(
          '/welcome',
          (route) => false,
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(gdprService.error ?? 'Erreur lors de la suppression'),
            backgroundColor: AppColors.errorRed,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    }
  }

  void _showLoadingDialog(String message) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return AlertDialog(
          content: Row(
            children: [
              const CircularProgressIndicator(),
              const SizedBox(width: AppSpacing.lg),
              Expanded(child: Text(message)),
            ],
          ),
        );
      },
    );
  }
}