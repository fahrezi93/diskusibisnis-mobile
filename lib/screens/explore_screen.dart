import 'package:flutter/material.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'communities_screen.dart';
import 'tags_screen.dart';
import 'reputation_screen.dart';
import 'users_list_screen.dart';
import 'all_questions_screen.dart';
import 'unanswered_questions_screen.dart';
import 'saved_questions_screen.dart';
import 'help_screen.dart';
import '../services/auth_service.dart';
import 'about_screen.dart';
import 'about_community_screen.dart';
import 'privacy_policy_screen.dart';
import 'terms_screen.dart';

class ExploreScreen extends StatelessWidget {
  const ExploreScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.only(bottom: 24),
          child: Column(
            children: [
              // Header
              Container(
                margin: const EdgeInsets.fromLTRB(16, 8, 16, 32),
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [Color(0xFF059669), Color(0xFF0D9488)],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: [
                    BoxShadow(
                      color: const Color(0xFF059669).withValues(alpha: 0.3),
                      spreadRadius: 0,
                      blurRadius: 20,
                      offset: const Offset(0, 10),
                    ),
                  ],
                ),
                child: const Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Jelajahi Forum',
                      style: TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                    SizedBox(height: 8),
                    Text(
                      'Temukan komunitas, topik menarik, dan diskusi yang relevan untuk bisnis Anda.',
                      style: TextStyle(
                        fontSize: 14,
                        color: Color(0xFFECFDF5),
                        height: 1.5,
                      ),
                    ),
                  ],
                ),
              ),

              // Main Menu
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Padding(
                      padding: const EdgeInsets.only(left: 4, bottom: 16),
                      child: Row(
                        children: [
                          const Icon(LucideIcons.search,
                              size: 16, color: Color(0xFF0F172A)),
                          const SizedBox(width: 8),
                          Text(
                            'MENU UTAMA',
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.bold,
                              letterSpacing: 1.2,
                              color: const Color(0xFF0F172A)
                                  .withValues(alpha: 0.8),
                            ),
                          ),
                        ],
                      ),
                    ),
                    GridView.count(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      crossAxisCount: 2,
                      mainAxisSpacing: 12,
                      crossAxisSpacing: 12,
                      childAspectRatio: 1.3,
                      children: [
                        _buildMenuCard(
                          'Komunitas',
                          'Gabung grup diskusi',
                          LucideIcons.users,
                          const Color(0xFF2563EB),
                          const Color(0xFFEFF6FF),
                          () => Navigator.push(
                              context,
                              MaterialPageRoute(
                                  builder: (_) => const CommunitiesScreen())),
                        ),
                        _buildMenuCard(
                          'Topik / Tag',
                          'Cari kategori',
                          LucideIcons.hash,
                          const Color(0xFF9333EA),
                          const Color(0xFFFAF5FF),
                          () => Navigator.push(
                              context,
                              MaterialPageRoute(
                                  builder: (_) => const TagsScreen())),
                        ),
                        _buildMenuCard(
                          'Leaderboard',
                          'Member teraktif',
                          LucideIcons.trophy,
                          const Color(0xFFD97706),
                          const Color(0xFFFFFBEB),
                          () async {
                            final authService = AuthService();
                            await authService.init();
                            if (context.mounted) {
                              Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                      builder: (_) => ReputationScreen(
                                          userId: authService.currentUser?.id ??
                                              '')));
                            }
                          },
                        ),
                        _buildMenuCard(
                          'Pengguna',
                          'Cari member lain',
                          LucideIcons.user,
                          const Color(0xFFE11D48),
                          const Color(0xFFFFF1F2),
                          () => Navigator.push(
                              context,
                              MaterialPageRoute(
                                  builder: (_) => const UsersListScreen())),
                        ),
                      ],
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 32),

              // Questions Navigation
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Padding(
                      padding: const EdgeInsets.only(left: 4, bottom: 16),
                      child: Row(
                        children: [
                          const Icon(LucideIcons.helpCircle,
                              size: 16, color: Color(0xFF0F172A)),
                          const SizedBox(width: 8),
                          Text(
                            'DISKUSI',
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.bold,
                              letterSpacing: 1.2,
                              color: const Color(0xFF0F172A)
                                  .withValues(alpha: 0.8),
                            ),
                          ),
                        ],
                      ),
                    ),
                    _buildNavTile(
                      'Semua Pertanyaan',
                      'Lihat diskusi terbaru',
                      LucideIcons.messageCircle,
                      const Color(0xFF059669),
                      const Color(0xFFECFDF5),
                      () => Navigator.push(
                          context,
                          MaterialPageRoute(
                              builder: (_) => const AllQuestionsScreen())),
                    ),
                    const SizedBox(height: 12),
                    _buildNavTile(
                      'Belum Terjawab',
                      'Bantu jawab pertanyaan',
                      LucideIcons.helpCircle,
                      const Color(0xFFEA580C),
                      const Color(0xFFFFEDD5),
                      () => Navigator.push(
                          context,
                          MaterialPageRoute(
                              builder: (_) =>
                                  const UnansweredQuestionsScreen())),
                    ),
                    const SizedBox(height: 12),
                    _buildNavTile(
                      'Disimpan',
                      'Koleksi diskusi Anda',
                      LucideIcons.bookmark,
                      const Color(0xFF0EA5E9),
                      const Color(0xFFE0F2FE),
                      () => Navigator.push(
                          context,
                          MaterialPageRoute(
                              builder: (_) => const SavedQuestionsScreen())),
                    ),
                    const SizedBox(height: 12),
                    _buildNavTile(
                      'Bantuan / CS',
                      'Hubungi dukungan',
                      LucideIcons.mail,
                      const Color(0xFF475569),
                      const Color(0xFFF1F5F9),
                      () => Navigator.push(
                          context,
                          MaterialPageRoute(
                              builder: (_) => const HelpScreen())),
                    ),
                  ],
                ),
              ),

              // Footer Links
              const SizedBox(height: 40),
              Center(
                child: Wrap(
                  alignment: WrapAlignment.center,
                  spacing: 16,
                  runSpacing: 8,
                  children: [
                    _buildFooterLink(context, 'Tentang'),
                    _buildFooterLink(context, 'Tentang Komunitas'),
                    _buildFooterLink(context, 'Privasi'),
                    _buildFooterLink(context, 'Syarat & Ketentuan'),
                    _buildFooterLink(context, 'Bantuan'),
                  ],
                ),
              ),
              const SizedBox(height: 16),
              const Center(
                child: Text(
                  '© 2025 DiskusiBisnis. Platform Q&A untuk UMKM Indonesia.',
                  style: TextStyle(fontSize: 10, color: Color(0xFF94A3B8)),
                ),
              ),
              const SizedBox(height: 32),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildMenuCard(String title, String subtitle, IconData icon,
      Color color, Color bg, VoidCallback onTap) {
    return InkWell(
      onTap: onTap,
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: const Color(0xFFE2E8F0)),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.02),
              blurRadius: 4,
              offset: const Offset(0, 2),
            )
          ],
        ),
        child: Stack(
          children: [
            Positioned(
              top: 0,
              right: 0,
              child: Padding(
                padding: const EdgeInsets.all(12),
                child: Opacity(
                  opacity: 0.1,
                  child: Icon(icon, size: 60, color: const Color(0xFF059669)),
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: bg,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Icon(icon, size: 20, color: color),
                  ),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        style: const TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF1E293B),
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        subtitle,
                        style: const TextStyle(
                          fontSize: 10,
                          color: Color(0xFF64748B),
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildNavTile(String title, String subtitle, IconData icon,
      Color color, Color bg, VoidCallback onTap) {
    return InkWell(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: const Color(0xFFE2E8F0)),
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: bg,
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(icon, size: 20, color: color),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF0F172A),
                    ),
                  ),
                  Text(
                    subtitle,
                    style: const TextStyle(
                      fontSize: 11,
                      color: Color(0xFF64748B),
                    ),
                  ),
                ],
              ),
            ),
            const Icon(LucideIcons.chevronRight,
                size: 20, color: Color(0xFFCBD5E1)),
          ],
        ),
      ),
    );
  }

  Widget _buildFooterLink(BuildContext context, String text) {
    return GestureDetector(
      onTap: () {
        if (text == 'Tentang') {
          Navigator.push(
              context, MaterialPageRoute(builder: (_) => const AboutScreen()));
        } else if (text == 'Tentang Komunitas') {
          Navigator.push(context,
              MaterialPageRoute(builder: (_) => const AboutCommunityScreen()));
        } else if (text == 'Privasi') {
          Navigator.push(context,
              MaterialPageRoute(builder: (_) => const PrivacyPolicyScreen()));
        } else if (text == 'Syarat & Ketentuan') {
          Navigator.push(
              context, MaterialPageRoute(builder: (_) => const TermsScreen()));
        } else if (text == 'Bantuan') {
          Navigator.push(
              context, MaterialPageRoute(builder: (_) => const HelpScreen()));
        }
      },
      child: Padding(
        padding: const EdgeInsets.all(4),
        child: Text(
          text,
          style: const TextStyle(
            fontSize: 12,
            color: Color(0xFF64748B),
            fontWeight: FontWeight.w500,
          ),
        ),
      ),
    );
  }
}
