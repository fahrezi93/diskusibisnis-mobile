import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:lucide_icons/lucide_icons.dart';
import '../config/app_config.dart';
import '../services/api_service.dart';
import '../services/auth_service.dart';
import '../utils/avatar_helper.dart';
import '../widgets/rich_content_text.dart';
import 'profile_screen.dart';
import 'tag_detail_screen.dart';
import '../models/user_profile.dart';
import '../models/tag.dart' as tag_model;
import '../widgets/comment_section.dart';
import '../widgets/vote_widget.dart';
import '../widgets/skeleton_loading.dart';

class QuestionDetailScreen extends StatefulWidget {
  final String questionId;

  const QuestionDetailScreen({super.key, required this.questionId});

  @override
  State<QuestionDetailScreen> createState() => _QuestionDetailScreenState();
}

class _QuestionDetailScreenState extends State<QuestionDetailScreen> {
  final ApiService _api = ApiService();
  final AuthService _auth = AuthService();
  final TextEditingController _answerController = TextEditingController();

  Map<String, dynamic>? _question;
  bool _isLoading = true;
  bool _isSendingAnswer = false;
  String _error = '';

  // User mention for answer
  bool _showMentionSuggestions = false;
  String _mentionQuery = '';
  List<UserProfile> _mentionSuggestions = [];
  int _mentionStartIndex = -1;

  @override
  void initState() {
    super.initState();
    _answerController.addListener(_onAnswerContentChanged);
    _loadQuestion();
  }

  @override
  void dispose() {
    _answerController.dispose();
    super.dispose();
  }

  // --- Mention Logic Start ---
  void _onAnswerContentChanged() {
    final text = _answerController.text;
    final selection = _answerController.selection;

    if (!selection.isValid) {
      if (_showMentionSuggestions)
        setState(() => _showMentionSuggestions = false);
      return;
    }

    if (selection.baseOffset != selection.extentOffset) {
      if (_showMentionSuggestions)
        setState(() => _showMentionSuggestions = false);
      return;
    }

    final cursorPos = selection.baseOffset;
    if (cursorPos <= 0 || cursorPos > text.length) {
      if (_showMentionSuggestions)
        setState(() => _showMentionSuggestions = false);
      return;
    }

    final textBeforeCursor = text.substring(0, cursorPos);
    final lastAtIndex = textBeforeCursor.lastIndexOf('@');

    if (lastAtIndex == -1) {
      if (_showMentionSuggestions)
        setState(() => _showMentionSuggestions = false);
      return;
    }

    final textAfterAt = textBeforeCursor.substring(lastAtIndex + 1);
    if (textAfterAt.contains(' ') || textAfterAt.contains('\n')) {
      if (_showMentionSuggestions)
        setState(() => _showMentionSuggestions = false);
      return;
    }

    if (lastAtIndex > 0) {
      final charBefore = textBeforeCursor[lastAtIndex - 1];
      if (charBefore != ' ' && charBefore != '\n') {
        if (_showMentionSuggestions)
          setState(() => _showMentionSuggestions = false);
        return;
      }
    }

    _mentionQuery = textAfterAt;
    _mentionStartIndex = lastAtIndex;

    // Search even if empty (just @)
    _searchUsers(_mentionQuery);
  }

  Future<void> _searchUsers(String query) async {
    try {
      final searchQuery = query.isEmpty ? '' : query;
      // Pass 'a' as fallback if empty to get some popular users
      final users = await _api
          .searchUsersForMention(searchQuery.isEmpty ? 'a' : searchQuery);

      if (mounted) {
        setState(() {
          _mentionSuggestions = users;
          _showMentionSuggestions = users.isNotEmpty;
        });
      }
    } catch (e) {
      print('Error searching users: $e');
    }
  }

  void _insertMention(UserProfile user) {
    final text = _answerController.text;
    final beforeMention = text.substring(0, _mentionStartIndex);
    final afterMention = text.substring(_answerController.selection.baseOffset);

    // Use username or display name without spaces
    final mentionText =
        '@${user.username ?? user.displayName.replaceAll(' ', '')} ';

    final newText = beforeMention + mentionText + afterMention;
    _answerController.text = newText;

    // Move cursor after the mention
    _answerController.selection = TextSelection.fromPosition(
      TextPosition(offset: beforeMention.length + mentionText.length),
    );

    setState(() {
      _showMentionSuggestions = false;
    });
  }
  // --- Mention Logic End ---

  Future<void> _loadQuestion({bool refresh = false}) async {
    if (!refresh) {
      setState(() {
        _isLoading = true;
        _error = '';
      });
    }

    try {
      await _auth.init();
      final data = await _api.getQuestionById(
        widget.questionId,
        token: _auth.token,
        userId: _auth.currentUser?.id,
      );
      if (mounted) {
        setState(() {
          _question = data;
          // Only update loading state if this is not a silent refresh
          if (!refresh) {
            _isLoading = false;
          }
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _error = e.toString();
          // Only update loading state if this is not a silent refresh
          if (!refresh) {
            _isLoading = false;
          }
        });
      }
    }
  }

