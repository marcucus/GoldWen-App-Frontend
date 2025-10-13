import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';
import '../../../core/theme/app_theme.dart';
import '../providers/chat_provider.dart';
import '../../../core/models/chat.dart';

class ArchivedChatsPage extends StatefulWidget {
  const ArchivedChatsPage({super.key});

  @override
  State<ArchivedChatsPage> createState() => _ArchivedChatsPageState();
}

class _ArchivedChatsPageState extends State<ArchivedChatsPage> {
  @override
  void initState() {
    super.initState();
    _loadArchivedChats();
  }

  void _loadArchivedChats() {
    final chatProvider = Provider.of<ChatProvider>(context, listen: false);
    chatProvider.loadConversations();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Chats archivés'),
        elevation: 0,
      ),
      body: Consumer<ChatProvider>(
        builder: (context, chatProvider, child) {
          if (chatProvider.isLoading) {
            return const Center(
              child: CircularProgressIndicator(),
            );
          }

          final archivedChats = chatProvider.archivedConversations;

          if (archivedChats.isEmpty) {
            return _buildEmptyState();
          }

          return RefreshIndicator(
            onRefresh: () async {
              await chatProvider.loadConversations();
            },
            child: ListView.builder(
              padding: const EdgeInsets.all(AppSpacing.md),
              itemCount: archivedChats.length,
              itemBuilder: (context, index) {
                final conversation = archivedChats[index];
                return _buildArchivedChatCard(conversation);
              },
            ),
          );
        },
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.lg),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.archive_outlined,
              size: 80,
              color: AppColors.textSecondary.withOpacity(0.5),
            ),
            const SizedBox(height: AppSpacing.lg),
            Text(
              'Aucun chat archivé',
              style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                    color: AppColors.textSecondary,
                  ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: AppSpacing.md),
            Text(
              'Les conversations expirées apparaîtront ici. Elles seront consultables en lecture seule.',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: AppColors.textSecondary,
                  ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildArchivedChatCard(Conversation conversation) {
    final otherUser = conversation.otherParticipant;
    final lastMessage = conversation.lastMessage;

    return Card(
      margin: const EdgeInsets.only(bottom: AppSpacing.md),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppBorderRadius.medium),
      ),
      child: InkWell(
        onTap: () {
          context.push('/chat/${conversation.id}?archived=true');
        },
        borderRadius: BorderRadius.circular(AppBorderRadius.medium),
        child: Container(
          padding: const EdgeInsets.all(AppSpacing.md),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(AppBorderRadius.medium),
            border: Border.all(
              color: AppColors.errorRed.withOpacity(0.2),
              width: 1,
            ),
          ),
          child: Row(
            children: [
              // Avatar with archived badge
              Stack(
                children: [
                  CircleAvatar(
                    radius: 28,
                    backgroundColor: AppColors.backgroundGrey,
                    backgroundImage: otherUser?.photoUrls?.isNotEmpty == true
                        ? NetworkImage(otherUser!.photoUrls!.first)
                        : null,
                    child: otherUser?.photoUrls?.isEmpty ?? true
                        ? const Icon(Icons.person, color: AppColors.textSecondary)
                        : null,
                  ),
                  Positioned(
                    bottom: 0,
                    right: 0,
                    child: Container(
                      padding: const EdgeInsets.all(2),
                      decoration: const BoxDecoration(
                        color: AppColors.errorRed,
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(
                        Icons.archive,
                        size: 12,
                        color: Colors.white,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(width: AppSpacing.md),
              // Chat info
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            otherUser?.firstName ?? 'Utilisateur',
                            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                                  fontWeight: FontWeight.w600,
                                ),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: AppSpacing.sm,
                            vertical: AppSpacing.xs,
                          ),
                          decoration: BoxDecoration(
                            color: AppColors.errorRed.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(AppBorderRadius.small),
                          ),
                          child: Text(
                            'Archivé',
                            style: Theme.of(context).textTheme.labelSmall?.copyWith(
                                  color: AppColors.errorRed,
                                  fontWeight: FontWeight.w600,
                                ),
                          ),
                        ),
                      ],
                    ),
                    if (lastMessage != null) ...[
                      const SizedBox(height: AppSpacing.xs),
                      Text(
                        lastMessage.content,
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                              color: AppColors.textSecondary,
                            ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                    const SizedBox(height: AppSpacing.xs),
                    Row(
                      children: [
                        Icon(
                          Icons.schedule,
                          size: 14,
                          color: AppColors.textSecondary,
                        ),
                        const SizedBox(width: AppSpacing.xs),
                        Text(
                          'Expiré le ${_formatDate(conversation.expiresAt)}',
                          style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                color: AppColors.textSecondary,
                                fontSize: 12,
                              ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(width: AppSpacing.sm),
              // Arrow icon
              Icon(
                Icons.chevron_right,
                color: AppColors.textSecondary,
              ),
            ],
          ),
        ),
      ),
    );
  }

  String _formatDate(DateTime? date) {
    if (date == null) return 'Date inconnue';
    
    final now = DateTime.now();
    final difference = now.difference(date);
    
    if (difference.inDays == 0) {
      return 'Aujourd\'hui';
    } else if (difference.inDays == 1) {
      return 'Hier';
    } else if (difference.inDays < 7) {
      return 'Il y a ${difference.inDays} jours';
    } else {
      return '${date.day}/${date.month}/${date.year}';
    }
  }
}
