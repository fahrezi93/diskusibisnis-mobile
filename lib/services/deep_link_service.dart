import 'package:flutter/material.dart';
import 'package:app_links/app_links.dart';
import 'dart:async';

/// Service to handle deep links from diskusibisnis.my.id
class DeepLinkService {
  static final DeepLinkService _instance = DeepLinkService._internal();
  factory DeepLinkService() => _instance;
  DeepLinkService._internal();

  late AppLinks _appLinks;
  StreamSubscription<Uri>? _linkSubscription;

  final StreamController<Uri> _deepLinkController =
      StreamController<Uri>.broadcast();
  Stream<Uri> get deepLinkStream => _deepLinkController.stream;

  Uri? _initialLink;
  Uri? get initialLink => _initialLink;

  Future<void> initialize() async {
    _appLinks = AppLinks();

    // Get initial link if app was opened with a deep link
    try {
      _initialLink = await _appLinks.getInitialLink();
      if (_initialLink != null) {
        debugPrint('Initial deep link: $_initialLink');
        _deepLinkController.add(_initialLink!);
      }
    } catch (e) {
      debugPrint('Error getting initial deep link: $e');
    }

    // Listen for deep links while app is running
    _linkSubscription = _appLinks.uriLinkStream.listen((uri) {
      debugPrint('Received deep link: $uri');
      _deepLinkController.add(uri);
    }, onError: (e) {
      debugPrint('Deep link stream error: $e');
    });
  }

  /// Parse deep link and extract route information
  /// Returns a map with 'route' and 'params' keys
  Map<String, dynamic>? parseDeepLink(Uri uri) {
    try {
      // Handle diskusibisnis.my.id links
      if (uri.host == 'diskusibisnis.my.id' ||
          uri.host == 'www.diskusibisnis.my.id') {
        final pathSegments = uri.pathSegments;

        if (pathSegments.isEmpty) {
          return {'route': 'home', 'params': {}};
        }

        // /questions/:id
        if (pathSegments.first == 'questions' && pathSegments.length > 1) {
          return {
            'route': 'question',
            'params': {'questionId': pathSegments[1]}
          };
        }

        // /communities/:slug
        if (pathSegments.first == 'communities' && pathSegments.length > 1) {
          return {
            'route': 'community',
            'params': {'slug': pathSegments[1]}
          };
        }

        // /u/:username or /profile/:id
        if ((pathSegments.first == 'u' || pathSegments.first == 'profile') &&
            pathSegments.length > 1) {
          return {
            'route': 'profile',
            'params': {'userId': pathSegments[1]}
          };
        }

        // /notifications
        if (pathSegments.first == 'notifications') {
          return {'route': 'notifications', 'params': {}};
        }

        // /ask
        if (pathSegments.first == 'ask') {
          return {'route': 'ask', 'params': {}};
        }
      }

      // Handle custom scheme diskusibisnis://
      if (uri.scheme == 'diskusibisnis') {
        return {'route': uri.host, 'params': uri.queryParameters};
      }

      return null;
    } catch (e) {
      debugPrint('Error parsing deep link: $e');
      return null;
    }
  }

  void dispose() {
    _linkSubscription?.cancel();
    _deepLinkController.close();
  }
}
