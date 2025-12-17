class Community {
  final String id;
  final String name;
  final String slug;
  final String description;
  final int memberCount;
  final int questionCount;
  final String category;
  final String? location;
  final bool isPopular;
  final String? avatarUrl;
  final DateTime createdAt;
  final String? createdBy;
  final bool? isMember;
  final String? userRole;

  Community({
    required this.id,
    required this.name,
    required this.slug,
    required this.description,
    required this.memberCount,
    required this.questionCount,
    required this.category,
    this.location,
    this.isPopular = false,
    this.avatarUrl,
    required this.createdAt,
    this.createdBy,
    this.isMember,
    this.userRole,
  });

  factory Community.fromJson(Map<String, dynamic> json) {
    return Community(
      id: json['id']?.toString() ?? '',
      name: json['name'] ?? '',
      slug: json['slug'] ?? '',
      description: json['description'] ?? '',
      memberCount: int.tryParse(json['member_count']?.toString() ?? '0') ??
          int.tryParse(json['members_count']?.toString() ?? '0') ??
          0,
      questionCount:
          int.tryParse(json['question_count']?.toString() ?? '0') ?? 0,
      category: json['category'] ?? 'General',
      location: json['location'],
      isPopular: json['is_popular'] ?? false,
      avatarUrl: json['avatar_url'],
      createdAt: DateTime.tryParse(json['created_at'] ?? '') ?? DateTime.now(),
      createdBy: json['created_by']?.toString(),
      isMember: json['is_member'],
      userRole: json['user_role'],
    );
  }
}
