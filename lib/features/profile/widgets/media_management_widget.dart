import 'dart:io';
import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/models/profile.dart';
import '../../../core/services/api_service.dart';

/// A widget for managing audio and video media files in user profiles.
///
/// This widget allows users to:
/// - Upload audio files (mp3, wav, m4a, aac, ogg) up to 50MB
/// - Upload video files (mp4, mov, avi, mkv, webm) up to 50MB
/// - Preview uploaded media files
/// - Delete media files with confirmation
/// - Enforce maximum limits (2 audio files, 1 video file by default)
///
/// Example usage:
/// ```dart
/// MediaManagementWidget(
///   mediaFiles: profileProvider.mediaFiles,
///   onMediaFilesChanged: (files) => profileProvider.updateMediaFiles(files),
///   maxAudioFiles: 2,
///   maxVideoFiles: 1,
/// )
/// ```
class MediaManagementWidget extends StatefulWidget {
  final List<MediaFile> mediaFiles;
  final Function(List<MediaFile>) onMediaFilesChanged;
  final int maxAudioFiles;
  final int maxVideoFiles;
  final bool showAddButton;

  const MediaManagementWidget({
    super.key,
    required this.mediaFiles,
    required this.onMediaFilesChanged,
    this.maxAudioFiles = 2,
    this.maxVideoFiles = 1,
    this.showAddButton = true,
  });

  @override
  State<MediaManagementWidget> createState() => _MediaManagementWidgetState();
}

class _MediaManagementWidgetState extends State<MediaManagementWidget> {
  List<MediaFile> _mediaFiles = [];
  bool _isLoading = false;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _mediaFiles = List.from(widget.mediaFiles);
  }

  int get _audioCount =>
      _mediaFiles.where((m) => m.type == 'audio').length;
  int get _videoCount =>
      _mediaFiles.where((m) => m.type == 'video').length;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildHeader(),
        const SizedBox(height: AppSpacing.lg),
        if (_errorMessage != null) ...[
          _buildErrorMessage(),
          const SizedBox(height: AppSpacing.md),
        ],
        _buildMediaList(),
        if (_isLoading) const SizedBox(height: AppSpacing.md),
        if (_isLoading) const LinearProgressIndicator(),
      ],
    );
  }

  Widget _buildHeader() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Médias Audio/Vidéo',
              style: Theme.of(context).textTheme.headlineSmall,
            ),
            Text(
              'Audio: $_audioCount/${widget.maxAudioFiles} | Vidéo: $_videoCount/${widget.maxVideoFiles}',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: AppColors.textSecondary,
                  ),
            ),
          ],
        ),
        if (widget.showAddButton)
          PopupMenuButton<String>(
            icon: Icon(
              Icons.add_circle_outline,
              color: AppColors.primaryGold,
            ),
            onSelected: (value) {
              if (value == 'audio') {
                _addMedia('audio');
              } else if (value == 'video') {
                _addMedia('video');
              }
            },
            itemBuilder: (context) => [
              if (_audioCount < widget.maxAudioFiles)
                PopupMenuItem(
                  value: 'audio',
                  child: Row(
                    children: [
                      Icon(Icons.audiotrack, size: 20),
                      SizedBox(width: AppSpacing.sm),
                      Text('Ajouter Audio'),
                    ],
                  ),
                ),
              if (_videoCount < widget.maxVideoFiles)
                PopupMenuItem(
                  value: 'video',
                  child: Row(
                    children: [
                      Icon(Icons.videocam, size: 20),
                      SizedBox(width: AppSpacing.sm),
                      Text('Ajouter Vidéo'),
                    ],
                  ),
                ),
            ],
          ),
      ],
    );
  }

  Widget _buildErrorMessage() {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: AppColors.error.withOpacity(0.1),
        borderRadius: BorderRadius.circular(AppBorderRadius.medium),
        border: Border.all(color: AppColors.error.withOpacity(0.3)),
      ),
      child: Row(
        children: [
          Icon(Icons.error_outline, color: AppColors.error),
          const SizedBox(width: AppSpacing.sm),
          Expanded(
            child: Text(
              _errorMessage!,
              style: TextStyle(color: AppColors.error),
            ),
          ),
          IconButton(
            icon: Icon(Icons.close, size: 20),
            onPressed: () {
              setState(() {
                _errorMessage = null;
              });
            },
          ),
        ],
      ),
    );
  }

  Widget _buildMediaList() {
    if (_mediaFiles.isEmpty) {
      return Container(
        padding: const EdgeInsets.all(AppSpacing.xl),
        decoration: BoxDecoration(
          color: AppColors.accentCream.withOpacity(0.3),
          borderRadius: BorderRadius.circular(AppBorderRadius.medium),
          border: Border.all(
            color: AppColors.primaryGold.withOpacity(0.3),
            style: BorderStyle.dashed,
          ),
        ),
        child: Center(
          child: Column(
            children: [
              Icon(
                Icons.perm_media,
                size: 48,
                color: AppColors.textSecondary,
              ),
              const SizedBox(height: AppSpacing.sm),
              Text(
                'Aucun média ajouté',
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: AppColors.textSecondary,
                    ),
              ),
              const SizedBox(height: AppSpacing.xs),
              Text(
                'Utilisez le bouton + pour ajouter audio ou vidéo',
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: AppColors.textSecondary,
                    ),
              ),
            ],
          ),
        ),
      );
    }

    return ListView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: _mediaFiles.length,
      itemBuilder: (context, index) {
        return _buildMediaTile(_mediaFiles[index], index);
      },
    );
  }

  Widget _buildMediaTile(MediaFile mediaFile, int index) {
    final isAudio = mediaFile.type == 'audio';
    final icon = isAudio ? Icons.audiotrack : Icons.videocam;
    final color = isAudio ? Colors.blue : Colors.purple;

    return Card(
      margin: const EdgeInsets.only(bottom: AppSpacing.md),
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: color.withOpacity(0.1),
          child: Icon(icon, color: color),
        ),
        title: Text(
          isAudio ? 'Audio ${index + 1}' : 'Vidéo ${index + 1}',
          style: Theme.of(context).textTheme.bodyLarge,
        ),
        subtitle: Text(
          mediaFile.duration != null
              ? _formatDuration(mediaFile.duration!)
              : 'Durée inconnue',
          style: Theme.of(context).textTheme.bodySmall,
        ),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            IconButton(
              icon: Icon(Icons.play_circle_outline),
              onPressed: () => _previewMedia(mediaFile),
              tooltip: 'Prévisualiser',
            ),
            IconButton(
              icon: Icon(Icons.delete_outline, color: AppColors.error),
              onPressed: () => _deleteMedia(mediaFile.id),
              tooltip: 'Supprimer',
            ),
          ],
        ),
      ),
    );
  }

  String _formatDuration(int seconds) {
    final minutes = seconds ~/ 60;
    final remainingSeconds = seconds % 60;
    return '${minutes}:${remainingSeconds.toString().padLeft(2, '0')}';
  }

  Future<void> _addMedia(String type) async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      // Define allowed file extensions and types
      final List<String> allowedExtensions;
      final String fileTypeLabel;
      const int maxFileSizeMB = 50; // 50MB limit

      if (type == 'audio') {
        allowedExtensions = ['mp3', 'wav', 'm4a', 'aac', 'ogg'];
        fileTypeLabel = 'Audio';
      } else {
        allowedExtensions = ['mp4', 'mov', 'avi', 'mkv', 'webm'];
        fileTypeLabel = 'Vidéo';
      }

      // Pick file
      final result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: allowedExtensions,
        allowMultiple: false,
      );

      if (result == null || result.files.isEmpty) {
        setState(() {
          _isLoading = false;
        });
        return;
      }

      final file = result.files.first;

      // Validate file size
      if (file.size > maxFileSizeMB * 1024 * 1024) {
        setState(() {
          _errorMessage =
              'Le fichier est trop volumineux. Taille maximale: ${maxFileSizeMB}MB';
          _isLoading = false;
        });
        return;
      }

      // Validate file extension
      final extension = file.extension?.toLowerCase();
      if (extension == null || !allowedExtensions.contains(extension)) {
        setState(() {
          _errorMessage =
              'Format de fichier non supporté. Formats acceptés: ${allowedExtensions.join(", ")}';
          _isLoading = false;
        });
        return;
      }

      // Upload file
      final response = await ApiService.uploadMediaFile(
        file.path!,
        type: type,
        order: _mediaFiles.length,
      );

      // Parse response and add to list
      final newMediaFile = MediaFile.fromJson(response['data']);
      setState(() {
        _mediaFiles.add(newMediaFile);
        _isLoading = false;
      });

      widget.onMediaFilesChanged(_mediaFiles);

      // Show success message
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('$fileTypeLabel ajouté avec succès'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      setState(() {
        _errorMessage = 'Erreur lors de l\'ajout du fichier: ${e.toString()}';
        _isLoading = false;
      });
    }
  }

  Future<void> _deleteMedia(String mediaId) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Confirmer la suppression'),
        content: Text('Voulez-vous vraiment supprimer ce média ?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: Text('Annuler'),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            style: TextButton.styleFrom(foregroundColor: AppColors.error),
            child: Text('Supprimer'),
          ),
        ],
      ),
    );

    if (confirmed != true) return;

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      await ApiService.deleteMediaFile(mediaId);

      setState(() {
        _mediaFiles.removeWhere((m) => m.id == mediaId);
        _isLoading = false;
      });

      widget.onMediaFilesChanged(_mediaFiles);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Média supprimé avec succès'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      setState(() {
        _errorMessage = 'Erreur lors de la suppression: ${e.toString()}';
        _isLoading = false;
      });
    }
  }

  void _previewMedia(MediaFile mediaFile) {
    // Show preview dialog
    showDialog(
      context: context,
      builder: (context) => MediaPreviewDialog(mediaFile: mediaFile),
    );
  }
}

