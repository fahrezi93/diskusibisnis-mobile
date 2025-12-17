import 'package:flutter/material.dart';
import 'package:lottie/lottie.dart';
import 'package:smooth_page_indicator/smooth_page_indicator.dart';
import 'login_screen.dart';

class OnboardingItem {
  final String title;
  final String description;
  final String lottieUrl;

  OnboardingItem({
    required this.title,
    required this.description,
    required this.lottieUrl,
  });
}

class WelcomeScreen extends StatefulWidget {
  const WelcomeScreen({super.key});

  @override
  State<WelcomeScreen> createState() => _WelcomeScreenState();
}

class _WelcomeScreenState extends State<WelcomeScreen> {
  final PageController _pageController = PageController();
  int _currentIndex = 0;

  // Data Onboarding
  final List<OnboardingItem> _items = [
    OnboardingItem(
      title: 'Solusi Bisnis Terpercaya',
      description:
          'Temukan tim dan komunitas yang siap membantumu memecahkan masalah bisnis bersama-sama.',
      // Business Team Animation
      lottieUrl: 'assets/lottie/business_team.json',
    ),
    OnboardingItem(
      title: 'Diskusi & Tanya Jawab',
      description:
          'Forum diskusi interaktif untuk bertanya dan menjawab segala hal tentang dunia usaha.',
      // Q&A Animation
      lottieUrl: 'assets/lottie/qna.json',
    ),
    OnboardingItem(
      title: 'Bangun Kerajaan Bisnismu',
      description:
          'Dapatkan strategi terbaik untuk membangun dan mengembangkan bisnismu mulai dari nol.',
      // Building/Growth Animation
      lottieUrl: 'assets/lottie/building_page.json',
    ),
  ];

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  void _nextPage() {
    if (_currentIndex < _items.length - 1) {
      _pageController.nextPage(
        duration: const Duration(milliseconds: 500),
        curve: Curves.easeInOut,
      );
    } else {
      _navigateToLogin();
    }
  }

  void _navigateToLogin() {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => const LoginScreen()),
    );
  }

  @override
  Widget build(BuildContext context) {
    const primaryColor = Color(0xFF059669); // Emerald 600
    const backgroundColor = Color(0xFFECFDF5); // Emerald 50

    return Scaffold(
      backgroundColor: backgroundColor,
      body: Column(
        children: [
          // 1. Top Section - Lottie Area (Flex 6)
          Expanded(
            flex: 6,
            child: SafeArea(
              child: PageView.builder(
                controller: _pageController,
                itemCount: _items.length,
                onPageChanged: (index) {
                  setState(() => _currentIndex = index);
                },
                itemBuilder: (context, index) {
                  return Padding(
                    padding: const EdgeInsets.all(32.0),
                    child: Center(
                      child: Lottie.asset(
                        _items[index].lottieUrl,
                        fit: BoxFit.contain,
                        errorBuilder: (context, error, stackTrace) {
                          // Fallback icon if asset fails
                          return Icon(
                            Icons.rocket_launch_rounded,
                            size: 100,
                            color: primaryColor.withOpacity(0.2),
                          );
                        },
                      ),
                    ),
                  );
                },
              ),
            ),
          ),

          // 2. Bottom Section - White Card (Flex 4)
          Expanded(
            flex: 4,
            child: Container(
              width: double.infinity,
              decoration: const BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.only(
                  topLeft: Radius.circular(32),
                  topRight: Radius.circular(32),
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black12,
                    blurRadius: 20,
                    offset: Offset(0, -5),
                  ),
                ],
              ),
              child: Padding(
                padding: const EdgeInsets.fromLTRB(24, 40, 24, 24),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Text Content with Animation
                    Expanded(
                      child: AnimatedSwitcher(
                        duration: const Duration(milliseconds: 300),
                        transitionBuilder:
                            (Widget child, Animation<double> animation) {
                          return FadeTransition(
                              opacity: animation, child: child);
                        },
                        child: Column(
                          key: ValueKey<int>(_currentIndex),
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              _items[_currentIndex].title,
                              style: const TextStyle(
                                fontSize: 28,
                                fontWeight: FontWeight.bold,
                                color: Color(0xFF0F172A), // Slate 900
                                height: 1.2,
                              ),
                            ),
                            const SizedBox(height: 16),
                            Text(
                              _items[_currentIndex].description,
                              style: const TextStyle(
                                fontSize: 16,
                                color: Color(0xFF64748B), // Slate 500
                                height: 1.5,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),

                    // Indicators & Button Row
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        // Page Indicator
                        SmoothPageIndicator(
                          controller: _pageController,
                          count: _items.length,
                          effect: const ExpandingDotsEffect(
                            dotHeight: 8,
                            dotWidth: 8,
                            activeDotColor: primaryColor,
                            dotColor: Color(0xFFE2E8F0),
                            expansionFactor: 4,
                          ),
                        ),

                        // Action Button
                        ElevatedButton(
                          onPressed: _nextPage,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: primaryColor,
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(
                                horizontal: 32, vertical: 16),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(16),
                            ),
                            elevation: 0,
                          ),
                          child: Row(
                            children: [
                              Text(
                                _currentIndex == _items.length - 1
                                    ? 'Mulai'
                                    : 'Lanjut',
                                style: const TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              if (_currentIndex != _items.length - 1) ...[
                                const SizedBox(width: 8),
                                const Icon(Icons.arrow_forward_rounded,
                                    size: 20),
                              ]
                            ],
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
