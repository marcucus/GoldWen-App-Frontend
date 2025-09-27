import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/models/feedback.dart';
import '../providers/feedback_provider.dart';

class FeedbackPage extends StatefulWidget {
  const FeedbackPage({super.key});

  @override
  State<FeedbackPage> createState() => _FeedbackPageState();
}

class _FeedbackPageState extends State<FeedbackPage> {
  final _formKey = GlobalKey<FormState>();
  final _subjectController = TextEditingController();
  final _messageController = TextEditingController();
  
  FeedbackType? _selectedType;
  int? _selectedRating;

  @override
  void initState() {
    super.initState();
    // Clear any previous state when entering the page
    WidgetsBinding.instance.addPostFrameCallback((_) {
      Provider.of<FeedbackProvider>(context, listen: false).clearState();
    });
  }

  @override
  void dispose() {
    _subjectController.dispose();
    _messageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<FeedbackProvider>(
      builder: (context, feedbackProvider, child) {
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
                            'Votre feedback',
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
                      child: _buildContent(context, feedbackProvider),
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildContent(BuildContext context, FeedbackProvider feedbackProvider) {
    if (feedbackProvider.isSubmitted) {
      return _buildSuccessView(context, feedbackProvider);
    }

    return SingleChildScrollView(
      padding: const EdgeInsets.all(AppSpacing.lg),
      child: Form(
        key: _formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Introduction text
            Text(
              'Nous sommes à l\'écoute de vos retours pour améliorer GoldWen.',
              style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                color: AppColors.textSecondary,
              ),
            ),
            const SizedBox(height: AppSpacing.xl),
            
            // Type selection
            _buildSectionTitle('Type de feedback'),
            const SizedBox(height: AppSpacing.md),
            _buildTypeSelection(feedbackProvider),
            const SizedBox(height: AppSpacing.xl),
            
            // Subject field
            _buildSectionTitle('Sujet'),
            const SizedBox(height: AppSpacing.md),
            _buildSubjectField(),
            const SizedBox(height: AppSpacing.xl),
            
            // Rating section (optional)
            _buildSectionTitle('Évaluation (optionnel)'),
            const SizedBox(height: AppSpacing.md),
            _buildRatingSection(),
            const SizedBox(height: AppSpacing.xl),
            
            // Message field
            _buildSectionTitle('Message'),
            const SizedBox(height: AppSpacing.md),
            _buildMessageField(),
            const SizedBox(height: AppSpacing.xl),
            
            // Error display
            if (feedbackProvider.error != null) ...[
              _buildErrorCard(feedbackProvider.error!),
              const SizedBox(height: AppSpacing.lg),
            ],
            
            // Submit button
            _buildSubmitButton(context, feedbackProvider),
            const SizedBox(height: AppSpacing.xl),
          ],
        ),
      ),
    );
  }

