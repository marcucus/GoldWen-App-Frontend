import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:provider/provider.dart';
import '../../core/services/accessibility_service.dart';
import '../../core/services/performance_cache_service.dart';
import '../../core/theme/app_theme.dart';

/// Optimized image widget with lazy loading, caching, and accessibility features
class OptimizedImage extends StatefulWidget {
  final String? imageUrl;
  final String? semanticLabel;
  final double? width;
  final double? height;
  final BoxFit fit;
  final bool enableHero;
  final String? heroTag;
  final Widget? placeholder;
  final Widget? errorWidget;
  final bool lazyLoad;
  final bool fadeIn;
  final Duration fadeDuration;
  final BorderRadius? borderRadius;
  final List<BoxShadow>? shadows;
  final VoidCallback? onTap;
  final double compressionQuality;

  const OptimizedImage({
    super.key,
    required this.imageUrl,
    this.semanticLabel,
    this.width,
    this.height,
    this.fit = BoxFit.cover,
    this.enableHero = false,
    this.heroTag,
    this.placeholder,
    this.errorWidget,
    this.lazyLoad = true,
    this.fadeIn = true,
    this.fadeDuration = const Duration(milliseconds: 300),
    this.borderRadius,
    this.shadows,
    this.onTap,
    this.compressionQuality = 0.8,
  });

  @override
  State<OptimizedImage> createState() => _OptimizedImageState();
}

