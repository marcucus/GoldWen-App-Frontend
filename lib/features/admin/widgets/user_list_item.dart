import 'package:flutter/material.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/models/user.dart';

class UserListItem extends StatelessWidget {
  final User user;
  final VoidCallback onTap;
  final Function(String) onStatusChanged;

  const UserListItem({
    super.key,
    required this.user,
    required this.onTap,
    required this.onStatusChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.md),
          child: Row(
            children: [
              // Profile Picture Placeholder
              CircleAvatar(
                radius: 28,
                backgroundColor: AppColors.primaryGold.withOpacity(0.1),
                backgroundImage: user.profilePicture != null 
                    ? NetworkImage(user.profilePicture!) 
                    : null,
                child: user.profilePicture == null 
                    ? Text(
                        '${user.firstName?.substring(0, 1) ?? ''}${user.lastName?.substring(0, 1) ?? ''}',
                        style: TextStyle(
                          color: AppColors.primaryGold,
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                        ),
                      )
                    : null,
              ),
              
              const SizedBox(width: AppSpacing.md),
              
              // User Info
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '${user.firstName} ${user.lastName}',
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w600,
                        color: AppColors.textDark,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      user.email,
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: AppColors.textSecondary,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        Icon(
                          Icons.cake_outlined,
                          size: 14,
                          color: AppColors.textTertiary,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          '${user.age} ans',
                          style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            color: AppColors.textTertiary,
                          ),
                        ),
                        const SizedBox(width: AppSpacing.md),
                        if (user.lastActive != null) ...[
                          Icon(
                            Icons.access_time,
                            size: 14,
                            color: AppColors.textTertiary,
                          ),
                          const SizedBox(width: 4),
                          Text(
                            _getLastActiveText(user.lastActive!),
                            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                              color: AppColors.textTertiary,
                            ),
                          ),
                        ],
                      ],
                    ),
                  ],
                ),
              ),
              
              // Status and Actions
              Column(
                children: [
                  _StatusChip(status: _getUserStatus()),
                  const SizedBox(height: AppSpacing.sm),
                  PopupMenuButton<String>(
                    onSelected: onStatusChanged,
                    itemBuilder: (context) => [
                      const PopupMenuItem(
                        value: 'active',
                        child: Row(
                          children: [
                            Icon(Icons.check_circle, color: Colors.green, size: 20),
                            SizedBox(width: 8),
                            Text('Activer'),
                          ],
                        ),
                      ),
                      const PopupMenuItem(
                        value: 'suspended',
                        child: Row(
                          children: [
                            Icon(Icons.pause_circle, color: Colors.orange, size: 20),
                            SizedBox(width: 8),
                            Text('Suspendre'),
                          ],
                        ),
                      ),
                      const PopupMenuItem(
                        value: 'banned',
                        child: Row(
                          children: [
                            Icon(Icons.block, color: Colors.red, size: 20),
                            SizedBox(width: 8),
                            Text('Bannir'),
                          ],
                        ),
                      ),
                    ],
                    child: Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: AppColors.backgroundGrey,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Icon(
                        Icons.more_vert,
                        size: 20,
                        color: AppColors.textSecondary,
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  String _getUserStatus() {
    // Since the User model might not have a status field directly,
    // we'll assume active for now. This should be updated based on the actual User model.
    return 'active'; // This should be user.status when available
  }

  String _getLastActiveText(DateTime lastActive) {
    final now = DateTime.now();
    final difference = now.difference(lastActive);
    
    if (difference.inDays > 0) {
      return 'Il y a ${difference.inDays}j';
    } else if (difference.inHours > 0) {
      return 'Il y a ${difference.inHours}h';
    } else if (difference.inMinutes > 0) {
      return 'Il y a ${difference.inMinutes}min';
    } else {
      return 'À l\'instant';
    }
  }
}

class _StatusChip extends StatelessWidget {
  final String status;

  const _StatusChip({required this.status});

  @override
  Widget build(BuildContext context) {
    Color backgroundColor;
    Color textColor;
    String label;

    switch (status.toLowerCase()) {
      case 'active':
        backgroundColor = AppColors.successGreen.withOpacity(0.1);
        textColor = AppColors.successGreen;
        label = 'Actif';
        break;
      case 'suspended':
        backgroundColor = AppColors.warningAmber.withOpacity(0.1);
        textColor = AppColors.warningAmber;
        label = 'Suspendu';
        break;
      case 'banned':
        backgroundColor = AppColors.errorRed.withOpacity(0.1);
        textColor = AppColors.errorRed;
        label = 'Banni';
        break;
      default:
        backgroundColor = AppColors.textTertiary.withOpacity(0.1);
        textColor = AppColors.textTertiary;
        label = 'Inconnu';
    }

    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.sm,
        vertical: AppSpacing.xs,
      ),
      decoration: BoxDecoration(
        color: backgroundColor,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Text(
        label,
        style: Theme.of(context).textTheme.bodySmall?.copyWith(
          color: textColor,
          fontWeight: FontWeight.w500,
        ),
      ),
    );
  }
}