import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/models/models.dart';
import '../../matching/providers/report_provider.dart';
import '../widgets/report_form_widget.dart';

class ReportPage extends StatefulWidget {
  final String targetUserId;
  final String? targetUserName;
  final String? messageId;
  final String? chatId;

  const ReportPage({
    super.key,
    required this.targetUserId,
    this.targetUserName,
    this.messageId,
    this.chatId,
  });

  @override
  State<ReportPage> createState() => _ReportPageState();
}

class _ReportPageState extends State<ReportPage> {
  bool _isSubmitting = false;
  bool _isCheckingDuplicate = true;
  bool _alreadyReported = false;

  @override
  void initState() {
    super.initState();
    _checkIfAlreadyReported();
  }

  /// Check if the user has already reported this target locally
  Future<void> _checkIfAlreadyReported() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final reportKey = _getReportKey();
      final alreadyReported = prefs.getBool(reportKey) ?? false;
      
      setState(() {
        _alreadyReported = alreadyReported;
        _isCheckingDuplicate = false;
      });
    } catch (e) {
      setState(() {
        _isCheckingDuplicate = false;
      });
    }
  }

  /// Generate a unique key for this report based on target
  String _getReportKey() {
    if (widget.messageId != null) {
      return 'report_message_${widget.messageId}';
    }
    return 'report_user_${widget.targetUserId}';
  }

  /// Mark this target as reported locally
  Future<void> _markAsReported() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final reportKey = _getReportKey();
      await prefs.setBool(reportKey, true);
    } catch (e) {
      print('Failed to mark as reported: $e');
    }
  }

  Future<void> _handleSubmit(ReportType type, String description) async {
    setState(() => _isSubmitting = true);

    try {
      final reportProvider = Provider.of<ReportProvider>(context, listen: false);
      
      await reportProvider.submitReport(
        targetUserId: widget.targetUserId,
        type: type,
        reason: description.isEmpty 
            ? _getDefaultReasonForType(type) 
            : description,
        messageId: widget.messageId,
        chatId: widget.chatId,
      );

      // Mark as reported locally to prevent duplicates
      await _markAsReported();

      if (mounted) {
        // Show success dialog
        await _showSuccessDialog();
        
        // Navigate back
        if (mounted) {
          Navigator.of(context).pop(true);
        }
      }
    } catch (e) {
      if (mounted) {
        // Check if it's a duplicate error from backend
        final errorMessage = e.toString();
        if (errorMessage.contains('already reported') || 
            errorMessage.contains('duplicate')) {
          await _markAsReported();
          await _showAlreadyReportedDialog();
          if (mounted) {
            Navigator.of(context).pop();
          }
        } else {
          _showErrorSnackBar(errorMessage);
        }
      }
    } finally {
      if (mounted) {
        setState(() => _isSubmitting = false);
      }
    }
  }

  String _getDefaultReasonForType(ReportType type) {
    switch (type) {
      case ReportType.inappropriateContent:
        return 'Contenu inapproprié';
      case ReportType.harassment:
        return 'Harcèlement';
      case ReportType.spam:
        return 'Spam';
      case ReportType.other:
        return 'Autre';
      default:
        return 'Signalement';
    }
  }

  Future<void> _showSuccessDialog() async {
    await showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppBorderRadius.large),
        ),
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(AppSpacing.sm),
              decoration: const BoxDecoration(
                color: Colors.green,
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.check,
                color: Colors.white,
                size: 24,
              ),
            ),
            const SizedBox(width: AppSpacing.md),
            const Expanded(
              child: Text('Signalement envoyé'),
            ),
          ],
        ),
        content: const Text(
          'Votre signalement a été transmis à notre équipe de modération. Nous examinerons ce contenu dans les plus brefs délais.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            style: TextButton.styleFrom(
              foregroundColor: AppColors.primaryGold,
            ),
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }

  Future<void> _showAlreadyReportedDialog() async {
    await showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppBorderRadius.large),
        ),
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(AppSpacing.sm),
              decoration: BoxDecoration(
                color: Colors.orange.shade100,
                shape: BoxShape.circle,
              ),
              child: Icon(
                Icons.info_outline,
                color: Colors.orange.shade700,
                size: 24,
              ),
            ),
            const SizedBox(width: AppSpacing.md),
            const Expanded(
              child: Text('Déjà signalé'),
            ),
          ],
        ),
        content: const Text(
          'Vous avez déjà signalé ce contenu. Notre équipe de modération examine votre demande.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            style: TextButton.styleFrom(
              foregroundColor: AppColors.primaryGold,
            ),
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }

  void _showErrorSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Erreur : $message'),
        backgroundColor: Colors.red,
        behavior: SnackBarBehavior.floating,
        action: SnackBarAction(
          label: 'OK',
          textColor: Colors.white,
          onPressed: () {},
        ),
      ),
    );
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
              _buildHeader(),
              
              // Content
              Expanded(
                child: Container(
                  decoration: const BoxDecoration(
                    color: AppColors.backgroundWhite,
                    borderRadius: BorderRadius.only(
                      topLeft: Radius.circular(AppBorderRadius.xLarge),
                      topRight: Radius.circular(AppBorderRadius.xLarge),
                    ),
                  ),
                  child: _buildContent(),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Padding(
      padding: const EdgeInsets.all(AppSpacing.lg),
      child: Row(
        children: [
          Container(
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: AppColors.cardOverlay.withOpacity(0.2),
            ),
            child: IconButton(
              onPressed: _isSubmitting 
                  ? null 
                  : () => Navigator.of(context).pop(),
              icon: const Icon(
                Icons.arrow_back,
                color: AppColors.textLight,
              ),
            ),
          ),
          const SizedBox(width: AppSpacing.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Signaler un problème',
                  style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                    color: AppColors.textLight,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  'Aidez-nous à maintenir une communauté saine',
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: AppColors.textLight.withOpacity(0.9),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildContent() {
    if (_isCheckingDuplicate) {
      return const Center(
        child: CircularProgressIndicator(
          valueColor: AlwaysStoppedAnimation<Color>(AppColors.primaryGold),
        ),
      );
    }

    if (_alreadyReported) {
      return _buildAlreadyReportedView();
    }

    return Padding(
      padding: const EdgeInsets.all(AppSpacing.lg),
      child: ReportFormWidget(
        targetUserId: widget.targetUserId,
        targetUserName: widget.targetUserName,
        messageId: widget.messageId,
        chatId: widget.chatId,
        onSubmit: _handleSubmit,
        isSubmitting: _isSubmitting,
      ),
    );
  }

  Widget _buildAlreadyReportedView() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.xl),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(AppSpacing.xl),
              decoration: BoxDecoration(
                color: Colors.orange.shade50,
                shape: BoxShape.circle,
              ),
              child: Icon(
                Icons.report_problem_outlined,
                size: 64,
                color: Colors.orange.shade700,
              ),
            ),
            const SizedBox(height: AppSpacing.xl),
            Text(
              'Déjà signalé',
              style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                color: AppColors.textDark,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: AppSpacing.md),
            Text(
              'Vous avez déjà signalé ce contenu. Notre équipe de modération examine votre demande.',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: AppColors.textSecondary,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: AppSpacing.xl),
            ElevatedButton(
              onPressed: () => Navigator.of(context).pop(),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primaryGold,
                foregroundColor: AppColors.textDark,
                padding: const EdgeInsets.symmetric(
                  horizontal: AppSpacing.xl,
                  vertical: AppSpacing.md,
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(AppBorderRadius.medium),
                ),
              ),
              child: const Text('Retour'),
            ),
          ],
        ),
      ),
    );
  }
}
