import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/models/profile.dart';
import '../../../core/services/api_service.dart';

class PhotoManagementWidget extends StatefulWidget {
  final List<Photo> photos;
  final Function(List<Photo>) onPhotosChanged;
  final int minPhotos;
  final int maxPhotos;
  final bool showAddButton;

  const PhotoManagementWidget({
    super.key,
    required this.photos,
    required this.onPhotosChanged,
    this.minPhotos = 3,
    this.maxPhotos = 6,
    this.showAddButton = true,
  });

  @override
  State<PhotoManagementWidget> createState() => _PhotoManagementWidgetState();
}

class _PhotoManagementWidgetState extends State<PhotoManagementWidget> {
  final ImagePicker _picker = ImagePicker();
  List<Photo> _photos = [];
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _photos = List.from(widget.photos);
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildHeader(),
        const SizedBox(height: AppSpacing.lg),
        _buildPhotoGrid(),
        if (_isLoading) const SizedBox(height: AppSpacing.md),
        if (_isLoading) const LinearProgressIndicator(),
      ],
    );
  }

  Widget _buildHeader() {
    final hasMinPhotos = _photos.length >= widget.minPhotos;
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Vos Photos',
              style: Theme.of(context).textTheme.headlineSmall,
            ),
            Text(
              '${_photos.length}/${widget.maxPhotos} photos${!hasMinPhotos ? ' (min ${widget.minPhotos})' : ''}',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: hasMinPhotos ? AppColors.textSecondary : AppColors.error,
                  ),
            ),
          ],
        ),
        if (widget.showAddButton && _photos.length < widget.maxPhotos)
          IconButton(
            onPressed: _addPhoto,
            icon: const Icon(Icons.add_photo_alternate),
            style: IconButton.styleFrom(
              backgroundColor: AppColors.primaryGold.withOpacity(0.1),
              foregroundColor: AppColors.primaryGold,
            ),
          ),
      ],
    );
  }

  Widget _buildPhotoGrid() {
    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        crossAxisSpacing: AppSpacing.md,
        mainAxisSpacing: AppSpacing.md,
        childAspectRatio: 0.8,
      ),
      itemCount: widget.maxPhotos,
      itemBuilder: (context, index) {
        final hasPhoto = index < _photos.length;
        if (hasPhoto) {
          return _buildPhotoTile(_photos[index], index);
        } else {
          return _buildEmptyPhotoTile(index);
        }
      },
    );
  }

  Widget _buildPhotoTile(Photo photo, int index) {
    return LongPressDraggable<int>(
      data: index,
      feedback: Material(
        elevation: 8,
        child: Container(
          width: 120,
          height: 150,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(AppBorderRadius.medium),
            image: DecorationImage(
              image: _getImageProvider(photo.url),
              fit: BoxFit.cover,
            ),
          ),
        ),
      ),
      childWhenDragging: Container(
        decoration: BoxDecoration(
          color: AppColors.accentCream.withOpacity(0.5),
          borderRadius: BorderRadius.circular(AppBorderRadius.medium),
          border: Border.all(
            color: AppColors.primaryGold.withOpacity(0.3),
            width: 2,
            style: BorderStyle.solid,
          ),
        ),
        child: const Center(
          child: Icon(
            Icons.drag_indicator,
            color: AppColors.primaryGold,
            size: 32,
          ),
        ),
      ),
      child: DragTarget<int>(
        onAccept: (draggedIndex) {
          if (draggedIndex != index) {
            _onReorder(draggedIndex, index);
          }
        },
        builder: (context, candidateData, rejectedData) {
          final isReceiving = candidateData.isNotEmpty;
          return Card(
            key: ValueKey('photo_${photo.id}'),
            child: Container(
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(AppBorderRadius.medium),
                border: isReceiving
                    ? Border.all(
                        color: AppColors.primaryGold,
                        width: 2,
                      )
                    : null,
                image: DecorationImage(
                  image: _getImageProvider(photo.url),
                  fit: BoxFit.cover,
                  onError: (error, stackTrace) {
                    debugPrint('Error loading image: $error');
                  },
                ),
              ),
              child: Stack(
                children: [
                  // Primary photo indicator
                  if (photo.isPrimary)
                    Positioned(
                      top: 8,
                      left: 8,
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color: AppColors.primaryGold,
                          borderRadius:
                              BorderRadius.circular(AppBorderRadius.small),
                        ),
                        child: Text(
                          'Principal',
                          style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                color: Colors.white,
                                fontWeight: FontWeight.bold,
                              ),
                        ),
                      ),
                    ),

                  // Actions overlay
                  Positioned(
                    top: 8,
                    right: 8,
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        // Set as primary button
                        if (!photo.isPrimary)
                          _buildActionButton(
                            icon: Icons.star_border,
                            onPressed: () => _setPrimaryPhoto(photo),
                            tooltip: 'Définir comme principale',
                          ),

                        const SizedBox(width: 4),

                        // Delete button
                        _buildActionButton(
                          icon: Icons.delete,
                          onPressed: () => _deletePhoto(photo),
                          tooltip: 'Supprimer',
                          color: AppColors.error,
                        ),
                      ],
                    ),
                  ),

                  // Order indicator
                  Positioned(
                    bottom: 8,
                    left: 8,
                    child: Container(
                      width: 24,
                      height: 24,
                      decoration: const BoxDecoration(
                        color: AppColors.primaryGold,
                        shape: BoxShape.circle,
                      ),
                      child: Center(
                        child: Text(
                          '${index + 1}',
                          style:
                              Theme.of(context).textTheme.bodySmall?.copyWith(
                                    color: Colors.white,
                                    fontWeight: FontWeight.bold,
                                  ),
                        ),
                      ),
                    ),
                  ),

                  // Drag handle hint
                  Positioned(
                    bottom: 8,
                    right: 8,
                    child: Container(
                      padding: const EdgeInsets.all(2),
                      decoration: const BoxDecoration(
                        color: Colors.black54,
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(
                        Icons.drag_indicator,
                        color: Colors.white,
                        size: 12,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildEmptyPhotoTile(int index) {
    return DragTarget<int>(
      onAccept: (draggedIndex) {
        // Move dragged photo to this empty position
        if (draggedIndex < _photos.length && index >= _photos.length) {
          _onReorder(draggedIndex, index);
        }
      },
      builder: (context, candidateData, rejectedData) {
        final isReceiving = candidateData.isNotEmpty;
        return Card(
          key: ValueKey('empty_$index'),
          child: InkWell(
            onTap: widget.showAddButton && _photos.length < widget.maxPhotos
                ? _addPhoto
                : null,
            child: Container(
              decoration: BoxDecoration(
                color: isReceiving 
                    ? AppColors.primaryGold.withOpacity(0.1)
                    : AppColors.accentCream,
                borderRadius: BorderRadius.circular(AppBorderRadius.medium),
                border: Border.all(
                  color: isReceiving 
                      ? AppColors.primaryGold
                      : AppColors.dividerLight,
                  width: isReceiving ? 2 : 1,
                  style: BorderStyle.solid,
                ),
              ),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    isReceiving 
                        ? Icons.move_to_inbox
                        : Icons.add_photo_alternate,
                    size: 32,
                    color: isReceiving 
                        ? AppColors.primaryGold
                        : AppColors.textSecondary,
                  ),
                  const SizedBox(height: AppSpacing.xs),
                  Text(
                    isReceiving 
                        ? 'Déposer ici'
                        : (index == 0 ? 'Photo principale' : 'Ajouter une photo'),
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: isReceiving 
                              ? AppColors.primaryGold
                              : AppColors.textSecondary,
                        ),
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildActionButton({
    required IconData icon,
    required VoidCallback onPressed,
    required String tooltip,
    Color? color,
  }) {
    return Container(
      width: 28,
      height: 28,
      decoration: BoxDecoration(
        color: color?.withOpacity(0.9) ?? Colors.black54,
        shape: BoxShape.circle,
      ),
      child: IconButton(
        onPressed: onPressed,
        icon: Icon(icon, size: 14),
        color: Colors.white,
        tooltip: tooltip,
        padding: EdgeInsets.zero,
        constraints: const BoxConstraints(),
      ),
    );
  }

  ImageProvider _getImageProvider(String url) {
    if (url.startsWith('file://')) {
      return FileImage(File(url.replaceFirst('file://', '')));
    } else if (url.startsWith('http')) {
      return NetworkImage(url);
    } else {
      return AssetImage(url);
    }
  }

  Future<void> _addPhoto() async {
    if (_photos.length >= widget.maxPhotos) return;

    try {
      final ImageSource? source = await _showImageSourceDialog();
      if (source == null) return;

      setState(() => _isLoading = true);

      final XFile? image = await _picker.pickImage(
        source: source,
        maxWidth: 1200,
        maxHeight: 1200,
        imageQuality: 85,
      );

      if (image != null && mounted) {
        // Validate image
        final bool isValid = await _validateImage(image);
        if (!isValid) return;

        try {
          // Upload the image to backend
          final response = await ApiService.uploadPhoto(
            image.path,
            order: _photos.length + 1,
          );

          // Create new Photo object from response
          final photoData = response['data'] ?? response;
          final newPhoto = Photo.fromJson(photoData);

          setState(() {
            _photos.add(newPhoto);
          });

          widget.onPhotosChanged(_photos);

          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('Photo ajoutée avec succès'),
                backgroundColor: Colors.green,
              ),
            );
          }
        } catch (uploadError) {
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text('Erreur d\'upload: $uploadError'),
                backgroundColor: AppColors.error,
              ),
            );
          }
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Erreur lors de l\'ajout de la photo: $e'),
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

  Future<bool> _validateImage(XFile image) async {
    try {
      final file = File(image.path);
      final fileSizeInBytes = await file.length();
      const maxSizeInBytes = 10 * 1024 * 1024; // 10MB

      if (fileSizeInBytes > maxSizeInBytes) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('La photo est trop volumineuse (max 10MB)'),
              backgroundColor: Colors.orange,
            ),
          );
        }
        return false;
      }

      // Check image format
      final extension = image.path.toLowerCase().split('.').last;
      final allowedFormats = ['jpg', 'jpeg', 'png', 'heic'];
      
      if (!allowedFormats.contains(extension)) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Format d\'image non supporté (JPG, PNG, HEIC uniquement)'),
              backgroundColor: Colors.orange,
            ),
          );
        }
        return false;
      }

      return true;
    } catch (e) {
      debugPrint('Image validation error: $e');
      return false;
    }
  }

  Future<ImageSource?> _showImageSourceDialog() async {
    return showDialog<ImageSource>(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Choisir une source'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ListTile(
                leading: const Icon(Icons.camera_alt),
                title: const Text('Appareil photo'),
                onTap: () => Navigator.of(context).pop(ImageSource.camera),
              ),
              ListTile(
                leading: const Icon(Icons.photo_library),
                title: const Text('Galerie'),
                onTap: () => Navigator.of(context).pop(ImageSource.gallery),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Annuler'),
            ),
          ],
        );
      },
    );
  }

  Future<void> _deletePhoto(Photo photo) async {
    final bool? confirmed = await showDialog<bool>(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Supprimer la photo'),
          content: const Text('Êtes-vous sûr de vouloir supprimer cette photo ?'),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(false),
              child: const Text('Annuler'),
            ),
            TextButton(
              onPressed: () => Navigator.of(context).pop(true),
              style: TextButton.styleFrom(foregroundColor: AppColors.error),
              child: const Text('Supprimer'),
            ),
          ],
        );
      },
    );

    if (confirmed != true) return;

    setState(() => _isLoading = true);

    try {
      await ApiService.deletePhoto(photo.id);
      
      setState(() {
        _photos.removeWhere((p) => p.id == photo.id);
        // Reorder remaining photos
        for (int i = 0; i < _photos.length; i++) {
          _photos[i] = Photo(
            id: _photos[i].id,
            url: _photos[i].url,
            order: i + 1,
            isPrimary: _photos[i].isPrimary,
            createdAt: _photos[i].createdAt,
          );
        }
      });

      widget.onPhotosChanged(_photos);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Photo supprimée'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Erreur lors de la suppression: $e'),
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

  Future<void> _setPrimaryPhoto(Photo photo) async {
    setState(() => _isLoading = true);

    try {
      await ApiService.setPrimaryPhoto(photo.id);
      
      setState(() {
        // Remove primary status from all photos and set it for the selected one
        _photos = _photos.map((p) => Photo(
          id: p.id,
          url: p.url,
          order: p.order,
          isPrimary: p.id == photo.id,
          createdAt: p.createdAt,
        )).toList();
      });

      widget.onPhotosChanged(_photos);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Photo principale mise à jour'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Erreur lors de la mise à jour: $e'),
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

  void _onReorder(int oldIndex, int newIndex) {
    if (oldIndex >= _photos.length) return;
    
    // If moving to an empty position, just reorder
    if (newIndex >= _photos.length) {
      // This would extend beyond current photos, so we just move to the end
      newIndex = _photos.length - 1;
    }

    setState(() {
      if (newIndex > oldIndex) {
        newIndex -= 1;
      }
      final Photo item = _photos.removeAt(oldIndex);
      _photos.insert(newIndex, item);

      // Update order for all photos
      for (int i = 0; i < _photos.length; i++) {
        _photos[i] = Photo(
          id: _photos[i].id,
          url: _photos[i].url,
          order: i + 1,
          isPrimary: _photos[i].isPrimary,
          createdAt: _photos[i].createdAt,
        );
      }
    });

    // Update backend
    _updatePhotoOrder(_photos[newIndex], newIndex + 1);
    widget.onPhotosChanged(_photos);
  }

  Future<void> _updatePhotoOrder(Photo photo, int newOrder) async {
    try {
      await ApiService.updatePhotoOrder(photo.id, newOrder);
    } catch (e) {
      debugPrint('Error updating photo order: $e');
      // Note: We don't show error to user as this is background operation
    }
  }
}