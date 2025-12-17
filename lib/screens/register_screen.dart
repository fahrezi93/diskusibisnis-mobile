import 'package:flutter/material.dart';
import 'package:lucide_icons/lucide_icons.dart';
import '../services/auth_service.dart';
import '../widgets/google_logo.dart';
import 'login_screen.dart';
import 'main_nav_screen.dart';
import 'otp_verification_screen.dart';

class RegisterScreen extends StatefulWidget {
  const RegisterScreen({super.key});

  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  final _formKey = GlobalKey<FormState>();
  final AuthService _authService = AuthService();

  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _usernameController = TextEditingController();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();

  bool _isLoading = false;
  bool _isPasswordVisible = false;

  Future<void> _handleRegister() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);
    try {
      // 1. Request OTP
      await _authService.requestRegisterOTP(
          _nameController.text,
          _usernameController.text,
          _emailController.text,
          _passwordController.text);

      if (mounted) {
        // 2. Navigate to OTP Verification
        Navigator.push(
          context,
          MaterialPageRoute(
              builder: (_) => OtpVerificationScreen(
                    email: _emailController.text,
                    displayName: _nameController.text,
                  )),
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

  Future<void> _handleGoogleLogin() async {
    setState(() => _isLoading = true);
    try {
      final success = await _authService.googleLogin();
      if (success && mounted) {
        Navigator.pushAndRemoveUntil(
          context,
          MaterialPageRoute(builder: (_) => const MainNavScreen()),
          (route) => false,
        );
      }
    } catch (e) {
      if (mounted) {
        String errorMessage = 'Google Sign-In Gagal: ${e.toString()}';
        if (e.toString().contains('ApiException: 10')) {
          errorMessage =
              'Konfigurasi Salah: SHA-1 Fingerprint belum ditambahkan di Firebase Console.';
        }
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(errorMessage), backgroundColor: Colors.red),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(LucideIcons.arrowLeft, color: Color(0xFF0F172A)),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24.0),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Center(
                  child: Image.asset(
                    'assets/images/logo.png',
                    height: 80,
                  ),
                ),
                const SizedBox(height: 24),
                const Text(
                  'Buat Akun Baru',
                  style: TextStyle(
                    fontSize: 28,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF0F172A),
                  ),
                ),
                const SizedBox(height: 8),
                const Text(
                  'Daftar sekarang untuk mulai berdiskusi.',
                  style: TextStyle(color: Color(0xFF64748B), fontSize: 16),
                ),
                const SizedBox(height: 32),

                // Name Field
                TextFormField(
                  controller: _nameController,
                  validator: (value) {
                    if (value == null || value.isEmpty)
                      return 'Nama Lengkap wajib diisi';
                    return null;
                  },
                  decoration: InputDecoration(
                    labelText: 'Nama Lengkap',
                    hintText: 'John Doe',
                    prefixIcon: const Icon(LucideIcons.user, size: 20),
                    border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12)),
                  ),
                ),
                const SizedBox(height: 20),

                // Username Field
                TextFormField(
                  controller: _usernameController,
                  validator: (value) {
                    if (value == null || value.isEmpty)
                      return 'Username wajib diisi';
                    if (value.length < 3) return 'Username minimal 3 karakter';
                    if (!RegExp(r'^[a-z0-9_]+$').hasMatch(value))
                      return 'Hanya huruf kecil, angka, dan underscore';
                    return null;
                  },
                  decoration: InputDecoration(
                    labelText: 'Username',
                    hintText: 'username_anda',
                    prefixIcon: const Icon(LucideIcons.atSign, size: 20),
                    border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12)),
                  ),
                ),
                const SizedBox(height: 20),

                // Email Field
                TextFormField(
                  controller: _emailController,
                  validator: (value) {
                    if (value == null || value.isEmpty)
                      return 'Email wajib diisi';
                    if (!value.contains('@')) return 'Email tidak valid';
                    return null;
                  },
                  decoration: InputDecoration(
                    labelText: 'Email',
                    hintText: 'nama@email.com',
                    prefixIcon: const Icon(LucideIcons.mail, size: 20),
                    border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12)),
                  ),
                ),
                const SizedBox(height: 20),

                // Password Field
                TextFormField(
                  controller: _passwordController,
                  obscureText: !_isPasswordVisible,
                  validator: (value) {
                    if (value == null || value.isEmpty)
                      return 'Password wajib diisi';
                    if (value.length < 6) return 'Password minimal 6 karakter';
                    return null;
                  },
                  decoration: InputDecoration(
                    labelText: 'Password',
                    hintText: 'Minimal 6 karakter',
                    prefixIcon: const Icon(LucideIcons.lock, size: 20),
                    suffixIcon: IconButton(
                      icon: Icon(
                          _isPasswordVisible
                              ? LucideIcons.eyeOff
                              : LucideIcons.eye,
                          size: 20),
                      onPressed: () => setState(
                          () => _isPasswordVisible = !_isPasswordVisible),
                    ),
                    border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12)),
                  ),
                ),

                const SizedBox(height: 32),

                // Register Button
                ElevatedButton(
                  onPressed: _isLoading ? null : _handleRegister,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF059669),
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12)),
                  ),
                  child: _isLoading
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(
                              color: Colors.white, strokeWidth: 2))
                      : const Text('Daftar Akun',
                          style: TextStyle(
                              fontSize: 16, fontWeight: FontWeight.bold)),
                ),

                const SizedBox(height: 24),
                const Row(
                  children: [
                    Expanded(child: Divider()),
                    Padding(
                      padding: EdgeInsets.symmetric(horizontal: 16),
                      child: Text('atau daftar dengan',
                          style: TextStyle(color: Color(0xFF94A3B8))),
                    ),
                    Expanded(child: Divider()),
                  ],
                ),
                const SizedBox(height: 24),

                // Google Button
                OutlinedButton.icon(
                  onPressed: _isLoading ? null : _handleGoogleLogin,
                  icon: const GoogleLogo(size: 24),
                  label: const Text('Google'),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: const Color(0xFF0F172A),
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    side: const BorderSide(color: Color(0xFFE2E8F0)),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12)),
                  ),
                ),

                const SizedBox(height: 32),

                // Login Link
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Text('Sudah punya akun? ',
                        style: TextStyle(color: Color(0xFF64748B))),
                    GestureDetector(
                      onTap: () {
                        Navigator.pushReplacement(
                            context,
                            MaterialPageRoute(
                                builder: (_) => const LoginScreen()));
                      },
                      child: const Text('Masuk',
                          style: TextStyle(
                              color: Color(0xFF059669),
                              fontWeight: FontWeight.bold)),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
