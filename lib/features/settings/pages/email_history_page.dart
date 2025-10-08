import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/models/models.dart';
import '../../../shared/widgets/loading_animation.dart';
import '../../../shared/widgets/error_message_widget.dart';
import '../../../shared/widgets/empty_state_widget.dart';
import '../providers/email_notification_provider.dart';
import '../widgets/email_notification_card.dart';

class EmailHistoryPage extends StatefulWidget {
  const EmailHistoryPage({super.key});

  @override
  State<EmailHistoryPage> createState() => _EmailHistoryPageState();
}

class _EmailHistoryPageState extends State<EmailHistoryPage>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  bool _isInitialized = false;
  final ScrollController _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _scrollController.addListener(_onScroll);
    _loadEmailHistory();
  }

  @override
  void dispose() {
    _tabController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  void _onScroll() {
    if (_scrollController.position.pixels >=
        _scrollController.position.maxScrollExtent * 0.9) {
      final provider = context.read<EmailNotificationProvider>();
      if (!provider.isLoading && provider.hasMore) {
        provider.loadMore();
      }
    }
  }

  Future<void> _loadEmailHistory() async {
    if (!_isInitialized) {
      final provider = context.read<EmailNotificationProvider>();
      await provider.loadEmailHistory();
      if (mounted) {
        setState(() {
          _isInitialized = true;
        });
      }
    }
  }

  Future<void> _handleRetry(String emailId) async {
    final provider = context.read<EmailNotificationProvider>();
    final success = await provider.retryEmail(emailId);
    
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            success
                ? 'Email retry initiated successfully'
                : 'Failed to retry email. Please try again.',
          ),
          backgroundColor: success ? Colors.green : Colors.red,
        ),
      );
    }
  }

  void _showEmailDetails(EmailNotification email) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => _EmailDetailsSheet(email: email),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.backgroundLight,
      appBar: AppBar(
        title: const Text('Email History'),
        backgroundColor: AppColors.backgroundLight,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: AppColors.textDark),
          onPressed: () => Navigator.pop(context),
        ),
        bottom: TabBar(
          controller: _tabController,
          labelColor: AppColors.primary,
          unselectedLabelColor: AppColors.textMuted,
          indicatorColor: AppColors.primary,
          tabs: const [
            Tab(text: 'All'),
            Tab(text: 'Failed'),
            Tab(text: 'Pending'),
          ],
        ),
      ),
      body: Consumer<EmailNotificationProvider>(
        builder: (context, provider, _) {
          if (provider.isLoading && !_isInitialized) {
            return const LoadingAnimation();
          }

          if (provider.error != null) {
            return ErrorMessageWidget(
              message: provider.error!,
              onRetry: () => provider.loadEmailHistory(),
            );
          }

          return TabBarView(
            controller: _tabController,
            children: [
              _buildEmailList(provider.emailHistory),
              _buildEmailList(provider.failedEmails),
              _buildEmailList(provider.pendingEmails),
            ],
          );
        },
      ),
    );
  }

  Widget _buildEmailList(List<EmailNotification> emails) {
    if (emails.isEmpty) {
      return const EmptyStateWidget(
        icon: Icons.email_outlined,
        title: 'No emails found',
        message: 'Your email history will appear here.',
      );
    }

    return RefreshIndicator(
      onRefresh: () => context.read<EmailNotificationProvider>().refresh(),
      child: ListView.builder(
        controller: _scrollController,
        padding: const EdgeInsets.all(AppSpacing.md),
        itemCount: emails.length + 1,
        itemBuilder: (context, index) {
          if (index == emails.length) {
            final provider = context.read<EmailNotificationProvider>();
            if (provider.isLoading) {
              return const Padding(
                padding: EdgeInsets.all(AppSpacing.md),
                child: Center(child: CircularProgressIndicator()),
              );
            }
            return const SizedBox.shrink();
          }

          final email = emails[index];
          return EmailNotificationCard(
            email: email,
            onTap: () => _showEmailDetails(email),
            onRetry: email.canRetry ? () => _handleRetry(email.id) : null,
          );
        },
      ),
    );
  }
}

class _EmailDetailsSheet extends StatelessWidget {
  final EmailNotification email;

