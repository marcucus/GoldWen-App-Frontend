import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/models/user.dart';
import '../providers/admin_provider.dart';
import '../widgets/user_list_item.dart';

class AdminUsersPage extends StatefulWidget {
  const AdminUsersPage({super.key});

  @override
  State<AdminUsersPage> createState() => _AdminUsersPageState();
}

class _AdminUsersPageState extends State<AdminUsersPage> {
  final _searchController = TextEditingController();
  final _scrollController = ScrollController();
  String? _selectedStatusFilter;
  
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<AdminProvider>().loadUsers(refresh: true);
    });
    
    _scrollController.addListener(_onScroll);
  }

  @override
  void dispose() {
    _searchController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  void _onScroll() {
    if (_scrollController.position.pixels == _scrollController.position.maxScrollExtent) {
      final adminProvider = context.read<AdminProvider>();
      if (adminProvider.hasMoreUsers && !adminProvider.isLoading) {
        adminProvider.loadUsers(
          search: _searchController.text.isNotEmpty ? _searchController.text : null,
          status: _selectedStatusFilter,
        );
      }
    }
  }

  void _performSearch() {
    context.read<AdminProvider>().loadUsers(
      refresh: true,
      search: _searchController.text.isNotEmpty ? _searchController.text : null,
      status: _selectedStatusFilter,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.backgroundWhite,
      appBar: AppBar(
        title: const Text('Gestion des Utilisateurs'),
        backgroundColor: AppColors.primaryGold,
        foregroundColor: Colors.white,
        elevation: 2,
      ),
      body: Column(
        children: [
          // Search and Filter Section
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
            child: Column(
              children: [
                // Search Bar
                TextField(
                  controller: _searchController,
                  decoration: InputDecoration(
                    hintText: 'Rechercher par nom, email...',
                    prefixIcon: const Icon(Icons.search),
                    suffixIcon: IconButton(
                      icon: const Icon(Icons.clear),
                      onPressed: () {
                        _searchController.clear();
                        _performSearch();
                      },
                    ),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    filled: true,
                    fillColor: AppColors.backgroundGrey,
                  ),
                  onSubmitted: (_) => _performSearch(),
                ),
                
                const SizedBox(height: AppSpacing.md),
                
                // Filter Row
                Row(
                  children: [
                    Expanded(
                      child: DropdownButtonFormField<String>(
                        value: _selectedStatusFilter,
                        decoration: InputDecoration(
                          labelText: 'Statut',
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          filled: true,
                          fillColor: AppColors.backgroundGrey,
                        ),
                        items: const [
                          DropdownMenuItem(value: null, child: Text('Tous les statuts')),
                          DropdownMenuItem(value: 'active', child: Text('Actifs')),
                          DropdownMenuItem(value: 'suspended', child: Text('Suspendus')),
                          DropdownMenuItem(value: 'banned', child: Text('Bannis')),
                        ],
                        onChanged: (value) {
                          setState(() {
                            _selectedStatusFilter = value;
                          });
                          _performSearch();
                        },
                      ),
                    ),
                    const SizedBox(width: AppSpacing.md),
                    ElevatedButton.icon(
                      onPressed: _performSearch,
                      icon: const Icon(Icons.search),
                      label: const Text('Rechercher'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.primaryGold,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(
                          horizontal: AppSpacing.lg,
                          vertical: AppSpacing.md,
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          
          // Users List
          Expanded(
            child: Consumer<AdminProvider>(
              builder: (context, adminProvider, child) {
                if (adminProvider.isLoading && adminProvider.users.isEmpty) {
                  return const Center(
                    child: CircularProgressIndicator(
                      valueColor: AlwaysStoppedAnimation<Color>(AppColors.primaryGold),
                    ),
                  );
                }

                if (adminProvider.error != null && adminProvider.users.isEmpty) {
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
                          onPressed: () => adminProvider.loadUsers(refresh: true),
                          child: const Text('Réessayer'),
                        ),
                      ],
                    ),
                  );
                }

                if (adminProvider.users.isEmpty) {
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.people_outline,
                          size: 64,
                          color: AppColors.textTertiary,
                        ),
                        const SizedBox(height: AppSpacing.lg),
                        Text(
                          'Aucun utilisateur trouvé',
                          style: Theme.of(context).textTheme.titleLarge,
                        ),
                        const SizedBox(height: AppSpacing.md),
                        Text(
                          'Essayez de modifier vos critères de recherche',
                          style: TextStyle(color: AppColors.textSecondary),
                        ),
                      ],
                    ),
                  );
                }

                return RefreshIndicator(
                  onRefresh: () => adminProvider.loadUsers(
                    refresh: true,
                    search: _searchController.text.isNotEmpty ? _searchController.text : null,
                    status: _selectedStatusFilter,
                  ),
                  child: ListView.separated(
                    controller: _scrollController,
                    padding: const EdgeInsets.all(AppSpacing.md),
                    itemCount: adminProvider.users.length + 
                        (adminProvider.hasMoreUsers ? 1 : 0),
                    separatorBuilder: (context, index) => const SizedBox(height: AppSpacing.sm),
                    itemBuilder: (context, index) {
                      if (index == adminProvider.users.length) {
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

                      final user = adminProvider.users[index];
                      return UserListItem(
                        user: user,
                        onTap: () => _showUserDetails(context, user),
                        onStatusChanged: (newStatus) => _updateUserStatus(user.id, newStatus),
                      );
                    },
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  void _showUserDetails(BuildContext context, User user) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('${user.firstName} ${user.lastName}'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _DetailRow(label: 'Email', value: user.email),
              _DetailRow(label: 'ID', value: user.id),
              _DetailRow(label: 'Âge', value: '${user.age} ans'),
              if (user.bio?.isNotEmpty == true)
                _DetailRow(label: 'Bio', value: user.bio!),
              _DetailRow(label: 'Créé le', value: _formatDate(user.createdAt)),
              if (user.lastActive != null)
                _DetailRow(label: 'Dernière activité', value: _formatDate(user.lastActive!)),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Fermer'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              _showStatusChangeDialog(context, user);
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primaryGold,
              foregroundColor: Colors.white,
            ),
            child: const Text('Modifier le statut'),
          ),
        ],
      ),
    );
  }

  void _showStatusChangeDialog(BuildContext context, User user) {
    String? selectedStatus;
    
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Modifier le statut de ${user.firstName}'),
        content: DropdownButtonFormField<String>(
          decoration: const InputDecoration(
            labelText: 'Nouveau statut',
            border: OutlineInputBorder(),
          ),
          items: const [
            DropdownMenuItem(value: 'active', child: Text('Actif')),
            DropdownMenuItem(value: 'suspended', child: Text('Suspendu')),
            DropdownMenuItem(value: 'banned', child: Text('Banni')),
          ],
          onChanged: (value) => selectedStatus = value,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Annuler'),
          ),
          ElevatedButton(
            onPressed: () {
              if (selectedStatus != null) {
                Navigator.pop(context);
                _updateUserStatus(user.id, selectedStatus!);
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

  void _updateUserStatus(String userId, String newStatus) async {
    final success = await context.read<AdminProvider>().updateUserStatus(userId, newStatus);
    
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(success 
              ? 'Statut utilisateur mis à jour' 
              : 'Erreur lors de la mise à jour'),
          backgroundColor: success ? AppColors.successGreen : AppColors.errorRed,
        ),
      );
    }
  }

  String _formatDate(DateTime date) {
    return '${date.day.toString().padLeft(2, '0')}/${date.month.toString().padLeft(2, '0')}/${date.year}';
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
            width: 100,
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