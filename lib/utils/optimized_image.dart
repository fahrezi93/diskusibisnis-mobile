import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:lucide_icons/lucide_icons.dart';

import '../config/app_config.dart';

/// Optimized Image Widget with caching, compression, and loading states.
/// This widget significantly improves image loading performance.
class OptimizedImage extends StatelessWidget {
  /// The URL of the image to display
  final String imageUrl;

  /// Width of the image container
  final double? width;

  /// Height of the image container
  final double? height;

  /// How the image should fit in its bounds
  final BoxFit fit;

  /// Border radius for the image
  final double borderRadius;

  /// Whether to show a placeholder while loading
  final bool showPlaceholder;

  /// Whether to show an error widget when loading fails
  final bool showErrorWidget;

  /// Memory cache height (reduces memory usage)
  /// Set to 2-3x the display height for better quality
  final int? memCacheHeight;

  /// Memory cache width
  final int? memCacheWidth;

  /// Maximum disk cache width (reduces storage usage)
  final int maxDiskCacheWidth;

  /// Background color for placeholder/error states
  final Color placeholderColor;

  /// Custom placeholder widget
  final Widget? placeholder;

  /// Custom error widget
  final Widget? errorWidget;

  /// Callback when image is tapped
  final VoidCallback? onTap;

  const OptimizedImage({
    super.key,
    required this.imageUrl,
    this.width,
    this.height,
    this.fit = BoxFit.cover,
    this.borderRadius = 0,
    this.showPlaceholder = true,
    this.showErrorWidget = true,
    this.memCacheHeight,
    this.memCacheWidth,
    this.maxDiskCacheWidth = 1080,
    this.placeholderColor = const Color(0xFFF1F5F9),
    this.placeholder,
    this.errorWidget,
    this.onTap,
  });

  /// Normalize URL - add base URL if needed
  static String normalizeUrl(String url) {
    if (url.isEmpty) return url;
    if (url.startsWith('data:')) return url;
    if (url.startsWith('http://') || url.startsWith('https://')) return url;
    return '${AppConfig.baseUrl}$url';
  }

  @override
  Widget build(BuildContext context) {
    final normalizedUrl = normalizeUrl(imageUrl);

    // Handle empty URL
    if (normalizedUrl.isEmpty) {
      return _buildErrorState();
    }

    // Handle data URLs (base64) - can't be cached
    if (normalizedUrl.startsWith('data:')) {
      return _buildDataImage(normalizedUrl);
    }

    // Use CachedNetworkImage for optimal performance
    Widget imageWidget = CachedNetworkImage(
      imageUrl: normalizedUrl,
      width: width,
      height: height,
      fit: fit,
      // Use imageBuilder for rounded corners (more efficient than ClipRRect)
      imageBuilder: borderRadius > 0
          ? (context, imageProvider) => Container(
                width: width,
                height: height,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(borderRadius),
                  image: DecorationImage(
                    image: imageProvider,
                    fit: fit,
                  ),
                ),
              )
          : null,
      placeholder: showPlaceholder
          ? (context, url) => placeholder ?? _buildPlaceholder()
          : null,
      errorWidget: showErrorWidget
          ? (context, url, error) => errorWidget ?? _buildErrorState()
          : null,
      // Memory cache optimization - reduces RAM usage
      memCacheHeight:
          memCacheHeight ?? (height != null ? (height! * 2).toInt() : 600),
      memCacheWidth:
          memCacheWidth ?? (width != null ? (width! * 2).toInt() : 1080),
      // Disk cache optimization
      maxWidthDiskCache: maxDiskCacheWidth,
      // Fade animation for smooth loading
      fadeInDuration: const Duration(milliseconds: 200),
      fadeOutDuration: const Duration(milliseconds: 100),
    );

    // Wrap with GestureDetector if onTap is provided
    if (onTap != null) {
      imageWidget = GestureDetector(
        onTap: onTap,
        child: imageWidget,
      );
    }

    return imageWidget;
  }

  Widget _buildDataImage(String dataUrl) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(borderRadius),
      child: Image.network(
        dataUrl,
        width: width,
        height: height,
        fit: fit,
        errorBuilder: (_, __, ___) => _buildErrorState(),
      ),
    );
  }

  Widget _buildPlaceholder() {
    return Container(
      width: width,
      height: height,
      decoration: BoxDecoration(
        color: placeholderColor,
        borderRadius: BorderRadius.circular(borderRadius),
      ),
      child: const Center(
        child: SizedBox(
          width: 24,
          height: 24,
          child: CircularProgressIndicator(
            strokeWidth: 2,
            color: Color(0xFF059669),
          ),
        ),
      ),
    );
  }

  Widget _buildErrorState() {
    return Container(
      width: width,
      height: height,
      decoration: BoxDecoration(
        color: placeholderColor,
        borderRadius: BorderRadius.circular(borderRadius),
      ),
      child: const Center(
        child: Icon(
          LucideIcons.imageOff,
          color: Color(0xFFCBD5E1),
          size: 32,
        ),
      ),
    );
  }
}

/// Full screen image viewer with zoom support
class FullScreenImageViewer extends StatelessWidget {
  final String imageUrl;

  const FullScreenImageViewer({
    super.key,
    required this.imageUrl,
  });

  static void show(BuildContext context, String imageUrl) {
    showDialog(
      context: context,
      builder: (context) => FullScreenImageViewer(imageUrl: imageUrl),
    );
  }

  @override
  Widget build(BuildContext context) {
    final normalizedUrl = OptimizedImage.normalizeUrl(imageUrl);

    return Dialog(
      backgroundColor: Colors.transparent,
      insetPadding: const EdgeInsets.all(10),
      child: Stack(
        children: [
          GestureDetector(
            onTap: () => Navigator.pop(context),
            child: Container(
              color: Colors.black.withValues(alpha: 0.9),
              child: Center(
                child: InteractiveViewer(
                  panEnabled: true,
                  minScale: 0.5,
                  maxScale: 4,
                  child: CachedNetworkImage(
                    imageUrl: normalizedUrl,
                    fit: BoxFit.contain,
                    placeholder: (context, url) => const SizedBox(
                      width: 48,
                      height: 48,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: Colors.white54,
                      ),
                    ),
                    errorWidget: (context, url, error) => const Icon(
                      LucideIcons.imageOff,
                      color: Colors.white54,
                      size: 64,
                    ),
                    // Higher resolution for zoom
                    memCacheHeight: 2000,
                    memCacheWidth: 2000,
                    maxWidthDiskCache: 2000,
                  ),
                ),
              ),
            ),
          ),
          Positioned(
            top: 10,
            right: 10,
            child: IconButton(
              icon: const Icon(Icons.close, color: Colors.white, size: 30),
              onPressed: () => Navigator.pop(context),
            ),
          ),
        ],
      ),
    );
  }
}
