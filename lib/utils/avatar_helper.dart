import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';

import '../config/app_config.dart';

/// Centralized avatar helper to ensure consistent avatar handling across the app.
class AvatarHelper {
  /// Base URL - now using AppConfig for environment switching
  static String get _baseUrl => AppConfig.baseUrl;

  /// Normalize avatar URL to ensure it's a valid absolute URL
  static String? normalizeUrl(String? url) {
    if (url == null || url.isEmpty) return null;
    if (url.startsWith('data:')) return url;
    if (url.startsWith('http://') || url.startsWith('https://')) return url;
    return '$_baseUrl$url';
  }

  /// Helper for Reputation Colors
  static Color getReputationColor(int points) {
    if (points >= 500) return const Color(0xFFF59E0B); // Amber 500
    if (points >= 100) return const Color(0xFF059669); // Emerald 600
    if (points >= 10) return const Color(0xFF3B82F6); // Blue 500
    return const Color(0xFFE2E8F0); // Slate 200
  }

  /// Build a CircleAvatar widget with proper error handling and caching
  static Widget buildAvatar(
    String? avatarUrl,
    String name, {
    double radius = 20,
    Color? backgroundColor,
    Color? textColor,
  }) {
    final url = normalizeUrl(avatarUrl);
    final bgColor = backgroundColor ?? Colors.grey[200];
    final fgColor = textColor ?? const Color(0xFF059669);

    if (url == null) {
      return CircleAvatar(
        radius: radius,
        backgroundColor: bgColor,
        child: Text(
          _getInitials(name),
          style: TextStyle(
            fontSize: radius * 0.7,
            fontWeight: FontWeight.bold,
            color: fgColor,
          ),
        ),
      );
    }

    if (url.startsWith('data:')) {
      return ClipOval(
        child: Image.network(
          url,
          width: radius * 2,
          height: radius * 2,
          fit: BoxFit.cover,
          cacheWidth: (radius * 4).toInt(),
          cacheHeight: (radius * 4).toInt(),
          errorBuilder: (_, __, ___) => CircleAvatar(
            radius: radius,
            backgroundColor: bgColor,
            child: Text(
              _getInitials(name),
              style: TextStyle(
                fontSize: radius * 0.7,
                fontWeight: FontWeight.bold,
                color: fgColor,
              ),
            ),
          ),
        ),
      );
    }

    return CachedNetworkImage(
      imageUrl: url,
      imageBuilder: (context, imageProvider) => CircleAvatar(
        radius: radius,
        backgroundImage: imageProvider,
      ),
      placeholder: (context, url) => CircleAvatar(
        radius: radius,
        backgroundColor: bgColor,
        child: SizedBox(
          width: radius * 0.8,
          height: radius * 0.8,
          child: const CircularProgressIndicator(
            strokeWidth: 2,
            color: Color(0xFF059669),
          ),
        ),
      ),
      errorWidget: (context, url, error) => CircleAvatar(
        radius: radius,
        backgroundColor: bgColor,
        child: Text(
          _getInitials(name),
          style: TextStyle(
            fontSize: radius * 0.7,
            fontWeight: FontWeight.bold,
            color: fgColor,
          ),
        ),
      ),
      memCacheHeight: (radius * 4).toInt(),
      memCacheWidth: (radius * 4).toInt(),
    );
  }

