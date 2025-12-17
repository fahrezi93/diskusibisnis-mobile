import '../config/app_config.dart';

class UserProfile {
  final String id;
  final String displayName;
  final String? username;
  final String? email;
  final String? avatarUrl;
  final String? bio;
  final int reputationPoints;
  final DateTime createdAt;
  final bool isVerified;
  final bool hasPassword;
  final String? authProvider; // 'google' or 'email'
  final String role; // 'admin', 'moderator', 'user'

  UserProfile({
    required this.id,
    required this.displayName,
    this.username,
    this.email,
    this.avatarUrl,
    this.bio,
    required this.reputationPoints,
    required this.createdAt,
    required this.isVerified,
    this.hasPassword = false,
    this.authProvider,
    this.role = 'user',
  });

  factory UserProfile.fromJson(Map<String, dynamic> json) {
    // Handle createdAt safely - could be null from backend
    DateTime parsedCreatedAt;
    final createdAtValue = json['createdAt'] ?? json['created_at'];
    if (createdAtValue != null && createdAtValue is String) {
      parsedCreatedAt = DateTime.tryParse(createdAtValue) ?? DateTime.now();
    } else {
      parsedCreatedAt = DateTime.now();
    }

    // Normalize avatar URL - prepend base URL if it's a relative path
    String? avatarUrl = json['avatarUrl'] ?? json['avatar_url'];
    if (avatarUrl != null &&
        avatarUrl.isNotEmpty &&
        !avatarUrl.startsWith('http') &&
        !avatarUrl.startsWith('data:')) {
      avatarUrl = '${AppConfig.baseUrl}$avatarUrl';
    }

    return UserProfile(
      id: json['id']?.toString() ?? '',
      displayName: json['displayName'] ?? json['display_name'] ?? 'User',
      username: json['username'],
      email: json['email'],
      avatarUrl: avatarUrl,
      bio: json['bio'],
      reputationPoints:
          _parseInt(json['reputationPoints'] ?? json['reputation_points']),
      createdAt: parsedCreatedAt,
      isVerified: json['isVerified'] == true ||
          json['isVerified'] == 'true' ||
          json['is_verified'] == true,
      hasPassword: json['hasPassword'] == true || json['has_password'] == true,
      authProvider: json['authProvider'] ?? json['auth_provider'],
      role: json['role'] ?? 'user',
    );
  }
}

int _parseInt(dynamic value) {
  if (value is int) return value;
  if (value is String) return int.tryParse(value) ?? 0;
  return 0;
}
