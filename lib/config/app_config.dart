/// App configuration for different environments
import 'package:flutter/foundation.dart';

class AppConfig {
  static const bool forceProduction = false; // SET TO TRUE FOR PRODUCTION

  static bool get isProduction => kReleaseMode || forceProduction;

  // Development URLs (local network)
  // - Android Emulator: use 10.0.2.2
  // - Physical Device: use your computer's IP address (e.g., 192.168.1.x)
  // - iOS Simulator/Web: can use localhost

  // For Physical Device (use computer's IP when testing on real phone)
  static const String _devApiUrl = 'http://192.168.1.2:5000/api';
  static const String _devBaseUrl = 'http://192.168.1.2:5000';

  // Production URLs (Railway)
  static const String _prodApiUrl =
      'https://humble-solace-production-4650.up.railway.app/api';
  static const String _prodBaseUrl =
      'https://humble-solace-production-4650.up.railway.app';

  // Get the correct URL based on environment
  static String get apiUrl => isProduction ? _prodApiUrl : _devApiUrl;
  static String get baseUrl => isProduction ? _prodBaseUrl : _devBaseUrl;
  static String get authUrl => '$apiUrl/auth';

  /// Normalize URL - prepend baseUrl if path is relative
  static String normalizeUrl(String? url) {
    if (url == null || url.isEmpty) return '';
    if (url.startsWith('http://') || url.startsWith('https://')) {
      return url;
    }
    return '$baseUrl$url';
  }

  /// Get avatar URL with proper formatting
  static String getAvatarUrl(String? avatarUrl) {
    if (avatarUrl == null || avatarUrl.isEmpty) return '';
    return normalizeUrl(avatarUrl);
  }
}