  const _EmailDetailsSheet({required this.email});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        color: AppColors.backgroundLight,
        borderRadius: BorderRadius.vertical(top: Radius.circular(AppRadius.xl)),
      ),
      child: DraggableScrollableSheet(
        initialChildSize: 0.7,
        minChildSize: 0.5,
        maxChildSize: 0.9,
        builder: (context, scrollController) {
          return Column(
            children: [
              // Handle bar
              Container(
                margin: const EdgeInsets.symmetric(vertical: AppSpacing.sm),
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: AppColors.textMuted.withOpacity(0.3),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              
              // Content
              Expanded(
                child: ListView(
                  controller: scrollController,
                  padding: const EdgeInsets.all(AppSpacing.lg),
                  children: [
                    // Header
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(AppSpacing.md),
                          decoration: BoxDecoration(
                            color: email.statusColor.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(AppRadius.md),
                          ),
                          child: Icon(
                            email.typeIcon,
                            color: email.statusColor,
                            size: 32,
                          ),
                        ),
                        const SizedBox(width: AppSpacing.md),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                email.typeName,
                                style: Theme.of(context).textTheme.titleLarge?.copyWith(
                                      fontWeight: FontWeight.bold,
                                      color: AppColors.textDark,
                                    ),
                              ),
                              const SizedBox(height: AppSpacing.xs),
                              _buildStatusChip(context),
                            ],
                          ),
                        ),
                      ],
                    ),
                    
                    const SizedBox(height: AppSpacing.lg),
                    const Divider(),
                    const SizedBox(height: AppSpacing.lg),
                    
                    // Details
                    _buildDetailRow(context, 'Subject', email.subject),
                    const SizedBox(height: AppSpacing.md),
                    _buildDetailRow(context, 'Recipient', email.recipient),
                    const SizedBox(height: AppSpacing.md),
                    _buildDetailRow(context, 'Created', _formatDateTime(email.createdAt)),
                    
                    if (email.sentAt != null) ...[
                      const SizedBox(height: AppSpacing.md),
                      _buildDetailRow(context, 'Sent', _formatDateTime(email.sentAt!)),
                    ],
                    
                    if (email.deliveredAt != null) ...[
                      const SizedBox(height: AppSpacing.md),
                      _buildDetailRow(context, 'Delivered', _formatDateTime(email.deliveredAt!)),
                    ],
                    
                    if (email.hasError && email.errorMessage != null) ...[
                      const SizedBox(height: AppSpacing.lg),
                      const Divider(),
                      const SizedBox(height: AppSpacing.lg),
                      Text(
                        'Error Details',
                        style: Theme.of(context).textTheme.titleMedium?.copyWith(
                              fontWeight: FontWeight.bold,
                              color: Colors.red.shade700,
                            ),
                      ),
                      const SizedBox(height: AppSpacing.sm),
                      Container(
                        padding: const EdgeInsets.all(AppSpacing.md),
                        decoration: BoxDecoration(
                          color: Colors.red.shade50,
                          borderRadius: BorderRadius.circular(AppRadius.md),
                        ),
                        child: Text(
                          email.errorMessage!,
                          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                                color: Colors.red.shade700,
                              ),
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildStatusChip(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.sm,
        vertical: AppSpacing.xs,
      ),
      decoration: BoxDecoration(
        color: email.statusColor.withOpacity(0.1),
        borderRadius: BorderRadius.circular(AppRadius.sm),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            email.statusIcon,
            size: 16,
            color: email.statusColor,
          ),
          const SizedBox(width: AppSpacing.xs),
          Text(
            email.statusName,
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: email.statusColor,
                  fontWeight: FontWeight.w600,
                ),
          ),
        ],
      ),
    );
  }

  Widget _buildDetailRow(BuildContext context, String label, String value) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: AppColors.textMuted,
                fontWeight: FontWeight.w500,
              ),
        ),
        const SizedBox(height: AppSpacing.xs),
        Text(
          value,
          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: AppColors.textDark,
              ),
        ),
      ],
    );
  }

  String _formatDateTime(DateTime dateTime) {
    return '${dateTime.day}/${dateTime.month}/${dateTime.year} at ${dateTime.hour.toString().padLeft(2, '0')}:${dateTime.minute.toString().padLeft(2, '0')}';
  }
}
