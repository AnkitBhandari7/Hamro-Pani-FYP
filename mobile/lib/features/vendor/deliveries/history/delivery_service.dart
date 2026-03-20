import 'dart:convert';
import 'package:fyp/services/api_service.dart';

class Delivery {
  final int bookingId;
  final String customerName;
  final String address;
  final String status; // DELIVERED, CANCELLED, PENDING
  final DateTime dateTime;
  final int quantityLiters;
  final String paymentMethod;

  Delivery({
    required this.bookingId,
    required this.customerName,
    required this.address,
    required this.status,
    required this.dateTime,
    required this.quantityLiters,
    required this.paymentMethod,
  });

  bool get isDelivered => status.toUpperCase() == "DELIVERED";

  factory Delivery.fromApi(Map<String, dynamic> json) {
    return Delivery(
      bookingId: (json['bookingId'] as num).toInt(),
      customerName: (json['customerName'] ?? 'Customer').toString(),
      address: (json['address'] ?? '').toString(),
      status: (json['status'] ?? 'PENDING').toString(),
      dateTime: DateTime.parse(json['dateTime'].toString()),
      quantityLiters: (json['quantityLiters'] as num?)?.toInt() ?? 12000,
      paymentMethod: (json['paymentMethod'] ?? 'Not applicable').toString(),
    );
  }
}

class VendorDeliveryStats {
  final int totalDeliveries;
  final double totalEarnings;
  final double avgRating;

  VendorDeliveryStats({
    required this.totalDeliveries,
    required this.totalEarnings,
    required this.avgRating,
  });

  factory VendorDeliveryStats.fromApi(Map<String, dynamic> json) {
    double toDouble(dynamic v) {
      if (v == null) return 0;
      if (v is num) return v.toDouble();
      return double.tryParse(v.toString()) ?? 0;
    }

    return VendorDeliveryStats(
      totalDeliveries: (json['totalDeliveries'] as num?)?.toInt() ?? 0,
      totalEarnings: toDouble(json['totalEarnings']),
      avgRating: toDouble(json['avgRating']),
    );
  }
}

class VendorDeliveriesResponse {
  final VendorDeliveryStats stats;
  final List<Delivery> deliveries;

  VendorDeliveriesResponse({required this.stats, required this.deliveries});
}

class DeliveryService {
  static Future<VendorDeliveriesResponse> getVendorDeliveries({
    int limit = 100,
  }) async {
    final res = await ApiService.get('/vendors/deliveries?limit=$limit');

    if (res.statusCode != 200) {
      throw Exception(
        'GET /vendors/deliveries failed: ${res.statusCode} ${res.body}',
      );
    }

    final data = jsonDecode(res.body) as Map<String, dynamic>;
    final stats = VendorDeliveryStats.fromApi(
      (data['stats'] ?? {}) as Map<String, dynamic>,
    );
    final list = (data['deliveries'] as List? ?? const [])
        .map((e) => Delivery.fromApi(Map<String, dynamic>.from(e as Map)))
        .toList();

    return VendorDeliveriesResponse(stats: stats, deliveries: list);
  }
}
