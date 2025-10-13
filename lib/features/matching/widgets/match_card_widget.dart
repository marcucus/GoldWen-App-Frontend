import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../../core/models/models.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/widgets/modern_cards.dart';
import '../../chat/widgets/chat_countdown_timer.dart';

class MatchCardWidget extends StatelessWidget {
  final Match match;
  final VoidCallback? onArchive;

  const MatchCardWidget({
    super.key,
    required this.match,
    this.onArchive,
  });

  @override
  Widget build(BuildContext context) {
    final profile = match.otherProfile;
    final isActive = match.status == 'active';
    final isPending = match.status == 'pending';
    final isExpired = match.isExpired;

    return Dismissible(
      key: Key(match.id),
      direction: DismissDirection.endToStart,
      confirmDismiss: (direction) async {
        return await showDialog(
          context: context,
          builder: (context) => AlertDialog(
            title: const Text('Archiver ce match ?'),
            content: const Text('Cette action est irréversible.'),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(context).pop(false),
                child: const Text('Annuler'),
              ),
              ElevatedButton(
                onPressed: () => Navigator.of(context).pop(true),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.errorRed,
                  foregroundColor: Colors.white,
                ),
                child: const Text('Archiver'),
              ),
            ],
          ),
        );
      },
      onDismissed: (direction) {
        onArchive?.call();
      },
      background: Container(
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.only(right: 20),
        decoration: BoxDecoration(
          color: AppColors.errorRed,
          borderRadius: BorderRadius.circular(16),
        ),
        child: const Icon(
          Icons.archive,
          color: Colors.white,
          size: 32,
        ),
      ),
      child: GlassCard(
        margin: const EdgeInsets.only(bottom: 16),
        child: InkWell(
          onTap: () {
            if (match.chatId != null && isActive) {
              context.push('/chat/${match.chatId}');
            } else if (profile != null) {
              context.push('/profile/${profile.id}');
            }
          },
          borderRadius: BorderRadius.circular(16),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              children: [
                Row(
                  children: [
                    // Profile Photo with unread badge
                    Stack(
                      children: [
                        Container(
                          width: 60,
                          height: 60,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            gradient: LinearGradient(
                              colors: [
                                AppColors.primaryGold.withOpacity(0.3),
                                AppColors.primaryGold.withOpacity(0.7),
                              ],
                            ),
                          ),
                          child: (profile?.photos != null && profile!.photos.isNotEmpty)
                              ? ClipOval(
                                  child: Image.network(
                                    profile.photos.first.url,
                                    width: 60,
                                    height: 60,
                                    fit: BoxFit.cover,
                                    errorBuilder: (context, error, stackTrace) {
                                      return const Icon(
                                        Icons.person,
                                        color: Colors.white,
                                        size: 30,
                                      );
                                    },
                                  ),
                                )
                              : const Icon(
                                  Icons.person,
                                  color: Colors.white,
                                  size: 30,
                                ),
                        ),
                        // Unread badge
                        if (match.hasUnreadMessages && !isExpired)
                          Positioned(
                            right: 0,
                            top: 0,
                            child: Container(
                              padding: const EdgeInsets.all(6),
                              decoration: BoxDecoration(
                                color: AppColors.errorRed,
                                shape: BoxShape.circle,
                                border: Border.all(color: Colors.white, width: 2),
                              ),
                            ),
                          ),
                      ],
                    ),
                    const SizedBox(width: 16),

                    // Profile Info
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Expanded(
                                child: Text(
                                  profile?.firstName ?? 'Utilisateur',
                                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                                    fontWeight: FontWeight.bold,
                                    color: AppColors.textDark,
                                  ),
                                ),
                              ),
                              // Status badge
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                decoration: BoxDecoration(
                                  color: _getStatusColor(match.status),
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: Text(
                                  _getStatusText(match.status),
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontSize: 11,
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 4),
                          Row(
                            children: [
                              Icon(
                                Icons.favorite,
                                size: 14,
                                color: AppColors.primaryGold,
                              ),
                              const SizedBox(width: 4),
                              Text(
                                '${(match.compatibilityScore * 100).round()}% compatibles',
                                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                  color: AppColors.primaryGold,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 4),
                          // Unread messages indicator
                          if (match.hasUnreadMessages && !isExpired)
                            Row(
                              children: [
                                Icon(
                                  Icons.mark_chat_unread,
                                  size: 14,
                                  color: AppColors.errorRed,
                                ),
                                const SizedBox(width: 4),
                                Text(
                                  'Nouveaux messages',
                                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                    color: AppColors.errorRed,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ],
                            )
                          else
                            Text(
                              _formatMatchDate(match.createdAt),
                              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                color: AppColors.textSecondary,
                              ),
                            ),
                        ],
                      ),
                    ),
                  ],
                ),
                
                // Timer and action button
                if (match.expiresAt != null && !isExpired) ...[
                  const SizedBox(height: 12),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Expanded(
                        child: ChatCountdownTimer(
                          expiresAt: match.expiresAt!,
                        ),
                      ),
                      const SizedBox(width: 12),
                      if (isActive && match.chatId != null)
                        ElevatedButton.icon(
                          onPressed: () => context.push('/chat/${match.chatId}'),
                          icon: const Icon(Icons.chat_bubble, size: 16),
                          label: const Text('Discuter'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppColors.primaryGold,
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                          ),
                        )
                      else if (isPending)
                        const Icon(
                          Icons.hourglass_empty,
                          color: Colors.orange,
                          size: 24,
                        ),
                    ],
                  ),
                ] else if (isExpired) ...[
                  const SizedBox(height: 12),
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: AppColors.errorRed.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Row(
                      children: [
                        Icon(
                          Icons.timer_off,
                          color: AppColors.errorRed,
                          size: 20,
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            'Ce match a expiré',
                            style: TextStyle(
                              color: AppColors.errorRed,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }

  String _formatMatchDate(DateTime date) {
    final now = DateTime.now();
    final difference = now.difference(date);

    if (difference.inDays > 0) {
      return 'Il y a ${difference.inDays} jour${difference.inDays > 1 ? 's' : ''}';
    } else if (difference.inHours > 0) {
      return 'Il y a ${difference.inHours} heure${difference.inHours > 1 ? 's' : ''}';
    } else {
      return 'Il y a ${difference.inMinutes} minute${difference.inMinutes > 1 ? 's' : ''}';
    }
  }

  Color _getStatusColor(String status) {
    switch (status.toLowerCase()) {
      case 'active':
        return Colors.green;
      case 'pending':
        return Colors.orange;
      case 'expired':
      case 'archived':
        return Colors.red;
      default:
        return Colors.grey;
    }
  }

  String _getStatusText(String status) {
    switch (status.toLowerCase()) {
      case 'active':
        return 'Actif';
      case 'pending':
        return 'En attente';
      case 'expired':
        return 'Expiré';
      case 'archived':
        return 'Archivé';
      default:
        return 'Inconnu';
    }
  }
}
