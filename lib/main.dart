import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:shared_preferences/shared_preferences.dart';
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

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  try {
    // Initialize Firebase if not already initialized
    if (Firebase.apps.isEmpty) {
      await Firebase.initializeApp(
        options: DefaultFirebaseOptions.currentPlatform,
      );
    }
  } catch (e) {
    debugPrint('Firebase initialization failed: $e');
  }

  // Initialize Supabase for avatar uploads
  try {
    await SupabaseService.initialize();
  } catch (e) {
    debugPrint('Supabase initialization failed: $e');
  }

  // Initialize Theme
  try {
    await ThemeService().init();
  } catch (e) {
    debugPrint('Theme initialization failed: $e');
  }

  runApp(const DiskusiBisnisApp());
}

class DiskusiBisnisApp extends StatefulWidget {
  const DiskusiBisnisApp({super.key});

  @override
  State<DiskusiBisnisApp> createState() => _DiskusiBisnisAppState();
}

class _DiskusiBisnisAppState extends State<DiskusiBisnisApp> {
  bool _isAuthenticated = false;
  bool _showSplash = true; // Flag untuk splash
  final FCMService _fcmService = FCMService();
  final DeepLinkService _deepLinkService = DeepLinkService();
  final SocketService _socketService = SocketService();

  @override
  void initState() {
    super.initState();
    _initialize();
  }

  Future<void> _initialize() async {
    // Minimum splash duration 1.2 detik
    final splashFuture = Future.delayed(const Duration(milliseconds: 1200));
    
    try {
      await _checkAuth();

      // Initialize FCM if user is authenticated
      if (_isAuthenticated) {
        await _fcmService.initialize();
        // Connect to WebSocket for real-time notifications
        await _socketService.connect();
      }

      // Initialize Deep Linking
      await _deepLinkService.initialize();

      // Listen for deep links while app is running
      _deepLinkService.deepLinkStream.listen(_handleDeepLink);
      
      // Wait for minimum splash duration
      await splashFuture;
      
      // Handle initial deep link (app opened from link)
      if (_deepLinkService.initialLink != null) {
        _handleDeepLink(_deepLinkService.initialLink!);
      }
    } catch (e) {
      debugPrint('Initialization failed: $e');
      // Still wait for splash even on error
      await splashFuture;
    }
    
    // Hide splash after everything is done
    if (mounted) {
      setState(() {
        _showSplash = false;
      });
    }
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
      
      final navigator = Navigator.of(context);
      
      switch (route) {
        case 'question':
          final questionId = params['questionId'] as String?;
          if (questionId != null) {
            navigator.push(
              MaterialPageRoute(
                builder: (context) => QuestionDetailScreen(questionId: questionId),
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
                builder: (context) => ProfileScreen(userId: userId, showBackButton: true),
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
          
        default:
          // Just go to home
          break;
      }
    });
  }

  Future<void> _checkAuth() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('auth_token');
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
        home: const _AnimatedSplashScreen(),
      );
    }

    return ValueListenableBuilder<ThemeMode>(
      valueListenable: ThemeService().themeMode,
      builder: (context, currentMode, child) {
        return MaterialApp(
          title: 'DiskusiBisnis',
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
