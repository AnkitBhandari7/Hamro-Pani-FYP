import 'dart:convert';
import 'dart:io';

import 'package:http/http.dart' as http;

class WardAdminProfileService {
  static const String baseUrl = "http://10.0.2.2:3000";

  static Map<String, String> _authHeaders(String token) => {
    'Authorization': 'Bearer $token',
  };

  static Map<String, String> _authJsonHeaders(String token) => {
    'Authorization': 'Bearer $token',
    'Content-Type': 'application/json',
    'Accept': 'application/json',
  };

  static Map<String, dynamic> _decodeJson(http.Response res) {
    try {
      final body = res.body.trim();
      if (body.isEmpty) return {};
      return jsonDecode(body) as Map<String, dynamic>;
    } catch (_) {
      return {"raw": res.body};
    }
  }

  /// Returns profile JSON from backend.
  /// Backend returns profileImageUrl already as an absolute URL
  static Future<Map<String, dynamic>> fetchProfile(String token) async {
    final res = await http.get(
      Uri.parse('$baseUrl/admin/profile/me'),
      headers: _authHeaders(token),
    );

    if (res.statusCode == 200) {
      return _decodeJson(res);
    }

    final err = _decodeJson(res);
    throw Exception(
      'Failed to load profile: ${res.statusCode} - ${err['error'] ?? res.body}',
    );
  }

  /// Update editable fields
  static Future<Map<String, dynamic>> updateProfile(
    String token,
    Map<String, dynamic> data,
  ) async {
    final res = await http.patch(
      Uri.parse('$baseUrl/admin/profile/me'),
      headers: _authJsonHeaders(token),
      body: jsonEncode(data),
    );

    if (res.statusCode == 200) {
      return _decodeJson(res);
    }

    final err = _decodeJson(res);
    throw Exception(
      'Failed to update profile: ${res.statusCode} - ${err['error'] ?? res.body}',
    );
  }

  /// Upload profile photo.

  /// - backend returns { profileImageUrl: "http://host/uploads/profile/xxx.png" }
  static Future<String> uploadPhoto(String token, File file) async {
    final request = http.MultipartRequest(
      'POST',
      Uri.parse('$baseUrl/admin/profile/me/photo'),
    );

    request.headers.addAll(_authHeaders(token));

    request.files.add(
      await http.MultipartFile.fromPath(
        'photo',
        file.path,

        filename: file.uri.pathSegments.isNotEmpty
            ? file.uri.pathSegments.last
            : 'photo.jpg',
      ),
    );

    final streamed = await request.send();
    final res = await http.Response.fromStream(streamed);

    if (res.statusCode == 200) {
      final data = _decodeJson(res);

      // backend should return direct string
      final url = (data['profileImageUrl'] ?? '').toString().trim();
      if (url.isEmpty) {
        throw Exception(
          'Upload succeeded but profileImageUrl missing: ${res.body}',
        );
      }
      return url;
    }

    final err = _decodeJson(res);
    throw Exception(
      'Photo upload failed: ${res.statusCode} - ${err['error'] ?? res.body}',
    );
  }
}
