import 'dart:convert';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:http/http.dart' as http;

import '../models/notification_model.dart';

class NotificationService {
  static const baseUrl = "http://10.0.2.2:3000";

  // Student note:
  // ERD backend returns list of recipient rows:
  // [{ isRead, deliveredAt, notification: {...} }]
  // We convert it to List<AppNotification> for UI.
  static Future<List<AppNotification>> getNotifications() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) throw Exception("User not logged in");

    final idToken = await user.getIdToken();

    final uri = Uri.parse("$baseUrl/notifications");

    final response = await http.get(
      uri,
      headers: {'Authorization': 'Bearer $idToken'},
    );

    if (response.statusCode != 200) {
      throw Exception("Failed to load notifications (${response.statusCode})");
    }

    final data = json.decode(response.body);

    if (data is! List) return [];

    return data.map<AppNotification>((raw) {
      final m = raw as Map<String, dynamic>;

      // If ERD format, notification is inside "notification"
      if (m.containsKey('notification') && m['notification'] is Map) {
        final notif = Map<String, dynamic>.from(m['notification'] as Map);

        // Optional: attach isRead/deliveredAt (safe even if model ignores it)
        notif['isRead'] = m['isRead'];
        notif['deliveredAt'] = m['deliveredAt'];

        return AppNotification.fromJson(notif);
      }

      // Fallback: if backend returns direct notification list
      return AppNotification.fromJson(m);
    }).toList();
  }
}