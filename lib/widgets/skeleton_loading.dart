import 'package:flutter/material.dart';

/// A shimmer/skeleton loading placeholder widget for better UX
class SkeletonLoading extends StatefulWidget {
  final double width;
  final double height;
  final double borderRadius;

  const SkeletonLoading({
    super.key,
    this.width = double.infinity,
    this.height = 20,
    this.borderRadius = 8,
  });

  @override
  State<SkeletonLoading> createState() => _SkeletonLoadingState();
}

class _SkeletonLoadingState extends State<SkeletonLoading>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _animation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 1500),
      vsync: this,
    )..repeat();
    _animation = Tween<double>(begin: -2, end: 2).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _animation,
      builder: (context, child) {
        return Container(
          width: widget.width,
          height: widget.height,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(widget.borderRadius),
            gradient: LinearGradient(
              begin: Alignment(_animation.value - 1, 0),
              end: Alignment(_animation.value + 1, 0),
              colors: const [
                Color(0xFFE2E8F0),
                Color(0xFFF1F5F9),
                Color(0xFFE2E8F0),
              ],
            ),
          ),
        );
      },
    );
  }
}

/// Skeleton for a question card
class QuestionCardSkeleton extends StatelessWidget {
  const QuestionCardSkeleton({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Author row
          Row(
            children: [
              const SkeletonLoading(width: 40, height: 40, borderRadius: 20),
              const SizedBox(width: 12),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: const [
                  SkeletonLoading(width: 100, height: 14),
                  SizedBox(height: 4),
                  SkeletonLoading(width: 60, height: 10),
                ],
              ),
            ],
          ),
          const SizedBox(height: 12),
          // Title
          const SkeletonLoading(width: double.infinity, height: 18),
          const SizedBox(height: 8),
          // Content preview
          const SkeletonLoading(width: double.infinity, height: 14),
          const SizedBox(height: 4),
          const SkeletonLoading(width: 200, height: 14),
          const SizedBox(height: 12),
          // Tags
          Row(
            children: const [
              SkeletonLoading(width: 60, height: 24, borderRadius: 12),
              SizedBox(width: 8),
              SkeletonLoading(width: 50, height: 24, borderRadius: 12),
            ],
          ),
          const SizedBox(height: 12),
          // Stats row
          Row(
            children: const [
              SkeletonLoading(width: 40, height: 14),
              SizedBox(width: 16),
              SkeletonLoading(width: 40, height: 14),
              SizedBox(width: 16),
              SkeletonLoading(width: 40, height: 14),
            ],
          ),
        ],
      ),
    );
  }
}

/// Skeleton for profile header
class ProfileHeaderSkeleton extends StatelessWidget {
  const ProfileHeaderSkeleton({super.key});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        // Banner
        Container(
          height: 180,
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              colors: [Color(0xFF1E293B), Color(0xFF0F172A)],
              begin: Alignment.centerLeft,
              end: Alignment.centerRight,
            ),
          ),
        ),
        Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Avatar
              const SkeletonLoading(width: 80, height: 80, borderRadius: 16),
              const SizedBox(height: 16),
              // Name
              const SkeletonLoading(width: 180, height: 24),
              const SizedBox(height: 8),
              // Username
              const SkeletonLoading(width: 120, height: 14),
              const SizedBox(height: 16),
              // Stats row
              Row(
                children: const [
                  Expanded(
                      child: SkeletonLoading(height: 60, borderRadius: 12)),
                  SizedBox(width: 12),
                  Expanded(
                      child: SkeletonLoading(height: 60, borderRadius: 12)),
                  SizedBox(width: 12),
                  Expanded(
                      child: SkeletonLoading(height: 60, borderRadius: 12)),
                ],
              ),
            ],
          ),
        ),
      ],
    );
  }
}

