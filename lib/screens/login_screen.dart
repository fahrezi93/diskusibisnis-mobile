import 'package:flutter/material.dart';
import 'package:lucide_icons/lucide_icons.dart';
import '../services/auth_service.dart';
import '../widgets/google_logo.dart';
import 'register_screen.dart';
import 'main_nav_screen.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final AuthService _authService = AuthService();

  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();

  bool _isLoading = false;
  bool _isPasswordVisible = false;

  Future<void> _handleLogin() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);
    try {
      await _authService.login(_emailController.text, _passwordController.text);
      if (mounted) {
        // Navigate to MainScreen and remove all previous routes
        Navigator.pushAndRemoveUntil(
          context,
          MaterialPageRoute(builder: (_) => const MainNavScreen()),
          (route) => false,
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
        String errorMessage = 'Google Login Gagal: ${e.toString()}';
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
                  'Masuk Kembali',
                  style: TextStyle(
                    fontSize: 28,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF0F172A),
                  ),
                ),
                const SizedBox(height: 8),
                const Text(
                  'Selamat datang kembali! Masuk untuk melanjutkan.',
                  style: TextStyle(color: Color(0xFF64748B), fontSize: 16),
                ),
                const SizedBox(height: 32),

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

                const SizedBox(height: 12),
                Align(
                  alignment: Alignment.centerRight,
                  child: TextButton(
                    onPressed: () {
                      // TODO: Implement forgot password
                    },
                    child: const Text('Lupa Password?',
                        style: TextStyle(color: Color(0xFF059669))),
                  ),
                ),

                const SizedBox(height: 24),

                // Login Button
                ElevatedButton(
                  onPressed: _isLoading ? null : _handleLogin,
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
                      : const Text('Masuk',
                          style: TextStyle(
                              fontSize: 16, fontWeight: FontWeight.bold)),
                ),

                const SizedBox(height: 24),
                const Row(
                  children: [
                    Expanded(child: Divider()),
                    Padding(
                      padding: EdgeInsets.symmetric(horizontal: 16),
                      child: Text('atau masuk dengan',
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

                // Register Link
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Text('Belum punya akun? ',
                        style: TextStyle(color: Color(0xFF64748B))),
                    GestureDetector(
                      onTap: () {
                        Navigator.pushReplacement(
                            context,
                            MaterialPageRoute(
                                builder: (_) => const RegisterScreen()));
                      },
                      child: const Text('Daftar Sekarang',
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
