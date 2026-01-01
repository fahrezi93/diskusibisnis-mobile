import 'package:flutter/material.dart';
import 'package:lucide_icons/lucide_icons.dart';
import '../services/announcement_service.dart';

/// Widget to display announcement banners
class AnnouncementBannerWidget extends StatefulWidget {
  final String showOn;

  const AnnouncementBannerWidget({
    super.key,
    this.showOn = 'all',
  });

  @override
  State<AnnouncementBannerWidget> createState() =>
      _AnnouncementBannerWidgetState();
}

class _AnnouncementBannerWidgetState extends State<AnnouncementBannerWidget> {
  final AnnouncementService _service = AnnouncementService();
  List<Announcement> _announcements = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _fetchAnnouncements();
  }

  Future<void> _fetchAnnouncements() async {
    final announcements =
        await _service.getActiveAnnouncements(showOn: widget.showOn);
    if (mounted) {
      setState(() {
        _announcements = announcements;
        _isLoading = false;
      });
    }
  }

  void _dismissAnnouncement(Announcement announcement) async {
    await _service.dismissAnnouncement(announcement.id);
    if (mounted) {
      setState(() {
        _announcements.removeWhere((a) => a.id == announcement.id);
      });
    }
  }

  Color _getBackgroundColor(String type) {
    switch (type) {
      case 'info':
        return const Color(0xFFEFF6FF); // Blue 50
      case 'warning':
        return const Color(0xFFFEF9C3); // Yellow 50
      case 'success':
        return const Color(0xFFF0FDF4); // Green 50
      case 'error':
        return const Color(0xFFFEF2F2); // Red 50
      case 'promo':
        return const Color(0xFFFAF5FF); // Purple 50
      default:
        return const Color(0xFFEFF6FF);
    }
  }

  Color _getBorderColor(String type) {
    switch (type) {
      case 'info':
        return const Color(0xFFBFDBFE); // Blue 200
      case 'warning':
        return const Color(0xFFFDE68A); // Yellow 200
      case 'success':
        return const Color(0xFFBBF7D0); // Green 200
      case 'error':
        return const Color(0xFFFECACA); // Red 200
      case 'promo':
        return const Color(0xFFE9D5FF); // Purple 200
      default:
        return const Color(0xFFBFDBFE);
    }
  }

  Color _getTextColor(String type) {
    switch (type) {
      case 'info':
        return const Color(0xFF1E40AF); // Blue 800
      case 'warning':
        return const Color(0xFF854D0E); // Yellow 800
      case 'success':
        return const Color(0xFF166534); // Green 800
      case 'error':
        return const Color(0xFF991B1B); // Red 800
      case 'promo':
        return const Color(0xFF6B21A8); // Purple 800
      default:
        return const Color(0xFF1E40AF);
    }
  }

  IconData _getIcon(String type) {
    switch (type) {
      case 'info':
        return LucideIcons.info;
      case 'warning':
        return LucideIcons.alertTriangle;
      case 'success':
        return LucideIcons.checkCircle;
      case 'error':
        return LucideIcons.alertCircle;
      case 'promo':
        return LucideIcons.gift;
      default:
        return LucideIcons.info;
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading || _announcements.isEmpty) {
      return const SizedBox.shrink();
    }

    return Column(
      children: _announcements.map((announcement) {
        return Container(
          margin: const EdgeInsets.only(bottom: 8),
          decoration: BoxDecoration(
            color: _getBackgroundColor(announcement.type),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: _getBorderColor(announcement.type),
              width: 1,
            ),
          ),
          child: Padding(
            padding: const EdgeInsets.all(12),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Icon
                Icon(
                  _getIcon(announcement.type),
                  color: _getTextColor(announcement.type),
                  size: 20,
                ),
                const SizedBox(width: 12),

                // Content
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        announcement.title,
                        style: TextStyle(
                          fontWeight: FontWeight.w600,
                          color: _getTextColor(announcement.type),
                          fontSize: 14,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        announcement.message,
                        style: TextStyle(
                          color:
                              _getTextColor(announcement.type).withOpacity(0.9),
                          fontSize: 13,
                        ),
                      ),
                      if (announcement.linkUrl != null &&
                          announcement.linkText != null) ...[
                        const SizedBox(height: 8),
                        GestureDetector(
                          onTap: () {
                            // TODO: Handle link navigation
                          },
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Text(
                                announcement.linkText!,
                                style: TextStyle(
                                  color: _getTextColor(announcement.type),
                                  fontSize: 13,
                                  fontWeight: FontWeight.w600,
                                  decoration: TextDecoration.underline,
                                ),
                              ),
                              const SizedBox(width: 4),
                              Icon(
                                LucideIcons.externalLink,
                                color: _getTextColor(announcement.type),
                                size: 14,
                              ),
                            ],
                          ),
                        ),
                      ],
                    ],
                  ),
                ),

                // Dismiss button
                if (announcement.isDismissible)
                  GestureDetector(
                    onTap: () => _dismissAnnouncement(announcement),
                    child: Container(
                      padding: const EdgeInsets.all(4),
                      child: Icon(
                        LucideIcons.x,
                        color: _getTextColor(announcement.type),
                        size: 18,
                      ),
                    ),
                  ),
              ],
            ),
          ),
        );
      }).toList(),
    );
  }
}
