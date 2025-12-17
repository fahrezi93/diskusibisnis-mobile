import 'package:flutter/material.dart';
import 'package:lucide_icons/lucide_icons.dart';

class AboutCommunityScreen extends StatelessWidget {
  const AboutCommunityScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: const Text(
          'Tentang Komunitas',
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
            // Hero / Intro
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: const Color(0xFFF0FDFA),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: const Color(0xFFCCFBF1)),
              ),
              child: const Column(
                children: [
                  Icon(LucideIcons.users,
                      size: 48, color: Color(0xFF0D9488)),
                  SizedBox(height: 16),
                  Text(
                    'Komunitas Bisnis #1 di Indonesia',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF0F172A),
                    ),
                  ),
                  SizedBox(height: 8),
                  Text(
                    'Wadah bagi para pengusaha, UMKM, dan profesional untuk saling berbagi ilmu dan pengalaman.',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 14,
                      color: Color(0xFF334155),
                      height: 1.5,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 32),

            // Values
            const Text(
              'Nilai-Nilai Kami',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Color(0xFF0F172A),
              ),
            ),
            const SizedBox(height: 16),
            _buildValueItem(
              LucideIcons.heart,
              'Saling Membantu',
              'Kami percaya bahwa kesuksesan lebih mudah diraih jika kita saling mendukung satu sama lain.',
            ),
            _buildValueItem(
              LucideIcons.shieldCheck,
              'Integritas',
              'Kami menjunjung tinggi kejujuran dan etika bisnis dalam setiap interaksi.',
            ),
            _buildValueItem(
              LucideIcons.lightbulb,
              'Inovasi',
              'Kami mendorong ide-ide baru dan solusi kreatif untuk tantangan bisnis masa kini.',
            ),

            const SizedBox(height: 32),

            // Rules / Guidelines
            const Text(
              'Pedoman Komunitas',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Color(0xFF0F172A),
              ),
            ),
            const SizedBox(height: 16),
            _buildGuidelineItem(
              '1. Bersikap Sopan',
              'Hargai pendapat orang lain. Dilarang menggunakan kata-kata kasar atau menyerang pribadi.',
            ),
            _buildGuidelineItem(
              '2. No Spam',
              'Dilarang melakukan promosi berlebihan atau mengirim pesan spam yang mengganggu.',
            ),
            _buildGuidelineItem(
              '3. Tetap Relevan',
              'Pastikan diskusi dan pertanyaan Anda relevan dengan topik bisnis dan kewirausahaan.',
            ),
            _buildGuidelineItem(
              '4. Bagikan Sumber',
              'Jika mengutip data atau artikel, sertakan sumber yang valid untuk menjaga kredibilitas.',
            ),

            const SizedBox(height: 32),
            Center(
              child: ElevatedButton(
                onPressed: () {
                  // Navigate to community list or join page
                  Navigator.pop(context);
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF059669),
                  padding:
                      const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
                child: const Text('Bergabung dengan Diskusi',
                    style: TextStyle(color: Colors.white)),
              ),
            ),
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }

  Widget _buildValueItem(IconData icon, String title, String description) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 20),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: const Color(0xFFE2E8F0)),
            ),
            child: Icon(icon, size: 20, color: const Color(0xFF059669)),
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
                const SizedBox(height: 4),
                Text(
                  description,
                  style: const TextStyle(
                    fontSize: 13,
                    color: Color(0xFF64748B),
                    height: 1.4,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildGuidelineItem(String title, String description) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: const TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.w600,
              color: Color(0xFF334155),
            ),
          ),
          const SizedBox(height: 4),
          Text(
            description,
            style: const TextStyle(
              fontSize: 13,
              color: Color(0xFF64748B),
              height: 1.4,
            ),
          ),
        ],
      ),
    );
  }
}