class _OptimizedImageState extends State<OptimizedImage>
    with SingleTickerProviderStateMixin {
  late AnimationController _fadeController;
  late Animation<double> _fadeAnimation;
  
  bool _hasError = false;
  bool _isLoaded = false;

  @override
  void initState() {
    super.initState();
    _fadeController = AnimationController(
      duration: widget.fadeDuration,
      vsync: this,
    );
    _fadeAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _fadeController,
      curve: Curves.easeInOut,
    ));
  }

  @override
  void dispose() {
    _fadeController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final accessibilityService = context.watch<AccessibilityService>();
    
    if (widget.imageUrl == null || widget.imageUrl!.isEmpty) {
      return _buildErrorWidget();
    }

    final effectiveFadeDuration = accessibilityService.getAnimationDuration(widget.fadeDuration);
    
    Widget imageWidget = _buildImageWidget(accessibilityService, effectiveFadeDuration);

    // Apply accessibility enhancements
    imageWidget = _applyAccessibilityEnhancements(imageWidget, accessibilityService);

    // Apply decorations
    if (widget.borderRadius != null || widget.shadows != null) {
      imageWidget = Container(
        decoration: BoxDecoration(
          borderRadius: widget.borderRadius,
          boxShadow: widget.shadows,
        ),
        clipBehavior: widget.borderRadius != null ? Clip.antiAlias : Clip.none,
        child: imageWidget,
      );
    }

    // Apply hero animation if enabled
    if (widget.enableHero && widget.heroTag != null) {
      imageWidget = Hero(
        tag: widget.heroTag!,
        child: imageWidget,
      );
    }

    // Apply tap handler
    if (widget.onTap != null) {
      imageWidget = GestureDetector(
        onTap: widget.onTap,
        child: imageWidget,
      );
    }

    return SizedBox(
      width: widget.width,
      height: widget.height,
      child: imageWidget,
    );
  }

  Widget _buildImageWidget(AccessibilityService accessibilityService, Duration fadeDuration) {
    if (widget.lazyLoad) {
      return _buildLazyLoadedImage(accessibilityService, fadeDuration);
    } else {
      return _buildDirectImage(accessibilityService, fadeDuration);
    }
  }

  Widget _buildLazyLoadedImage(AccessibilityService accessibilityService, Duration fadeDuration) {
    return LayoutBuilder(
      builder: (context, constraints) {
        // Only load when the widget is actually visible and has size
        if (constraints.maxWidth <= 0 || constraints.maxHeight <= 0) {
          return _buildPlaceholder();
        }

        return FutureBuilder<Uint8List?>(
          future: context.read<PerformanceCacheService>().loadImageWithCache(
            widget.imageUrl!,
            onProgress: (received, total) {
              // Optional: Update loading progress
            },
          ),
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return _buildPlaceholder();
            }

            if (snapshot.hasError || snapshot.data == null) {
              return _buildErrorWidget();
            }

            return _buildFadeInImage(
              MemoryImage(snapshot.data!),
              accessibilityService,
              fadeDuration,
            );
          },
        );
      },
    );
  }

  Widget _buildDirectImage(AccessibilityService accessibilityService, Duration fadeDuration) {
    return CachedNetworkImage(
      imageUrl: widget.imageUrl!,
      width: widget.width,
      height: widget.height,
      fit: widget.fit,
      fadeInDuration: fadeDuration,
      placeholder: (context, url) => _buildPlaceholder(),
      errorWidget: (context, url, error) => _buildErrorWidget(),
      memCacheWidth: _getMemCacheWidth(),
      memCacheHeight: _getMemCacheHeight(),
      maxWidthDiskCache: _getMaxDiskCacheWidth(),
      maxHeightDiskCache: _getMaxDiskCacheHeight(),
    );
  }

  Widget _buildFadeInImage(ImageProvider imageProvider, AccessibilityService accessibilityService, Duration fadeDuration) {
    if (!widget.fadeIn || accessibilityService.reducedMotion) {
      return Image(
        image: imageProvider,
        width: widget.width,
        height: widget.height,
        fit: widget.fit,
        semanticLabel: widget.semanticLabel,
        errorBuilder: (context, error, stackTrace) => _buildErrorWidget(),
        loadingBuilder: (context, child, loadingProgress) {
          if (loadingProgress == null) {
            _isLoaded = true;
            return child;
          }
          return _buildPlaceholder();
        },
      );
    }

    return AnimatedBuilder(
      animation: _fadeAnimation,
      builder: (context, child) {
        return Opacity(
          opacity: _isLoaded ? _fadeAnimation.value : 0.0,
          child: Image(
            image: imageProvider,
            width: widget.width,
            height: widget.height,
            fit: widget.fit,
            semanticLabel: widget.semanticLabel,
            errorBuilder: (context, error, stackTrace) => _buildErrorWidget(),
            loadingBuilder: (context, child, loadingProgress) {
              if (loadingProgress == null) {
                if (!_isLoaded) {
                  _isLoaded = true;
                  _fadeController.forward();
                }
                return child;
              }
              return _buildPlaceholder();
            },
          ),
        );
      },
    );
  }

  Widget _buildPlaceholder() {
    if (widget.placeholder != null) {
      return widget.placeholder!;
    }

    return Container(
      width: widget.width,
      height: widget.height,
      decoration: BoxDecoration(
        color: AppColors.backgroundGrey,
        borderRadius: widget.borderRadius,
      ),
      child: const Center(
        child: CircularProgressIndicator(
          valueColor: AlwaysStoppedAnimation<Color>(AppColors.primaryGold),
          strokeWidth: 2,
        ),
      ),
    );
  }

  Widget _buildErrorWidget() {
    if (widget.errorWidget != null) {
      return widget.errorWidget!;
    }

    return Container(
      width: widget.width,
      height: widget.height,
      decoration: BoxDecoration(
        color: AppColors.backgroundGrey,
        borderRadius: widget.borderRadius,
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.image_not_supported_outlined,
            size: (widget.width != null && widget.width! < 100) ? 24 : 48,
            color: AppColors.textMuted,
          ),
          if (widget.width == null || widget.width! >= 100) ...[
            const SizedBox(height: AppSpacing.sm),
            Text(
              'Image non disponible',
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: AppColors.textMuted,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ],
      ),
    );
  }

  Widget _applyAccessibilityEnhancements(Widget child, AccessibilityService accessibilityService) {
    return Semantics(
      label: widget.semanticLabel ?? 'Image',
      image: true,
      child: ExcludeSemantics(
        excluding: widget.semanticLabel == null,
        child: child,
      ),
    );
  }

  int? _getMemCacheWidth() {
    if (widget.width == null) return null;
    return (widget.width! * MediaQuery.of(context).devicePixelRatio * widget.compressionQuality).round();
  }

  int? _getMemCacheHeight() {
    if (widget.height == null) return null;
    return (widget.height! * MediaQuery.of(context).devicePixelRatio * widget.compressionQuality).round();
  }

  int? _getMaxDiskCacheWidth() {
    if (widget.width == null) return null;
    return (widget.width! * 2).round(); // Allow 2x for high-DPI screens
  }

  int? _getMaxDiskCacheHeight() {
    if (widget.height == null) return null;
    return (widget.height! * 2).round(); // Allow 2x for high-DPI screens
  }
}

