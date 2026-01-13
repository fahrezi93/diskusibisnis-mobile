  import 'dart:io';
import 'package:flutter/material.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:image_picker/image_picker.dart';
import '../services/api_service.dart';
import '../services/auth_service.dart';
import '../services/supabase_service.dart';
import '../models/user_profile.dart';
import '../utils/avatar_helper.dart';
import 'question_detail_screen.dart';

class AskQuestionScreen extends StatefulWidget {
  final String? communitySlug;

  const AskQuestionScreen({super.key, this.communitySlug});

  @override
  State<AskQuestionScreen> createState() => _AskQuestionScreenState();
}

class _AskQuestionScreenState extends State<AskQuestionScreen> {
  final ApiService _api = ApiService();
  final AuthService _auth = AuthService();

  final TextEditingController _titleController = TextEditingController();
  final TextEditingController _contentController = TextEditingController();
  final TextEditingController _tagController = TextEditingController();
  final FocusNode _contentFocusNode = FocusNode();

  final List<String> _selectedTags = [];
  final List<String> _suggestedTags = [
    'marketing',
    'keuangan',
    'legalitas',
    'operasional',
    'digital',
    'supply-chain',
    'sdm',
    'ekspansi',
  ];

  // Image upload
  final ImagePicker _imagePicker = ImagePicker();
  final List<XFile> _selectedImages = [];
  final List<String> _uploadedImageUrls = [];
  bool _isUploadingImages = false;

  // User mention
  bool _showMentionSuggestions = false;
  String _mentionQuery = '';
  List<UserProfile> _mentionSuggestions = [];
  int _mentionStartIndex = -1;
  final ScrollController _scrollController = ScrollController();

  bool _isLoading = false;
  bool _isInitializing = true;
  String _error = '';

