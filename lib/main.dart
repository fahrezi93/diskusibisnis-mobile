import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:firebase_core/firebase_core.dart';
import 'firebase_options.dart';
import 'services/fcm_service.dart';
import 'services/supabase_service.dart';
import 'services/theme_service.dart';
import 'services/deep_link_service.dart';
import 'services/socket_service.dart';
import 'screens/welcome_screen.dart';
import 'screens/main_nav_screen.dart';
import 'screens/question_detail_screen.dart';
import 'screens/profile_screen.dart';
import 'screens/community_detail_screen.dart';
import 'screens/notifications_screen.dart';
import 'screens/ask_question_screen.dart';
import 'screens/reset_password_screen.dart';
import 'utils/image_cache_config.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Only do essential, fast initialization before runApp
  try {
    // Initialize Firebase with timeout
    if (Firebase.apps.isEmpty) {
      await Firebase.initializeApp(
        options: DefaultFirebaseOptions.currentPlatform,
      ).timeout(
        const Duration(seconds: 5),
        onTimeout: () {
          debugPrint('Firebase initialization timed out');
          throw Exception('Firebase timeout');
        },
      );
    }
  } catch (e) {
    debugPrint('Firebase initialization failed: $e');
  }

  // Initialize Theme (local, should be fast)
  try {
    await ThemeService().init().timeout(
      const Duration(seconds: 2),
      onTimeout: () {
        debugPrint('Theme initialization timed out');
      },
    );
  } catch (e) {
    debugPrint('Theme initialization failed: $e');
  }

  // Start app immediately - defer heavy initialization
  runApp(const DiskusiBisnisApp());

  // Initialize Supabase in background after app starts (non-blocking)
  SupabaseService.initialize().catchError((e) {
    debugPrint('Supabase initialization failed: $e');
  });
}

class DiskusiBisnisApp extends StatefulWidget {
  const DiskusiBisnisApp({super.key});

  @override
  State<DiskusiBisnisApp> createState() => _DiskusiBisnisAppState();
}

class _DiskusiBisnisAppState extends State<DiskusiBisnisApp> {
  bool _isAuthenticated = false;
  bool _showSplash = true;
  final FCMService _fcmService = FCMService();
  final DeepLinkService _deepLinkService = DeepLinkService();
  final SocketService _socketService = SocketService();
  final GlobalKey<NavigatorState> _navigatorKey = GlobalKey<NavigatorState>();

  @override
  void initState() {
    super.initState();
    _initialize();
  }

  Future<void> _initialize() async {
    debugPrint('[Init] Starting initialization...');

    // Safety net: Force hide splash after 4 seconds regardless of errors
    // This ensures user is never stuck on splash screen
    Future.delayed(const Duration(seconds: 4), () {
      if (mounted && _showSplash) {
        debugPrint('[Init] Safety net triggered: Forcing splash hide');
        _hideSplash();
      }
    });

    try {
      // Run auth check and splash timer in parallel
      await Future.wait([
        // Minimum splash duration
        Future.delayed(const Duration(milliseconds: 1500)),
        // Auth check with short timeout
        _checkAuth().timeout(const Duration(seconds: 3), onTimeout: () {
          debugPrint('[Init] Auth check timed out, proceeding as guest');
          if (mounted) {
            setState(() {
              _isAuthenticated = false;
            });
          }
        }).catchError((e) {
          debugPrint('[Init] Auth check error: $e');
        }),
      ]);
    } catch (e) {
      debugPrint('[Init] Initialization error: $e');
    }

    if (mounted && _showSplash) {
      debugPrint('[Init] Initialization done, hiding splash...');
      _hideSplash();
    }
  }

