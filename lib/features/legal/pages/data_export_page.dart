import 'dart:io';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/services/gdpr_service.dart';
import '../../../core/models/gdpr_consent.dart';

class DataExportPage extends StatefulWidget {
  const DataExportPage({super.key});

  @override
  State<DataExportPage> createState() => _DataExportPageState();
}

class _DataExportPageState extends State<DataExportPage> {
  @override
  void initState() {
    super.initState();
    _checkExistingRequest();
  }

  Future<void> _checkExistingRequest() async {
    final gdprService = Provider.of<GdprService>(context, listen: false);
    final currentRequest = gdprService.currentExportRequest;
    
    if (currentRequest != null && !currentRequest.isExpired) {
      await gdprService.getExportStatus(currentRequest.requestId);
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
                        'Export de mes données',
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
                      final exportRequest = gdprService.currentExportRequest;

                      return SingleChildScrollView(
                        padding: const EdgeInsets.all(AppSpacing.lg),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            // Info banner
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
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Icon(
                                    Icons.info_outline,
                                    color: AppColors.primaryGold,
                                    size: 32,
                                  ),
                                  const SizedBox(width: AppSpacing.md),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          'Droit d\'accès RGPD',
                                          style: Theme.of(context).textTheme.titleMedium?.copyWith(
                                            fontWeight: FontWeight.bold,
                                            color: AppColors.primaryGold,
                                          ),
                                        ),
                                        const SizedBox(height: AppSpacing.sm),
                                        Text(
                                          'Conformément à l\'article 20 du RGPD, vous avez le droit d\'obtenir une copie de toutes vos données personnelles dans un format structuré et lisible.',
                                          style: Theme.of(context).textTheme.bodyMedium,
                                        ),
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                            ),

                            const SizedBox(height: AppSpacing.xl),

                            // What's included
                            _buildSectionTitle('Données incluses dans l\'export'),
                            const SizedBox(height: AppSpacing.md),
                            _buildIncludedDataList(),

                            const SizedBox(height: AppSpacing.xl),

                            // Current request status or request button
                            if (exportRequest != null && !exportRequest.isExpired)
                              _buildExportStatusCard(exportRequest, gdprService)
                            else
                              _buildRequestExportButton(gdprService),

                            const SizedBox(height: AppSpacing.lg),

                            // Additional info
                            Container(
                              padding: const EdgeInsets.all(AppSpacing.md),
                              decoration: BoxDecoration(
                                color: AppColors.backgroundGrey,
                                borderRadius: BorderRadius.circular(AppBorderRadius.medium),
                              ),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    children: [
                                      Icon(
                                        Icons.schedule,
                                        size: 20,
                                        color: AppColors.textSecondary,
                                      ),
                                      const SizedBox(width: AppSpacing.sm),
                                      Text(
                                        'Temps de traitement',
                                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: AppSpacing.sm),
                                  Text(
                                    'La préparation de vos données peut prendre jusqu\'à 24 heures. Vous recevrez un email avec un lien de téléchargement.',
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
      style: Theme.of(context).textTheme.titleMedium?.copyWith(
        fontWeight: FontWeight.bold,
        color: AppColors.primaryGold,
      ),
    );
  }

  Widget _buildIncludedDataList() {
    final items = [
      {'icon': Icons.person, 'text': 'Informations de profil (nom, email, etc.)'},
      {'icon': Icons.photo, 'text': 'Photos et média uploadés'},
      {'icon': Icons.psychology, 'text': 'Réponses au questionnaire de personnalité'},
      {'icon': Icons.chat, 'text': 'Historique de conversations'},
      {'icon': Icons.favorite, 'text': 'Matches et préférences'},
      {'icon': Icons.settings, 'text': 'Paramètres et consentements'},
      {'icon': Icons.history, 'text': 'Historique d\'activité'},
    ];

    return Container(
      padding: const EdgeInsets.all(AppSpacing.lg),
      decoration: BoxDecoration(
        color: AppColors.backgroundGrey,
        borderRadius: BorderRadius.circular(AppBorderRadius.medium),
      ),
      child: Column(
        children: items.map((item) {
          return Padding(
            padding: const EdgeInsets.only(bottom: AppSpacing.md),
            child: Row(
              children: [
                Icon(
                  item['icon'] as IconData,
                  color: AppColors.primaryGold,
                  size: 20,
                ),
                const SizedBox(width: AppSpacing.md),
                Expanded(
                  child: Text(
                    item['text'] as String,
                    style: Theme.of(context).textTheme.bodyMedium,
                  ),
                ),
              ],
            ),
          );
        }).toList(),
      ),
    );
  }

  Widget _buildExportStatusCard(DataExportRequest request, GdprService gdprService) {
    IconData statusIcon;
    Color statusColor;
    String statusText;
    Widget? actionButton;

    if (request.isReady) {
      statusIcon = Icons.check_circle;
      statusColor = AppColors.successGreen;
      statusText = 'Votre export est prêt !';
      actionButton = ElevatedButton.icon(
        onPressed: () => _downloadExport(request.requestId, gdprService),
        icon: const Icon(Icons.download),
        label: const Text('Télécharger'),
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.primaryGold,
          foregroundColor: AppColors.textLight,
        ),
      );
    } else if (request.isProcessing) {
      statusIcon = Icons.hourglass_empty;
      statusColor = AppColors.primaryGold;
      statusText = 'Export en cours de préparation...';
      actionButton = TextButton.icon(
        onPressed: () => _refreshStatus(request.requestId, gdprService),
        icon: const Icon(Icons.refresh),
        label: const Text('Actualiser'),
      );
    } else if (request.isFailed) {
      statusIcon = Icons.error;
      statusColor = AppColors.errorRed;
      statusText = 'L\'export a échoué';
      actionButton = TextButton(
        onPressed: () => _requestNewExport(gdprService),
        child: const Text('Réessayer'),
      );
    } else {
      statusIcon = Icons.warning;
      statusColor = AppColors.errorRed;
      statusText = 'L\'export a expiré';
      actionButton = TextButton(
        onPressed: () => _requestNewExport(gdprService),
        child: const Text('Nouvelle demande'),
      );
    }

    return Container(
      padding: const EdgeInsets.all(AppSpacing.lg),
      decoration: BoxDecoration(
        color: statusColor.withOpacity(0.1),
        borderRadius: BorderRadius.circular(AppBorderRadius.large),
        border: Border.all(color: statusColor.withOpacity(0.3)),
      ),
      child: Column(
        children: [
          Row(
            children: [
              Icon(statusIcon, color: statusColor, size: 32),
              const SizedBox(width: AppSpacing.md),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      statusText,
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                        color: statusColor,
                      ),
                    ),
                    if (request.estimatedTime != null) ...[
                      const SizedBox(height: 4),
                      Text(
                        'Temps estimé : ${request.estimatedTime}',
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: AppColors.textSecondary,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ],
          ),
          if (actionButton != null) ...[
            const SizedBox(height: AppSpacing.md),
            SizedBox(
              width: double.infinity,
              child: actionButton,
            ),
          ],
          if (request.isReady && request.expiresAt != null) ...[
            const SizedBox(height: AppSpacing.sm),
            Text(
              'Expire le ${_formatDate(request.expiresAt!)}',
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: AppColors.textSecondary,
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildRequestExportButton(GdprService gdprService) {
    return Column(
      children: [
        SizedBox(
          width: double.infinity,
          child: ElevatedButton.icon(
            onPressed: gdprService.isLoading ? null : () => _requestNewExport(gdprService),
            icon: gdprService.isLoading
                ? const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      valueColor: AlwaysStoppedAnimation<Color>(AppColors.textLight),
                    ),
                  )
                : const Icon(Icons.file_download),
            label: Text(gdprService.isLoading ? 'Demande en cours...' : 'Demander un export'),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primaryGold,
              foregroundColor: AppColors.textLight,
              padding: const EdgeInsets.symmetric(vertical: AppSpacing.md),
            ),
          ),
        ),
      ],
    );
  }

  Future<void> _requestNewExport(GdprService gdprService) async {
    final success = await gdprService.requestDataExport();

    if (!mounted) return;

    if (success) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('Export demandé avec succès. Vous recevrez un email.'),
          backgroundColor: AppColors.successGreen,
          behavior: SnackBarBehavior.floating,
        ),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(gdprService.error ?? 'Erreur lors de la demande'),
          backgroundColor: AppColors.errorRed,
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  Future<void> _refreshStatus(String requestId, GdprService gdprService) async {
    await gdprService.getExportStatus(requestId);
  }

  Future<void> _downloadExport(String requestId, GdprService gdprService) async {
    try {
      // Show loading
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) => const Center(
          child: CircularProgressIndicator(
            valueColor: AlwaysStoppedAnimation<Color>(AppColors.primaryGold),
          ),
        ),
      );

      final data = await gdprService.downloadDataExport(requestId);

      if (!mounted) return;
      Navigator.of(context).pop(); // Close loading

      if (data != null) {
        // Save file
        final directory = await getApplicationDocumentsDirectory();
        final file = File('${directory.path}/goldwen_data_export_${DateTime.now().millisecondsSinceEpoch}.json');
        await file.writeAsBytes(data);

        // Share file
        await Share.shareXFiles(
          [XFile(file.path)],
          subject: 'Export de mes données GoldWen',
        );

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: const Text('Export téléchargé avec succès'),
              backgroundColor: AppColors.successGreen,
              behavior: SnackBarBehavior.floating,
            ),
          );
        }
      } else {
        throw Exception('Données non disponibles');
      }
    } catch (e) {
      if (mounted) {
        Navigator.of(context).pop(); // Close loading if still open
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Erreur lors du téléchargement: $e'),
            backgroundColor: AppColors.errorRed,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    }
  }

  String _formatDate(DateTime date) {
    return '${date.day.toString().padLeft(2, '0')}/${date.month.toString().padLeft(2, '0')}/${date.year}';
  }
}
