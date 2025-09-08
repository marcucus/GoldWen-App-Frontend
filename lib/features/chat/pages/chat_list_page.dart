import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';
import '../../../core/theme/app_theme.dart';
import '../providers/chat_provider.dart';

class ChatListPage extends StatefulWidget {
  const ChatListPage({super.key});

  @override
  State<ChatListPage> createState() => _ChatListPageState();
}

class _ChatListPageState extends State<ChatListPage> {
  @override
  void initState() {
    super.initState();
    _loadChats();
  }

  void _loadChats() {
    final chatProvider = Provider.of<ChatProvider>(context, listen: false);
    chatProvider.loadConversations();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
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
                  Expanded(
                    child: Text(
                      'Messages',
                      style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                        color: AppColors.textLight,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            
            // Content container
            Expanded(
              child: Container(
                decoration: BoxDecoration(
                  color: AppColors.backgroundWhite,
                  borderRadius: const BorderRadius.only(
                    topLeft: Radius.circular(AppBorderRadius.xLarge),
                    topRight: Radius.circular(AppBorderRadius.xLarge),
                  ),
                ),
                child: Consumer<ChatProvider>(
                  builder: (context, chatProvider, child) {
                    if (chatProvider.isLoading) {
                      return const Center(
                        child: CircularProgressIndicator(
                          valueColor: AlwaysStoppedAnimation<Color>(AppColors.primaryGold),
                        ),
                      );
                    }

                    if (chatProvider.error != null) {
                      return _buildErrorState(chatProvider.error!);
                    }

                    if (chatProvider.conversations.isEmpty) {
                      return _buildEmptyState();
                    }

                    return RefreshIndicator(
                      onRefresh: () async => _loadChats(),
                      child: ListView.builder(
                        padding: const EdgeInsets.all(AppSpacing.md).copyWith(
                          bottom: 100, // Add space for floating nav
                        ),
                        itemCount: chatProvider.conversations.length,
                        itemBuilder: (context, index) {
                          final chat = chatProvider.conversations[index];
                          return _buildChatItem(chat, chatProvider);
                        },
                      ),
                    );
                  },
                ),
              ),
            ),
          ],
        ),
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
              Icons.chat_bubble_outline,
              size: 80,
              color: AppColors.textSecondary,
            ),
            const SizedBox(height: AppSpacing.lg),
            Text(
              'Aucune conversation',
              style: Theme.of(context).textTheme.headlineSmall,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: AppSpacing.md),
            Text(
              'Vos conversations apparaîtront ici après vos premiers matches.',
              style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                color: AppColors.textSecondary,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildErrorState(String error) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.lg),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.error_outline,
              size: 80,
              color: AppColors.errorRed,
            ),
            const SizedBox(height: AppSpacing.lg),
            Text(
              'Erreur de chargement',
              style: Theme.of(context).textTheme.headlineSmall,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: AppSpacing.md),
            Text(
              error,
              style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                color: AppColors.textSecondary,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: AppSpacing.lg),
            ElevatedButton(
              onPressed: () {
                final chatProvider = Provider.of<ChatProvider>(context, listen: false);
                chatProvider.clearError();
                _loadChats();
              },
              child: const Text('Réessayer'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildChatItem(dynamic chat, ChatProvider chatProvider) {
    final isExpired = chatProvider.isChatExpired(chat.id);
    final remainingTime = chatProvider.getRemainingTime(chat.id);
    
    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.sm),
      child: Card(
        child: ListTile(
          leading: Container(
            width: 50,
            height: 50,
            decoration: BoxDecoration(
              color: AppColors.primaryGold.withOpacity(0.3),
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.person,
              color: AppColors.primaryGold,
            ),
          ),
          title: Text(
            chat.otherParticipant?.id ?? 'Match',
            style: Theme.of(context).textTheme.titleMedium,
          ),
          subtitle: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                chat.lastMessage?.content ?? 'Nouveau match !',
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: AppColors.textSecondary,
                ),
              ),
              if (!isExpired && remainingTime != null) ...[
                const SizedBox(height: 2),
                Text(
                  'Expire dans ${remainingTime.inHours}h ${remainingTime.inMinutes % 60}m',
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: AppColors.primaryGold,
                    fontSize: 11,
                  ),
                ),
              ] else if (isExpired) ...[
                const SizedBox(height: 2),
                Text(
                  'Conversation expirée',
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: AppColors.errorRed,
                    fontSize: 11,
                  ),
                ),
              ],
            ],
          ),
          trailing: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              if (chat.unreadCount > 0)
                Container(
                  padding: const EdgeInsets.all(6),
                  decoration: const BoxDecoration(
                    color: AppColors.primaryGold,
                    shape: BoxShape.circle,
                  ),
                  child: Text(
                    chat.unreadCount.toString(),
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              if (!isExpired)
                const Icon(
                  Icons.arrow_forward_ios,
                  size: 16,
                  color: AppColors.textSecondary,
                ),
            ],
          ),
          onTap: isExpired
              ? null
              : () {
                  context.go('/chat/${chat.id}');
                },
        ),
      ),
    );
  }
}