import 'package:flutter/material.dart';
import '../../../core/theme/app_theme.dart';

class AdminSupportPage extends StatefulWidget {
  const AdminSupportPage({super.key});

  @override
  State<AdminSupportPage> createState() => _AdminSupportPageState();
}

class _AdminSupportPageState extends State<AdminSupportPage> with TickerProviderStateMixin {
  late TabController _tabController;
  final List<SupportTicket> _tickets = _generateMockTickets();

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.backgroundWhite,
      appBar: AppBar(
        title: const Text('Support Utilisateur'),
        backgroundColor: AppColors.primaryGold,
        foregroundColor: Colors.white,
        elevation: 2,
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: Colors.white,
          labelColor: Colors.white,
          unselectedLabelColor: Colors.white70,
          tabs: const [
            Tab(text: 'Ouvert', icon: Icon(Icons.inbox)),
            Tab(text: 'En cours', icon: Icon(Icons.work)),
            Tab(text: 'Fermé', icon: Icon(Icons.check_circle)),
          ],
        ),
      ),
      body: Column(
        children: [
          // Stats Section
          Container(
            padding: const EdgeInsets.all(AppSpacing.lg),
            decoration: BoxDecoration(
              color: Colors.white,
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.05),
                  blurRadius: 4,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Row(
              children: [
                _StatCard(
                  title: 'Ouverts',
                  count: _getTicketsByStatus('open').length,
                  color: AppColors.warningAmber,
                  icon: Icons.inbox,
                ),
                const SizedBox(width: AppSpacing.md),
                _StatCard(
                  title: 'En cours',
                  count: _getTicketsByStatus('in_progress').length,
                  color: AppColors.infoBlue,
                  icon: Icons.work,
                ),
                const SizedBox(width: AppSpacing.md),
                _StatCard(
                  title: 'Fermés (7j)',
                  count: _getTicketsByStatus('closed').length,
                  color: AppColors.successGreen,
                  icon: Icons.check_circle,
                ),
              ],
            ),
          ),
          
          // Tickets List
          Expanded(
            child: TabBarView(
              controller: _tabController,
              children: [
                _buildTicketsList('open'),
                _buildTicketsList('in_progress'),
                _buildTicketsList('closed'),
              ],
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _showBroadcastDialog(),
        backgroundColor: AppColors.primaryGold,
        icon: const Icon(Icons.announcement),
        label: const Text('Annonce globale'),
      ),
    );
  }

  Widget _buildTicketsList(String status) {
    final tickets = _getTicketsByStatus(status);

    if (tickets.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              _getStatusIcon(status),
              size: 64,
              color: AppColors.textTertiary,
            ),
            const SizedBox(height: AppSpacing.lg),
            Text(
              _getEmptyMessage(status),
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: AppSpacing.md),
            Text(
              'Aucun ticket dans cette catégorie',
              style: TextStyle(color: AppColors.textSecondary),
            ),
          ],
        ),
      );
    }

    return ListView.separated(
      padding: const EdgeInsets.all(AppSpacing.md),
      itemCount: tickets.length,
      separatorBuilder: (context, index) => const SizedBox(height: AppSpacing.sm),
      itemBuilder: (context, index) {
        final ticket = tickets[index];
        return _SupportTicketCard(
          ticket: ticket,
          onTap: () => _showTicketDetails(ticket),
          onStatusChanged: (newStatus) => _updateTicketStatus(ticket, newStatus),
        );
      },
    );
  }

  List<SupportTicket> _getTicketsByStatus(String status) {
    return _tickets.where((ticket) => ticket.status == status).toList();
  }

  IconData _getStatusIcon(String status) {
    switch (status) {
      case 'open':
        return Icons.inbox;
      case 'in_progress':
        return Icons.work;
      case 'closed':
        return Icons.check_circle;
      default:
        return Icons.help;
    }
  }

  String _getEmptyMessage(String status) {
    switch (status) {
      case 'open':
        return 'Aucun ticket ouvert';
      case 'in_progress':
        return 'Aucun ticket en cours';
      case 'closed':
        return 'Aucun ticket fermé';
      default:
        return 'Aucun ticket';
    }
  }

  void _showTicketDetails(SupportTicket ticket) {
    showDialog(
      context: context,
      builder: (context) => Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        child: Container(
          width: MediaQuery.of(context).size.width * 0.9,
          constraints: const BoxConstraints(maxHeight: 600),
          padding: const EdgeInsets.all(AppSpacing.lg),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(AppSpacing.sm),
                    decoration: BoxDecoration(
                      color: _getPriorityColor(ticket.priority).withOpacity(0.1),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Icon(
                      _getCategoryIcon(ticket.category),
                      color: _getPriorityColor(ticket.priority),
                    ),
                  ),
                  const SizedBox(width: AppSpacing.md),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          ticket.subject,
                          style: Theme.of(context).textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        Text(
                          '${ticket.userEmail} • ${_formatDate(ticket.createdAt)}',
                          style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            color: AppColors.textSecondary,
                          ),
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    onPressed: () => Navigator.pop(context),
                    icon: const Icon(Icons.close),
                  ),
                ],
              ),
              
              const SizedBox(height: AppSpacing.lg),
              
              // Ticket Info
              Container(
                padding: const EdgeInsets.all(AppSpacing.md),
                decoration: BoxDecoration(
                  color: AppColors.backgroundGrey,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        _InfoChip(label: 'Catégorie', value: ticket.category),
                        const SizedBox(width: AppSpacing.sm),
                        _InfoChip(label: 'Priorité', value: ticket.priority),
                        const SizedBox(width: AppSpacing.sm),
                        _InfoChip(label: 'Statut', value: ticket.status),
                      ],
                    ),
                  ],
                ),
              ),
              
              const SizedBox(height: AppSpacing.lg),
              
              // Message
              Text(
                'Message:',
                style: Theme.of(context).textTheme.titleSmall?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: AppSpacing.sm),
              Expanded(
                child: Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(AppSpacing.md),
                  decoration: BoxDecoration(
                    border: Border.all(color: AppColors.dividerLight),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: SingleChildScrollView(
                    child: Text(
                      ticket.message,
                      style: Theme.of(context).textTheme.bodyMedium,
                    ),
                  ),
                ),
              ),
              
              const SizedBox(height: AppSpacing.lg),
              
              // Actions
              Row(
                children: [
                  if (ticket.status == 'open')
                    Expanded(
                      child: ElevatedButton.icon(
                        onPressed: () {
                          Navigator.pop(context);
                          _updateTicketStatus(ticket, 'in_progress');
                        },
                        icon: const Icon(Icons.play_arrow),
                        label: const Text('Prendre en charge'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.infoBlue,
                        ),
                      ),
                    ),
                  if (ticket.status == 'open') const SizedBox(width: AppSpacing.md),
                  Expanded(
                    child: ElevatedButton.icon(
                      onPressed: () => _showResponseDialog(ticket),
                      icon: const Icon(Icons.reply),
                      label: const Text('Répondre'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.primaryGold,
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showResponseDialog(SupportTicket ticket) {
    final responseController = TextEditingController();
    
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Répondre au ticket'),
        content: SizedBox(
          width: 400,
          child: TextField(
            controller: responseController,
            decoration: const InputDecoration(
              labelText: 'Votre réponse',
              border: OutlineInputBorder(),
              hintText: 'Tapez votre réponse ici...',
            ),
            maxLines: 6,
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Annuler'),
          ),
          ElevatedButton(
            onPressed: () {
              if (responseController.text.isNotEmpty) {
                Navigator.pop(context);
                Navigator.pop(context); // Close details dialog too
                _sendResponse(ticket, responseController.text);
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primaryGold,
            ),
            child: const Text('Envoyer'),
          ),
        ],
      ),
    );
  }

  void _showBroadcastDialog() {
    final titleController = TextEditingController();
    final messageController = TextEditingController();
    
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Annonce globale'),
        content: SizedBox(
          width: 400,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: titleController,
                decoration: const InputDecoration(
                  labelText: 'Titre de l\'annonce',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: AppSpacing.md),
              TextField(
                controller: messageController,
                decoration: const InputDecoration(
                  labelText: 'Message',
                  border: OutlineInputBorder(),
                ),
                maxLines: 4,
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Annuler'),
          ),
          ElevatedButton(
            onPressed: () {
              if (titleController.text.isNotEmpty && messageController.text.isNotEmpty) {
                Navigator.pop(context);
                _sendBroadcast(titleController.text, messageController.text);
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primaryGold,
            ),
            child: const Text('Diffuser'),
          ),
        ],
      ),
    );
  }

  void _updateTicketStatus(SupportTicket ticket, String newStatus) {
    setState(() {
      ticket.status = newStatus;
    });
    
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Statut du ticket mis à jour: $newStatus'),
        backgroundColor: AppColors.successGreen,
      ),
    );
  }

  void _sendResponse(SupportTicket ticket, String response) {
    // In a real app, this would send the response via API
    _updateTicketStatus(ticket, 'closed');
    
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Réponse envoyée avec succès'),
        backgroundColor: AppColors.successGreen,
      ),
    );
  }

  void _sendBroadcast(String title, String message) {
    // In a real app, this would send via API
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Annonce diffusée à tous les utilisateurs'),
        backgroundColor: AppColors.successGreen,
      ),
    );
  }

  Color _getPriorityColor(String priority) {
    switch (priority) {
      case 'high':
        return AppColors.errorRed;
      case 'medium':
        return AppColors.warningAmber;
      case 'low':
        return AppColors.successGreen;
      default:
        return AppColors.textSecondary;
    }
  }

  IconData _getCategoryIcon(String category) {
    switch (category) {
      case 'technical':
        return Icons.bug_report;
      case 'account':
        return Icons.account_circle;
      case 'payment':
        return Icons.payment;
      case 'feature':
        return Icons.lightbulb;
      case 'other':
        return Icons.help;
      default:
        return Icons.help;
    }
  }

  String _formatDate(DateTime date) {
    return '${date.day.toString().padLeft(2, '0')}/${date.month.toString().padLeft(2, '0')}/${date.year}';
  }
}