  @override
  void initState() {
    super.initState();
    _initAuth();
    _contentController.addListener(_onContentChanged);
    _scrollController.addListener(_onScroll);
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
    _titleController.dispose();
    _contentController.dispose();
    _tagController.dispose();
    _contentFocusNode.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  void _onScroll() {
    // Hide mention suggestions when scrolling
    if (_showMentionSuggestions) {
      setState(() {
        _showMentionSuggestions = false;
      });
    }
  }

  // Content change listener for @mention detection
  void _onContentChanged() {
    final text = _contentController.text;
    final selection = _contentController.selection;

    // Check if selection is valid
    if (!selection.isValid) {
      if (_showMentionSuggestions) {
        setState(() => _showMentionSuggestions = false);
      }
      return;
    }

    if (selection.baseOffset != selection.extentOffset) {
      // Text is selected, don't show mentions
      if (_showMentionSuggestions) {
        setState(() => _showMentionSuggestions = false);
      }
      return;
    }

    final cursorPos = selection.baseOffset;
    if (cursorPos <= 0 || cursorPos > text.length) {
      if (_showMentionSuggestions) {
        setState(() => _showMentionSuggestions = false);
      }
      return;
    }

    // Find @ symbol before cursor
    final textBeforeCursor = text.substring(0, cursorPos);
    final lastAtIndex = textBeforeCursor.lastIndexOf('@');

    if (lastAtIndex == -1) {
      if (_showMentionSuggestions) {
        setState(() => _showMentionSuggestions = false);
      }
      return;
    }

    // Check if there's a space or newline between @ and cursor
    final textAfterAt = textBeforeCursor.substring(lastAtIndex + 1);
    if (textAfterAt.contains(' ') || textAfterAt.contains('\n')) {
      if (_showMentionSuggestions) {
        setState(() => _showMentionSuggestions = false);
      }
      return;
    }

    // Check if @ is at start or preceded by space/newline
    if (lastAtIndex > 0) {
      final charBefore = textBeforeCursor[lastAtIndex - 1];
      if (charBefore != ' ' && charBefore != '\n') {
        if (_showMentionSuggestions) {
          setState(() => _showMentionSuggestions = false);
        }
        return;
      }
    }

    // We have a valid mention query
    _mentionQuery = textAfterAt;
    _mentionStartIndex = lastAtIndex;

    print(
        '[Mention] Detected @ at index $lastAtIndex, query: "$_mentionQuery"');

    // Search users - even with empty query to show popular users
    _searchUsers(_mentionQuery);
  }

  Future<void> _searchUsers(String query) async {
    print('[Mention] Searching users for query: "$query"');

    try {
      // Use empty string or 'a' if query is empty to get some results
      final searchQuery = query.isEmpty ? '' : query;
      final users = await _api
          .searchUsersForMention(searchQuery.isEmpty ? 'a' : searchQuery);

      print('[Mention] Found ${users.length} users');

      if (mounted) {
        setState(() {
          _mentionSuggestions = users;
          _showMentionSuggestions = users.isNotEmpty;
        });
        print('[Mention] showMentionSuggestions: $_showMentionSuggestions');
      }
    } catch (e) {
      print('[Mention] Error searching users: $e');
    }
  }

  void _insertMention(UserProfile user) {
    final text = _contentController.text;
    final beforeMention = text.substring(0, _mentionStartIndex);
    final afterMention =
        text.substring(_contentController.selection.baseOffset);

    final username =
        user.username ?? user.displayName.toLowerCase().replaceAll(' ', '');
    final newText = '$beforeMention@$username $afterMention';
    _contentController.text = newText;

    // Move cursor after the mention
    final newCursorPos = _mentionStartIndex + username.length + 2;
    _contentController.selection =
        TextSelection.collapsed(offset: newCursorPos);

    setState(() {
      _showMentionSuggestions = false;
      _mentionSuggestions = [];
    });

    _contentFocusNode.requestFocus();
  }

  // Image picking
  Future<void> _pickImages() async {
    if (_selectedImages.length >= 4) {
      _showSnackBar('Maksimal 4 gambar');
      return;
    }

    try {
      final List<XFile> images = await _imagePicker.pickMultiImage(
        maxWidth: 1920,
        maxHeight: 1920,
        imageQuality: 85,
      );

      if (images.isNotEmpty) {
        final remaining = 4 - _selectedImages.length;
        final toAdd = images.take(remaining).toList();

        setState(() {
          _selectedImages.addAll(toAdd);
        });
      }
    } catch (e) {
      _showSnackBar('Gagal memilih gambar');
    }
  }

  Future<void> _takePhoto() async {
    if (_selectedImages.length >= 4) {
      _showSnackBar('Maksimal 4 gambar');
      return;
    }

    try {
      final XFile? image = await _imagePicker.pickImage(
        source: ImageSource.camera,
        maxWidth: 1920,
        maxHeight: 1920,
        imageQuality: 85,
      );

      if (image != null) {
        setState(() {
          _selectedImages.add(image);
        });
      }
    } catch (e) {
      _showSnackBar('Gagal mengambil foto');
    }
  }

  void _removeImage(int index) {
    setState(() {
      _selectedImages.removeAt(index);
      if (index < _uploadedImageUrls.length) {
        _uploadedImageUrls.removeAt(index);
      }
    });
  }

  Future<List<String>> _uploadImages() async {
    if (_selectedImages.isEmpty) return [];

    setState(() => _isUploadingImages = true);

    List<String> urls = [];
    try {
      final supabase = SupabaseService.instance;
      final userId = _auth.currentUser?.id ?? 'anonymous';

      print('[AskQuestion] Starting image upload. User ID: $userId');
      print(
          '[AskQuestion] Number of images to upload: ${_selectedImages.length}');

      for (int i = 0; i < _selectedImages.length; i++) {
        final image = _selectedImages[i];
        print('[AskQuestion] Uploading image ${i + 1}: ${image.path}');

        final url =
            await supabase.uploadQuestionImage(File(image.path), userId);
        urls.add(url);

        print('[AskQuestion] Image ${i + 1} uploaded. URL: $url');
      }

      print('[AskQuestion] All images uploaded. URLs: $urls');
    } catch (e) {
      print('[AskQuestion] ERROR uploading images: $e');
      _showSnackBar('Gagal mengupload gambar: $e');
    } finally {
      setState(() => _isUploadingImages = false);
    }

    return urls;
  }

  void _showSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        behavior: SnackBarBehavior.floating,
        backgroundColor: const Color(0xFF334155),
      ),
    );
  }

  void _toggleTag(String tag) {
    setState(() {
      if (_selectedTags.contains(tag)) {
        _selectedTags.remove(tag);
      } else {
        if (_selectedTags.length < 5) {
          _selectedTags.add(tag);
          _error = '';
        } else {
          _error = 'Maksimal 5 tag';
        }
      }
    });
  }

  void _addCustomTag() {
    final tag = _tagController.text.trim().toLowerCase();

    if (tag.isEmpty) {
      setState(() => _error = 'Tag tidak boleh kosong');
      return;
    }

    if (tag.length < 2) {
      setState(() => _error = 'Tag minimal 2 karakter');
      return;
    }

    if (tag.length > 20) {
      setState(() => _error = 'Tag maksimal 20 karakter');
      return;
    }

    if (_selectedTags.contains(tag)) {
      setState(() => _error = 'Tag sudah ada dalam daftar');
      return;
    }

    if (_selectedTags.length >= 5) {
      setState(() => _error = 'Maksimal 5 tag');
      return;
    }

    setState(() {
      _selectedTags.add(tag);
      _tagController.clear();
      _error = '';
    });
  }

  void _removeTag(String tag) {
    setState(() {
      _selectedTags.remove(tag);
    });
  }

  Future<void> _submitQuestion() async {
    if (!_auth.isAuthenticated) {
      setState(() => _error = 'Login diperlukan untuk membuat pertanyaan');
      return;
    }

    final title = _titleController.text.trim();
    final content = _contentController.text.trim();

    // Validasi
    if (title.length < 10) {
      setState(() => _error = 'Judul pertanyaan minimal 10 karakter');
      return;
    }

    if (content.length < 20) {
      setState(() => _error = 'Isi pertanyaan minimal 20 karakter');
      return;
    }

    if (_selectedTags.isEmpty) {
      setState(() => _error = 'Pilih minimal 1 tag');
      return;
    }

    setState(() {
      _isLoading = true;
      _error = '';
    });

    try {
      // Upload images first
      List<String> imageUrls = [];
      if (_selectedImages.isNotEmpty) {
        imageUrls = await _uploadImages();
        print('[AskQuestion] Image URLs to send: $imageUrls');
      }

      print('[AskQuestion] Creating question with ${imageUrls.length} images');
      print('[AskQuestion] Tags: $_selectedTags');

      final response = await _api.createQuestion(
        token: _auth.token!,
        title: title,
        content: content,
        tags: _selectedTags,
        images: imageUrls,
        communitySlug: widget.communitySlug,
      );

      print('[AskQuestion] Question created successfully: $response');

      if (mounted) {
        // Get question ID from response
        final questionId = response['question']?['id']?.toString() ??
            response['id']?.toString();

        if (questionId != null) {
          Navigator.of(context).pushReplacement(
            MaterialPageRoute(
              builder: (context) =>
                  QuestionDetailScreen(questionId: questionId),
            ),
          );
        } else {
          Navigator.of(context).pop();
        }
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
      return _buildLoginRequired();
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
          'Buat Pertanyaan',
          style: TextStyle(
            color: Color(0xFF0F172A),
            fontWeight: FontWeight.w600,
            fontSize: 16,
          ),
        ),
      ),
      body: Stack(
        children: [
          SingleChildScrollView(
            controller: _scrollController,
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildHeaderInfo(),
                  const SizedBox(height: 16),
                  if (_error.isNotEmpty) ...[
                    _buildErrorMessage(),
                    const SizedBox(height: 16),
                  ],
                  _buildForm(),
                  const SizedBox(height: 16),
                  _buildSubmitButtons(),
                  const SizedBox(height: 100),
                ],
              ),
            ),
          ),
          // Mention suggestions overlay
          if (_showMentionSuggestions) _buildMentionSuggestions(),
        ],
      ),
    );
  }

  Widget _buildLoginRequired() {
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
          'Buat Pertanyaan',
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
                  LucideIcons.logIn,
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
                'Silakan login untuk membuat pertanyaan',
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
                  padding:
                      const EdgeInsets.symmetric(horizontal: 32, vertical: 12),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: const Text(
                  'Kembali',
                  style: TextStyle(fontWeight: FontWeight.w600),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHeaderInfo() {
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
          const Row(
            children: [
              Icon(LucideIcons.helpCircle, size: 16, color: Color(0xFF059669)),
              SizedBox(width: 8),
              Text(
                'Formulir Pertanyaan',
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: Color(0xFF059669),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          const Text(
            'Tanyakan Masalah Bisnis Anda',
            style: TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.bold,
              color: Color(0xFF0F172A),
            ),
          ),
          const SizedBox(height: 8),
          const Text(
            'Jelaskan kendala secara spesifik agar komunitas bisa memberikan solusi terbaik.',
            style: TextStyle(
              fontSize: 13,
              color: Color(0xFF64748B),
              height: 1.5,
            ),
          ),
          if (widget.communitySlug != null) ...[
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: const Color(0xFFECFDF5),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: const Color(0xFFD1FAE5)),
              ),
              child: Row(
                children: [
                  const Text('📍', style: TextStyle(fontSize: 16)),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'Pertanyaan ini akan diposting di komunitas ${widget.communitySlug}',
                      style: const TextStyle(
                        fontSize: 12,
                        color: Color(0xFF059669),
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildErrorMessage() {
    return Container(
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
              style: const TextStyle(fontSize: 13, color: Color(0xFFDC2626)),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildForm() {
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
          // Title Field
          _buildTitleField(),
          const SizedBox(height: 20),

          // Content Field with mention support
          _buildContentField(),
          const SizedBox(height: 20),

          // Image Upload Section
          _buildImageSection(),
          const SizedBox(height: 20),

          // Tags Section
          _buildTagsSection(),
          const SizedBox(height: 20),

          // Tips
          _buildTips(),
        ],
      ),
    );
  }

  Widget _buildTitleField() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text(
              'Judul Pertanyaan *',
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: Color(0xFF334155),
              ),
            ),
            Text(
              '${_titleController.text.length}/10',
              style: TextStyle(
                fontSize: 11,
                color: _titleController.text.length < 10
                    ? const Color(0xFFDC2626)
                    : const Color(0xFF64748B),
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        TextField(
          controller: _titleController,
          onChanged: (_) => setState(() {}),
          decoration: InputDecoration(
            hintText:
                'Contoh: Strategi pemasaran digital untuk meningkatkan penjualan',
            hintStyle: const TextStyle(fontSize: 13, color: Color(0xFF94A3B8)),
            filled: true,
            fillColor: const Color(0xFFF8FAFC),
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
              borderSide: const BorderSide(color: Color(0xFF059669), width: 2),
            ),
            contentPadding: const EdgeInsets.all(16),
          ),
          maxLines: 2,
        ),
      ],
    );
  }

  Widget _buildContentField() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text(
              'Detail Pertanyaan *',
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: Color(0xFF334155),
              ),
            ),
            Text(
              '${_contentController.text.length}/20',
              style: TextStyle(
                fontSize: 11,
                color: _contentController.text.length < 20
                    ? const Color(0xFFDC2626)
                    : const Color(0xFF64748B),
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        TextField(
          controller: _contentController,
          focusNode: _contentFocusNode,
          onChanged: (_) => setState(() {}),
          decoration: InputDecoration(
            hintText:
                'Jelaskan latar belakang bisnis, masalah utama, dan solusi yang sudah dicoba...\n\nGunakan @ untuk mention pengguna lain',
            hintStyle: const TextStyle(fontSize: 13, color: Color(0xFF94A3B8)),
            filled: true,
            fillColor: const Color(0xFFF8FAFC),
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
              borderSide: const BorderSide(color: Color(0xFF059669), width: 2),
            ),
            contentPadding: const EdgeInsets.all(16),
          ),
          maxLines: 8,
        ),
        const SizedBox(height: 8),
        Row(
          children: [
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: const Color(0xFFF1F5F9),
                borderRadius: BorderRadius.circular(6),
              ),
              child: const Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(LucideIcons.atSign, size: 12, color: Color(0xFF64748B)),
                  SizedBox(width: 4),
                  Text(
                    'Ketik @ untuk mention',
                    style: TextStyle(fontSize: 11, color: Color(0xFF64748B)),
                  ),
                ],
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildImageSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text(
              'Gambar (Opsional)',
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: Color(0xFF334155),
              ),
            ),
            Text(
              '${_selectedImages.length}/4',
              style: const TextStyle(fontSize: 11, color: Color(0xFF64748B)),
            ),
          ],
        ),
        const SizedBox(height: 8),
        const Text(
          'Tambahkan gambar untuk memperjelas pertanyaan Anda',
          style: TextStyle(fontSize: 11, color: Color(0xFF64748B)),
        ),
        const SizedBox(height: 12),

        // Image Preview Grid
        if (_selectedImages.isNotEmpty) ...[
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: List.generate(_selectedImages.length, (index) {
              return Stack(
                children: [
                  Container(
                    width: 80,
                    height: 80,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: const Color(0xFFE2E8F0)),
                    ),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(11),
                      child: Image.file(
                        File(_selectedImages[index].path),
                        fit: BoxFit.cover,
                      ),
                    ),
                  ),
                  Positioned(
                    top: -4,
                    right: -4,
                    child: GestureDetector(
                      onTap: () => _removeImage(index),
                      child: Container(
                        padding: const EdgeInsets.all(4),
                        decoration: const BoxDecoration(
                          color: Color(0xFFDC2626),
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(LucideIcons.x,
                            size: 12, color: Colors.white),
                      ),
                    ),
                  ),
                ],
              );
            }),
          ),
          const SizedBox(height: 12),
        ],

        // Add Image Buttons
        Row(
          children: [
            Expanded(
              child: OutlinedButton.icon(
                onPressed: _selectedImages.length >= 4 ? null : _pickImages,
                icon: const Icon(LucideIcons.image, size: 16),
                label: const Text('Galeri'),
                style: OutlinedButton.styleFrom(
                  foregroundColor: const Color(0xFF059669),
                  side: const BorderSide(color: Color(0xFFE2E8F0)),
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: OutlinedButton.icon(
                onPressed: _selectedImages.length >= 4 ? null : _takePhoto,
                icon: const Icon(LucideIcons.camera, size: 16),
                label: const Text('Kamera'),
                style: OutlinedButton.styleFrom(
                  foregroundColor: const Color(0xFF059669),
                  side: const BorderSide(color: Color(0xFFE2E8F0)),
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildTagsSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text(
              'Tag *',
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: Color(0xFF334155),
              ),
            ),
            Text(
              '${_selectedTags.length}/5 tag',
              style: const TextStyle(fontSize: 11, color: Color(0xFF64748B)),
            ),
          ],
        ),
        const SizedBox(height: 12),

        // Selected tags
        if (_selectedTags.isNotEmpty) ...[
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: _selectedTags.map((tag) {
              return Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: const Color(0xFF059669),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(LucideIcons.tag, size: 12, color: Colors.white),
                    const SizedBox(width: 6),
                    Text(
                      tag,
                      style: const TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: Colors.white,
                      ),
                    ),
                    const SizedBox(width: 4),
                    GestureDetector(
                      onTap: () => _removeTag(tag),
                      child: Container(
                        padding: const EdgeInsets.all(2),
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.3),
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(LucideIcons.x,
                            size: 10, color: Colors.white),
                      ),
                    ),
                  ],
                ),
              );
            }).toList(),
          ),
          const SizedBox(height: 12),
        ],

        // Custom tag input
        Row(
          children: [
            Expanded(
              child: TextField(
                controller: _tagController,
                decoration: InputDecoration(
                  hintText: 'Ketik tag custom',
                  hintStyle:
                      const TextStyle(fontSize: 13, color: Color(0xFF94A3B8)),
                  filled: true,
                  fillColor: const Color(0xFFF8FAFC),
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
                    borderSide: const BorderSide(color: Color(0xFF059669)),
                  ),
                  contentPadding:
                      const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                ),
                onSubmitted: (_) => _addCustomTag(),
                enabled: _selectedTags.length < 5,
              ),
            ),
            const SizedBox(width: 8),
            ElevatedButton(
              onPressed:
                  _selectedTags.length < 5 && _tagController.text.isNotEmpty
                      ? _addCustomTag
                      : null,
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF059669),
                foregroundColor: Colors.white,
                disabledBackgroundColor: const Color(0xFFE2E8F0),
                padding:
                    const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                elevation: 0,
              ),
              child: const Text('Tambah',
                  style: TextStyle(fontWeight: FontWeight.w600)),
            ),
          ],
        ),
        const SizedBox(height: 12),

        // Suggested tags
        const Text(
          'Tag yang disarankan:',
          style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w600,
              color: Color(0xFF64748B)),
        ),
        const SizedBox(height: 8),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: _suggestedTags.map((tag) {
            final isSelected = _selectedTags.contains(tag);
            final isDisabled = !isSelected && _selectedTags.length >= 5;

            return GestureDetector(
              onTap: isDisabled ? null : () => _toggleTag(tag),
              child: Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: isSelected
                      ? const Color(0xFF059669)
                      : isDisabled
                          ? const Color(0xFFF1F5F9)
                          : Colors.white,
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(
                    color: isSelected
                        ? const Color(0xFF059669)
                        : const Color(0xFFE2E8F0),
                  ),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      LucideIcons.tag,
                      size: 12,
                      color: isSelected
                          ? Colors.white
                          : isDisabled
                              ? const Color(0xFFCBD5E1)
                              : const Color(0xFF64748B),
                    ),
                    const SizedBox(width: 6),
                    Text(
                      tag,
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: isSelected
                            ? Colors.white
                            : isDisabled
                                ? const Color(0xFFCBD5E1)
                                : const Color(0xFF64748B),
                      ),
                    ),
                  ],
                ),
              ),
            );
          }).toList(),
        ),
      ],
    );
  }

  Widget _buildTips() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFFECFDF5),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFD1FAE5)),
      ),
      child: const Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(LucideIcons.lightbulb, size: 20, color: Color(0xFF059669)),
          SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Tips Pertanyaan Berkualitas',
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                    color: Color(0xFF059669),
                  ),
                ),
                SizedBox(height: 6),
                Text(
                  '• Jelaskan masalah dengan spesifik dan detail\n'
                  '• Sertakan data atau angka pendukung jika ada\n'
                  '• Ceritakan apa yang sudah Anda coba\n'
                  '• Gunakan gambar untuk memperjelas masalah\n'
                  '• Mention pengguna ahli dengan @username',
                  style: TextStyle(
                    fontSize: 11,
                    color: Color(0xFF047857),
                    height: 1.5,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSubmitButtons() {
    return Row(
      children: [
        Expanded(
          child: OutlinedButton(
            onPressed: _isLoading ? null : () => Navigator.pop(context),
            style: OutlinedButton.styleFrom(
              foregroundColor: const Color(0xFF64748B),
              side: const BorderSide(color: Color(0xFFE2E8F0)),
              padding: const EdgeInsets.symmetric(vertical: 16),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            child: const Text('Batal',
                style: TextStyle(fontWeight: FontWeight.w600)),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          flex: 2,
          child: ElevatedButton(
            onPressed:
                _isLoading || _isUploadingImages ? null : _submitQuestion,
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
            child: _isLoading || _isUploadingImages
                ? Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const SizedBox(
                        height: 20,
                        width: 20,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          valueColor:
                              AlwaysStoppedAnimation<Color>(Colors.white),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Text(
                        _isUploadingImages ? 'Mengupload...' : 'Posting...',
                        style: const TextStyle(
                          fontWeight: FontWeight.w600,
                          color: Colors.white,
                        ),
                      ),
                    ],
                  )
                : const Text(
                    'Posting Pertanyaan',
                    style: TextStyle(fontWeight: FontWeight.w700, fontSize: 14),
                  ),
          ),
        ),
      ],
    );
  }

  Widget _buildMentionSuggestions() {
    // Calculate position - should appear just above keyboard
    final keyboardHeight = MediaQuery.of(context).viewInsets.bottom;

    // When keyboard is open, position just above it
    // NOTE: Since Scaffold.resizeToAvoidBottomInset is true, the body already resizes to be above keyboard.
    // So we don't need to add keyboardHeight to the bottom position, just a small padding.

    if (keyboardHeight == 0) {
      // Keyboard is closed, auto-hide
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted && _showMentionSuggestions) {
          setState(() => _showMentionSuggestions = false);
        }
      });
      return const SizedBox.shrink();
    }

    return Positioned(
      left: 16,
      right: 16,
      bottom:
          8, // Just 8px padding from the bottom of readability area (which is top of keyboard)
      child: Material(
        elevation: 12,
        borderRadius: BorderRadius.circular(12),
        shadowColor: Colors.black26,
        child: Container(
          constraints: const BoxConstraints(maxHeight: 250),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: const Color(0xFFE2E8F0), width: 1),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                decoration: const BoxDecoration(
                  color: Color(0xFFF8FAFC),
                  borderRadius: BorderRadius.vertical(top: Radius.circular(12)),
                ),
                child: Row(
                  children: [
                    const Icon(LucideIcons.atSign,
                        size: 14, color: Color(0xFF059669)),
                    const SizedBox(width: 8),
                    Text(
                      _mentionQuery.isEmpty
                          ? 'Pilih pengguna untuk di-mention'
                          : 'Hasil pencarian "$_mentionQuery"',
                      style: const TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: Color(0xFF64748B),
                      ),
                    ),
                  ],
                ),
              ),
              const Divider(height: 1),
              // User list
              Flexible(
                child: ListView.separated(
                  shrinkWrap: true,
                  padding: const EdgeInsets.symmetric(vertical: 4),
                  itemCount: _mentionSuggestions.length,
                  separatorBuilder: (_, __) =>
                      const Divider(height: 1, indent: 56),
                  itemBuilder: (context, index) {
                    final user = _mentionSuggestions[index];
                    return InkWell(
                      onTap: () => _insertMention(user),
                      child: Padding(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 16, vertical: 10),
                        child: Row(
                          children: [
                            AvatarHelper.buildAvatarWithBadge(
                              avatarUrl: user.avatarUrl,
                              name: user.displayName,
                              reputation: user.reputationPoints,
                              isVerified: user.isVerified,
                              radius: 18,
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    children: [
                                      Flexible(
                                        child: Text(
                                          user.displayName,
                                          style: const TextStyle(
                                            fontWeight: FontWeight.w600,
                                            fontSize: 14,
                                            color: Color(0xFF0F172A),
                                          ),
                                          overflow: TextOverflow.ellipsis,
                                        ),
                                      ),
                                      if (user.isVerified)
                                        AvatarHelper.getVerifiedBadge(size: 14),
                                    ],
                                  ),
                                  const SizedBox(height: 2),
                                  Text(
                                    '@${user.username ?? user.displayName.toLowerCase().replaceAll(' ', '')}',
                                    style: const TextStyle(
                                      fontSize: 12,
                                      color: Color(0xFF64748B),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 8, vertical: 4),
                              decoration: BoxDecoration(
                                color: const Color(0xFFECFDF5),
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Text(
                                '${user.reputationPoints} pts',
                                style: const TextStyle(
                                  fontSize: 11,
                                  color: Color(0xFF059669),
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
