import 'package:flutter/material.dart';
import 'package:video_player/video_player.dart';
import 'package:audioplayers/audioplayers.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/models/profile.dart';

/// A widget for playing audio and video media files.
///
/// This widget provides:
/// - Video playback with standard controls (play/pause, seek, duration)
/// - Audio playback with custom UI and controls
/// - Progress bar with seek functionality
/// - Automatic resource cleanup
/// - Error handling and loading states
///
/// Example usage:
/// ```dart
/// MediaPlayerWidget(
///   mediaFile: mediaFile,
///   autoPlay: false,
///   showControls: true,
/// )
/// ```
class MediaPlayerWidget extends StatefulWidget {
  final MediaFile mediaFile;
  final bool autoPlay;
  final bool showControls;

  const MediaPlayerWidget({
    super.key,
    required this.mediaFile,
    this.autoPlay = false,
    this.showControls = true,
  });

  @override
  State<MediaPlayerWidget> createState() => _MediaPlayerWidgetState();
}

class _MediaPlayerWidgetState extends State<MediaPlayerWidget> {
  VideoPlayerController? _videoController;
  AudioPlayer? _audioPlayer;
  bool _isPlaying = false;
  bool _isLoading = true;
  String? _errorMessage;
  Duration _currentPosition = Duration.zero;
  Duration _totalDuration = Duration.zero;

  @override
  void initState() {
    super.initState();
    _initializePlayer();
  }

  @override
  void dispose() {
    _videoController?.dispose();
    _audioPlayer?.dispose();
    super.dispose();
  }

  Future<void> _initializePlayer() async {
    try {
      if (widget.mediaFile.type == 'video') {
        _videoController = VideoPlayerController.networkUrl(
          Uri.parse(widget.mediaFile.url),
        );

        await _videoController!.initialize();
        
        _videoController!.addListener(() {
          if (mounted) {
            setState(() {
              _currentPosition = _videoController!.value.position;
              _totalDuration = _videoController!.value.duration;
              _isPlaying = _videoController!.value.isPlaying;
            });
          }
        });

        if (widget.autoPlay) {
          await _videoController!.play();
        }
      } else {
        _audioPlayer = AudioPlayer();
        
        _audioPlayer!.onPositionChanged.listen((position) {
          if (mounted) {
            setState(() {
              _currentPosition = position;
            });
          }
        });

        _audioPlayer!.onDurationChanged.listen((duration) {
          if (mounted) {
            setState(() {
              _totalDuration = duration;
            });
          }
        });

        _audioPlayer!.onPlayerStateChanged.listen((state) {
          if (mounted) {
            setState(() {
              _isPlaying = state == PlayerState.playing;
            });
          }
        });

        _audioPlayer!.onPlayerComplete.listen((_) {
          if (mounted) {
            setState(() {
              _isPlaying = false;
              _currentPosition = Duration.zero;
            });
          }
        });

        if (widget.autoPlay) {
          await _audioPlayer!.play(UrlSource(widget.mediaFile.url));
        }
      }

      setState(() {
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
        _errorMessage = 'Erreur de chargement: ${e.toString()}';
      });
    }
  }

  Future<void> _togglePlayPause() async {
    try {
      if (widget.mediaFile.type == 'video') {
        if (_videoController!.value.isPlaying) {
          await _videoController!.pause();
        } else {
          await _videoController!.play();
        }
      } else {
        if (_isPlaying) {
          await _audioPlayer!.pause();
        } else {
          await _audioPlayer!.play(UrlSource(widget.mediaFile.url));
        }
      }
    } catch (e) {
      setState(() {
        _errorMessage = 'Erreur de lecture: ${e.toString()}';
      });
    }
  }

