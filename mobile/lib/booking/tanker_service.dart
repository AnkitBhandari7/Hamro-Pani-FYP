import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;

class TankerService {
  static const String baseUrl = "http://10.0.2.2:3000";

  static Future<List<Map<String, dynamic>>> getNearbyTankers({
    required String token,
    String? searchQuery,
    String? filter,
  }) async {
    final qp = <String, String>{};
    if (searchQuery != null && searchQuery.trim().isNotEmpty) qp["search"] = searchQuery.trim();
    if (filter != null && filter.trim().isNotEmpty) qp["filter"] = filter.trim();

    final uri = Uri.parse('$baseUrl/tankers/nearby').replace(queryParameters: qp);

    try {
      final response = await http.get(
        uri,
        headers: {
          'Authorization': 'Bearer $token',
          'Accept': 'application/json',
        },
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body) as List;
        return data.map((e) => Map<String, dynamic>.from(e as Map)).toList();
      }

      throw Exception('Failed to load tankers: ${response.statusCode} - ${response.body}');
    } on SocketException {
      return [];
    }
  }

  // send paymentMethod
  static Future<Map<String, dynamic>> bookTankerSlot({
    required String token,
    required int slotId,
    required String paymentMethod,
  }) async {
    final res = await http.post(
      Uri.parse('$baseUrl/tankers/book'),
      headers: {
        'Authorization': 'Bearer $token',
        'Content-Type': 'application/json',
        'Accept': 'application/json',
      },
      body: jsonEncode({
        "slotId": slotId,
        "paymentMethod": paymentMethod,
      }),
    );

    if (res.statusCode == 201 || res.statusCode == 200) {
      return jsonDecode(res.body) as Map<String, dynamic>;
    }

    throw Exception('Booking failed: ${res.statusCode} - ${res.body}');
  }
}