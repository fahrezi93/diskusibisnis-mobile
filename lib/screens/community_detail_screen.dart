import 'package:flutter/material.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../services/api_service.dart';
import '../services/auth_service.dart';
import '../utils/avatar_helper.dart';

import '../widgets/skeleton_loading.dart';
import 'edit_community_screen.dart';
import '../models/question.dart';
import '../widgets/question_card.dart';
import 'profile_screen.dart';

class CommunityDetailScreen extends StatefulWidget {
  final String slug;

  const CommunityDetailScreen({super.key, required this.slug});

  @override
  State<CommunityDetailScreen> createState() => _CommunityDetailScreenState();
}

class _CommunityDetailScreenState extends State<CommunityDetailScreen> {
  final ApiService _api = ApiService();
  final AuthService _auth = AuthService();

  Map<String, dynamic>? _community;
  List<dynamic> _members = [];
  List<Question> _questions = [];
  bool _isLoading = true;
  bool _isJoining = false;

  String _activeTab = 'questions'; // questions, overview, members

  @override
  void initState() {
    super.initState();
    _auth.init();
    _loadData();
  }

  Future<void> _loadData() async {
    setState(() => _isLoading = true);
    await Future.wait([
      _fetchCommunity(),
      _fetchMembers(),
      _fetchQuestions(),
    ]);
    setState(() => _isLoading = false);
  }

  Future<void> _fetchCommunity() async {
    try {
      final community =
          await _api.getCommunity(widget.slug, token: _auth.token);
      if (mounted && community != null) {
        setState(() {
          _community = {
            'name': community.name,
            'slug': community.slug,
            'description': community.description,
            'category': community.category,
            'location': community.location,
            'created_at': community.createdAt.toString(),
            'created_by': community.createdBy,
            'members_count': community.memberCount,
            'is_member': community.isMember ?? false,
            'user_role': community.userRole,
            'avatar_url': community.avatarUrl,
          };
        });
      }
    } catch (e) {
      print('Error fetching community: $e');
    }
  }

  Future<void> _fetchMembers() async {
    try {
      final members = await _api.getCommunityMembers(widget.slug);
      setState(() {
        _members = members;
        if (_community != null) {
          // SYNC METADATA: Update count and is_member status from the definitive list
          _community!['members_count'] = members.length;

          if (_auth.currentUser != null) {
            final isUserMember = members.any((m) {
              // Check various possible ID fields
              final id = m['id']?.toString() ??
                  m['user_id']?.toString() ??
                  m['user']?['id']?.toString();
              return id == _auth.currentUser!.id;
            });

            print('[CommunityDetail] Sync isMember: $isUserMember');
            if (isUserMember) {
              _community!['is_member'] = true;

              // Check if user is admin
              try {
                final memberData = members.firstWhere((m) {
                  final id = m['id']?.toString() ??
                      m['user_id']?.toString() ??
                      m['user']?['id']?.toString();
                  return id == _auth.currentUser!.id;
                });

                if (memberData['role'] == 'admin') {
                  _community!['user_role'] = 'admin';
                }
              } catch (_) {}
            }
          }
        }
      });
    } catch (e) {
      print('Error fetching members: $e');
    }
  }

  Future<void> _fetchQuestions() async {
    try {
      final questions = await _api.getCommunityQuestions(widget.slug);
      if (mounted) {
        setState(() {
          _questions = questions;
        });
      }
    } catch (e) {
      print('Error fetching questions: $e');
    }
  }

