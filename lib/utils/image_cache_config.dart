import 'package:flutter/material.dart';

/// Configuration for optimized image caching.
/// This significantly improves image loading performance.
class ImageCacheConfig {
  /// Initialize image caching configuration
  /// Call this early in app startup for best performance
  static void initialize() {
    // Configure the Flutter image cache for better performance
    // This is the memory cache used by Image widgets
    PaintingBinding.instance.imageCache.maximumSizeBytes =
        200 * 1024 * 1024; // 200MB memory cache
    PaintingBinding.instance.imageCache.maximumSize =
        1000; // 1000 images max in memory

    debugPrint('[ImageCache] Configured: 200MB memory cache, 1000 images max');
  }

  /// Clear image memory cache
  static void clearCache() {
    PaintingBinding.instance.imageCache.clear();
    PaintingBinding.instance.imageCache.clearLiveImages();
    debugPrint('[ImageCache] Memory cache cleared');
  }

  /// Get cache status for debugging
  static Map<String, dynamic> getCacheStatus() {
    final imageCache = PaintingBinding.instance.imageCache;
    return {
      'currentSize': imageCache.currentSize,
      'currentSizeBytes': imageCache.currentSizeBytes,
      'maximumSize': imageCache.maximumSize,
      'maximumSizeBytes': imageCache.maximumSizeBytes,
    };
  }
}
