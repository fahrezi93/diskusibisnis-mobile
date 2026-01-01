import 'package:flutter/material.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'home_screen.dart';
// Placeholder setup for other screens
import 'explore_screen.dart';
import 'notifications_screen.dart';
import 'profile_screen.dart';
import 'ask_question_screen.dart';
import 'question_detail_screen.dart';

import 'dart:async';
import '../services/api_service.dart';
import '../services/auth_service.dart';
import '../services/update_service.dart';
import '../services/fcm_service.dart';
import '../services/popup_service.dart';
import '../widgets/promo_popup.dart';

class MainNavScreen extends StatefulWidget {
  const MainNavScreen({super.key});

  @override
  State<MainNavScreen> createState() => _MainNavScreenState();
}

class _MainNavScreenState extends State<MainNavScreen> {
  int _currentIndex = 0;
  int _unreadNotifications = 0;
  Timer? _notificationTimer;
  final ApiService _api = ApiService();
  final AuthService _auth = AuthService();
  final UpdateService _updateService = UpdateService();
  final FCMService _fcmService = FCMService();
  final PopupService _popupService = PopupService();
  StreamSubscription? _fcmSubscription;

  final List<Widget> _screens = [
    const HomeScreen(),
    const ExploreScreen(),
    const SizedBox(), // Placeholder for Ask Button
    const NotificationsScreen(),
    const ProfileScreen(),
  ];

  @override
  void initState() {
    super.initState();
    _checkNotifications();
    _checkForUpdates();
    _setupFCMListener();
    _checkForPromoPopup(); // Check for promotional popup

    // Check every 30 seconds
    _notificationTimer = Timer.periodic(const Duration(seconds: 30), (_) {
      _checkNotifications();
    });
  }

  @override
  void dispose() {
    _notificationTimer?.cancel();
    _fcmSubscription?.cancel();
    super.dispose();
  }

  /// Setup FCM notification click listener
  void _setupFCMListener() {
    _fcmSubscription = _fcmService.onNotificationReceived.listen((message) {
      // Handle notification click - navigate to the relevant screen
      final data = message.data;
      final link = data['link'];

      if (link != null && link.contains('/questions/')) {
        // Extract question ID from link like "/questions/uuid-here"
        final parts = link.split('/');
        if (parts.length > 2) {
          final questionId = parts[2];
          _navigateToQuestion(questionId);
        }
      } else if (link == '/notifications') {
        // Go to notifications tab
        setState(() => _currentIndex = 3);
      }
    });
  }

  /// Navigate to question detail
  void _navigateToQuestion(String questionId) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => QuestionDetailScreen(questionId: questionId),
      ),
    );
  }

  /// Check for app updates
  Future<void> _checkForUpdates() async {
    await Future.delayed(const Duration(seconds: 2)); // Wait for app to settle
    final updateInfo = await _updateService.checkForUpdate();
    if (updateInfo != null && mounted) {
      _updateService.showUpdateDialog(context, updateInfo);
    }
  }

  Future<void> _checkNotifications() async {
    await _auth.init();
    if (_auth.isAuthenticated && _auth.token != null) {
      final count = await _api.getUnreadNotificationCount(_auth.token!);
      if (mounted && count != _unreadNotifications) {
        setState(() {
          _unreadNotifications = count;
        });
      }
    }
  }

  /// Check for promotional popup
  Future<void> _checkForPromoPopup() async {
    // Wait for app to settle and other dialogs to clear
    await Future.delayed(const Duration(seconds: 3));
    if (!mounted) return;

    final popup = await _popupService.getActivePopup();
    if (popup != null && mounted) {
      _showPromoPopup(popup);
    }
  }

  /// Show promotional popup dialog
  void _showPromoPopup(PromoPopup popup) {
    showDialog(
      context: context,
      barrierDismissible: true,
      builder: (context) => PromoPopupDialog(
        popup: popup,
        onDismiss: () {
          Navigator.of(context).pop();
          _popupService.recordPopupView(popup.id, clicked: false);
        },
        onTap: () {
          Navigator.of(context).pop();
          _popupService.recordPopupView(popup.id, clicked: true);
          _handlePromoPopupTap(popup);
        },
      ),
    );
  }

  /// Handle popup tap - navigate based on link type
  void _handlePromoPopupTap(PromoPopup popup) {
    if (popup.linkUrl == null) return;

    switch (popup.linkType) {
      case 'question':
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) =>
                QuestionDetailScreen(questionId: popup.linkUrl!),
          ),
        );
        break;
      case 'community':
        // Navigate to community by slug
        // TODO: Implement community navigation
        break;
      case 'external':
      case 'url':
      default:
        // Open URL in browser
        // TODO: Implement URL launcher
        break;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: IndexedStack(
        index: _currentIndex,
        children: _screens,
      ),
      // Custom FAB for the Center Button
      floatingActionButton: Container(
        margin: const EdgeInsets.only(top: 30),
        height: 64,
        width: 64,
        child: FloatingActionButton(
          onPressed: () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => const AskQuestionScreen(),
              ),
            );
          },
          backgroundColor: const Color(0xFF059669),
          elevation: 4,
          shape: const CircleBorder(),
          child: const Icon(LucideIcons.plus, color: Colors.white, size: 28),
        ),
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerDocked,
      bottomNavigationBar: Container(
        decoration: const BoxDecoration(
          border:
              Border(top: BorderSide(color: Color(0xFFE2E8F0))), // Slate 200
        ),
        child: BottomAppBar(
          padding: const EdgeInsets.symmetric(horizontal: 8),
          height: 65,
          color: Colors.white,
          elevation: 0,
          notchMargin: 8,
          shape: const CircularNotchedRectangle(),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _buildNavItem(0, LucideIcons.home, 'Beranda'),
              _buildNavItem(1, LucideIcons.compass, 'Jelajah'),
              const SizedBox(width: 48), // Space for FAB
              _buildNavItem(3, LucideIcons.bell, 'Notifikasi',
                  badgeCount: _unreadNotifications),
              _buildNavItem(4, LucideIcons.user, 'Profil'),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildNavItem(int index, IconData icon, String label,
      {int badgeCount = 0}) {
    final isSelected = _currentIndex == index;
    final color = isSelected
        ? const Color(0xFF059669)
        : const Color(0xFF64748B); // Slate 500

    return InkWell(
      onTap: () {
        setState(() {
          _currentIndex = index;
          // If tapping notifications, maybe clear badge locally or let screen do it?
          // Since NotificationsScreen marks read, next poll will clear it.
          // But for better UX, we might want to clear it immediately if we knew they'd read it.
          // For now, rely on polling or the screen update.
        });
        if (index == 3) {
          _checkNotifications(); // Immediate check on tap
        }
      },
      borderRadius: BorderRadius.circular(12),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Stack(
              clipBehavior: Clip.none,
              children: [
                Icon(icon, color: color, size: 24),
                if (badgeCount > 0)
                  Positioned(
                    top: -2,
                    right: -4,
                    child: Container(
                      padding: const EdgeInsets.all(4),
                      decoration: const BoxDecoration(
                        color: Colors.red,
                        shape: BoxShape.circle,
                      ),
                      constraints: const BoxConstraints(
                        minWidth: 16,
                        minHeight: 16,
                      ),
                      child: Text(
                        badgeCount > 99 ? '99+' : badgeCount.toString(),
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 10,
                          fontWeight: FontWeight.bold,
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 4),
            Text(
              label,
              style: TextStyle(
                color: color,
                fontSize: 10,
                fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
