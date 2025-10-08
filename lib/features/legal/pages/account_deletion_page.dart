import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/services/gdpr_service.dart';
import '../../../core/models/gdpr_consent.dart';
import '../../auth/providers/auth_provider.dart';

class AccountDeletionPage extends StatefulWidget {
  const AccountDeletionPage({super.key});

  @override
  State<AccountDeletionPage> createState() => _AccountDeletionPageState();
}

class _AccountDeletionPageState extends State<AccountDeletionPage> {
  final _formKey = GlobalKey<FormState>();
  final _passwordController = TextEditingController();
  final _reasonController = TextEditingController();
  bool _obscurePassword = true;
  bool _immediateDelete = false;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _loadDeletionStatus();
  }

  @override
  void dispose() {
    _passwordController.dispose();
    _reasonController.dispose();
    super.dispose();
  }

  Future<void> _loadDeletionStatus() async {
    final gdprService = Provider.of<GdprService>(context, listen: false);
    await gdprService.getAccountDeletionStatus();
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
                        'Suppression de compte',
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
                      final deletionStatus = gdprService.accountDeletionStatus;

                      // If account is scheduled for deletion, show status
                      if (deletionStatus != null && deletionStatus.isScheduledForDeletion) {
                        return _buildScheduledDeletionView(deletionStatus);
                      }

                      // Otherwise show deletion form
                      return _buildDeletionForm();
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

  Widget _buildScheduledDeletionView(AccountDeletionStatus status) {
    final daysLeft = status.daysUntilDeletion ?? 0;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(AppSpacing.lg),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Warning banner
          Container(
            padding: const EdgeInsets.all(AppSpacing.lg),
            decoration: BoxDecoration(
              color: AppColors.errorRed.withOpacity(0.1),
              borderRadius: BorderRadius.circular(AppBorderRadius.large),
              border: Border.all(color: AppColors.errorRed.withOpacity(0.3)),
            ),
            child: Column(
              children: [
                Icon(
                  Icons.warning_amber_rounded,
                  size: 64,
                  color: AppColors.errorRed,
                ),
                const SizedBox(height: AppSpacing.md),
                Text(
                  'Suppression programmée',
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: AppColors.errorRed,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: AppSpacing.sm),
                Text(
                  'Votre compte sera supprimé dans',
                  style: Theme.of(context).textTheme.bodyLarge,
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: AppSpacing.md),
                Text(
                  '$daysLeft jours',
                  style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: AppColors.errorRed,
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: AppSpacing.xl),

          // Deletion date
          if (status.deletionDate != null)
            _buildInfoCard(
              'Date de suppression',
              _formatDate(status.deletionDate!),
              Icons.calendar_today,
            ),

          const SizedBox(height: AppSpacing.lg),

          // Message
          if (status.message != null)
            Container(
              padding: const EdgeInsets.all(AppSpacing.lg),
              decoration: BoxDecoration(
                color: AppColors.backgroundGrey,
                borderRadius: BorderRadius.circular(AppBorderRadius.medium),
              ),
              child: Row(
                children: [
                  Icon(Icons.info_outline, color: AppColors.textSecondary),
                  const SizedBox(width: AppSpacing.md),
                  Expanded(
                    child: Text(
                      status.message!,
                      style: Theme.of(context).textTheme.bodyMedium,
                    ),
                  ),
                ],
              ),
            ),

          const SizedBox(height: AppSpacing.xl),

          // What will be deleted
          _buildSectionTitle('Ce qui sera supprimé'),
          const SizedBox(height: AppSpacing.md),
          _buildDeletedDataList(),

          const SizedBox(height: AppSpacing.xl),

          // Cancel button
          if (status.canCancel)
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: _isLoading ? null : _cancelDeletion,
                icon: _isLoading
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          valueColor: AlwaysStoppedAnimation<Color>(AppColors.textLight),
                        ),
                      )
                    : const Icon(Icons.cancel),
                label: Text(_isLoading ? 'Annulation...' : 'Annuler la suppression'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.successGreen,
                  foregroundColor: AppColors.textLight,
                  padding: const EdgeInsets.symmetric(vertical: AppSpacing.md),
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildDeletionForm() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(AppSpacing.lg),
      child: Form(
        key: _formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Warning banner
            Container(
              padding: const EdgeInsets.all(AppSpacing.lg),
              decoration: BoxDecoration(
                color: AppColors.errorRed.withOpacity(0.1),
                borderRadius: BorderRadius.circular(AppBorderRadius.large),
                border: Border.all(color: AppColors.errorRed.withOpacity(0.3)),
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Icon(
                    Icons.warning_amber_rounded,
                    color: AppColors.errorRed,
                    size: 32,
                  ),
                  const SizedBox(width: AppSpacing.md),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Attention',
                          style: Theme.of(context).textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.bold,
                            color: AppColors.errorRed,
                          ),
                        ),
                        const SizedBox(height: AppSpacing.sm),
                        Text(
                          'La suppression de votre compte est une action définitive. Toutes vos données seront supprimées.',
                          style: Theme.of(context).textTheme.bodyMedium,
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: AppSpacing.xl),

            // What will be deleted
            _buildSectionTitle('Ce qui sera supprimé'),
            const SizedBox(height: AppSpacing.md),
            _buildDeletedDataList(),

            const SizedBox(height: AppSpacing.xl),

            // Password confirmation
            _buildSectionTitle('Confirmation'),
            const SizedBox(height: AppSpacing.md),
            TextFormField(
              controller: _passwordController,
              obscureText: _obscurePassword,
              decoration: InputDecoration(
                labelText: 'Mot de passe',
                hintText: 'Saisissez votre mot de passe',
                prefixIcon: const Icon(Icons.lock_outline),
                suffixIcon: IconButton(
                  icon: Icon(
                    _obscurePassword ? Icons.visibility : Icons.visibility_off,
                  ),
                  onPressed: () {
                    setState(() {
                      _obscurePassword = !_obscurePassword;
                    });
                  },
                ),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(AppBorderRadius.medium),
                ),
              ),
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return 'Veuillez saisir votre mot de passe';
                }
                return null;
              },
            ),

            const SizedBox(height: AppSpacing.lg),

            // Reason (optional)
            TextFormField(
              controller: _reasonController,
              maxLines: 3,
              decoration: InputDecoration(
                labelText: 'Raison (optionnel)',
                hintText: 'Pourquoi souhaitez-vous supprimer votre compte ?',
                prefixIcon: const Icon(Icons.comment_outlined),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(AppBorderRadius.medium),
                ),
              ),
            ),

            const SizedBox(height: AppSpacing.lg),

            // Grace period option
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
                      Checkbox(
                        value: _immediateDelete,
                        onChanged: (value) {
                          setState(() {
                            _immediateDelete = value ?? false;
                          });
                        },
                        activeColor: AppColors.errorRed,
                      ),
                      Expanded(
                        child: Text(
                          'Supprimer immédiatement',
                          style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ],
                  ),
                  Padding(
                    padding: const EdgeInsets.only(left: AppSpacing.xl + AppSpacing.sm),
                    child: Text(
                      _immediateDelete
                          ? 'Votre compte sera supprimé immédiatement et de façon irréversible.'
                          : 'Délai de grâce de 30 jours : vous pourrez annuler la suppression pendant cette période.',
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: AppColors.textSecondary,
                      ),
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: AppSpacing.xl),

            // Delete button
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: _isLoading ? null : _confirmDeletion,
                icon: _isLoading
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          valueColor: AlwaysStoppedAnimation<Color>(AppColors.textLight),
                        ),
                      )
                    : const Icon(Icons.delete_forever),
                label: Text(_isLoading ? 'Suppression...' : 'Supprimer mon compte'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.errorRed,
                  foregroundColor: AppColors.textLight,
                  padding: const EdgeInsets.symmetric(vertical: AppSpacing.md),
                ),
              ),
            ),

            const SizedBox(height: AppSpacing.md),

            // Cancel button
            SizedBox(
              width: double.infinity,
              child: OutlinedButton(
                onPressed: () => Navigator.of(context).pop(),
                child: const Text('Annuler'),
                style: OutlinedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: AppSpacing.md),
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
        fontWeight: FontWeight.bold,
        color: AppColors.primaryGold,
      ),
    );
  }

  Widget _buildDeletedDataList() {
    final items = [
      'Votre profil et toutes vos photos',
      'Vos réponses au questionnaire de personnalité',
      'Tous vos matches et conversations',
      'Votre historique d\'activité',
      'Vos préférences et paramètres',
      'Votre abonnement (si actif)',
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
            padding: const EdgeInsets.only(bottom: AppSpacing.sm),
            child: Row(
              children: [
                Icon(
                  Icons.close,
                  color: AppColors.errorRed,
                  size: 20,
                ),
                const SizedBox(width: AppSpacing.sm),
                Expanded(
                  child: Text(
                    item,
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

  Widget _buildInfoCard(String label, String value, IconData icon) {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.lg),
      decoration: BoxDecoration(
        color: AppColors.backgroundGrey,
        borderRadius: BorderRadius.circular(AppBorderRadius.medium),
      ),
      child: Row(
        children: [
          Icon(icon, color: AppColors.primaryGold),
          const SizedBox(width: AppSpacing.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: AppColors.textSecondary,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  value,
                  style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _confirmDeletion() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    // Show confirmation dialog
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Dernière confirmation'),
        content: Text(
          _immediateDelete
              ? 'Votre compte sera supprimé immédiatement et définitivement. Cette action est irréversible.'
              : 'Votre compte sera programmé pour suppression dans 30 jours. Vous pourrez annuler cette action pendant cette période.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Annuler'),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            style: TextButton.styleFrom(
              foregroundColor: AppColors.errorRed,
            ),
            child: const Text('Confirmer'),
          ),
        ],
      ),
    );

    if (confirmed != true) return;

    setState(() {
      _isLoading = true;
    });

    final gdprService = Provider.of<GdprService>(context, listen: false);
    final authProvider = Provider.of<AuthProvider>(context, listen: false);

    final success = await gdprService.deleteAccountWithGdprCompliance(
      password: _passwordController.text,
      reason: _reasonController.text.isNotEmpty ? _reasonController.text : null,
      immediateDelete: _immediateDelete,
    );

    setState(() {
      _isLoading = false;
    });

    if (!mounted) return;

    if (success) {
      if (_immediateDelete) {
        // Logout and redirect to welcome
        await authProvider.logout();
        if (mounted) {
          context.go('/welcome');
        }
      } else {
        // Show success message and refresh status
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text('Suppression programmée. Vous avez 30 jours pour annuler.'),
            backgroundColor: AppColors.successGreen,
            behavior: SnackBarBehavior.floating,
          ),
        );
        await _loadDeletionStatus();
      }
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

  Future<void> _cancelDeletion() async {
    setState(() {
      _isLoading = true;
    });

    final gdprService = Provider.of<GdprService>(context, listen: false);
    final success = await gdprService.cancelAccountDeletion();

    setState(() {
      _isLoading = false;
    });

    if (!mounted) return;

    if (success) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('Suppression annulée avec succès'),
          backgroundColor: AppColors.successGreen,
          behavior: SnackBarBehavior.floating,
        ),
      );
      await _loadDeletionStatus();
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(gdprService.error ?? 'Erreur lors de l\'annulation'),
          backgroundColor: AppColors.errorRed,
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  String _formatDate(DateTime date) {
    return '${date.day.toString().padLeft(2, '0')}/${date.month.toString().padLeft(2, '0')}/${date.year}';
  }
}
