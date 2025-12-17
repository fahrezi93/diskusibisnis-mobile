import 'package:flutter/material.dart';
import 'package:lucide_icons/lucide_icons.dart';
import '../screens/ask_question_screen.dart';

class HeroSection extends StatelessWidget {
  final int totalQuestions;

  const HeroSection({super.key, this.totalQuestions = 0});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.all(16),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Color(0xFF059669),
            Color(0xFF10B981),
          ],
        ),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          // Badge
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.2),
              borderRadius: BorderRadius.circular(20),
            ),
            child: const Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(LucideIcons.sparkles, size: 14, color: Color(0xFFFDE047)),
                SizedBox(width: 6),
                Text(
                  'Komunitas UMKM',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 16),

          // Heading - removed fontFamily to avoid TextStyle interpolation error
          const Text(
            'Temukan Jawaban &\nBangun Bisnismu',
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: Colors.white,
              height: 1.2,
            ),
          ),

          const SizedBox(height: 12),

          // Subtext
          const Text(
            'Tanyakan masalahmu dan tumbuh bersama komunitas.',
            style: TextStyle(
              color: Color(0xFFECFDF5),
              fontSize: 14,
              height: 1.4,
            ),
          ),

          const SizedBox(height: 20),

          // Button
          ElevatedButton.icon(
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => const AskQuestionScreen(),
                ),
              );
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.white,
              foregroundColor: const Color(0xFF059669),
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              elevation: 0,
            ),
            icon: const Icon(LucideIcons.plus, size: 16),
            label: const Text(
              'Buat Pertanyaan',
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
            ),
          ),
        ],
      ),
    );
  }
}
