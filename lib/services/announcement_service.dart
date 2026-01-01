import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:uuid/uuid.dart';
import '../config/app_config.dart';

/// Model for Announcement
class Announcement {
  final String id;
  final String title;
  final String message;
  final String type; // info, warning, success, error, promo
  final String? linkUrl;
  final String? linkText;
  final DateTime startDate;
  final DateTime? endDate;
  final bool isActive;
  final bool isDismissible;
  final int priority;
  final String showOn;
  final DateTime createdAt;

  Announcement({
    required this.id,
    required this.title,
    required this.message,
    required this.type,
    this.linkUrl,
    this.linkText,
    required this.startDate,
    this.endDate,
    required this.isActive,
    required this.isDismissible,
    required this.priority,
    required this.showOn,
    required this.createdAt,
  });

  factory Announcement.fromJson(Map<String, dynamic> json) {
    return Announcement(
      id: json['id'],
      title: json['title'],
      message: json['message'],
      type: json['type'] ?? 'info',
      linkUrl: json['link_url'],
      linkText: json['link_text'],
      startDate: DateTime.parse(json['start_date']),
      endDate:
          json['end_date'] != null ? DateTime.parse(json['end_date']) : null,
      isActive: json['is_active'] ?? true,
      isDismissible: json['is_dismissible'] ?? true,
      priority: json['priority'] ?? 0,
      showOn: json['show_on'] ?? 'all',
      createdAt: DateTime.parse(json['created_at']),
    );
  }
}

/// Service to handle Announcements
class AnnouncementService {
  static final AnnouncementService _instance = AnnouncementService._internal();
  factory AnnouncementService() => _instance;
  AnnouncementService._internal();

  static const FlutterSecureStorage _secureStorage = FlutterSecureStorage();
  static const String _deviceIdKey = 'announcement_device_id';

  String? _deviceId;

  /// Get or create device ID for tracking dismissals
  Future<String> _getDeviceId() async {
    if (_deviceId != null) return _deviceId!;

    _deviceId = await _secureStorage.read(key: _deviceIdKey);
    if (_deviceId == null) {
      _deviceId = const Uuid().v4();
      await _secureStorage.write(key: _deviceIdKey, value: _deviceId);
    }
    return _deviceId!;
  }

  /// Get active announcements
  Future<List<Announcement>> getActiveAnnouncements(
      {String showOn = 'all'}) async {
    try {
      final deviceId = await _getDeviceId();
      final token = await _secureStorage.read(key: 'auth_token');

      final response = await http.get(
        Uri.parse('${AppConfig.apiUrl}/announcements/active?showOn=$showOn'),
        headers: {
          'Content-Type': 'application/json',
          'x-device-id': deviceId,
          if (token != null) 'Authorization': 'Bearer $token',
        },
      ).timeout(const Duration(seconds: 10));

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final List<dynamic> announcementsJson =
            data['data']['announcements'] ?? [];
        return announcementsJson
            .map((json) => Announcement.fromJson(json))
            .toList();
      }
      return [];
    } catch (e) {
      print('[AnnouncementService] Error getting announcements: $e');
      return [];
    }
  }

  /// Dismiss an announcement
  Future<void> dismissAnnouncement(String announcementId) async {
    try {
      final deviceId = await _getDeviceId();
      final token = await _secureStorage.read(key: 'auth_token');

      await http.post(
        Uri.parse('${AppConfig.apiUrl}/announcements/$announcementId/dismiss'),
        headers: {
          'Content-Type': 'application/json',
          'x-device-id': deviceId,
          if (token != null) 'Authorization': 'Bearer $token',
        },
      ).timeout(const Duration(seconds: 5));
    } catch (e) {
      print('[AnnouncementService] Error dismissing announcement: $e');
    }
  }
}
