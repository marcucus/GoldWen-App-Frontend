import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:provider/provider.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/models/models.dart';
import '../../../shared/widgets/loading_animation.dart';
import '../../../shared/widgets/error_message_widget.dart';
import '../../../shared/widgets/empty_state_widget.dart';
import '../providers/notification_provider.dart';
import '../widgets/notification_item.dart';

class NotificationsPage extends StatefulWidget {
  const NotificationsPage({super.key});

  @override
  State<NotificationsPage> createState() => _NotificationsPageState();
}

class _NotificationsPageState extends State<NotificationsPage>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  bool _isInitialized = false;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _loadNotifications();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _loadNotifications() async {
    if (!_isInitialized) {
      final provider = context.read<NotificationProvider>();
      await provider.loadNotifications();
      _isInitialized = true;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.backgroundLight,
      appBar: AppBar(
        title: const Text('Notifications'),
        backgroundColor: AppColors.backgroundLight,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: AppColors.textDark),
          onPressed: () => Navigator.pop(context),
        ),
        actions: [
          Consumer<NotificationProvider>(
            builder: (context, provider, _) {
              if (provider.unreadCount > 0) {
                return IconButton(
                  icon: const Icon(Icons.done_all, color: AppColors.primaryGold),
                  onPressed: () async {
                    await provider.markAllAsRead();
                    if (mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('All notifications marked as read'),
                          backgroundColor: AppColors.successGreen,
                        ),
                      );
                    }
                  },
                );
              }
              return const SizedBox.shrink();
            },
          ),
        ],
        bottom: TabBar(
          controller: _tabController,
          labelColor: AppColors.primaryGold,
          unselectedLabelColor: AppColors.textMuted,
          indicatorColor: AppColors.primaryGold,
          tabs: [
            Consumer<NotificationProvider>(
              builder: (context, provider, _) {
                return Tab(
                  text: provider.unreadCount > 0 
                      ? 'Non lues (${provider.unreadCount})' 
                      : 'Non lues',
                );
              },
            ),
            const Tab(text: 'Toutes'),
            const Tab(text: 'Paramètres'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _buildUnreadNotifications(),
          _buildAllNotifications(),
          _buildNotificationSettings(),
        ],
      ),
      // Add test page FAB in debug mode only
      floatingActionButton: kDebugMode ? FloatingActionButton(
        onPressed: () => Navigator.pushNamed(context, '/notifications/test'),
        backgroundColor: AppColors.primaryGold,
        child: const Icon(Icons.bug_report, color: Colors.white),
      ) : null,
    );
  }

  Widget _buildUnreadNotifications() {
    return Consumer<NotificationProvider>(
      builder: (context, provider, _) {
        if (provider.isLoading && !_isInitialized) {
          return const LoadingAnimation();
        }

        if (provider.error != null) {
          return ErrorMessageWidget(
            message: provider.error!,
            onRetry: () => provider.loadNotifications(),
          );
        }

        final unreadNotifications = provider.unreadNotifications;

        if (unreadNotifications.isEmpty) {
          return const EmptyStateWidget(
            icon: Icons.notifications_none,
            title: 'Aucune nouvelle notification',
            message: 'Vous êtes à jour ! Toutes vos notifications ont été lues.',
          );
        }

        return RefreshIndicator(
          onRefresh: () => provider.loadNotifications(),
          child: ListView.builder(
            padding: const EdgeInsets.all(AppSpacing.md),
            itemCount: unreadNotifications.length,
            itemBuilder: (context, index) {
              final notification = unreadNotifications[index];
              return NotificationItem(
                notification: notification,
                onTap: () => _handleNotificationTap(notification),
                onDismiss: () => provider.deleteNotification(notification.id),
              );
            },
          ),
        );
      },
    );
  }

  Widget _buildAllNotifications() {
    return Consumer<NotificationProvider>(
      builder: (context, provider, _) {
        if (provider.isLoading && !_isInitialized) {
          return const LoadingAnimation();
        }

        if (provider.error != null) {
          return ErrorMessageWidget(
            message: provider.error!,
            onRetry: () => provider.loadNotifications(),
          );
        }

        final notifications = provider.notifications;

        if (notifications.isEmpty) {
          return const EmptyStateWidget(
            icon: Icons.notifications_none,
            title: 'Aucune notification',
            message: 'Vous n\'avez encore reçu aucune notification.',
          );
        }

        return RefreshIndicator(
          onRefresh: () => provider.loadNotifications(),
          child: ListView.builder(
            padding: const EdgeInsets.all(AppSpacing.md),
            itemCount: notifications.length,
            itemBuilder: (context, index) {
              final notification = notifications[index];
              return NotificationItem(
                notification: notification,
                onTap: () => _handleNotificationTap(notification),
                onDismiss: () => provider.deleteNotification(notification.id),
              );
            },
          ),
        );
      },
    );
  }

  Widget _buildNotificationSettings() {
    return Consumer<NotificationProvider>(
      builder: (context, provider, _) {
        final settings = provider.settings;

        if (settings == null) {
          return const LoadingAnimation();
        }

        return SingleChildScrollView(
          padding: const EdgeInsets.all(AppSpacing.md),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Types de notifications',
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: AppColors.textDark,
                    ),
              ),
              const SizedBox(height: AppSpacing.md),
              _buildSettingsTile(
                'Sélection quotidienne',
                'Notification quotidienne à 12h pour votre sélection',
                settings.dailySelection,
                provider.toggleDailySelectionNotifications,
              ),
              _buildSettingsTile(
                'Nouveaux matchs',
                'Quand quelqu\'un flashe sur vous aussi',
                settings.newMatches,
                provider.toggleNewMatchNotifications,
              ),
              _buildSettingsTile(
                'Nouveaux messages',
                'Quand vous recevez un message',
                settings.newMessages,
                provider.toggleNewMessageNotifications,
              ),
              _buildSettingsTile(
                'Chat expirant',
                'Rappel avant l\'expiration des conversations',
                settings.chatExpiring,
                () => _toggleSetting('chatExpiring'),
              ),
              const SizedBox(height: AppSpacing.lg),
              Text(
                'Préférences générales',
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: AppColors.textDark,
                    ),
              ),
              const SizedBox(height: AppSpacing.md),
              _buildSettingsTile(
                'Notifications push',
                'Recevoir les notifications sur votre appareil',
                settings.pushEnabled,
                provider.togglePushNotifications,
              ),
              _buildSettingsTile(
                'Notifications par email',
                'Recevoir les notifications par email',
                settings.emailEnabled,
                provider.toggleEmailNotifications,
              ),
              _buildSettingsTile(
                'Son',
                'Jouer un son avec les notifications',
                settings.soundEnabled,
                () => _toggleSetting('soundEnabled'),
              ),
              _buildSettingsTile(
                'Vibration',
                'Faire vibrer l\'appareil avec les notifications',
                settings.vibrationEnabled,
                () => _toggleSetting('vibrationEnabled'),
              ),
              const SizedBox(height: AppSpacing.lg),
              _buildQuietHoursSection(settings),
            ],
          ),
        );
      },
    );
  }

  Widget _buildSettingsTile(
    String title,
    String subtitle,
    bool value,
    VoidCallback onChanged,
  ) {
    return Card(
      margin: const EdgeInsets.only(bottom: AppSpacing.sm),
      elevation: 0,
      color: AppColors.cardBackground,
      child: SwitchListTile(
        title: Text(
          title,
          style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                fontWeight: FontWeight.w600,
                color: AppColors.textDark,
              ),
        ),
        subtitle: Text(
          subtitle,
          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: AppColors.textMuted,
              ),
        ),
        value: value,
        onChanged: (_) => onChanged(),
        activeColor: AppColors.primaryGold,
      ),
    );
  }

  Widget _buildQuietHoursSection(NotificationSettings settings) {
    return Card(
      elevation: 0,
      color: AppColors.cardBackground,
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.md),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Heures de silence',
              style: Theme.of(context).textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: AppColors.textDark,
                  ),
            ),
            const SizedBox(height: AppSpacing.sm),
            Text(
              'Pas de notifications entre ${settings.quietHoursStart} et ${settings.quietHoursEnd}',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: AppColors.textMuted,
                  ),
            ),
            const SizedBox(height: AppSpacing.md),
            Row(
              children: [
                Expanded(
                  child: TextButton(
                    onPressed: () => _selectQuietHourTime(true),
                    child: Text(
                      'Début: ${settings.quietHoursStart}',
                      style: const TextStyle(color: AppColors.primaryGold),
                    ),
                  ),
                ),
                Expanded(
                  child: TextButton(
                    onPressed: () => _selectQuietHourTime(false),
                    child: Text(
                      'Fin: ${settings.quietHoursEnd}',
                      style: const TextStyle(color: AppColors.primaryGold),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  void _handleNotificationTap(AppNotification notification) {
    final provider = context.read<NotificationProvider>();
    
    // Mark as read if not already
    if (!notification.isRead) {
      provider.markAsRead(notification.id);
    }

    // Navigate based on notification type
    switch (notification.type) {
      case 'daily_selection':
        Navigator.pushNamed(context, '/discover');
        break;
      case 'new_match':
        Navigator.pushNamed(context, '/matches');
        break;
      case 'new_message':
        final conversationId = notification.data?['conversationId'];
        if (conversationId != null) {
          Navigator.pushNamed(context, '/chat/$conversationId');
        }
        break;
      case 'chat_expiring':
        final conversationId = notification.data?['conversationId'];
        if (conversationId != null) {
          Navigator.pushNamed(context, '/chat/$conversationId');
        }
        break;
      default:
        // Stay on notifications page for system notifications
        break;
    }
  }

  void _toggleSetting(String settingKey) {
    final provider = context.read<NotificationProvider>();
    final settings = provider.settings;
    if (settings == null) return;

    NotificationSettings newSettings;
    switch (settingKey) {
      case 'chatExpiring':
        newSettings = settings.copyWith(chatExpiring: !settings.chatExpiring);
        break;
      case 'soundEnabled':
        newSettings = settings.copyWith(soundEnabled: !settings.soundEnabled);
        break;
      case 'vibrationEnabled':
        newSettings = settings.copyWith(vibrationEnabled: !settings.vibrationEnabled);
        break;
      default:
        return;
    }

    provider.updateNotificationSettings(newSettings);
  }

  Future<void> _selectQuietHourTime(bool isStart) async {
    final provider = context.read<NotificationProvider>();
    final settings = provider.settings;
    if (settings == null) return;

    final currentTime = isStart 
        ? TimeOfDay(
            hour: int.parse(settings.quietHoursStart.split(':')[0]),
            minute: int.parse(settings.quietHoursStart.split(':')[1]),
          )
        : TimeOfDay(
            hour: int.parse(settings.quietHoursEnd.split(':')[0]),
            minute: int.parse(settings.quietHoursEnd.split(':')[1]),
          );

    final TimeOfDay? selectedTime = await showTimePicker(
      context: context,
      initialTime: currentTime,
    );

    if (selectedTime != null) {
      final timeString = '${selectedTime.hour.toString().padLeft(2, '0')}:${selectedTime.minute.toString().padLeft(2, '0')}';
      
      final newSettings = isStart
          ? settings.copyWith(quietHoursStart: timeString)
          : settings.copyWith(quietHoursEnd: timeString);
      
      await provider.updateNotificationSettings(newSettings);
    }
  }
}