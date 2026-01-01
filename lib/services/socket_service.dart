import 'package:socket_io_client/socket_io_client.dart' as io;
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import '../config/app_config.dart';

class SocketService {
  static final SocketService _instance = SocketService._internal();
  factory SocketService() => _instance;
  SocketService._internal();

  io.Socket? _socket;
  bool _isConnected = false;
  final List<Function(Map<String, dynamic>)> _notificationListeners = [];

  bool get isConnected => _isConnected;

  Future<void> connect() async {
    if (_socket != null && _isConnected) {
      print('[Socket] Already connected');
      return;
    }

    // Get token from FlutterSecureStorage
    const secureStorage = FlutterSecureStorage();
    final token = await secureStorage.read(key: 'auth_token');

    // Get WebSocket URL from base URL (not API URL)
    String wsUrl = AppConfig.baseUrl;

    print('[Socket] Connecting to: $wsUrl');

    _socket = io.io(wsUrl, <String, dynamic>{
      'transports': ['websocket', 'polling'],
      'autoConnect': false,
      'auth': {'token': token ?? ''},
      'reconnection': true,
      'reconnectionAttempts': 5,
      'reconnectionDelay': 1000,
    });

    _socket!.onConnect((_) {
      print('[Socket] Connected: ${_socket!.id}');
      _isConnected = true;
    });

    _socket!.onDisconnect((reason) {
      print('[Socket] Disconnected: $reason');
      _isConnected = false;
    });

    _socket!.onConnectError((error) {
      print('[Socket] Connection error: $error');
      _isConnected = false;
    });

    _socket!.onError((error) {
      print('[Socket] Error: $error');
    });

    // Listen for new notifications
    _socket!.on('notification:new', (data) {
      print('[Socket] New notification received: $data');
      if (data is Map<String, dynamic>) {
        for (var listener in _notificationListeners) {
          listener(data);
        }
      }
    });

    // Listen for deleted notifications
    _socket!.on('notification:deleted', (data) {
      print('[Socket] Notification deleted: $data');
      // Handle deletion if needed
    });

    _socket!.connect();
  }

  void disconnect() {
    if (_socket != null) {
      print('[Socket] Disconnecting...');
      _socket!.disconnect();
      _socket!.dispose();
      _socket = null;
      _isConnected = false;
    }
  }

  void addNotificationListener(Function(Map<String, dynamic>) listener) {
    _notificationListeners.add(listener);
  }

  void removeNotificationListener(Function(Map<String, dynamic>) listener) {
    _notificationListeners.remove(listener);
  }

  void joinCommunity(String communitySlug) {
    if (_socket != null && _isConnected) {
      _socket!.emit('join:community', {'communitySlug': communitySlug});
      print('[Socket] Joined community: $communitySlug');
    }
  }

  void leaveCommunity(String communitySlug) {
    if (_socket != null && _isConnected) {
      _socket!.emit('leave:community', {'communitySlug': communitySlug});
      print('[Socket] Left community: $communitySlug');
    }
  }

  void joinQuestion(String questionId) {
    if (_socket != null && _isConnected) {
      _socket!.emit('join:question', {'questionId': questionId});
      print('[Socket] Joined question: $questionId');
    }
  }

  void leaveQuestion(String questionId) {
    if (_socket != null && _isConnected) {
      _socket!.emit('leave:question', {'questionId': questionId});
      print('[Socket] Left question: $questionId');
    }
  }

  // Reconnect with new token (after login)
  Future<void> reconnect() async {
    disconnect();
    await Future.delayed(const Duration(milliseconds: 500));
    await connect();
  }
}
