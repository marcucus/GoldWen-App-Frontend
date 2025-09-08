import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/widgets/animated_widgets.dart';
import '../../../core/widgets/modern_cards.dart';
import '../providers/chat_provider.dart';

class ChatListPage extends StatefulWidget {
  const ChatListPage({super.key});

  @override
  State<ChatListPage> createState() => _ChatListPageState();
}

class _ChatListPageState extends State<ChatListPage> with TickerProviderStateMixin {
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
                AppColors.gradientEnd.withOpacity(0.8 + 0.2 * _backgroundAnimation.value),
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
                      style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                        color: AppColors.textDark,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Consumer<ChatProvider>(
                      builder: (context, chatProvider, child) {
                        final unreadCount = _getSampleChats()
                            .where((chat) => chat['unreadCount'] > 0)
                            .length;
                        return Text(
                          unreadCount > 0 
                              ? '$unreadCount nouveaux messages'
                              : 'Aucun nouveau message',
                          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
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

        final chats = _getSampleChats(); // Using sample data
        
        if (chats.isEmpty) {
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
                  itemCount: chats.length,
                  itemBuilder: (context, index) {
                    final chat = chats[index];
                    return FadeInAnimation(
                      delay: Duration(milliseconds: 600 + (index * 100)),
                      child: _buildChatItem(chat, index),
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

  Widget _buildChatItem(Map<String, dynamic> chat, int index) {
    return AnimatedPressable(
      onPressed: () => _openChat(chat),
      child: Container(
        margin: const EdgeInsets.only(bottom: AppSpacing.md),
        child: GlassCard(
          margin: EdgeInsets.zero,
          padding: const EdgeInsets.all(AppSpacing.md),
          child: Row(
            children: [
              // Avatar with online status
              Stack(
                children: [
                  Container(
                    width: 56,
                    height: 56,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      gradient: LinearGradient(
                        colors: [
                          chat['avatarColor'].withOpacity(0.8),
                          chat['avatarColor'],
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
                  if (chat['isOnline'])
                    Positioned(
                      bottom: 2,
                      right: 2,
                      child: Container(
                        width: 16,
                        height: 16,
                        decoration: BoxDecoration(
                          color: AppColors.successGreen,
                          shape: BoxShape.circle,
                          border: Border.all(
                            color: Colors.white,
                            width: 2,
                          ),
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
                            chat['name'],
                            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                              fontWeight: FontWeight.w600,
                              color: AppColors.textDark,
                            ),
                          ),
                        ),
                        Text(
                          chat['time'],
                          style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            color: AppColors.textSecondary,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        if (chat['isTyping'])
                          Expanded(
                            child: _buildTypingIndicator(),
                          )
                        else
                          Expanded(
                            child: Text(
                              chat['lastMessage'],
                              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                                color: chat['unreadCount'] > 0 
                                    ? AppColors.textDark
                                    : AppColors.textSecondary,
                                fontWeight: chat['unreadCount'] > 0 
                                    ? FontWeight.w500
                                    : FontWeight.normal,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        if (chat['unreadCount'] > 0)
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: AppSpacing.sm,
                              vertical: 2,
                            ),
                            decoration: BoxDecoration(
                              gradient: AppColors.premiumGradient,
                              borderRadius: BorderRadius.circular(AppBorderRadius.small),
                            ),
                            child: Text(
                              '${chat['unreadCount']}',
                              style: Theme.of(context).textTheme.bodySmall?.copyWith(
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
              
              // Action menu
              AnimatedPressable(
                onPressed: () => _showChatMenu(chat),
                child: Container(
                  padding: const EdgeInsets.all(AppSpacing.xs),
                  decoration: BoxDecoration(
                    color: AppColors.primaryGold.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(AppBorderRadius.small),
                  ),
                  child: const Icon(
                    Icons.more_vert,
                    color: AppColors.primaryGold,
                    size: 20,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
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
                      4 * (0.5 - (_contentController.value + index * 0.3) % 1.0).abs(),
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

  void _openChat(Map<String, dynamic> chat) {
    // Navigate to chat detail page
  }

  void _showChatMenu(Map<String, dynamic> chat) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        decoration: BoxDecoration(
          color: AppColors.backgroundWhite,
          borderRadius: const BorderRadius.vertical(
            top: Radius.circular(AppBorderRadius.xLarge),
          ),
        ),
        padding: const EdgeInsets.all(AppSpacing.lg),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: AppColors.dividerLight,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(height: AppSpacing.lg),
            ListTile(
              leading: const Icon(Icons.person_outline),
              title: const Text('Voir le profil'),
              onTap: () {
                Navigator.pop(context);
              },
            ),
            ListTile(
              leading: const Icon(Icons.notifications_off_outlined),
              title: const Text('Désactiver les notifications'),
              onTap: () {
                Navigator.pop(context);
              },
            ),
            ListTile(
              leading: const Icon(Icons.delete_outline, color: AppColors.errorRed),
              title: const Text('Supprimer la conversation'),
              textColor: AppColors.errorRed,
              onTap: () {
                Navigator.pop(context);
              },
            ),
          ],
        ),
      ),
    );
  }

  List<Map<String, dynamic>> _getSampleChats() {
    return [
      {
        'name': 'Sarah',
        'lastMessage': 'Salut ! Comment ça va ?',
        'time': '14:30',
        'unreadCount': 2,
        'isOnline': true,
        'isTyping': false,
        'avatarColor': AppColors.errorRed,
      },
      {
        'name': 'Marie',
        'lastMessage': 'On se voit toujours ce soir ?',
        'time': '12:15',
        'unreadCount': 0,
        'isOnline': false,
        'isTyping': false,
        'avatarColor': AppColors.infoBlue,
      },
      {
        'name': 'Julie',
        'lastMessage': '',
        'time': '11:45',
        'unreadCount': 0,
        'isOnline': true,
        'isTyping': true,
        'avatarColor': AppColors.successGreen,
      },
      {
        'name': 'Emma',
        'lastMessage': 'Merci pour cette soirée ! 😊',
        'time': 'Hier',
        'unreadCount': 0,
        'isOnline': false,
        'isTyping': false,
        'avatarColor': AppColors.warningAmber,
      },
      {
        'name': 'Sophie',
        'lastMessage': 'À bientôt !',
        'time': 'Hier',
        'unreadCount': 1,
        'isOnline': false,
        'isTyping': false,
        'avatarColor': AppColors.primaryGold,
      },
    ];
  }
}
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