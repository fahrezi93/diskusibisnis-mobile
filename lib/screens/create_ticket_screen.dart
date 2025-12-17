import 'package:flutter/material.dart';
import 'package:lucide_icons/lucide_icons.dart';
import '../services/api_service.dart';
import '../services/auth_service.dart';

class CreateTicketScreen extends StatefulWidget {
  const CreateTicketScreen({super.key});

  @override
  State<CreateTicketScreen> createState() => _CreateTicketScreenState();
}

class _CreateTicketScreenState extends State<CreateTicketScreen> {
  final _formKey = GlobalKey<FormState>();
  final _authService = AuthService();
  final _apiService = ApiService();

  final _subjectController = TextEditingController();
  final _messageController = TextEditingController();
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();

  String _selectedCategory = 'General';
  bool _isLoading = false;
  bool _isLoggedIn = false;

  final List<String> _categories = [
    'General',
    'Technical',
    'Billing',
    'Feature Request',
    'Report Violation'
  ];

  @override
  void initState() {
    super.initState();
    _initAuth();
  }

  Future<void> _initAuth() async {
    await _authService.init();
    setState(() {
      _isLoggedIn = _authService.isAuthenticated;
      if (_isLoggedIn && _authService.currentUser != null) {
        _nameController.text = _authService.currentUser!.displayName;
        // _emailController.text = _authService.currentUser!.email; // Email might be private/masked, asking user to fill is safer or use from profile if available
        // Assuming email is not readily available in public profile without extra fetch, letting user fill it.
        // If email is in currentUser, pre-fill it:
        // _emailController.text = _authService.currentUser!.email ?? '';
      }
    });
  }

  Future<void> _submitTicket() async {
    if (!_formKey.currentState!.validate()) return;

    if (!_isLoggedIn) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Silakan login terlebih dahulu')),
      );
      return;
    }

    setState(() => _isLoading = true);

    try {
      await _apiService.createSupportTicket(
        token: _authService.token!,
        subject: _subjectController.text,
        message: _messageController.text,
        name: _nameController.text,
        email: _emailController.text,
        category: _selectedCategory,
      );

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
                'Tiket berhasil dikirim! Tim kami akan segera menghubungi Anda.'),
            backgroundColor: Color(0xFF059669),
          ),
        );
        Navigator.pop(context);
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
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: const Text('Buat Tiket Bantuan'),
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(LucideIcons.arrowLeft, color: Colors.black),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Sampaikan masalah atau masukan Anda',
                style: TextStyle(
                  fontSize: 16,
                  color: Color(0xFF64748B),
                ),
              ),
              const SizedBox(height: 24),

              // Name Support
              _buildLabel('Nama'),
              TextFormField(
                controller: _nameController,
                decoration: _inputDecoration('Nama Lengkap'),
                validator: (val) =>
                    val == null || val.isEmpty ? 'Nama wajib diisi' : null,
              ),
              const SizedBox(height: 16),

              // Email Support
              _buildLabel('Email'),
              TextFormField(
                controller: _emailController,
                decoration: _inputDecoration('Alamat Email'),
                validator: (val) {
                  if (val == null || val.isEmpty) return 'Email wajib diisi';
                  if (!val.contains('@')) return 'Email tidak valid';
                  return null;
                },
              ),
              const SizedBox(height: 16),

              // Category
              _buildLabel('Kategori'),
              DropdownButtonFormField<String>(
                initialValue: _selectedCategory,
                decoration: _inputDecoration('Pilih Kategori'),
                items: _categories
                    .map((c) => DropdownMenuItem(value: c, child: Text(c)))
                    .toList(),
                onChanged: (val) => setState(() => _selectedCategory = val!),
              ),
              const SizedBox(height: 16),

              // Subject
              _buildLabel('Subjek'),
              TextFormField(
                controller: _subjectController,
                decoration: _inputDecoration('Judul Laporan'),
                validator: (val) =>
                    val == null || val.isEmpty ? 'Subjek wajib diisi' : null,
              ),
              const SizedBox(height: 16),

              // Message
              _buildLabel('Pesan'),
              TextFormField(
                controller: _messageController,
                maxLines: 5,
                decoration:
                    _inputDecoration('Jelaskan masalah Anda secara detail...'),
                validator: (val) =>
                    val == null || val.isEmpty ? 'Pesan wajib diisi' : null,
              ),
              const SizedBox(height: 32),

              // Submit Button
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: _isLoading ? null : _submitTicket,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF059669),
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: _isLoading
                      ? const SizedBox(
                          height: 20,
                          width: 20,
                          child: CircularProgressIndicator(
                              strokeWidth: 2, color: Colors.white),
                        )
                      : const Text(
                          'Kirim Tiket',
                          style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              color: Colors.white),
                        ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildLabel(String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Text(
        text,
        style: const TextStyle(
          fontSize: 14,
          fontWeight: FontWeight.w600,
          color: Color(0xFF0F172A),
        ),
      ),
    );
  }

  InputDecoration _inputDecoration(String hint) {
    return InputDecoration(
      hintText: hint,
      hintStyle: const TextStyle(color: Color(0xFF94A3B8), fontSize: 14),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: Color(0xFFE2E8F0)),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: Color(0xFFE2E8F0)),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: Color(0xFF059669), width: 1.5),
      ),
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
      filled: true,
      fillColor: const Color(0xFFF8FAFC),
    );
  }

  @override
  void dispose() {
    _subjectController.dispose();
    _messageController.dispose();
    _nameController.dispose();
    _emailController.dispose();
    super.dispose();
  }
}
