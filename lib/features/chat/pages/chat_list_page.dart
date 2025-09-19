import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/widgets/animated_widgets.dart';
import '../../../core/widgets/modern_cards.dart';
import '../providers/chat_provider.dart';
import '../../../core/models/chat.dart';

class ChatListPage extends StatefulWidget {
  const ChatListPage({super.key});

  @override
  State<ChatListPage> createState() => _ChatListPageState();
}

class _ChatListPageState extends State<ChatListPage>
    with TickerProviderStateMixin {
  late AnimationController _backgroundController;
  late AnimationController _contentController;
  late Animation<double> _backgroundAnimation;
  final TextEditingController _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _initializeAnimations();
    _loadChats();
    _startAnimations();
  }

  void _initializeAnimations() {
    _backgroundController = AnimationController(
      duration: AppAnimations.verySlow,
      vsync: this,
    );
    _contentController = AnimationController(
      duration: AppAnimations.medium,
      vsync: this,
    );

    _backgroundAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _backgroundController,
      curve: AppAnimations.easeInOut,
    ));
  }

  void _startAnimations() {
    _backgroundController.forward();
    Future.delayed(const Duration(milliseconds: 300), () {
      _contentController.forward();
    });
  }

  @override
  void dispose() {
    _backgroundController.dispose();
    _contentController.dispose();
    _searchController.dispose();
    super.dispose();
  }

  void _loadChats() {
    final chatProvider = Provider.of<ChatProvider>(context, listen: false);
    chatProvider.loadConversations();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _backgroundAnimation,
      builder: (context, child) {
        return Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [
                AppColors.gradientStart,
                AppColors.gradientMiddle,
                AppColors.gradientEnd
                    .withOpacity(0.8 + 0.2 * _backgroundAnimation.value),
              ],
              stops: const [0.0, 0.4, 1.0],
            ),
          ),
          child: SafeArea(
            child: Column(
              children: [
                _buildAnimatedHeader(),
                _buildSearchBar(),
                Expanded(
                  child: _buildChatList(),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildAnimatedHeader() {
    return FadeInAnimation(
      delay: const Duration(milliseconds: 200),
      child: Container(
        margin: const EdgeInsets.all(AppSpacing.lg),
        child: GlassCard(
          borderRadius: AppBorderRadius.xLarge,
          padding: const EdgeInsets.all(AppSpacing.lg),
          child: Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Messages',
                      style:
                          Theme.of(context).textTheme.headlineSmall?.copyWith(
                                color: AppColors.textDark,
                                fontWeight: FontWeight.bold,
                              ),
                    ),
                    const SizedBox(height: 4),
                    Consumer<ChatProvider>(
                      builder: (context, chatProvider, child) {
                        final unreadCount = chatProvider.conversations
                            .where((chat) => chat.unreadCount > 0)
                            .length;
                        return Text(
                          unreadCount > 0
                              ? '$unreadCount nouveaux messages'
                              : 'Aucun nouveau message',
                          style:
                              Theme.of(context).textTheme.bodyMedium?.copyWith(
                                    color: AppColors.textSecondary,
                                  ),
                        );
                      },
                    ),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.all(AppSpacing.sm),
                decoration: BoxDecoration(
                  gradient: AppColors.premiumGradient,
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.chat_bubble,
                  color: Colors.white,
                  size: 24,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSearchBar() {
    return SlideInAnimation(
      delay: const Duration(milliseconds: 400),
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
        child: AnimatedSearchBar(
          controller: _searchController,
          hintText: 'Rechercher dans les conversations...',
          onChanged: (value) {
            // Handle search
          },
        ),
      ),
    );
  }

  Widget _buildChatList() {
    return Consumer<ChatProvider>(
      builder: (context, chatProvider, child) {
        if (chatProvider.isLoading) {
          return _buildLoadingState();
        }

        final conversations = chatProvider.conversations;

        if (conversations.isEmpty) {
          return _buildEmptyState();
        }

        return Container(
          margin: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
          child: Column(
            children: [
              const SizedBox(height: AppSpacing.lg),
              Expanded(
                child: ListView.builder(
                  physics: const BouncingScrollPhysics(),
                  itemCount: conversations.length,
                  itemBuilder: (context, index) {
                    final conversation = conversations[index];
                    return FadeInAnimation(
                      delay: Duration(milliseconds: 600 + (index * 100)),
                      child: _buildConversationItem(conversation, index),
                    );
                  },
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildConversationItem(Conversation conversation, int index) {
    final isExpired = conversation.isExpired;
    final remainingTime = isExpired ? null : _formatRemainingTime(conversation);
    
    return AnimatedPressable(
      onPressed: () => _openConversation(conversation),
      child: Container(
        margin: const EdgeInsets.only(bottom: AppSpacing.md),
        child: GlassCard(
          margin: EdgeInsets.zero,
          padding: const EdgeInsets.all(AppSpacing.md),
          child: Row(
            children: [
              // Avatar
              Container(
                width: 56,
                height: 56,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: LinearGradient(
                    colors: [
                      AppColors.primaryGold.withOpacity(0.8),
                      AppColors.primaryGold,
                    ],
                  ),
                  boxShadow: AppShadows.soft,
                ),
                child: const Icon(
                  Icons.person,
                  color: Colors.white,
                  size: 28,
                ),
              ),

              const SizedBox(width: AppSpacing.md),

              // Conversation info
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            conversation.otherParticipant?.firstName ?? 'Utilisateur',
                            style: Theme.of(context)
                                .textTheme
                                .titleMedium
                                ?.copyWith(
                                  fontWeight: FontWeight.w600,
                                  color: AppColors.textDark,
                                ),
                          ),
                        ),
                        if (remainingTime != null)
                          Text(
                            remainingTime,
                            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                  color: AppColors.primaryGold,
                                  fontWeight: FontWeight.bold,
                                ),
                          ),
                        if (isExpired)
                          Text(
                            'Expiré',
                            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                  color: AppColors.errorRed,
                                  fontWeight: FontWeight.bold,
                                ),
                          ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            conversation.lastMessage?.content ?? 
                            (isExpired ? 'Conversation expirée' : 'Félicitations! Vous avez un match'),
                            style: Theme.of(context)
                                .textTheme
                                .bodyMedium
                                ?.copyWith(
                                  color: conversation.hasUnreadMessages
                                      ? AppColors.textDark
                                      : AppColors.textSecondary,
                                  fontWeight: conversation.hasUnreadMessages
                                      ? FontWeight.w500
                                      : FontWeight.normal,
                                  fontStyle: isExpired ? FontStyle.italic : null,
                                ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        if (conversation.hasUnreadMessages && !isExpired)
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: AppSpacing.sm,
                              vertical: 2,
                            ),
                            decoration: BoxDecoration(
                              gradient: AppColors.premiumGradient,
                              borderRadius:
                                  BorderRadius.circular(AppBorderRadius.small),
                            ),
                            child: Text(
                              '${conversation.unreadCount}',
                              style: Theme.of(context)
                                  .textTheme
                                  .bodySmall
                                  ?.copyWith(
                                    color: Colors.white,
                                    fontWeight: FontWeight.bold,
                                  ),
                            ),
                          ),
                      ],
                    ),
                  ],
                ),
              ),

              const SizedBox(width: AppSpacing.sm),

              // Status icon
              Icon(
                isExpired ? Icons.schedule_outlined : Icons.message,
                color: isExpired ? AppColors.errorRed : AppColors.primaryGold,
                size: 20,
              ),
            ],
          ),
        ),
      ),
    );
  }

  String _formatRemainingTime(Conversation conversation) {
    if (conversation.expiresAt == null) return '';
    
    final remaining = conversation.expiresAt!.difference(DateTime.now());
    if (remaining.isNegative) return '';
    
    final hours = remaining.inHours;
    final minutes = remaining.inMinutes % 60;
    
    return '${hours.toString().padLeft(2, '0')}:${minutes.toString().padLeft(2, '0')}';
  }

  Widget _buildTypingIndicator() {
    return Row(
      children: [
        Text(
          'En train d\'écrire',
          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: AppColors.primaryGold,
                fontStyle: FontStyle.italic,
                fontWeight: FontWeight.w500,
              ),
        ),
        const SizedBox(width: 4),
        SizedBox(
          width: 20,
          height: 20,
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: List.generate(3, (index) {
              return AnimatedBuilder(
                animation: _contentController,
                builder: (context, child) {
                  return Transform.translate(
                    offset: Offset(
                      0,
                      4 *
                          (0.5 - (_contentController.value + index * 0.3) % 1.0)
                              .abs(),
                    ),
                    child: Container(
                      width: 4,
                      height: 4,
                      decoration: BoxDecoration(
                        color: AppColors.primaryGold,
                        shape: BoxShape.circle,
                      ),
                    ),
                  );
                },
              );
            }),
          ),
        ),
      ],
    );
  }

  Widget _buildLoadingState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: 60,
            height: 60,
            padding: const EdgeInsets.all(AppSpacing.md),
            decoration: BoxDecoration(
              gradient: AppColors.premiumGradient,
              shape: BoxShape.circle,
            ),
            child: const CircularProgressIndicator(
              valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
              strokeWidth: 3,
            ),
          ),
          const SizedBox(height: AppSpacing.lg),
          Text(
            'Chargement des conversations...',
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  color: AppColors.textLight,
                  fontWeight: FontWeight.w600,
                ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.xl),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(AppSpacing.xl),
              decoration: BoxDecoration(
                gradient: AppColors.premiumGradient,
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.chat_bubble_outline,
                size: 60,
                color: Colors.white,
              ),
            ),
            const SizedBox(height: AppSpacing.xl),
            Text(
              'Aucune conversation',
              style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                    color: AppColors.textLight,
                    fontWeight: FontWeight.bold,
                  ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: AppSpacing.md),
            Text(
              'Commencez à matcher pour recevoir vos premiers messages !',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: AppColors.textLight.withOpacity(0.8),
                  ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: AppSpacing.xl),
            PremiumButton(
              text: 'Découvrir des profils',
              onPressed: () {
                // Navigate to discover page
              },
              gradient: LinearGradient(
                colors: [
                  Colors.white.withOpacity(0.9),
                  Colors.white,
                ],
              ),
              textColor: AppColors.primaryGold,
            ),
          ],
        ),
      ),
    );
  }

  void _openConversation(Conversation conversation) {
    if (conversation.isExpired) {
      // Show expired conversation message
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Cette conversation a expiré'),
          backgroundColor: AppColors.errorRed,
        ),
      );
      return;
    }
    
    // Navigate to chat detail page
    context.push('/chat/${conversation.id}');
  }

}
