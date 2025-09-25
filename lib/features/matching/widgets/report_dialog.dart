import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/models/models.dart';
import '../providers/report_provider.dart';

class ReportDialog extends StatefulWidget {
  final String targetUserId;
  final String? targetUserName;
  final String? messageId;
  final String? chatId;

  const ReportDialog({
    super.key,
    required this.targetUserId,
    this.targetUserName,
    this.messageId,
    this.chatId,
  });

  @override
  State<ReportDialog> createState() => _ReportDialogState();
}

class _ReportDialogState extends State<ReportDialog> {
  final _formKey = GlobalKey<FormState>();
  final _reasonController = TextEditingController();
  ReportType _selectedType = ReportType.inappropriateContent;
  bool _isSubmitting = false;

  final Map<ReportType, String> _reportTypeLabels = {
    ReportType.inappropriateContent: 'Contenu inapproprié',
    ReportType.harassment: 'Harcèlement',
    ReportType.fakeProfile: 'Faux profil',
    ReportType.spam: 'Spam',
    ReportType.other: 'Autre',
  };

  final Map<ReportType, String> _reportTypeDescriptions = {
    ReportType.inappropriateContent: 'Photos ou texte inapproprié, offensant',
    ReportType.harassment: 'Messages insistants, comportement harcelant',
    ReportType.fakeProfile: 'Profil suspect, fausse identité',
    ReportType.spam: 'Messages publicitaires, liens suspects',
    ReportType.other: 'Autre problème non listé ci-dessus',
  };

  @override
  void dispose() {
    _reasonController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      child: Container(
        constraints: const BoxConstraints(maxWidth: 400),
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header
            Row(
              children: [
                Icon(
                  Icons.flag,
                  color: Colors.red,
                  size: 28,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    'Signaler un problème',
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: AppColors.textDark,
                    ),
                  ),
                ),
                IconButton(
                  onPressed: () => Navigator.of(context).pop(),
                  icon: const Icon(Icons.close),
                  color: AppColors.textSecondary,
                ),
              ],
            ),
            const SizedBox(height: 8),
            
            if (widget.targetUserName != null) ...[
              Text(
                'Signaler ${widget.targetUserName}',
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: AppColors.textSecondary,
                ),
              ),
              const SizedBox(height: 16),
            ],

            Form(
              key: _formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Report Type Selection
                  Text(
                    'Type de problème',
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w600,
                      color: AppColors.textDark,
                    ),
                  ),
                  const SizedBox(height: 12),
                  
                  ..._reportTypeLabels.entries.map((entry) {
                    return _buildReportTypeOption(entry.key, entry.value);
                  }),

                  const SizedBox(height: 20),

                  // Reason Text Field
                  Text(
                    'Description du problème',
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w600,
                      color: AppColors.textDark,
                    ),
                  ),
                  const SizedBox(height: 8),
                  TextFormField(
                    controller: _reasonController,
                    maxLines: 4,
                    maxLength: 500,
                    decoration: InputDecoration(
                      hintText: 'Décrivez le problème en détail...',
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                        borderSide: const BorderSide(color: AppColors.primaryGold),
                      ),
                    ),
                    validator: (value) {
                      if (value == null || value.trim().isEmpty) {
                        return 'Veuillez décrire le problème';
                      }
                      if (value.trim().length < 10) {
                        return 'Description trop courte (minimum 10 caractères)';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 8),

                  // Info text
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.blue.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: Colors.blue.withOpacity(0.3)),
                    ),
                    child: Row(
                      children: [
                        Icon(
                          Icons.info_outline,
                          color: Colors.blue[700],
                          size: 20,
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            'Votre signalement sera examiné par notre équipe de modération.',
                            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                              color: Colors.blue[700],
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 24),

            // Action Buttons
            Row(
              children: [
                Expanded(
                  child: TextButton(
                    onPressed: _isSubmitting ? null : () => Navigator.of(context).pop(),
                    child: const Text('Annuler'),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: ElevatedButton(
                    onPressed: _isSubmitting ? null : _submitReport,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.red,
                      foregroundColor: Colors.white,
                    ),
                    child: _isSubmitting
                        ? const SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                            ),
                          )
                        : const Text('Signaler'),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildReportTypeOption(ReportType type, String label) {
    return InkWell(
      onTap: () => setState(() => _selectedType = type),
      borderRadius: BorderRadius.circular(8),
      child: Container(
        margin: const EdgeInsets.only(bottom: 8),
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          border: Border.all(
            color: _selectedType == type ? AppColors.primaryGold : Colors.grey.shade300,
            width: _selectedType == type ? 2 : 1,
          ),
          borderRadius: BorderRadius.circular(8),
          color: _selectedType == type 
              ? AppColors.primaryGold.withOpacity(0.1) 
              : null,
        ),
        child: Row(
          children: [
            Radio<ReportType>(
              value: type,
              groupValue: _selectedType,
              onChanged: (value) => setState(() => _selectedType = value!),
              activeColor: AppColors.primaryGold,
            ),
            const SizedBox(width: 8),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    label,
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      fontWeight: FontWeight.w500,
                      color: AppColors.textDark,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    _reportTypeDescriptions[type]!,
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: AppColors.textSecondary,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _submitReport() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    setState(() => _isSubmitting = true);

    try {
      final reportProvider = Provider.of<ReportProvider>(context, listen: false);
      
      await reportProvider.submitReport(
        targetUserId: widget.targetUserId,
        type: _selectedType,
        reason: _reasonController.text.trim(),
        messageId: widget.messageId,
        chatId: widget.chatId,
      );

      if (mounted) {
        Navigator.of(context).pop();
        
        // Show success message
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Signalement envoyé avec succès'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Erreur lors de l\'envoi: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isSubmitting = false);
      }
    }
  }

  static Future<void> show(
    BuildContext context, {
    required String targetUserId,
    String? targetUserName,
    String? messageId,
    String? chatId,
  }) async {
    return showDialog(
      context: context,
      builder: (context) => ReportDialog(
        targetUserId: targetUserId,
        targetUserName: targetUserName,
        messageId: messageId,
        chatId: chatId,
      ),
    );
  }
}