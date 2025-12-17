import 'package:flutter/material.dart';
import 'package:lucide_icons/lucide_icons.dart';
import '../services/api_service.dart';
import '../models/question.dart';
import '../utils/avatar_helper.dart';
import 'question_detail_screen.dart';
import 'profile_screen.dart';

class UnansweredQuestionsScreen extends StatefulWidget {
  const UnansweredQuestionsScreen({super.key});

  @override
  State<UnansweredQuestionsScreen> createState() =>
      _UnansweredQuestionsScreenState();
}

class _UnansweredQuestionsScreenState extends State<UnansweredQuestionsScreen> {
  final ApiService _api = ApiService();
  List<Question> _questions = [];
  bool _isLoading = true;
  String _error = '';
  String _activeSort = 'newest';

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
      final data = await _api.getQuestions(
        sort: _activeSort == 'votes'
            ? 'most_voted'
            : _activeSort == 'views'
                ? 'most_viewed'
                : _activeSort == 'newest'
                    ? 'newest'
                    : 'unanswered',
      );
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

  void _changeSortFilter(String sort) {
    if (_activeSort != sort) {
      setState(() => _activeSort = sort);
      _loadQuestions();
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
                                  'KOMUNITAS',
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
                            'Bantu Jawab Pertanyaan',
                            style: TextStyle(
                              fontSize: 26,
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                            ),
                          ),
                          const SizedBox(height: 6),
                          Text(
                            'Temukan pertanyaan yang belum terjawab dan bagikan pengetahuan Anda.',
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
                        'Vote Terbanyak', 'votes', LucideIcons.trendingUp),
                  ),
                  const SizedBox(width: 4),
                  Expanded(
                    child: _buildFilterChip(
                        'Paling Dilihat', 'views', LucideIcons.eye),
                  ),
                ],
              ),
            ),
          ),

          // Questions list
          _isLoading
              ? const SliverFillRemaining(
                  child: Center(
                    child: CircularProgressIndicator(color: Color(0xFF059669)),
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
                                return Padding(
                                  padding: const EdgeInsets.only(bottom: 12),
                                  child: _buildQuestionCard(_questions[index]),
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
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
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
              size: 13,
              color: isActive ? Colors.white : const Color(0xFF64748B),
            ),
            const SizedBox(width: 4),
            Flexible(
              child: Text(
                label,
                style: TextStyle(
                  color: isActive ? Colors.white : const Color(0xFF64748B),
                  fontWeight: FontWeight.w600,
                  fontSize: 11,
                ),
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildQuestionCard(Question question) {
    return GestureDetector(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => QuestionDetailScreen(questionId: question.id),
          ),
        );
      },
      behavior: HitTestBehavior.opaque,
      child: Stack(
        children: [
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: const Color(0xFFE2E8F0)),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.02),
                  blurRadius: 4,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Author info - Tappable
                GestureDetector(
                  onTap: question.author.id != null
                      ? () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) =>
                                  ProfileScreen(userId: question.author.id!),
                            ),
                          );
                        }
                      : null,
                  child: Row(
                    children: [
                      AvatarHelper.buildAvatarWithBadge(
                          avatarUrl: question.author.avatar,
                          name: question.author.name,
                          reputation: question.author.reputation,
                          isVerified: question.author.isVerified,
                          radius: 14),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Row(
                          children: [
                            Flexible(
                              child: Text(
                                question.author.name,
                                style: const TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w600,
                                  color: Color(0xFF64748B),
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                            if (question.author.isVerified)
                              AvatarHelper.getVerifiedBadge(size: 14),
                          ],
                        ),
                      ),
                      Text(
                        _formatTimeAgo(question.createdAt),
                        style: const TextStyle(
                          fontSize: 11,
                          color: Color(0xFF94A3B8),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 12),
                // Title
                Text(
                  question.title,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w700,
                    color: Color(0xFF0F172A),
                    height: 1.3,
                  ),
                ),
                // Tags
                if (question.tags.isNotEmpty) ...[
                  const SizedBox(height: 10),
                  Wrap(
                    spacing: 6,
                    runSpacing: 6,
                    children: question.tags.take(3).map((tag) {
                      return Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: const Color(0xFFECFDF5),
                          borderRadius: BorderRadius.circular(6),
                          border: Border.all(color: const Color(0xFFD1FAE5)),
                        ),
                        child: Text(
                          tag.name,
                          style: const TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w500,
                            color: Color(0xFF059669),
                          ),
                        ),
                      );
                    }).toList(),
                  ),
                ],
                const SizedBox(height: 12),
                // Stats
                Row(
                  children: [
                    const Icon(LucideIcons.arrowUp,
                        size: 14, color: Color(0xFF059669)),
                    const SizedBox(width: 4),
                    Text(
                      '${question.upvotesCount}',
                      style: const TextStyle(
                          fontSize: 12,
                          color: Color(0xFF059669),
                          fontWeight: FontWeight.w600),
                    ),
                    const SizedBox(width: 12),
                    const Icon(LucideIcons.eye,
                        size: 14, color: Color(0xFF64748B)),
                    const SizedBox(width: 4),
                    Text(
                      '${question.viewsCount}',
                      style: const TextStyle(
                          fontSize: 12, color: Color(0xFF64748B)),
                    ),
                  ],
                ),
              ],
            ),
          ),
          // "Butuh Jawaban" badge
          Positioned(
            top: 16,
            right: 16,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
              decoration: BoxDecoration(
                color: const Color(0xFFECFDF5),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: const Color(0xFFD1FAE5)),
              ),
              child: const Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(LucideIcons.helpCircle,
                      size: 12, color: Color(0xFF059669)),
                  SizedBox(width: 4),
                  Text(
                    'Butuh Jawaban',
                    style: TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.w700,
                      color: Color(0xFF059669),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
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
                gradient: const LinearGradient(
                  colors: [Color(0xFF059669), Color(0xFF10B981)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(20),
              ),
              child: const Icon(
                LucideIcons.sparkles,
                size: 40,
                color: Colors.white,
              ),
            ),
            const SizedBox(height: 24),
            const Text(
              'Semua Pertanyaan Sudah Terjawab!',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: Color(0xFF0F172A),
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            const Text(
              'Luar biasa! Komunitas sangat aktif dan semua pertanyaan telah mendapatkan jawaban.',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 14,
                color: Color(0xFF64748B),
                height: 1.5,
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

  String _formatTimeAgo(DateTime date) {
    final diff = DateTime.now().difference(date);
    if (diff.inDays > 0) return '${diff.inDays}h lalu';
    if (diff.inHours > 0) return '${diff.inHours}j lalu';
    return '${diff.inMinutes}m lalu';
  }
}
