import '../config/app_config.dart';

class Question {
  final String id;
  final String title;
  final String content;
  final String plainContent; // Optimized for preview
  final String? firstImage; // Derived from images[0]
  final User author;
  final int upvotesCount;
  final int answersCount;
  final int viewsCount;
  final bool hasAcceptedAnswer;
  final List<Tag> tags;
  final DateTime createdAt;

  Question({
    required this.id,
    required this.title,
    required this.content,
    required this.plainContent,
    this.firstImage,
    required this.author,
    required this.upvotesCount,
    required this.answersCount,
    required this.viewsCount,
    required this.hasAcceptedAnswer,
    required this.tags,
    required this.createdAt,
  });

  factory Question.fromJson(Map<String, dynamic> json) {
    var tagsList =
        (json['tags'] as List? ?? []).map((t) => Tag.fromJson(t)).toList();
    var images = json['images'] as List?;
    String? firstImg = (images != null && images.isNotEmpty) ? images[0] : null;

    // Normalize firstImage URL
    if (firstImg != null &&
        firstImg.isNotEmpty &&
        !firstImg.startsWith('http') &&
        !firstImg.startsWith('data:')) {
      firstImg = '${AppConfig.baseUrl}$firstImg';
    }

    final String rawContent = json['content'] ?? '';
    // Strip HTML tags for preview performance
    final String strippedContent = rawContent
        .replaceAll(RegExp(r'<[^>]*>'), '')
        .replaceAll(RegExp(r'\s+'), ' ')
        .trim();

    return Question(
      id: json['id']?.toString() ?? '',
      title: json['title'] ?? 'No Title',
      content: rawContent,
      plainContent: strippedContent,
      firstImage: firstImg,
      author: _parseAuthor(json),
      upvotesCount: _parseInt(json['upvotes_count']),
      answersCount: _parseInt(json['answers_count']),
      viewsCount: _parseInt(json['views_count']),
      hasAcceptedAnswer: json['has_accepted_answer'] == true ||
          json['has_accepted_answer'] == 'true',
      tags: tagsList,
      createdAt: DateTime.tryParse(json['created_at'] ?? '') ?? DateTime.now(),
    );
  }

  static User _parseAuthor(Map<String, dynamic> json) {
    if (json['user'] is Map) {
      return User.fromJson(json['user']);
    } else if (json['author'] is Map) {
      return User.fromJson(json['author']);
    } else {
      return User.fromJson({
        'id': json['author_id'],
        'name': json['author_name'],
        'avatar': json['author_avatar'],
        'reputation': json['author_reputation'],
        'is_verified': json['author_is_verified'],
      });
    }
  }
}

class User {
  final String? id;
  final String name;
  final String avatar;
  final int reputation;
  final bool isVerified;

  User({
    this.id,
    required this.name,
    required this.avatar,
    required this.reputation,
    required this.isVerified,
  });

  factory User.fromJson(Map<String, dynamic> json) {
    // Normalize avatar URL - prepend base URL if it's a relative path
    String avatarUrl = json['avatar'] ?? '';
    if (avatarUrl.isNotEmpty &&
        !avatarUrl.startsWith('http') &&
        !avatarUrl.startsWith('data:')) {
      avatarUrl = '${AppConfig.baseUrl}$avatarUrl';
    }

    return User(
      id: json['id']?.toString(),
      name: json['name'] ?? 'Unknown',
      avatar: avatarUrl,
      reputation: _parseInt(json['reputation']),
      isVerified: json['is_verified'] == true || json['is_verified'] == 'true',
    );
  }
}

class Tag {
  final String id;
  final String name;
  final String slug;

  Tag({required this.id, required this.name, required this.slug});

  factory Tag.fromJson(Map<String, dynamic> json) {
    return Tag(
      id: json['id']?.toString() ?? '',
      name: json['name'] ?? '',
      slug: json['slug'] ?? '',
    );
  }
}

int _parseInt(dynamic value) {
  if (value is int) return value;
  if (value is String) return int.tryParse(value) ?? 0;
  return 0;
}
