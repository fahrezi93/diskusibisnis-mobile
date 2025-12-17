import 'package:flutter/material.dart';
import 'package:lucide_icons/lucide_icons.dart';
import '../models/tag.dart' as tag_model;
import '../services/api_service.dart';
import 'tag_detail_screen.dart';

class TagsScreen extends StatefulWidget {
  const TagsScreen({super.key});

  @override
  State<TagsScreen> createState() => _TagsScreenState();
}

class _TagsScreenState extends State<TagsScreen> {
  final ApiService _apiService = ApiService();
  List<tag_model.TopicTag> _tags = [];
  List<tag_model.TopicTag> _filteredTags = [];
  bool _isLoading = true;
  String _searchQuery = '';
  String _sortBy = 'popular'; // popular or name

  @override
  void initState() {
    super.initState();
    _loadTags();
  }

  Future<void> _loadTags() async {
    setState(() => _isLoading = true);
    try {
      final data = await _apiService.getTags();
      setState(() {
        _tags = data;
        _filterTags();
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
    }
  }

  void _filterTags() {
    setState(() {
      var result = _tags.where((t) {
        return t.name.toLowerCase().contains(_searchQuery.toLowerCase()) ||
            (t.description
                    ?.toLowerCase()
                    .contains(_searchQuery.toLowerCase()) ??
                false);
      }).toList();

      if (_sortBy == 'name') {
        result.sort((a, b) => a.name.compareTo(b.name));
      } else {
        result.sort((a, b) => b.count.compareTo(a.count)); // Descending count
      }

      _filteredTags = result;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(
        title: const Text('Topik / Tag',
            style: TextStyle(
                color: Color(0xFF0F172A), fontWeight: FontWeight.bold)),
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(LucideIcons.arrowLeft, color: Color(0xFF0F172A)),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: SingleChildScrollView(
        child: Column(
          children: [
            // Header
            Container(
              color: Colors.white,
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
              child: const Column(
                children: [
                  Row(
                    children: [
                      Icon(LucideIcons.hash,
                          size: 24, color: Color(0xFF059669)),
                      SizedBox(width: 8),
                      Text('Tags',
                          style: TextStyle(
                              fontSize: 24,
                              fontWeight: FontWeight.bold,
                              color: Color(0xFF0F172A))),
                    ],
                  ),
                  SizedBox(height: 8),
                  Text('Jelajahi pertanyaan berdasarkan kategori bisnis',
                      style: TextStyle(color: Color(0xFF64748B))),
                ],
              ),
            ),

            // Search & Filters
            Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: TextField(
                          onChanged: (val) {
                            _searchQuery = val;
                            _filterTags();
                          },
                          decoration: InputDecoration(
                            hintText: 'Cari topik bisnis...',
                            prefixIcon: const Icon(LucideIcons.search,
                                size: 20, color: Color(0xFF94A3B8)),
                            filled: true,
                            fillColor: Colors.white,
                            border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12),
                                borderSide:
                                    const BorderSide(color: Color(0xFFE2E8F0))),
                            enabledBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12),
                                borderSide:
                                    const BorderSide(color: Color(0xFFE2E8F0))),
                            contentPadding:
                                const EdgeInsets.symmetric(vertical: 0),
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      _buildSortButton(
                          'Populer', 'popular', LucideIcons.trendingUp),
                      const SizedBox(width: 8),
                      _buildSortButton('Nama', 'name', LucideIcons.hash),
                    ],
                  ),
                ],
              ),
            ),

            // Grid
            if (_isLoading)
              const Center(
                  child: CircularProgressIndicator(color: Color(0xFF059669)))
            else if (_filteredTags.isEmpty)
              const Padding(
                padding: EdgeInsets.all(32),
                child: Center(child: Text('Tidak ada tag ditemukan')),
              )
            else
              GridView.builder(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 2,
                  childAspectRatio: 0.85,
                  crossAxisSpacing: 16,
                  mainAxisSpacing: 16,
                ),
                itemCount: _filteredTags.length,
                itemBuilder: (context, index) {
                  final tag = _filteredTags[index];
                  return GestureDetector(
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => TagDetailScreen(tag: tag),
                        ),
                      );
                    },
                    child: Container(
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: const Color(0xFFE2E8F0)),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(
                                0.02), // Fixed withValues to withOpacity
                            blurRadius: 4,
                            offset: const Offset(0, 2),
                          )
                        ],
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Padding(
                            padding: const EdgeInsets.all(12),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 8, vertical: 4),
                                  decoration: BoxDecoration(
                                    color: const Color(0xFFEFF6FF),
                                    borderRadius: BorderRadius.circular(6),
                                  ),
                                  child: Text(
                                    '#${tag.name}',
                                    style: const TextStyle(
                                      fontSize: 12,
                                      fontWeight: FontWeight.bold,
                                      color: Color(0xFF2563EB),
                                    ),
                                  ),
                                ),
                                const SizedBox(height: 8),
                                Text(
                                  tag.description ??
                                      'Diskusi seputar ${tag.name}',
                                  style: const TextStyle(
                                    fontSize: 11,
                                    color: Color(0xFF64748B),
                                    height: 1.4,
                                  ),
                                  maxLines: 2,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ],
                            ),
                          ),
                          Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 12, vertical: 10),
                            decoration: const BoxDecoration(
                              border: Border(
                                  top: BorderSide(color: Color(0xFFF1F5F9))),
                            ),
                            child: Row(
                              children: [
                                const Icon(LucideIcons.messageSquare,
                                    size: 12, color: Color(0xFF94A3B8)),
                                const SizedBox(width: 4),
                                Text(
                                  '${tag.count} diskusi',
                                  style: const TextStyle(
                                    fontSize: 10,
                                    color: Color(0xFF64748B),
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                },
              ),

            // Info Box
            Container(
              margin: const EdgeInsets.all(16),
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [Color(0xFF064E3B), Color(0xFF115E59)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(16),
              ),
              child: const Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(LucideIcons.tag, color: Color(0xFF6EE7B7)),
                      SizedBox(width: 12),
                      Text('Tips Menggunakan Tag',
                          style: TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                              fontSize: 18)),
                    ],
                  ),
                  SizedBox(height: 16),
                  _TipItem('Relevansi', 'Pilih tag yang paling sesuai.'),
                  SizedBox(height: 12),
                  _TipItem(
                      'Eksplorasi', 'Klik tag untuk melihat diskusi serupa.'),
                ],
              ),
            ),
            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }

  Widget _buildSortButton(String label, String value, IconData icon) {
    final isSelected = _sortBy == value;
    return Expanded(
      child: GestureDetector(
        onTap: () => setState(() {
          _sortBy = value;
          _filterTags();
        }),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 12),
          decoration: BoxDecoration(
            color: isSelected ? const Color(0xFF059669) : Colors.white,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
                color: isSelected
                    ? const Color(0xFF059669)
                    : const Color(0xFFE2E8F0)),
            boxShadow: isSelected
                ? [
                    BoxShadow(
                        color: const Color(0xFF059669).withOpacity(0.2),
                        blurRadius: 8,
                        offset: const Offset(0, 4))
                  ]
                : [],
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon,
                  size: 16,
                  color: isSelected ? Colors.white : const Color(0xFF64748B)),
              const SizedBox(width: 8),
              Text(label,
                  style: TextStyle(
                      fontWeight: FontWeight.bold,
                      color:
                          isSelected ? Colors.white : const Color(0xFF64748B))),
            ],
          ),
        ),
      ),
    );
  }
}

class _TipItem extends StatelessWidget {
  final String title;
  final String desc;
  const _TipItem(this.title, this.desc);

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(title,
            style: const TextStyle(
                color: Color(0xFF6EE7B7),
                fontWeight: FontWeight.bold,
                fontSize: 14)),
        Text(desc,
            style: const TextStyle(color: Color(0xFFD1FAE5), fontSize: 12)),
      ],
    );
  }
}
