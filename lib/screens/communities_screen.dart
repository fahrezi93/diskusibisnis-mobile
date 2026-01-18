import 'package:flutter/material.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../models/community.dart';
import '../services/api_service.dart';
import '../widgets/skeleton_loading.dart';
import 'community_detail_screen.dart';
import 'create_community_screen.dart';

class CommunitiesScreen extends StatefulWidget {
  const CommunitiesScreen({super.key});

  @override
  State<CommunitiesScreen> createState() => _CommunitiesScreenState();
}

class _CommunitiesScreenState extends State<CommunitiesScreen> {
  final ApiService _apiService = ApiService();
  List<Community> _communities = [];
  List<Community> _filteredCommunities = [];
  bool _isLoading = true;
  String _searchQuery = '';
  String _selectedCategory = 'Semua';

  final List<String> _categories = [
    'Semua',
    'Regional',
    'Marketing',
    'Industri',
    'Perdagangan',
    'Teknologi',
  ];

  @override
  void initState() {
    super.initState();
    _loadCommunities();
  }

  Future<void> _loadCommunities() async {
    setState(() => _isLoading = true);
    try {
      final data = await _apiService.getCommunities();
      setState(() {
        _communities = data;
        _filterCommunities();
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
    }
  }

  void _filterCommunities() {
    setState(() {
      _filteredCommunities = _communities.filter((c) {
        final matchesSearch = c.name
                .toLowerCase()
                .contains(_searchQuery.toLowerCase()) ||
            c.description.toLowerCase().contains(_searchQuery.toLowerCase());
        final matchesCategory =
            _selectedCategory == 'Semua' || c.category == _selectedCategory;
        return matchesSearch && matchesCategory;
      }).toList();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: const Text('Komunitas',
            style: TextStyle(
                color: Color(0xFF0F172A), fontWeight: FontWeight.bold)),
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(LucideIcons.arrowLeft, color: Color(0xFF0F172A)),
          onPressed: () => Navigator.pop(context),
        ),
        actions: [
          IconButton(
            icon: const Icon(LucideIcons.plus, color: Color(0xFF059669)),
            onPressed: () async {
              final result = await Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => const CreateCommunityScreen(),
                ),
              );
              if (result == true) {
                _loadCommunities(); // Reload if community was created
              }
            },
          ),
        ],
      ),
      body: Column(
        children: [
          // Search & Filter
          Container(
            padding: const EdgeInsets.all(16),
            color: const Color(0xFFF8FAFC),
            child: Column(
              children: [
                TextField(
                  onChanged: (val) {
                    _searchQuery = val;
                    _filterCommunities();
                  },
                  decoration: InputDecoration(
                    hintText: 'Cari komunitas...',
                    prefixIcon: const Icon(LucideIcons.search,
                        size: 20, color: Color(0xFF94A3B8)),
                    filled: true,
                    fillColor: Colors.white,
                    contentPadding: const EdgeInsets.symmetric(vertical: 0),
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
                  ),
                ),
                const SizedBox(height: 12),
                SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Row(
                    children: _categories.map((category) {
                      final isSelected = _selectedCategory == category;
                      return Padding(
                        padding: const EdgeInsets.only(right: 8),
                        child: FilterChip(
                          label: Text(category),
                          selected: isSelected,
                          onSelected: (val) {
                            setState(() {
                              _selectedCategory = category;
                              _filterCommunities();
                            });
                          },
                          backgroundColor: Colors.white,
                          selectedColor: const Color(0xFF059669),
                          labelStyle: TextStyle(
                            color: isSelected
                                ? Colors.white
                                : const Color(0xFF64748B),
                            fontWeight: isSelected
                                ? FontWeight.bold
                                : FontWeight.normal,
                          ),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8),
                            side: BorderSide(
                              color: isSelected
                                  ? Colors.transparent
                                  : const Color(0xFFE2E8F0),
                            ),
                          ),
                          showCheckmark: false,
                        ),
                      );
                    }).toList(),
                  ),
                ),
              ],
            ),
          ),

