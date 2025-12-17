import 'question.dart'; // For User model

class Comment {
  final String id;
  final String content;
  final User author;
  final DateTime createdAt;

  Comment({
    required this.id,
    required this.content,
    required this.author,
    required this.createdAt,
  });

  factory Comment.fromJson(Map<String, dynamic> json) {
    return Comment(
      id: json['id']?.toString() ?? '',
      content: json['content'] ?? '',
      author: User.fromJson({
        'id': json['author_id'],
        'name': json['author_name'],
        'avatar': json['author_avatar'],
        'reputation': json['author_reputation'],
        'is_verified': json['author_is_verified'],
      }),
      createdAt: DateTime.tryParse(json['created_at'] ?? '') ?? DateTime.now(),
    );
  }
}