/// Skeleton for notification item
class NotificationItemSkeleton extends StatelessWidget {
  const NotificationItemSkeleton({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 20),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SkeletonLoading(width: 40, height: 40, borderRadius: 20),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: const [
                SkeletonLoading(width: double.infinity, height: 14),
                SizedBox(height: 8),
                SkeletonLoading(width: 200, height: 12),
                SizedBox(height: 4),
                SkeletonLoading(width: 150, height: 12),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// List of skeleton loading items
class SkeletonList extends StatelessWidget {
  final int itemCount;
  final Widget Function(BuildContext context, int index) itemBuilder;

  const SkeletonList({
    super.key,
    this.itemCount = 5,
    required this.itemBuilder,
  });

  @override
  Widget build(BuildContext context) {
    return ListView.builder(
      physics: const NeverScrollableScrollPhysics(),
      shrinkWrap: true,
      itemCount: itemCount,
      itemBuilder: itemBuilder,
    );
  }
}

/// Skeleton for question detail page
class QuestionDetailSkeleton extends StatelessWidget {
  const QuestionDetailSkeleton({super.key});

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      physics: const AlwaysScrollableScrollPhysics(),
      child: Column(
        children: [
          // Question section skeleton
          Container(
            color: Colors.white,
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Author row
                Row(
                  children: [
                    const SkeletonLoading(
                        width: 40, height: 40, borderRadius: 20),
                    const SizedBox(width: 12),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: const [
                        SkeletonLoading(width: 120, height: 14),
                        SizedBox(height: 4),
                        SkeletonLoading(width: 80, height: 10),
                      ],
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                // Title
                const SkeletonLoading(width: double.infinity, height: 24),
                const SizedBox(height: 8),
                const SkeletonLoading(width: 200, height: 24),
                const SizedBox(height: 16),
                // Content
                const SkeletonLoading(width: double.infinity, height: 14),
                const SizedBox(height: 6),
                const SkeletonLoading(width: double.infinity, height: 14),
                const SizedBox(height: 6),
                const SkeletonLoading(width: 250, height: 14),
                const SizedBox(height: 16),
                // Tags
                Row(
                  children: const [
                    SkeletonLoading(width: 70, height: 26, borderRadius: 13),
                    SizedBox(width: 8),
                    SkeletonLoading(width: 60, height: 26, borderRadius: 13),
                    SizedBox(width: 8),
                    SkeletonLoading(width: 50, height: 26, borderRadius: 13),
                  ],
                ),
                const SizedBox(height: 16),
                // Vote buttons
                Row(
                  children: const [
                    SkeletonLoading(width: 36, height: 36, borderRadius: 8),
                    SizedBox(width: 8),
                    SkeletonLoading(width: 30, height: 16),
                    SizedBox(width: 8),
                    SkeletonLoading(width: 36, height: 36, borderRadius: 8),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 8),
          // Answers section skeleton
          Container(
            color: Colors.white,
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SkeletonLoading(width: 100, height: 18),
                const SizedBox(height: 16),
                // Answer 1
                _buildAnswerSkeleton(),
                const Divider(height: 32),
                // Answer 2
                _buildAnswerSkeleton(),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAnswerSkeleton() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            const SkeletonLoading(width: 32, height: 32, borderRadius: 16),
            const SizedBox(width: 8),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: const [
                SkeletonLoading(width: 100, height: 12),
                SizedBox(height: 4),
                SkeletonLoading(width: 60, height: 10),
              ],
            ),
          ],
        ),
        const SizedBox(height: 12),
        const SkeletonLoading(width: double.infinity, height: 14),
        const SizedBox(height: 6),
        const SkeletonLoading(width: double.infinity, height: 14),
        const SizedBox(height: 6),
        const SkeletonLoading(width: 200, height: 14),
      ],
    );
  }
}

/// Skeleton for leaderboard item
class LeaderboardItemSkeleton extends StatelessWidget {
  const LeaderboardItemSkeleton({super.key});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
      child: Row(
        children: [
          // Rank
          const SkeletonLoading(width: 32, height: 24, borderRadius: 4),
          const SizedBox(width: 16),
          // Avatar
          const SkeletonLoading(width: 40, height: 40, borderRadius: 20),
          const SizedBox(width: 12),
          // Name and date
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: const [
                SkeletonLoading(width: 120, height: 14),
                SizedBox(height: 4),
                SkeletonLoading(width: 80, height: 10),
              ],
            ),
          ),
          // Reputation
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: const [
              SkeletonLoading(width: 50, height: 14),
              SizedBox(height: 4),
              SkeletonLoading(width: 60, height: 10),
            ],
          ),
        ],
      ),
    );
  }
}

