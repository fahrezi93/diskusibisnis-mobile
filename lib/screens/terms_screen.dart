import 'package:flutter/material.dart';
import 'package:lucide_icons/lucide_icons.dart';

class TermsScreen extends StatelessWidget {
  const TermsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: const Text(
          'Syarat & Ketentuan',
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
              'Syarat Layanan',
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: Color(0xFF0F172A),
              ),
            ),
            const SizedBox(height: 8),
            const Text(
              'Selamat datang di DiskusiBisnis',
              style: TextStyle(
                fontSize: 16,
                color: Color(0xFF64748B),
              ),
            ),
            const SizedBox(height: 32),
            _buildSection(
              '1. Ketentuan Umum',
              'Dengan mengakses dan menggunakan layanan DiskusiBisnis, Anda menyetujui untuk terikat dengan syarat dan ketentuan ini. Jika Anda tidak setuju, mohon untuk tidak menggunakan layanan kami.',
            ),
            _buildSection(
              '2. Akun Pengguna',
              'Anda bertanggung jawab untuk menjaga kerahasiaan akun dan password Anda. Anda setuju untuk memberikan informasi yang akurat dan lengkap saat mendaftar.',
            ),
            _buildSection(
              '3. Konten Pengguna',
              'Anda bertanggung jawab penuh atas segala konten yang Anda posting. Konten tidak boleh mengandung unsur SARA, pornografi, ujaran kebencian, atau melanggar hak kekayaan intelektual orang lain.',
            ),
            _buildSection(
              '4. Pedoman Komunitas',
              'Kami mendorong diskusi yang sehat dan konstruktif. Harap bersikap hormat kepada sesama pengguna. Kami berhak menghapus konten atau memblokir akun yang melanggar pedoman komunitas.',
            ),
            _buildSection(
              '5. Hak Kekayaan Intelektual',
              'Konten yang dipublikasikan di DiskusiBisnis tetap menjadi milik pembuatnya, namun Anda memberikan kami lisensi non-eksklusif untuk menampilkan dan mendistribusikan konten tersebut di platform kami.',
            ),
            _buildSection(
              '6. Perubahan Layanan',
              'Kami berhak untuk mengubah atau menghentikan layanan sewaktu-waktu tanpa pemberitahuan sebelumnya. Kami tidak bertanggung jawab atas kerugian yang timbul akibat perubahan tersebut.',
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
