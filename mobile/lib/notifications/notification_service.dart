import 'dart:convert';
import 'package:fyp/services/api_service.dart';
import 'package:fyp/notifications/notification_model.dart';

class NotificationService {
  static Future<List<AppNotification>> getNotifications() async {
    final response = await ApiService.get('/notifications');

    if (response.statusCode != 200) {
      throw Exception("Failed to load notifications (${response.statusCode}) ${response.body}");
    }

    final data = json.decode(response.body);
    if (data is! List) return [];

    return data.map<AppNotification>((raw) {
      final m = Map<String, dynamic>.from(raw as Map);


      if (m.containsKey('notification') && m['notification'] is Map) {
        final notif = Map<String, dynamic>.from(m['notification'] as Map);
        notif['isRead'] = m['isRead'] ?? false;
        notif['deliveredAt'] = m['deliveredAt'];
        return AppNotification.fromJson(notif);
      }

      return AppNotification.fromJson(m);
    }).toList();
  }

  /// Permanent mark read in db
  static Future<void> markAsRead(int notificationId) async {
    final res = await ApiService.patch('/notifications/$notificationId/read', {});
    if (res.statusCode != 200) {
      throw Exception("Failed to mark read: ${res.statusCode} ${res.body}");
    }
  }

  ///  Permanent mark all read in db
  static Future<void> markAllAsRead() async {
    final res = await ApiService.post('/notifications/mark-all-read', {});
    if (res.statusCode != 200) {
      throw Exception("Failed to mark all read: ${res.statusCode} ${res.body}");
    }
  }
}