/// Skeleton for community card
class CommunityCardSkeleton extends StatelessWidget {
  const CommunityCardSkeleton({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Avatar
          const SkeletonLoading(width: 48, height: 48, borderRadius: 8),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SkeletonLoading(width: 150, height: 16),
                const SizedBox(height: 4),
                const SkeletonLoading(width: double.infinity, height: 12),
                const SizedBox(height: 2),
                const SkeletonLoading(width: 200, height: 12),
                const SizedBox(height: 8),
                Row(
                  children: const [
                    SkeletonLoading(width: 50, height: 12),
                    SizedBox(width: 12),
                    SkeletonLoading(width: 40, height: 12),
                    Spacer(),
                    SkeletonLoading(width: 60, height: 20, borderRadius: 4),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// Skeleton for tag card
class TagCardSkeleton extends StatelessWidget {
  const TagCardSkeleton({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Padding(
            padding: const EdgeInsets.all(12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: const [
                SkeletonLoading(width: 80, height: 24, borderRadius: 6),
                SizedBox(height: 8),
                SkeletonLoading(width: double.infinity, height: 12),
                SizedBox(height: 4),
                SkeletonLoading(width: 100, height: 12),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
            decoration: const BoxDecoration(
              border: Border(top: BorderSide(color: Color(0xFFF1F5F9))),
            ),
            child: const SkeletonLoading(width: 60, height: 12),
          ),
        ],
      ),
    );
  }
}

/// Skeleton for user card
class UserCardSkeleton extends StatelessWidget {
  const UserCardSkeleton({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const SkeletonLoading(width: 64, height: 64, borderRadius: 32),
          const SizedBox(height: 12),
          const SkeletonLoading(width: 100, height: 14),
          const SizedBox(height: 4),
          const SkeletonLoading(width: 60, height: 18, borderRadius: 4),
          const SizedBox(height: 12),
          Container(
            margin: const EdgeInsets.symmetric(horizontal: 12),
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: const Color(0xFFF8FAFC),
              borderRadius: BorderRadius.circular(8),
            ),
            child: const SkeletonLoading(width: double.infinity, height: 20),
          ),
        ],
      ),
    );
  }
}

/// Skeleton for Community Detail Screen
class CommunityDetailSkeleton extends StatelessWidget {
  const CommunityDetailSkeleton({super.key});

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      child: Column(
        children: [
          // Header banner
          Container(
            height: 180,
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                colors: [Color(0xFFE2E8F0), Color(0xFFF1F5F9)],
              ),
            ),
          ),
          Transform.translate(
            offset: const Offset(0, -40),
            child: Column(
              children: [
                // Avatar and info card
                Container(
                  margin: const EdgeInsets.symmetric(horizontal: 16),
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: const Color(0xFFE2E8F0)),
                  ),
                  child: const Column(
                    children: [
                      SkeletonLoading(width: 80, height: 80, borderRadius: 20),
                      SizedBox(height: 16),
                      SkeletonLoading(width: 180, height: 24),
                      SizedBox(height: 12),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          SkeletonLoading(
                              width: 80, height: 24, borderRadius: 8),
                          SizedBox(width: 12),
                          SkeletonLoading(
                              width: 100, height: 24, borderRadius: 8),
                        ],
                      ),
                      SizedBox(height: 16),
                      SkeletonLoading(width: double.infinity, height: 60),
                      SizedBox(height: 16),
                      SkeletonLoading(
                          width: double.infinity, height: 48, borderRadius: 12),
                    ],
                  ),
                ),
                const SizedBox(height: 24),
                // Tabs skeleton
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: Row(
                    children: List.generate(
                        3,
                        (i) => Expanded(
                              child: Container(
                                margin: EdgeInsets.only(right: i < 2 ? 8 : 0),
                                child: const SkeletonLoading(
                                    height: 44, borderRadius: 12),
                              ),
                            )),
                  ),
                ),
                const SizedBox(height: 16),
                // Content skeleton
                for (int i = 0; i < 3; i++)
                  const Padding(
                    padding: EdgeInsets.symmetric(horizontal: 16, vertical: 6),
                    child: QuestionCardSkeleton(),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// Skeleton for Search Results
class SearchResultSkeleton extends StatelessWidget {
  const SearchResultSkeleton({super.key});

  @override
  Widget build(BuildContext context) {
    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: 6,
      itemBuilder: (context, index) => Padding(
        padding: const EdgeInsets.only(bottom: 12),
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: const Color(0xFFE2E8F0)),
          ),
          child: const Row(
            children: [
              SkeletonLoading(width: 40, height: 40, borderRadius: 20),
              SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    SkeletonLoading(width: 150, height: 16),
                    SizedBox(height: 6),
                    SkeletonLoading(width: 100, height: 12),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
