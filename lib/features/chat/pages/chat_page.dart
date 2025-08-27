import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../core/theme/app_theme.dart';
import '../providers/chat_provider.dart';

class ChatPage extends StatefulWidget {
  final String chatId;

  const ChatPage({
    super.key,
    required this.chatId,
  });

  @override
  State<ChatPage> createState() => _ChatPageState();
}

class _ChatPageState extends State<ChatPage> with TickerProviderStateMixin {
  final TextEditingController _messageController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  late AnimationController _timerAnimationController;

  @override
  void initState() {
    super.initState();
    _timerAnimationController = AnimationController(
      vsync: this,
      duration: const Duration(hours: 24),
    );

    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadChatMessages();
    });
  }

  void _loadChatMessages() {
    final chatProvider = Provider.of<ChatProvider>(context, listen: false);
    chatProvider.loadChatMessages(widget.chatId);
    _startTimerAnimation();
  }

  void _startTimerAnimation() {
    final chatProvider = Provider.of<ChatProvider>(context, listen: false);
    final remainingTime = chatProvider.getRemainingTime(widget.chatId);

    if (remainingTime != null && remainingTime.inSeconds > 0) {
      final progress = 1.0 - (remainingTime.inSeconds / (24 * 60 * 60));
      _timerAnimationController.value = progress;
      _timerAnimationController.animateTo(1.0);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Row(
          children: [
            CircleAvatar(
              backgroundColor: AppColors.primaryGold.withOpacity(0.3),
              child: const Icon(
                Icons.person,
                color: Colors.white,
              ),
            ),
            const SizedBox(width: AppSpacing.md),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('Sophie'),
                  Consumer<ChatProvider>(
                    builder: (context, chatProvider, child) {
                      final remainingTime =
                          chatProvider.getRemainingTime(widget.chatId);
                      if (remainingTime == null) return const SizedBox.shrink();

                      final isExpired =
                          chatProvider.isChatExpired(widget.chatId);
                      if (isExpired) {
                        return Text(
                          'Conversation expirée',
                          style:
                              Theme.of(context).textTheme.bodySmall?.copyWith(
                                    color: AppColors.errorRed,
                                  ),
                        );
                      }

                      final hours = remainingTime.inHours;
                      final minutes = remainingTime.inMinutes % 60;

                      return Text(
                        'Expire dans ${hours}h ${minutes}m',
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                              color: AppColors.primaryGold,
                            ),
                      );
                    },
                  ),
                ],
              ),
            ),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.info_outline),
            onPressed: _showChatInfo,
          ),
        ],
      ),
      body: Consumer<ChatProvider>(
        builder: (context, chatProvider, child) {
          final messages = chatProvider.getChatMessages(widget.chatId);
          final isExpired = chatProvider.isChatExpired(widget.chatId);

          return Column(
            children: [
              // Timer indicator
              Container(
                width: double.infinity,
                height: 4,
                child: AnimatedBuilder(
                  animation: _timerAnimationController,
                  builder: (context, child) {
                    return LinearProgressIndicator(
                      value: _timerAnimationController.value,
                      backgroundColor: AppColors.dividerLight,
                      valueColor: AlwaysStoppedAnimation<Color>(
                        isExpired ? AppColors.errorRed : AppColors.primaryGold,
                      ),
                    );
                  },
                ),
              ),

              // Messages
              Expanded(
                child: messages.isEmpty
                    ? _buildEmptyState()
                    : ListView.builder(
                        controller: _scrollController,
                        padding: const EdgeInsets.all(AppSpacing.md),
                        itemCount: messages.length,
                        itemBuilder: (context, index) {
                          final message = messages[index];
                          return _buildMessageBubble(message);
                        },
                      ),
              ),

              // Input area
              if (!isExpired) _buildMessageInput(chatProvider),
              if (isExpired) _buildExpiredMessage(),
            ],
          );
        },
      ),
    );
  }

  Widget _buildMessageBubble(Map<String, dynamic> message) {
    final isFromCurrentUser = message['isFromCurrentUser'] ?? false;
    final timestamp = message['timestamp'] as DateTime;

    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.md),
      child: Row(
        mainAxisAlignment:
            isFromCurrentUser ? MainAxisAlignment.end : MainAxisAlignment.start,
        children: [
          if (!isFromCurrentUser) ...[
            CircleAvatar(
              radius: 16,
              backgroundColor: AppColors.primaryGold.withOpacity(0.3),
              child: const Icon(
                Icons.person,
                size: 16,
                color: Colors.white,
              ),
            ),
            const SizedBox(width: AppSpacing.sm),
          ],
          Flexible(
            child: Container(
              padding: const EdgeInsets.symmetric(
                horizontal: AppSpacing.md,
                vertical: AppSpacing.sm,
              ),
              decoration: BoxDecoration(
                color: isFromCurrentUser
                    ? AppColors.primaryGold
                    : AppColors.accentCream,
                borderRadius: BorderRadius.circular(AppBorderRadius.medium),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    message['text'],
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          color: isFromCurrentUser
                              ? Colors.white
                              : AppColors.textDark,
                        ),
                  ),
                  const SizedBox(height: AppSpacing.xs),
                  Text(
                    '${timestamp.hour.toString().padLeft(2, '0')}:${timestamp.minute.toString().padLeft(2, '0')}',
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: isFromCurrentUser
                              ? Colors.white70
                              : AppColors.textSecondary,
                        ),
                  ),
                ],
              ),
            ),
          ),
          if (isFromCurrentUser) ...[
            const SizedBox(width: AppSpacing.sm),
            CircleAvatar(
              radius: 16,
              backgroundColor: AppColors.primaryGold,
              child: const Icon(
                Icons.person,
                size: 16,
                color: Colors.white,
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildMessageInput(ChatProvider chatProvider) {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: AppColors.backgroundWhite,
        border: Border(
          top: BorderSide(color: AppColors.dividerLight),
        ),
      ),
      child: Row(
        children: [
          Expanded(
            child: TextField(
              controller: _messageController,
              decoration: InputDecoration(
                hintText: 'Tapez votre message...',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(AppBorderRadius.large),
                  borderSide: BorderSide.none,
                ),
                filled: true,
                fillColor: AppColors.accentCream,
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: AppSpacing.md,
                  vertical: AppSpacing.sm,
                ),
              ),
              maxLines: null,
              textCapitalization: TextCapitalization.sentences,
            ),
          ),
          const SizedBox(width: AppSpacing.sm),
          FloatingActionButton(
            onPressed: () => _sendMessage(chatProvider),
            backgroundColor: AppColors.primaryGold,
            mini: true,
            child: const Icon(
              Icons.send,
              color: Colors.white,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildExpiredMessage() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(AppSpacing.lg),
      decoration: BoxDecoration(
        color: AppColors.errorRed.withOpacity(0.1),
        border: Border(
          top: BorderSide(color: AppColors.errorRed.withOpacity(0.3)),
        ),
      ),
      child: Column(
        children: [
          Icon(
            Icons.schedule_outlined,
            color: AppColors.errorRed,
            size: 32,
          ),
          const SizedBox(height: AppSpacing.sm),
          Text(
            'Cette conversation a expiré',
            style: Theme.of(context).textTheme.labelLarge?.copyWith(
                  color: AppColors.errorRed,
                ),
          ),
          const SizedBox(height: AppSpacing.xs),
          Text(
            'Les conversations GoldWen durent 24 heures pour encourager des échanges authentiques.',
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: AppColors.textSecondary,
                ),
            textAlign: TextAlign.center,
          ),
        ],
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
            Container(
              width: 80,
              height: 80,
              decoration: BoxDecoration(
                color: AppColors.primaryGold.withOpacity(0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(
                Icons.favorite,
                size: 40,
                color: AppColors.primaryGold,
              ),
            ),
            const SizedBox(height: AppSpacing.lg),
            Text(
              'Félicitations, c\'est un match !',
              style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                    color: AppColors.primaryGold,
                  ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: AppSpacing.md),
            Text(
              'Commencez une conversation avec Sophie. Vous avez 24 heures pour faire connaissance.',
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

  void _sendMessage(ChatProvider chatProvider) {
    final message = _messageController.text.trim();
    if (message.isNotEmpty) {
      chatProvider.sendMessage(widget.chatId, message);
      _messageController.clear();

      // Scroll to bottom
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (_scrollController.hasClients) {
          _scrollController.animateTo(
            _scrollController.position.maxScrollExtent,
            duration: const Duration(milliseconds: 300),
            curve: Curves.easeOut,
          );
        }
      });
    }
  }

  void _showChatInfo() {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppBorderRadius.large),
          ),
          title: Row(
            children: [
              Icon(
                Icons.info_outline,
                color: AppColors.primaryGold,
              ),
              const SizedBox(width: AppSpacing.sm),
              const Text('À propos de cette conversation'),
            ],
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildInfoItem(
                'Durée',
                '24 heures à partir du match',
                Icons.schedule,
              ),
              const SizedBox(height: AppSpacing.md),
              _buildInfoItem(
                'Confidentialité',
                'Messages chiffrés de bout en bout',
                Icons.security,
              ),
              const SizedBox(height: AppSpacing.md),
              Text(
                'Après expiration, cette conversation sera archivée et ne sera plus accessible.',
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: AppColors.textSecondary,
                    ),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Fermer'),
            ),
          ],
        );
      },
    );
  }

  Widget _buildInfoItem(String title, String subtitle, IconData icon) {
    return Row(
      children: [
        Icon(
          icon,
          color: AppColors.primaryGold,
          size: 20,
        ),
        const SizedBox(width: AppSpacing.sm),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: Theme.of(context).textTheme.labelLarge,
              ),
              Text(
                subtitle,
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: AppColors.textSecondary,
                    ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  @override
  void dispose() {
    _messageController.dispose();
    _scrollController.dispose();
    _timerAnimationController.dispose();
    super.dispose();
  }
}
