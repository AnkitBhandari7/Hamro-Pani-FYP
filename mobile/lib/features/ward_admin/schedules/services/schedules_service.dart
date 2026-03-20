import 'dart:convert';
import 'package:http/http.dart' as http;

import 'package:fyp/app/config/app_config.dart';
import '../models/schedule_payload.dart';

class SchedulesService {
  static Uri _uri(String path) => Uri.parse('$kApiBaseUrl$path');

  static Map<String, dynamic> _decodeJson(http.Response res) {
    try {
      final body = res.body.trim();
      if (body.isEmpty) return {};
      final decoded = jsonDecode(body);
      if (decoded is Map<String, dynamic>) return decoded;
      return {"data": decoded};
    } catch (_) {
      return {"raw": res.body};
    }
  }

  static Future<void> publishSchedule({
    required String idToken,
    required SchedulePayload payload,
  }) async {
    final res = await http.post(
      _uri('/schedules'),
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $idToken',
      },
      body: jsonEncode(payload.toJson()),
    );

    if (res.statusCode == 201) return;

    final err = _decodeJson(res);
    throw Exception(err['error'] ?? 'HTTP ${res.statusCode}: ${res.body}');
  }
}
