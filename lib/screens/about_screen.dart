import 'package:flutter/material.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'privacy_policy_screen.dart';
import 'terms_screen.dart';
import 'about_community_screen.dart';

class AboutScreen extends StatefulWidget {
  const AboutScreen({super.key});

  @override
  State<AboutScreen> createState() => _AboutScreenState();
}

class _AboutScreenState extends State<AboutScreen> {
  String _version = '1.0.0';
  String _buildNumber = '1';

  @override
  void initState() {
    super.initState();
    _loadPackageInfo();
  }

  Future<void> _loadPackageInfo() async {
    try {
      final packageInfo = await PackageInfo.fromPlatform();
      setState(() {
        _version = packageInfo.version;
        _buildNumber = packageInfo.buildNumber;
      });
    } catch (e) {
      // Use default values if package info fails
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: const Text('Tentang Aplikasi'),
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
          children: [
            // App Logo
            Container(
              width: 100,
              height: 100,
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [Color(0xFF059669), Color(0xFF10B981)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(24),
                boxShadow: [
                  BoxShadow(
                    color: const Color(0xFF059669).withOpacity(0.3),
                    blurRadius: 20,
                    offset: const Offset(0, 10),
                  ),
                ],
              ),
              child: const Icon(
                LucideIcons.messageSquare,
                size: 50,
                color: Colors.white,
              ),
            ),
            const SizedBox(height: 24),

            // App Name
            const Text(
              'DiskusiBisnis',
              style: TextStyle(
                fontSize: 28,
                fontWeight: FontWeight.bold,
                color: Color(0xFF0F172A),
              ),
            ),
            const SizedBox(height: 8),

            // Version
            Text(
              'Versi $_version (Build $_buildNumber)',
              style: const TextStyle(
                fontSize: 14,
                color: Color(0xFF64748B),
              ),
            ),
            const SizedBox(height: 4),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
              decoration: BoxDecoration(
                color: const Color(0xFFFEF3C7),
                borderRadius: BorderRadius.circular(20),
              ),
              child: const Text(
                'Beta',
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: Color(0xFFF59E0B),
                ),
              ),
            ),

            const SizedBox(height: 32),

            // Description
            const Text(
              'Platform tanya jawab dan diskusi bisnis untuk komunitas Indonesia',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 15,
                color: Color(0xFF475569),
                height: 1.6,
              ),
            ),

            const SizedBox(height: 40),

            // Features
            _buildFeatureItem(
              LucideIcons.messageCircle,
              'Tanya & Jawab',
              'Ajukan pertanyaan dan dapatkan jawaban dari komunitas',
            ),
            _buildFeatureItem(
              LucideIcons.users,
              'Komunitas',
              'Bergabung dengan komunitas sesuai minat Anda',
            ),
            _buildFeatureItem(
              LucideIcons.award,
              'Reputasi',
              'Dapatkan poin dan badge dengan berkontribusi',
            ),
            _buildFeatureItem(
              LucideIcons.bookmark,
              'Simpan',
              'Simpan pertanyaan favorit untuk dibaca nanti',
            ),

            const SizedBox(height: 40),

            // Footer Info
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: const Color(0xFFF8FAFC),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: const Color(0xFFE2E8F0)),
              ),
              child: Column(
                children: [
                  _buildInfoRow('Dibuat oleh', 'Tim DiskusiBisnis'),
                  const SizedBox(height: 12),
                  _buildInfoRow('Email', 'hello@diskusibisnis.my.id'),
                  const SizedBox(height: 12),
                  _buildInfoRow('Website', 'diskusibisnis.my.id'),
                  const SizedBox(height: 20),
                  const Divider(color: Color(0xFFE2E8F0)),
                  const SizedBox(height: 16),
                  const Text(
                    '© 2024 DiskusiBisnis. All rights reserved.',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 12,
                      color: Color(0xFF94A3B8),
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 24),

            // Links
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                _buildLinkButton('Tentang Komunitas'),
                const SizedBox(width: 8),
                Container(
                  width: 4,
                  height: 4,
                  decoration: const BoxDecoration(
                    color: Color(0xFFCBD5E1),
                    shape: BoxShape.circle,
                  ),
                ),
                const SizedBox(width: 8),
                _buildLinkButton('Kebijakan Privasi'),
                const SizedBox(width: 8),
                Container(
                  width: 4,
                  height: 4,
                  decoration: const BoxDecoration(
                    color: Color(0xFFCBD5E1),
                    shape: BoxShape.circle,
                  ),
                ),
                const SizedBox(width: 8),
                _buildLinkButton('Syarat Layanan'),
              ],
            ),

            const SizedBox(height: 40),
          ],
        ),
      ),
    );
  }

  Widget _buildFeatureItem(IconData icon, String title, String description) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: const Color(0xFF059669).withOpacity(0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(icon, size: 24, color: const Color(0xFF059669)),
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
                  description,
                  style: const TextStyle(
                    fontSize: 13,
                    color: Color(0xFF64748B),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInfoRow(String label, String value) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: const TextStyle(
            fontSize: 13,
            color: Color(0xFF64748B),
          ),
        ),
        Text(
          value,
          style: const TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w600,
            color: Color(0xFF0F172A),
          ),
        ),
      ],
    );
  }

  Widget _buildLinkButton(String text) {
    return GestureDetector(
      onTap: () {
        if (text == 'Kebijakan Privasi') {
          Navigator.push(
            context,
            MaterialPageRoute(
                builder: (context) => const PrivacyPolicyScreen()),
          );
        } else if (text == 'Syarat Layanan') {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => const TermsScreen()),
          );
        } else if (text == 'Tentang Komunitas') {
          Navigator.push(
            context,
            MaterialPageRoute(
                builder: (context) => const AboutCommunityScreen()),
          );
        }
      },
      child: Text(
        text,
        style: const TextStyle(
          fontSize: 12,
          color: Color(0xFF059669),
          fontWeight: FontWeight.w500,
        ),
      ),
    );
  }
}
