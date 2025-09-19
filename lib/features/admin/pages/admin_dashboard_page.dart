import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';
import '../../../core/theme/app_theme.dart';
import '../providers/admin_provider.dart';
import '../providers/admin_auth_provider.dart';
import '../widgets/admin_stats_card.dart';
import '../widgets/admin_quick_actions.dart';

class AdminDashboardPage extends StatefulWidget {
  const AdminDashboardPage({super.key});

  @override
  State<AdminDashboardPage> createState() => _AdminDashboardPageState();
}

class _AdminDashboardPageState extends State<AdminDashboardPage> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<AdminProvider>().loadAnalytics();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.backgroundWhite,
      appBar: AppBar(
        title: const Text('Dashboard Administrateur'),
        backgroundColor: AppColors.primaryGold,
        foregroundColor: Colors.white,
        elevation: 2,
        actions: [
          Consumer<AdminAuthProvider>(
            builder: (context, authProvider, child) {
              return PopupMenuButton<String>(
                onSelected: (value) {
                  if (value == 'profile') {
                    // Show admin profile
                    _showAdminProfile(context, authProvider.currentAdmin!);
                  } else if (value == 'logout') {
                    _handleLogout(context, authProvider);
                  }
                },
                itemBuilder: (context) => [
                  PopupMenuItem(
                    value: 'profile',
                    child: Row(
                      children: const [
                        Icon(Icons.person, size: 20),
                        SizedBox(width: 8),
                        Text('Profil'),
                      ],
                    ),
                  ),
                  const PopupMenuDivider(),
                  PopupMenuItem(
                    value: 'logout',
                    child: Row(
                      children: const [
                        Icon(Icons.logout, size: 20, color: Colors.red),
                        SizedBox(width: 8),
                        Text('Déconnexion', style: TextStyle(color: Colors.red)),
                      ],
                    ),
                  ),
                ],
                child: Padding(
                  padding: const EdgeInsets.all(8.0),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      CircleAvatar(
                        radius: 16,
                        backgroundColor: Colors.white,
                        child: Text(
                          authProvider.currentAdmin?.email.substring(0, 1).toUpperCase() ?? 'A',
                          style: TextStyle(
                            color: AppColors.primaryGold,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Icon(Icons.arrow_drop_down, color: Colors.white),
                    ],
                  ),
                ),
              );
            },
          ),
        ],
      ),
      body: Consumer<AdminProvider>(
        builder: (context, adminProvider, child) {
          if (adminProvider.isLoading && adminProvider.analytics == null) {
            return const Center(
              child: CircularProgressIndicator(
                valueColor: AlwaysStoppedAnimation<Color>(AppColors.primaryGold),
              ),
            );
          }

          if (adminProvider.error != null) {
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
                    onPressed: () => adminProvider.loadAnalytics(),
                    child: const Text('Réessayer'),
                  ),
                ],
              ),
            );
          }

          final analytics = adminProvider.analytics;
          if (analytics == null) {
            return const Center(child: Text('Aucune donnée disponible'));
          }

          return RefreshIndicator(
            onRefresh: () => adminProvider.loadAnalytics(),
            child: SingleChildScrollView(
              physics: const AlwaysScrollableScrollPhysics(),
              padding: const EdgeInsets.all(AppSpacing.lg),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Welcome Section
                  Card(
                    child: Padding(
                      padding: const EdgeInsets.all(AppSpacing.lg),
                      child: Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(AppSpacing.md),
                            decoration: BoxDecoration(
                              color: AppColors.primaryGold.withOpacity(0.1),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Icon(
                              Icons.dashboard,
                              size: 32,
                              color: AppColors.primaryGold,
                            ),
                          ),
                          const SizedBox(width: AppSpacing.md),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Bienvenue sur le tableau de bord',
                                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  'Vue d\'ensemble de la plateforme GoldWen',
                                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                                    color: AppColors.textSecondary,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  
                  const SizedBox(height: AppSpacing.xl),
                  
                  // Statistics Cards
                  Text(
                    'Statistiques générales',
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: AppSpacing.md),
                  
                  GridView.count(
                    crossAxisCount: 2,
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    crossAxisSpacing: AppSpacing.md,
                    mainAxisSpacing: AppSpacing.md,
                    childAspectRatio: 1.5,
                    children: [
                      AdminStatsCard(
                        title: 'Utilisateurs actifs',
                        value: analytics.activeUsers.toString(),
                        icon: Icons.people,
                        color: AppColors.primaryGold,
                      ),
                      AdminStatsCard(
                        title: 'Nouvelles inscriptions',
                        value: analytics.newRegistrations.toString(),
                        icon: Icons.person_add,
                        color: AppColors.successGreen,
                      ),
                      AdminStatsCard(
                        title: 'Matches quotidiens',
                        value: analytics.dailyMatches.toString(),
                        icon: Icons.favorite,
                        color: Colors.pink,
                      ),
                      AdminStatsCard(
                        title: 'Messages envoyés',
                        value: analytics.messagesSent.toString(),
                        icon: Icons.chat_bubble,
                        color: AppColors.infoBlue,
                      ),
                    ],
                  ),
                  
                  const SizedBox(height: AppSpacing.xl),
                  
                  // Additional Stats
                  Row(
                    children: [
                      Expanded(
                        child: AdminStatsCard(
                          title: 'Taux d\'abonnement',
                          value: '${analytics.subscriptionRate.toStringAsFixed(1)}%',
                          icon: Icons.trending_up,
                          color: AppColors.warningAmber,
                        ),
                      ),
                      const SizedBox(width: AppSpacing.md),
                      Expanded(
                        child: AdminStatsCard(
                          title: 'Signalements en attente',
                          value: analytics.pendingReports.toString(),
                          icon: Icons.warning,
                          color: analytics.pendingReports > 0 ? AppColors.errorRed : AppColors.successGreen,
                        ),
                      ),
                    ],
                  ),
                  
                  const SizedBox(height: AppSpacing.xl),
                  
                  // Quick Actions
                  Text(
                    'Actions rapides',
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: AppSpacing.md),
                  
                  const AdminQuickActions(),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  void _showAdminProfile(BuildContext context, adminUser) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Profil Administrateur'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Icons.email, size: 20, color: Colors.grey),
                const SizedBox(width: 8),
                Expanded(child: Text(adminUser.email)),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                const Icon(Icons.admin_panel_settings, size: 20, color: Colors.grey),
                const SizedBox(width: 8),
                Text(adminUser.role.toUpperCase()),
              ],
            ),
            if (adminUser.lastLogin != null) ...[
              const SizedBox(height: 12),
              Row(
                children: [
                  const Icon(Icons.access_time, size: 20, color: Colors.grey),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'Dernière connexion: ${_formatDateTime(adminUser.lastLogin!)}',
                      style: const TextStyle(fontSize: 12),
                    ),
                  ),
                ],
              ),
            ],
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Fermer'),
          ),
        ],
      ),
    );
  }

  void _handleLogout(BuildContext context, AdminAuthProvider authProvider) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Confirmation'),
        content: const Text('Êtes-vous sûr de vouloir vous déconnecter ?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Annuler'),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              authProvider.logout();
              context.go('/admin/login');
            },
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Déconnexion'),
          ),
        ],
      ),
    );
  }

  String _formatDateTime(DateTime dateTime) {
    return '${dateTime.day.toString().padLeft(2, '0')}/${dateTime.month.toString().padLeft(2, '0')}/${dateTime.year} à ${dateTime.hour.toString().padLeft(2, '0')}:${dateTime.minute.toString().padLeft(2, '0')}';
  }
}