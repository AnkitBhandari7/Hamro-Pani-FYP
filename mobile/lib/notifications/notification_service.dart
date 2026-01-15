import 'package:firebase_auth/firebase_auth.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/notification_model.dart';


class NotificationService {
  static const baseUrl = "http://10.0.2.2:3000";

  static Future<List<AppNotification>> getNotifications({String? ward}) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) throw Exception("User not logged in");

    final idToken = await user.getIdToken();

    final uri = Uri.parse("$baseUrl/notifications").replace(
      queryParameters: {
        if (ward != null && ward.isNotEmpty) "ward": ward,
      },
    );

    final response = await http.get(
      uri,
      headers: {'Authorization': 'Bearer $idToken'},
    );

    if (response.statusCode == 200) {
      final data = json.decode(response.body);
      return (data as List).map((e) => AppNotification.fromJson(e)).toList();
    }

    throw Exception("Failed to load notifications (${response.statusCode})");
  }
}