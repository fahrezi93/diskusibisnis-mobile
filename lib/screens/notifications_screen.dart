import 'package:flutter/material.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:url_launcher/url_launcher.dart';
import 'dart:async'; // Import Timer/StreamSubscription

import '../services/api_service.dart';
import '../services/auth_service.dart';
import '../services/fcm_service.dart'; // Import FCMService
import '../services/socket_service.dart'; // Import SocketService
import '../models/notification.dart' as notif;
import 'question_detail_screen.dart';

class NotificationsScreen extends StatefulWidget {
  const NotificationsScreen({super.key});

  @override
  State<NotificationsScreen> createState() => _NotificationsScreenState();
}

class _NotificationsScreenState extends State<NotificationsScreen>
    with WidgetsBindingObserver {
  final ApiService _apiService = ApiService();
  final AuthService _authService = AuthService();
  final SocketService _socketService = SocketService();
  bool _isLoading = true;
  bool _isLoggedIn = false;
  List<notif.Notification> _notifications = [];
  StreamSubscription? _notificationSubscription;
  bool _hasInitialized = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _initAndLoad();

    // Listen for real-time notifications via FCM (background/push)
    _notificationSubscription =
        FCMService().onNotificationReceived.listen((message) {
      print("FCM notification received: refreshing list...");
      // Add a small delay to ensure backend has processed the data
      Future.delayed(const Duration(seconds: 1), () {
        if (mounted) _loadNotifications();
      });
    });

    // Listen for real-time notifications via WebSocket
    _socketService.addNotificationListener(_handleNewNotification);
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    super.didChangeAppLifecycleState(state);
    // Refresh notifications when app is resumed from background
    if (state == AppLifecycleState.resumed && _hasInitialized && _isLoggedIn) {
      print('[NotificationsScreen] App resumed, refreshing notifications...');
      _loadNotifications();
    }
  }

  void _handleNewNotification(Map<String, dynamic> data) {
    print("[NotificationsScreen] New notification via WebSocket: $data");
    if (mounted) {
      // Add notification to list if not exists
      final newNotification = notif.Notification.fromJson(data);
      setState(() {
        // Check if already exists
        if (!_notifications.any((n) => n.id == newNotification.id)) {
          _notifications.insert(0, newNotification);
        }
      });
    }
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _notificationSubscription?.cancel();
    _socketService.removeNotificationListener(_handleNewNotification);
    super.dispose();
  }

  Future<void> _initAndLoad() async {
    print('[NotificationsScreen] _initAndLoad started');

    try {
      await _authService.init();

      final isAuth = _authService.isAuthenticated;
      final token = _authService.token;

      print(
          '[NotificationsScreen] Auth status: isAuthenticated=$isAuth, token=${token != null ? "present (${token.length} chars)" : "NULL"}');

      if (mounted) {
        setState(() {
          _isLoggedIn = isAuth;
          _hasInitialized = true;
        });
      }

      if (isAuth && token != null) {
        await _loadNotifications();
      } else {
        print(
            '[NotificationsScreen] Not authenticated or token is null, skipping notification load');
        if (mounted) setState(() => _isLoading = false);
      }
    } catch (e) {
      print('[NotificationsScreen] Error in _initAndLoad: $e');
      if (mounted) {
        setState(() {
          _isLoading = false;
          _hasInitialized = true;
        });
      }
    }
  }

  Future<void> _loadNotifications() async {
    print('[NotificationsScreen] _loadNotifications started');

    // Check token before making request
    final token = _authService.token;
    if (token == null) {
      print(
          '[NotificationsScreen] ERROR: Token is null, cannot load notifications');
      if (mounted) setState(() => _isLoading = false);
      return;
    }

    print('[NotificationsScreen] Token present, making API request...');

    // Only show loading spinner on initial load, not background refresh
    if (_notifications.isEmpty) {
      setState(() => _isLoading = true);
    }

    try {
      final data = await _apiService.getNotifications(token: token);
      print('[NotificationsScreen] API returned ${data.length} notifications');

      if (mounted) {
        setState(() {
          _notifications = data;
          _isLoading = false;
        });
        print(
            '[NotificationsScreen] State updated with ${_notifications.length} notifications');
      }
    } catch (e) {
      print('[NotificationsScreen] Error loading notifications: $e');
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _markAllAsRead() async {
    final success =
        await _apiService.markAllNotificationsAsRead(token: _authService.token);
    if (success) {
      await _loadNotifications();
    }
  }

  Future<void> _deleteNotification(notif.Notification notification,
      {bool showSnackbar = true}) async {
    final success = await _apiService.deleteNotification(
      notification.id,
      token: _authService.token,
    );
    if (success && mounted) {
      setState(() {
        _notifications.removeWhere((n) => n.id == notification.id);
      });
      if (showSnackbar) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Notifikasi dihapus'),
            backgroundColor: Color(0xFF059669),
            duration: Duration(seconds: 2),
          ),
        );
      }
    }
  }

  void _showDeleteConfirmation(notif.Notification notification) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Hapus Notifikasi'),
        content:
            const Text('Apakah Anda yakin ingin menghapus notifikasi ini?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Batal'),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              _deleteNotification(notification);
            },
            child: const Text('Hapus', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: const Text('Notifikasi',
            style: TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 18,
                color: Color(0xFF0F172A))),
        backgroundColor: Colors.white,
        elevation: 0,
        centerTitle: false,
        actions: [
          if (_notifications.isNotEmpty && _notifications.any((n) => !n.isRead))
            TextButton(
              onPressed: _markAllAsRead,
              child: const Text('Tandai dibaca',
                  style: TextStyle(
                      color: Color(0xFF059669), fontWeight: FontWeight.w600)),
            ),
        ],
      ),
      body: _isLoading
          ? const Center(
              child: CircularProgressIndicator(color: Color(0xFF059669)))
          : !_isLoggedIn
              ? _buildLoginRequired()
              : _notifications.isEmpty
                  ? _buildEmptyState()
                  : RefreshIndicator(
                      onRefresh: _loadNotifications,
                      color: const Color(0xFF059669),
                      child: ListView.separated(
                        itemCount: _notifications.length,
                        separatorBuilder: (context, index) =>
                            const Divider(height: 1, color: Color(0xFFF1F5F9)),
                        itemBuilder: (context, index) {
                          final notification = _notifications[index];
                          return _buildNotificationItem(notification);
                        },
                      ),
                    ),
    );
  }

  Widget _buildNotificationItem(notif.Notification notification) {
    return Dismissible(
      key: Key(notification.id),
      direction: DismissDirection.endToStart,
      background: Container(
        color: Colors.red,
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.only(right: 20),
        child: const Icon(LucideIcons.trash2, color: Colors.white),
      ),
      confirmDismiss: (direction) async {
        return await showDialog(
          context: context,
          builder: (context) => AlertDialog(
            title: const Text('Hapus Notifikasi'),
            content:
                const Text('Apakah Anda yakin ingin menghapus notifikasi ini?'),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context, false),
                child: const Text('Batal'),
              ),
              TextButton(
                onPressed: () => Navigator.pop(context, true),
                child: const Text('Hapus', style: TextStyle(color: Colors.red)),
              ),
            ],
          ),
        );
      },
      onDismissed: (direction) {
        // Remove from list immediately (synchronously) to prevent "still part of tree" error
        setState(() {
          _notifications.removeWhere((n) => n.id == notification.id);
        });
        // Then call API in background
        _apiService.deleteNotification(notification.id,
            token: _authService.token);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Notifikasi dihapus'),
            backgroundColor: Color(0xFF059669),
            duration: Duration(seconds: 2),
          ),
        );
      },
      child: InkWell(
        onTap: () => _handleNotificationTap(notification),
        onLongPress: () => _showDeleteConfirmation(notification),
        child: Container(
          color: notification.isRead
              ? Colors.white
              : const Color(0xFFECFDF5).withValues(alpha: 0.4),
          padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 20),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildIcon(notification.type),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Expanded(
                          child: Text(
                            notification.title,
                            style: TextStyle(
                              fontWeight: FontWeight.w600,
                              fontSize: 14,
                              color: notification.isRead
                                  ? const Color(0xFF475569)
                                  : const Color(0xFF0F172A),
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        Row(
                          children: [
                            Text(
                              _formatTimeAgo(notification.createdAt),
                              style: const TextStyle(
                                  fontSize: 10, color: Color(0xFF94A3B8)),
                            ),
                            if (!notification.isRead)
                              Container(
                                margin: const EdgeInsets.only(left: 8),
                                width: 8,
                                height: 8,
                                decoration: const BoxDecoration(
                                  color: Color(0xFF059669),
                                  shape: BoxShape.circle,
                                ),
                              ),
                          ],
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    _buildRichMessage(
                      notification.message,
                      notification.isRead
                          ? const Color(0xFF64748B)
                          : const Color(0xFF334155),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildRichMessage(String message, Color color) {
    List<TextSpan> spans = [];
    final parts = message.split('**');

    for (int i = 0; i < parts.length; i++) {
      // If i is odd, it was inside ** so it is bold
      // If i is even, it is regular text
      if (i % 2 != 0) {
        spans.add(TextSpan(
            text: parts[i],
            style: TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 13,
                color: color,
                height: 1.4)));
      } else {
        if (parts[i].isNotEmpty) {
          spans.add(TextSpan(
              text: parts[i],
              style: TextStyle(fontSize: 13, color: color, height: 1.4)));
        }
      }
    }

    return RichText(
      text: TextSpan(children: spans),
      maxLines: 2,
      overflow: TextOverflow.ellipsis,
    );
  }

  Future<void> _handleNotificationTap(notif.Notification notification) async {
    // 1. Mark as read immediately in UI
    if (!notification.isRead) {
      setState(() {
        final index = _notifications.indexWhere((n) => n.id == notification.id);
        if (index != -1) {
          // Create a new list to trigger UI update with modified item
          List<notif.Notification> updatedList = List.from(_notifications);
          updatedList[index] = notif.Notification(
            id: notification.id,
            title: notification.title,
            message: notification.message,
            isRead: true, // Mark read
            type: notification.type,
            createdAt: notification.createdAt,
            link: notification.link,
          );
          _notifications = updatedList;
        }
      });
      // Call API efficiently silently
      _apiService.markNotificationAsRead(notification.id,
          token: _authService.token);
    }

    // 2. Navigate based on link
    if (notification.link != null && notification.link!.isNotEmpty) {
      final link = notification.link!;

      // Handle external URLs (http/https)
      if (link.startsWith('http://') || link.startsWith('https://')) {
        // Open in external browser
        try {
          final uri = Uri.parse(link);
          if (await canLaunchUrl(uri)) {
            await launchUrl(uri, mode: LaunchMode.externalApplication);
          } else {
            if (mounted) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text('Tidak dapat membuka: $link'),
                  backgroundColor: Colors.red,
                  duration: const Duration(seconds: 2),
                ),
              );
            }
          }
        } catch (e) {
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text('Error: $e'),
                backgroundColor: Colors.red,
                duration: const Duration(seconds: 2),
              ),
            );
          }
        }
        return;
      }

      // Parse internal path
      final uri = Uri.parse(link);
      final pathSegments = uri.pathSegments;

      if (pathSegments.isEmpty || link == '/') {
        // Home - just go back or do nothing
        return;
      }

      final firstSegment = pathSegments.isNotEmpty ? pathSegments[0] : '';

      switch (firstSegment) {
        case 'questions':
          if (pathSegments.length > 1) {
            final secondSegment = pathSegments[1];
            if (secondSegment == 'ask') {
              // Navigate to ask question screen
              // Navigator.push(context, MaterialPageRoute(builder: (_) => AskQuestionScreen()));
              if (mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Buat pertanyaan baru'),
                    backgroundColor: Color(0xFF059669),
                  ),
                );
              }
            } else {
              // Navigate to question detail
              final questionId = secondSegment;
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) =>
                      QuestionDetailScreen(questionId: questionId),
                ),
              );
            }
          } else {
            // Navigate to questions list (go to home with questions tab)
            Navigator.of(context).popUntil((route) => route.isFirst);
          }
          break;

        case 'communities':
          if (pathSegments.length > 1) {
            // Navigate to specific community
            // final communitySlug = pathSegments[1];
            // Navigator.push(context, MaterialPageRoute(builder: (_) => CommunityDetailScreen(slug: communitySlug)));
          }
          // For now, go back to home (communities are accessible from there)
          Navigator.of(context).popUntil((route) => route.isFirst);
          break;

        case 'leaderboard':
          // Navigate to leaderboard/users list
          Navigator.of(context).popUntil((route) => route.isFirst);
          // TODO: Navigate to leaderboard tab
          break;

        case 'settings':
          // Navigate to settings
          // Navigator.push(context, MaterialPageRoute(builder: (_) => SettingsScreen()));
          Navigator.of(context).popUntil((route) => route.isFirst);
          break;

        case 'about':
          // Handle about pages like /about/bantuan
          Navigator.of(context).popUntil((route) => route.isFirst);
          break;

        case 'notifications':
          // Already on notifications screen, do nothing
          break;

        default:
          // Unknown path, just go home
          Navigator.of(context).popUntil((route) => route.isFirst);
      }
    }
  }

  Widget _buildIcon(String type) {
    IconData icon;
    Color color;
    Color bg;

    switch (type) {
      case 'answer':
      case 'comment':
        icon = LucideIcons.messageSquare;
        color = const Color(0xFF059669); // Emerald 600
        bg = const Color(0xFFD1FAE5); // Emerald 100
        break;
      case 'vote':
        icon = LucideIcons.thumbsUp;
        color = const Color(0xFFEA580C); // Orange 600
        bg = const Color(0xFFFFEDD5); // Orange 100
        break;
      case 'warning':
        icon = LucideIcons.alertTriangle;
        color = const Color(0xFFDC2626); // Red 600
        bg = const Color(0xFFFEE2E2); // Red 100
        break;
      case 'update':
        icon = LucideIcons.checkCircle;
        color = const Color(0xFF16A34A); // Green 600
        bg = const Color(0xFFDCFCE7); // Green 100
        break;
      case 'promo':
        icon = LucideIcons.gift;
        color = const Color(0xFF9333EA); // Purple 600
        bg = const Color(0xFFF3E8FF); // Purple 100
        break;
      case 'system':
        icon = LucideIcons.info;
        color = const Color(0xFF2563EB); // Blue 600
        bg = const Color(0xFFDBEAFE); // Blue 100
        break;
      default:
        icon = LucideIcons.bell;
        color = const Color(0xFF475569); // Slate 600
        bg = const Color(0xFFF1F5F9); // Slate 100
    }

    return Container(
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: bg,
        shape: BoxShape.circle,
      ),
      child: Icon(icon, size: 20, color: color),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(24),
            decoration: const BoxDecoration(
              color: Color(0xFFF8FAFC),
              shape: BoxShape.circle,
            ),
            child: const Icon(LucideIcons.bellOff,
                size: 48, color: Color(0xFFCBD5E1)),
          ),
          const SizedBox(height: 16),
          const Text('Belum ada notifikasi',
              style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF0F172A))),
          const SizedBox(height: 4),
          const Text(
              'Kami akan memberi tahu Anda ketika\nada aktivitas penting.',
              textAlign: TextAlign.center,
              style: TextStyle(color: Color(0xFF64748B))),
        ],
      ),
    );
  }

  Widget _buildLoginRequired() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(24),
            decoration: const BoxDecoration(
              color: Color(0xFFF8FAFC),
              shape: BoxShape.circle,
            ),
            child: const Icon(LucideIcons.logIn,
                size: 48, color: Color(0xFFCBD5E1)),
          ),
          const SizedBox(height: 16),
          const Text('Login diperlukan',
              style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF0F172A))),
          const SizedBox(height: 4),
          const Text('Silakan login untuk melihat notifikasi Anda.',
              textAlign: TextAlign.center,
              style: TextStyle(color: Color(0xFF64748B))),
        ],
      ),
    );
  }

  String _formatTimeAgo(DateTime date) {
    final diff = DateTime.now().difference(date);
    if (diff.inMinutes < 60) {
      return '${diff.inMinutes}m lalu';
    } else if (diff.inHours < 24) {
      return '${diff.inHours}j lalu';
    } else {
      return '${diff.inDays}h lalu';
    }
  }
}
