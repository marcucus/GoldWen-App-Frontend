import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/models/models.dart';
import '../../matching/providers/report_provider.dart';

class UserReportsPage extends StatefulWidget {
  const UserReportsPage({super.key});

  @override
  State<UserReportsPage> createState() => _UserReportsPageState();
}

class _UserReportsPageState extends State<UserReportsPage> {
  ReportStatus? _selectedStatus;
  final ScrollController _scrollController = ScrollController();
  int _currentPage = 1;
  static const int _pageSize = 20;

  @override
  void initState() {
    super.initState();
    _loadReports();
    _scrollController.addListener(_onScroll);
  }

  @override
  void dispose() {
    _scrollController.removeListener(_onScroll);
    _scrollController.dispose();
    super.dispose();
  }

  void _loadReports({bool refresh = false}) {
    final reportProvider = Provider.of<ReportProvider>(context, listen: false);
    reportProvider.loadMyReports(
      page: refresh ? 1 : _currentPage,
      limit: _pageSize,
      status: _selectedStatus,
      refresh: refresh,
    );
    
    if (refresh) {
      _currentPage = 1;
    }
  }

  void _onScroll() {
    if (_scrollController.position.pixels >= 
        _scrollController.position.maxScrollExtent * 0.8) {
      final reportProvider = Provider.of<ReportProvider>(context, listen: false);
      if (reportProvider.hasMoreReports && !reportProvider.isLoading) {
        setState(() {
          _currentPage++;
        });
        _loadReports();
      }
    }
  }

