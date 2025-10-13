import 'dart:async';
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:emoji_picker_flutter/emoji_picker_flutter.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/models/chat.dart';
import '../../../core/widgets/moderation_widgets.dart';
import '../providers/chat_provider.dart';
import '../widgets/chat_countdown_timer.dart';
import '../widgets/typing_indicator.dart';
import '../widgets/online_status_indicator.dart';
import '../../auth/providers/auth_provider.dart';

class ChatPage extends StatefulWidget {
  final String chatId;
  final bool isArchived;

  const ChatPage({
    super.key,
    required this.chatId,
    this.isArchived = false,
  });

  @override
  State<ChatPage> createState() => _ChatPageState();
}

class _ChatPageState extends State<ChatPage> with TickerProviderStateMixin {
  final TextEditingController _messageController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  late AnimationController _timerAnimationController;
  bool _showEmojiPicker = false;
  final FocusNode _focusNode = FocusNode();
  Timer? _countdownTimer;

  @override
  void initState() {
    super.initState();
    _timerAnimationController = AnimationController(
      vsync: this,
      duration: const Duration(hours: 24),
    );

    // Close emoji picker when keyboard appears
    _focusNode.addListener(() {
      if (_focusNode.hasFocus && _showEmojiPicker) {
        setState(() {
          _showEmojiPicker = false;
        });
      }
    });

    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadChatMessages();
      _startCountdownTimer();
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

  void _startCountdownTimer() {
    _countdownTimer?.cancel();
    _countdownTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      final chatProvider = Provider.of<ChatProvider>(context, listen: false);
      final remainingTime = chatProvider.getRemainingTime(widget.chatId);

      if (remainingTime == null || remainingTime.inSeconds <= 0) {
        timer.cancel();
        // Check if chat is expired and handle accordingly
        if (chatProvider.isChatExpired(widget.chatId)) {
          setState(() {
            // This will trigger a rebuild and show expired message
          });
        }
      } else {
        // Update the UI every second for countdown
        setState(() {
          // This triggers rebuild to update the timer display
        });
      }
    });
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
              child: Consumer<ChatProvider>(
                builder: (context, chatProvider, child) {
                  final conversation = chatProvider.getConversation(widget.chatId);
                  final authProvider = Provider.of<AuthProvider>(context, listen: false);
                  final currentUserId = authProvider.user?.id;
                  
                  // Get the other user's ID from the conversation participants
                  final otherUserId = conversation?.participantIds
                      .firstWhere((id) => id != currentUserId, orElse: () => '');
                  final onlineStatus = otherUserId != null && otherUserId.isNotEmpty
                      ? chatProvider.getOnlineStatus(otherUserId)
                      : null;
                  
                  return Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        conversation?.otherParticipant?.firstName ?? 'Chat',
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                          fontFamily: 'Lato',
                        ),
                      ),
                      if (onlineStatus != null)
                        OnlineStatusIndicator(
                          status: onlineStatus,
                          showText: true,
                          compact: true,
                        )
                      else if (conversation?.expiresAt != null)
                        ChatCountdownTimer(
                          expiresAt: conversation!.expiresAt!,
                          onExpired: () {
                            // Refresh chat provider when expired
                            chatProvider.clearExpiredChats();
                          },
                        ),
                    ],
                  );
                },
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
          final isReadOnly = widget.isArchived || isExpired;

          return Column(
            children: [
              // Timer indicator (only show for non-archived)
              if (!widget.isArchived)
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
              
              // Archive banner
              if (widget.isArchived)
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(
                    horizontal: AppSpacing.md,
                    vertical: AppSpacing.sm,
                  ),
                  decoration: BoxDecoration(
                    color: AppColors.errorRed.withOpacity(0.1),
                    border: Border(
                      bottom: BorderSide(
                        color: AppColors.errorRed.withOpacity(0.3),
                      ),
                    ),
                  ),
                  child: Row(
                    children: [
                      Icon(
                        Icons.archive,
                        size: 16,
                        color: AppColors.errorRed,
                      ),
                      const SizedBox(width: AppSpacing.sm),
                      Expanded(
                        child: Text(
                          'Cette conversation est archivée - Lecture seule',
                          style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                color: AppColors.errorRed,
                                fontWeight: FontWeight.w500,
                              ),
                        ),
                      ),
                    ],
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

              // Typing indicator (only show for non-archived)
              if (!widget.isArchived)
                Consumer<ChatProvider>(
                  builder: (context, chatProvider, child) {
                    final conversation = chatProvider.getConversation(widget.chatId);
                    final authProvider = Provider.of<AuthProvider>(context, listen: false);
                    final currentUserId = authProvider.user?.id;
                    
                    // Get the other user's ID
                    final otherUserId = conversation?.participantIds
                        .firstWhere((id) => id != currentUserId, orElse: () => '');
                    
                    if (otherUserId != null && 
                        otherUserId.isNotEmpty && 
                        chatProvider.isUserTyping(widget.chatId, otherUserId)) {
                      return Padding(
                        padding: const EdgeInsets.symmetric(
                          horizontal: AppSpacing.md,
                          vertical: AppSpacing.sm,
                        ),
                        child: TypingIndicator(
                          userName: conversation?.otherParticipant?.firstName ?? 'L\'utilisateur',
                        ),
                      );
                    }
                    return const SizedBox.shrink();
                  },
                ),

              // Input area or expired message
              if (!isReadOnly) _buildMessageInput(chatProvider),
              if (isReadOnly) _buildExpiredMessage(),
            ],
          );
        },
      ),
    );
  }

  Widget _buildMessageBubble(ChatMessage message) {
    // Handle system messages differently
    if (message.isSystemMessage) {
      return _buildSystemMessage(message);
    }

    // Check if message is blocked by moderation
    if (message.moderationResult != null && message.moderationResult!.isBlocked) {
      return _buildBlockedMessage(message);
    }

    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final currentUserId = authProvider.user?.id ??
        'current_user'; // Fallback to 'current_user' if no user
    final isFromCurrentUser = message.senderId == currentUserId;
    final timestamp = message.createdAt;

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
            child: Column(
              crossAxisAlignment: isFromCurrentUser 
                  ? CrossAxisAlignment.end 
                  : CrossAxisAlignment.start,
              children: [
                Container(
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
                        message.content,
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                              color: isFromCurrentUser
                                  ? Colors.white
                                  : AppColors.textDark,
                            ),
                      ),
                      const SizedBox(height: AppSpacing.xs),
                      Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            '${timestamp.hour.toString().padLeft(2, '0')}:${timestamp.minute.toString().padLeft(2, '0')}',
                            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                  color: isFromCurrentUser
                                      ? Colors.white70
                                      : AppColors.textSecondary,
                                ),
                          ),
                          if (isFromCurrentUser) ...[
                            const SizedBox(width: AppSpacing.xs),
                            Icon(
                              message.isRead ? Icons.done_all : Icons.done,
                              size: 14,
                              color: message.isRead 
                                  ? Colors.lightBlue 
                                  : Colors.white70,
                            ),
                          ],
                        ],
                      ),
                    ],
                  ),
                ),
                // Show moderation badge if pending
                if (message.moderationResult != null && 
                    message.moderationResult!.isPending) ...[
                  const SizedBox(height: 4),
                  ModerationStatusBadge(
                    moderationResult: message.moderationResult!,
                    compact: true,
                  ),
                ],
              ],
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

  Widget _buildSystemMessage(ChatMessage message) {
    return Padding(
      padding: const EdgeInsets.symmetric(
        vertical: AppSpacing.md,
        horizontal: AppSpacing.lg,
      ),
      child: Center(
        child: Container(
          padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.md,
            vertical: AppSpacing.sm,
          ),
          decoration: BoxDecoration(
            color: AppColors.errorRed.withOpacity(0.1),
            borderRadius: BorderRadius.circular(AppBorderRadius.large),
            border: Border.all(
              color: AppColors.errorRed.withOpacity(0.3),
              width: 1,
            ),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                Icons.schedule_outlined,
                color: AppColors.errorRed,
                size: 16,
              ),
              const SizedBox(width: AppSpacing.sm),
              Flexible(
                child: Text(
                  message.content,
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: AppColors.errorRed,
                        fontWeight: FontWeight.w500,
                      ),
                  textAlign: TextAlign.center,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildBlockedMessage(ChatMessage message) {
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final currentUserId = authProvider.user?.id ?? 'current_user';
    final isFromCurrentUser = message.senderId == currentUserId;

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
            child: ModerationBlockedContent(
              moderationResult: message.moderationResult!,
              resourceType: 'message',
            ),
          ),
          if (isFromCurrentUser) ...[
            const SizedBox(width: AppSpacing.sm),
            CircleAvatar(
              radius: 16,
              backgroundColor: AppColors.errorRed,
              child: const Icon(
                Icons.block,
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
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          padding: const EdgeInsets.all(AppSpacing.md),
          decoration: BoxDecoration(
            color: AppColors.backgroundWhite,
            border: Border(
              top: BorderSide(color: AppColors.dividerLight),
            ),
          ),
          child: Row(
            children: [
              // Emoji button
              IconButton(
                onPressed: () {
                  setState(() {
                    _showEmojiPicker = !_showEmojiPicker;
                  });
                  if (_showEmojiPicker) {
                    _focusNode.unfocus();
                  } else {
                    _focusNode.requestFocus();
                  }
                },
                icon: Icon(
                  _showEmojiPicker ? Icons.keyboard : Icons.emoji_emotions,
                  color: AppColors.primaryGold,
                ),
              ),
              const SizedBox(width: AppSpacing.xs),
              // Text input
              Expanded(
                child: Consumer<ChatProvider>(
                  builder: (context, chatProvider, child) {
                    final isExpired = chatProvider.isChatExpired(widget.chatId);
                    
                    return TextField(
                      controller: _messageController,
                      focusNode: _focusNode,
                      enabled: !isExpired,
                      onChanged: (text) {
                        // Trigger typing indicator
                        if (text.isNotEmpty) {
                          chatProvider.startTyping(widget.chatId);
                        } else {
                          chatProvider.stopTyping(widget.chatId);
                        }
                      },
                      onTap: () {
                        if (_showEmojiPicker) {
                          setState(() {
                            _showEmojiPicker = false;
                          });
                        }
                      },
                      decoration: InputDecoration(
                        hintText: isExpired 
                            ? 'Cette conversation a expiré' 
                            : 'Tapez votre message...',
                        border: OutlineInputBorder(
                          borderRadius:
                              BorderRadius.circular(AppBorderRadius.large),
                          borderSide: BorderSide.none,
                        ),
                        filled: true,
                        fillColor: isExpired 
                            ? AppColors.backgroundGrey 
                            : AppColors.accentCream,
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: AppSpacing.md,
                          vertical: AppSpacing.sm,
                        ),
                      ),
                      maxLines: null,
                      textCapitalization: TextCapitalization.sentences,
                      onSubmitted: isExpired ? null : (_) => _sendMessage(chatProvider),
                    );
                  },
                ),
              ),
              const SizedBox(width: AppSpacing.sm),
              // Send button
              Consumer<ChatProvider>(
                builder: (context, chatProvider, child) {
                  final isExpired = chatProvider.isChatExpired(widget.chatId);
                  
                  return FloatingActionButton(
                    onPressed: isExpired ? null : () => _sendMessage(chatProvider),
                    backgroundColor: isExpired 
                        ? AppColors.backgroundGrey 
                        : AppColors.primaryGold,
                    mini: true,
                    child: Icon(
                      Icons.send,
                      color: isExpired ? AppColors.textTertiary : Colors.white,
                    ),
                  );
                },
              ),
            ],
          ),
        ),
        // Emoji picker
        if (_showEmojiPicker)
          SizedBox(
            height: 250,
            child: EmojiPicker(
              onEmojiSelected: (category, emoji) {
                _onEmojiSelected(emoji);
              },
              config: const Config(
                height: 256,
                checkPlatformCompatibility: true,
                bottomActionBarConfig: BottomActionBarConfig(),
                skinToneConfig: SkinToneConfig(
                  dialogBackgroundColor: Colors.white,
                  indicatorColor: Colors.grey,
                ),
                categoryViewConfig: CategoryViewConfig(
                  recentTabBehavior: RecentTabBehavior.RECENT,
                ),
              ),
            ),
          ),
      ],
    );
  }

  void _onEmojiSelected(Emoji emoji) {
    final currentText = _messageController.text;
    final selection = _messageController.selection;
    final newText = currentText.replaceRange(
      selection.start,
      selection.end,
      emoji.emoji,
    );

    _messageController.text = newText;
    _messageController.selection = TextSelection.fromPosition(
      TextPosition(offset: selection.start + emoji.emoji.length),
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
      
      // Stop typing indicator since message was sent
      chatProvider.stopTyping(widget.chatId);

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
    _focusNode.dispose();
    _countdownTimer?.cancel();
    super.dispose();
  }
}
