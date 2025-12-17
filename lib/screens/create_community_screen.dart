import 'package:flutter/material.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';
import '../services/api_service.dart';
import '../services/auth_service.dart';
import '../services/supabase_service.dart';

class CreateCommunityScreen extends StatefulWidget {
  const CreateCommunityScreen({super.key});

  @override
  State<CreateCommunityScreen> createState() => _CreateCommunityScreenState();
}

class _CreateCommunityScreenState extends State<CreateCommunityScreen> {
  final ApiService _api = ApiService();
  final AuthService _auth = AuthService();
  final SupabaseService _supabase = SupabaseService.instance;

  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _descriptionController = TextEditingController();
  final TextEditingController _locationController = TextEditingController();

  File? _imageFile;

  String _selectedCategory = '';
  final List<String> _categories = [
    'Regional',
    'Marketing',
    'Industri',
    'Perdagangan',
    'Teknologi',
    'Keuangan',
    'Kuliner',
    'Fashion',
    'Kesehatan',
    'Pendidikan',
  ];

  bool _isLoading = false;
  bool _isInitializing = true;
  String _error = '';
  String _success = '';

  @override
  void initState() {
    super.initState();
    _initAuth();
  }

  Future<void> _initAuth() async {
    await _auth.init();
    if (mounted) {
      setState(() {
        _isInitializing = false;
      });
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _descriptionController.dispose();
    _locationController.dispose();
    super.dispose();
  }

  Future<void> _pickImage() async {
    final picker = ImagePicker();
    final pickedFile = await picker.pickImage(source: ImageSource.gallery);

    if (pickedFile != null) {
      setState(() {
        _imageFile = File(pickedFile.path);
      });
    }
  }

  Future<void> _submitCommunity() async {
    if (!_auth.isAuthenticated) {
      setState(() => _error = 'Login diperlukan untuk membuat komunitas');
      return;
    }

    final name = _nameController.text.trim();
    final description = _descriptionController.text.trim();
    final location = _locationController.text.trim();

    // Validasi
    if (name.isEmpty) {
      setState(() => _error = 'Nama komunitas harus diisi');
      return;
    }

    if (description.isEmpty) {
      setState(() => _error = 'Deskripsi harus diisi');
      return;
    }

    if (_selectedCategory.isEmpty) {
      setState(() => _error = 'Pilih kategori komunitas');
      return;
    }

    setState(() {
      _isLoading = true;
      _error = '';
      _success = '';
    });

    try {
      String? avatarUrl;
      // Upload avatar if selected
      if (_imageFile != null) {
        if (_auth.currentUser?.id == null) {
          throw Exception('User ID not found');
        }
        avatarUrl = await _supabase.uploadCommunityIcon(
            _imageFile!, _auth.currentUser!.id);
      }

      await _api.createCommunity(
        token: _auth.token!,
        name: name,
        description: description,
        category: _selectedCategory,
        location: location.isNotEmpty ? location : null,
        avatarUrl: avatarUrl,
      );

      if (mounted) {
        setState(() {
          _success = 'Komunitas berhasil dibuat!';
          _isLoading = false;
        });

        // Navigate back after 1.5 seconds
        Future.delayed(const Duration(milliseconds: 1500), () {
          if (mounted) {
            Navigator.of(context).pop(true); // Return true to indicate success
          }
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _error = e.toString().replaceAll('Exception: ', '');
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    // Show loading while checking auth
    if (_isInitializing) {
      return const Scaffold(
        backgroundColor: Color(0xFFF8FAFC),
        body: Center(
          child: CircularProgressIndicator(color: Color(0xFF059669)),
        ),
      );
    }

    if (!_auth.isAuthenticated) {
      return Scaffold(
        backgroundColor: const Color(0xFFF8FAFC),
        appBar: AppBar(
          backgroundColor: Colors.white,
          elevation: 0,
          leading: IconButton(
            icon: const Icon(LucideIcons.arrowLeft, color: Color(0xFF0F172A)),
            onPressed: () => Navigator.pop(context),
          ),
          title: const Text(
            'Buat Komunitas',
            style: TextStyle(
              color: Color(0xFF0F172A),
              fontWeight: FontWeight.w600,
              fontSize: 16,
            ),
          ),
        ),
        body: Center(
          child: Padding(
            padding: const EdgeInsets.all(32),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Container(
                  width: 80,
                  height: 80,
                  decoration: BoxDecoration(
                    color: const Color(0xFFECFDF5),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: const Icon(
                    LucideIcons.users,
                    size: 40,
                    color: Color(0xFF059669),
                  ),
                ),
                const SizedBox(height: 24),
                const Text(
                  'Login Diperlukan',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF0F172A),
                  ),
                ),
                const SizedBox(height: 8),
                const Text(
                  'Silakan login untuk membuat komunitas',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 14,
                    color: Color(0xFF64748B),
                  ),
                ),
                const SizedBox(height: 24),
                ElevatedButton(
                  onPressed: () => Navigator.pop(context),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF059669),
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(
                        horizontal: 32, vertical: 12),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: const Text(
                    'Kembali',
                    style: TextStyle(
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      );
    }

    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(LucideIcons.arrowLeft, color: Color(0xFF0F172A)),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          'Buat Komunitas',
          style: TextStyle(
            color: Color(0xFF0F172A),
            fontWeight: FontWeight.w600,
            fontSize: 16,
          ),
        ),
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header
              Container(
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: const Color(0xFFE2E8F0)),
                ),
                child: Column(
                  children: [
                    Container(
                      width: 64,
                      height: 64,
                      decoration: BoxDecoration(
                        color: const Color(0xFFECFDF5),
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: const Icon(
                        LucideIcons.plus,
                        size: 32,
                        color: Color(0xFF059669),
                      ),
                    ),
                    const SizedBox(height: 16),
                    const Text(
                      'Buat Komunitas Baru',
                      style: TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF0F172A),
                      ),
                    ),
                    const SizedBox(height: 8),
                    const Text(
                      'Bangun komunitas UMKM untuk berbagi pengalaman dan saling mendukung',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 13,
                        color: Color(0xFF64748B),
                        height: 1.5,
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 16),

              // Success message
              if (_success.isNotEmpty) ...[
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: const Color(0xFFECFDF5),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: const Color(0xFFD1FAE5)),
                  ),
                  child: Row(
                    children: [
                      const Icon(LucideIcons.checkCircle,
                          size: 20, color: Color(0xFF059669)),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          _success,
                          style: const TextStyle(
                            fontSize: 13,
                            color: Color(0xFF059669),
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),
              ],

              // Error message
              if (_error.isNotEmpty) ...[
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: const Color(0xFFFEE2E2),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: const Color(0xFFFECACA)),
                  ),
                  child: Row(
                    children: [
                      const Icon(LucideIcons.alertCircle,
                          size: 20, color: Color(0xFFDC2626)),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          _error,
                          style: const TextStyle(
                            fontSize: 13,
                            color: Color(0xFFDC2626),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),
              ],

              // Form
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: const Color(0xFFE2E8F0)),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Community Icon
                    Align(
                      alignment: Alignment.center,
                      child: GestureDetector(
                        onTap: _pickImage,
                        child: Column(
                          children: [
                            Container(
                              width: 100,
                              height: 100,
                              decoration: BoxDecoration(
                                color: const Color(0xFFF1F5F9),
                                borderRadius: BorderRadius.circular(50),
                                image: _imageFile != null
                                    ? DecorationImage(
                                        image: FileImage(_imageFile!),
                                        fit: BoxFit.cover,
                                      )
                                    : null,
                                border:
                                    Border.all(color: const Color(0xFFE2E8F0)),
                              ),
                              child: _imageFile == null
                                  ? const Icon(LucideIcons.camera,
                                      size: 32, color: Color(0xFF64748B))
                                  : null,
                            ),
                            const SizedBox(height: 8),
                            const Text(
                              'Tambahkan Ikon Komunitas',
                              style: TextStyle(
                                fontSize: 13,
                                color: Color(0xFF64748B),
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 24),
                    // Name
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Row(
                          children: [
                            Icon(LucideIcons.users,
                                size: 16, color: Color(0xFF059669)),
                            SizedBox(width: 8),
                            Text(
                              'Nama Komunitas *',
                              style: TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.w600,
                                color: Color(0xFF334155),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        TextField(
                          controller: _nameController,
                          decoration: InputDecoration(
                            hintText: 'Contoh: UMKM Bandung Kreatif',
                            hintStyle: const TextStyle(
                              fontSize: 13,
                              color: Color(0xFF94A3B8),
                            ),
                            filled: true,
                            fillColor: const Color(0xFFF8FAFC),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                              borderSide:
                                  const BorderSide(color: Color(0xFFE2E8F0)),
                            ),
                            enabledBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                              borderSide:
                                  const BorderSide(color: Color(0xFFE2E8F0)),
                            ),
                            focusedBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                              borderSide: const BorderSide(
                                  color: Color(0xFF059669), width: 2),
                            ),
                            contentPadding: const EdgeInsets.all(16),
                          ),
                          maxLength: 100,
                        ),
                      ],
                    ),

                    const SizedBox(height: 16),

                    // Description
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Row(
                          children: [
                            Icon(LucideIcons.fileText,
                                size: 16, color: Color(0xFF059669)),
                            SizedBox(width: 8),
                            Text(
                              'Deskripsi *',
                              style: TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.w600,
                                color: Color(0xFF334155),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        TextField(
                          controller: _descriptionController,
                          decoration: InputDecoration(
                            hintText:
                                'Jelaskan tujuan komunitas, target anggota, dan aktivitas yang akan dilakukan...',
                            hintStyle: const TextStyle(
                              fontSize: 13,
                              color: Color(0xFF94A3B8),
                            ),
                            filled: true,
                            fillColor: const Color(0xFFF8FAFC),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                              borderSide:
                                  const BorderSide(color: Color(0xFFE2E8F0)),
                            ),
                            enabledBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                              borderSide:
                                  const BorderSide(color: Color(0xFFE2E8F0)),
                            ),
                            focusedBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                              borderSide: const BorderSide(
                                  color: Color(0xFF059669), width: 2),
                            ),
                            contentPadding: const EdgeInsets.all(16),
                          ),
                          maxLines: 4,
                          maxLength: 500,
                        ),
                      ],
                    ),

                    const SizedBox(height: 16),

                    // Category
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Row(
                          children: [
                            Icon(LucideIcons.tag,
                                size: 16, color: Color(0xFF059669)),
                            SizedBox(width: 8),
                            Text(
                              'Kategori *',
                              style: TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.w600,
                                color: Color(0xFF334155),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        Container(
                          decoration: BoxDecoration(
                            color: const Color(0xFFF8FAFC),
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: const Color(0xFFE2E8F0)),
                          ),
                          padding: const EdgeInsets.symmetric(horizontal: 16),
                          child: DropdownButtonHideUnderline(
                            child: DropdownButton<String>(
                              value: _selectedCategory.isEmpty
                                  ? null
                                  : _selectedCategory,
                              isExpanded: true,
                              hint: const Text(
                                'Pilih kategori komunitas',
                                style: TextStyle(
                                  fontSize: 13,
                                  color: Color(0xFF94A3B8),
                                ),
                              ),
                              items: _categories.map((category) {
                                return DropdownMenuItem<String>(
                                  value: category,
                                  child: Text(
                                    category,
                                    style: const TextStyle(
                                      fontSize: 14,
                                      color: Color(0xFF0F172A),
                                    ),
                                  ),
                                );
                              }).toList(),
                              onChanged: (value) {
                                setState(() {
                                  _selectedCategory = value ?? '';
                                });
                              },
                            ),
                          ),
                        ),
                      ],
                    ),

                    const SizedBox(height: 16),

                    // Location
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Row(
                          children: [
                            Icon(LucideIcons.mapPin,
                                size: 16, color: Color(0xFF059669)),
                            SizedBox(width: 8),
                            Text(
                              'Lokasi (Opsional)',
                              style: TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.w600,
                                color: Color(0xFF334155),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        TextField(
                          controller: _locationController,
                          decoration: InputDecoration(
                            hintText: 'Jakarta, Bandung, atau Online',
                            hintStyle: const TextStyle(
                              fontSize: 13,
                              color: Color(0xFF94A3B8),
                            ),
                            filled: true,
                            fillColor: const Color(0xFFF8FAFC),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                              borderSide:
                                  const BorderSide(color: Color(0xFFE2E8F0)),
                            ),
                            enabledBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                              borderSide:
                                  const BorderSide(color: Color(0xFFE2E8F0)),
                            ),
                            focusedBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                              borderSide: const BorderSide(
                                  color: Color(0xFF059669), width: 2),
                            ),
                            contentPadding: const EdgeInsets.all(16),
                          ),
                          maxLength: 100,
                        ),
                      ],
                    ),

                    const SizedBox(height: 16),

                    // Tips
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: const Color(0xFFF8FAFC),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: const Color(0xFFE2E8F0)),
                      ),
                      child: const Row(
                        children: [
                          Icon(
                            LucideIcons.info,
                            size: 20,
                            color: Color(0xFF059669),
                          ),
                          SizedBox(width: 12),
                          Expanded(
                            child: Text(
                              'Nama harus unik, deskripsi jelas, dan pilih kategori yang tepat.',
                              style: TextStyle(
                                fontSize: 12,
                                color: Color(0xFF64748B),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 16),

              // Submit buttons
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed:
                          _isLoading ? null : () => Navigator.pop(context),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: const Color(0xFF64748B),
                        side: const BorderSide(color: Color(0xFFE2E8F0)),
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      child: const Text(
                        'Batal',
                        style: TextStyle(fontWeight: FontWeight.w600),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    flex: 2,
                    child: ElevatedButton(
                      onPressed: _isLoading ? null : _submitCommunity,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF059669),
                        foregroundColor: Colors.white,
                        disabledBackgroundColor: const Color(0xFFE2E8F0),
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        elevation: 0,
                      ),
                      child: _isLoading
                          ? const SizedBox(
                              height: 20,
                              width: 20,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                valueColor:
                                    AlwaysStoppedAnimation<Color>(Colors.white),
                              ),
                            )
                          : const Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(LucideIcons.plus, size: 16),
                                SizedBox(width: 8),
                                Text(
                                  'Buat Komunitas',
                                  style: TextStyle(
                                    fontWeight: FontWeight.w700,
                                    fontSize: 14,
                                  ),
                                ),
                              ],
                            ),
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 100),
            ],
          ),
        ),
      ),
    );
  }
}