  void _hideSplash() {
    if (!mounted) return;

    setState(() {
      _showSplash = false;
    });

    // Do remaining initialization in background AFTER splash is hidden
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _initializeBackgroundServices();
    });
  }

  void _initializeBackgroundServices() {
    debugPrint('[Init] Starting background services...');

    // Initialize FCM and Socket in background (fire-and-forget)
    if (_isAuthenticated) {
      _fcmService.initialize();
      _socketService.connect();
    }

    // Initialize Image Cache for faster image loading
    ImageCacheConfig.initialize();

    // Initialize Deep Linking in background
    _deepLinkService.initialize().then((_) {
      debugPrint('[Init] Deep link initialized');
      _deepLinkService.deepLinkStream.listen(_handleDeepLink);
      if (_deepLinkService.initialLink != null) {
        _handleDeepLink(_deepLinkService.initialLink!);
      }
    }).catchError((e) {
      debugPrint('[Init] Deep link error: $e');
    });
  }

  void _handleDeepLink(Uri uri) {
    final parsed = _deepLinkService.parseDeepLink(uri);
    if (parsed != null) {
      debugPrint(
          'Navigating to: ${parsed['route']} with params: ${parsed['params']}');

      // Navigate to appropriate screen based on deep link
      _navigateToDeepLink(parsed['route'], parsed['params']);
    }
  }

  void _navigateToDeepLink(String route, Map<String, dynamic> params) {
    // Wait for the app to be ready before navigating
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;

      final navigator = _navigatorKey.currentState;
      if (navigator == null) return;

      switch (route) {
        case 'question':
          final questionId = params['questionId'] as String?;
          if (questionId != null) {
            navigator.push(
              MaterialPageRoute(
                builder: (context) =>
                    QuestionDetailScreen(questionId: questionId),
              ),
            );
          }
          break;

        case 'community':
          final slug = params['slug'] as String?;
          if (slug != null) {
            navigator.push(
              MaterialPageRoute(
                builder: (context) => CommunityDetailScreen(slug: slug),
              ),
            );
          }
          break;

        case 'profile':
          final userId = params['userId'] as String?;
          if (userId != null) {
            navigator.push(
              MaterialPageRoute(
                builder: (context) =>
                    ProfileScreen(userId: userId, showBackButton: true),
              ),
            );
          }
          break;

        case 'notifications':
          navigator.push(
            MaterialPageRoute(
              builder: (context) => const NotificationsScreen(),
            ),
          );
          break;

        case 'ask':
          if (_isAuthenticated) {
            navigator.push(
              MaterialPageRoute(
                builder: (context) => const AskQuestionScreen(),
              ),
            );
          }
          break;

        case 'reset_password':
          final token = params['token'] as String?;
          if (token != null) {
            navigator.push(
              MaterialPageRoute(
                builder: (context) => ResetPasswordScreen(token: token),
              ),
            );
          }
          break;

        default:
          // Just go to home
          break;
      }
    });
  }

  Future<void> _checkAuth() async {
    try {
      const secureStorage = FlutterSecureStorage();

      // First, check secure storage (primary location after migration)
      String? token = await secureStorage.read(key: 'auth_token').timeout(
            const Duration(seconds: 2),
            onTimeout: () => null,
          );

      // If not in secure storage, check SharedPreferences (legacy/pre-migration)
      if (token == null) {
        final prefs = await SharedPreferences.getInstance().timeout(
          const Duration(seconds: 2),
          onTimeout: () {
            throw Exception('SharedPreferences timeout');
          },
        );
        token = prefs.getString('auth_token');

        // Migrate to secure storage if found in SharedPreferences
        if (token != null) {
          await secureStorage.write(key: 'auth_token', value: token);
          await prefs.remove('auth_token');
          debugPrint('[Auth] Migrated token to secure storage');
        }
      }

      if (mounted) {
        setState(() {
          _isAuthenticated = token != null;
        });
      }
    } catch (e) {
      debugPrint('Auth check failed: $e');
      if (mounted) {
        setState(() {
          _isAuthenticated = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    // Create Inter text theme with consistent inherit value
    final baseTextTheme = ThemeData.light().textTheme;
    final interTextTheme = GoogleFonts.interTextTheme(baseTextTheme);

    // Show splash screen while loading
    if (_showSplash) {
      return MaterialApp(
        debugShowCheckedModeBanner: false,
        theme: ThemeData(
          textTheme: interTextTheme,
        ),
        // Don't use navigatorKey here - it will conflict when switching to main app
        home: const _AnimatedSplashScreen(),
      );
    }

    return ValueListenableBuilder<ThemeMode>(
      valueListenable: ThemeService().themeMode,
      builder: (context, currentMode, child) {
        return MaterialApp(
          title: 'DiskusiBisnis',
          navigatorKey: _navigatorKey,
          debugShowCheckedModeBanner: false,
          showPerformanceOverlay: false,
          showSemanticsDebugger: false,
          checkerboardRasterCacheImages: false,
          checkerboardOffscreenLayers: false,
          themeMode: currentMode,
          theme: ThemeData(
            useMaterial3: true,
            primaryColor: const Color(0xFF059669),
            scaffoldBackgroundColor: const Color(0xFFF8FAFC),
            colorScheme: ColorScheme.fromSeed(
              seedColor: const Color(0xFF059669),
              primary: const Color(0xFF059669),
              surface: const Color(0xFFF8FAFC),
            ),
            textTheme: interTextTheme,
            primaryTextTheme: interTextTheme,
            appBarTheme: AppBarTheme(
              backgroundColor: Colors.white,
              elevation: 0,
              scrolledUnderElevation: 0,
              iconTheme: const IconThemeData(color: Color(0xFF0F172A)),
              titleTextStyle: GoogleFonts.inter(
                color: const Color(0xFF0F172A),
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            snackBarTheme: const SnackBarThemeData(
              behavior: SnackBarBehavior.floating,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.all(Radius.circular(12)),
              ),
              elevation: 4,
            ),
            fontFamily: GoogleFonts.inter().fontFamily,
          ),
          darkTheme: ThemeData(
            useMaterial3: true,
            brightness: Brightness.dark,
            primaryColor: const Color(0xFF059669),
            scaffoldBackgroundColor: const Color(0xFF0F172A),
            colorScheme: ColorScheme.fromSeed(
              seedColor: const Color(0xFF059669),
              primary: const Color(0xFF059669),
              surface: const Color(0xFF0F172A),
              brightness: Brightness.dark,
            ),
            textTheme: GoogleFonts.interTextTheme(ThemeData.dark().textTheme),
            primaryTextTheme:
                GoogleFonts.interTextTheme(ThemeData.dark().primaryTextTheme),
            appBarTheme: AppBarTheme(
              backgroundColor: const Color(0xFF1E293B),
              elevation: 0,
              scrolledUnderElevation: 0,
              iconTheme: const IconThemeData(color: Colors.white),
              titleTextStyle: GoogleFonts.inter(
                color: Colors.white,
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            snackBarTheme: const SnackBarThemeData(
              behavior: SnackBarBehavior.floating,
              backgroundColor: Color(0xFF334155),
              contentTextStyle: TextStyle(color: Colors.white),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.all(Radius.circular(12)),
              ),
              elevation: 4,
            ),
            fontFamily: GoogleFonts.inter().fontFamily,
          ),
          home:
              _isAuthenticated ? const MainNavScreen() : const WelcomeScreen(),
        );
      },
    );
  }
}

/// Animated splash screen with fade and scale animation
class _AnimatedSplashScreen extends StatefulWidget {
  const _AnimatedSplashScreen();

  @override
  State<_AnimatedSplashScreen> createState() => _AnimatedSplashScreenState();
}

class _AnimatedSplashScreenState extends State<_AnimatedSplashScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _fadeAnimation;
  late Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    );

    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeOut),
    );

    _scaleAnimation = Tween<double>(begin: 0.8, end: 1.0).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeOutBack),
    );

    _controller.forward();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: AnimatedBuilder(
        animation: _controller,
        builder: (context, child) {
          return Stack(
            children: [
              // Logo di tengah
              Center(
                child: FadeTransition(
                  opacity: _fadeAnimation,
                  child: ScaleTransition(
                    scale: _scaleAnimation,
                    child: Image.asset(
                      'assets/images/logo.png',
                      width: 180,
                      height: 180,
                    ),
                  ),
                ),
              ),
              // "from KreativLabs" di bawah
              Positioned(
                bottom: 60,
                left: 0,
                right: 0,
                child: FadeTransition(
                  opacity: _fadeAnimation,
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        'from',
                        style: TextStyle(
                          color: Colors.grey[500],
                          fontSize: 13,
                          fontWeight: FontWeight.w400,
                        ),
                      ),
                      const SizedBox(height: 4),
                      const Text(
                        'KreativLabs',
                        style: TextStyle(
                          color: Color(0xFF1E293B),
                          fontSize: 18,
                          fontWeight: FontWeight.w600,
                          letterSpacing: -0.5,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}
