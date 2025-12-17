import 'package:flutter/material.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';
import '../services/api_service.dart';
import '../services/auth_service.dart';
import '../services/supabase_service.dart';

class EditCommunityScreen extends StatefulWidget {
  final Map<String, dynamic> community;

  const EditCommunityScreen({
    super.key,
    required this.community,
  });

  @override
  State<EditCommunityScreen> createState() => _EditCommunityScreenState();
}

class _EditCommunityScreenState extends State<EditCommunityScreen> {
  final ApiService _api = ApiService();
  final AuthService _auth = AuthService();
  final SupabaseService _supabase = SupabaseService.instance;

  late TextEditingController _nameController;
  late TextEditingController _descriptionController;
  late TextEditingController _locationController;
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
  String _error = '';
  String _success = '';

  @override
  void initState() {
    super.initState();
    _auth.init();

    // Initialize with existing data
    _nameController = TextEditingController(text: widget.community['name']);
    _descriptionController =
        TextEditingController(text: widget.community['description']);
    _locationController =
        TextEditingController(text: widget.community['location'] ?? '');

    // Set category if it exists in the list
    if (widget.community['category'] != null &&
        _categories.contains(widget.community['category'])) {
      _selectedCategory = widget.community['category'];
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

  Future<void> _submitChanges() async {
    if (!_auth.isAuthenticated) {
      setState(() => _error = 'Login diperlukan');
      return;
    }

    final name = _nameController.text.trim();
    final description = _descriptionController.text.trim();
    final location = _locationController.text.trim();

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
      // Upload avatar if new image selected
      if (_imageFile != null) {
        if (_auth.currentUser?.id == null) {
          throw Exception('User ID not found');
        }
        avatarUrl = await _supabase.uploadCommunityIcon(
            _imageFile!, _auth.currentUser!.id);
      }

      await _api.updateCommunity(
        token: _auth.token!,
        slug: widget.community['slug'],
        name: name,
        description: description,
        category: _selectedCategory,
        location: location.isNotEmpty ? location : null,
        avatarUrl: avatarUrl,
      );

      if (mounted) {
        setState(() {
          _success = 'Perubahan berhasil disimpan!';
          _isLoading = false;
        });

        Future.delayed(const Duration(milliseconds: 1500), () {
          if (mounted) {
            Navigator.of(context).pop(true); // Return update signal
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
          'Edit Komunitas',
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
                child: Row(
                  children: [
                    Container(
                      width: 48,
                      height: 48,
                      decoration: BoxDecoration(
                        color: const Color(0xFFECFDF5),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: const Icon(
                        LucideIcons.edit,
                        size: 24,
                        color: Color(0xFF059669),
                      ),
                    ),
                    const SizedBox(width: 16),
                    const Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Edit Informasi',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              color: Color(0xFF0F172A),
                            ),
                          ),
                          SizedBox(height: 4),
                          Text(
                            'Perbarui detail komunitas Anda',
                            style: TextStyle(
                              fontSize: 13,
                              color: Color(0xFF64748B),
                            ),
                          ),
                        ],
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
                                    : (widget.community['avatar_url'] != null &&
                                            widget.community['avatar_url']
                                                .isNotEmpty)
                                        ? DecorationImage(
                                            image: NetworkImage(
                                                widget.community['avatar_url']),
                                            fit: BoxFit.cover,
                                          )
                                        : null,
                                border:
                                    Border.all(color: const Color(0xFFE2E8F0)),
                              ),
                              child: _imageFile == null &&
                                      (widget.community['avatar_url'] == null ||
                                          widget
                                              .community['avatar_url'].isEmpty)
                                  ? const Icon(LucideIcons.camera,
                                      size: 32, color: Color(0xFF64748B))
                                  : null,
                            ),
                            const SizedBox(height: 8),
                            const Text(
                              'Ubah Ikon',
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
                            hintText: 'Nama komunitas',
                            filled: true,
                            fillColor: const Color(0xFFF8FAFC),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                              borderSide:
                                  const BorderSide(color: Color(0xFFE2E8F0)),
                            ),
                          ),
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
                          maxLines: 4,
                          decoration: InputDecoration(
                            hintText: 'Deskripsi komunitas',
                            filled: true,
                            fillColor: const Color(0xFFF8FAFC),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                              borderSide:
                                  const BorderSide(color: Color(0xFFE2E8F0)),
                            ),
                          ),
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
                          width: double.infinity,
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
                              hint: const Text('Pilih kategori'),
                              items: _categories.map((category) {
                                return DropdownMenuItem<String>(
                                  value: category,
                                  child: Text(category),
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
                            hintText: 'Lokasi',
                            filled: true,
                            fillColor: const Color(0xFFF8FAFC),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                              borderSide:
                                  const BorderSide(color: Color(0xFFE2E8F0)),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 24),

              // Save Button
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: _isLoading ? null : _submitChanges,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF059669),
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  icon: _isLoading
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            valueColor:
                                AlwaysStoppedAnimation<Color>(Colors.white),
                          ),
                        )
                      : const Icon(LucideIcons.save, size: 20),
                  label: Text(
                    _isLoading ? 'Menyimpan...' : 'Simpan Perubahan',
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),

              const SizedBox(height: 40),
            ],
          ),
        ),
      ),
    );
  }
}
