import 'package:flutter/material.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:image_picker/image_picker.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'dart:io';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/user_profile.dart';
import '../services/auth_service.dart';
import '../services/api_service.dart';
import '../services/supabase_service.dart';
import '../utils/avatar_helper.dart';
import 'welcome_screen.dart';
import 'help_center_screen.dart';
import 'about_screen.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  final AuthService _authService = AuthService();
  final ApiService _apiService = ApiService();
  late TextEditingController _nameController;
  late TextEditingController _bioController;
  UserProfile? _user;

  bool _isLoading = true;
  bool _emailNotifications = true;

  @override
  void initState() {
    super.initState();
    _loadUserData();
  }

  Future<void> _loadUserData() async {
    await _authService.init();
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _user = _authService.currentUser;
      _nameController = TextEditingController(text: _user?.displayName ?? '');
      _bioController = TextEditingController(text: _user?.bio ?? '');
      _emailNotifications = prefs.getBool('email_notifications') ?? true;
      _isLoading = false;
    });
  }

  bool get _isGoogleUser => _user?.authProvider == 'google';

  Future<void> _handleRequestPasswordReset() async {
    if (_user?.email == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Email tidak ditemukan')),
      );
      return;
    }

    // Show confirmation dialog
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Reset Password'),
        content: Text(
          'Link reset password akan dikirim ke ${_user!.email}\n\nProses ini akan mengirim email dengan link untuk mereset password Anda.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Batal'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF059669),
              foregroundColor: Colors.white, // FIXED: Add white text color
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
            ),
            child: const Text(
              'Kirim Link',
              style: TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );

    if (confirmed != true) return;

    // Show loading
    setState(() => _isLoading = true);

    try {
      // Call API to request reset
      await _apiService.requestPasswordReset(_user!.email!);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Link reset password telah dikirim ke ${_user!.email}',
            ),
            backgroundColor: const Color(0xFF059669),
            duration: const Duration(seconds: 5),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              e.toString().replaceAll('Exception: ', ''),
            ),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _handleLogout() async {
    bool confirm = await showDialog(
          context: context,
          builder: (context) => AlertDialog(
            title: const Text('Keluar'),
            content: const Text('Apakah Anda yakin ingin keluar dari akun?'),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context, false),
                child: const Text('Batal'),
              ),
              TextButton(
                onPressed: () => Navigator.pop(context, true),
                style: TextButton.styleFrom(foregroundColor: Colors.red),
                child: const Text('Keluar'),
              ),
            ],
          ),
        ) ??
        false;

    if (confirm) {
      await _authService.logout();
      if (mounted) {
        Navigator.pushAndRemoveUntil(
            context,
            MaterialPageRoute(builder: (_) => const WelcomeScreen()),
            (route) => false);
      }
    }
  }

  Future<void> _handleSaveChanges() async {
    setState(() => _isLoading = true);
    try {
      await _authService.updateProfile(
        _nameController.text,
        _bioController.text,
        null,
      );

      // Refresh user data from auth service to get potential updates
      await _authService.init();
      await _loadUserData();

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Profil berhasil diperbarui'),
            backgroundColor: Color(0xFF059669),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
              content: Text(e.toString().replaceAll('Exception: ', '')),
              backgroundColor: Colors.red),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _handleDeleteAccount() async {
    bool confirm = await showDialog(
          context: context,
          builder: (context) => AlertDialog(
            title: const Text('Hapus Akun'),
            content: const Text(
                'Apakah Anda yakin ingin menghapus akun secara PERMANEN? Data tidak dapat dikembalikan.'),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context, false),
                child: const Text('Batal'),
              ),
              TextButton(
                onPressed: () => Navigator.pop(context, true),
                style: TextButton.styleFrom(foregroundColor: Colors.red),
                child: const Text('Hapus Permanen'),
              ),
            ],
          ),
        ) ??
        false;

    if (!confirm) return;

    String? password;
    if (_user!.hasPassword) {
      final passController = TextEditingController();
      final bool? passConfirm = await showDialog<bool>(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text('Konfirmasi Password'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text(
                  'Masukkan password Anda untuk konfirmasi penghapusan.'),
              const SizedBox(height: 16),
              TextField(
                controller: passController,
                obscureText: true,
                decoration: const InputDecoration(
                  labelText: 'Password',
                  border: OutlineInputBorder(),
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('Batal'),
            ),
            ElevatedButton(
              onPressed: () => Navigator.pop(context, true),
              style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
              child: const Text('Konfirmasi'),
            ),
          ],
        ),
      );

      if (passConfirm != true) return;
      password = passController.text;
      if (password.isEmpty) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text("Password wajib diisi")));
        }
        return;
      }
    }

    setState(() => _isLoading = true);
    try {
      await _authService.deleteAccount(password);
      if (mounted) {
        Navigator.pushAndRemoveUntil(
            context,
            MaterialPageRoute(builder: (_) => const WelcomeScreen()),
            (route) => false);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Akun berhasil dihapus')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
              content: Text(e.toString().replaceAll('Exception: ', '')),
              backgroundColor: Colors.red),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _handleChangeAvatar() async {
    try {
      final ImagePicker picker = ImagePicker();

      // Pick image from gallery
      final XFile? image = await picker.pickImage(
        source: ImageSource.gallery,
        maxWidth: 400, // Smaller for avatar
        maxHeight: 400,
        imageQuality: 85,
      );

      if (image == null) return;

      setState(() => _isLoading = true);

      // Upload to Supabase Storage (like website does)
      final supabaseService = SupabaseService.instance;
      final imageFile = File(image.path);

      // Delete old avatar from Supabase if it exists
      if (_user?.avatarUrl != null &&
          _user!.avatarUrl!.contains('supabase.co')) {
        try {
          await supabaseService.deleteAvatar(_user!.avatarUrl!);
        } catch (e) {
          // Ignore deletion errors - old avatar might not exist
          print('Could not delete old avatar: $e');
        }
      }

      // Upload new avatar to Supabase Storage
      final avatarUrl = await supabaseService.uploadAvatar(
        imageFile,
        _user!.id,
      );

      // Update profile with the Supabase URL
      await _authService.updateProfile(
        _nameController.text.isEmpty
            ? (_user?.displayName ?? '')
            : _nameController.text,
        _bioController.text,
        avatarUrl, // Now it's a proper URL, not base64!
      );

      if (mounted) {
        // Clear cache for the new avatar
        if (_user?.avatarUrl != null) {
          final url = AvatarHelper.normalizeUrl(_user!.avatarUrl!);
          if (url != null) {
            await CachedNetworkImage.evictFromCache(url);
          }
        }

        // Reload user data
        await _loadUserData();

        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Foto profil berhasil diubah'),
            backgroundColor: Color(0xFF059669),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(e.toString().replaceAll('Exception: ', '')),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _handleDeleteAvatar() async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Hapus Foto Profil'),
        content: const Text('Apakah Anda yakin ingin menghapus foto profil?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Batal'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Hapus'),
          ),
        ],
      ),
    );

    if (confirm != true) return;

    setState(() => _isLoading = true);
    try {
      await _authService.deleteAvatar();
      if (mounted) {
        await _loadUserData();
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Foto profil berhasil dihapus'),
            backgroundColor: Color(0xFF059669),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(e.toString().replaceAll('Exception: ', '')),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _handleAvatarCamera() async {
    // This is triggered by the camera icon - same as change avatar
    await _handleChangeAvatar();
  }

  Future<void> _handleEmailNotificationsToggle(bool value) async {
    setState(() => _isLoading = true);

    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool('email_notifications', value);

      // TODO: Send preference to backend API
      // await _apiService.updateEmailNotificationPreference(value);

      setState(() {
        _emailNotifications = value;
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(value
                ? 'Notifikasi email diaktifkan'
                : 'Notifikasi email dinonaktifkan'),
            backgroundColor: const Color(0xFF059669),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Gagal mengubah pengaturan: ${e.toString()}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Scaffold(
        body:
            Center(child: CircularProgressIndicator(color: Color(0xFF059669))),
      );
    }

    if (_user == null) {
      return const Scaffold(
          body: Center(child: Text("Data user tidak ditemukan")));
    }

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: const Text('Pengaturan'),
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
            const Text('Kelola preferensi akun Anda',
                style: TextStyle(color: Color(0xFF64748B), fontSize: 14)),
            const SizedBox(height: 32),

            // Profile Section
            _buildSectionHeader('PROFIL'),
            const SizedBox(height: 16),

            // Avatar Row
            Row(
              children: [
                Container(
                  width: 80,
                  height: 80,
                  decoration: BoxDecoration(
                    color: const Color(0xFFF1F5F9),
                    borderRadius: BorderRadius.circular(999),
                  ),
                  child: _buildAvatarImage(),
                ),
                const SizedBox(width: 20),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text('Foto Profil',
                          style: TextStyle(
                              fontWeight: FontWeight.w600, fontSize: 16)),
                      const SizedBox(height: 8),
                      Row(
                        children: [
                          GestureDetector(
                            onTap: _handleChangeAvatar,
                            child: const Text('Ubah',
                                style: TextStyle(
                                    color: Color(0xFF059669),
                                    fontWeight: FontWeight.w500)),
                          ),
                          const SizedBox(width: 16),
                          GestureDetector(
                            onTap: _handleDeleteAvatar,
                            child: const Text('Hapus',
                                style: TextStyle(
                                    color: Color(0xFFDC2626),
                                    fontWeight: FontWeight.w500)),
                          ),
                        ],
                      )
                    ],
                  ),
                ),
                GestureDetector(
                  onTap: _handleAvatarCamera,
                  child: Container(
                    width: 40,
                    height: 40,
                    decoration: BoxDecoration(
                      color: const Color(0xFF0F172A),
                      borderRadius: BorderRadius.circular(999),
                    ),
                    child: const Icon(LucideIcons.camera,
                        color: Colors.white, size: 16),
                  ),
                )
              ],
            ),

            const SizedBox(height: 24),

            // Form Fields
            _buildTextField('DISPLAY NAME', _nameController, 'Nama Lengkap'),
            const SizedBox(height: 16),
            _buildTextField(
                'BIO', _bioController, 'Ceritakan sedikit tentang Anda...',
                maxLines: 3, maxLength: 200),

            const SizedBox(height: 24),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: _handleSaveChanges,
                icon: const Icon(LucideIcons.save, size: 16),
                label: const Text('Simpan Perubahan'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF059669),
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  elevation: 0,
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(999)),
                ),
              ),
            ),

            const SizedBox(height: 32),
            const Divider(color: Color(0xFFF1F5F9)),
            const SizedBox(height: 32),

            // Account & Security
            _buildSectionHeader('AKUN & KEAMANAN'),
            const SizedBox(height: 8),

            // Email with Google badge
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 12),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                        color: const Color(0xFFF8FAFC),
                        borderRadius: BorderRadius.circular(8)),
                    child: const Icon(LucideIcons.mail,
                        size: 20, color: Color(0xFF475569)),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text('Email',
                            style: TextStyle(
                                fontWeight: FontWeight.w600,
                                fontSize: 14,
                                color: Color(0xFF0F172A))),
                        Row(
                          children: [
                            Text(_user!.email ?? '',
                                style: const TextStyle(
                                    color: Color(0xFF64748B), fontSize: 12)),
                            if (_isGoogleUser) ...[
                              const SizedBox(width: 8),
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 6,
                                  vertical: 2,
                                ),
                                decoration: BoxDecoration(
                                  gradient: const LinearGradient(
                                    colors: [
                                      Color(0xFF4285F4), // Google Blue
                                      Color(0xFF34A853), // Google Green
                                    ],
                                  ),
                                  borderRadius: BorderRadius.circular(4),
                                ),
                                child: const Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Text(
                                      'G',
                                      style: TextStyle(
                                        fontSize: 10,
                                        fontWeight: FontWeight.bold,
                                        color: Colors.white,
                                      ),
                                    ),
                                    SizedBox(width: 2),
                                    Text(
                                      'Google',
                                      style: TextStyle(
                                        fontSize: 10,
                                        fontWeight: FontWeight.w600,
                                        color: Colors.white,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ],
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),

            // Password - Only show for email users or to request reset
            if (!_isGoogleUser)
              _buildListTile(
                LucideIcons.lock,
                'Password',
                subtitle: '••••••••',
                showArrow: true,
                onTap: _handleRequestPasswordReset,
              )
            else
              _buildListTile(
                LucideIcons.info,
                'Login dengan Google',
                subtitle: 'Password dikelola oleh Google',
                color: const Color(0xFF64748B),
              ),

            // Logout Button
            InkWell(
              onTap: _handleLogout,
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 12),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                          color: const Color(0xFFFEF2F2),
                          borderRadius: BorderRadius.circular(8)),
                      child: const Icon(LucideIcons.logOut,
                          size: 20, color: Color(0xFFDC2626)),
                    ),
                    const SizedBox(width: 16),
                    const Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text("Keluar",
                              style: TextStyle(
                                  fontWeight: FontWeight.w600,
                                  fontSize: 14,
                                  color: Color(0xFFDC2626))),
                          Text("Keluar dari akun Anda",
                              style: TextStyle(
                                  color: Color(0xFF64748B), fontSize: 12)),
                        ],
                      ),
                    ),
                    const Icon(LucideIcons.chevronRight,
                        size: 20, color: Color(0xFFCBD5E1)),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 32),
            const Divider(color: Color(0xFFF1F5F9)),
            const SizedBox(height: 32),

            // Preferences
            _buildSectionHeader('PREFERENSI'),
            const SizedBox(height: 8),
            _buildSwitchTile(
                LucideIcons.bell,
                'Notifikasi Email',
                'Info terbaru via email',
                _emailNotifications,
                _handleEmailNotificationsToggle),

            const SizedBox(height: 32),
            const Divider(color: Color(0xFFF1F5F9)),
            const SizedBox(height: 32),

            // About
            _buildSectionHeader('TENTANG & BANTUAN'),
            const SizedBox(height: 8),
            _buildListTile(LucideIcons.helpCircle, 'Pusat Bantuan',
                subtitle: 'FAQ dan Hubungi Kami',
                showExternal: true, onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => const HelpCenterScreen(),
                ),
              );
            }),
            _buildListTile(LucideIcons.info, 'Tentang Aplikasi',
                subtitle: 'Versi 1.0.0 (Beta)', showArrow: true, onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => const AboutScreen(),
                ),
              );
            }),

            const SizedBox(height: 32),
            const Divider(color: Color(0xFFF1F5F9)),
            const SizedBox(height: 32),

            // Delete Account
            GestureDetector(
              onTap: _handleDeleteAccount,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Hapus Akun',
                          style: TextStyle(
                              color: Color(0xFFDC2626),
                              fontWeight: FontWeight.w600)),
                      SizedBox(height: 2),
                      Text('Hapus permanen akun dan data Anda',
                          style: TextStyle(
                              color: Color(0xFF94A3B8), fontSize: 12)),
                    ],
                  ),
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: const BoxDecoration(
                        color: Color(0xFFFEF2F2), shape: BoxShape.circle),
                    child: const Icon(LucideIcons.trash2,
                        size: 16, color: Color(0xFFDC2626)),
                  )
                ],
              ),
            ),
            const SizedBox(height: 40),
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
          letterSpacing: 1.2),
    );
  }

  Widget _buildTextField(
      String label, TextEditingController controller, String placeholder,
      {int maxLines = 1, int? maxLength}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label,
            style: const TextStyle(
                fontSize: 10,
                fontWeight: FontWeight.bold,
                color: Color(0xFF64748B))),
        const SizedBox(height: 8),
        TextField(
          controller: controller,
          maxLines: maxLines,
          maxLength: maxLength,
          style: const TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w500,
              color: Color(0xFF0F172A)),
          decoration: InputDecoration(
            hintText: placeholder,
            hintStyle: const TextStyle(color: Color(0xFFCBD5E1)),
            contentPadding: const EdgeInsets.symmetric(vertical: 8),
            isDense: true,
            border: InputBorder.none,
            enabledBorder: const UnderlineInputBorder(
                borderSide: BorderSide(color: Color(0xFFE2E8F0))),
            focusedBorder: const UnderlineInputBorder(
                borderSide: BorderSide(color: Color(0xFF059669))),
            counterText: maxLength != null ? null : '',
          ),
        ),
      ],
    );
  }

  Widget _buildListTile(IconData icon, String title,
      {String? subtitle,
      bool showArrow = false,
      bool showExternal = false,
      bool isDestructive = false,
      Color? color,
      Widget? trailing,
      VoidCallback? onTap}) {
    final baseColor =
        isDestructive ? const Color(0xFFDC2626) : const Color(0xFF0F172A);
    final iconBg =
        isDestructive ? const Color(0xFFFEF2F2) : const Color(0xFFF8FAFC);
    final iconColor =
        isDestructive ? const Color(0xFFDC2626) : const Color(0xFF475569);

    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 12),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                  color: iconBg, borderRadius: BorderRadius.circular(8)),
              child: Icon(icon, size: 20, color: iconColor),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title,
                      style: TextStyle(
                          fontWeight: FontWeight.w600,
                          fontSize: 14,
                          color: baseColor)),
                  if (subtitle != null)
                    Text(subtitle,
                        style: const TextStyle(
                            color: Color(0xFF64748B), fontSize: 12)),
                ],
              ),
            ),
            if (trailing != null) trailing,
            if (showArrow)
              const Icon(LucideIcons.chevronRight,
                  size: 20, color: Color(0xFFCBD5E1)),
            if (showExternal)
              const Icon(LucideIcons.externalLink,
                  size: 16, color: Color(0xFFCBD5E1)),
          ],
        ),
      ),
    );
  }

  Widget _buildSwitchTile(IconData icon, String title, String subtitle,
      bool value, Function(bool) onChanged) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 12),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
                color: const Color(0xFFF8FAFC),
                borderRadius: BorderRadius.circular(8)),
            child: Icon(icon, size: 20, color: const Color(0xFF475569)),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title,
                    style: const TextStyle(
                        fontWeight: FontWeight.w600,
                        fontSize: 14,
                        color: Color(0xFF0F172A))),
                Text(subtitle,
                    style: const TextStyle(
                        color: Color(0xFF64748B), fontSize: 12)),
              ],
            ),
          ),
          Switch(
            value: value,
            onChanged: onChanged,
            activeThumbColor: Colors.white,
            activeTrackColor: const Color(0xFF059669),
          ),
        ],
      ),
    );
  }

  Widget _buildAvatarImage() {
    final avatarUrl = _user?.avatarUrl;
    final displayName = _user?.displayName ?? 'User';

    // Use AvatarHelper for consistent avatar handling with Supabase URLs
    return AvatarHelper.buildSquareAvatarWithBadge(
      avatarUrl: avatarUrl,
      name: displayName,
      isVerified: _user?.isVerified ?? false,
      size: 80,
      borderRadius: 40, // Circular for settings page
    );
  }
}