  Future<void> _handleJoinCommunity() async {
    if (!_auth.isAuthenticated) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Login diperlukan untuk bergabung')),
      );
      return;
    }

    if (_isJoining || _community?['is_member'] == true) return;

    setState(() => _isJoining = true);
    try {
      await _api.joinCommunity(widget.slug, _auth.token!);

      // FORCE UPDATE STATE
      setState(() {
        _community!['is_member'] = true;
        _community!['members_count'] = (_community!['members_count'] ?? 0) + 1;
      });

      // IMPORTANT: Reload all data to get updated status
      // await _loadData(); // DISABLED: Causes flicker/stale data race condition

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Berhasil bergabung dengan komunitas'),
            backgroundColor: Color(0xFF059669),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Gagal bergabung: ${e.toString()}')),
        );
      }
    } finally {
      if (mounted) setState(() => _isJoining = false);
    }
  }

  Future<void> _handleLeaveCommunity() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Keluar dari Komunitas'),
        content: const Text('Apakah Anda yakin ingin keluar?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Batal'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Keluar'),
          ),
        ],
      ),
    );

    if (confirmed != true) return;

    setState(() => _isJoining = true);
    try {
      await _api.leaveCommunity(widget.slug, _auth.token!);
      // Manual state update
      setState(() {
        _community!['is_member'] = false;
        if ((_community!['members_count'] ?? 0) > 0) {
          _community!['members_count'] = _community!['members_count'] - 1;
        }
      });
      // IMPORTANT: Reload all data to get updated status
      // await _loadData(); // DISABLED: Causes flicker/stale data race condition
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Berhasil keluar dari komunitas')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Gagal keluar: ${e.toString()}')),
        );
      }
    } finally {
      if (mounted) setState(() => _isJoining = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Scaffold(
        backgroundColor: Color(0xFFF8FAFC),
        body: SafeArea(child: CommunityDetailSkeleton()),
      );
    }

    if (_community == null) {
      return Scaffold(
        backgroundColor: const Color(0xFFF8FAFC),
        appBar: AppBar(
          backgroundColor: Colors.white,
          elevation: 0,
          leading: IconButton(
            icon: const Icon(LucideIcons.arrowLeft, color: Color(0xFF0F172A)),
            onPressed: () => Navigator.pop(context),
          ),
        ),
        body: const Center(
          child: Text('Komunitas tidak ditemukan'),
        ),
      );
    }

    final isMember = _community!['is_member'] == true;
    final userRole = _community!['user_role'];

    // DEBUG: Print state
    print(
        '[CommunityDetail] is_member: $isMember, user_role: $userRole, community: ${_community!['name']}');

    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      body: Stack(
        children: [
          // Main content
          CustomScrollView(
            slivers: [
              // App Bar with Banner
              SliverAppBar(
                expandedHeight: 180,
                pinned:
                    false, // FIXED: Unpinned to allow content overlap (z-order fix)
                backgroundColor: const Color(0xFF059669),
                leading: IconButton(
                  icon: const Icon(LucideIcons.arrowLeft, color: Colors.white),
                  onPressed: () => Navigator.pop(context),
                ),
                actions: [
                  // FIXED: Show edit button for admin OR creator
                  if (_auth.isAuthenticated &&
                      (userRole == 'admin' ||
                          _community!['created_by'] == _auth.currentUser?.id))
                    IconButton(
                      icon:
                          const Icon(LucideIcons.settings, color: Colors.white),
                      tooltip: 'Edit Komunitas',
                      onPressed: () async {
                        final result = await Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) =>
                                EditCommunityScreen(community: _community!),
                          ),
                        );

                        if (result == true) {
                          _loadData(); // Refresh data if updated
                        }
                      },
                    ),
                ],
                flexibleSpace: FlexibleSpaceBar(
                  background: Container(
                    decoration: const BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                        colors: [
                          Color(0xFF059669),
                          Color(0xFF10B981),
                          Color(0xFF0D9488),
                        ],
                      ),
                    ),
                  ),
                ),
              ),

              // Content
              SliverToBoxAdapter(
                child: Transform.translate(
                  offset: const Offset(0, -40), // Reduced offset
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Header Card
                      Container(
                        margin: const EdgeInsets.symmetric(horizontal: 16),
                        padding: const EdgeInsets.only(
                            top: 60,
                            left: 20,
                            right: 20,
                            bottom: 20), // Extra top padding for avatar
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(color: const Color(0xFFE2E8F0)),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.05),
                              blurRadius: 10,
                              offset: const Offset(0, 4),
                            ),
                          ],
                        ),
                        child: Column(
                          children: [
                            // Avatar - FIXED: Higher elevation
                            Material(
                              elevation: 8,
                              borderRadius: BorderRadius.circular(20),
                              child: Container(
                                width: 80,
                                height: 80,
                                decoration: BoxDecoration(
                                  color: const Color(0xFFECFDF5),
                                  borderRadius: BorderRadius.circular(20),
                                  border: Border.all(
                                    color: const Color(0xFFD1FAE5),
                                    width: 3,
                                  ),
                                ),
                                child: _community!['avatar_url'] != null
                                    ? ClipRRect(
                                        borderRadius: BorderRadius.circular(17),
                                        child: CachedNetworkImage(
                                          imageUrl: _community!['avatar_url'],
                                          width: 80,
                                          height: 80,
                                          fit: BoxFit.cover,
                                          placeholder: (context, url) =>
                                              const Center(
                                            child: SizedBox(
                                              width: 20,
                                              height: 20,
                                              child: CircularProgressIndicator(
                                                strokeWidth: 2,
                                                color: Color(0xFF059669),
                                              ),
                                            ),
                                          ),
                                          errorWidget: (context, url, error) =>
                                              Center(
                                            child: Text(
                                              _community!['name'][0]
                                                  .toUpperCase(),
                                              style: const TextStyle(
                                                fontSize: 32,
                                                fontWeight: FontWeight.bold,
                                                color: Color(0xFF059669),
                                              ),
                                            ),
                                          ),
                                        ),
                                      )
                                    : Center(
                                        child: Text(
                                          _community!['name'][0].toUpperCase(),
                                          style: const TextStyle(
                                            fontSize: 32,
                                            fontWeight: FontWeight.bold,
                                            color: Color(0xFF059669),
                                          ),
                                        ),
                                      ),
                              ),
                            ),

                            const SizedBox(height: 16),

                            // Name
                            Text(
                              _community!['name'],
                              style: const TextStyle(
                                fontSize: 24,
                                fontWeight: FontWeight.bold,
                                color: Color(0xFF0F172A),
                              ),
                              textAlign: TextAlign.center,
                            ),

                            const SizedBox(height: 8),

                            // Meta Info
                            Wrap(
                              alignment: WrapAlignment.center,
                              spacing: 12,
                              runSpacing: 8,
                              children: [
                                _buildMetaChip(
                                  LucideIcons.tag,
                                  _community!['category'],
                                ),
                                if (_community!['location'] != null)
                                  _buildMetaChip(
                                    LucideIcons.mapPin,
                                    _community!['location'],
                                  ),
                                _buildMetaChip(
                                  LucideIcons.users,
                                  '${_community!['members_count'] ?? 0} anggota',
                                ),
                              ],
                            ),

                            const SizedBox(height: 12),

                            // Description
                            Text(
                              _community!['description'],
                              style: const TextStyle(
                                fontSize: 14,
                                color: Color(0xFF64748B),
                                height: 1.5,
                              ),
                              textAlign: TextAlign.center,
                            ),

                            const SizedBox(height: 16),

                            // Action Button - FIXED: Show correct state
                            if (_auth.isAuthenticated) ...[
                              if (!isMember) ...[
                                SizedBox(
                                  width: double.infinity,
                                  child: ElevatedButton.icon(
                                    onPressed: _isJoining
                                        ? null
                                        : _handleJoinCommunity,
                                    icon: _isJoining
                                        ? const SizedBox(
                                            width: 16,
                                            height: 16,
                                            child: CircularProgressIndicator(
                                              strokeWidth: 2,
                                              color: Colors.white,
                                            ),
                                          )
                                        : const Icon(LucideIcons.userPlus,
                                            size: 18),
                                    label: Text(_isJoining
                                        ? 'Memproses...'
                                        : 'Bergabung'),
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: const Color(0xFF059669),
                                      foregroundColor: Colors.white,
                                      padding: const EdgeInsets.symmetric(
                                          vertical: 14),
                                      shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(12),
                                      ),
                                    ),
                                  ),
                                ),
                              ] else
                                Column(
                                  children: [
                                    Container(
                                      width: double.infinity,
                                      padding: const EdgeInsets.all(12),
                                      decoration: BoxDecoration(
                                        color: const Color(0xFFECFDF5),
                                        borderRadius: BorderRadius.circular(12),
                                        border: Border.all(
                                            color: const Color(0xFFD1FAE5)),
                                      ),
                                      child: Row(
                                        mainAxisAlignment:
                                            MainAxisAlignment.center,
                                        children: [
                                          const Icon(
                                            LucideIcons.checkCircle,
                                            size: 16,
                                            color: Color(0xFF059669),
                                          ),
                                          const SizedBox(width: 8),
                                          const Text(
                                            'Sudah Bergabung',
                                            style: TextStyle(
                                              color: Color(0xFF059669),
                                              fontWeight: FontWeight.w600,
                                            ),
                                          ),
                                          if (userRole == 'admin' ||
                                              _community!['created_by'] ==
                                                  _auth.currentUser?.id) ...[
                                            const SizedBox(width: 4),
                                            const Icon(
                                              LucideIcons.crown,
                                              size: 14,
                                              color: Color(0xFFF59E0B),
                                            ),
                                          ],
                                        ],
                                      ),
                                    ),
                                    const SizedBox(height: 8),
                                    TextButton(
                                      onPressed: _handleLeaveCommunity,
                                      child: const Text(
                                        'Keluar Komunitas',
                                        style: TextStyle(
                                          color: Colors.red,
                                          fontSize: 12,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                            ],
                          ],
                        ),
                      ),

                      const SizedBox(height: 24),

                      // Tabs
                      Container(
                        margin: const EdgeInsets.symmetric(horizontal: 16),
                        child: Row(
                          children: [
                            _buildTab('questions', 'Diskusi',
                                LucideIcons.messageSquare),
                            const SizedBox(width: 8),
                            _buildTab('overview', 'Tentang', LucideIcons.info),
                            const SizedBox(width: 8),
                            _buildTab('members', 'Anggota', LucideIcons.users),
                          ],
                        ),
                      ),

                      const SizedBox(height: 16),

                      // Tab Content
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 16),
                        child: _buildTabContent(),
                      ),

                      const SizedBox(height: 100),
                    ],
                  ),
                ),
              ),
            ], // End of CustomScrollView slivers
          ), // End of CustomScrollView
        ], // End of Stack children
      ), // End of Stack
    ); // End of Scaffold
  }

  Widget _buildMetaChip(IconData icon, String label) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: const Color(0xFFF8FAFC),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: const Color(0xFF64748B)),
          const SizedBox(width: 4),
          Text(
            label,
            style: const TextStyle(
              fontSize: 12,
              color: Color(0xFF475569),
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTab(String value, String label, IconData icon) {
    final isActive = _activeTab == value;
    return Expanded(
      child: GestureDetector(
        onTap: () => setState(() => _activeTab = value),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 12),
          decoration: BoxDecoration(
            color: isActive ? const Color(0xFF059669) : Colors.white,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color:
                  isActive ? const Color(0xFF059669) : const Color(0xFFE2E8F0),
            ),
            boxShadow: isActive
                ? [
                    BoxShadow(
                      color: const Color(0xFF059669).withOpacity(0.2),
                      blurRadius: 8,
                      offset: const Offset(0, 2),
                    ),
                  ]
                : null,
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                icon,
                size: 16,
                color: isActive ? Colors.white : const Color(0xFF64748B),
              ),
              const SizedBox(width: 6),
              Text(
                label,
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: isActive ? Colors.white : const Color(0xFF64748B),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTabContent() {
    switch (_activeTab) {
      case 'questions':
        return _buildQuestionsTab();
      case 'overview':
        return _buildOverviewTab();
      case 'members':
        return _buildMembersTab();
      default:
        return const SizedBox.shrink();
    }
  }

  Widget _buildQuestionsTab() {
    if (_questions.isEmpty) {
      return Container(
        width: double.infinity,
        padding: const EdgeInsets.all(40),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: const Color(0xFFE2E8F0)),
        ),
        child: Column(
          children: [
            Icon(
              LucideIcons.messageSquare,
              size: 48,
              color: Colors.grey[300],
            ),
            const SizedBox(height: 16),
            const Text(
              'Belum ada diskusi',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: Color(0xFF64748B),
              ),
            ),
            const SizedBox(height: 8),
            const Text(
              'Jadilah yang pertama memulai diskusi!',
              style: TextStyle(
                fontSize: 14,
                color: Color(0xFF94A3B8),
              ),
            ),
          ],
        ),
      );
    }

    return Column(
      children: _questions.map((question) {
        return Padding(
          padding: const EdgeInsets.only(bottom: 12),
          child: QuestionCard(question: question),
        );
      }).toList(),
    );
  }

  Widget _buildOverviewTab() {
    // FIXED: Always show overview with at least description
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Tentang Komunitas',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Color(0xFF0F172A),
            ),
          ),
          const SizedBox(height: 12),
          Text(
            _community!['description'] ?? 'Tidak ada deskripsi',
            style: const TextStyle(
              fontSize: 14,
              color: Color(0xFF64748B),
              height: 1.6,
            ),
          ),
          const SizedBox(height: 20),
          const Divider(color: Color(0xFFE2E8F0)),
          const SizedBox(height: 16),
          // Info Section
          _buildInfoRow(LucideIcons.tag, 'Kategori', _community!['category']),
          if (_community!['location'] != null) ...[
            const SizedBox(height: 12),
            _buildInfoRow(
                LucideIcons.mapPin, 'Lokasi', _community!['location']),
          ],
          const SizedBox(height: 12),
          _buildInfoRow(
              LucideIcons.users, 'Total Anggota', '${_members.length} orang'),
          const SizedBox(height: 12),
          _buildInfoRow(LucideIcons.messageSquare, 'Total Diskusi',
              '${_questions.length} pertanyaan'),
        ],
      ),
    );
  }

  Widget _buildInfoRow(IconData icon, String label, String value) {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: const Color(0xFFF8FAFC),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(icon, size: 16, color: const Color(0xFF059669)),
        ),
        const SizedBox(width: 12),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              label,
              style: const TextStyle(
                fontSize: 12,
                color: Color(0xFF94A3B8),
              ),
            ),
            const SizedBox(height: 2),
            Text(
              value,
              style: const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: Color(0xFF0F172A),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildMembersTab() {
    if (_members.isEmpty) {
      return Container(
        padding: const EdgeInsets.all(40),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: const Color(0xFFE2E8F0)),
        ),
        child: Column(
          children: [
            Icon(
              LucideIcons.users,
              size: 48,
              color: Colors.grey[300],
            ),
            const SizedBox(height: 16),
            const Text(
              'Belum ada anggota',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: Color(0xFF64748B),
              ),
            ),
          ],
        ),
      );
    }

    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        childAspectRatio: 1.2,
        crossAxisSpacing: 12,
        mainAxisSpacing: 12,
      ),
      itemCount: _members.length,
      itemBuilder: (context, index) {
        final member = _members[index];
        final role = member['role'] ?? 'member';

        // Extract user details robustly
        final userId = member['id']?.toString() ??
            member['user_id']?.toString() ??
            member['user']?['id']?.toString();

        final displayName = member['display_name'] ??
            member['user_name'] ??
            member['user']?['display_name'] ??
            'Anonim';

        final avatarUrl = member['avatar_url']?.toString() ??
            member['user']?['avatar_url']?.toString() ??
            '';

        // Try to get reputation and verification status if available
        final reputation = member['reputation_points'] ??
            member['user']?['reputation_points'] ??
            0;
        final isVerified = member['is_verified'] == true ||
            member['user']?['is_verified'] == true;

        return GestureDetector(
          onTap: userId != null
              ? () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => ProfileScreen(userId: userId),
                    ),
                  );
                }
              : null,
          child: Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: const Color(0xFFE2E8F0)),
            ),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              mainAxisSize: MainAxisSize.min,
              children: [
                // Avatar with Reputation Ring and Badge using Helper
                AvatarHelper.buildAvatarWithBadge(
                  avatarUrl: avatarUrl,
                  name: displayName,
                  reputation: reputation is int ? reputation : 0,
                  isVerified: isVerified,
                  radius: 20,
                ),

                const SizedBox(height: 6),

                Text(
                  displayName,
                  style: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: Color(0xFF0F172A),
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  textAlign: TextAlign.center,
                ),
                if (isVerified)
                  Padding(
                    padding: const EdgeInsets.only(top: 2),
                    child: AvatarHelper.getVerifiedBadge(size: 14),
                  ),
                const SizedBox(height: 2),

                // Role Badge
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      role == 'admin'
                          ? LucideIcons.crown
                          : role == 'moderator'
                              ? LucideIcons.settings
                              : LucideIcons.user,
                      size: 10,
                      color: role == 'admin'
                          ? const Color(0xFFF59E0B)
                          : const Color(0xFF64748B),
                    ),
                    const SizedBox(width: 3),
                    Text(
                      role == 'admin'
                          ? 'Admin'
                          : role == 'moderator'
                              ? 'Moderator'
                              : 'Member',
                      style: TextStyle(
                        fontSize: 10,
                        color: role == 'admin'
                            ? const Color(0xFFF59E0B)
                            : const Color(0xFF64748B),
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}
