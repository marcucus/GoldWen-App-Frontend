import 'package:flutter/material.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/models/models.dart';
import '../../../core/utils/text_validator.dart';

class ReportFormWidget extends StatefulWidget {
  final String targetUserId;
  final String? targetUserName;
  final String? messageId;
  final String? chatId;
  final Function(ReportType type, String description) onSubmit;
  final bool isSubmitting;

  const ReportFormWidget({
    super.key,
    required this.targetUserId,
    this.targetUserName,
    this.messageId,
    this.chatId,
    required this.onSubmit,
    this.isSubmitting = false,
  });

  @override
  State<ReportFormWidget> createState() => _ReportFormWidgetState();
}

class _ReportFormWidgetState extends State<ReportFormWidget> {
  final _formKey = GlobalKey<FormState>();
  final _descriptionController = TextEditingController();
  ReportType _selectedType = ReportType.inappropriateContent;

  final Map<ReportType, String> _reportTypeLabels = {
    ReportType.inappropriateContent: 'Contenu inapproprié',
    ReportType.harassment: 'Harcèlement',
    ReportType.spam: 'Spam',
    ReportType.other: 'Autre',
  };

  final Map<ReportType, String> _reportTypeDescriptions = {
    ReportType.inappropriateContent: 'Photos ou texte inapproprié, offensant',
    ReportType.harassment: 'Messages insistants, comportement harcelant',
    ReportType.spam: 'Messages publicitaires, liens suspects',
    ReportType.other: 'Autre problème non listé ci-dessus',
  };

  final Map<ReportType, IconData> _reportTypeIcons = {
    ReportType.inappropriateContent: Icons.warning_amber_rounded,
    ReportType.harassment: Icons.block_rounded,
    ReportType.spam: Icons.report_rounded,
    ReportType.other: Icons.help_outline_rounded,
  };

  @override
  void dispose() {
    _descriptionController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Form(
      key: _formKey,
      child: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Target info card
            if (widget.targetUserName != null) _buildTargetInfoCard(),
            
            const SizedBox(height: AppSpacing.lg),

            // Report type section
            Text(
              'Motif du signalement',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w600,
                color: AppColors.textDark,
              ),
            ),
            const SizedBox(height: AppSpacing.sm),
            Text(
              'Sélectionnez la catégorie qui correspond le mieux au problème',
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: AppColors.textSecondary,
              ),
            ),
            const SizedBox(height: AppSpacing.md),

            // Report type options
            ..._reportTypeLabels.entries.map((entry) {
              return _buildReportTypeOption(entry.key, entry.value);
            }),

            const SizedBox(height: AppSpacing.lg),

            // Description field
            Text(
              'Description du problème (optionnel)',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w600,
                color: AppColors.textDark,
              ),
            ),
            const SizedBox(height: AppSpacing.sm),
            TextFormField(
              controller: _descriptionController,
              maxLines: 5,
              maxLength: 500,
              enabled: !widget.isSubmitting,
              decoration: InputDecoration(
                hintText: 'Décrivez le problème en détail (optionnel)...',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(AppBorderRadius.medium),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(AppBorderRadius.medium),
                  borderSide: const BorderSide(
                    color: AppColors.primaryGold,
                    width: 2,
                  ),
                ),
                filled: true,
                fillColor: AppColors.backgroundLight,
              ),
              validator: (value) {
                if (value != null && value.trim().isNotEmpty) {
                  // Validate for forbidden words if description is provided
                  return TextValidator.validateText(
                    value,
                    checkForbiddenWords: true,
                    checkContactInfo: false,
                    checkSpamPatterns: false,
                  );
                }
                return null; // Optional field
              },
            ),

            const SizedBox(height: AppSpacing.lg),

            // Info message
            Container(
              padding: const EdgeInsets.all(AppSpacing.md),
              decoration: BoxDecoration(
                color: Colors.blue.shade50,
                borderRadius: BorderRadius.circular(AppBorderRadius.medium),
                border: Border.all(
                  color: Colors.blue.shade200,
                  width: 1,
                ),
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Icon(
                    Icons.info_outline,
                    color: Colors.blue.shade700,
                    size: 20,
                  ),
                  const SizedBox(width: AppSpacing.sm),
                  Expanded(
                    child: Text(
                      'Votre signalement sera examiné par notre équipe de modération. Vous ne pouvez signaler le même contenu qu\'une seule fois.',
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: Colors.blue.shade900,
                      ),
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: AppSpacing.xl),

            // Submit button
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: widget.isSubmitting
                    ? null
                    : () {
                        if (_formKey.currentState!.validate()) {
                          widget.onSubmit(
                            _selectedType,
                            _descriptionController.text.trim(),
                          );
                        }
                      },
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.red,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(
                    vertical: AppSpacing.md,
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(AppBorderRadius.medium),
                  ),
                  elevation: 2,
                ),
                child: widget.isSubmitting
                    ? const SizedBox(
                        height: 20,
                        width: 20,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                        ),
                      )
                    : const Text(
                        'Envoyer le signalement',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTargetInfoCard() {
    final isMessageReport = widget.messageId != null;
    
    return Container(
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: AppColors.backgroundLight,
        borderRadius: BorderRadius.circular(AppBorderRadius.medium),
        border: Border.all(
          color: AppColors.borderLight,
          width: 1,
        ),
      ),
      child: Row(
        children: [
          Icon(
            isMessageReport ? Icons.message : Icons.person,
            color: AppColors.primaryGold,
            size: 24,
          ),
          const SizedBox(width: AppSpacing.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Signalement de ${isMessageReport ? 'message' : 'profil'}',
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: AppColors.textSecondary,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  widget.targetUserName!,
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    color: AppColors.textDark,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildReportTypeOption(ReportType type, String label) {
    final isSelected = _selectedType == type;
    
    return GestureDetector(
      onTap: widget.isSubmitting
          ? null
          : () => setState(() => _selectedType = type),
      child: Container(
        margin: const EdgeInsets.only(bottom: AppSpacing.sm),
        padding: const EdgeInsets.all(AppSpacing.md),
        decoration: BoxDecoration(
          color: isSelected 
              ? AppColors.primaryGold.withOpacity(0.1) 
              : AppColors.backgroundWhite,
          borderRadius: BorderRadius.circular(AppBorderRadius.medium),
          border: Border.all(
            color: isSelected 
                ? AppColors.primaryGold 
                : AppColors.borderLight,
            width: isSelected ? 2 : 1,
          ),
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(AppSpacing.sm),
              decoration: BoxDecoration(
                color: isSelected 
                    ? AppColors.primaryGold 
                    : AppColors.backgroundLight,
                shape: BoxShape.circle,
              ),
              child: Icon(
                _reportTypeIcons[type]!,
                color: isSelected ? Colors.white : AppColors.textSecondary,
                size: 20,
              ),
            ),
            const SizedBox(width: AppSpacing.md),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    label,
                    style: Theme.of(context).textTheme.titleSmall?.copyWith(
                      fontWeight: FontWeight.w600,
                      color: isSelected 
                          ? AppColors.primaryGold 
                          : AppColors.textDark,
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
            if (isSelected)
              const Icon(
                Icons.check_circle,
                color: AppColors.primaryGold,
                size: 24,
              ),
          ],
        ),
      ),
    );
  }
}