class MediaPreviewDialog extends StatelessWidget {
  final MediaFile mediaFile;

  const MediaPreviewDialog({super.key, required this.mediaFile});

  @override
  Widget build(BuildContext context) {
    return Dialog(
      child: Container(
        padding: const EdgeInsets.all(AppSpacing.lg),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  mediaFile.type == 'audio' ? 'Audio' : 'Vidéo',
                  style: Theme.of(context).textTheme.headlineSmall,
                ),
                IconButton(
                  icon: Icon(Icons.close),
                  onPressed: () => Navigator.of(context).pop(),
                ),
              ],
            ),
            const SizedBox(height: AppSpacing.md),
            Icon(
              mediaFile.type == 'audio' ? Icons.audiotrack : Icons.videocam,
              size: 64,
              color: AppColors.primaryGold,
            ),
            const SizedBox(height: AppSpacing.md),
            Text(
              'Prévisualisation disponible dans l\'application',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: AppColors.textSecondary,
                  ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: AppSpacing.sm),
            if (mediaFile.duration != null)
              Text(
                'Durée: ${_formatDuration(mediaFile.duration!)}',
                style: Theme.of(context).textTheme.bodySmall,
              ),
          ],
        ),
      ),
    );
  }

  String _formatDuration(int seconds) {
    final minutes = seconds ~/ 60;
    final remainingSeconds = seconds % 60;
    return '${minutes}:${remainingSeconds.toString().padLeft(2, '0')}';
  }
}
