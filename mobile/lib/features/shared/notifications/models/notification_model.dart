import 'package:flutter/material.dart';

class AppNotification {
  final int id;
  final String title;
  final String message;

  /// backend: createdAt (Notification.createdAt)
  final DateTime createdAt;

  /// backend: notification.type (GENERAL/SCHEDULE/BOOKING/ALERT)
  final String type;

  /// backend: NotificationRecipient.isRead
  final bool isRead;

  /// backend: NotificationRecipient.deliveredAt
  final DateTime? deliveredAt;

  final String ward;

  AppNotification({
    required this.id,
    required this.title,
    required this.message,
    required this.createdAt,
    required this.type,
    required this.isRead,
    required this.deliveredAt,
    required this.ward,
  });

  bool get isUnread => !isRead;

  IconData get icon {
    switch (type.toUpperCase()) {
      case "BOOKING":
        return Icons.local_shipping_outlined;
      case "SCHEDULE":
        return Icons.calendar_month_outlined;
      case "ALERT":
        return Icons.warning_amber_rounded;
      case "GENERAL":
      default:
        return Icons.notifications_outlined;
    }
  }

  Color get iconColor {
    switch (type.toUpperCase()) {
      case "BOOKING":
        return Colors.green;
      case "SCHEDULE":
        return Colors.blue;
      case "ALERT":
        return Colors.orange;
      case "GENERAL":
      default:
        return Colors.blueGrey;
    }
  }

  factory AppNotification.fromJson(Map<String, dynamic> json) {
    DateTime? parseDt(dynamic v) {
      if (v == null) return null;
      return DateTime.tryParse(v.toString());
    }

    final created = parseDt(json['createdAt']) ?? DateTime.now();
    final delivered = parseDt(json['deliveredAt']);

    return AppNotification(
      id: (json['id'] is int)
          ? json['id'] as int
          : int.tryParse(json['id'].toString()) ?? 0,
      title: (json['title'] ?? '').toString(),
      message: (json['message'] ?? '').toString(),
      createdAt: created.toLocal(),
      deliveredAt: delivered?.toLocal(),
      type: (json['type'] ?? 'GENERAL').toString(),
      isRead: (json['isRead'] == true),
      ward: (json['ward'] ?? json['wardName'] ?? '').toString(),
    );
  }

  AppNotification copyWith({
    int? id,
    String? title,
    String? message,
    DateTime? createdAt,
    String? type,
    bool? isRead,
    DateTime? deliveredAt,
    String? ward,
  }) {
    return AppNotification(
      id: id ?? this.id,
      title: title ?? this.title,
      message: message ?? this.message,
      createdAt: createdAt ?? this.createdAt,
      type: type ?? this.type,
      isRead: isRead ?? this.isRead,
      deliveredAt: deliveredAt ?? this.deliveredAt,
      ward: ward ?? this.ward,
    );
  }
}