  Future<void> _handleVote(String voteType, {String? answerId}) async {
    if (!_auth.isAuthenticated) {
      _showSnackBar('Login diperlukan untuk vote');
      return;
    }

    // Store previous state for rollback if API fails
    final previousQuestion = Map<String, dynamic>.from(_question!);

    // Optimistic UI Update - update immediately without waiting for API
    setState(() {
      if (answerId == null) {
        // Voting on question
        _updateQuestionVoteOptimistically(voteType);
      } else {
        // Voting on answer
        _updateAnswerVoteOptimistically(answerId, voteType);
      }
    });

    try {
      await _api.vote(
        token: _auth.token!,
        questionId: answerId == null ? widget.questionId : null,
        answerId: answerId,
        voteType: voteType,
      );
      // Background refresh to sync with server (non-blocking)
      _loadQuestion(refresh: true);
    } catch (e) {
      // Rollback to previous state on error
      if (mounted) {
        setState(() {
          _question = previousQuestion;
        });
      }
      _showSnackBar(e.toString().replaceAll('Exception: ', ''));
    }
  }

  void _updateQuestionVoteOptimistically(String voteType) {
    final currentVote = _question!['user_vote'];
    int upvotes =
        int.tryParse(_question!['upvotes_count']?.toString() ?? '0') ?? 0;
    int downvotes =
        int.tryParse(_question!['downvotes_count']?.toString() ?? '0') ?? 0;

    if (currentVote == voteType) {
      // Toggle off - removing vote
      _question!['user_vote'] = null;
      if (voteType == 'upvote') {
        upvotes--;
      } else {
        downvotes--;
      }
    } else {
      // New vote or changing vote
      if (currentVote == 'upvote') {
        upvotes--;
      } else if (currentVote == 'downvote') {
        downvotes--;
      }

      if (voteType == 'upvote') {
        upvotes++;
      } else {
        downvotes++;
      }
      _question!['user_vote'] = voteType;
    }

    _question!['upvotes_count'] = upvotes;
    _question!['downvotes_count'] = downvotes;
  }

  void _updateAnswerVoteOptimistically(String answerId, String voteType) {
    final answers = _question!['answers'] as List? ?? [];
    for (int i = 0; i < answers.length; i++) {
      final answer = answers[i];
      if (answer['id']?.toString() == answerId) {
        final currentVote = answer['user_vote'];
        int upvotes =
            int.tryParse(answer['upvotes_count']?.toString() ?? '0') ?? 0;
        int downvotes =
            int.tryParse(answer['downvotes_count']?.toString() ?? '0') ?? 0;

        if (currentVote == voteType) {
          // Toggle off
          answer['user_vote'] = null;
          if (voteType == 'upvote') {
            upvotes--;
          } else {
            downvotes--;
          }
        } else {
          // New vote or changing
          if (currentVote == 'upvote') {
            upvotes--;
          } else if (currentVote == 'downvote') {
            downvotes--;
          }

          if (voteType == 'upvote') {
            upvotes++;
          } else {
            downvotes++;
          }
          answer['user_vote'] = voteType;
        }

        answer['upvotes_count'] = upvotes;
        answer['downvotes_count'] = downvotes;
        break;
      }
    }
  }

  Future<void> _handleBookmark() async {
    if (!_auth.isAuthenticated) {
      _showSnackBar('Login diperlukan untuk menyimpan');
      return;
    }

    final isBookmarked = _question!['is_bookmarked'] == true;

    // Optimistic update - immediately toggle UI
    setState(() {
      _question!['is_bookmarked'] = !isBookmarked;
    });

    // Show feedback immediately
    _showSnackBar(
        isBookmarked ? 'Dihapus dari simpanan' : 'Disimpan ke koleksi');

    try {
      if (isBookmarked) {
        await _api.deleteBookmark(
          token: _auth.token!,
          questionId: widget.questionId,
        );
      } else {
        await _api.createBookmark(
          token: _auth.token!,
          questionId: widget.questionId,
        );
      }
      // Background sync
      _loadQuestion(refresh: true);
    } catch (e) {
      // Rollback on error
      if (mounted) {
        setState(() {
          _question!['is_bookmarked'] = isBookmarked;
        });
      }
      _showSnackBar(e.toString().replaceAll('Exception: ', ''));
    }
  }

  Future<void> _handleSendAnswer() async {
    final content = _answerController.text.trim();
    if (content.length < 20) {
      _showSnackBar(
          'Jawaban minimal 20 karakter (saat ini: ${content.length})');
      return;
    }

    if (content.isEmpty) {
      _showSnackBar('Tulis jawaban terlebih dahulu');
      return;
    }

    if (!_auth.isAuthenticated) {
      _showSnackBar('Login diperlukan untuk menjawab');
      return;
    }

    setState(() => _isSendingAnswer = true);

    print('[QuestionDetail] Sending answer: $content');

    try {
      await _api.postAnswer(
        token: _auth.token!,
        questionId: widget.questionId,
        content: content,
      );
      _answerController.clear();
      FocusScope.of(context).unfocus();
      _showSnackBar('Jawaban berhasil dikirim!');
      await _loadQuestion(refresh: true); // Update list
    } catch (e) {
      print('[QuestionDetail] Kirim jawaban error: $e');
      _showSnackBar(e.toString().replaceAll('Exception: ', ''));
    } finally {
      if (mounted) setState(() => _isSendingAnswer = false);
    }
  }

