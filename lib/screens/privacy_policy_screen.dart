import 'package:flutter/material.dart';
import 'package:lucide_icons/lucide_icons.dart';

class PrivacyPolicyScreen extends StatelessWidget {
  const PrivacyPolicyScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: const Text(
          'Kebijakan Privasi',
          style: TextStyle(
            color: Color(0xFF0F172A),
            fontWeight: FontWeight.w600,
            fontSize: 18,
          ),
        ),
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(LucideIcons.arrowLeft, color: Color(0xFF0F172A)),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Kebijakan Privasi DiskusiBisnis',
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: Color(0xFF0F172A),
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Terakhir diperbarui: ${DateTime.now().year}',
              style: const TextStyle(
                fontSize: 14,
                color: Color(0xFF64748B),
              ),
            ),
            const SizedBox(height: 32),
            _buildSection(
              '1. Pendahuluan',
              'Kami di DiskusiBisnis menghargai privasi Anda. Kebijakan ini menjelaskan bagaimana kami mengumpulkan, menggunakan, dan melindungi informasi pribadi Anda saat menggunanakan layanan kami.',
            ),
            _buildSection(
              '2. Informasi yang Kami Kumpulkan',
              'Kami mengumpulkan informasi yang Anda berikan secara langsung, seperti saat membuat akun, memposting konten, atau berkomunikasi dengan kami. Ini termasuk nama, alamat email, dan konten diskusi Anda.',
            ),
            _buildSection(
              '3. Penggunaan Informasi',
              'Kami menggunakan informasi Anda untuk menyediakan, memelihara, dan meningkatkan layanan kami, serta untuk berkomunikasi dengan Anda mengenai pembaruan, keamanan, dan dukungan.',
            ),
            _buildSection(
              '4. Berbagi Informasi',
              'Kami tidak menjual informasi pribadi Anda kepada pihak ketiga. Kami hanya membagikan informasi jika diperlukan untuk mematuhi hukum atau melindungi hak-hak kami.',
            ),
            _buildSection(
              '5. Keamanan Data',
              'Kami mengambil langkah-langkah yang wajar untuk melindungi informasi Anda dari akses, penggunaan, atau pengungkapan yang tidak sah.',
            ),
            _buildSection(
              '6. Hak Anda',
              'Anda memiliki hak untuk mengakses, mengoreksi, atau menghapus informasi pribadi Anda. Anda dapat mengelola pengaturan privasi melalui akun Anda atau menghubungi kami untuk bantuan.',
            ),
            _buildSection(
              '7. Hubungi Kami',
              'Jika Anda memiliki pertanyaan tentang kebijakan ini, silakan hubungi kami di hello@diskusibisnis.my.id.',
            ),
            const SizedBox(height: 32),
          ],
        ),
      ),
    );
  }

  Widget _buildSection(String title, String content) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: Color(0xFF0F172A),
            ),
          ),
          const SizedBox(height: 8),
          Text(
            content,
            style: const TextStyle(
              fontSize: 14,
              color: Color(0xFF475569),
              height: 1.6,
            ),
          ),
        ],
      ),
    );
  }
}
