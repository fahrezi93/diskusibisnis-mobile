import 'package:flutter/material.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:intl/intl.dart';
import '../models/user_profile.dart';
import '../models/question.dart';
import '../models/answer.dart';
import '../services/api_service.dart';
import '../widgets/question_card.dart';
import '../widgets/skeleton_loading.dart';
import '../services/auth_service.dart';
import '../utils/avatar_helper.dart';
import 'settings_screen.dart';
import 'question_detail_screen.dart';
import '../widgets/reputation_badge.dart';

class ProfileScreen extends StatefulWidget {
  final String? userId;
  final bool showBackButton;

  const ProfileScreen({super.key, this.userId, this.showBackButton = false});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen>
    with SingleTickerProviderStateMixin {
  final ApiService _apiService = ApiService();
  bool _isLoading = true;
  UserProfile? _profile;
  List<Question> _questions = [];
  List<Answer> _answers = [];
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _loadProfileData();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _loadProfileData({bool silent = false}) async {
    if (!silent) setState(() => _isLoading = true);
    try {
      String? userId = widget.userId;

      // If no specific userId is requested, use current logged-in user
      if (userId == null) {
        final authService = AuthService();
        await authService.init();
        if (authService.currentUser != null) {
          userId = authService.currentUser!.id;
        } else {
          // Fallback for safety
          if (mounted) setState(() => _isLoading = false);
          return;
        }
      }

      // At this point userId must be non-null if we didn't return above
      final validUserId = userId;

      // OPTIMIZATION: Fetch Profile, Questions, Answers in PARALLEL
      // Use useCache: false to get fresh data for profile stats
      final results = await Future.wait([
        _apiService.getProfile(validUserId, useCache: false),
        _apiService.getUserQuestions(validUserId),
        _apiService.getUserAnswers(validUserId).catchError((_) => <Answer>[]),
      ]);

      // Handle nullable profile
      final profileResult = results[0];
      if (profileResult == null) {
        if (mounted) setState(() => _isLoading = false);
        return;
      }

      final profile = profileResult as UserProfile;
      var userQuestions = results[1] as List<Question>;
      final userAnswers = results[2] as List<Answer>;

      // Debug log
      print('[ProfileScreen] Loaded profile: ${profile.displayName}');
      print('[ProfileScreen] Questions count: ${userQuestions.length}');
      print('[ProfileScreen] Answers count: ${userAnswers.length}');

      // PATCH: If question author is 'Unknown' or avatar is empty,
      // inject the profile data we just fetched since this is the user's own profile.
      final authorUser = User(
        id: profile.id,
        name: profile.displayName,
        avatar: profile.avatarUrl ?? '',
        reputation: profile.reputationPoints,
        isVerified: profile.isVerified,
      );

      userQuestions = userQuestions.map((q) {
        // Patch if name is Unknown OR avatar is empty (since this is user's own questions)
        if (q.author.name == 'Unknown' || q.author.avatar.isEmpty) {
          final plain = q.content
              .replaceAll(RegExp(r'<[^>]*>'), '')
              .replaceAll(RegExp(r'\s+'), ' ')
              .trim();

          return Question(
            id: q.id,
            title: q.title,
            content: q.content,
            plainContent: plain,
            firstImage: q.firstImage,
            author: authorUser,
            upvotesCount: q.upvotesCount,
            answersCount: q.answersCount,
            viewsCount: q.viewsCount,
            hasAcceptedAnswer: q.hasAcceptedAnswer,
            tags: q.tags,
            createdAt: q.createdAt,
          );
        }
        return q;
      }).toList();

      if (mounted) {
        setState(() {
          _profile = profile;
          _questions = userQuestions;
          _answers = userAnswers;
          _isLoading = false;
        });
      }
    } catch (e) {
      print('Error loading profile: $e');
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return Scaffold(
        backgroundColor: const Color(0xFFF8FAFC),
        body: SingleChildScrollView(
          child: Column(
            children: [
              const ProfileHeaderSkeleton(),
              const SizedBox(height: 16),
              // Skeleton question cards
              for (int i = 0; i < 3; i++) const QuestionCardSkeleton(),
            ],
          ),
        ),
      );
    }

    if (_profile == null) {
      return Scaffold(
        appBar: widget.showBackButton ? AppBar() : null,
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(LucideIcons.userX, size: 64, color: Colors.grey),
              const SizedBox(height: 16),
              const Text('Profil tidak ditemukan',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
              const SizedBox(height: 8),
              ElevatedButton(
                onPressed: _loadProfileData,
                child: const Text('Coba Lagi'),
              )
            ],
          ),
        ),
      );
    }

    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC), // Slate 50
      body: Stack(
        children: [
          // Main Scrollable Content
          SingleChildScrollView(
            child: Column(
              children: [
                // Header Area (Banner + Avatar + Basic Info)
                _buildProfileHeader(),

                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Reputation Progress Card
                      ReputationProgress(
                        reputationPoints: _profile!.reputationPoints,
                      ),

                      const SizedBox(height: 16),

                      // Stats Grid
                      Row(
                        children: [
                          _buildStatCard(
                              'Reputasi',
                              '${_profile!.reputationPoints}',
                              LucideIcons.award,
                              const Color(0xFFD97706),
                              const Color(0xFFFFFBEB)),
                          const SizedBox(width: 12),
                          _buildStatCard(
                              'Tanya',
                              '${_questions.length}',
                              LucideIcons.messageSquare,
                              const Color(0xFF059669),
                              const Color(0xFFECFDF5)),
                          const SizedBox(width: 12),
                          _buildStatCard(
                              'Jawab',
                              '${_answers.length}',
                              LucideIcons.checkCircle,
                              const Color(0xFF059669),
                              const Color(0xFFECFDF5)),
                        ],
                      ),

                      const SizedBox(height: 24),

                      // Tabs
                      Container(
                        height: 40,
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(999),
                          border: Border.all(color: const Color(0xFFE2E8F0)),
                        ),
                        child: TabBar(
                          controller: _tabController,
                          indicator: BoxDecoration(
                            color: const Color(0xFF059669),
                            borderRadius: BorderRadius.circular(999),
                          ),
                          labelColor: Colors.white,
                          unselectedLabelColor: const Color(0xFF64748B),
                          indicatorSize: TabBarIndicatorSize.tab,
                          dividerColor: Colors.transparent,
                          padding: const EdgeInsets.all(4),
                          tabs: [
                            Tab(text: 'Pertanyaan (${_questions.length})'),
                            Tab(text: 'Jawaban (${_answers.length})'),
                          ],
                        ),
                      ),

                      const SizedBox(height: 16),

                      // Tab Content
                      AnimatedBuilder(
                        animation: _tabController,
                        builder: (context, _) {
                          return _tabController.index == 0
                              ? _buildQuestionsList()
                              : _buildAnswersList();
                        },
                      ),

                      // Bottom Padding
                      const SizedBox(height: 40),
                    ],
                  ),
                ),
              ],
            ),
          ),

          // Custom Floating App Bar (Back Button / Settings)
          Positioned(
            top: 0,
            left: 0,
            right: 0,
            child: SafeArea(
              child: Padding(
                padding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    // Back Button (Only if showBackButton is true)
                    if (widget.showBackButton)
                      Container(
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.9),
                          shape: BoxShape.circle,
                          boxShadow: [
                            BoxShadow(
                                color: Colors.black.withOpacity(0.1),
                                blurRadius: 4),
                          ],
                        ),
                        child: IconButton(
                          icon: const Icon(LucideIcons.arrowLeft,
                              size: 20, color: Color(0xFF0F172A)),
                          onPressed: () => Navigator.pop(context),
                        ),
                      )
                    else
                      const SizedBox(
                          width: 40), // Placeholder to balance layout if needed

                    // Settings Button (Only if My Profile)
                    if (widget.userId == null)
                      Container(
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.9),
                          shape: BoxShape.circle,
                          boxShadow: [
                            BoxShadow(
                                color: Colors.black.withOpacity(0.1),
                                blurRadius: 4),
                          ],
                        ),
                        child: IconButton(
                          icon: const Icon(LucideIcons.settings,
                              size: 20, color: Color(0xFF0F172A)),
                          onPressed: () async {
                            await Navigator.push(
                                context,
                                MaterialPageRoute(
                                    builder: (context) =>
                                        const SettingsScreen()));
                            // Refresh profile after returning from settings
                            _loadProfileData();
                          },
                        ),
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

  Widget _buildProfileHeader() {
    return Stack(
      clipBehavior: Clip.none,
      children: [
        // 1. Banner Background
        Container(
          height: 180, // Banner height
          width: double.infinity,
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              colors: [Color(0xFF1E293B), Color(0xFF0F172A)],
              begin: Alignment.centerLeft,
              end: Alignment.centerRight,
            ),
          ),
        ),

        // 2. Content below banner requiring padding for the avatar overlap area
        Container(
          margin: const EdgeInsets.only(top: 180),
          color: Colors.transparent,
        ),

        // 3. Avatar & Info Wrapper
        // We position this starting from slightly above the bottom of the banner
        Padding(
          padding: const EdgeInsets.fromLTRB(
              16, 130, 16, 0), // 130 = 180 (banner) - 50 (overlap)
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Avatar Row
              Row(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Container(
                    padding: const EdgeInsets.all(4),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(16),
                      boxShadow: [
                        BoxShadow(
                            color: Colors.black.withOpacity(0.1), blurRadius: 4)
                      ],
                    ),
                    child: _buildAvatar(),
                  ),
                ],
              ),

              const SizedBox(height: 16),

              // Name & Badges
              Row(
                children: [
                  Text(
                    _profile!.displayName,
                    style: const TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF0F172A)),
                  ),
                  if (_profile!.isVerified)
                    AvatarHelper.getVerifiedBadge(size: 24),
                  const SizedBox(width: 8),
                  ReputationBadge(
                    reputationPoints: _profile!.reputationPoints,
                    showLabel: true,
                    compact: false,
                  ),
                ],
              ),
              if (_profile!.username != null)
                Text(
                  '@${_profile!.username}',
                  style:
                      const TextStyle(color: Color(0xFF64748B), fontSize: 14),
                ),

              const SizedBox(height: 12),

              // Meta (Join Date)
              Row(
                children: [
                  const Icon(LucideIcons.calendar,
                      size: 14, color: Color(0xFF64748B)),
                  const SizedBox(width: 4),
                  Text(
                    'Bergabung ${DateFormat('MMMM yyyy').format(_profile!.createdAt)}',
                    style:
                        const TextStyle(color: Color(0xFF64748B), fontSize: 12),
                  ),
                ],
              ),

              const SizedBox(height: 16),

              // Bio
              if (_profile!.bio != null && _profile!.bio!.isNotEmpty)
                Text(
                  _profile!.bio!,
                  style: const TextStyle(color: Color(0xFF475569), height: 1.5),
                ),

              const SizedBox(height: 24),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildStatCard(
      String label, String value, IconData icon, Color color, Color bg) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 8),
        decoration: BoxDecoration(
          color: bg,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: color.withValues(alpha: 0.2)),
        ),
        child: Column(
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(icon, size: 14, color: color),
                const SizedBox(width: 4),
                Text(
                  label.toUpperCase(),
                  style: TextStyle(
                      fontSize: 10, fontWeight: FontWeight.bold, color: color),
                ),
              ],
            ),
            const SizedBox(height: 4),
            Text(
              value,
              style: TextStyle(
                  fontSize: 18, fontWeight: FontWeight.bold, color: color),
            )
          ],
        ),
      ),
    );
  }

  Widget _buildQuestionsList() {
    if (_questions.isEmpty) {
      return _buildEmptyState(
          'Belum ada pertanyaan yang dibuat', LucideIcons.messageSquare);
    }
    return Column(
      children: _questions
          .map((q) => QuestionCard(
                question: q,
                onRefresh: () => _loadProfileData(silent: true),
              ))
          .toList(),
    );
  }

  Widget _buildAnswersList() {
    if (_answers.isEmpty) {
      return _buildEmptyState(
          'Belum ada jawaban yang diberikan', LucideIcons.checkCircle);
    }
    return Column(
      children: _answers
          .map((a) => InkWell(
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) =>
                        QuestionDetailScreen(questionId: a.questionId),
                  ),
                );
              },
              child: Container(
                margin: const EdgeInsets.only(bottom: 12),
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: const Color(0xFFE2E8F0)),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        const Text('Menjawab di ',
                            style: TextStyle(
                                color: Color(0xFF64748B), fontSize: 12)),
                        Expanded(
                          child: Text(
                            a.questionTitle,
                            style: const TextStyle(
                                color: Color(0xFF059669),
                                fontSize: 12,
                                fontWeight: FontWeight.w600),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Text(
                      a.content.replaceAll(RegExp(r'<[^>]*>'), ''),
                      maxLines: 3,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                          color: Color(0xFF334155), height: 1.5, fontSize: 14),
                    ),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        const Icon(LucideIcons.thumbsUp,
                            size: 14, color: Color(0xFF059669)),
                        const SizedBox(width: 4),
                        Text('${a.upvotesCount} upvotes',
                            style: const TextStyle(
                                fontSize: 12, fontWeight: FontWeight.w600)),
                        if (a.isAccepted) ...[
                          const SizedBox(width: 12),
                          Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 8, vertical: 2),
                            decoration: BoxDecoration(
                              color: const Color(0xFFECFDF5),
                              borderRadius: BorderRadius.circular(999),
                            ),
                            child: const Row(
                              children: [
                                Icon(LucideIcons.checkCircle,
                                    size: 12, color: Color(0xFF059669)),
                                SizedBox(width: 4),
                                Text('Diterima',
                                    style: TextStyle(
                                        fontSize: 10,
                                        color: Color(0xFF059669),
                                        fontWeight: FontWeight.bold)),
                              ],
                            ),
                          )
                        ],
                        const Spacer(),
                        Text(DateFormat('dd MMM yyyy').format(a.createdAt),
                            style: const TextStyle(
                                fontSize: 12, color: Color(0xFF94A3B8))),
                      ],
                    ),
                  ],
                ),
              )))
          .toList(),
    );
  }

  Widget _buildEmptyState(String message, IconData icon) {
    return Container(
      padding: const EdgeInsets.all(32),
      alignment: Alignment.center,
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(16),
            decoration: const BoxDecoration(
              color: Colors.white,
              shape: BoxShape.circle,
            ),
            child: Icon(icon, size: 32, color: const Color(0xFFCBD5E1)),
          ),
          const SizedBox(height: 16),
          Text(message, style: const TextStyle(color: Color(0xFF64748B))),
        ],
      ),
    );
  }

  Widget _buildAvatar() {
    final avatarUrl = _profile!.avatarUrl;
    final displayName = _profile!.displayName;

    // Use AvatarHelper for consistent avatar handling
    return AvatarHelper.buildSquareAvatarWithBadge(
      avatarUrl: avatarUrl,
      name: displayName,
      isVerified: _profile!.isVerified,
      size: 80,
      borderRadius: 12,
    );
  }
}
