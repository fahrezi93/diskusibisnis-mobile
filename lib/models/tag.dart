class TopicTag {
  final String id;
  final String name;
  final String slug;
  final String? description;
  final int count;

  TopicTag({
    required this.id,
    required this.name,
    required this.slug,
    this.description,
    required this.count,
  });

  factory TopicTag.fromJson(Map<String, dynamic> json) {
    return TopicTag(
      id: json['id']?.toString() ?? '',
      name: json['name'] ?? '',
      slug: json['slug'] ?? '',
      description: json['description'],
      count: int.tryParse(json['usage_count']?.toString() ??
              json['questions_count']?.toString() ??
              '0') ??
          0,
    );
  }
}