  Future<void> _seekTo(Duration position) async {
    try {
      if (widget.mediaFile.type == 'video') {
        await _videoController!.seekTo(position);
      } else {
        await _audioPlayer!.seek(position);
      }
    } catch (e) {
      print('Error seeking: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return _buildLoadingWidget();
    }

    if (_errorMessage != null) {
      return _buildErrorWidget();
    }

    if (widget.mediaFile.type == 'video') {
      return _buildVideoPlayer();
    } else {
      return _buildAudioPlayer();
    }
  }

  Widget _buildLoadingWidget() {
    return Container(
      height: 200,
      decoration: BoxDecoration(
        color: AppColors.accentCream.withOpacity(0.3),
        borderRadius: BorderRadius.circular(AppBorderRadius.medium),
      ),
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            CircularProgressIndicator(color: AppColors.primaryGold),
            const SizedBox(height: AppSpacing.md),
            Text(
              'Chargement...',
              style: Theme.of(context).textTheme.bodyMedium,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildErrorWidget() {
    return Container(
      height: 200,
      decoration: BoxDecoration(
        color: AppColors.error.withOpacity(0.1),
        borderRadius: BorderRadius.circular(AppBorderRadius.medium),
        border: Border.all(color: AppColors.error.withOpacity(0.3)),
      ),
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.error_outline, size: 48, color: AppColors.error),
            const SizedBox(height: AppSpacing.md),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
              child: Text(
                _errorMessage!,
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: AppColors.error,
                    ),
                textAlign: TextAlign.center,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildVideoPlayer() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.black,
        borderRadius: BorderRadius.circular(AppBorderRadius.medium),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(AppBorderRadius.medium),
        child: Stack(
          alignment: Alignment.center,
          children: [
            AspectRatio(
              aspectRatio: _videoController!.value.aspectRatio,
              child: VideoPlayer(_videoController!),
            ),
            if (widget.showControls) _buildVideoControls(),
            if (widget.mediaFile.thumbnailUrl != null && !_isPlaying)
              Positioned.fill(
                child: Image.network(
                  widget.mediaFile.thumbnailUrl!,
                  fit: BoxFit.cover,
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildAudioPlayer() {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.lg),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            AppColors.primaryGold.withOpacity(0.1),
            AppColors.accentCream.withOpacity(0.3),
          ],
        ),
        borderRadius: BorderRadius.circular(AppBorderRadius.medium),
        border: Border.all(
          color: AppColors.primaryGold.withOpacity(0.3),
        ),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            Icons.audiotrack,
            size: 64,
            color: AppColors.primaryGold,
          ),
          const SizedBox(height: AppSpacing.md),
          if (widget.showControls) _buildAudioControls(),
        ],
      ),
    );
  }

  Widget _buildVideoControls() {
    return Positioned(
      bottom: 0,
      left: 0,
      right: 0,
      child: Container(
        padding: const EdgeInsets.all(AppSpacing.md),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              Colors.transparent,
              Colors.black.withOpacity(0.7),
            ],
          ),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            _buildProgressBar(),
            const SizedBox(height: AppSpacing.sm),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                IconButton(
                  icon: Icon(
                    _isPlaying ? Icons.pause : Icons.play_arrow,
                    color: Colors.white,
                    size: 32,
                  ),
                  onPressed: _togglePlayPause,
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAudioControls() {
    return Column(
      children: [
        _buildProgressBar(),
        const SizedBox(height: AppSpacing.md),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            IconButton(
              icon: Icon(
                _isPlaying ? Icons.pause_circle_filled : Icons.play_circle_filled,
                color: AppColors.primaryGold,
                size: 48,
              ),
              onPressed: _togglePlayPause,
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildProgressBar() {
    return Column(
      children: [
        SliderTheme(
          data: SliderThemeData(
            trackHeight: 2,
            thumbShape: RoundSliderThumbShape(enabledThumbRadius: 6),
            overlayShape: RoundSliderOverlayShape(overlayRadius: 12),
            activeTrackColor: AppColors.primaryGold,
            inactiveTrackColor: Colors.white.withOpacity(0.3),
            thumbColor: AppColors.primaryGold,
            overlayColor: AppColors.primaryGold.withOpacity(0.2),
          ),
          child: Slider(
            value: _currentPosition.inSeconds.toDouble(),
            min: 0,
            max: _totalDuration.inSeconds.toDouble().clamp(0.1, double.infinity),
            onChanged: (value) {
              _seekTo(Duration(seconds: value.toInt()));
            },
          ),
        ),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: AppSpacing.sm),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                _formatDuration(_currentPosition),
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: widget.mediaFile.type == 'video'
                          ? Colors.white
                          : AppColors.textSecondary,
                    ),
              ),
              Text(
                _formatDuration(_totalDuration),
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: widget.mediaFile.type == 'video'
                          ? Colors.white
                          : AppColors.textSecondary,
                    ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  String _formatDuration(Duration duration) {
    String twoDigits(int n) => n.toString().padLeft(2, '0');
    final minutes = twoDigits(duration.inMinutes.remainder(60));
    final seconds = twoDigits(duration.inSeconds.remainder(60));
    return '$minutes:$seconds';
  }
}
