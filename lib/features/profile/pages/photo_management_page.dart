import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/models/profile.dart';
import '../widgets/photo_management_widget.dart';
import '../providers/profile_provider.dart';

class PhotoManagementPage extends StatefulWidget {
  const PhotoManagementPage({super.key});

  @override
  State<PhotoManagementPage> createState() => _PhotoManagementPageState();
}

class _PhotoManagementPageState extends State<PhotoManagementPage> {
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadProfile();
  }

  Future<void> _loadProfile() async {
    try {
      final profileProvider =
          Provider.of<ProfileProvider>(context, listen: false);
      await profileProvider.loadProfile();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Erreur lors du chargement du profil: $e'),
            backgroundColor: AppColors.error,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Gestion des Photos'),
        centerTitle: true,
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(AppSpacing.lg),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Card(
                    child: Padding(
                      padding: const EdgeInsets.all(AppSpacing.md),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Icon(
                                Icons.info_outline,
                                color: AppColors.primaryGold,
                              ),
                              const SizedBox(width: AppSpacing.sm),
                              Text(
                                'Conseils pour vos photos',
                                style: Theme.of(context)
                                    .textTheme
                                    .titleMedium
                                    ?.copyWith(
                                      color: AppColors.primaryGold,
                                      fontWeight: FontWeight.bold,
                                    ),
                              ),
                            ],
                          ),
                          const SizedBox(height: AppSpacing.sm),
                          const Text(
                              '• Ajoutez au moins 3 photos pour optimiser votre profil\n'
                              '• La première photo sera votre photo principale\n'
                              '• Utilisez des photos récentes et de bonne qualité\n'
                              '• Glissez-déposez pour réorganiser l\'ordre\n'
                              '• Formats acceptés: JPG, PNG, HEIC (max 10MB)'),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: AppSpacing.lg),
                  Consumer<ProfileProvider>(
                    builder: (context, profileProvider, child) {
                      return PhotoManagementWidget(
                        photos: profileProvider.photos,
                        onPhotosChanged: (photos) {
                          profileProvider.updatePhotos(photos);
                          _showSuccessMessage(
                              'Photos mises à jour avec succès');
                        },
                        minPhotos: 3,
                        maxPhotos: 6,
                        showAddButton: true,
                      );
                    },
                  ),
                  const SizedBox(height: AppSpacing.xl),
                  Consumer<ProfileProvider>(
                    builder: (context, profileProvider, child) {
                      final photoCount = profileProvider.photos.length;
                      final hasMinPhotos = photoCount >= 3;

                      return Card(
                        color: hasMinPhotos
                            ? AppColors.successGreen.withOpacity(0.1)
                            : AppColors.warningAmber.withOpacity(0.1),
                        child: Padding(
                          padding: const EdgeInsets.all(AppSpacing.md),
                          child: Row(
                            children: [
                              Icon(
                                hasMinPhotos
                                    ? Icons.check_circle
                                    : Icons.warning,
                                color: hasMinPhotos
                                    ? AppColors.successGreen
                                    : AppColors.warningAmber,
                              ),
                              const SizedBox(width: AppSpacing.sm),
                              Expanded(
                                child: Text(
                                  hasMinPhotos
                                      ? 'Votre profil respecte le minimum de photos requis ✓'
                                      : 'Ajoutez encore ${3 - photoCount} photo${3 - photoCount > 1 ? 's' : ''} pour compléter votre profil',
                                  style: Theme.of(context)
                                      .textTheme
                                      .bodyMedium
                                      ?.copyWith(
                                        fontWeight: FontWeight.w500,
                                      ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
                ],
              ),
            ),
      floatingActionButton: Consumer<ProfileProvider>(
        builder: (context, profileProvider, child) {
          if (profileProvider.photos.length >= 6) return Container();
          
          return FloatingActionButton(
            onPressed: () {
              // Trigger photo addition through the widget
              // The PhotoManagementWidget handles the actual photo adding
            },
            backgroundColor: AppColors.primaryGold,
            child: const Icon(Icons.add_a_photo, color: Colors.white),
          );
        },
      ),
    );
  }

  void _showSuccessMessage(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: AppColors.successGreen,
      ),
    );
  }
}