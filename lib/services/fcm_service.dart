import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';
import 'dart:async';
import 'package:http/http.dart' as http;
import '../config/app_config.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';

// Background message handler (must be top-level function)
@pragma('vm:entry-point')
Future<void> _firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  print('Handling a background message: ${message.messageId}');
}

class FCMService {
  // Singleton pattern so we can access the same instance from anywhere
  static final FCMService _instance = FCMService._internal();

  factory FCMService() {
    return _instance;
  }

  FCMService._internal();

  // Changed to late to allow manual initialization check
  late final FirebaseMessaging _messaging;
  final FlutterLocalNotificationsPlugin _localNotifications =
      FlutterLocalNotificationsPlugin();

  // Stream controller to broadcast notification events to UI
  final _notificationStreamController =
      StreamController<RemoteMessage>.broadcast();
  Stream<RemoteMessage> get onNotificationReceived =>
      _notificationStreamController.stream;

  String? _fcmToken;

  String? get fcmToken => _fcmToken;

  Future<void> initialize() async {
    // 0. Initialize Firebase Messaging Instance safely
    try {
      _messaging = FirebaseMessaging.instance;
    } catch (e) {
      print('Error Initialize FirebaseMessaging instance: $e');
      return;
    }

    // 1. Initialize Local Notifications
    const AndroidInitializationSettings initializationSettingsAndroid =
        AndroidInitializationSettings('@drawable/ic_notification');

    final DarwinInitializationSettings initializationSettingsDarwin =
        DarwinInitializationSettings();

    final InitializationSettings initializationSettings =
        InitializationSettings(
      android: initializationSettingsAndroid,
      iOS: initializationSettingsDarwin,
    );

    await _localNotifications.initialize(
      initializationSettings,
      onDidReceiveNotificationResponse: (NotificationResponse response) {
        // Handle notification tap
        print('Notification tapped: ${response.payload}');
      },
    );

    // Create high importance channel for Android
    if (!kIsWeb) {
      await _localNotifications
          .resolvePlatformSpecificImplementation<
              AndroidFlutterLocalNotificationsPlugin>()
          ?.createNotificationChannel(const AndroidNotificationChannel(
            'high_importance_channel', // id
            'High Importance Notifications', // title
            description:
                'This channel is used for important notifications.', // description
            importance: Importance.high,
          ));
    }

    // 2. Request permission for Firebase Messaging
    NotificationSettings settings = await _messaging.requestPermission(
      alert: true,
      badge: true,
      sound: true,
      provisional: false,
    );

    if (settings.authorizationStatus == AuthorizationStatus.authorized) {
      print('User granted permission for notifications');

      // 3. Get FCM Token
      try {
        _fcmToken = await _messaging.getToken(
          vapidKey: kIsWeb
              ? 'BAaXUOU0lBVd4PCprGeUqRSta0DowX6w7c5l1QtQio-GWc6_nUM6hW0TihD-UeWrI4LXbpIZ28pjN_kLbZRTNCQ'
              : null,
        );
        print('FCM Token: $_fcmToken');

        if (_fcmToken != null) {
          final prefs = await SharedPreferences.getInstance();
          await prefs.setString('fcm_token', _fcmToken!);
          await _sendTokenToBackend(_fcmToken!);
        }
      } catch (e) {
        print('Error getting FCM token: $e');
      }

      // 4. Listen for token refresh
      _messaging.onTokenRefresh.listen((newToken) async {
        _fcmToken = newToken;
        final prefs = await SharedPreferences.getInstance();
        await prefs.setString('fcm_token', newToken);
        await _sendTokenToBackend(newToken);
      });

      // 5. Handle foreground messages
      FirebaseMessaging.onMessage.listen(_handleForegroundMessage);

      // 6. Handle background messages (Android/iOS only)
      if (!kIsWeb) {
        FirebaseMessaging.onBackgroundMessage(
            _firebaseMessagingBackgroundHandler);
      }
    } else {
      print('User declined notification permission');
    }
  }

  void _handleForegroundMessage(RemoteMessage message) {
    print('Got a message whilst in the foreground!');

    // Broadcast message to listeners (e.g., NotificationsScreen)
    _notificationStreamController.add(message);

    print('Message data: ${message.data}');

    RemoteNotification? notification = message.notification;
    AndroidNotification? android = message.notification?.android;

    if (notification != null && android != null && !kIsWeb) {
      // Show local notification
      _localNotifications.show(
        notification.hashCode,
        notification.title,
        notification.body,
        NotificationDetails(
          android: AndroidNotificationDetails(
            'high_importance_channel',
            'High Importance Notifications',
            channelDescription:
                'This channel is used for important notifications.',
            icon: '@mipmap/ic_launcher',
            importance: Importance.high,
            priority: Priority.high,
          ),
        ),
      );
    }
  }

  Future<void> _sendTokenToBackend(String token) async {
    try {
      const secureStorage = FlutterSecureStorage();
      final authToken = await secureStorage.read(key: 'auth_token');

      if (authToken == null) return;

      final response = await http
          .post(
            Uri.parse('${AppConfig.apiUrl}/notifications/register-token'),
            headers: {
              'Content-Type': 'application/json',
              'Authorization': 'Bearer $authToken',
            },
            body: jsonEncode({
              'fcmToken': token,
              'deviceType': 'android', // Identifies this as mobile device
              'deviceName': 'DiskusiBisnis Mobile App',
            }),
          )
          .timeout(const Duration(seconds: 10));

      if (response.statusCode == 200) {
        print('FCM token sent to backend successfully (Android)');
      } else {
        print('Failed to send FCM token to backend: ${response.statusCode}');
      }
    } catch (e) {
      print('Error sending FCM token to backend: $e');
    }
  }

  Future<void> deleteToken() async {
    await _messaging.deleteToken();
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('fcm_token');
    _fcmToken = null;
  }
}