/// Specialized widget for profile images with optimized loading
class ProfileImage extends StatelessWidget {
  final String? imageUrl;
  final double size;
  final String? name;
  final bool enableHero;
  final VoidCallback? onTap;

  const ProfileImage({
    super.key,
    required this.imageUrl,
    required this.size,
    this.name,
    this.enableHero = false,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return OptimizedImage(
      imageUrl: imageUrl,
      width: size,
      height: size,
      fit: BoxFit.cover,
      enableHero: enableHero,
      heroTag: enableHero ? 'profile_$imageUrl' : null,
      semanticLabel: name != null ? 'Photo de profil de $name' : 'Photo de profil',
      borderRadius: BorderRadius.circular(size / 2),
      shadows: AppShadows.soft(),
      onTap: onTap,
      placeholder: Container(
        width: size,
        height: size,
        decoration: BoxDecoration(
          color: AppColors.primaryGold.withOpacity(0.3),
          shape: BoxShape.circle,
        ),
        child: Icon(
          Icons.person,
          size: size * 0.6,
          color: Colors.white,
        ),
      ),
      errorWidget: Container(
        width: size,
        height: size,
        decoration: BoxDecoration(
          color: AppColors.primaryGold.withOpacity(0.3),
          shape: BoxShape.circle,
        ),
        child: Icon(
          Icons.person,
          size: size * 0.6,
          color: Colors.white,
        ),
      ),
    );
  }
}

/// Grid of images with lazy loading and preloading
class LazyImageGrid extends StatefulWidget {
  final List<String> imageUrls;
  final List<String>? semanticLabels;
  final double aspectRatio;
  final int crossAxisCount;
  final double crossAxisSpacing;
  final double mainAxisSpacing;
  final void Function(int index, String url)? onImageTap;
  final bool preloadImages;

  const LazyImageGrid({
    super.key,
    required this.imageUrls,
    this.semanticLabels,
    this.aspectRatio = 1.0,
    this.crossAxisCount = 2,
    this.crossAxisSpacing = AppSpacing.md,
    this.mainAxisSpacing = AppSpacing.md,
    this.onImageTap,
    this.preloadImages = true,
  });

  @override
  State<LazyImageGrid> createState() => _LazyImageGridState();
}

class _LazyImageGridState extends State<LazyImageGrid> {
  final Set<int> _visibleIndices = <int>{};

  @override
  void initState() {
    super.initState();
    if (widget.preloadImages) {
      _preloadVisibleImages();
    }
  }

  void _preloadVisibleImages() {
    // Preload first few images that will be immediately visible
    final initialLoadCount = (widget.crossAxisCount * 2).clamp(1, widget.imageUrls.length);
    final cacheService = context.read<PerformanceCacheService>();
    
    for (int i = 0; i < initialLoadCount; i++) {
      cacheService.loadImageWithCache(widget.imageUrls[i]);
    }
  }

  @override
  Widget build(BuildContext context) {
    return GridView.builder(
      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: widget.crossAxisCount,
        crossAxisSpacing: widget.crossAxisSpacing,
        mainAxisSpacing: widget.mainAxisSpacing,
        childAspectRatio: widget.aspectRatio,
      ),
      itemCount: widget.imageUrls.length,
      itemBuilder: (context, index) {
        final imageUrl = widget.imageUrls[index];
        final semanticLabel = widget.semanticLabels?.elementAtOrNull(index);
        
        return OptimizedImage(
          imageUrl: imageUrl,
          semanticLabel: semanticLabel ?? 'Image ${index + 1}',
          fit: BoxFit.cover,
          borderRadius: BorderRadius.circular(AppBorderRadius.medium),
          lazyLoad: !_visibleIndices.contains(index),
          onTap: widget.onImageTap != null 
              ? () => widget.onImageTap!(index, imageUrl)
              : null,
        );
      },
    );
  }
}