  Future<void> _handleAcceptAnswer(String answerId) async {
    if (!_auth.isAuthenticated) {
      _showSnackBar('Login diperlukan');
      return;
    }

    try {
      await _api.acceptAnswer(token: _auth.token!, answerId: answerId);
      _showSnackBar('Jawaban diterima!');
      await _loadQuestion(refresh: true); // Silent refresh
    } catch (e) {
      _showSnackBar(e.toString().replaceAll('Exception: ', ''));
    }
  }

  Future<void> _handlePostComment(
      String content, String type, String id) async {
    if (!_auth.isAuthenticated) {
      _showSnackBar('Login diperlukan untuk berkomentar');
      return;
    }

    try {
      await _api.createComment(
        token: _auth.token!,
        content: content,
        commentableType: type,
        commentableId: id,
      );
      _showSnackBar('Komentar berhasil dikirim!');
      await _loadQuestion(refresh: true);
    } catch (e) {
      _showSnackBar(e.toString().replaceAll('Exception: ', ''));
    }
  }

  Future<void> _handleReport(
      String type, String id, String titleOrContent) async {
    if (!_auth.isAuthenticated) {
      _showSnackBar('Login diperlukan untuk melapor');
      return;
    }

    final reasonController = TextEditingController();
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Lapor $type'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text('Apa alasan Anda melaporkan konten ini?'),
            const SizedBox(height: 12),
            TextField(
              controller: reasonController,
              decoration: const InputDecoration(
                hintText: 'Contoh: Spam, konten kasar, dll.',
                border: OutlineInputBorder(),
              ),
              maxLines: 3,
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Batal'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              foregroundColor: Colors.white,
            ),
            child: const Text('Lapor'),
          ),
        ],
      ),
    );

    if (confirm == true) {
      if (reasonController.text.trim().isEmpty) {
        _showSnackBar('Alasan lapor wajib diisi');
        return;
      }

      try {
        final userData = _auth.currentUser;
        await _api.createTicket(
          name: userData?.displayName ?? 'Reporter',
          email: userData?.email ?? 'reporter@app.com',
          subject: 'Lapor $type #$id',
          message:
              'Alasan: ${reasonController.text}\n\nKonten yang dilaporkan:\n$titleOrContent\n\nID: $id\nLink: https://diskusibisnis.my.id/questions/${widget.questionId}',
          category: 'report',
        );
        _showSnackBar('Laporan berhasil dikirim. Terima kasih!');
      } catch (e) {
        _showSnackBar(e.toString().replaceAll('Exception: ', ''));
      }
    }
  }

  Future<void> _handleEditAnswer(String answerId, String currentContent) async {
    final contentController = TextEditingController(text: currentContent);

    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Edit Jawaban'),
        content: TextField(
          controller: contentController,
          decoration: const InputDecoration(
            border: OutlineInputBorder(),
            hintText: 'Tulis jawaban Anda...',
          ),
          maxLines: 5,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Batal'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF059669),
              foregroundColor: Colors.white,
            ),
            child: const Text('Simpan'),
          ),
        ],
      ),
    );

    if (confirm == true) {
      if (contentController.text.length < 20) {
        _showSnackBar('Jawaban minimal 20 karakter');
        return;
      }

      try {
        await _api.updateAnswer(
          id: answerId,
          token: _auth.token!,
          content: contentController.text,
        );
        _showSnackBar('Jawaban berhasil diupdate');
        _loadQuestion(refresh: true);
      } catch (e) {
        _showSnackBar(e.toString().replaceAll('Exception: ', ''));
      }
    }
  }

  Future<void> _handleDeleteAnswer(String answerId) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Hapus Jawaban'),
        content: const Text('Apakah Anda yakin ingin menghapus jawaban ini?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Batal'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Hapus'),
          ),
        ],
      ),
    );

    if (confirm == true) {
      try {
        await _api.deleteAnswer(id: answerId, token: _auth.token!);
        _showSnackBar('Jawaban berhasil dihapus');
        _loadQuestion(refresh: true);
      } catch (e) {
        _showSnackBar(e.toString().replaceAll('Exception: ', ''));
      }
    }
  }

  Future<void> _navigateToUserByUsername(String username) async {
    try {
      // Search for user by username
      final users = await _api.searchUsersForMention(username);
      if (users.isNotEmpty) {
        final user = users.firstWhere(
          (u) => u.username?.toLowerCase() == username.toLowerCase(),
          orElse: () => users.first,
        );
        if (mounted) {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => ProfileScreen(userId: user.id),
            ),
          );
        }
      } else {
        _showSnackBar('User @$username tidak ditemukan');
      }
    } catch (e) {
      _showSnackBar('Gagal menemukan user');
    }
  }

  void _showFullImage(BuildContext context, String imageUrl) {
    showDialog(
      context: context,
      builder: (context) => Dialog(
        backgroundColor: Colors.transparent,
        insetPadding: const EdgeInsets.all(10),
        child: Stack(
          children: [
            GestureDetector(
              onTap: () => Navigator.pop(context),
              child: Container(
                color: Colors.black.withValues(alpha: 0.9),
                child: Center(
                  child: InteractiveViewer(
                    panEnabled: true,
                    minScale: 0.5,
                    maxScale: 4,
                    child: Image.network(
                      imageUrl,
                      fit: BoxFit.contain,
                      errorBuilder: (_, __, ___) => const Icon(
                        Icons.broken_image,
                        color: Colors.white54,
                        size: 64,
                      ),
                    ),
                  ),
                ),
              ),
            ),
            Positioned(
              top: 10,
              right: 10,
              child: IconButton(
                icon: const Icon(Icons.close, color: Colors.white, size: 30),
                onPressed: () => Navigator.pop(context),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        behavior: SnackBarBehavior.floating,
        backgroundColor: const Color(0xFF334155),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      resizeToAvoidBottomInset: true,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(LucideIcons.arrowLeft, color: Color(0xFF0F172A)),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          'Detail Pertanyaan',
          style: TextStyle(
            color: Color(0xFF0F172A),
            fontWeight: FontWeight.w600,
            fontSize: 16,
          ),
        ),
        actions: [
          IconButton(
            icon: const Icon(LucideIcons.share2, color: Color(0xFF64748B)),
            onPressed: () {
              if (_question != null) {
                final questionId = widget.questionId;
                final url = 'https://diskusibisnis.my.id/questions/$questionId';
                Clipboard.setData(ClipboardData(text: url));
                _showSnackBar('Link disalin ke clipboard!');
              }
            },
          ),
          if (_question != null)
            IconButton(
              icon: Icon(
                _question!['is_bookmarked'] == true
                    ? Icons.bookmark // Use Material filled bookmark
                    : LucideIcons.bookmark, // Use Lucide outlined bookmark
                color: _question!['is_bookmarked'] == true
                    ? const Color(0xFF059669)
                    : const Color(0xFF64748B),
              ),
              onPressed: _handleBookmark,
            ),
        ],
      ),
      body: Stack(
        children: [
          Positioned.fill(
            child: _isLoading
                ? const QuestionDetailSkeleton()
                : _error.isNotEmpty
                    ? _buildErrorState()
                    : _question == null
                        ? const Center(
                            child: Text('Pertanyaan tidak ditemukan'))
                        : Column(
                            children: [
                              Expanded(
                                child: RefreshIndicator(
                                  onRefresh: _loadQuestion,
                                  color: const Color(0xFF059669),
                                  child: SingleChildScrollView(
                                    physics:
                                        const AlwaysScrollableScrollPhysics(),
                                    child: Column(
                                      children: [
                                        _buildQuestionSection(),
                                        const SizedBox(height: 8),
                                        _buildAnswersSection(),
                                        const SizedBox(height: 16),
                                      ],
                                    ),
                                  ),
                                ),
                              ),
                              if (_question != null) _buildAnswerInput(),
                            ],
                          ),
          ),
          if (_showMentionSuggestions) _buildMentionSuggestions(),
        ],
      ),
    );
  }

  Widget _buildErrorState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(LucideIcons.alertCircle, size: 48, color: Colors.grey),
            const SizedBox(height: 16),
            Text(_error,
                textAlign: TextAlign.center,
                style: const TextStyle(color: Colors.grey)),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: _loadQuestion,
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

  Widget _buildQuestionSection() {
    final q = _question!;
    final authorId = q['author_id']?.toString() ?? '';
    final authorName = q['author_name'] ?? 'Anonim';
    final authorAvatar = q['author_avatar'] ?? '';
    final authorReputation = q['author_reputation'] ?? 0;
    final authorIsVerified = q['author_is_verified'] == true;
    final title = q['title'] ?? '';
    final content = q['content'] ?? '';
    final upvotes = int.tryParse(q['upvotes_count']?.toString() ?? '0') ?? 0;
    final downvotes =
        int.tryParse(q['downvotes_count']?.toString() ?? '0') ?? 0;
    final views = int.tryParse(q['views_count']?.toString() ?? '0') ?? 0;
    final tags = q['tags'] as List? ?? [];
    final images = q['images'] as List? ?? [];
    final createdAt =
        DateTime.tryParse(q['created_at'] ?? '') ?? DateTime.now();
    final userVote = q['user_vote'];

    return Container(
      color: Colors.white,
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Author Row - with tappable avatar/name and optional menu
          Row(
            children: [
              // Tappable author section
              Expanded(
                child: GestureDetector(
                  onTap: authorId.isNotEmpty
                      ? () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) =>
                                  ProfileScreen(userId: authorId),
                            ),
                          );
                        }
                      : null,
                  child: Row(
                    children: [
                      AvatarHelper.buildAvatarWithBadge(
                        avatarUrl: authorAvatar,
                        name: authorName,
                        reputation:
                            authorReputation is int ? authorReputation : 0,
                        isVerified: authorIsVerified,
                        radius: 20,
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Flexible(
                                  child: Text(
                                    authorName,
                                    style: const TextStyle(
                                      fontWeight: FontWeight.w600,
                                      fontSize: 14,
                                      color: Color(0xFF0F172A),
                                    ),
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                                if (authorIsVerified)
                                  AvatarHelper.getVerifiedBadge(),
                              ],
                            ),
                            Row(
                              children: [
                                Text(
                                  '$authorReputation reputasi',
                                  style: const TextStyle(
                                      fontSize: 12, color: Color(0xFF64748B)),
                                ),
                                const Text(' • ',
                                    style: TextStyle(color: Color(0xFF94A3B8))),
                                Text(
                                  _formatTimeAgo(createdAt),
                                  style: const TextStyle(
                                      fontSize: 12, color: Color(0xFF64748B)),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              // Menu button
              if (_auth.isAuthenticated)
                PopupMenuButton<String>(
                  icon: const Icon(LucideIcons.moreHorizontal,
                      color: Color(0xFF64748B)),
                  onSelected: (value) async {
                    if (value == 'report') {
                      _handleReport('Pertanyaan', widget.questionId, title);
                    } else if (value == 'delete') {
                      final confirm = await showDialog<bool>(
                        context: context,
                        builder: (context) => AlertDialog(
                          title: const Text('Hapus Pertanyaan'),
                          content: const Text(
                              'Apakah Anda yakin ingin menghapus pertanyaan ini?'),
                          actions: [
                            TextButton(
                              onPressed: () => Navigator.pop(context, false),
                              child: const Text('Batal'),
                            ),
                            TextButton(
                              onPressed: () => Navigator.pop(context, true),
                              style: TextButton.styleFrom(
                                  foregroundColor: Colors.red),
                              child: const Text('Hapus'),
                            ),
                          ],
                        ),
                      );

                      if (confirm == true) {
                        try {
                          await _api.deleteQuestion(
                              widget.questionId, _auth.token!);
                          if (mounted) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                  content: Text('Pertanyaan berhasil dihapus')),
                            );
                            Navigator.pop(context,
                                true); // Return true to refresh previous screen
                          }
                        } catch (e) {
                          if (mounted) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                  content: Text(e
                                      .toString()
                                      .replaceAll('Exception: ', ''))),
                            );
                          }
                        }
                      }
                    } else if (value == 'edit') {
                      final titleController =
                          TextEditingController(text: q['title']);
                      final contentController =
                          TextEditingController(text: q['content']);

                      final confirm = await showDialog<bool>(
                        context: context,
                        builder: (context) => AlertDialog(
                          title: const Text('Edit Pertanyaan'),
                          content: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              TextField(
                                controller: titleController,
                                decoration: const InputDecoration(
                                  labelText: 'Judul',
                                  border: OutlineInputBorder(),
                                ),
                              ),
                              const SizedBox(height: 12),
                              TextField(
                                controller: contentController,
                                decoration: const InputDecoration(
                                  labelText: 'Konten',
                                  border: OutlineInputBorder(),
                                ),
                                maxLines: 5,
                              ),
                            ],
                          ),
                          actions: [
                            TextButton(
                              onPressed: () => Navigator.pop(context, false),
                              child: const Text('Batal'),
                            ),
                            ElevatedButton(
                              onPressed: () => Navigator.pop(context, true),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: const Color(0xFF059669),
                              ),
                              child: const Text('Simpan',
                                  style: TextStyle(color: Colors.white)),
                            ),
                          ],
                        ),
                      );

                      if (confirm == true) {
                        try {
                          await _api.updateQuestion(
                            id: widget.questionId,
                            token: _auth.token!,
                            title: titleController.text,
                            content: contentController.text,
                          );
                          if (mounted) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                  content:
                                      Text('Pertanyaan berhasil diupdate')),
                            );
                            _loadQuestion(); // Refresh current page logic
                          }
                        } catch (e) {
                          if (mounted) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                  content: Text(e
                                      .toString()
                                      .replaceAll('Exception: ', ''))),
                            );
                          }
                        }
                      }
                    }
                  },
                  itemBuilder: (context) {
                    final isOwner = _auth.currentUser?.id == authorId;
                    if (isOwner) {
                      return [
                        const PopupMenuItem(
                          value: 'edit',
                          child: Row(
                            children: [
                              Icon(LucideIcons.edit,
                                  size: 16, color: Color(0xFF0F172A)),
                              SizedBox(width: 8),
                              Text('Edit'),
                            ],
                          ),
                        ),
                        const PopupMenuItem(
                          value: 'delete',
                          child: Row(
                            children: [
                              Icon(LucideIcons.trash2,
                                  size: 16, color: Colors.red),
                              SizedBox(width: 8),
                              Text('Hapus',
                                  style: TextStyle(color: Colors.red)),
                            ],
                          ),
                        ),
                      ];
                    } else {
                      return [
                        const PopupMenuItem(
                          value: 'report',
                          child: Row(
                            children: [
                              Icon(LucideIcons.flag,
                                  size: 16, color: Colors.red),
                              SizedBox(width: 8),
                              Text('Lapor Konten',
                                  style: TextStyle(color: Colors.red)),
                            ],
                          ),
                        ),
                      ];
                    }
                  },
                ),
            ],
          ),

          const SizedBox(height: 16),

          // Title
          Text(
            title,
            style: const TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: Color(0xFF0F172A),
              height: 1.3,
            ),
          ),

          const SizedBox(height: 12),

          // Tags
          if (tags.isNotEmpty)
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: tags.map<Widget>((tag) {
                return GestureDetector(
                  onTap: () {
                    final topicTag = tag_model.TopicTag(
                      id: tag['id']?.toString() ?? '',
                      name: tag['name'] ?? '',
                      slug: tag['slug'] ?? tag['name'] ?? '',
                      count: 0,
                    );
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => TagDetailScreen(tag: topicTag),
                      ),
                    );
                  },
                  child: Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                    decoration: BoxDecoration(
                      color: const Color(0xFFECFDF5),
                      borderRadius: BorderRadius.circular(6),
                      border: Border.all(color: const Color(0xFFD1FAE5)),
                    ),
                    child: Text(
                      tag['name'] ?? '',
                      style: const TextStyle(
                        color: Color(0xFF059669),
                        fontSize: 12,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                );
              }).toList(),
            ),

          const SizedBox(height: 16),

          // Content with @mentions and links
          RichContentText(
            content: _stripHtml(content),
            style: const TextStyle(
              fontSize: 15,
              color: Color(0xFF334155),
              height: 1.6,
            ),
            onMentionTap: (username) => _navigateToUserByUsername(username),
          ),

          // Images
          if (images.isNotEmpty) ...[
            const SizedBox(height: 16),
            ...images.map((img) {
              String imageUrl = img.toString();
              // Ensure proper URL format
              if (!imageUrl.startsWith('http')) {
                imageUrl = '${AppConfig.baseUrl}$imageUrl';
              }
              return Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(12),
                  child: GestureDetector(
                    onTap: () => _showFullImage(context, imageUrl),
                    child: Image.network(
                      imageUrl,
                      width: double.infinity,
                      fit: BoxFit.cover,
                      loadingBuilder: (context, child, loadingProgress) {
                        if (loadingProgress == null) return child;
                        return Container(
                          height: 200,
                          color: const Color(0xFFF1F5F9),
                          child: const Center(
                            child: CircularProgressIndicator(
                              color: Color(0xFF059669),
                              strokeWidth: 2,
                            ),
                          ),
                        );
                      },
                      errorBuilder: (_, __, ___) => Container(
                        height: 100,
                        color: const Color(0xFFF1F5F9),
                        child: const Center(
                          child: Icon(LucideIcons.imageOff,
                              color: Color(0xFFCBD5E1)),
                        ),
                      ),
                    ),
                  ),
                ),
              );
            }),
          ],

          const SizedBox(height: 16),
          const Divider(color: Color(0xFFE2E8F0)),
          const SizedBox(height: 12),

          // Vote and Stats Row
          Row(
            children: [
              VoteWidget(
                upvotes: upvotes,
                downvotes: downvotes,
                userVote: userVote,
                onUpvote: () => _handleVote('upvote'),
                onDownvote: () => _handleVote('downvote'),
              ),

              const SizedBox(width: 16),

              // Views
              Row(
                children: [
                  const Icon(LucideIcons.eye,
                      size: 16, color: Color(0xFF64748B)),
                  const SizedBox(width: 6),
                  Text('$views dilihat',
                      style: const TextStyle(
                          color: Color(0xFF64748B), fontSize: 13)),
                ],
              ),
            ],
          ),

          // Comments
          CommentSection(
            comments: q['comments'] as List? ?? [],
            type: 'question',
            parentId: widget.questionId,
            onPostComment: _handlePostComment,
          ),
        ],
      ),
    );
  }

  Widget _buildAnswersSection() {
    final answers = _question!['answers'] as List? ?? [];
    final answersCount = answers.length;
    final questionAuthorId = _question!['author_id']?.toString();
    final currentUserId = _auth.currentUser?.id;
    final isQuestionOwner =
        currentUserId != null && currentUserId == questionAuthorId;

    return Container(
      color: Colors.white,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                const Icon(LucideIcons.messageCircle,
                    size: 20, color: Color(0xFF059669)),
                const SizedBox(width: 8),
                Text(
                  '$answersCount Jawaban',
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF0F172A),
                  ),
                ),
              ],
            ),
          ),
          if (answers.isEmpty)
            const Padding(
              padding: EdgeInsets.all(32),
              child: Center(
                child: Column(
                  children: [
                    Icon(LucideIcons.messageSquare,
                        size: 48, color: Color(0xFFCBD5E1)),
                    SizedBox(height: 12),
                    Text(
                      'Belum ada jawaban',
                      style: TextStyle(fontSize: 14, color: Color(0xFF64748B)),
                    ),
                    SizedBox(height: 4),
                    Text(
                      'Jadilah yang pertama menjawab!',
                      style: TextStyle(fontSize: 12, color: Color(0xFF94A3B8)),
                    ),
                  ],
                ),
              ),
            )
          else
            ListView.separated(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: answers.length,
              separatorBuilder: (_, __) =>
                  const Divider(height: 1, color: Color(0xFFE2E8F0)),
              itemBuilder: (context, index) {
                return _buildAnswerItem(answers[index], isQuestionOwner);
              },
            ),
        ],
      ),
    );
  }

  Widget _buildAnswerItem(Map<String, dynamic> answer, bool isQuestionOwner) {
    final answerId = answer['id']?.toString() ?? '';
    final authorId = answer['author_id']?.toString() ?? '';
    final authorName = answer['author_name'] ?? 'Anonim';
    final authorAvatar = answer['author_avatar'] ?? '';
    final authorReputation = answer['author_reputation'] ?? 0;
    final authorIsVerified = answer['author_is_verified'] == true;
    final content = answer['content'] ?? '';
    final upvotes =
        int.tryParse(answer['upvotes_count']?.toString() ?? '0') ?? 0;
    final downvotes =
        int.tryParse(answer['downvotes_count']?.toString() ?? '0') ?? 0;
    final isAccepted = answer['is_accepted'] == true;
    final createdAt =
        DateTime.tryParse(answer['created_at'] ?? '') ?? DateTime.now();
    final userVote = answer['user_vote'];

    return Container(
      color: isAccepted
          ? const Color(0xFFECFDF5).withValues(alpha: 0.5)
          : Colors.white,
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Accepted badge
          if (isAccepted)
            Container(
              margin: const EdgeInsets.only(bottom: 12),
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
              decoration: BoxDecoration(
                color: const Color(0xFF059669),
                borderRadius: BorderRadius.circular(6),
              ),
              child: const Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(LucideIcons.checkCircle, size: 14, color: Colors.white),
                  SizedBox(width: 6),
                  Text(
                    'Jawaban Diterima',
                    style: TextStyle(
                        color: Colors.white,
                        fontSize: 12,
                        fontWeight: FontWeight.w600),
                  ),
                ],
              ),
            ),

          // Author row - Tappable
          Row(
            children: [
              Expanded(
                child: GestureDetector(
                  onTap: authorId.isNotEmpty
                      ? () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) =>
                                  ProfileScreen(userId: authorId),
                            ),
                          );
                        }
                      : null,
                  child: Row(
                    children: [
                      AvatarHelper.buildAvatarWithBadge(
                        avatarUrl: authorAvatar,
                        name: authorName,
                        reputation:
                            authorReputation is int ? authorReputation : 0,
                        isVerified: authorIsVerified,
                        radius: 16,
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Flexible(
                                  child: Text(
                                    authorName,
                                    style: const TextStyle(
                                        fontWeight: FontWeight.w600,
                                        fontSize: 13,
                                        color: Color(0xFF0F172A)),
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                                if (authorIsVerified)
                                  AvatarHelper.getVerifiedBadge(size: 14),
                              ],
                            ),
                            Text(
                              '$authorReputation reputasi • ${_formatTimeAgo(createdAt)}',
                              style: const TextStyle(
                                  fontSize: 11, color: Color(0xFF64748B)),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              // Accept button for question owner
              if (isQuestionOwner && !isAccepted)
                IconButton(
                  icon: const Icon(LucideIcons.checkCircle2,
                      size: 20, color: Color(0xFF059669)),
                  tooltip: 'Terima jawaban ini',
                  onPressed: () => _handleAcceptAnswer(answerId),
                ),

              // Menu for Answer (Edit/Delete for author, Report for others)
              if (_auth.isAuthenticated)
                PopupMenuButton<String>(
                  icon: const Icon(LucideIcons.moreHorizontal,
                      size: 18, color: Color(0xFF64748B)),
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(),
                  onSelected: (value) {
                    if (value == 'edit') {
                      _handleEditAnswer(answerId, content);
                    } else if (value == 'delete') {
                      _handleDeleteAnswer(answerId);
                    } else if (value == 'report') {
                      _handleReport('Jawaban', answerId, content);
                    }
                  },
                  itemBuilder: (context) {
                    final isAnswerAuthor =
                        _auth.currentUser?.id.toString() == authorId;

                    if (isAnswerAuthor) {
                      return [
                        const PopupMenuItem(
                          value: 'edit',
                          child: Row(
                            children: [
                              Icon(LucideIcons.edit,
                                  size: 16, color: Color(0xFF0F172A)),
                              SizedBox(width: 8),
                              Text('Edit'),
                            ],
                          ),
                        ),
                        const PopupMenuItem(
                          value: 'delete',
                          child: Row(
                            children: [
                              Icon(LucideIcons.trash2,
                                  size: 16, color: Colors.red),
                              SizedBox(width: 8),
                              Text('Hapus',
                                  style: TextStyle(color: Colors.red)),
                            ],
                          ),
                        ),
                      ];
                    } else {
                      return [
                        const PopupMenuItem(
                          value: 'report',
                          child: Row(
                            children: [
                              Icon(LucideIcons.flag,
                                  size: 16, color: Colors.red),
                              SizedBox(width: 8),
                              Text('Lapor Jawaban',
                                  style: TextStyle(color: Colors.red)),
                            ],
                          ),
                        ),
                      ];
                    }
                  },
                ),
            ],
          ),

          const SizedBox(height: 12),

          // Content
          // Content - Use RichContentText for mentions and links
          RichContentText(
            content: content,
            style: const TextStyle(
                fontSize: 14, color: Color(0xFF334155), height: 1.5),
            onMentionTap: (username) => _navigateToUserByUsername(username),
          ),

          const SizedBox(height: 12),

          // Vote row - compact horizontal version for answers
          VoteWidget(
            upvotes: upvotes,
            downvotes: downvotes,
            userVote: userVote,
            onUpvote: () => _handleVote('upvote', answerId: answerId),
            onDownvote: () => _handleVote('downvote', answerId: answerId),
            isCompact: true,
          ),

          // Answer Comments
          CommentSection(
            comments: answer['comments'] as List? ?? [],
            type: 'answer',
            parentId: answerId,
            onPostComment: _handlePostComment,
          ),
        ],
      ),
    );
  }

  Widget _buildMentionSuggestions() {
    return Positioned(
      left: 16,
      right: 16,
      bottom: 80, // Approximate height of input field to sit on top of
      child: Material(
        elevation: 8,
        borderRadius: BorderRadius.circular(12),
        color: Colors.white,
        child: Container(
          constraints: const BoxConstraints(maxHeight: 200),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: const Color(0xFFE2E8F0)),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: double.infinity,
                padding:
                    const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                decoration: const BoxDecoration(
                  color: Color(0xFFF8FAFC),
                  borderRadius: BorderRadius.vertical(top: Radius.circular(12)),
                ),
                child: Text(
                  _mentionQuery.isEmpty
                      ? 'Pilih pengguna'
                      : 'Hasil pencarian "$_mentionQuery"',
                  style: const TextStyle(
                    fontSize: 12,
                    color: Color(0xFF64748B),
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
              const Divider(height: 1),
              Flexible(
                child: ListView.separated(
                  shrinkWrap: true,
                  padding: EdgeInsets.zero,
                  itemCount: _mentionSuggestions.length,
                  separatorBuilder: (_, __) => const Divider(height: 1),
                  itemBuilder: (context, index) {
                    final user = _mentionSuggestions[index];
                    return InkWell(
                      onTap: () => _insertMention(user),
                      child: Padding(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 16, vertical: 12),
                        child: Row(
                          children: [
                            AvatarHelper.buildAvatarWithBadge(
                                avatarUrl: user.avatarUrl,
                                name: user.displayName,
                                reputation: user.reputationPoints,
                                isVerified: user.isVerified,
                                radius: 14),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    children: [
                                      Flexible(
                                        child: Text(
                                          user.displayName,
                                          style: const TextStyle(
                                            fontWeight: FontWeight.w600,
                                            fontSize: 14,
                                            color: Color(0xFF0F172A),
                                          ),
                                          overflow: TextOverflow.ellipsis,
                                        ),
                                      ),
                                      if (user.isVerified)
                                        Padding(
                                          padding:
                                              const EdgeInsets.only(left: 4),
                                          child: AvatarHelper.getVerifiedBadge(
                                              size: 14),
                                        ),
                                    ],
                                  ),
                                  if (user.username != null)
                                    Text(
                                      '@${user.username}',
                                      style: const TextStyle(
                                        fontSize: 12,
                                        color: Color(0xFF64748B),
                                      ),
                                    ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildAnswerInput() {
    // Use SafeArea to handle bottom padding instead of MediaQuery
    // This prevents unnecessary rebuilds when keyboard appears
    return SafeArea(
      top: false,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: const BoxDecoration(
          color: Colors.white,
          border: Border(top: BorderSide(color: Color(0xFFE2E8F0))),
        ),
        child: Row(
          children: [
            Expanded(
              child: TextField(
                controller: _answerController,
                decoration: InputDecoration(
                  hintText: 'Tulis jawaban Anda...',
                  hintStyle:
                      const TextStyle(color: Color(0xFF94A3B8), fontSize: 14),
                  filled: true,
                  fillColor: const Color(0xFFF8FAFC),
                  contentPadding:
                      const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: const BorderSide(color: Color(0xFFE2E8F0)),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: const BorderSide(color: Color(0xFFE2E8F0)),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: const BorderSide(color: Color(0xFF059669)),
                  ),
                ),
                maxLines: null,
                textInputAction: TextInputAction.send,
                onSubmitted: (_) => _handleSendAnswer(),
              ),
            ),
            const SizedBox(width: 12),
            Container(
              decoration: BoxDecoration(
                color: const Color(0xFF059669),
                borderRadius: BorderRadius.circular(12),
              ),
              child: IconButton(
                icon: _isSendingAnswer
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(
                            color: Colors.white, strokeWidth: 2),
                      )
                    : const Icon(LucideIcons.send,
                        color: Colors.white, size: 20),
                onPressed: _isSendingAnswer ? null : _handleSendAnswer,
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _formatTimeAgo(DateTime date) {
    final diff = DateTime.now().difference(date);
    if (diff.inDays > 30) return '${(diff.inDays / 30).floor()} bulan lalu';
    if (diff.inDays > 0) return '${diff.inDays} hari lalu';
    if (diff.inHours > 0) return '${diff.inHours} jam lalu';
    if (diff.inMinutes > 0) return '${diff.inMinutes} menit lalu';
    return 'Baru saja';
  }

  String _stripHtml(String html) {
    return html
        .replaceAll(RegExp(r'<[^>]*>'), '')
        .replaceAll('&nbsp;', ' ')
        .trim();
  }
}