// Mock data and helper classes
class SupportTicket {
  final String id;
  final String userEmail;
  final String subject;
  final String message;
  final String category;
  final String priority;
  String status;
  final DateTime createdAt;

  SupportTicket({
    required this.id,
    required this.userEmail,
    required this.subject,
    required this.message,
    required this.category,
    required this.priority,
    required this.status,
    required this.createdAt,
  });
}

List<SupportTicket> _generateMockTickets() {
  return [
    SupportTicket(
      id: '1',
      userEmail: 'sophie.martin@email.com',
      subject: 'Problème de connexion',
      message: 'Je n\'arrive plus à me connecter avec Google depuis hier. L\'application se ferme à chaque fois.',
      category: 'technical',
      priority: 'high',
      status: 'open',
      createdAt: DateTime.now().subtract(const Duration(hours: 2)),
    ),
    SupportTicket(
      id: '2',
      userEmail: 'marc.dupont@email.com',
      subject: 'Question sur l\'abonnement',
      message: 'J\'aimerais savoir comment annuler mon abonnement Premium. Je ne trouve pas l\'option dans les paramètres.',
      category: 'payment',
      priority: 'medium',
      status: 'in_progress',
      createdAt: DateTime.now().subtract(const Duration(days: 1)),
    ),
    SupportTicket(
      id: '3',
      userEmail: 'claire.dubois@email.com',
      subject: 'Suggestion d\'amélioration',
      message: 'Il serait bien d\'avoir plus de filtres pour les préférences de matching.',
      category: 'feature',
      priority: 'low',
      status: 'closed',
      createdAt: DateTime.now().subtract(const Duration(days: 3)),
    ),
  ];
}

