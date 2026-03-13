import 'dart:convert';
import 'package:fyp/services/api_service.dart';

class PaymentReceipt {
  final int bookingId;
  final String transactionId;
  final DateTime dateTime;
  final String paymentMethod;
  final String recipient;
  final String service;
  final int quantityLiters;
  final double amount;

  PaymentReceipt({
    required this.bookingId,
    required this.transactionId,
    required this.dateTime,
    required this.paymentMethod,
    required this.recipient,
    required this.service,
    required this.quantityLiters,
    required this.amount,
  });

  factory PaymentReceipt.fromApi(Map<String, dynamic> json) {
    return PaymentReceipt(
      bookingId: (json['bookingId'] as num).toInt(),
      transactionId: (json['transactionId'] ?? '').toString(),
      dateTime: DateTime.parse(json['dateTime'].toString()).toLocal(),
      paymentMethod: (json['paymentMethod'] ?? '').toString(),
      recipient: (json['recipient'] ?? '').toString(),
      service: (json['service'] ?? '').toString(),
      quantityLiters: (json['quantityLiters'] as num?)?.toInt() ?? 0,
      amount: (json['amount'] is num) ? (json['amount'] as num).toDouble() : double.tryParse(json['amount'].toString()) ?? 0.0,
    );
  }
}

class PaymentReceiptService {
  static Future<PaymentReceipt> fetchReceiptByBookingId(int bookingId) async {
    final res = await ApiService.get('/payments/receipt/$bookingId');
    if (res.statusCode != 200) {
      throw Exception("Receipt load failed: ${res.statusCode} ${res.body}");
    }
    return PaymentReceipt.fromApi(jsonDecode(res.body) as Map<String, dynamic>);
  }
}