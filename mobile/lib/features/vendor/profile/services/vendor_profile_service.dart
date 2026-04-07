// Student note: Vendor profile API calls

import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;

class VendorProfileService {
  static const String baseUrl = "https://hamro-pani-fyp-backend.onrender.com";

  static Future<Map<String, dynamic>> fetchVendorProfile(String token) async {
    final res = await http.get(
      Uri.parse('$baseUrl/vendors/profile/me'),
      headers: {'Authorization': 'Bearer $token'},
    );

    if (res.statusCode == 200) {
      return jsonDecode(res.body) as Map<String, dynamic>;
    }
    throw Exception(
      'Failed to load vendor profile: ${res.statusCode} - ${res.body}',
    );
  }

  static Future<void> updateVendorProfile(
    String token,
    Map<String, dynamic> data,
  ) async {
    final res = await http.patch(
      Uri.parse('$baseUrl/vendors/profile/me'),
      headers: {
        'Authorization': 'Bearer $token',
        'Content-Type': 'application/json',
      },
      body: jsonEncode(data),
    );

    if (res.statusCode != 200) {
      throw Exception(
        'Failed to update vendor profile: ${res.statusCode} - ${res.body}',
      );
    }
  }

  static Future<String> uploadVendorPhoto(String token, File file) async {
    final request = http.MultipartRequest(
      'POST',
      Uri.parse('$baseUrl/vendors/profile/me/photo'),
    );

    request.headers['Authorization'] = 'Bearer $token';
    request.files.add(await http.MultipartFile.fromPath('photo', file.path));

    final streamed = await request.send();
    final res = await http.Response.fromStream(streamed);

    if (res.statusCode == 200) {
      final data = jsonDecode(res.body) as Map<String, dynamic>;
      return (data['logoUrl'] ?? '').toString();
    }
    throw Exception('Photo upload failed: ${res.statusCode} - ${res.body}');
  }

  static Future<void> deleteVendorPhoto(String token) async {
    final res = await http.delete(
      Uri.parse('$baseUrl/vendors/profile/me/photo'),
      headers: {'Authorization': 'Bearer $token'},
    );

    if (res.statusCode != 200) {
      throw Exception('Delete photo failed: ${res.statusCode} - ${res.body}');
    }
  }
}