class _StatCard extends StatelessWidget {
  final String title;
  final int count;
  final Color color;
  final IconData icon;

  const _StatCard({
    required this.title,
    required this.count,
    required this.color,
    required this.icon,
  });

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(AppSpacing.md),
        decoration: BoxDecoration(
          color: color.withOpacity(0.1),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Column(
          children: [
            Icon(icon, color: color, size: 24),
            const SizedBox(height: AppSpacing.sm),
            Text(
              count.toString(),
              style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                color: color,
                fontWeight: FontWeight.bold,
              ),
            ),
            Text(
              title,
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: color,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _SupportTicketCard extends StatelessWidget {
  final SupportTicket ticket;
  final VoidCallback onTap;
  final Function(String) onStatusChanged;

  const _SupportTicketCard({
    required this.ticket,
    required this.onTap,
    required this.onStatusChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 2,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.md),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(AppSpacing.sm),
                    decoration: BoxDecoration(
                      color: _getPriorityColor(ticket.priority).withOpacity(0.1),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Icon(
                      _getCategoryIcon(ticket.category),
                      color: _getPriorityColor(ticket.priority),
                      size: 20,
                    ),
                  ),
                  const SizedBox(width: AppSpacing.md),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          ticket.subject,
                          style: Theme.of(context).textTheme.titleSmall?.copyWith(
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        Text(
                          ticket.userEmail,
                          style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            color: AppColors.textSecondary,
                          ),
                        ),
                      ],
                    ),
                  ),
                  _StatusChip(status: ticket.status),
                ],
              ),
              const SizedBox(height: AppSpacing.sm),
              Text(
                ticket.message,
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: AppColors.textSecondary,
                ),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Color _getPriorityColor(String priority) {
    switch (priority) {
      case 'high':
        return AppColors.errorRed;
      case 'medium':
        return AppColors.warningAmber;
      case 'low':
        return AppColors.successGreen;
      default:
        return AppColors.textSecondary;
    }
  }

