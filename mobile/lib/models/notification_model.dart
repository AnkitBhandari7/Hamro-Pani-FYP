class AppNotification {
  final int id;
  final String ward;
  final String title;
  final String message;
  final DateTime createdAt;

  AppNotification({
    required this.id,
    required this.ward,
    required this.title,
    required this.message,
    required this.createdAt,
  });

  factory AppNotification.fromJson(Map<String, dynamic> json) {
    final createdRaw = json['createdAt']?.toString();

    return AppNotification(
      id: (json['id'] is int) ? json['id'] as int : int.tryParse(json['id'].toString()) ?? 0,
      ward: (json['ward'] ?? '').toString(),
      title: (json['title'] ?? '').toString(),
      message: (json['message'] ?? '').toString(),

      // Convert UTC timestamp string to local time

      createdAt: createdRaw == null
          ? DateTime.now()
          : DateTime.parse(createdRaw).toLocal(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'ward': ward,
      'title': title,
      'message': message,
      'createdAt': createdAt.toIso8601String(),
    };
  }

  @override
  String toString() {
    return 'AppNotification(id: $id, ward: $ward, title: $title, message: $message, createdAt: $createdAt)';
  }
}