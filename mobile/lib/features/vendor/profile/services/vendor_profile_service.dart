// Student note: Vendor profile API calls

import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;
import 'package:fyp/services/api_service.dart';
import 'package:fyp/services/firebase_storage_service.dart';
import 'package:firebase_auth/firebase_auth.dart';

class VendorProfileService {
  static Future<Map<String, dynamic>> fetchVendorProfile(String token) async {
    final res = await http.get(
      Uri.parse('${ApiService.baseUrl}/vendors/profile/me'),
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
      Uri.parse('${ApiService.baseUrl}/vendors/profile/me'),
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

  /// Upload vendor profile photo via Firebase Storage, then persist the
  /// HTTPS download URL to the backend.
  static Future<String> uploadVendorPhoto(String token, File file) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) throw Exception('Not authenticated');

    // 1. Upload to Firebase Storage → get HTTPS URL
    final downloadUrl = await FirebaseStorageService.uploadProfileImage(
      user.uid,
      file,
    );

    // 2. Save the URL in the backend MySQL row
    final res = await http.patch(
      Uri.parse('${ApiService.baseUrl}/vendors/profile/me/photo-url'),
      headers: {
        'Authorization': 'Bearer $token',
        'Content-Type': 'application/json',
      },
      body: jsonEncode({'photoUrl': downloadUrl}),
    );

    if (res.statusCode != 200) {
      throw Exception('Photo URL save failed: ${res.statusCode} - ${res.body}');
    }

    return downloadUrl;
  }

  /// Delete vendor profile photo from Firebase Storage and clear it on backend.
  static Future<void> deleteVendorPhoto(String token) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      await FirebaseStorageService.deleteProfileImage(user.uid);
    }

    final res = await http.delete(
      Uri.parse('${ApiService.baseUrl}/vendors/profile/me/photo'),
      headers: {'Authorization': 'Bearer $token'},
    );

    if (res.statusCode != 200) {
      throw Exception('Delete photo failed: ${res.statusCode} - ${res.body}');
    }
  }
}
