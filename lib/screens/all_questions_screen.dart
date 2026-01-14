import 'package:flutter/material.dart';
import 'package:lucide_icons/lucide_icons.dart';
import '../services/api_service.dart';
import '../models/question.dart';

import '../widgets/question_card.dart';
import '../widgets/skeleton_loading.dart';

class AllQuestionsScreen extends StatefulWidget {
  final String initialSort;
  const AllQuestionsScreen({super.key, this.initialSort = 'newest'});

  @override
  State<AllQuestionsScreen> createState() => _AllQuestionsScreenState();
}

class _AllQuestionsScreenState extends State<AllQuestionsScreen> {
  final ApiService _api = ApiService();
  List<Question> _questions = [];
  bool _isLoading = true;
  bool _isRefreshing = false;
  String _error = '';
  late String _activeSort;

  // Cache for instant filter switching
  final Map<String, List<Question>> _sortCache = {};

  @override
  void initState() {
    super.initState();
    _activeSort = widget.initialSort;
    _loadQuestions();
  }

  Future<void> _loadQuestions({bool showFullLoader = true}) async {
    // Use cache for instant display
    if (_sortCache.containsKey(_activeSort) && showFullLoader) {
      setState(() {
        _questions = _sortCache[_activeSort]!;
        _isLoading = false;
        _isRefreshing = true;
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
      final data = await _api.getQuestions(sort: _activeSort);
      _sortCache[_activeSort] = data;
      if (mounted) {
        setState(() {
          _questions = data;
          _isLoading = false;
          _isRefreshing = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          if (_sortCache.containsKey(_activeSort)) {
            _questions = _sortCache[_activeSort]!;
          }
          _error = _questions.isEmpty ? e.toString() : '';
          _isLoading = false;
          _isRefreshing = false;
        });
      }
    }
  }

  void _changeSortFilter(String sort) {
    if (_activeSort != sort) {
      setState(() => _activeSort = sort);
      if (_sortCache.containsKey(sort)) {
        setState(() => _questions = _sortCache[sort]!);
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
      body: CustomScrollView(
        slivers: [
          // Modern Gradient Header - matching website
          SliverAppBar(
            expandedHeight: 220,
            floating: false,
            pinned: true,
            backgroundColor: const Color(0xFF059669),
            flexibleSpace: FlexibleSpaceBar(
              background: Container(
                decoration: const BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      Color(0xFF059669),
                      Color(0xFF10B981),
                      Color(0xFF0D9488)
                    ],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                ),
                child: Stack(
                  children: [
                    // Decorative circles
                    Positioned(
                      top: -50,
                      right: -50,
                      child: Container(
                        width: 200,
                        height: 200,
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.1),
                          shape: BoxShape.circle,
                        ),
                      ),
                    ),
                    Positioned(
                      bottom: -30,
                      left: -30,
                      child: Container(
                        width: 150,
                        height: 150,
                        decoration: BoxDecoration(
                          color: const Color(0xFF0D9488).withOpacity(0.2),
                          shape: BoxShape.circle,
                        ),
                      ),
                    ),
                    // Content
                    Padding(
                      padding: const EdgeInsets.fromLTRB(16, 60, 16, 24),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisAlignment: MainAxisAlignment.end,
                        children: [
                          Row(
                            children: [
                              Container(
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 10, vertical: 4),
                                decoration: BoxDecoration(
                                  color: Colors.white.withOpacity(0.2),
                                  borderRadius: BorderRadius.circular(20),
                                  border: Border.all(
                                    color: Colors.white.withOpacity(0.3),
                                  ),
                                ),
                                child: const Text(
                                  'DISKUSI',
                                  style: TextStyle(
                                    fontSize: 10,
                                    color: Colors.white,
                                    fontWeight: FontWeight.w700,
                                    letterSpacing: 1,
                                  ),
                                ),
                              ),
                              const SizedBox(width: 8),
                              Container(
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 10, vertical: 4),
                                decoration: BoxDecoration(
                                  color: Colors.white.withOpacity(0.15),
                                  borderRadius: BorderRadius.circular(20),
                                  border: Border.all(
                                    color: Colors.white.withOpacity(0.2),
                                  ),
                                ),
                                child: Text(
                                  '${_questions.length} Pertanyaan',
                                  style: const TextStyle(
                                    fontSize: 10,
                                    color: Colors.white,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 12),
                          const Text(
                            'Semua Pertanyaan',
                            style: TextStyle(
                              fontSize: 26,
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                            ),
                          ),
                          const SizedBox(height: 6),
                          Text(
                            'Temukan jawaban, bagikan pengalaman bisnis Anda.',
                            style: TextStyle(
                              fontSize: 13,
                              color: Colors.white.withOpacity(0.9),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
            leading: IconButton(
              icon: const Icon(LucideIcons.arrowLeft, color: Colors.white),
              onPressed: () => Navigator.pop(context),
            ),
          ),

          // Filter tabs - matching website style
          SliverToBoxAdapter(
            child: Container(
              margin: const EdgeInsets.all(16),
              padding: const EdgeInsets.all(4),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: const Color(0xFFE2E8F0)),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.02),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Row(
                children: [
                  Expanded(
                    child: _buildFilterChip(
                        'Terbaru', 'newest', LucideIcons.clock),
                  ),
                  const SizedBox(width: 4),
                  Expanded(
                    child: _buildFilterChip(
                        'Populer', 'popular', LucideIcons.trendingUp),
                  ),
                  const SizedBox(width: 4),
                  Expanded(
                    child: _buildFilterChip(
                        'Belum Terjawab', 'unanswered', LucideIcons.helpCircle),
                  ),
                ],
              ),
            ),
          ),

          // Questions list
          _isLoading && _questions.isEmpty
              ? SliverPadding(
                  padding: const EdgeInsets.fromLTRB(16, 0, 16, 100),
                  sliver: SliverList(
                    delegate: SliverChildBuilderDelegate(
                      (context, index) => const QuestionCardSkeleton(),
                      childCount: 5,
                    ),
                  ),
                )
              : _error.isNotEmpty
                  ? SliverFillRemaining(child: _buildErrorState())
                  : _questions.isEmpty
                      ? SliverFillRemaining(child: _buildEmptyState())
                      : SliverPadding(
                          padding: const EdgeInsets.fromLTRB(16, 0, 16, 100),
                          sliver: SliverList(
                            delegate: SliverChildBuilderDelegate(
                              (context, index) {
                                // Show refresh indicator at top
                                if (index == 0 && _isRefreshing) {
                                  return Column(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Container(
                                        height: 2,
                                        child: const LinearProgressIndicator(
                                          backgroundColor: Colors.transparent,
                                          valueColor:
                                              AlwaysStoppedAnimation<Color>(
                                                  Color(0xFF059669)),
                                        ),
                                      ),
                                      Padding(
                                        padding:
                                            const EdgeInsets.only(bottom: 12),
                                        child: QuestionCard(
                                            question: _questions[index],
                                            onRefresh: () => _loadQuestions(
                                                showFullLoader: false)),
                                      ),
                                    ],
                                  );
                                }
                                return Padding(
                                  padding: const EdgeInsets.only(bottom: 12),
                                  child: QuestionCard(
                                      question: _questions[index],
                                      onRefresh: () => _loadQuestions(
                                          showFullLoader: false)),
                                );
                              },
                              childCount: _questions.length,
                            ),
                          ),
                        ),
        ],
      ),
    );
  }

  Widget _buildFilterChip(String label, String value, IconData icon) {
    final isActive = _activeSort == value;
    return GestureDetector(
      onTap: () => _changeSortFilter(value),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        decoration: BoxDecoration(
          color: isActive ? const Color(0xFF059669) : Colors.transparent,
          borderRadius: BorderRadius.circular(12),
          boxShadow: isActive
              ? [
                  BoxShadow(
                    color: const Color(0xFF059669).withOpacity(0.1),
                    blurRadius: 4,
                  ),
                ]
              : null,
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              icon,
              size: 14,
              color: isActive ? Colors.white : const Color(0xFF64748B),
            ),
            const SizedBox(width: 6),
            Flexible(
              child: Text(
                label,
                style: TextStyle(
                  color: isActive ? Colors.white : const Color(0xFF64748B),
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

  Widget _buildEmptyState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 80,
              height: 80,
              decoration: BoxDecoration(
                color: const Color(0xFFECFDF5),
                borderRadius: BorderRadius.circular(20),
              ),
              child: const Icon(
                LucideIcons.sparkles,
                size: 40,
                color: Color(0xFF059669),
              ),
            ),
            const SizedBox(height: 24),
            const Text(
              'Belum Ada Pertanyaan',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: Color(0xFF0F172A),
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Jadilah yang pertama bertanya di komunitas kami!',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 14,
                color: const Color(0xFF64748B),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildErrorState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(LucideIcons.alertCircle,
                size: 48, color: Color(0xFFCBD5E1)),
            const SizedBox(height: 16),
            Text(
              'Gagal memuat data\n$_error',
              textAlign: TextAlign.center,
              style: const TextStyle(color: Color(0xFF64748B)),
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: _loadQuestions,
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF059669),
                foregroundColor: Colors.white,
                padding:
                    const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              child: const Text('Coba Lagi'),
            ),
          ],
        ),
      ),
    );
  }
}
