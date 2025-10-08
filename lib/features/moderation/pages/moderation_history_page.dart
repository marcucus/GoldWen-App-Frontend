import 'package:flutter/material.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/models/moderation.dart';
import '../../../core/services/moderation_service.dart';
import '../../../core/widgets/moderation_widgets.dart';

/// Page to display moderation history for the current user
class ModerationHistoryPage extends StatefulWidget {
  const ModerationHistoryPage({super.key});

  @override
  State<ModerationHistoryPage> createState() => _ModerationHistoryPageState();
}

class _ModerationHistoryPageState extends State<ModerationHistoryPage> {
  List<ModerationHistoryItem> _historyItems = [];
  bool _isLoading = false;
  String? _error;
  int _currentPage = 1;
  bool _hasMore = true;
  final ScrollController _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    _loadHistory();
    _scrollController.addListener(_onScroll);
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  void _onScroll() {
    if (_scrollController.position.pixels >= 
        _scrollController.position.maxScrollExtent * 0.8) {
      if (!_isLoading && _hasMore) {
        _loadMore();
      }
    }
  }

  Future<void> _loadHistory() async {
    if (_isLoading) return;

    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final items = await ModerationService.getModerationHistory(
        page: 1,
        limit: 20,
      );

      if (mounted) {
        setState(() {
          _historyItems = items;
          _currentPage = 1;
          _hasMore = items.length >= 20;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _error = 'Erreur lors du chargement de l\'historique';
          _isLoading = false;
        });
      }
    }
  }

  Future<void> _loadMore() async {
    if (_isLoading || !_hasMore) return;

    setState(() {
      _isLoading = true;
    });

    try {
      final items = await ModerationService.getModerationHistory(
        page: _currentPage + 1,
        limit: 20,
      );

      if (mounted) {
        setState(() {
          _historyItems.addAll(items);
          _currentPage++;
          _hasMore = items.length >= 20;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.backgroundCream,
      appBar: AppBar(
        title: Text(
          'Historique de Modération',
          style: Theme.of(context).textTheme.headlineSmall?.copyWith(
            fontWeight: FontWeight.bold,
            color: AppColors.textDark,
          ),
        ),
        backgroundColor: AppColors.backgroundCream,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: AppColors.textDark),
          onPressed: () => Navigator.of(context).pop(),
        ),
      ),
      body: RefreshIndicator(
        onRefresh: _loadHistory,
        child: _buildBody(),
      ),
    );
  }

  Widget _buildBody() {
    if (_isLoading && _historyItems.isEmpty) {
      return const Center(
        child: CircularProgressIndicator(
          valueColor: AlwaysStoppedAnimation<Color>(AppColors.primaryGold),
        ),
      );
    }

    if (_error != null && _historyItems.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(
              Icons.error_outline,
              size: 64,
              color: AppColors.errorRed,
            ),
            const SizedBox(height: 16),
            Text(
              _error!,
              style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                color: AppColors.errorRed,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: _loadHistory,
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primaryGold,
                foregroundColor: Colors.white,
              ),
              child: const Text('Réessayer'),
            ),
          ],
        ),
      );
    }

    if (_historyItems.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(32.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.verified_user,
                size: 80,
                color: AppColors.primaryGold.withOpacity(0.5),
              ),
              const SizedBox(height: 24),
              Text(
                'Aucune action de modération',
                style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: AppColors.textDark,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 16),
              Text(
                'Tout votre contenu est conforme à nos règles de communauté.',
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

    return ListView.builder(
      controller: _scrollController,
      padding: const EdgeInsets.all(16),
      itemCount: _historyItems.length + (_isLoading ? 1 : 0),
      itemBuilder: (context, index) {
        if (index >= _historyItems.length) {
          return const Padding(
            padding: EdgeInsets.all(16.0),
            child: Center(
              child: CircularProgressIndicator(
                valueColor: AlwaysStoppedAnimation<Color>(AppColors.primaryGold),
              ),
            ),
          );
        }

        final item = _historyItems[index];
        return _buildHistoryItem(item);
      },
    );
  }

  Widget _buildHistoryItem(ModerationHistoryItem item) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                _buildResourceTypeIcon(item.resourceType),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        _getResourceTypeLabel(item.resourceType),
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                          color: AppColors.textDark,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        _formatDate(item.createdAt),
                        style: const TextStyle(
                          fontSize: 12,
                          color: AppColors.textSecondary,
                        ),
                      ),
                    ],
                  ),
                ),
                ModerationStatusBadge(
                  moderationResult: item.result,
                  showLabel: true,
                ),
              ],
            ),
            if (item.result.hasFlags) ...[
              const SizedBox(height: 12),
              const Divider(color: AppColors.dividerLight),
              const SizedBox(height: 12),
              const Text(
                'Raisons de la modération:',
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: AppColors.textSecondary,
                ),
              ),
              const SizedBox(height: 8),
              ModerationFlagsWidget(
                flags: item.result.flags,
                showConfidence: true,
              ),
            ],
            if (item.result.isBlocked) ...[
              const SizedBox(height: 12),
              SizedBox(
                width: double.infinity,
                child: OutlinedButton.icon(
                  onPressed: () => _showAppealDialog(item),
                  icon: const Icon(Icons.feedback, size: 16),
                  label: const Text('Faire appel'),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: AppColors.primaryGold,
                    side: const BorderSide(color: AppColors.primaryGold),
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildResourceTypeIcon(String resourceType) {
    IconData icon;
    Color color;

    switch (resourceType) {
      case 'message':
        icon = Icons.message;
        color = AppColors.infoBlue;
        break;
      case 'photo':
        icon = Icons.photo;
        color = AppColors.primaryGold;
        break;
      case 'bio':
        icon = Icons.description;
        color = AppColors.successGreen;
        break;
      default:
        icon = Icons.help_outline;
        color = AppColors.textSecondary;
    }

    return Container(
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Icon(icon, color: color, size: 24),
    );
  }

  String _getResourceTypeLabel(String resourceType) {
    switch (resourceType) {
      case 'message':
        return 'Message';
      case 'photo':
        return 'Photo de profil';
      case 'bio':
        return 'Biographie';
      default:
        return 'Contenu';
    }
  }

  String _formatDate(DateTime date) {
    final now = DateTime.now();
    final difference = now.difference(date);

    if (difference.inDays == 0) {
      if (difference.inHours == 0) {
        return 'Il y a ${difference.inMinutes} minutes';
      }
      return 'Il y a ${difference.inHours} heures';
    } else if (difference.inDays == 1) {
      return 'Hier';
    } else if (difference.inDays < 7) {
      return 'Il y a ${difference.inDays} jours';
    } else {
      return '${date.day}/${date.month}/${date.year}';
    }
  }

  void _showAppealDialog(ModerationHistoryItem item) {
    final reasonController = TextEditingController();

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Faire appel de la décision'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Expliquez pourquoi vous pensez que cette décision est incorrecte:',
              style: Theme.of(context).textTheme.bodyMedium,
            ),
            const SizedBox(height: 16),
            TextField(
              controller: reasonController,
              maxLines: 4,
              maxLength: 500,
              decoration: const InputDecoration(
                hintText: 'Votre raison...',
                border: OutlineInputBorder(),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Annuler'),
          ),
          ElevatedButton(
            onPressed: () async {
              if (reasonController.text.trim().isEmpty) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Veuillez fournir une raison'),
                    backgroundColor: AppColors.errorRed,
                  ),
                );
                return;
              }

              final success = await ModerationService.appealModerationDecision(
                resourceType: item.resourceType,
                resourceId: item.resourceId,
                reason: reasonController.text.trim(),
              );

              if (context.mounted) {
                Navigator.of(context).pop();
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(
                      success
                          ? 'Votre appel a été soumis avec succès'
                          : 'Erreur lors de la soumission de l\'appel',
                    ),
                    backgroundColor: success ? AppColors.successGreen : AppColors.errorRed,
                  ),
                );
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primaryGold,
              foregroundColor: Colors.white,
            ),
            child: const Text('Soumettre'),
          ),
        ],
      ),
    );
  }
}
