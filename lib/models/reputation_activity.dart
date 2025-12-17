class ReputationActivity {
  final String id;
  final String type;
  final int points;
  final String description;
  final DateTime date;
  final String? questionTitle;
  final String? questionId;

  ReputationActivity({
    required this.id,
    required this.type,
    required this.points,
    required this.description,
    required this.date,
    this.questionTitle,
    this.questionId,
  });

  factory ReputationActivity.fromJson(Map<String, dynamic> json) {
    return ReputationActivity(
      id: json['id']?.toString() ?? '',
      type: json['type'] ?? '',
      points: int.tryParse(json['points']?.toString() ?? '0') ?? 0,
      description: json['description'] ?? '',
      date: DateTime.tryParse(json['date'] ?? '') ?? DateTime.now(),
      questionTitle: json['questionTitle'],
      questionId: json['questionId'],
    );
  }
}