  void _onStatusFilterChanged(ReportStatus? status) {
    setState(() {
      _selectedStatus = status;
      _currentPage = 1;
    });
    _loadReports(refresh: true);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: BoxDecoration(
          gradient: AppColors.primaryGradient,
        ),
        child: SafeArea(
          child: Column(
            children: [
              // Header
              Padding(
                padding: const EdgeInsets.all(AppSpacing.lg),
                child: Row(
                  children: [
                    Container(
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: AppColors.cardOverlay.withOpacity(0.2),
                      ),
                      child: IconButton(
                        onPressed: () => Navigator.of(context).pop(),
                        icon: const Icon(
                          Icons.arrow_back,
                          color: AppColors.textLight,
                        ),
                      ),
                    ),
                    const SizedBox(width: AppSpacing.md),
                    Expanded(
                      child: Text(
                        'Mes signalements',
                        style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                          color: AppColors.textLight,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ],
                ),
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
                  child: Column(
                    children: [
                      // Filter section
                      _buildFilterSection(),
                      
                      // Reports list
                      Expanded(
                        child: Consumer<ReportProvider>(
                          builder: (context, reportProvider, child) {
                            if (reportProvider.isLoading && reportProvider.myReports.isEmpty) {
                              return const Center(
                                child: CircularProgressIndicator(
                                  valueColor: AlwaysStoppedAnimation<Color>(AppColors.primaryGold),
                                ),
                              );
                            }

                            if (reportProvider.error != null) {
                              return _buildErrorState(reportProvider);
                            }

                            if (reportProvider.myReports.isEmpty) {
                              return _buildEmptyState();
                            }

                            return _buildReportsList(reportProvider);
                          },
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildFilterSection() {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.lg),
      decoration: BoxDecoration(
        color: AppColors.backgroundWhite,
        border: Border(
          bottom: BorderSide(
            color: AppColors.borderLight,
            width: 1,
          ),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Filtrer par statut',
            style: Theme.of(context).textTheme.titleSmall?.copyWith(
              fontWeight: FontWeight.w600,
              color: AppColors.textDark,
            ),
          ),
          const SizedBox(height: AppSpacing.sm),
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: [
                _buildStatusChip('Tous', null),
                const SizedBox(width: AppSpacing.sm),
                _buildStatusChip('En attente', ReportStatus.pending),
                const SizedBox(width: AppSpacing.sm),
                _buildStatusChip('Examiné', ReportStatus.reviewed),
                const SizedBox(width: AppSpacing.sm),
                _buildStatusChip('Résolu', ReportStatus.resolved),
                const SizedBox(width: AppSpacing.sm),
                _buildStatusChip('Rejeté', ReportStatus.dismissed),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatusChip(String label, ReportStatus? status) {
    final isSelected = _selectedStatus == status;
    
    return FilterChip(
      label: Text(label),
      selected: isSelected,
      onSelected: (_) => _onStatusFilterChanged(status),
      backgroundColor: AppColors.backgroundLight,
      selectedColor: AppColors.primaryGold.withOpacity(0.2),
      labelStyle: TextStyle(
        color: isSelected ? AppColors.primaryGold : AppColors.textSecondary,
        fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
      ),
      side: BorderSide(
        color: isSelected ? AppColors.primaryGold : AppColors.borderLight,
      ),
      showCheckmark: false,
    );
  }

  Widget _buildReportsList(ReportProvider reportProvider) {
    return RefreshIndicator(
      color: AppColors.primaryGold,
      onRefresh: () async => _loadReports(refresh: true),
      child: ListView.separated(
        controller: _scrollController,
        padding: const EdgeInsets.all(AppSpacing.lg),
        itemCount: reportProvider.myReports.length + 
                  (reportProvider.hasMoreReports ? 1 : 0),
        separatorBuilder: (context, index) => const SizedBox(height: AppSpacing.md),
        itemBuilder: (context, index) {
          if (index >= reportProvider.myReports.length) {
            return const Center(
              child: Padding(
                padding: EdgeInsets.all(AppSpacing.lg),
                child: CircularProgressIndicator(
                  valueColor: AlwaysStoppedAnimation<Color>(AppColors.primaryGold),
                ),
              ),
            );
          }

          final report = reportProvider.myReports[index];
          return _buildReportCard(report);
        },
      ),
    );
  }

  Widget _buildReportCard(Report report) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppBorderRadius.md),
      ),
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.lg),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header with type and status
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Text(
                    _getReportTypeLabel(report.type),
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w600,
                      color: AppColors.textDark,
                    ),
                  ),
                ),
                _buildStatusBadge(report.status),
              ],
            ),
            const SizedBox(height: AppSpacing.sm),

            // Report reason
            Text(
              report.reason,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: AppColors.textSecondary,
              ),
              maxLines: 3,
              overflow: TextOverflow.ellipsis,
            ),
            const SizedBox(height: AppSpacing.md),

            // Date and additional info
            Row(
              children: [
                Icon(
                  Icons.access_time,
                  size: 16,
                  color: AppColors.textSecondary,
                ),
                const SizedBox(width: AppSpacing.xs),
                Text(
                  'Signalé le ${DateFormat('dd/MM/yyyy à HH:mm').format(report.createdAt)}',
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: AppColors.textSecondary,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatusBadge(ReportStatus status) {
    Color backgroundColor;
    Color textColor;
    String label;

    switch (status) {
      case ReportStatus.pending:
        backgroundColor = Colors.orange.withOpacity(0.1);
        textColor = Colors.orange.shade700;
        label = 'En attente';
        break;
      case ReportStatus.reviewed:
        backgroundColor = Colors.blue.withOpacity(0.1);
        textColor = Colors.blue.shade700;
        label = 'Examiné';
        break;
      case ReportStatus.resolved:
        backgroundColor = Colors.green.withOpacity(0.1);
        textColor = Colors.green.shade700;
        label = 'Résolu';
        break;
      case ReportStatus.dismissed:
        backgroundColor = Colors.grey.withOpacity(0.1);
        textColor = Colors.grey.shade700;
        label = 'Rejeté';
        break;
    }

    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.sm,
        vertical: AppSpacing.xs,
      ),
      decoration: BoxDecoration(
        color: backgroundColor,
        borderRadius: BorderRadius.circular(AppBorderRadius.sm),
      ),
      child: Text(
        label,
        style: Theme.of(context).textTheme.bodySmall?.copyWith(
          color: textColor,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }

  String _getReportTypeLabel(ReportType type) {
    switch (type) {
      case ReportType.inappropriateContent:
        return 'Contenu inapproprié';
      case ReportType.harassment:
        return 'Harcèlement';
      case ReportType.fakeProfile:
        return 'Faux profil';
      case ReportType.spam:
        return 'Spam';
      case ReportType.other:
        return 'Autre';
    }
  }

  Widget _buildEmptyState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.xl),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.report_off,
              size: 64,
              color: AppColors.textSecondary.withOpacity(0.5),
            ),
            const SizedBox(height: AppSpacing.lg),
            Text(
              'Aucun signalement',
              style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                color: AppColors.textSecondary,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: AppSpacing.sm),
            Text(
              'Vous n\'avez encore soumis aucun signalement.',
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

  Widget _buildErrorState(ReportProvider reportProvider) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.xl),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.error_outline,
              size: 64,
              color: Colors.red.shade400,
            ),
            const SizedBox(height: AppSpacing.lg),
            Text(
              'Erreur de chargement',
              style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                color: AppColors.textDark,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: AppSpacing.sm),
            Text(
              reportProvider.error ?? 'Une erreur est survenue',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: AppColors.textSecondary,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: AppSpacing.lg),
            ElevatedButton(
              onPressed: () {
                reportProvider.clearError();
                _loadReports(refresh: true);
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primaryGold,
                foregroundColor: AppColors.textDark,
              ),
              child: const Text('Réessayer'),
            ),
          ],
        ),
      ),
    );
  }
}