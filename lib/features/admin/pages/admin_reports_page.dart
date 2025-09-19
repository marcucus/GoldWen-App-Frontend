import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../core/theme/app_theme.dart';
import '../providers/admin_provider.dart';
import '../models/admin_report.dart';
import '../widgets/report_list_item.dart';

class AdminReportsPage extends StatefulWidget {
  const AdminReportsPage({super.key});

  @override
  State<AdminReportsPage> createState() => _AdminReportsPageState();
}

class _AdminReportsPageState extends State<AdminReportsPage> with TickerProviderStateMixin {
  late TabController _tabController;
  final _scrollController = ScrollController();
  String? _selectedTypeFilter;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<AdminProvider>().loadReports(refresh: true, status: 'pending');
    });
    
    _scrollController.addListener(_onScroll);
    _tabController.addListener(_onTabChanged);
  }

  @override
  void dispose() {
    _tabController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  void _onScroll() {
    if (_scrollController.position.pixels == _scrollController.position.maxScrollExtent) {
      final adminProvider = context.read<AdminProvider>();
      if (adminProvider.hasMoreReports && !adminProvider.isLoading) {
        adminProvider.loadReports(
          status: _getStatusFromTab(),
          type: _selectedTypeFilter,
        );
      }
    }
  }

  void _onTabChanged() {
    final status = _getStatusFromTab();
    context.read<AdminProvider>().loadReports(
      refresh: true,
      status: status,
      type: _selectedTypeFilter,
    );
  }

  String? _getStatusFromTab() {
    switch (_tabController.index) {
      case 0:
        return 'pending';
      case 1:
        return 'in_progress';
      case 2:
        return 'resolved';
      default:
        return null;
    }
  }

  void _performFilter() {
    context.read<AdminProvider>().loadReports(
      refresh: true,
      status: _getStatusFromTab(),
      type: _selectedTypeFilter,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.backgroundWhite,
      appBar: AppBar(
        title: const Text('Modération des Signalements'),
        backgroundColor: AppColors.primaryGold,
        foregroundColor: Colors.white,
        elevation: 2,
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: Colors.white,
          labelColor: Colors.white,
          unselectedLabelColor: Colors.white70,
          tabs: const [
            Tab(text: 'En attente', icon: Icon(Icons.pending_actions)),
            Tab(text: 'En cours', icon: Icon(Icons.work)),
            Tab(text: 'Résolus', icon: Icon(Icons.check_circle)),
          ],
        ),
      ),
      body: Column(
        children: [
          // Filter Section
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
                Expanded(
                  child: DropdownButtonFormField<String>(
                    value: _selectedTypeFilter,
                    decoration: InputDecoration(
                      labelText: 'Type de signalement',
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      filled: true,
                      fillColor: AppColors.backgroundGrey,
                    ),
                    items: const [
                      DropdownMenuItem(value: null, child: Text('Tous les types')),
                      DropdownMenuItem(value: 'inappropriate_content', child: Text('Contenu inapproprié')),
                      DropdownMenuItem(value: 'fake_profile', child: Text('Faux profil')),
                      DropdownMenuItem(value: 'harassment', child: Text('Harcèlement')),
                      DropdownMenuItem(value: 'spam', child: Text('Spam')),
                      DropdownMenuItem(value: 'other', child: Text('Autre')),
                    ],
                    onChanged: (value) {
                      setState(() {
                        _selectedTypeFilter = value;
                      });
                      _performFilter();
                    },
                  ),
                ),
                const SizedBox(width: AppSpacing.md),
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: AppColors.primaryGold.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Consumer<AdminProvider>(
                    builder: (context, adminProvider, child) {
                      final pendingCount = adminProvider.reports
                          .where((report) => report.isPending)
                          .length;
                      return Column(
                        children: [
                          Icon(
                            Icons.flag,
                            color: AppColors.primaryGold,
                            size: 20,
                          ),
                          const SizedBox(height: 4),
                          Text(
                            '$pendingCount',
                            style: TextStyle(
                              color: AppColors.primaryGold,
                              fontWeight: FontWeight.bold,
                              fontSize: 16,
                            ),
                          ),
                          Text(
                            'En attente',
                            style: TextStyle(
                              color: AppColors.primaryGold,
                              fontSize: 10,
                            ),
                          ),
                        ],
                      );
                    },
                  ),
                ),
              ],
            ),
          ),
          
          // Reports List
          Expanded(
            child: TabBarView(
              controller: _tabController,
              children: [
                _buildReportsList('pending'),
                _buildReportsList('in_progress'),
                _buildReportsList('resolved'),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildReportsList(String status) {
    return Consumer<AdminProvider>(
      builder: (context, adminProvider, child) {
        final filteredReports = adminProvider.reports
            .where((report) => report.status == status)
            .toList();

        if (adminProvider.isLoading && filteredReports.isEmpty) {
          return const Center(
            child: CircularProgressIndicator(
              valueColor: AlwaysStoppedAnimation<Color>(AppColors.primaryGold),
            ),
          );
        }

        if (adminProvider.error != null && filteredReports.isEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.error_outline,
                  size: 64,
                  color: AppColors.errorRed,
                ),
                const SizedBox(height: AppSpacing.lg),
                Text(
                  'Erreur de chargement',
                  style: Theme.of(context).textTheme.headlineSmall,
                ),
                const SizedBox(height: AppSpacing.md),
                Text(
                  adminProvider.error!,
                  textAlign: TextAlign.center,
                  style: TextStyle(color: AppColors.textSecondary),
                ),
                const SizedBox(height: AppSpacing.lg),
                ElevatedButton(
                  onPressed: () => adminProvider.loadReports(
                    refresh: true,
                    status: status,
                  ),
                  child: const Text('Réessayer'),
                ),
              ],
            ),
          );
        }

        if (filteredReports.isEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  _getTabIcon(status),
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
                  'Aucun signalement trouvé dans cette catégorie',
                  style: TextStyle(color: AppColors.textSecondary),
                ),
              ],
            ),
          );
        }

        return RefreshIndicator(
          onRefresh: () => adminProvider.loadReports(
            refresh: true,
            status: status,
            type: _selectedTypeFilter,
          ),
          child: ListView.separated(
            controller: _scrollController,
            padding: const EdgeInsets.all(AppSpacing.md),
            itemCount: filteredReports.length + 
                (adminProvider.hasMoreReports && adminProvider.isLoading ? 1 : 0),
            separatorBuilder: (context, index) => const SizedBox(height: AppSpacing.sm),
            itemBuilder: (context, index) {
              if (index == filteredReports.length) {
                // Loading indicator for pagination
                return const Padding(
                  padding: EdgeInsets.all(AppSpacing.lg),
                  child: Center(
                    child: CircularProgressIndicator(
                      valueColor: AlwaysStoppedAnimation<Color>(AppColors.primaryGold),
                    ),
                  ),
                );
              }

              final report = filteredReports[index];
              return ReportListItem(
                report: report,
                onTap: () => _showReportDetails(context, report),
                onActionTaken: (action, resolution) => 
                    _handleReportAction(report, action, resolution),
              );
            },
          ),
        );
      },
    );
  }

  IconData _getTabIcon(String status) {
    switch (status) {
      case 'pending':
        return Icons.pending_actions;
      case 'in_progress':
        return Icons.work;
      case 'resolved':
        return Icons.check_circle;
      default:
        return Icons.flag;
    }
  }

  String _getEmptyMessage(String status) {
    switch (status) {
      case 'pending':
        return 'Aucun signalement en attente';
      case 'in_progress':
        return 'Aucun signalement en cours';
      case 'resolved':
        return 'Aucun signalement résolu';
      default:
        return 'Aucun signalement';
    }
  }

  void _showReportDetails(BuildContext context, AdminReport report) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Signalement ${report.reportType}'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _DetailRow(label: 'ID', value: report.id),
              _DetailRow(label: 'Type', value: _getTypeLabel(report.reportType)),
              _DetailRow(label: 'Raison', value: report.reason),
              if (report.description != null)
                _DetailRow(label: 'Description', value: report.description!),
              _DetailRow(label: 'Utilisateur signalé', value: report.reportedUserId),
              if (report.reporterUserId != null)
                _DetailRow(label: 'Signalé par', value: report.reporterUserId!),
              _DetailRow(label: 'Statut', value: _getStatusLabel(report.status)),
              _DetailRow(label: 'Créé le', value: _formatDateTime(report.createdAt)),
              if (report.resolvedAt != null)
                _DetailRow(label: 'Résolu le', value: _formatDateTime(report.resolvedAt!)),
              if (report.resolution != null)
                _DetailRow(label: 'Résolution', value: report.resolution!),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Fermer'),
          ),
          if (report.isPending || report.isInProgress)
            ElevatedButton(
              onPressed: () {
                Navigator.pop(context);
                _showActionDialog(context, report);
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primaryGold,
                foregroundColor: Colors.white,
              ),
              child: const Text('Agir'),
            ),
        ],
      ),
    );
  }

  void _showActionDialog(BuildContext context, AdminReport report) {
    String? selectedAction;
    final resolutionController = TextEditingController();

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Action sur le signalement'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            DropdownButtonFormField<String>(
              decoration: const InputDecoration(
                labelText: 'Action',
                border: OutlineInputBorder(),
              ),
              items: const [
                DropdownMenuItem(value: 'warning_sent', child: Text('Avertissement envoyé')),
                DropdownMenuItem(value: 'content_removed', child: Text('Contenu supprimé')),
                DropdownMenuItem(value: 'user_suspended', child: Text('Utilisateur suspendu')),
                DropdownMenuItem(value: 'user_banned', child: Text('Utilisateur banni')),
                DropdownMenuItem(value: 'no_action', child: Text('Aucune action nécessaire')),
                DropdownMenuItem(value: 'false_report', child: Text('Faux signalement')),
              ],
              onChanged: (value) => selectedAction = value,
            ),
            const SizedBox(height: AppSpacing.md),
            TextField(
              controller: resolutionController,
              decoration: const InputDecoration(
                labelText: 'Note de résolution',
                border: OutlineInputBorder(),
                hintText: 'Expliquez l\'action prise...',
              ),
              maxLines: 3,
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Annuler'),
          ),
          ElevatedButton(
            onPressed: () {
              if (selectedAction != null && resolutionController.text.isNotEmpty) {
                Navigator.pop(context);
                _handleReportAction(report, selectedAction!, resolutionController.text);
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primaryGold,
              foregroundColor: Colors.white,
            ),
            child: const Text('Confirmer'),
          ),
        ],
      ),
    );
  }

  void _handleReportAction(AdminReport report, String action, String resolution) async {
    final success = await context.read<AdminProvider>().updateReportStatus(
      report.id,
      'resolved',
      resolution,
    );
    
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(success 
              ? 'Signalement traité avec succès' 
              : 'Erreur lors du traitement'),
          backgroundColor: success ? AppColors.successGreen : AppColors.errorRed,
        ),
      );
    }
  }

  String _getTypeLabel(String type) {
    switch (type) {
      case 'inappropriate_content':
        return 'Contenu inapproprié';
      case 'fake_profile':
        return 'Faux profil';
      case 'harassment':
        return 'Harcèlement';
      case 'spam':
        return 'Spam';
      case 'other':
        return 'Autre';
      default:
        return type;
    }
  }

  String _getStatusLabel(String status) {
    switch (status) {
      case 'pending':
        return 'En attente';
      case 'in_progress':
        return 'En cours';
      case 'resolved':
        return 'Résolu';
      default:
        return status;
    }
  }

  String _formatDateTime(DateTime dateTime) {
    return '${dateTime.day.toString().padLeft(2, '0')}/${dateTime.month.toString().padLeft(2, '0')}/${dateTime.year} ${dateTime.hour.toString().padLeft(2, '0')}:${dateTime.minute.toString().padLeft(2, '0')}';
  }
}

class _DetailRow extends StatelessWidget {
  final String label;
  final String value;

  const _DetailRow({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 120,
            child: Text(
              '$label:',
              style: TextStyle(
                fontWeight: FontWeight.w500,
                color: AppColors.textSecondary,
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(color: AppColors.textDark),
            ),
          ),
        ],
      ),
    );
  }
}