import 'package:flutter/material.dart';
import 'package:lucide_icons/lucide_icons.dart';
import '../models/user_profile.dart';
import '../services/api_service.dart';
import '../utils/avatar_helper.dart';
import 'profile_screen.dart';

class UsersListScreen extends StatefulWidget {
  const UsersListScreen({super.key});

  @override
  State<UsersListScreen> createState() => _UsersListScreenState();
}

class _UsersListScreenState extends State<UsersListScreen> {
  final ApiService _apiService = ApiService();
  List<UserProfile> _users = [];
  List<UserProfile> _filteredUsers = []; // For local filtering if needed
  bool _isLoading = true;
  String _searchQuery = '';

  @override
  void initState() {
    super.initState();
    _loadUsers();
  }

  Future<void> _loadUsers() async {
    setState(() => _isLoading = true);
    try {
      final data = await _apiService.getUsers();
      setState(() {
        _users = data;
        _filterUsers();
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
    }
  }

  void _filterUsers() {
    setState(() {
      _filteredUsers = _users.where((u) {
        return u.displayName
                .toLowerCase()
                .contains(_searchQuery.toLowerCase()) ||
            (u.username?.toLowerCase().contains(_searchQuery.toLowerCase()) ??
                false);
      }).toList();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(
        title: const Text('Pengguna',
            style: TextStyle(
                color: Color(0xFF0F172A), fontWeight: FontWeight.bold)),
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(LucideIcons.arrowLeft, color: Color(0xFF0F172A)),
          onPressed: () => Navigator.pop(context),
        ),
        actions: [
          Center(
            child: Container(
              margin: const EdgeInsets.only(right: 16),
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              decoration: BoxDecoration(
                  color: const Color(0xFFF1F5F9),
                  borderRadius: BorderRadius.circular(20)),
              child: Text('${_users.length}',
                  style: const TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF64748B))),
            ),
          )
        ],
      ),
      body: _isLoading
          ? const Center(
              child: CircularProgressIndicator(color: Color(0xFF059669)))
          : Column(
              children: [
                // Search
                Container(
                  padding: const EdgeInsets.all(16),
                  color: const Color(0xFFF8FAFC),
                  child: TextField(
                    onChanged: (val) {
                      _searchQuery = val;
                      _filterUsers();
                    },
                    decoration: InputDecoration(
                      hintText: 'Cari pengguna...',
                      prefixIcon: const Icon(LucideIcons.search,
                          size: 20, color: Color(0xFF94A3B8)),
                      filled: true,
                      fillColor: Colors.white,
                      border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide:
                              const BorderSide(color: Color(0xFFE2E8F0))),
                      enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide:
                              const BorderSide(color: Color(0xFFE2E8F0))),
                      contentPadding: const EdgeInsets.symmetric(vertical: 0),
                    ),
                  ),
                ),

                // Grid
                Expanded(
                  child: _filteredUsers.isEmpty
                      ? const Center(child: Text('Pengguna tidak ditemukan'))
                      : GridView.builder(
                          padding: const EdgeInsets.all(16),
                          gridDelegate:
                              const SliverGridDelegateWithFixedCrossAxisCount(
                            crossAxisCount: 2,
                            childAspectRatio: 0.75,
                            crossAxisSpacing: 16,
                            mainAxisSpacing: 16,
                          ),
                          itemCount: _filteredUsers.length,
                          itemBuilder: (context, index) =>
                              _buildUserCard(_filteredUsers[index]),
                        ),
                ),
              ],
            ),
    );
  }

  Widget _buildUserCard(UserProfile user) {
    return GestureDetector(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) =>
                ProfileScreen(userId: user.id, showBackButton: true),
          ),
        );
      },
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: const Color(0xFFE2E8F0)),
          boxShadow: [
            BoxShadow(
              color: const Color(0xFF64748B).withOpacity(0.05),
              blurRadius: 8,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            AvatarHelper.buildAvatarWithBadge(
                avatarUrl: user.avatarUrl,
                name: user.displayName,
                reputation: user.reputationPoints,
                isVerified: user.isVerified,
                radius: 32),
            const SizedBox(height: 12),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Flexible(
                    child: Text(user.displayName,
                        style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            color: Color(0xFF0F172A)),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis)),
                if (user.isVerified)
                  Padding(
                    padding: const EdgeInsets.only(left: 4),
                    child: AvatarHelper.getVerifiedBadge(size: 14),
                  ),
              ],
            ),
            const SizedBox(height: 4),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
              decoration: BoxDecoration(
                  color: const Color(0xFFF1F5F9),
                  borderRadius: BorderRadius.circular(4)),
              child: const Text('Anggota',
                  style: TextStyle(fontSize: 10, color: Color(0xFF64748B))),
            ),
            const SizedBox(height: 12),
            Container(
              margin: const EdgeInsets.symmetric(horizontal: 12),
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: const Color(0xFFF8FAFC),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: const Color(0xFFF1F5F9)),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  _buildMiniStat('Reputasi', '${user.reputationPoints}',
                      LucideIcons.award),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMiniStat(String label, String value, IconData icon) {
    return Expanded(
      child: Column(
        children: [
          Text(label,
              style: const TextStyle(
                  fontSize: 10,
                  color: Color(0xFF94A3B8),
                  fontWeight: FontWeight.bold)),
          const SizedBox(height: 2),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, size: 12, color: const Color(0xFF059669)),
              const SizedBox(width: 4),
              Text(value,
                  style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF059669),
                      fontSize: 12)),
            ],
          ),
        ],
      ),
    );
  }
}
