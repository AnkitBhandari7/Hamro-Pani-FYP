import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:firebase_auth/firebase_auth.dart';

class ApiService {
  static const String baseUrl = 'http://10.0.2.2:3000';

  static Future<String?> getToken({bool forceRefresh = false}) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return null;
    return user.getIdToken(forceRefresh);
  }

  static Map<String, String> _headers(String token) => {
    'Authorization': 'Bearer $token',
    'Content-Type': 'application/json',
  };

  static Future<http.Response> _request(
    Future<http.Response> Function(String token) makeCall,
  ) async {
    String? token = await getToken(forceRefresh: false);
    if (token == null) throw Exception('Not authenticated');

    http.Response res = await makeCall(token);

    if (res.statusCode == 401 || res.statusCode == 403) {
      token = await getToken(forceRefresh: true);
      if (token == null) throw Exception('Not authenticated');
      res = await makeCall(token);
    }

    return res;
  }

  static Future<http.Response> get(String endpoint) {
    return _request((token) {
      return http.get(Uri.parse('$baseUrl$endpoint'), headers: _headers(token));
    });
  }

  static Future<http.Response> post(
    String endpoint,
    Map<String, dynamic> body,
  ) {
    return _request((token) {
      return http.post(
        Uri.parse('$baseUrl$endpoint'),
        headers: _headers(token),
        body: jsonEncode(body),
      );
    });
  }

  static Future<http.Response> patch(
    String endpoint,
    Map<String, dynamic> body,
  ) {
    return _request((token) {
      return http.patch(
        Uri.parse('$baseUrl$endpoint'),
        headers: _headers(token),
        body: jsonEncode(body),
      );
    });
  }

  static Future<http.Response> delete(String endpoint) {
    return _request((token) {
      return http.delete(
        Uri.parse('$baseUrl$endpoint'),
        headers: _headers(token),
      );
    });
  }

  // decode JSON + throw readable error
  static Future<dynamic> postJson(
    String endpoint,
    Map<String, dynamic> body,
  ) async {
    final res = await post(endpoint, body);
    if (res.statusCode < 200 || res.statusCode >= 300) {
      throw Exception('HTTP ${res.statusCode}: ${res.body}');
    }
    return res.body.isEmpty ? null : jsonDecode(res.body);
  }
}
