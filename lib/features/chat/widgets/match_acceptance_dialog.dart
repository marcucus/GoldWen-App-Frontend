import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/models/models.dart';
import '../providers/chat_provider.dart';
import '../../matching/providers/matching_provider.dart';

class MatchAcceptanceDialog extends StatefulWidget {
  final String matchId;
  final Profile? otherUser;
  final VoidCallback? onAccepted;
  final VoidCallback? onDeclined;

  const MatchAcceptanceDialog({
    super.key,
    required this.matchId,
    this.otherUser,
    this.onAccepted,
    this.onDeclined,
  });

  @override
  State<MatchAcceptanceDialog> createState() => _MatchAcceptanceDialogState();
}

class _MatchAcceptanceDialogState extends State<MatchAcceptanceDialog> {
  bool _isLoading = false;

  @override
  Widget build(BuildContext context) {
    return Dialog(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
      ),
      child: Container(
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(20),
          gradient: const LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              AppColors.backgroundWhite,
              AppColors.secondaryBeige,
            ],
          ),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Celebration icon
            Container(
              width: 80,
              height: 80,
              decoration: const BoxDecoration(
                color: AppColors.primaryGold,
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.favorite,
                color: AppColors.textLight,
                size: 40,
              ),
            ),
            const SizedBox(height: 24),
            
            // Title
            const Text(
              'Félicitations !',
              style: TextStyle(
                fontSize: 28,
                fontWeight: FontWeight.bold,
                color: AppColors.textDark,
                fontFamily: 'Playfair Display',
              ),
            ),
            const SizedBox(height: 12),
            
            // Subtitle
            Text(
              'Vous avez un match avec ${widget.otherUser?.firstName ?? 'quelqu\'un de spécial'}',
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontSize: 16,
                color: AppColors.textSecondary,
                fontFamily: 'Lato',
              ),
            ),
            const SizedBox(height: 8),
            
            // Timer info
            const Text(
              'Vous avez 24h pour commencer une conversation !',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 14,
                color: AppColors.warningOrange,
                fontWeight: FontWeight.w600,
                fontFamily: 'Lato',
              ),
            ),
            const SizedBox(height: 32),
            
            if (_isLoading) ...[
              const CircularProgressIndicator(
                color: AppColors.primaryGold,
              ),
              const SizedBox(height: 16),
              const Text(
                'Création du chat...',
                style: TextStyle(
                  fontSize: 14,
                  color: AppColors.textSecondary,
                  fontFamily: 'Lato',
                ),
              ),
            ] else ...[
              // Action buttons
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () => _handleDecline(context),
                      style: OutlinedButton.styleFrom(
                        side: const BorderSide(color: AppColors.textTertiary),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        padding: const EdgeInsets.symmetric(vertical: 16),
                      ),
                      child: const Text(
                        'Décliner',
                        style: TextStyle(
                          color: AppColors.textSecondary,
                          fontWeight: FontWeight.w600,
                          fontFamily: 'Lato',
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    flex: 2,
                    child: ElevatedButton(
                      onPressed: () => _handleAccept(context),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.primaryGold,
                        foregroundColor: AppColors.textLight,
                        elevation: 2,
                        shadowColor: AppColors.shadowMedium,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        padding: const EdgeInsets.symmetric(vertical: 16),
                      ),
                      child: const Text(
                        'Commencer le chat',
                        style: TextStyle(
                          fontWeight: FontWeight.w600,
                          fontFamily: 'Lato',
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }

  Future<void> _handleAccept(BuildContext context) async {
    setState(() {
      _isLoading = true;
    });

    try {
      final matchingProvider = Provider.of<MatchingProvider>(context, listen: false);
      final chatProvider = Provider.of<ChatProvider>(context, listen: false);
      
      // Accept the match
      final result = await matchingProvider.acceptMatch(widget.matchId, accept: true);
      
      if (result != null && result['chatId'] != null) {
        // Refresh chat list to include new chat
        await chatProvider.loadConversations();
        
        widget.onAccepted?.call();
        
        if (context.mounted) {
          Navigator.of(context).pop();
          // Navigate to the new chat
          Navigator.pushNamed(
            context,
            '/chat/${result['chatId']}',
          );
        }
      } else {
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Erreur lors de la création du chat'),
              backgroundColor: AppColors.errorRed,
            ),
          );
        }
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Erreur lors de l\'acceptation du match'),
            backgroundColor: AppColors.errorRed,
          ),
        );
      }
    }

    if (mounted) {
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _handleDecline(BuildContext context) async {
    setState(() {
      _isLoading = true;
    });

    try {
      final matchingProvider = Provider.of<MatchingProvider>(context, listen: false);
      
      // Decline the match
      await matchingProvider.acceptMatch(widget.matchId, accept: false);
      
      widget.onDeclined?.call();
      
      if (context.mounted) {
        Navigator.of(context).pop();
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Erreur lors du refus du match'),
            backgroundColor: AppColors.errorRed,
          ),
        );
      }
    }

    if (mounted) {
      setState(() {
        _isLoading = false;
      });
    }
  }
}