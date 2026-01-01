import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../services/popup_service.dart';

/// Widget to display promotional popup dialog
class PromoPopupDialog extends StatelessWidget {
  final PromoPopup popup;
  final VoidCallback onDismiss;
  final VoidCallback? onTap;

  const PromoPopupDialog({
    super.key,
    required this.popup,
    required this.onDismiss,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: Colors.transparent,
      insetPadding: const EdgeInsets.symmetric(horizontal: 24, vertical: 24),
      child: Stack(
        clipBehavior: Clip.none,
        alignment: Alignment.topRight,
        children: [
          // Main popup content
          GestureDetector(
            onTap: onTap,
            child: Container(
              constraints: BoxConstraints(
                maxWidth: MediaQuery.of(context).size.width * 0.85,
                maxHeight: MediaQuery.of(context).size.height * 0.7,
              ),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(16),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.3),
                    blurRadius: 20,
                    offset: const Offset(0, 10),
                  ),
                ],
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(16),
                child: CachedNetworkImage(
                  imageUrl: popup.imageUrl,
                  fit: BoxFit.contain,
                  placeholder: (context, url) => Container(
                    color: Colors.grey[200],
                    child: const Center(
                      child: CircularProgressIndicator(
                        color: Color(0xFF059669),
                      ),
                    ),
                  ),
                  errorWidget: (context, url, error) => Container(
                    padding: const EdgeInsets.all(32),
                    color: Colors.grey[200],
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          Icons.image_not_supported,
                          size: 64,
                          color: Colors.grey[400],
                        ),
                        const SizedBox(height: 16),
                        Text(
                          popup.title,
                          style: const TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                          textAlign: TextAlign.center,
                        ),
                        if (popup.description != null) ...[
                          const SizedBox(height: 8),
                          Text(
                            popup.description!,
                            style: TextStyle(
                              fontSize: 14,
                              color: Colors.grey[600],
                            ),
                            textAlign: TextAlign.center,
                          ),
                        ],
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),

          // Close button
          Positioned(
            top: -12,
            right: -12,
            child: GestureDetector(
              onTap: onDismiss,
              child: Container(
                width: 36,
                height: 36,
                decoration: BoxDecoration(
                  color: Colors.white,
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.2),
                      blurRadius: 8,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: const Icon(
                  Icons.close,
                  size: 20,
                  color: Color(0xFF64748B),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// Mixin to add popup functionality to any StatefulWidget
mixin PromoPopupMixin<T extends StatefulWidget> on State<T> {
  final PopupService _popupService = PopupService();
  bool _popupShown = false;

  /// Call this in initState after super.initState()
  void checkAndShowPopup({Duration delay = const Duration(seconds: 1)}) {
    if (_popupShown) return;

    Future.delayed(delay, () async {
      if (!mounted) return;

      final popup = await _popupService.getActivePopup();
      if (popup != null && mounted) {
        _popupShown = true;
        _showPopupDialog(popup);
      }
    });
  }

  void _showPopupDialog(PromoPopup popup) {
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
          _handlePopupTap(popup);
        },
      ),
    );
  }

  /// Handle popup tap - navigate based on link type
  void _handlePopupTap(PromoPopup popup) {
    if (popup.linkUrl == null) return;

    switch (popup.linkType) {
      case 'question':
        // Navigate to question detail
        // Navigator.push(context, MaterialPageRoute(builder: (context) => QuestionDetailScreen(questionId: popup.linkUrl!)));
        break;
      case 'community':
        // Navigate to community
        // Navigator.push(context, MaterialPageRoute(builder: (context) => CommunityDetailScreen(slug: popup.linkUrl!)));
        break;
      case 'external':
      case 'url':
      default:
        // Open URL in browser or in-app browser
        // TODO: implement URL launcher
        break;
    }
  }
}
