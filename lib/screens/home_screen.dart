import 'package:flutter/material.dart';
import 'package:lucide_icons/lucide_icons.dart';
import '../widgets/hero_section.dart';
import '../widgets/announcement_banner.dart';
import '../widgets/skeleton_loading.dart';
import '../services/api_service.dart';
import '../models/question.dart';
import '../widgets/question_card.dart';
import 'search_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final ApiService _api = ApiService();
  List<Question> _questions = [];
  bool _isLoading = true;
  bool _isRefreshing = false; // For background refresh indicator
  String _error = '';
  String _activeFilter = 'newest';

  // Cache for each filter type to provide instant switching
  final Map<String, List<Question>> _filterCache = {};

  @override
  void initState() {
    super.initState();
    _loadQuestionsWithCache();
    _prefetchExploreData(); // Pre-load data for explore pages
  }

  /// Load questions with cache-first approach for instant display
  Future<void> _loadQuestionsWithCache() async {
    // API service getQuestions now returns cached data instantly if available
    // and triggers background refresh automatically
    _loadQuestions();
  }

  /// Pre-fetch data for explore pages so they load instantly when opened
  void _prefetchExploreData() {
    // Fire and forget - these will populate the cache
    _api.getCommunities();
    _api.getTags();
    _api.getUsers();
  }

  Future<void> _loadQuestions({bool showFullLoader = true}) async {
    // Check cache first for instant display
    if (_filterCache.containsKey(_activeFilter) && showFullLoader) {
      setState(() {
        _questions = _filterCache[_activeFilter]!;
        _isLoading = false;
        _isRefreshing = true; // Show subtle refresh indicator
      });
    } else if (showFullLoader) {
      setState(() {
        _isLoading = true;
        _error = '';
      });
    } else {
      setState(() => _isRefreshing = true);
    }

    try {
      final data = await _api.getQuestions(sort: _activeFilter);
      // Update cache
      _filterCache[_activeFilter] = data;

      if (mounted) {
        setState(() {
          _questions = data;
          _isLoading = false;
          _isRefreshing = false;
        });
      }
    } catch (e) {
      String errorMessage = 'Gagal memuat data.';
      final String errorString = e.toString().toLowerCase();

      // Check for common connectivity errors
      if (errorString.contains('xmlhttprequest') ||
          errorString.contains('socketexception') ||
          errorString.contains('connection refused') ||
          errorString.contains('connection timed out') ||
          errorString.contains('network is unreachable')) {
        errorMessage = 'Tidak ada koneksi internet.';
      } else {
        // Validation for when backend is likely down or unreachable but not strictly a network error
        errorMessage = 'Gagal memuat data.\nPastikan server berjalan.';
      }

      if (mounted) {
        setState(() {
          // Keep showing cached data if available
          if (_filterCache.containsKey(_activeFilter)) {
            _questions = _filterCache[_activeFilter]!;
          }
          _error = _questions.isEmpty ? errorMessage : '';
          _isLoading = false;
          _isRefreshing = false;
        });
      }
    }
  }

  void _setFilter(String filter) {
    if (_activeFilter != filter) {
      setState(() => _activeFilter = filter);
      // Use cached data if available for instant switch
      if (_filterCache.containsKey(filter)) {
        setState(() {
          _questions = _filterCache[filter]!;
        });
        // Background refresh to get latest data
        _loadQuestions(showFullLoader: false);
      } else {
        _loadQuestions();
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      body: SafeArea(
        child: NestedScrollView(
          headerSliverBuilder: (context, innerBoxIsScrolled) {
            return [
              // App Bar
              SliverAppBar(
                floating: true,
                snap: true,
                backgroundColor: Colors.white,
                elevation: 0,
                title: const Text(
                  'DiskusiBisnis',
                  style: TextStyle(
                    color: Color(0xFF059669),
                    fontWeight: FontWeight.w800,
                    fontSize: 22,
                  ),
                ),
                centerTitle: false,
                actions: [
                  IconButton(
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => const SearchScreen(),
                        ),
                      );
                    },
                    icon: const Icon(LucideIcons.search,
                        color: Color(0xFF64748B)),
                  ),
                ],
              ),

              // Hero Section
              SliverToBoxAdapter(
                child: HeroSection(totalQuestions: _questions.length),
              ),

              // Announcement Banner
              SliverToBoxAdapter(
                child: Padding(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  child: AnnouncementBannerWidget(showOn: 'home'),
                ),
              ),

              // Sticky Filter Tabs
              SliverPersistentHeader(
                pinned: true,
                delegate: _StickyFilterHeaderDelegate(
                  minHeight: 56,
                  maxHeight: 56,
                  child: Container(
                    color: const Color(0xFFF8FAFC),
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 16, vertical: 8),
                      child: Row(
                        children: [
                          Expanded(
                            child: _buildFilterChip(
                                'Terbaru', 'newest', LucideIcons.clock),
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: _buildFilterChip(
                                'Populer', 'popular', LucideIcons.trendingUp),
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: _buildFilterChip('Belum Jawab', 'unanswered',
                                LucideIcons.helpCircle),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ];
          },
          body: RefreshIndicator(
            onRefresh: _loadQuestions,
            color: const Color(0xFF059669),
            child: _buildContent(),
          ),
        ),
      ),
    );
  }

  Widget _buildContent() {
    if (_isLoading && _questions.isEmpty) {
      // Show skeleton loading instead of spinner
      return ListView.builder(
        padding: const EdgeInsets.only(top: 8, bottom: 100),
        itemCount: 5,
        itemBuilder: (context, index) => const QuestionCardSkeleton(),
      );
    }

    if (_error.isNotEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(LucideIcons.wifiOff, size: 48, color: Colors.grey),
              const SizedBox(height: 16),
              Text(
                _error,
                textAlign: TextAlign.center,
                style: const TextStyle(color: Colors.grey),
              ),
              const SizedBox(height: 16),
              ElevatedButton(
                onPressed: _loadQuestions,
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF059669),
                  foregroundColor: Colors.white,
                ),
                child: const Text('Coba Lagi'),
              ),
            ],
          ),
        ),
      );
    }

    if (_questions.isEmpty) {
      return const Center(child: Text('Belum ada diskusi.'));
    }

    return Stack(
      children: [
        ListView.builder(
          padding: const EdgeInsets.only(top: 8, bottom: 100),
          itemCount: _questions.length,
          itemBuilder: (context, index) {
            return Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
              child: QuestionCard(
                question: _questions[index],
                onRefresh: () => _loadQuestions(showFullLoader: false),
              ),
            );
          },
        ),
        // Subtle refresh indicator at top
        if (_isRefreshing)
          Positioned(
            top: 0,
            left: 0,
            right: 0,
            child: Container(
              height: 2,
              child: const LinearProgressIndicator(
                backgroundColor: Colors.transparent,
                valueColor: AlwaysStoppedAnimation<Color>(Color(0xFF059669)),
              ),
            ),
          ),
      ],
    );
  }

  Widget _buildFilterChip(String label, String value, IconData icon) {
    final isActive = _activeFilter == value;
    const activeColor = Color(0xFF059669);
    const inactiveBorderColor = Color(0xFFE2E8F0);
    const inactiveTextColor = Color(0xFF64748B);

    return GestureDetector(
      onTap: () => _setFilter(value),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 10),
        decoration: BoxDecoration(
          color: isActive ? activeColor : Colors.white,
          borderRadius: BorderRadius.circular(24),
          border: Border.all(
            color: isActive ? activeColor : inactiveBorderColor,
          ),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              icon,
              size: 16,
              color: isActive ? Colors.white : inactiveTextColor,
            ),
            const SizedBox(width: 6),
            Flexible(
              child: Text(
                label,
                style: TextStyle(
                  color: isActive ? Colors.white : inactiveTextColor,
                  fontWeight: FontWeight.w600,
                  fontSize: 12,
                ),
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// Sticky Header Delegate
class _StickyFilterHeaderDelegate extends SliverPersistentHeaderDelegate {
  final double minHeight;
  final double maxHeight;
  final Widget child;

  _StickyFilterHeaderDelegate({
    required this.minHeight,
    required this.maxHeight,
    required this.child,
  });

  @override
  double get minExtent => minHeight;

  @override
  double get maxExtent => maxHeight;

  @override
  Widget build(
      BuildContext context, double shrinkOffset, bool overlapsContent) {
    return SizedBox.expand(child: child);
  }

  @override
  bool shouldRebuild(_StickyFilterHeaderDelegate oldDelegate) {
    return maxHeight != oldDelegate.maxHeight ||
        minHeight != oldDelegate.minHeight ||
        child != oldDelegate.child;
  }
}
