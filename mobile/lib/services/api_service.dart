import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';

class ApiService {
  /// Set this when running on a real device:
  /// flutter run --dart-define=API_BASE_URL=http://192.168.1.10:3000
  static const String _fromEnv = String.fromEnvironment('API_BASE_URL');

  static String get baseUrl {
    final env = _fromEnv.trim();
    if (env.isNotEmpty) return _stripTrailingSlash(env);

    // Defaults if API_BASE_URL is not provided
    if (defaultTargetPlatform == TargetPlatform.android) {
      // Android Emulator special IP to access host machine
      return 'http://10.0.2.2:3000';
    }

    // iOS simulator / macOS / Windows / Linux
    return 'http://localhost:3000';
  }

  static String _stripTrailingSlash(String s) => s.endsWith('/') ? s.substring(0, s.length - 1) : s;

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

  static Uri _uri(String endpoint) {
    // endpoint must start with "/"
    final ep = endpoint.startsWith('/') ? endpoint : '/$endpoint';
    return Uri.parse('${baseUrl}$ep');
  }

  static Future<http.Response> get(String endpoint) {
    return _request((token) {
      return http.get(_uri(endpoint), headers: _headers(token));
    });
  }

  static Future<http.Response> post(String endpoint, Map<String, dynamic> body) {
    return _request((token) {
      return http.post(
        _uri(endpoint),
        headers: _headers(token),
        body: jsonEncode(body),
      );
    });
  }

  static Future<http.Response> patch(String endpoint, Map<String, dynamic> body) {
    return _request((token) {
      return http.patch(
        _uri(endpoint),
        headers: _headers(token),
        body: jsonEncode(body),
      );
    });
  }

  static Future<http.Response> delete(String endpoint) {
    return _request((token) {
      return http.delete(_uri(endpoint), headers: _headers(token));
    });
  }

  /// decode JSON + throw readable error
  static Future<dynamic> postJson(String endpoint, Map<String, dynamic> body) async {
    final res = await post(endpoint, body);
    if (res.statusCode < 200 || res.statusCode >= 300) {
      throw Exception('HTTP ${res.statusCode}: ${res.body}');
    }
    return res.body.isEmpty ? null : jsonDecode(res.body);
  }
}