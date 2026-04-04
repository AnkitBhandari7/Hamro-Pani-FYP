import 'dart:convert';
import 'package:fyp/services/api_service.dart';

class PaymentService {
  static Future<void> verifyEsewaPayment({
    required int bookingId,
    required String refId,
  }) async {
    final res = await ApiService.post('/payments/esewa/verify', {
      'bookingId': bookingId,
      'refId': refId,
    });

    if (res.statusCode != 200) {
      throw Exception("Verify failed: ${res.statusCode} ${res.body}");
    }

    final body = jsonDecode(res.body);
    if (body is Map && body['success'] != true) {
      throw Exception("Verify failed: ${res.body}");
    }
  }
}
