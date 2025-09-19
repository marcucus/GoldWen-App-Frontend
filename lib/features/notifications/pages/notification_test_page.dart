import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/services/local_notification_service.dart';
import '../../../core/services/firebase_messaging_service.dart';
import '../providers/notification_provider.dart';

class NotificationTestPage extends StatefulWidget {
  const NotificationTestPage({super.key});

  @override
  State<NotificationTestPage> createState() => _NotificationTestPageState();
}

class _NotificationTestPageState extends State<NotificationTestPage> {
  final LocalNotificationService _localNotificationService = LocalNotificationService();
  final FirebaseMessagingService _firebaseMessagingService = FirebaseMessagingService();
  
  final _titleController = TextEditingController();
  final _bodyController = TextEditingController();
  String _selectedType = 'daily_selection';
  
  final List<String> _notificationTypes = [
    'daily_selection',
    'new_match',
    'new_message',
    'chat_expiring',
    'system',
  ];

  @override
  void initState() {
    super.initState();
    _titleController.text = 'Test Notification';
    _bodyController.text = 'This is a test notification from GoldWen';
  }

  @override
  void dispose() {
    _titleController.dispose();
    _bodyController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.backgroundLight,
      appBar: AppBar(
        title: const Text('Test Notifications'),
        backgroundColor: AppColors.backgroundLight,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: AppColors.textDark),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(AppSpacing.md),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // System Status
            _buildSystemStatus(),
            
            const SizedBox(height: AppSpacing.lg),
            
            // Test Notification Form
            _buildTestForm(),
            
            const SizedBox(height: AppSpacing.lg),
            
            // Quick Test Buttons
            _buildQuickTests(),
            
            const SizedBox(height: AppSpacing.lg),
            
            // Scheduled Notifications
            _buildScheduledNotifications(),
          ],
        ),
      ),
    );
  }

  Widget _buildSystemStatus() {
    return Card(
      elevation: 0,
      color: AppColors.cardBackground,
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.md),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'System Status',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: AppColors.textDark,
                  ),
            ),
            const SizedBox(height: AppSpacing.md),
            _buildStatusItem(
              'Firebase Messaging',
              _firebaseMessagingService.isInitialized,
              'FCM Token: ${_firebaseMessagingService.deviceToken?.substring(0, 20) ?? 'Not available'}...',
            ),
            _buildStatusItem(
              'Local Notifications',
              true,
              'Permission requested and available',
            ),
            Consumer<NotificationProvider>(
              builder: (context, provider, _) {
                return _buildStatusItem(
                  'Notification Provider',
                  !provider.isLoading,
                  'Unread: ${provider.unreadCount}',
                );
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatusItem(String title, bool isWorking, String subtitle) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: AppSpacing.xs),
      child: Row(
        children: [
          Icon(
            isWorking ? Icons.check_circle : Icons.error,
            color: isWorking ? AppColors.successGreen : AppColors.errorRed,
            size: 20,
          ),
          const SizedBox(width: AppSpacing.sm),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        fontWeight: FontWeight.w600,
                        color: AppColors.textDark,
                      ),
                ),
                Text(
                  subtitle,
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: AppColors.textMuted,
                      ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTestForm() {
    return Card(
      elevation: 0,
      color: AppColors.cardBackground,
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.md),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Custom Test Notification',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: AppColors.textDark,
                  ),
            ),
            const SizedBox(height: AppSpacing.md),
            
            // Notification Type Dropdown
            DropdownButtonFormField<String>(
              value: _selectedType,
              decoration: const InputDecoration(
                labelText: 'Notification Type',
                border: OutlineInputBorder(),
              ),
              items: _notificationTypes.map((type) {
                return DropdownMenuItem(
                  value: type,
                  child: Text(_getTypeDisplayName(type)),
                );
              }).toList(),
              onChanged: (value) {
                setState(() {
                  _selectedType = value!;
                  _updateFormForType(value);
                });
              },
            ),
            
            const SizedBox(height: AppSpacing.md),
            
            // Title Field
            TextField(
              controller: _titleController,
              decoration: const InputDecoration(
                labelText: 'Notification Title',
                border: OutlineInputBorder(),
              ),
            ),
            
            const SizedBox(height: AppSpacing.md),
            
            // Body Field
            TextField(
              controller: _bodyController,
              decoration: const InputDecoration(
                labelText: 'Notification Body',
                border: OutlineInputBorder(),
              ),
              maxLines: 3,
            ),
            
            const SizedBox(height: AppSpacing.md),
            
            // Send Button
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _sendTestNotification,
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primaryGold,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: AppSpacing.md),
                ),
                child: const Text('Send Test Notification'),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildQuickTests() {
    return Card(
      elevation: 0,
      color: AppColors.cardBackground,
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.md),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Quick Tests',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: AppColors.textDark,
                  ),
            ),
            const SizedBox(height: AppSpacing.md),
            
            Wrap(
              spacing: AppSpacing.sm,
              runSpacing: AppSpacing.sm,
              children: [
                _buildQuickTestButton(
                  'Daily Selection',
                  'daily_selection',
                  'Votre sélection du jour est prête !',
                  '3 nouveaux profils compatibles vous attendent',
                ),
                _buildQuickTestButton(
                  'New Match',
                  'new_match',
                  'Vous avez un match !',
                  'Sophie a aussi flashé sur vous',
                ),
                _buildQuickTestButton(
                  'New Message',
                  'new_message',
                  'Nouveau message de Sophie',
                  'Salut ! Comment ça va ?',
                ),
                _buildQuickTestButton(
                  'Chat Expiring',
                  'chat_expiring',
                  'Votre conversation expire bientôt',
                  'Plus que 2h pour discuter avec Sophie',
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildQuickTestButton(String label, String type, String title, String body) {
    return ElevatedButton(
      onPressed: () => _sendQuickTest(type, title, body),
      style: ElevatedButton.styleFrom(
        backgroundColor: AppColors.primaryGold.withOpacity(0.1),
        foregroundColor: AppColors.primaryGold,
        elevation: 0,
      ),
      child: Text(label),
    );
  }

  Widget _buildScheduledNotifications() {
    return Card(
      elevation: 0,
      color: AppColors.cardBackground,
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.md),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Scheduled Notifications',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: AppColors.textDark,
                  ),
            ),
            const SizedBox(height: AppSpacing.md),
            
            Row(
              children: [
                Expanded(
                  child: ElevatedButton(
                    onPressed: _scheduleDailySelection,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.successGreen,
                      foregroundColor: Colors.white,
                    ),
                    child: const Text('Schedule Daily Selection'),
                  ),
                ),
                const SizedBox(width: AppSpacing.sm),
                Expanded(
                  child: ElevatedButton(
                    onPressed: _cancelAllNotifications,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.errorRed,
                      foregroundColor: Colors.white,
                    ),
                    child: const Text('Cancel All'),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  String _getTypeDisplayName(String type) {
    switch (type) {
      case 'daily_selection':
        return 'Daily Selection';
      case 'new_match':
        return 'New Match';
      case 'new_message':
        return 'New Message';
      case 'chat_expiring':
        return 'Chat Expiring';
      case 'system':
        return 'System';
      default:
        return type;
    }
  }

  void _updateFormForType(String type) {
    switch (type) {
      case 'daily_selection':
        _titleController.text = 'Votre sélection du jour est prête !';
        _bodyController.text = '3 nouveaux profils compatibles vous attendent';
        break;
      case 'new_match':
        _titleController.text = 'Vous avez un match !';
        _bodyController.text = 'Sophie a aussi flashé sur vous';
        break;
      case 'new_message':
        _titleController.text = 'Nouveau message de Sophie';
        _bodyController.text = 'Salut ! Comment ça va ?';
        break;
      case 'chat_expiring':
        _titleController.text = 'Votre conversation expire bientôt';
        _bodyController.text = 'Plus que 2h pour discuter avec Sophie';
        break;
      case 'system':
        _titleController.text = 'Notification système';
        _bodyController.text = 'Mise à jour disponible';
        break;
    }
  }

  Future<void> _sendTestNotification() async {
    try {
      await _localNotificationService.showTypedNotification(
        type: _selectedType,
        title: _titleController.text,
        body: _bodyController.text,
      );
      
      _showSnackBar('Test notification sent successfully', AppColors.successGreen);
    } catch (e) {
      _showSnackBar('Failed to send notification: $e', AppColors.errorRed);
    }
  }

  Future<void> _sendQuickTest(String type, String title, String body) async {
    try {
      await _localNotificationService.showTypedNotification(
        type: type,
        title: title,
        body: body,
      );
      
      _showSnackBar('$type notification sent', AppColors.successGreen);
    } catch (e) {
      _showSnackBar('Failed to send notification: $e', AppColors.errorRed);
    }
  }

  Future<void> _scheduleDailySelection() async {
    try {
      await _localNotificationService.scheduleDailySelectionNotification();
      _showSnackBar('Daily selection notification scheduled', AppColors.successGreen);
    } catch (e) {
      _showSnackBar('Failed to schedule notification: $e', AppColors.errorRed);
    }
  }

  Future<void> _cancelAllNotifications() async {
    try {
      await _localNotificationService.cancelAll();
      _showSnackBar('All notifications cancelled', AppColors.successGreen);
    } catch (e) {
      _showSnackBar('Failed to cancel notifications: $e', AppColors.errorRed);
    }
  }

  void _showSnackBar(String message, Color color) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: color,
      ),
    );
  }
}