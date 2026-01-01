import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:uuid/uuid.dart';
import '../config/app_config.dart';

/// Model for Promo Popup
class PromoPopup {
  final String id;
  final String title;
  final String imageUrl;
  final String? linkUrl;
  final String? linkType;
  final String? description;
  final DateTime startDate;
  final DateTime? endDate;
  final bool isActive;
  final int priority;
  final String targetAudience;
  final bool showOncePerUser;
  final DateTime createdAt;

  PromoPopup({
    required this.id,
    required this.title,
    required this.imageUrl,
    this.linkUrl,
    this.linkType,
    this.description,
    required this.startDate,
    this.endDate,
    required this.isActive,
    required this.priority,
    required this.targetAudience,
    required this.showOncePerUser,
    required this.createdAt,
  });

  factory PromoPopup.fromJson(Map<String, dynamic> json) {
    return PromoPopup(
      id: json['id'],
      title: json['title'],
      imageUrl: json['image_url'],
      linkUrl: json['link_url'],
      linkType: json['link_type'],
      description: json['description'],
      startDate: DateTime.parse(json['start_date']),
      endDate:
          json['end_date'] != null ? DateTime.parse(json['end_date']) : null,
      isActive: json['is_active'] ?? true,
      priority: json['priority'] ?? 0,
      targetAudience: json['target_audience'] ?? 'all',
      showOncePerUser: json['show_once_per_user'] ?? false,
      createdAt: DateTime.parse(json['created_at']),
    );
  }
}

/// Service to handle Promo Popups
class PopupService {
  static final PopupService _instance = PopupService._internal();
  factory PopupService() => _instance;
  PopupService._internal();

  static const FlutterSecureStorage _secureStorage = FlutterSecureStorage();
  static const String _deviceIdKey = 'popup_device_id';

  String? _deviceId;

  /// Get or create device ID for tracking popup views (for guests)
  Future<String> _getDeviceId() async {
    if (_deviceId != null) return _deviceId!;

    _deviceId = await _secureStorage.read(key: _deviceIdKey);
    if (_deviceId == null) {
      _deviceId = const Uuid().v4();
      await _secureStorage.write(key: _deviceIdKey, value: _deviceId);
    }
    return _deviceId!;
  }

  /// Get the active popup to display
  Future<PromoPopup?> getActivePopup() async {
    try {
      final deviceId = await _getDeviceId();
      final token = await _secureStorage.read(key: 'auth_token');

      final response = await http.get(
        Uri.parse('${AppConfig.apiUrl}/popups/active'),
        headers: {
          'Content-Type': 'application/json',
          'x-device-id': deviceId,
          if (token != null) 'Authorization': 'Bearer $token',
        },
      ).timeout(const Duration(seconds: 10));

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (data['data']['popup'] != null) {
          return PromoPopup.fromJson(data['data']['popup']);
        }
      }
      return null;
    } catch (e) {
      print('[PopupService] Error getting active popup: $e');
      return null;
    }
  }

  /// Record that user has viewed/dismissed a popup
  Future<void> recordPopupView(String popupId, {bool clicked = false}) async {
    try {
      final deviceId = await _getDeviceId();
      final token = await _secureStorage.read(key: 'auth_token');

      await http
          .post(
            Uri.parse('${AppConfig.apiUrl}/popups/$popupId/view'),
            headers: {
              'Content-Type': 'application/json',
              'x-device-id': deviceId,
              if (token != null) 'Authorization': 'Bearer $token',
            },
            body: jsonEncode({'clicked': clicked}),
          )
          .timeout(const Duration(seconds: 5));
    } catch (e) {
      print('[PopupService] Error recording popup view: $e');
    }
  }
}
