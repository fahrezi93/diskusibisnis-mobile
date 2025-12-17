import 'package:flutter/material.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:flutter/services.dart';
import 'package:url_launcher/url_launcher.dart';
import 'create_ticket_screen.dart';

class HelpScreen extends StatelessWidget {
  const HelpScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: SingleChildScrollView(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Navigation
                GestureDetector(
                  onTap: () => Navigator.pop(context),
                  child: const Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        LucideIcons.arrowLeft,
                        size: 18,
                        color: Color(0xFF64748B),
                      ),
                      SizedBox(width: 8),
                      Text(
                        'Kembali',
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          color: Color(0xFF64748B),
                        ),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 32),

                // Header
                const Text(
                  'Pusat Bantuan',
                  style: TextStyle(
                    fontSize: 36,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF0F172A),
                    height: 1.2,
                  ),
                ),
                const SizedBox(height: 16),
                const Text(
                  'Temukan jawaban atas pertanyaan Anda atau hubungi tim dukungan kami jika Anda mengalami kendala.',
                  style: TextStyle(
                    fontSize: 18,
                    color: Color(0xFF64748B),
                    height: 1.6,
                  ),
                ),

                const SizedBox(height: 48),

                // FAQ Section
                const Text(
                  'Pertanyaan Umum (FAQ)',
                  style: TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF0F172A),
                  ),
                ),
                const SizedBox(height: 24),

                _buildFAQCard(
                  question: 'Bagaimana cara menaikkan Reputasi?',
                  answer:
                      'Reputasi didapatkan ketika pengguna lain memberikan upvote pada pertanyaan atau jawaban Anda. Jawaban yang diterima sebagai solusi juga memberikan poin reputasi yang besar.',
                ),
                const SizedBox(height: 20),

                _buildFAQCard(
                  question: 'Apakah platform ini gratis?',
                  answer:
                      'Ya, DiskusiBisnis sepenuhnya gratis untuk digunakan oleh semua pelaku UMKM. Kami berkomitmen untuk mendemokratisasi pengetahuan bisnis.',
                ),
                const SizedBox(height: 20),

                _buildFAQCard(
                  question: 'Bagaimana cara melaporkan konten spam?',
                  answer:
                      'Gunakan tombol "Laporkan" (ikon bendera) yang ada di setiap pertanyaan atau jawaban. Tim moderator kami akan meninjau laporan Anda dalam 24 jam.',
                ),

                const SizedBox(height: 48),

                // Contact Section
                Container(
                  padding: const EdgeInsets.all(24),
                  decoration: BoxDecoration(
                    color: const Color(0xFFECFDF5).withOpacity(0.5),
                    borderRadius: BorderRadius.circular(24),
                    border: Border.all(color: const Color(0xFFD1FAE5)),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Butuh bantuan lebih lanjut?',
                        style: TextStyle(
                          fontSize: 22,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF0F172A),
                        ),
                      ),
                      const SizedBox(height: 12),
                      const Text(
                        'Jika Anda tidak menemukan jawaban di atas, jangan ragu untuk menghubungi tim support kami secara langsung.',
                        style: TextStyle(
                          fontSize: 14,
                          color: Color(0xFF64748B),
                          height: 1.6,
                        ),
                      ),
                      const SizedBox(height: 24),

                      // Contact options
                      _buildContactRow(
                        icon: LucideIcons.mail,
                        text: 'support@diskusibisnis.my.id',
                        onTap: () =>
                            _launchEmail('support@diskusibisnis.my.id'),
                      ),
                      const SizedBox(height: 16),

                      _buildContactRow(
                        icon: LucideIcons.messageSquare,
                        text: 'Live Chat (Setiap hari, 09:00 - 21:00)',
                        onTap: () {
                          // Could open WhatsApp or live chat
                        },
                      ),

                      const SizedBox(height: 24),

                      // Contact button
                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton(
                          onPressed: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) =>
                                    const CreateTicketScreen(),
                              ),
                            );
                          },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFF059669),
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(vertical: 16),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                            elevation: 0,
                            shadowColor:
                                const Color(0xFF059669).withOpacity(0.2),
                          ),
                          child: const Text(
                            'Buat Tiket Bantuan',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 32),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildFAQCard({required String question, required String answer}) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            question,
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w700,
              color: Color(0xFF0F172A),
            ),
          ),
          const SizedBox(height: 10),
          Text(
            answer,
            style: const TextStyle(
              fontSize: 14,
              color: Color(0xFF64748B),
              height: 1.6,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildContactRow({
    required IconData icon,
    required String text,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Row(
        children: [
          Icon(icon, size: 20, color: const Color(0xFF059669)),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              text,
              style: const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: Color(0xFF334155),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _launchEmail(String email) async {
    final Uri emailUri = Uri(
      scheme: 'mailto',
      path: email,
      query: 'subject=Bantuan DiskusiBisnis',
    );
    
    if (await canLaunchUrl(emailUri)) {
      await launchUrl(emailUri);
    } else {
      // Fallback: copy to clipboard
      await Clipboard.setData(ClipboardData(text: email));
    }
  }
}
