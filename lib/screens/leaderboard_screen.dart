import 'package:flutter/material.dart';
import 'package:lucide_icons/lucide_icons.dart';
import '../models/user_profile.dart';
import '../services/api_service.dart';
import '../utils/avatar_helper.dart';
import '../widgets/skeleton_loading.dart';
import 'profile_screen.dart';

class LeaderboardScreen extends StatefulWidget {
  const LeaderboardScreen({super.key});

  @override
  State<LeaderboardScreen> createState() => _LeaderboardScreenState();
}

class _LeaderboardScreenState extends State<LeaderboardScreen> {
  final ApiService _apiService = ApiService();
  List<UserProfile> _users = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    setState(() => _isLoading = true);
    try {
      // Fetch top users sorted by reputation
      final users = await _apiService.getUsers();
      if (mounted) {
        setState(() {
          _users = users.take(5).toList();
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      body: Stack(
        children: [
          // 1. Fixed Background Header
          Container(
            height: 320, // Fixed height for the banner
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                colors: [Color(0xFF059669), Color(0xFF047857)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
            ),
            child: Stack(
              children: [
                // Background Pattern (Circles)
                Positioned(
                  top: -20,
                  right: -20,
                  child: Container(
                    width: 150,
                    height: 150,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: Colors.white.withOpacity(0.1),
                    ),
                  ),
                ),
                Positioned(
                  bottom: 60,
                  left: 20,
                  child: Container(
                    width: 100,
                    height: 100,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: Colors.white.withOpacity(0.05),
                    ),
                  ),
                ),
                // Content
                SafeArea(
                  child: Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const SizedBox(height: 20),
                        Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: Colors.white.withOpacity(0.2),
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(LucideIcons.trophy,
                              size: 32, color: Color(0xFFFCD34D)),
                        ),
                        const SizedBox(height: 16),
                        const Text(
                          'Top Contributors',
                          style: TextStyle(
                            fontSize: 24,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 32),
                          child: Text(
                            'Apresiasi untuk anggota komunitas yang paling aktif berbagi pengetahuan.',
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              fontSize: 12,
                              color: const Color(0xFFD1FAE5),
                              height: 1.4,
                            ),
                          ),
                        ),
                        const SizedBox(height: 60), // Space for overlap
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),

          // 2. Scrollable Content
          CustomScrollView(
            slivers: [
              // Transparent AppBar for Back Button
              SliverAppBar(
                backgroundColor: Colors.transparent,
                elevation: 0,
                pinned: true,
                leading: IconButton(
                  icon: const Icon(LucideIcons.arrowLeft, color: Colors.white),
                  onPressed: () => Navigator.pop(context),
                ),
                expandedHeight: 280, // Matches banner visual height roughly
                flexibleSpace: const FlexibleSpaceBar(
                  background: SizedBox(), // Empty, letting bg show through
                ),
              ),

              // The List Container in Foreground
              SliverToBoxAdapter(
                child: Container(
                  constraints: BoxConstraints(
                    minHeight: MediaQuery.of(context).size.height - 100,
                  ),
                  decoration: const BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.only(
                      topLeft: Radius.circular(24),
                      topRight: Radius.circular(24),
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black12,
                        blurRadius: 10,
                        offset: Offset(0, -5),
                      ),
                    ],
                  ),
                  child: _isLoading
                      ? Column(
                          children: List.generate(
                            5,
                            (index) => const LeaderboardItemSkeleton(),
                          ),
                        )
                      : _users.isEmpty
                          ? const Padding(
                              padding: EdgeInsets.all(40.0),
                              child: Center(
                                child: Text(
                                  'Belum ada data kontributor',
                                  style: TextStyle(color: Color(0xFF64748B)),
                                ),
                              ),
                            )
                          : ListView.separated(
                              physics: const NeverScrollableScrollPhysics(),
                              shrinkWrap: true,
                              padding: const EdgeInsets.symmetric(vertical: 8),
                              itemCount: _users.length,
                              separatorBuilder: (_, __) => const Divider(
                                  height: 1, color: Color(0xFFF1F5F9)),
                              itemBuilder: (context, index) {
                                final user = _users[index];
                                return _buildUserItem(user, index);
                              },
                            ),
                ),
              ),

              const SliverPadding(padding: EdgeInsets.only(bottom: 32)),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildUserItem(UserProfile user, int index) {
    Color rankColor;
    double rankSize = 16;
    FontWeight rankWeight = FontWeight.bold;

    if (index == 0) {
      rankColor = const Color(0xFFEAB308); // Yellow-500
      rankSize = 20;
    } else if (index == 1) {
      rankColor = const Color(0xFF94A3B8); // Slate-400
      rankSize = 18;
    } else if (index == 2) {
      rankColor = const Color(0xFFB45309); // Amber-700
      rankSize = 18;
    } else {
      rankColor = const Color(0xFF94A3B8); // Slate-400
      rankWeight = FontWeight.normal;
    }

    return InkWell(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) =>
                ProfileScreen(userId: user.id, showBackButton: true),
          ),
        );
      },
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
        child: Row(
          children: [
            // Rank Number
            SizedBox(
              width: 32,
              child: Text(
                '${index + 1}',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: rankSize,
                  fontWeight: rankWeight,
                  color: rankColor,
                ),
              ),
            ),
            const SizedBox(width: 16),

            // Avatar
            AvatarHelper.buildAvatar(
              user.avatarUrl,
              user.displayName,
              radius: 20,
            ),
            const SizedBox(width: 12),

            // Name & Join Date
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Flexible(
                        child: Text(
                          user.displayName,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            fontWeight: FontWeight.w600,
                            fontSize: 14,
                            color: Color(0xFF0F172A),
                          ),
                        ),
                      ),
                      if (user.isVerified) ...[
                        const SizedBox(width: 4),
                        const Icon(LucideIcons.badgeCheck,
                            size: 14, color: Color(0xFF059669)),
                      ],
                    ],
                  ),
                  const SizedBox(height: 2),
                  Text(
                    'Bergabung ${user.createdAt.year}',
                    style: const TextStyle(
                      fontSize: 11,
                      color: Color(0xFF64748B),
                    ),
                  ),
                ],
              ),
            ),

            // Reputation Points
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Row(
                  children: [
                    const Icon(LucideIcons.award,
                        size: 14, color: Color(0xFF059669)),
                    const SizedBox(width: 4),
                    Text(
                      '${user.reputationPoints}',
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF059669),
                        fontSize: 14,
                      ),
                    ),
                  ],
                ),
                const Text(
                  'REPUTASI',
                  style: TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.w600,
                    color: Color(0xFF94A3B8),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