  IconData _getCategoryIcon(String category) {
    switch (category) {
      case 'technical':
        return Icons.bug_report;
      case 'account':
        return Icons.account_circle;
      case 'payment':
        return Icons.payment;
      case 'feature':
        return Icons.lightbulb;
      case 'other':
        return Icons.help;
      default:
        return Icons.help;
    }
  }
}

class _StatusChip extends StatelessWidget {
  final String status;

  const _StatusChip({required this.status});

  @override
  Widget build(BuildContext context) {
    Color color;
    String label;

    switch (status) {
      case 'open':
        color = AppColors.warningAmber;
        label = 'Ouvert';
        break;
      case 'in_progress':
        color = AppColors.infoBlue;
        label = 'En cours';
        break;
      case 'closed':
        color = AppColors.successGreen;
        label = 'Fermé';
        break;
      default:
        color = AppColors.textSecondary;
        label = status;
    }

    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.sm,
        vertical: AppSpacing.xs,
      ),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Text(
        label,
        style: Theme.of(context).textTheme.bodySmall?.copyWith(
          color: color,
          fontWeight: FontWeight.w500,
        ),
      ),
    );
  }
}

class _InfoChip extends StatelessWidget {
  final String label;
  final String value;

  const _InfoChip({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.sm,
        vertical: AppSpacing.xs,
      ),
      decoration: BoxDecoration(
        color: AppColors.primaryGold.withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(
        '$label: $value',
        style: Theme.of(context).textTheme.bodySmall?.copyWith(
          color: AppColors.primaryGold,
          fontWeight: FontWeight.w500,
        ),
      ),
    );
  }
}