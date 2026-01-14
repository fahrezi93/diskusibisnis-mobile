import 'package:flutter/material.dart';
import 'package:lucide_icons/lucide_icons.dart';
import '../services/api_service.dart';
import '../services/auth_service.dart';
import '../widgets/skeleton_loading.dart';
import 'question_detail_screen.dart';

class SavedQuestionsScreen extends StatefulWidget {
  const SavedQuestionsScreen({super.key});

  @override
  State<SavedQuestionsScreen> createState() => _SavedQuestionsScreenState();
}

class _SavedQuestionsScreenState extends State<SavedQuestionsScreen> {
  final ApiService _api = ApiService();
  final AuthService _auth = AuthService();
  List<Map<String, dynamic>> _bookmarks = [];
  bool _isLoading = true;
  bool _isLoggedIn = false;
  String _error = '';

  @override
  void initState() {
    super.initState();
    _initAndLoad();
  }

  Future<void> _initAndLoad() async {
    await _auth.init();
    setState(() {
      _isLoggedIn = _auth.isAuthenticated;
    });
    if (_isLoggedIn) {
      await _loadBookmarks();
    } else {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _loadBookmarks() async {
    setState(() {
      _isLoading = true;
      _error = '';
    });
    try {
      final data = await _api.getBookmarks(token: _auth.token!);
      setState(() {
        _bookmarks = data;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _error = e.toString();
        _isLoading = false;
      });
    }
  }

  Future<void> _removeBookmark(String questionId) async {
    // Optimistic delete - remove from list immediately
    final removedIndex =
        _bookmarks.indexWhere((b) => b['id']?.toString() == questionId);
    Map<String, dynamic>? removedItem;
    if (removedIndex != -1) {
      removedItem = _bookmarks[removedIndex];
      setState(() {
        _bookmarks.removeAt(removedIndex);
      });
    }

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Dihapus dari simpanan'),
          behavior: SnackBarBehavior.floating,
          backgroundColor: Color(0xFF334155),
        ),
      );
    }

