class Notification {
  final String id;
  final String title;
  final String message;
  final bool isRead;
  final String type;
  final DateTime createdAt;
  final String? link;

  Notification({
    required this.id,
    required this.title,
    required this.message,
    required this.isRead,
    required this.type,
    required this.createdAt,
    this.link,
  });

  factory Notification.fromJson(Map<String, dynamic> json) {
    // Handle created_at safely
    DateTime parsedCreatedAt;
    final createdAtValue = json['created_at'] ?? json['createdAt'];
    if (createdAtValue != null && createdAtValue is String) {
      parsedCreatedAt = DateTime.tryParse(createdAtValue) ?? DateTime.now();
    } else {
      parsedCreatedAt = DateTime.now();
    }

    return Notification(
      id: json['id']?.toString() ?? '',
      title: json['title']?.toString() ?? 'Notifikasi',
      message: json['message']?.toString() ?? '',
      isRead: json['is_read'] == true || json['isRead'] == true,
      type: json['type']?.toString() ?? 'system',
      createdAt: parsedCreatedAt,
      link: json['link']?.toString(),
    );
  }
}