  Widget _buildSuccessView(BuildContext context, FeedbackProvider feedbackProvider) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.xl),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 100,
              height: 100,
              decoration: BoxDecoration(
                color: AppColors.successGreen.withOpacity(0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(
                Icons.check_circle,
                size: 60,
                color: AppColors.successGreen,
              ),
            ),
            const SizedBox(height: AppSpacing.xl),
            Text(
              'Merci pour votre feedback !',
              style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                color: AppColors.textDark,
                fontWeight: FontWeight.bold,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: AppSpacing.md),
            Text(
              feedbackProvider.successMessage ?? 'Votre feedback a été envoyé avec succès.',
              style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                color: AppColors.textSecondary,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: AppSpacing.xl),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () => Navigator.of(context).pop(),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primaryGold,
                  padding: const EdgeInsets.symmetric(vertical: AppSpacing.md),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(AppBorderRadius.medium),
                  ),
                ),
                child: Text(
                  'Retour aux paramètres',
                  style: TextStyle(
                    color: AppColors.textLight,
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

  Widget _buildSectionTitle(String title) {
    return Text(
      title,
      style: Theme.of(context).textTheme.titleMedium?.copyWith(
        color: AppColors.textDark,
        fontWeight: FontWeight.bold,
      ),
    );
  }

  Widget _buildTypeSelection(FeedbackProvider feedbackProvider) {
    final options = feedbackProvider.getFeedbackTypeOptions();
    
    return Column(
      children: options.map((option) {
        final isSelected = _selectedType == option.type;
        return Padding(
          padding: const EdgeInsets.only(bottom: AppSpacing.sm),
          child: Card(
            elevation: isSelected ? 4 : 1,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(AppBorderRadius.medium),
              side: BorderSide(
                color: isSelected ? AppColors.primaryGold : Colors.transparent,
                width: 2,
              ),
            ),
            child: ListTile(
              leading: Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: option.color.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(AppBorderRadius.medium),
                ),
                child: Icon(
                  option.icon,
                  color: option.color,
                ),
              ),
              title: Text(
                option.title,
                style: TextStyle(
                  fontWeight: FontWeight.w600,
                  color: isSelected ? AppColors.primaryGold : AppColors.textDark,
                ),
              ),
              subtitle: Text(
                option.subtitle,
                style: TextStyle(
                  color: AppColors.textSecondary,
                ),
              ),
              trailing: isSelected
                  ? Icon(Icons.check_circle, color: AppColors.primaryGold)
                  : Icon(Icons.radio_button_unchecked, color: AppColors.textSecondary),
              onTap: () {
                setState(() {
                  _selectedType = option.type;
                });
              },
            ),
          ),
        );
      }).toList(),
    );
  }

  Widget _buildSubjectField() {
    return TextFormField(
      controller: _subjectController,
      decoration: InputDecoration(
        hintText: 'Décrivez brièvement votre feedback',
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppBorderRadius.medium),
          borderSide: BorderSide(color: AppColors.border),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppBorderRadius.medium),
          borderSide: BorderSide(color: AppColors.primaryGold, width: 2),
        ),
        prefixIcon: Icon(Icons.title, color: AppColors.textSecondary),
      ),
      maxLength: 100,
      validator: (value) {
        if (value == null || value.trim().isEmpty) {
          return 'Veuillez entrer un sujet';
        }
        return null;
      },
    );
  }

  Widget _buildRatingSection() {
    return Card(
      elevation: 1,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppBorderRadius.medium),
      ),
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.md),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Notez votre expérience globale avec GoldWen',
              style: TextStyle(
                color: AppColors.textSecondary,
                fontSize: 14,
              ),
            ),
            const SizedBox(height: AppSpacing.sm),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: List.generate(5, (index) {
                final rating = index + 1;
                final isSelected = _selectedRating != null && _selectedRating! >= rating;
                return GestureDetector(
                  onTap: () {
                    setState(() {
                      _selectedRating = rating;
                    });
                  },
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 4.0),
                    child: Icon(
                      Icons.star,
                      size: 40,
                      color: isSelected ? AppColors.primaryGold : AppColors.textSecondary.withOpacity(0.3),
                    ),
                  ),
                );
              }),
            ),
            if (_selectedRating != null) ...[
              const SizedBox(height: AppSpacing.sm),
              Center(
                child: Text(
                  '${_selectedRating!} étoile${_selectedRating! > 1 ? 's' : ''}',
                  style: TextStyle(
                    color: AppColors.primaryGold,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildMessageField() {
    return TextFormField(
      controller: _messageController,
      decoration: InputDecoration(
        hintText: 'Détaillez votre feedback...',
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppBorderRadius.medium),
          borderSide: BorderSide(color: AppColors.border),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppBorderRadius.medium),
          borderSide: BorderSide(color: AppColors.primaryGold, width: 2),
        ),
      ),
      maxLines: 6,
      maxLength: 1000,
      validator: (value) {
        if (value == null || value.trim().isEmpty) {
          return 'Veuillez entrer votre message';
        }
        if (value.trim().length < 10) {
          return 'Le message doit contenir au moins 10 caractères';
        }
        return null;
      },
    );
  }

  Widget _buildErrorCard(String error) {
    return Card(
      color: AppColors.errorRed.withOpacity(0.1),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppBorderRadius.medium),
        side: BorderSide(color: AppColors.errorRed.withOpacity(0.3)),
      ),
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.md),
        child: Row(
          children: [
            Icon(Icons.error_outline, color: AppColors.errorRed),
            const SizedBox(width: AppSpacing.sm),
            Expanded(
              child: Text(
                error,
                style: TextStyle(color: AppColors.errorRed),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSubmitButton(BuildContext context, FeedbackProvider feedbackProvider) {
    return SizedBox(
      width: double.infinity,
      child: ElevatedButton(
        onPressed: feedbackProvider.isLoading || _selectedType == null
            ? null
            : () => _submitFeedback(context, feedbackProvider),
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.primaryGold,
          padding: const EdgeInsets.symmetric(vertical: AppSpacing.md),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppBorderRadius.medium),
          ),
        ),
        child: feedbackProvider.isLoading
            ? SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(
                  valueColor: AlwaysStoppedAnimation<Color>(AppColors.textLight),
                  strokeWidth: 2,
                ),
              )
            : Text(
                'Envoyer le feedback',
                style: TextStyle(
                  color: AppColors.textLight,
                  fontWeight: FontWeight.w600,
                  fontSize: 16,
                ),
              ),
      ),
    );
  }

  void _submitFeedback(BuildContext context, FeedbackProvider feedbackProvider) async {
    // Clear any previous errors
    feedbackProvider.clearError();

    // Validate form
    if (!_formKey.currentState!.validate()) {
      return;
    }

    if (_selectedType == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Veuillez sélectionner un type de feedback'),
          backgroundColor: AppColors.errorRed,
        ),
      );
      return;
    }

    // Submit feedback
    final success = await feedbackProvider.submitFeedback(
      type: _selectedType!,
      subject: _subjectController.text.trim(),
      message: _messageController.text.trim(),
      rating: _selectedRating,
      currentPage: 'FeedbackPage',
    );

    if (!success && context.mounted) {
      // Error handling is managed by the provider and displayed in the UI
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Erreur lors de l\'envoi du feedback. Veuillez réessayer.'),
          backgroundColor: AppColors.errorRed,
        ),
      );
    }
  }
}