    try {
      await _api.deleteBookmark(token: _auth.token!, questionId: questionId);
    } catch (e) {
      // Rollback on error
      if (removedItem != null && mounted) {
        setState(() {
          _bookmarks.insert(removedIndex, removedItem!);
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(e.toString().replaceAll('Exception: ', '')),
            behavior: SnackBarBehavior.floating,
            backgroundColor: const Color(0xFFDC2626),
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(LucideIcons.arrowLeft, color: Color(0xFF0F172A)),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          'Disimpan',
          style: TextStyle(
            color: Color(0xFF0F172A),
            fontWeight: FontWeight.w600,
            fontSize: 16,
          ),
        ),
      ),
      body: _isLoading
          ? ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: 5,
              itemBuilder: (context, index) => const QuestionCardSkeleton(),
            )
          : !_isLoggedIn
              ? _buildLoginRequired()
              : _error.isNotEmpty
                  ? _buildErrorState()
                  : _bookmarks.isEmpty
                      ? _buildEmptyState()
                      : RefreshIndicator(
                          onRefresh: _loadBookmarks,
                          color: const Color(0xFF059669),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              // Header info
                              Padding(
                                padding: const EdgeInsets.all(16),
                                child: Row(
                                  children: [
                                    const Icon(LucideIcons.bookmark,
                                        color: Color(0xFF059669), size: 18),
                                    const SizedBox(width: 8),
                                    Text(
                                      '${_bookmarks.length} pertanyaan tersimpan',
                                      style: const TextStyle(
                                        fontSize: 13,
                                        fontWeight: FontWeight.w600,
                                        color: Color(0xFF64748B),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              // Bookmarks list
                              Expanded(
                                child: ListView.separated(
                                  padding:
                                      const EdgeInsets.fromLTRB(16, 0, 16, 16),
                                  itemCount: _bookmarks.length,
                                  separatorBuilder: (_, __) =>
                                      const SizedBox(height: 12),
                                  itemBuilder: (context, index) {
                                    return _buildBookmarkCard(
                                        _bookmarks[index]);
                                  },
                                ),
                              ),
                            ],
                          ),
                        ),
    );
  }

  Widget _buildBookmarkCard(Map<String, dynamic> bookmark) {
    // Backend returns flat structure, not nested 'question' object
    final questionId = bookmark['id']?.toString() ?? '';
    final title = bookmark['title'] ?? '';
    final upvotes =
        int.tryParse(bookmark['upvotes_count']?.toString() ?? '0') ?? 0;
    final answers =
        int.tryParse(bookmark['answers_count']?.toString() ?? '0') ?? 0;
    final views = int.tryParse(bookmark['views_count']?.toString() ?? '0') ?? 0;
    // bookmark['bookmarked_at'] is when it was bookmarked, created_at is question creation
    final createdAt =
        DateTime.tryParse(bookmark['created_at'] ?? '') ?? DateTime.now();

    return Dismissible(
      key: Key(questionId),
      direction: DismissDirection.endToStart,
      background: Container(
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.only(right: 20),
        decoration: BoxDecoration(
          color: const Color(0xFFDC2626),
          borderRadius: BorderRadius.circular(12),
        ),
        child: const Icon(LucideIcons.trash2, color: Colors.white),
      ),
      onDismissed: (_) => _removeBookmark(questionId),
      child: GestureDetector(
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) =>
                  QuestionDetailScreen(questionId: questionId),
            ),
          );
        },
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: const Color(0xFFE2E8F0)),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Text(
                      title,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w600,
                        color: Color(0xFF0F172A),
                      ),
                    ),
                  ),
                  IconButton(
                    icon: const Icon(LucideIcons.bookmark,
                        color: Color(0xFF059669), size: 18),
                    onPressed: () => _removeBookmark(questionId),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Row(
                children: [
                  const Icon(LucideIcons.arrowUp,
                      size: 14, color: Color(0xFF059669)),
                  const SizedBox(width: 4),
                  Text('$upvotes',
                      style: const TextStyle(
                          fontSize: 12, color: Color(0xFF64748B))),
                  const SizedBox(width: 12),
                  const Icon(LucideIcons.messageCircle,
                      size: 14, color: Color(0xFF64748B)),
                  const SizedBox(width: 4),
                  Text('$answers',
                      style: const TextStyle(
                          fontSize: 12, color: Color(0xFF64748B))),
                  const SizedBox(width: 12),
                  const Icon(LucideIcons.eye,
                      size: 14, color: Color(0xFF64748B)),
                  const SizedBox(width: 4),
                  Text('$views',
                      style: const TextStyle(
                          fontSize: 12, color: Color(0xFF64748B))),
                  const Spacer(),
                  Text(
                    _formatTimeAgo(createdAt),
                    style:
                        const TextStyle(fontSize: 11, color: Color(0xFF94A3B8)),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(24),
            decoration: const BoxDecoration(
              color: Color(0xFFF8FAFC),
              shape: BoxShape.circle,
            ),
            child: const Icon(LucideIcons.bookmark,
                size: 48, color: Color(0xFFCBD5E1)),
          ),
          const SizedBox(height: 16),
          const Text(
            'Belum ada simpanan',
            style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: Color(0xFF0F172A)),
          ),
          const SizedBox(height: 4),
          const Text(
            'Simpan pertanyaan favorit untuk dibaca nanti',
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 13, color: Color(0xFF64748B)),
          ),
        ],
      ),
    );
  }

  Widget _buildLoginRequired() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(24),
            decoration: const BoxDecoration(
              color: Color(0xFFF8FAFC),
              shape: BoxShape.circle,
            ),
            child: const Icon(LucideIcons.logIn,
                size: 48, color: Color(0xFFCBD5E1)),
          ),
          const SizedBox(height: 16),
          const Text(
            'Login diperlukan',
            style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: Color(0xFF0F172A)),
          ),
          const SizedBox(height: 4),
          const Text(
            'Silakan login untuk melihat simpanan Anda',
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 13, color: Color(0xFF64748B)),
          ),
        ],
      ),
    );
  }

  Widget _buildErrorState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(LucideIcons.alertCircle, size: 48, color: Colors.grey),
          const SizedBox(height: 16),
          Text('Gagal memuat data\n$_error',
              textAlign: TextAlign.center,
              style: const TextStyle(color: Colors.grey)),
          const SizedBox(height: 16),
          ElevatedButton(
            onPressed: _loadBookmarks,
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF059669),
              foregroundColor: Colors.white,
            ),
            child: const Text('Coba Lagi'),
          ),
        ],
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
