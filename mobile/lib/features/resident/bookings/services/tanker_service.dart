import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;

class TankerService {
  static const String baseUrl = "https://hamro-pani-fyp-backend.onrender.com";

  static Future<List<Map<String, dynamic>>> getNearbyTankers({
    required String token,
    String? searchQuery,
    String? filter,
  }) async {
    final qp = <String, String>{};
    if (searchQuery != null && searchQuery.trim().isNotEmpty)
      qp["search"] = searchQuery.trim();
    if (filter != null && filter.trim().isNotEmpty)
      qp["filter"] = filter.trim();

    final uri = Uri.parse(
      '$baseUrl/tankers/nearby',
    ).replace(queryParameters: qp);

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

      throw Exception(
        'Failed to load tankers: ${response.statusCode} - ${response.body}',
      );
    } on SocketException {
      return [];
    }
  }

  /// POST /tankers/book
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
      body: jsonEncode({"slotId": slotId, "paymentMethod": paymentMethod}),
    );

    if (res.statusCode == 201 || res.statusCode == 200) {
      return jsonDecode(res.body) as Map<String, dynamic>;
    }

    throw Exception('Booking failed: ${res.statusCode} - ${res.body}');
  }

  ///POST /payments/esewa/verify
  static Future<Map<String, dynamic>> verifyEsewaPayment({
    required String token,
    required int bookingId,
    required String refId,
  }) async {
    final res = await http.post(
      Uri.parse('$baseUrl/payments/esewa/verify'),
      headers: {
        'Authorization': 'Bearer $token',
        'Content-Type': 'application/json',
        'Accept': 'application/json',
      },
      body: jsonEncode({"bookingId": bookingId, "refId": refId}),
    );

    if (res.statusCode == 200) {
      return jsonDecode(res.body) as Map<String, dynamic>;
    }

    throw Exception('Verify failed: ${res.statusCode} - ${res.body}');
  }

  /// cancel booking if user cancels eSewa payment
  /// This matches your booking controller: PATCH /bookings/:id/status
  static Future<void> cancelBooking({
    required String token,
    required int bookingId,
  }) async {
    final res = await http.patch(
      Uri.parse('$baseUrl/bookings/$bookingId/status'),
      headers: {
        'Authorization': 'Bearer $token',
        'Content-Type': 'application/json',
        'Accept': 'application/json',
      },
      body: jsonEncode({"status": "CANCELLED"}),
    );

    if (res.statusCode == 200) return;

    throw Exception('Cancel failed: ${res.statusCode} - ${res.body}');
  }
}