          // Content
          Expanded(
            child: _isLoading
                ? ListView.separated(
                    padding: const EdgeInsets.all(16),
                    itemCount: 5,
                    separatorBuilder: (_, __) => const SizedBox(height: 16),
                    itemBuilder: (context, index) =>
                        const CommunityCardSkeleton(),
                  )
                : _filteredCommunities.isEmpty
                    ? _buildEmptyState()
                    : ListView.separated(
                        padding: const EdgeInsets.all(16),
                        itemCount: _filteredCommunities.length,
                        separatorBuilder: (_, __) => const SizedBox(height: 16),
                        itemBuilder: (context, index) {
                          return GestureDetector(
                            onTap: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (context) => CommunityDetailScreen(
                                      slug: _filteredCommunities[index].slug),
                                ),
                              );
                            },
                            child: _buildCommunityCard(
                                _filteredCommunities[index]),
                          );
                        },
                      ),
          ),
        ],
      ),
    );
  }

  Widget _buildCommunityCard(Community community) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: const Color(0xFF059669),
              borderRadius: BorderRadius.circular(8),
            ),
            alignment: Alignment.center,
            child:
                community.avatarUrl != null && community.avatarUrl!.isNotEmpty
                    ? ClipRRect(
                        borderRadius: BorderRadius.circular(8),
                        child: CachedNetworkImage(
                          imageUrl: community.avatarUrl!,
                          width: 48,
                          height: 48,
                          fit: BoxFit.cover,
                          memCacheHeight: 144,
                          memCacheWidth: 144,
                          maxWidthDiskCache: 200,
                          placeholder: (context, url) => const Center(
                            child: SizedBox(
                              width: 16,
                              height: 16,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                color: Colors.white,
                              ),
                            ),
                          ),
                          errorWidget: (context, url, error) => Text(
                            community.name.isNotEmpty
                                ? community.name[0].toUpperCase()
                                : 'C',
                            style: const TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.bold,
                                fontSize: 20),
                          ),
                        ),
                      )
                    : Text(
                        community.name.isNotEmpty
                            ? community.name[0].toUpperCase()
                            : 'C',
                        style: const TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                            fontSize: 20),
                      ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        community.name,
                        style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
                            color: Color(0xFF0F172A)),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    if (community.isPopular)
                      Container(
                        margin: const EdgeInsets.only(left: 8),
                        padding: const EdgeInsets.symmetric(
                            horizontal: 6, vertical: 2),
                        decoration: BoxDecoration(
                          color: const Color(0xFFFEF9C3),
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: const Text('Populer',
                            style: TextStyle(
                                fontSize: 10,
                                fontWeight: FontWeight.bold,
                                color: Color(0xFFA16207))),
                      ),
                  ],
                ),
                const SizedBox(height: 4),
                Text(
                  community.description,
                  style:
                      const TextStyle(fontSize: 12, color: Color(0xFF64748B)),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    _buildMeta(
                        LucideIcons.users, _formatCount(community.memberCount)),
                    const SizedBox(width: 12),
                    _buildMeta(LucideIcons.messageSquare,
                        '${community.questionCount}'),
                    const Spacer(),
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: const Color(0xFFF1F5F9),
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: Text(
                        community.category,
                        style: const TextStyle(
                            fontSize: 10,
                            fontWeight: FontWeight.w600,
                            color: Color(0xFF475569)),
                      ),
                    ),
                  ],
                )
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMeta(IconData icon, String label) {
    return Row(
      children: [
        Icon(icon, size: 12, color: const Color(0xFF94A3B8)),
        const SizedBox(width: 4),
        Text(label,
            style: const TextStyle(fontSize: 12, color: Color(0xFF64748B))),
      ],
    );
  }

  Widget _buildEmptyState() {
    return const Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(LucideIcons.search, size: 48, color: Color(0xFFCBD5E1)),
          SizedBox(height: 16),
          Text('Tidak ada komunitas',
              style: TextStyle(
                  fontWeight: FontWeight.bold, color: Color(0xFF64748B))),
        ],
      ),
    );
  }

  String _formatCount(int count) {
    if (count >= 1000) {
      return '${(count / 1000).toStringAsFixed(1)}k';
    }
    return count.toString();
  }
}

extension ListFilter<T> on List<T> {
  List<T> filter(bool Function(T) test) {
    List<T> result = [];
    for (var element in this) {
      if (test(element)) {
        result.add(element);
      }
    }
    return result;
  }
}
