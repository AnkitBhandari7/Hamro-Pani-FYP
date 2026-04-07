import 'dart:convert';
import 'package:http/http.dart' as http;

class VendorDetailsService {
  static const String baseUrl = "https://hamro-pani-fyp-backend.onrender.com";

  static Future<Map<String, dynamic>> getSlotDetails({
    required String token,
    required int slotId,
  }) async {
    final response = await http.get(
      Uri.parse('$baseUrl/tankers/slots/$slotId/details'),
      headers: {'Authorization': 'Bearer $token', 'Accept': 'application/json'},
    );

    if (response.statusCode == 200) {
      return jsonDecode(response.body) as Map<String, dynamic>;
    }
    throw Exception(
      'Failed to load slot details: ${response.statusCode} ${response.body}',
    );
  }
}
