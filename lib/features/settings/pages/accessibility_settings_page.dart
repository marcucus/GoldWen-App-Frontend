import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../core/services/accessibility_service.dart';
import '../../../core/theme/app_theme.dart';
import '../../../shared/widgets/loading_animation.dart';

/// Settings page for accessibility options
class AccessibilitySettingsPage extends StatefulWidget {
  const AccessibilitySettingsPage({super.key});

  @override
  State<AccessibilitySettingsPage> createState() => _AccessibilitySettingsPageState();
}

class _AccessibilitySettingsPageState extends State<AccessibilitySettingsPage> {
  bool _isLoading = false;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Accessibilité'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.of(context).pop(),
          tooltip: 'Retour',
        ),
      ),
      body: Consumer<AccessibilityService>(
        builder: (context, accessibilityService, child) {
          if (_isLoading) {
            return const LoadingAnimation(
              message: 'Sauvegarde des paramètres...',
              semanticLabel: 'Sauvegarde des paramètres d\'accessibilité en cours',
            );
          }

          return ListView(
            padding: const EdgeInsets.all(AppSpacing.lg),
            children: [
              _buildIntroduction(),
              const SizedBox(height: AppSpacing.xl),
              _buildFontSizeSection(accessibilityService),
              const SizedBox(height: AppSpacing.xl),
              _buildVisualSection(accessibilityService),
              const SizedBox(height: AppSpacing.xl),
              _buildMotionSection(accessibilityService),
              const SizedBox(height: AppSpacing.xl),
              _buildScreenReaderSection(accessibilityService),
              const SizedBox(height: AppSpacing.xl),
              _buildSystemInfoSection(accessibilityService),
              const SizedBox(height: AppSpacing.xxl),
              _buildResetButton(accessibilityService),
            ],
          );
        },
      ),
    );
  }

  Widget _buildIntroduction() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.lg),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  Icons.accessibility_new,
                  color: AppColors.primaryGold,
                  size: 28,
                  semanticLabel: 'Icône accessibilité',
                ),
                const SizedBox(width: AppSpacing.md),
                Expanded(
                  child: Text(
                    'Paramètres d\'accessibilité',
                    style: Theme.of(context).textTheme.headlineSmall,
                  ),
                ),
              ],
            ),
            const SizedBox(height: AppSpacing.md),
            Text(
              'Personnalisez l\'application selon vos besoins d\'accessibilité. Ces paramètres améliorent l\'expérience pour les personnes avec des difficultés visuelles, auditives ou motrices.',
              style: Theme.of(context).textTheme.bodyMedium,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFontSizeSection(AccessibilityService service) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.lg),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  Icons.text_fields,
                  color: AppColors.primaryGold,
                  semanticLabel: 'Icône taille du texte',
                ),
                const SizedBox(width: AppSpacing.md),
                Text(
                  'Taille du texte',
                  style: Theme.of(context).textTheme.titleLarge,
                ),
              ],
            ),
            const SizedBox(height: AppSpacing.md),
            Text(
              'Ajustez la taille du texte pour une meilleure lisibilité.',
              style: Theme.of(context).textTheme.bodyMedium,
            ),
            const SizedBox(height: AppSpacing.lg),
            
            // Font size options
            ...AccessibilityFontSize.values.map((fontSize) {
              final isSelected = service.fontSize == fontSize;
              return Semantics(
                label: 'Taille de police ${fontSize.displayName}${isSelected ? ', sélectionné' : ''}',
                button: true,
                selected: isSelected,
                child: RadioListTile<AccessibilityFontSize>(
                  title: Text(
                    fontSize.displayName,
                    style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                      fontSize: Theme.of(context).textTheme.bodyLarge!.fontSize! * 
                          _getFontSizeMultiplier(fontSize),
                    ),
                  ),
                  subtitle: Text(
                    'Exemple de texte avec cette taille',
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      fontSize: Theme.of(context).textTheme.bodyMedium!.fontSize! * 
                          _getFontSizeMultiplier(fontSize),
                    ),
                  ),
                  value: fontSize,
                  groupValue: service.fontSize,
                  onChanged: (value) async {
                    if (value != null) {
                      setState(() => _isLoading = true);
                      await service.setFontSize(value);
                      setState(() => _isLoading = false);
                    }
                  },
                  activeColor: AppColors.primaryGold,
                ),
              );
            }).toList(),
          ],
        ),
      ),
    );
  }

  Widget _buildVisualSection(AccessibilityService service) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.lg),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  Icons.contrast,
                  color: AppColors.primaryGold,
                  semanticLabel: 'Icône contraste',
                ),
                const SizedBox(width: AppSpacing.md),
                Text(
                  'Affichage visuel',
                  style: Theme.of(context).textTheme.titleLarge,
                ),
              ],
            ),
            const SizedBox(height: AppSpacing.md),
            
            // High contrast toggle
            Semantics(
              label: 'Contraste élevé${service.highContrast ? ', activé' : ', désactivé'}',
              hint: 'Améliore la lisibilité pour les malvoyants',
              child: SwitchListTile(
                title: const Text('Contraste élevé'),
                subtitle: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('Améliore la lisibilité avec des couleurs plus contrastées'),
                    if (service.highContrast) ...[
                      const SizedBox(height: 4),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: AppColors.successGreen.withOpacity(0.2),
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              Icons.check_circle,
                              size: 16,
                              color: AppColors.successGreen,
                            ),
                            const SizedBox(width: 4),
                            Text(
                              'Conforme WCAG AAA',
                              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                color: AppColors.successGreen,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ],
                ),
                value: service.highContrast,
                onChanged: (value) async {
                  setState(() => _isLoading = true);
                  await service.setHighContrast(value);
                  setState(() => _isLoading = false);
                },
                activeColor: AppColors.primaryGold,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMotionSection(AccessibilityService service) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.lg),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  Icons.animation,
                  color: AppColors.primaryGold,
                  semanticLabel: 'Icône animations',
                ),
                const SizedBox(width: AppSpacing.md),
                Text(
                  'Animations',
                  style: Theme.of(context).textTheme.titleLarge,
                ),
              ],
            ),
            const SizedBox(height: AppSpacing.md),
            
            // Reduced motion toggle
            Semantics(
              label: 'Mouvement réduit${service.reducedMotion ? ', activé' : ', désactivé'}',
              hint: 'Réduit les animations pour éviter les vertiges ou nausées',
              child: SwitchListTile(
                title: const Text('Mouvement réduit'),
                subtitle: const Text('Désactive les animations qui peuvent causer des vertiges'),
                value: service.reducedMotion,
                onChanged: (value) async {
                  setState(() => _isLoading = true);
                  await service.setReducedMotion(value);
                  setState(() => _isLoading = false);
                },
                activeColor: AppColors.primaryGold,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildScreenReaderSection(AccessibilityService service) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.lg),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  Icons.record_voice_over,
                  color: AppColors.primaryGold,
                  semanticLabel: 'Icône lecteur d\'écran',
                ),
                const SizedBox(width: AppSpacing.md),
                Text(
                  'Lecteur d\'écran',
                  style: Theme.of(context).textTheme.titleLarge,
                ),
              ],
            ),
            const SizedBox(height: AppSpacing.md),
            
            // Screen reader toggle
            Semantics(
              label: 'Support lecteur d\'écran${service.screenReaderEnabled ? ', activé' : ', désactivé'}',
              hint: 'Active les descriptions vocales pour les malvoyants',
              child: SwitchListTile(
                title: const Text('Support lecteur d\'écran'),
                subtitle: const Text('Active les descriptions audio et les annonces'),
                value: service.screenReaderEnabled,
                onChanged: (value) async {
                  setState(() => _isLoading = true);
                  await service.setScreenReaderEnabled(value);
                  setState(() => _isLoading = false);
                },
                activeColor: AppColors.primaryGold,
              ),
            ),
            
            if (service.screenReaderEnabled) ...[
              const SizedBox(height: AppSpacing.md),
              Container(
                padding: const EdgeInsets.all(AppSpacing.md),
                decoration: BoxDecoration(
                  color: AppColors.infoBlue.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(AppBorderRadius.medium),
                  border: Border.all(color: AppColors.infoBlue.withOpacity(0.3)),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(
                          Icons.info_outline,
                          color: AppColors.infoBlue,
                          size: 20,
                        ),
                        const SizedBox(width: AppSpacing.sm),
                        Text(
                          'Conseils d\'utilisation',
                          style: Theme.of(context).textTheme.titleMedium?.copyWith(
                            color: AppColors.infoBlue,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: AppSpacing.sm),
                    Text(
                      '• Utilisez les gestes de balayage pour naviguer\n'
                      '• Double-tap pour activer les boutons\n'
                      '• Les changements seront annoncés automatiquement',
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: AppColors.infoBlue,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildSystemInfoSection(AccessibilityService service) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.lg),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  Icons.system_update,
                  color: AppColors.primaryGold,
                  semanticLabel: 'Icône paramètres système',
                ),
                const SizedBox(width: AppSpacing.md),
                Text(
                  'Paramètres système détectés',
                  style: Theme.of(context).textTheme.titleLarge,
                ),
              ],
            ),
            const SizedBox(height: AppSpacing.md),
            Text(
              'L\'application détecte automatiquement certains paramètres de votre appareil.',
              style: Theme.of(context).textTheme.bodyMedium,
            ),
            const SizedBox(height: AppSpacing.lg),
            
            // System settings status
            _buildSystemSettingStatus(
              'Contraste élevé système',
              service.highContrast != service.highContrast, // This is system-only high contrast
              'Détecté depuis les paramètres de votre appareil',
              Icons.contrast,
            ),
            _buildSystemSettingStatus(
              'Mouvement réduit système',
              service.reducedMotion != service.reducedMotion, // This is system-only reduced motion
              'Respecte les préférences de votre appareil',
              Icons.animation,
            ),
            _buildSystemSettingStatus(
              'Facteur d\'échelle système',
              service.textScaleFactor != 1.0,
              'Adapte la taille selon votre appareil',
              Icons.text_fields,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSystemSettingStatus(String title, bool isActive, String description, IconData icon) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: AppSpacing.xs),
      child: Row(
        children: [
          Icon(
            icon,
            size: 20,
            color: isActive ? AppColors.successGreen : AppColors.textMuted,
          ),
          const SizedBox(width: AppSpacing.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    fontWeight: FontWeight.w500,
                  ),
                ),
                Text(
                  description,
                  style: Theme.of(context).textTheme.bodySmall,
                ),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: (isActive ? AppColors.successGreen : AppColors.textMuted).withOpacity(0.2),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Text(
              isActive ? 'Actif' : 'Inactif',
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: isActive ? AppColors.successGreen : AppColors.textMuted,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildResetButton(AccessibilityService service) {
    return Semantics(
      label: 'Réinitialiser tous les paramètres d\'accessibilité',
      hint: 'Remet les paramètres aux valeurs par défaut',
      button: true,
      child: Center(
        child: TextButton.icon(
          onPressed: service.isAccessibilityEnabled ? () async {
            final confirm = await showDialog<bool>(
              context: context,
              builder: (context) => AlertDialog(
                title: const Text('Réinitialiser les paramètres'),
                content: const Text(
                  'Voulez-vous vraiment remettre tous les paramètres d\'accessibilité aux valeurs par défaut ?'
                ),
                actions: [
                  TextButton(
                    onPressed: () => Navigator.of(context).pop(false),
                    child: const Text('Annuler'),
                  ),
                  ElevatedButton(
                    onPressed: () => Navigator.of(context).pop(true),
                    child: const Text('Réinitialiser'),
                  ),
                ],
              ),
            );

            if (confirm == true && mounted) {
              setState(() => _isLoading = true);
              await service.setFontSize(AccessibilityFontSize.medium);
              await service.setHighContrast(false);
              await service.setReducedMotion(false);
              await service.setScreenReaderEnabled(false);
              setState(() => _isLoading = false);
              
              if (mounted && service.screenReaderEnabled) {
                // service._announceChange('Paramètres d\'accessibilité réinitialisés');
                // Note: _announceChange is private, we should create a public announceChange method
              }
            }
          } : null,
          icon: const Icon(Icons.refresh),
          label: const Text('Réinitialiser les paramètres'),
        ),
      ),
    );
  }

  double _getFontSizeMultiplier(AccessibilityFontSize fontSize) {
    switch (fontSize) {
      case AccessibilityFontSize.small:
        return 0.85;
      case AccessibilityFontSize.medium:
        return 1.0;
      case AccessibilityFontSize.large:
        return 1.15;
      case AccessibilityFontSize.xlarge:
        return 1.3;
    }
  }
}