  /// Build an avatar with Reputation Ring (Badge is now separate)
  static Widget buildAvatarWithBadge({
    required String? avatarUrl,
    required String name,
    required int reputation,
    bool isVerified =
        false, // Kept for backward compatibility but unused for overlay
    double radius = 20,
    double ringWidth = 2,
    double badgeSize = 14,
  }) {
    // Only show reputation ring if points > 0
    if (reputation <= 0) {
      return buildAvatar(avatarUrl, name, radius: radius);
    }

    return Container(
      padding: EdgeInsets.all(ringWidth),
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: getReputationColor(reputation),
      ),
      child: Container(
        decoration: const BoxDecoration(
          shape: BoxShape.circle,
          color: Colors.white,
        ),
        padding: const EdgeInsets.all(1),
        child: buildAvatar(
          avatarUrl,
          name,
          radius: radius,
        ),
      ),
    );
  }

  static String _getInitials(String name) {
    if (name.isEmpty) return '?';
    final parts = name.trim().split(' ');
    if (parts.length == 1) return parts[0][0].toUpperCase();
    return '${parts[0][0]}${parts.last[0]}'.toUpperCase();
  }

  /// Build a square avatar widget with rounded corners (for profile pages)
  static Widget buildSquareAvatar(
    String? avatarUrl,
    String name, {
    double size = 80,
    double borderRadius = 12,
    Color? backgroundColor,
    Color? textColor,
  }) {
    final url = normalizeUrl(avatarUrl);
    final bgColor = backgroundColor ?? Colors.grey[200];
    final fgColor = textColor ?? const Color(0xFF059669);

    if (url == null) {
      return Container(
        width: size,
        height: size,
        decoration: BoxDecoration(
          color: bgColor,
          borderRadius: BorderRadius.circular(borderRadius),
        ),
        child: Center(
          child: Text(
            _getInitials(name),
            style: TextStyle(
              fontSize: size * 0.35,
              fontWeight: FontWeight.bold,
              color: fgColor,
            ),
          ),
        ),
      );
    }

    if (url.startsWith('data:')) {
      return ClipRRect(
        borderRadius: BorderRadius.circular(borderRadius),
        child: Image.network(
          url,
          width: size,
          height: size,
          fit: BoxFit.cover,
          cacheWidth: (size * 2).toInt(),
          cacheHeight: (size * 2).toInt(),
          errorBuilder: (_, __, ___) => Container(
            width: size,
            height: size,
            decoration: BoxDecoration(
              color: bgColor,
              borderRadius: BorderRadius.circular(borderRadius),
            ),
            child: Center(
              child: Text(
                _getInitials(name),
                style: TextStyle(
                  fontSize: size * 0.35,
                  fontWeight: FontWeight.bold,
                  color: fgColor,
                ),
              ),
            ),
          ),
        ),
      );
    }

    return ClipRRect(
      borderRadius: BorderRadius.circular(borderRadius),
      child: CachedNetworkImage(
        imageUrl: url,
        width: size,
        height: size,
        fit: BoxFit.cover,
        placeholder: (context, url) => Container(
          width: size,
          height: size,
          color: bgColor,
          child: const Center(
            child: SizedBox(
              width: 20,
              height: 20,
              child: CircularProgressIndicator(
                strokeWidth: 2,
                color: Color(0xFF059669),
              ),
            ),
          ),
        ),
        errorWidget: (context, url, error) => Container(
          width: size,
          height: size,
          decoration: BoxDecoration(
            color: bgColor,
            borderRadius: BorderRadius.circular(borderRadius),
          ),
          child: Center(
            child: Text(
              _getInitials(name),
              style: TextStyle(
                fontSize: size * 0.35,
                fontWeight: FontWeight.bold,
                color: fgColor,
              ),
            ),
          ),
        ),
        memCacheHeight: (size * 2).toInt(),
        memCacheWidth: (size * 2).toInt(),
      ),
    );
  }

  /// Build a square avatar with Verified Badge (Badge removed from overlay)
  static Widget buildSquareAvatarWithBadge({
    required String? avatarUrl,
    required String name,
    bool isVerified = false, // Kept for API compatibility
    double size = 80,
    double borderRadius = 12,
  }) {
    return buildSquareAvatar(
      avatarUrl,
      name,
      size: size,
      borderRadius: borderRadius,
    );
  }

  /// Helper to build the standard Verified Badge (Blue Check)
  static Widget getVerifiedBadge({double size = 16}) {
    return Padding(
      padding: const EdgeInsets.only(left: 4),
      child: Icon(
        Icons.verified, // Using Material Verified icon for "Meta" look
        size: size,
        color: const Color(0xFF1D9BF0), // Twitter/Meta Blue
      ),
    );
  }
}
