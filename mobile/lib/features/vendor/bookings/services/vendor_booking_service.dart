import 'dart:convert';

import 'package:fyp/services/api_service.dart';

class VendorBookingItem {
  final int bookingId;
  final String status;

  final String residentName;
  final String residentPhone;

  final String location;
  final String wardName;

  final DateTime? startTime;
  final DateTime? endTime;

  final int liters;
  final int? price;

  VendorBookingItem({
    required this.bookingId,
    required this.status,
    required this.residentName,
    required this.residentPhone,
    required this.location,
    required this.wardName,
    required this.startTime,
    required this.endTime,
    required this.liters,
    required this.price,
  });

  static VendorBookingItem fromApi(Map<String, dynamic> b) {
    final user = (b['user'] is Map)
        ? Map<String, dynamic>.from(b['user'] as Map)
        : <String, dynamic>{};

    final slot = (b['slot'] is Map)
        ? Map<String, dynamic>.from(b['slot'] as Map)
        : <String, dynamic>{};

    final route = (slot['route'] is Map)
        ? Map<String, dynamic>.from(slot['route'] as Map)
        : <String, dynamic>{};

    final ward = (route['ward'] is Map)
        ? Map<String, dynamic>.from(route['ward'] as Map)
        : <String, dynamic>{};

    DateTime? parseDt(dynamic v) {
      if (v == null) return null;
      return DateTime.tryParse(v.toString())?.toLocal();
    }

    final liters = (slot['tankerCapacityLiters'] is num)
        ? (slot['tankerCapacityLiters'] as num).toInt()
        : 12000;

    final priceRaw = slot['price'];
    final int? priceInt = priceRaw is num
        ? priceRaw.toInt()
        : int.tryParse(priceRaw?.toString() ?? '');

    return VendorBookingItem(
      bookingId: (b['id'] as num).toInt(),
      status: (b['status'] ?? 'PENDING').toString().toUpperCase(),
      residentName: (user['name'] ?? 'Resident').toString(),
      residentPhone: (user['phoneNumber'] ?? '').toString(),
      location: (route['location'] ?? '').toString(),
      wardName: (ward['wardName'] ?? '').toString(),
      startTime: parseDt(slot['startTime']),
      endTime: parseDt(slot['endTime']),
      liters: liters,
      price: priceInt,
    );
  }

  bool get canMarkDelivered => status == "CONFIRMED";
}

class VendorBookingService {
  /// Backend route: GET /bookings/vendor/list?status=CONFIRMED
  static Future<List<VendorBookingItem>> getVendorBookings({
    String? status,
  }) async {
    final endpoint = (status == null || status.trim().isEmpty)
        ? '/bookings/vendor/list'
        : '/bookings/vendor/list?status=${Uri.encodeComponent(status.trim().toUpperCase())}';

    final res = await ApiService.get(endpoint);

    if (res.statusCode != 200) {
      throw Exception('GET $endpoint failed: ${res.statusCode} ${res.body}');
    }

    final decoded = jsonDecode(res.body);
    if (decoded is! List) return [];

    return decoded
        .cast<dynamic>()
        .map((e) => VendorBookingItem.fromApi(Map<String, dynamic>.from(e as Map)))
        .toList();
  }

  /// Vendor marks booking DELIVERED
  static Future<void> markDelivered(int bookingId) async {
    final res = await ApiService.patch(
      '/bookings/$bookingId/status',
      {'status': 'DELIVERED'},
    );

    if (res.statusCode < 200 || res.statusCode >= 300) {
      throw Exception(
        'PATCH /bookings/$bookingId/status failed: ${res.statusCode} ${res.body}',
      );
    }
  }
}