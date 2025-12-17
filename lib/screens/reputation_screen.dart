import 'package:flutter/material.dart';
import 'package:lucide_icons/lucide_icons.dart';
import '../models/reputation_activity.dart';
import '../models/user_profile.dart'; // To show current user stats
import '../services/api_service.dart';

class ReputationScreen extends StatefulWidget {
  final String userId;

  const ReputationScreen({super.key, required this.userId});

  @override
  State<ReputationScreen> createState() => _ReputationScreenState();
}

class _ReputationScreenState extends State<ReputationScreen> {
  final ApiService _apiService = ApiService();
  List<ReputationActivity> _activities = [];
  bool _isLoading = true;
  int _userRank = 0;
  // Mock current user for display
  UserProfile? _currentUser;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    setState(() => _isLoading = true);
    try {
      final user = await _apiService.getProfile(widget.userId);
      final activities =
          await _apiService.getReputationActivities(widget.userId);
      final rank = await _apiService.getUserRank(widget.userId);

      setState(() {
        _currentUser = user;
        _activities = activities;
        _userRank = rank;
        _isLoading = false;
      });
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
      appBar: AppBar(
        title: const Text('Reputasi',
            style: TextStyle(
                color: Color(0xFF0F172A), fontWeight: FontWeight.bold)),
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(LucideIcons.arrowLeft, color: Color(0xFF0F172A)),
          onPressed: () => Navigator.pop(context),
        ),
        actions: [
          if (_currentUser != null)
            Container(
              margin: const EdgeInsets.only(right: 16),
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: const Color(0xFFECFDF5),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: const Color(0xFFD1FAE5)),
              ),
              child: Row(
                children: [
                  const Icon(LucideIcons.trophy,
                      size: 14, color: Color(0xFF059669)),
                  const SizedBox(width: 6),
                  Text(
                    '${_currentUser!.reputationPoints}',
                    style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF059669),
                        fontSize: 12),
                  ),
                ],
              ),
            ),
        ],
      ),
      body: _isLoading
          ? const Center(
              child: CircularProgressIndicator(color: Color(0xFF059669)))
          : SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Header
                  const Padding(
                    padding: EdgeInsets.only(bottom: 24),
                    child: Row(
                      children: [
                        Icon(LucideIcons.trophy,
                            size: 32, color: Color(0xFF059669)),
                        SizedBox(width: 16),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text('Reputasi Anda',
                                style: TextStyle(
                                    fontSize: 20,
                                    fontWeight: FontWeight.bold,
                                    color: Color(0xFF0F172A))),
                            Text('Statistik pencapaian dan kontribusi',
                                style: TextStyle(
                                    fontSize: 12, color: Color(0xFF64748B))),
                          ],
                        )
                      ],
                    ),
                  ),

                  // Stats Grid
                  Row(
                    children: [
                      Expanded(
                          child: _buildStatCard(
                              LucideIcons.trophy,
                              'Total Poin',
                              '${_currentUser?.reputationPoints ?? 0}')),
                      const SizedBox(width: 12),
                      Expanded(
                          child: _buildStatCard(
                              LucideIcons.trendingUp, 'Minggu Ini', '+15',
                              textColor: const Color(0xFF059669))),
                    ],
                  ),
                  const SizedBox(height: 12),
                  _buildRankCard(),

                  const SizedBox(height: 32),

                  // History & Sidebar
                  const Text('Riwayat Aktivitas',
                      style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF0F172A))),
                  const SizedBox(height: 12),

                  if (_activities.isEmpty)
                    const Padding(
                      padding: EdgeInsets.all(24),
                      child: Center(child: Text('Belum ada aktivitas')),
                    )
                  else
                    Container(
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: const Color(0xFFE2E8F0)),
                      ),
                      child: ListView.separated(
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        itemCount: _activities.length,
                        separatorBuilder: (_, __) =>
                            const Divider(height: 1, color: Color(0xFFF1F5F9)),
                        itemBuilder: (context, index) =>
                            _buildActivityItem(_activities[index]),
                      ),
                    ),

                  const SizedBox(height: 32),

                  // System Poin Info
                  Container(
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                          colors: [Color(0xFF064E3B), Color(0xFF065F46)]),
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Row(
                          children: [
                            Icon(LucideIcons.star, color: Color(0xFFFBBF24)),
                            SizedBox(width: 12),
                            Text('Sistem Poin',
                                style: TextStyle(
                                    color: Colors.white,
                                    fontWeight: FontWeight.bold,
                                    fontSize: 16)),
                          ],
                        ),
                        const SizedBox(height: 16),
                        _buildPointInfo('Jawaban Terbaik', '+15'),
                        _buildPointInfo('Dapat Upvote', '+10'),
                        _buildPointInfo('Buat Pertanyaan', '+5'),
                        _buildPointInfo('Dapat Downvote', '-2',
                            isNegative: true),
                      ],
                    ),
                  ),
                ],
              ),
            ),
    );
  }

  Widget _buildStatCard(IconData icon, String label, String value,
      {Color? textColor}) {
    return Container(
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
              Container(
                  padding: const EdgeInsets.all(6),
                  decoration: BoxDecoration(
                      color: const Color(0xFFECFDF5),
                      borderRadius: BorderRadius.circular(8)),
                  child: Icon(icon, size: 16, color: const Color(0xFF059669))),
              const SizedBox(width: 8),
              Text(label,
                  style:
                      const TextStyle(fontSize: 12, color: Color(0xFF64748B))),
            ],
          ),
          const SizedBox(height: 12),
          Text(value,
              style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: textColor ?? const Color(0xFF0F172A))),
        ],
      ),
    );
  }

  Widget _buildRankCard() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Row(
                children: [
                  Icon(LucideIcons.award, size: 16, color: Color(0xFF059669)),
                  SizedBox(width: 8),
                  Text('Peringkat Global',
                      style: TextStyle(fontSize: 12, color: Color(0xFF64748B))),
                ],
              ),
              const SizedBox(height: 8),
              Row(
                children: [
                  Text('#$_userRank',
                      style: const TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF0F172A))),
                  const SizedBox(width: 8),
                  Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 6, vertical: 2),
                      decoration: BoxDecoration(
                          color: const Color(0xFFECFDF5),
                          borderRadius: BorderRadius.circular(4)),
                      child: const Text('Top 1%',
                          style: TextStyle(
                              fontSize: 10,
                              fontWeight: FontWeight.bold,
                              color: Color(0xFF059669)))),
                ],
              ),
            ],
          ),
          // Decoration
          const Icon(LucideIcons.barChart2, size: 48, color: Color(0xFFF1F5F9)),
        ],
      ),
    );
  }

  Widget _buildActivityItem(ReputationActivity activity) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: const Color(0xFFECFDF5),
              shape: BoxShape.circle,
            ),
            child: Icon(_getIcon(activity.type),
                size: 18, color: const Color(0xFF059669)),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(
                        child: Text(activity.description,
                            style: const TextStyle(
                                fontWeight: FontWeight.w600,
                                fontSize: 14,
                                color: Color(0xFF0F172A)))),
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 8, vertical: 3),
                      decoration: BoxDecoration(
                        color: const Color(0xFFECFDF5),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text('+${activity.points}',
                          style: const TextStyle(
                              fontWeight: FontWeight.bold,
                              color: Color(0xFF047857),
                              fontSize: 11)),
                    ),
                  ],
                ),
                if (activity.questionTitle != null)
                  Padding(
                    padding: const EdgeInsets.only(top: 4),
                    child: Text(activity.questionTitle!,
                        style: const TextStyle(
                            color: Color(0xFF64748B), fontSize: 12),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis),
                  ),
                const SizedBox(height: 4),
                Text(_formatDate(activity.date),
                    style: const TextStyle(
                        fontSize: 11, color: Color(0xFF94A3B8))),
              ],
            ),
          ),
        ],
      ),
    );
  }

  IconData _getIcon(String type) {
    switch (type) {
      case 'question_upvote':
        return LucideIcons.thumbsUp;
      case 'answer_upvote':
        return LucideIcons.thumbsUp;
      case 'answer_accepted':
        return LucideIcons.checkCircle;
      case 'question_posted':
        return LucideIcons.messageSquare;
      default:
        return LucideIcons.star;
    }
  }

  String _formatDate(DateTime date) {
    return '${date.day}/${date.month}/${date.year}';
  }

  Widget _buildPointInfo(String label, String points,
      {bool isNegative = false}) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: const Color(0xFF065F46),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label,
              style: const TextStyle(color: Color(0xFFD1FAE5), fontSize: 13)),
          Text(points,
              style: TextStyle(
                  color: isNegative
                      ? const Color(0xFFF87171)
                      : const Color(0xFF34D399),
                  fontWeight: FontWeight.bold)),
        ],
      ),
    );
  }
}
