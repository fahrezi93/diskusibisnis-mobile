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

    UserProfile? currentUser = _authService.currentUser;

    // Fetch fresh data from API to ensure we have the latest bio/avatar
    if (currentUser != null) {
      try {
        final freshProfile = await _apiService.getProfile(currentUser.id);

        // Backend's public profile endpoint strips private info (email, authProvider, etc.)
        // We must preserve these from the stored session
        if (freshProfile != null) {
          currentUser = UserProfile(
            id: freshProfile.id,
            displayName: freshProfile.displayName,
            username: freshProfile.username,
            email: freshProfile.email ??
                currentUser.email, // Keep email if missing
            avatarUrl: freshProfile.avatarUrl,
            bio: freshProfile.bio,
            reputationPoints: freshProfile.reputationPoints,
            createdAt: freshProfile.createdAt,
            isVerified: freshProfile.isVerified,
            hasPassword: currentUser.hasPassword, // Keep private flag
            authProvider: currentUser.authProvider, // Keep provider info
            role: currentUser.role, // Keep role
          );
        }
      } catch (e) {
        print('Error refreshing profile in settings: $e');
      }
    }

    if (mounted) {
      setState(() {
        _user = currentUser;
        _nameController = TextEditingController(text: _user?.displayName ?? '');
        _bioController = TextEditingController(text: _user?.bio ?? '');
        _emailNotifications = prefs.getBool('email_notifications') ?? true;
        _isLoading = false;
      });
    }
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

            // Google Account Indicator (if Google user)
            if (_isGoogleUser)
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 12),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: const Color(0xFFE2E8F0)),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.05),
                            blurRadius: 4,
                          ),
                        ],
                      ),
                      // Google Logo SVG as custom painter or use image
                      child: SizedBox(
                        width: 20,
                        height: 20,
                        child: CustomPaint(
                          painter: GoogleLogoPainter(),
                        ),
                      ),
                    ),
                    const SizedBox(width: 16),
                    const Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('Login dengan Google',
                              style: TextStyle(
                                  fontWeight: FontWeight.w600,
                                  fontSize: 14,
                                  color: Color(0xFF0F172A))),
                          Text('Terhubung',
                              style: TextStyle(
                                  color: Color(0xFF059669),
                                  fontSize: 12,
                                  fontWeight: FontWeight.w500)),
                        ],
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: const Color(0xFFECFDF5),
                        borderRadius: BorderRadius.circular(999),
                      ),
                      child: const Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            LucideIcons.check,
                            size: 12,
                            color: Color(0xFF059669),
                          ),
                          SizedBox(width: 4),
                          Text(
                            'Aktif',
                            style: TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.w600,
                              color: Color(0xFF059669),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),

            // Password - Show for all users (email users can change, Google users can set optional)
            _buildListTile(
              LucideIcons.lock,
              'Password',
              subtitle: _isGoogleUser && !(_user?.hasPassword ?? false)
                  ? 'Belum diset (opsional)'
                  : '••••••••',
              showArrow: true,
              onTap: _handleRequestPasswordReset,
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

// Custom Painter for Google Logo
class GoogleLogoPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final double scale = size.width / 24;

    // Blue
    final bluePaint = Paint()..color = const Color(0xFF4285F4);
    final bluePath = Path()
      ..moveTo(22.56 * scale, 12.25 * scale)
      ..cubicTo(22.56 * scale, 11.47 * scale, 22.49 * scale, 10.72 * scale,
          22.36 * scale, 10 * scale)
      ..lineTo(12 * scale, 10 * scale)
      ..lineTo(12 * scale, 14.26 * scale)
      ..lineTo(17.92 * scale, 14.26 * scale)
      ..cubicTo(17.66 * scale, 15.63 * scale, 16.88 * scale, 16.79 * scale,
          15.71 * scale, 17.57 * scale)
      ..lineTo(15.71 * scale, 20.34 * scale)
      ..lineTo(19.28 * scale, 20.34 * scale)
      ..cubicTo(21.36 * scale, 18.42 * scale, 22.56 * scale, 15.6 * scale,
          22.56 * scale, 12.25 * scale)
      ..close();
    canvas.drawPath(bluePath, bluePaint);

    // Green
    final greenPaint = Paint()..color = const Color(0xFF34A853);
    final greenPath = Path()
      ..moveTo(12 * scale, 23 * scale)
      ..cubicTo(14.97 * scale, 23 * scale, 17.46 * scale, 22.02 * scale,
          19.28 * scale, 20.34 * scale)
      ..lineTo(15.71 * scale, 17.57 * scale)
      ..cubicTo(14.73 * scale, 18.23 * scale, 13.48 * scale, 18.63 * scale,
          12 * scale, 18.63 * scale)
      ..cubicTo(9.14 * scale, 18.63 * scale, 6.71 * scale, 16.7 * scale,
          5.84 * scale, 14.1 * scale)
      ..lineTo(2.18 * scale, 14.1 * scale)
      ..lineTo(2.18 * scale, 16.94 * scale)
      ..cubicTo(3.99 * scale, 20.53 * scale, 7.7 * scale, 23 * scale,
          12 * scale, 23 * scale)
      ..close();
    canvas.drawPath(greenPath, greenPaint);

    // Yellow
    final yellowPaint = Paint()..color = const Color(0xFFFBBC05);
    final yellowPath = Path()
      ..moveTo(5.84 * scale, 14.09 * scale)
      ..cubicTo(5.62 * scale, 13.43 * scale, 5.49 * scale, 12.73 * scale,
          5.49 * scale, 12 * scale)
      ..cubicTo(5.49 * scale, 11.27 * scale, 5.62 * scale, 10.57 * scale,
          5.84 * scale, 9.91 * scale)
      ..lineTo(5.84 * scale, 7.07 * scale)
      ..lineTo(2.18 * scale, 7.07 * scale)
      ..cubicTo(1.43 * scale, 8.55 * scale, 1 * scale, 10.22 * scale, 1 * scale,
          12 * scale)
      ..cubicTo(1 * scale, 13.78 * scale, 1.43 * scale, 15.45 * scale,
          2.18 * scale, 16.93 * scale)
      ..lineTo(5.84 * scale, 14.09 * scale)
      ..close();
    canvas.drawPath(yellowPath, yellowPaint);

    // Red
    final redPaint = Paint()..color = const Color(0xFFEA4335);
    final redPath = Path()
      ..moveTo(12 * scale, 5.38 * scale)
      ..cubicTo(13.62 * scale, 5.38 * scale, 15.06 * scale, 5.94 * scale,
          16.21 * scale, 7.02 * scale)
      ..lineTo(19.36 * scale, 3.87 * scale)
      ..cubicTo(17.45 * scale, 2.09 * scale, 14.97 * scale, 1 * scale,
          12 * scale, 1 * scale)
      ..cubicTo(7.7 * scale, 1 * scale, 3.99 * scale, 3.47 * scale,
          2.18 * scale, 7.07 * scale)
      ..lineTo(5.84 * scale, 9.91 * scale)
      ..cubicTo(6.71 * scale, 7.31 * scale, 9.14 * scale, 5.38 * scale,
          12 * scale, 5.38 * scale)
      ..close();
    canvas.drawPath(redPath, redPaint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
