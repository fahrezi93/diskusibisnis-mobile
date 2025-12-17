import 'package:flutter/material.dart';
import 'package:lucide_icons/lucide_icons.dart';
import '../widgets/hero_section.dart';
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
  String _error = '';
  String _activeFilter = 'newest';

  @override
  void initState() {
    super.initState();
    _loadQuestions();
  }

  Future<void> _loadQuestions() async {
    setState(() {
      _isLoading = true;
      _error = '';
    });
    try {
      final data = await _api.getQuestions(sort: _activeFilter);
      setState(() {
        _questions = data;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _error = e.toString();
        _isLoading = false;
      });
    }
  }

  void _setFilter(String filter) {
    if (_activeFilter != filter) {
      setState(() => _activeFilter = filter);
      _loadQuestions();
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
    if (_isLoading) {
      return const Center(
        child: CircularProgressIndicator(color: Color(0xFF059669)),
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
                'Gagal memuat data.\n$_error',
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

    return ListView.builder(
      padding: const EdgeInsets.only(top: 8, bottom: 100),
      itemCount: _questions.length,
      itemBuilder: (context, index) {
        return Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
          child: QuestionCard(question: _questions[index]),
        );
      },
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
