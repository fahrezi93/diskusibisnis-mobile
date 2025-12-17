class Answer {
  final String id;
  final String content;
  final int upvotesCount;
  final bool isAccepted;
  final String questionId;
  final String questionTitle;
  final DateTime createdAt;

  Answer({
    required this.id,
    required this.content,
    required this.upvotesCount,
    required this.isAccepted,
    required this.questionId,
    required this.questionTitle,
    required this.createdAt,
  });

  factory Answer.fromJson(Map<String, dynamic> json) {
    return Answer(
      id: json['id']?.toString() ?? '',
      content: json['content'] ?? '',
      upvotesCount: _parseInt(
          json['upvotes'] ?? json['upvotes_count'] ?? json['upvotesCount']),
      isAccepted: json['is_accepted'] == true || json['isAccepted'] == true,
      questionId: json['question_id'] ?? json['questionId'] ?? '',
      questionTitle: json['question_title'] ?? json['questionTitle'] ?? '',
      createdAt: DateTime.parse(json['created_at'] ?? json['createdAt']),
    );
  }
}

int _parseInt(dynamic value) {
  if (value is int) return value;
  if (value is String) return int.tryParse(value) ?? 0;
  return 0;
}
