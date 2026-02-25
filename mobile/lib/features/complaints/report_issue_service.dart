import 'dart:io';
import 'package:http/http.dart' as http;

class ReportIssueService {
  static const String baseUrl = "http://10.0.2.2:3000";

  static Future<void> submitIssue({
    required String token,
    required String issueType,
    required String description,
    required String ward,
    required String location,
    required List<String> photoPaths,
    int? bookingId,
  }) async {
    final request = http.MultipartRequest(
      'POST',
      Uri.parse('$baseUrl/complaints'),
    );

    request.headers.addAll({
      'Authorization': 'Bearer $token',
      'Accept': 'application/json',
    });

    request.fields.addAll({
      'issueType': issueType,
      'description': description,
      'ward': ward,
      'location': location,
      if (bookingId != null) 'bookingId': bookingId.toString(),
    });

    for (final p in photoPaths) {
      final file = File(p);
      if (await file.exists()) {
        request.files.add(await http.MultipartFile.fromPath('photos', p));
      }
    }

    final streamedResponse = await request.send();
    final response = await http.Response.fromStream(streamedResponse);

    if (response.statusCode != 201) {
      throw Exception('Failed: ${response.statusCode} ${response.body}');
    }
  }
}