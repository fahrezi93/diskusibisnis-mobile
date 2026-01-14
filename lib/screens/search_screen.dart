import 'dart:async';
import 'package:flutter/material.dart';
import 'package:lucide_icons/lucide_icons.dart';
import '../services/api_service.dart';
import '../models/question.dart';
import '../models/user_profile.dart';
import '../models/tag.dart';
import '../widgets/question_card.dart';
import '../widgets/skeleton_loading.dart';
import 'profile_screen.dart';
import 'tag_detail_screen.dart';
import '../utils/avatar_helper.dart';

class SearchScreen extends StatefulWidget {
  const SearchScreen({super.key});

  @override
  State<SearchScreen> createState() => _SearchScreenState();
}

class _SearchScreenState extends State<SearchScreen>
    with SingleTickerProviderStateMixin {
  final TextEditingController _searchController = TextEditingController();
  final ApiService _api = ApiService();
  late TabController _tabController;
  Timer? _debounce;

  // State
  String _query = '';
  String _sort = 'newest';

  List<Question> _questions = [];
  bool _questionsLoading = false;

  List<UserProfile> _users = [];
  bool _usersLoading = false;

  List<TopicTag> _tags = [];
  bool _tagsLoading = false;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _tabController.addListener(_handleTabSelection);
  }

  void _handleTabSelection() {
    if (_tabController.indexIsChanging) {
      _performSearch();
    }
  }

  @override
  void dispose() {
    _debounce?.cancel();
    _searchController.dispose();
    _tabController.dispose();
    super.dispose();
  }

  void _onSearchChanged(String query) {
    if (_debounce?.isActive ?? false) _debounce!.cancel();
    _debounce = Timer(const Duration(milliseconds: 500), () {
      if (query != _query) {
        setState(() => _query = query);
        _performSearch();
      }
    });
  }

  void _performSearch() {
    if (_query.isEmpty) return;

    final index = _tabController.index;
    if (index == 0)
      _searchQuestions();
    else if (index == 1)
      _searchUsers();
    else if (index == 2) _searchTags();
  }

  Future<void> _searchQuestions({bool silent = false}) async {
    if (!silent) setState(() => _questionsLoading = true);
    try {
      final results = await _api.getQuestions(search: _query, sort: _sort);
      setState(() => _questions = results);
    } catch (e) {
      debugPrint('Error searching questions: $e');
    } finally {
      if (!silent) setState(() => _questionsLoading = false);
    }
  }

  Future<void> _searchUsers() async {
    setState(() => _usersLoading = true);
    try {
      final results = await _api.getUsers(search: _query);
      setState(() => _users = results);
    } catch (e) {
      debugPrint('Error searching users: $e');
    } finally {
      setState(() => _usersLoading = false);
    }
  }

  Future<void> _searchTags() async {
    setState(() => _tagsLoading = true);
    try {
      final results = await _api.getTags(search: _query);
      setState(() => _tags = results);
    } catch (e) {
      debugPrint('Error searching tags: $e');
    } finally {
      setState(() => _tagsLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(LucideIcons.arrowLeft, color: Colors.black),
          onPressed: () => Navigator.pop(context),
        ),
        title: TextField(
          controller: _searchController,
          autofocus: true,
          decoration: const InputDecoration(
            hintText: 'Cari diskusi, orang, atau topik...',
            border: InputBorder.none,
            hintStyle: TextStyle(color: Colors.grey),
          ),
          textInputAction: TextInputAction.search,
          onChanged: _onSearchChanged,
          onSubmitted: (value) {
            if (_debounce?.isActive ?? false) _debounce!.cancel();
            setState(() => _query = value);
            _performSearch();
          },
        ),
        bottom: TabBar(
          controller: _tabController,
          labelColor: const Color(0xFF059669),
          unselectedLabelColor: Colors.grey,
          indicatorColor: const Color(0xFF059669),
          tabs: const [
            Tab(text: 'Pertanyaan'),
            Tab(text: 'Pengguna'),
            Tab(text: 'Topik'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _buildQuestionsTab(),
          _buildUsersTab(),
          _buildTagsTab(),
        ],
      ),
    );
  }

  Widget _buildQuestionsTab() {
    return Column(
      children: [
        if (_query.isNotEmpty)
          Container(
            height: 50,
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: ListView(
              scrollDirection: Axis.horizontal,
              children: [
                _buildFilterChip('Terbaru', 'newest'),
                const SizedBox(width: 8),
                _buildFilterChip('Populer', 'popular'),
                const SizedBox(width: 8),
                _buildFilterChip('Tanpa Jawaban', 'unanswered'),
              ],
            ),
          ),
        Expanded(
          child: _buildQuestionsList(),
        ),
      ],
    );
  }

  Widget _buildQuestionsList() {
    if (_questionsLoading) {
      return ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: 5,
        itemBuilder: (context, index) => const Padding(
          padding: EdgeInsets.only(bottom: 12),
          child: QuestionCardSkeleton(),
        ),
      );
    }
    if (_query.isEmpty) {
      return const Center(
          child: Text('Ketik pencarian Anda',
              style: TextStyle(color: Colors.grey)));
    }
    if (_questions.isEmpty) {
      return const Center(
          child: Text('Tidak ada pertanyaan ditemukan',
              style: TextStyle(color: Colors.grey)));
    }
    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: _questions.length,
      itemBuilder: (context, index) {
        return Padding(
          padding: const EdgeInsets.only(bottom: 12),
          child: QuestionCard(
            question: _questions[index],
            onRefresh: () => _searchQuestions(silent: true),
          ),
        );
      },
    );
  }

  Widget _buildFilterChip(String label, String value) {
    final isSelected = _sort == value;
    return FilterChip(
      label: Text(label),
      selected: isSelected,
      onSelected: (selected) {
        if (selected) {
          setState(() {
            _sort = value;
          });
          _searchQuestions();
        }
      },
      backgroundColor: Colors.white,
      selectedColor: const Color(0xFFECFDF5),
      checkmarkColor: const Color(0xFF059669),
      labelStyle: TextStyle(
        color: isSelected ? const Color(0xFF059669) : const Color(0xFF64748B),
        fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
      ),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
        side: BorderSide(
          color: isSelected ? const Color(0xFF059669) : const Color(0xFFE2E8F0),
        ),
      ),
    );
  }

  Widget _buildUsersTab() {
    if (_usersLoading) {
      return const SearchResultSkeleton();
    }
    if (_query.isEmpty) {
      return const Center(
          child: Text('Ketik nama pengguna',
              style: TextStyle(color: Colors.grey)));
    }
    if (_users.isEmpty) {
      return const Center(
          child: Text('Pengguna tidak ditemukan',
              style: TextStyle(color: Colors.grey)));
    }
    return ListView.separated(
      padding: const EdgeInsets.all(16),
      itemCount: _users.length,
      separatorBuilder: (context, index) => const Divider(height: 1),
      itemBuilder: (context, index) {
        final user = _users[index];
        return ListTile(
          contentPadding: EdgeInsets.zero,
          leading: AvatarHelper.buildAvatarWithBadge(
            avatarUrl: user.avatarUrl,
            name: user.displayName,
            reputation: user.reputationPoints,
            isVerified: user.isVerified,
            radius: 20,
          ),
          title: Row(
            children: [
              Flexible(
                child: Text(user.displayName,
                    style: const TextStyle(fontWeight: FontWeight.w600)),
              ),
              if (user.isVerified) AvatarHelper.getVerifiedBadge(size: 16),
            ],
          ),
          subtitle:
              Text('@${user.username} • ${user.reputationPoints} reputasi'),
          onTap: () {
            Navigator.push(
                context,
                MaterialPageRoute(
                    builder: (context) => ProfileScreen(userId: user.id)));
          },
        );
      },
    );
  }

  Widget _buildTagsTab() {
    if (_tagsLoading) {
      return const SearchResultSkeleton();
    }
    if (_query.isEmpty) {
      return const Center(
          child:
              Text('Cari topik diskusi', style: TextStyle(color: Colors.grey)));
    }
    if (_tags.isEmpty) {
      return const Center(
          child: Text('Topik tidak ditemukan',
              style: TextStyle(color: Colors.grey)));
    }
    return ListView.separated(
      padding: const EdgeInsets.all(16),
      itemCount: _tags.length,
      separatorBuilder: (context, index) => const Divider(height: 1),
      itemBuilder: (context, index) {
        final tag = _tags[index];
        return ListTile(
          contentPadding: EdgeInsets.zero,
          leading: Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: const Color(0xFFECFDF5),
              borderRadius: BorderRadius.circular(8),
            ),
            child: const Icon(LucideIcons.hash,
                color: Color(0xFF059669), size: 16),
          ),
          title: Text(tag.name,
              style: const TextStyle(fontWeight: FontWeight.w600)),
          subtitle: Text(tag.description ?? 'Tidak ada deskripsi'),
          onTap: () {
            Navigator.push(
                context,
                MaterialPageRoute(
                    builder: (context) => TagDetailScreen(tag: tag)));
          },
        );
      },
    );
  }
}
