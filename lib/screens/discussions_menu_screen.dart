import 'package:flutter/material.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'all_questions_screen.dart';
import 'unanswered_questions_screen.dart';
import 'saved_questions_screen.dart';
import 'help_screen.dart';

class DiscussionsMenuScreen extends StatelessWidget {
  const DiscussionsMenuScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        title: const Text(
          'Diskusi',
          style: TextStyle(
            color: Color(0xFF0F172A),
            fontWeight: FontWeight.w700,
            fontSize: 18,
          ),
        ),
        centerTitle: false,
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          _buildMenuItem(
            context,
            icon: LucideIcons.messageCircle,
            iconColor: const Color(0xFF059669),
            iconBg: const Color(0xFFECFDF5),
            title: 'Semua Pertanyaan',
            subtitle: 'Lihat diskusi terbaru',
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                    builder: (context) => const AllQuestionsScreen()),
              );
            },
          ),
          const SizedBox(height: 12),
          _buildMenuItem(
            context,
            icon: LucideIcons.helpCircle,
            iconColor: const Color(0xFFF59E0B),
            iconBg: const Color(0xFFFEF3C7),
            title: 'Belum Terjawab',
            subtitle: 'Bantu jawab pertanyaan',
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                    builder: (context) => const UnansweredQuestionsScreen()),
              );
            },
          ),
          const SizedBox(height: 12),
          _buildMenuItem(
            context,
            icon: LucideIcons.bookmark,
            iconColor: const Color(0xFF3B82F6),
            iconBg: const Color(0xFFDCEFFE),
            title: 'Disimpan',
            subtitle: 'Koleksi diskusi Anda',
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                    builder: (context) => const SavedQuestionsScreen()),
              );
            },
          ),
          const SizedBox(height: 12),
          _buildMenuItem(
            context,
            icon: LucideIcons.mail,
            iconColor: const Color(0xFF64748B),
            iconBg: const Color(0xFFF1F5F9),
            title: 'Bantuan / CS',
            subtitle: 'Hubungi dukungan',
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const HelpScreen()),
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _buildMenuItem(
    BuildContext context, {
    required IconData icon,
    required Color iconColor,
    required Color iconBg,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: const Color(0xFFE2E8F0)),
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: iconBg,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(icon, color: iconColor, size: 24),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: const TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w600,
                      color: Color(0xFF0F172A),
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    subtitle,
                    style: TextStyle(
                      fontSize: 13,
                      color: Colors.grey[600],
                    ),
                  ),
                ],
              ),
            ),
            const Icon(LucideIcons.chevronRight,
                color: Color(0xFF94A3B8), size: 20),
          ],
        ),
      ),
    );
  }
}
