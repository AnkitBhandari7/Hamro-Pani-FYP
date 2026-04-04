import 'dart:convert';
import 'dart:typed_data';

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

  /// Upload schedule file (CSV/PDF)
  /// Requires backend endpoint: POST /schedules/upload (multipart/form-data)
  static Future<void> uploadScheduleFile({
    required String idToken,
    required String fileName,
    required String? filePath,
    required Uint8List? fileBytes,
    required bool notifyResidents,
  }) async {
    final req = http.MultipartRequest('POST', _uri('/schedules/upload'));

    req.headers['Authorization'] = 'Bearer $idToken';
    req.fields['notifyResidents'] = notifyResidents ? 'true' : 'false';

    if (fileBytes != null) {
      req.files.add(
        http.MultipartFile.fromBytes(
          'file',
          fileBytes,
          filename: fileName,
        ),
      );
    } else if (filePath != null) {
      req.files.add(
        await http.MultipartFile.fromPath(
          'file',
          filePath,
          filename: fileName,
        ),
      );
    } else {
      throw Exception("FILE_MISSING");
    }

    final streamed = await req.send();
    final res = await http.Response.fromStream(streamed);

    if (res.statusCode == 200 || res.statusCode == 201) return;

    final err = _decodeJson(res);
    throw Exception(err['error'] ?? 'HTTP ${res.statusCode}: ${res.body}');
  }
}