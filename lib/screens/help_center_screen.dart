import 'package:flutter/material.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:url_launcher/url_launcher.dart';
import 'privacy_policy_screen.dart';
import 'terms_screen.dart';
import 'create_ticket_screen.dart';

class HelpCenterScreen extends StatelessWidget {
  const HelpCenterScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: const Text('Pusat Bantuan'),
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(LucideIcons.arrowLeft, color: Colors.black),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Bagaimana kami bisa membantu Anda?',
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: Color(0xFF0F172A),
              ),
            ),
            const SizedBox(height: 8),
            const Text(
              'Temukan jawaban untuk pertanyaan umum atau hubungi tim kami',
              style: TextStyle(
                fontSize: 14,
                color: Color(0xFF64748B),
              ),
            ),
            const SizedBox(height: 32),

            // FAQ Section
            _buildSectionHeader('Pertanyaan Umum (FAQ)'),
            const SizedBox(height: 16),
            _buildFAQItem(
              'Bagaimana cara membuat pertanyaan?',
              'Klik tombol + di halaman utama, isi judul dan detail pertanyaan, tambahkan tag yang relevan, lalu klik "Posting Pertanyaan".',
            ),
            _buildFAQItem(
              'Bagaimana cara mendapatkan poin reputasi?',
              'Anda mendapat poin dengan berkontribusi: +10 jawaban diterima, +5 jawaban upvote, +2 pertanyaan upvote, -1 downvote.',
            ),
            _buildFAQItem(
              'Apa itu komunitas?',
              'Komunitas adalah grup diskusi berdasarkan topik tertentu. Anda bisa bergabung dan berbagi pengetahuan dengan member lain.',
            ),
            _buildFAQItem(
              'Bagaimana cara menghapus akun?',
              'Buka Pengaturan > scroll ke bawah > klik "Hapus Akun". Konfirmasi dengan password Anda. Perhatian: Data akan terhapus permanen!',
            ),

            const SizedBox(height: 32),

            // Contact Section
            _buildSectionHeader('Hubungi Kami'),
            const SizedBox(height: 16),
            _buildContactItem(
              context,
              LucideIcons.mail,
              'Email',
              'support@diskusibisnis.my.id',
              'mailto:support@diskusibisnis.my.id',
            ),
            _buildContactItem(
              context,
              LucideIcons.messageCircle,
              'WhatsApp',
              '+62 812-3456-7890',
              'https://wa.me/6281234567890',
            ),
            _buildContactItem(
              context,
              LucideIcons.globe,
              'Website',
              'diskusibisnis.my.id',
              'https://diskusibisnis.my.id',
            ),

            const SizedBox(height: 32),

            // Quick Links
            _buildSectionHeader('Tautan Berguna'),
            const SizedBox(height: 16),
            _buildLinkItem(context, 'Panduan Pengguna', LucideIcons.bookOpen),
            _buildLinkItem(context, 'Kebijakan Privasi', LucideIcons.shield),
            _buildLinkItem(context, 'Syarat & Ketentuan', LucideIcons.fileText),
            _buildLinkItem(context, 'Laporkan Masalah', LucideIcons.flag),
          ],
        ),
      ),
    );
  }

  Widget _buildSectionHeader(String title) {
    return Text(
      title,
      style: const TextStyle(
        fontSize: 12,
        fontWeight: FontWeight.bold,
        color: Color(0xFF0F172A),
        letterSpacing: 1.2,
      ),
    );
  }

  Widget _buildFAQItem(String question, String answer) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFFF8FAFC),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(
                LucideIcons.helpCircle,
                size: 20,
                color: Color(0xFF059669),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  question,
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: Color(0xFF0F172A),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            answer,
            style: const TextStyle(
              fontSize: 13,
              color: Color(0xFF64748B),
              height: 1.5,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildContactItem(BuildContext context, IconData icon, String label,
      String value, String url) {
    return GestureDetector(
      onTap: () async {
        final uri = Uri.parse(url);
        try {
          if (!await launchUrl(uri, mode: LaunchMode.externalApplication)) {
            if (context.mounted) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text('Tidak dapat membuka link: $url'),
                  backgroundColor: Colors.red,
                ),
              );
            }
          }
        } catch (e) {
          if (context.mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text('Error: $e'),
                backgroundColor: Colors.red,
              ),
            );
          }
        }
      },
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: const Color(0xFF059669).withOpacity(0.1),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(icon, size: 20, color: const Color(0xFF059669)),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    label,
                    style: const TextStyle(
                      fontSize: 12,
                      color: Color(0xFF64748B),
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    value,
                    style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                      color: Color(0xFF0F172A),
                    ),
                  ),
                ],
              ),
            ),
            const Icon(
              LucideIcons.externalLink,
              size: 16,
              color: Color(0xFF059669),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildLinkItem(BuildContext context, String title, IconData icon) {
    return GestureDetector(
      onTap: () {
        if (title == 'Kebijakan Privasi') {
          Navigator.push(
            context,
            MaterialPageRoute(
                builder: (context) => const PrivacyPolicyScreen()),
          );
        } else if (title == 'Syarat & Ketentuan') {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => const TermsScreen()),
          );
        } else if (title == 'Panduan Pengguna') {
          _showGuideDialog(context);
        } else if (title == 'Laporkan Masalah') {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => const CreateTicketScreen()),
          );
        }
      },
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: const Color(0xFFE2E8F0)),
        ),
        child: Row(
          children: [
            Icon(icon, size: 20, color: const Color(0xFF475569)),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                title,
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                  color: Color(0xFF0F172A),
                ),
              ),
            ),
            const Icon(
              LucideIcons.chevronRight,
              size: 20,
              color: Color(0xFFCBD5E1),
            ),
          ],
        ),
      ),
    );
  }

  void _showGuideDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Row(
          children: [
            Icon(LucideIcons.bookOpen, color: Color(0xFF059669)),
            SizedBox(width: 12),
            Text('Panduan Pengguna'),
          ],
        ),
        content: const SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                '1. Memulai DiskusiBisnis',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              SizedBox(height: 8),
              Text(
                '• Buat akun dengan email atau Google\n'
                '• Lengkapi profil Anda\n'
                '• Jelajahi komunitas dan bergabunglah',
              ),
              SizedBox(height: 16),
              Text(
                '2. Bertanya',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              SizedBox(height: 8),
              Text(
                '• Tap tombol + di halaman utama\n'
                '• Tulis judul yang jelas\n'
                '• Jelaskan pertanyaan secara detail\n'
                '• Tambahkan tag yang relevan',
              ),
              SizedBox(height: 16),
              Text(
                '3. Menjawab',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              SizedBox(height: 8),
              Text(
                '• Klik pertanyaan yang ingin dijawab\n'
                '• Berikan jawaban yang membantu\n'
                '• Jawaban terbaik akan diterima oleh penanya',
              ),
              SizedBox(height: 16),
              Text(
                '4. Reputasi',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              SizedBox(height: 8),
              Text(
                '• +7 poin saat membuat pertanyaan\n'
                '• +5 poin saat pertanyaan di-upvote\n'
                '• +3 poin saat jawaban di-upvote\n'
                '• +10 poin saat jawaban diterima',
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text(
              'Tutup',
              style: TextStyle(color: Color(0xFF059669)),
            ),
          ),
        ],
      ),
    );
  }
}
