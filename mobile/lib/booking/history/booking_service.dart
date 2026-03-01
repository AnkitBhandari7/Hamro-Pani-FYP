import 'dart:convert';

import 'package:fyp/services/api_service.dart';

class BookingSummary {
  final int bookingId;
  final String vendorName;
  final String location; // can include ward
  final String status; // PENDING/CONFIRMED/CANCELLED/COMPLETED
  final DateTime slotStart;
  final int liters;
  final int? price;
  final bool canRebook;

  BookingSummary({
    required this.bookingId,
    required this.vendorName,
    required this.location,
    required this.status,
    required this.slotStart,
    required this.liters,
    required this.price,
    required this.canRebook,
  });

  static BookingSummary fromApi(Map<String, dynamic> b) {
    final slot = (b['slot'] ?? {}) as Map<String, dynamic>;
    final route = (slot['route'] ?? {}) as Map<String, dynamic>;
    final vendor = (route['vendor'] ?? {}) as Map<String, dynamic>;
    final user = (vendor['user'] ?? {}) as Map<String, dynamic>;
    final ward = (route['ward'] ?? {}) as Map<String, dynamic>;

    final vendorName = (user['name'] ?? 'Vendor').toString();
    final loc = (route['location'] ?? '').toString();
    final wardName = (ward['wardName'] ?? '').toString();

    final location = [
      loc.trim().isEmpty ? null : loc.trim(),
      wardName.trim().isEmpty ? null : wardName.trim(),
    ].whereType<String>().join(" • ");

    final startRaw = slot['startTime']?.toString();
    final slotStart = DateTime.tryParse(startRaw ?? '') ?? DateTime.now();

    final liters = (slot['tankerCapacityLiters'] is num)
        ? (slot['tankerCapacityLiters'] as num).toInt()
        : 12000;

    final priceRaw = slot['price'];
    final priceInt = priceRaw is num ? priceRaw.toInt() : int.tryParse(priceRaw?.toString() ?? '');

    final status = (b['status'] ?? 'PENDING').toString().toUpperCase();
    final canRebook = status == "COMPLETED" || status == "CANCELLED";

    return BookingSummary(
      bookingId: (b['id'] as num).toInt(),
      vendorName: vendorName,
      location: location.isEmpty ? "-" : location,
      status: status,
      slotStart: slotStart,
      liters: liters,
      price: priceInt,
      canRebook: canRebook,
    );
  }
}

class BookingDetail {
  final int bookingId;
  final String status;

  final String vendorName;
  final String location;
  final String wardName;

  final DateTime? startTime;
  final DateTime? endTime;

  final int liters;
  final int bookingSlotsUsed; // slot.bookedCount
  final int bookingSlotsTotal; // slot.capacity
  final int? price;

  final Map<String, dynamic>? payment;

  /// backend: statusHistory[] with fields oldStatus/newStatus/changedAt
  final List<Map<String, dynamic>> history;

  BookingDetail({
    required this.bookingId,
    required this.status,
    required this.vendorName,
    required this.location,
    required this.wardName,
    required this.startTime,
    required this.endTime,
    required this.liters,
    required this.bookingSlotsUsed,
    required this.bookingSlotsTotal,
    required this.price,
    required this.payment,
    required this.history,
  });

  static BookingDetail fromApi(Map<String, dynamic> d) {
    final slot = (d['slot'] ?? {}) as Map<String, dynamic>;
    final route = (slot['route'] ?? {}) as Map<String, dynamic>;
    final ward = (route['ward'] ?? {}) as Map<String, dynamic>;
    final vendor = (route['vendor'] ?? {}) as Map<String, dynamic>;
    final user = (vendor['user'] ?? {}) as Map<String, dynamic>;

    DateTime? parseDt(dynamic v) {
      if (v == null) return null;
      return DateTime.tryParse(v.toString());
    }

    final vendorName = (user['name'] ?? 'Vendor').toString();
    final location = (route['location'] ?? '').toString();
    final wardName = (ward['wardName'] ?? '').toString();

    final liters = (slot['tankerCapacityLiters'] is num)
        ? (slot['tankerCapacityLiters'] as num).toInt()
        : 12000;

    final bookingSlotsUsed =
    (slot['bookedCount'] is num) ? (slot['bookedCount'] as num).toInt() : 0;

    final bookingSlotsTotal =
    (slot['capacity'] is num) ? (slot['capacity'] as num).toInt() : 0;

    final priceRaw = slot['price'];
    final priceInt = priceRaw is num ? priceRaw.toInt() : int.tryParse(priceRaw?.toString() ?? '');

    final payment = d['payment'] is Map ? Map<String, dynamic>.from(d['payment'] as Map) : null;

    final statusHistory = (d['statusHistory'] as List? ?? const [])
        .map((e) => Map<String, dynamic>.from(e as Map))
        .toList();

    return BookingDetail(
      bookingId: (d['id'] as num).toInt(), // backend sends id
      status: (d['status'] ?? 'PENDING').toString(),
      vendorName: vendorName,
      location: location,
      wardName: wardName,
      startTime: parseDt(slot['startTime']),
      endTime: parseDt(slot['endTime']),
      liters: liters,
      bookingSlotsUsed: bookingSlotsUsed,
      bookingSlotsTotal: bookingSlotsTotal,
      price: priceInt,
      payment: payment,
      history: statusHistory,
    );
  }
}

class BookingService {
  static Future<List<BookingSummary>> getMyBookings() async {
    final res = await ApiService.get('/bookings/my');

    if (res.statusCode != 200) {
      throw Exception('GET /bookings/my failed: ${res.statusCode} ${res.body}');
    }

    final list = (jsonDecode(res.body) as List).cast<dynamic>();
    return list
        .map((e) => BookingSummary.fromApi(Map<String, dynamic>.from(e as Map)))
        .toList();
  }

  static Future<BookingDetail> getBookingDetail(int bookingId) async {
    final res = await ApiService.get('/bookings/$bookingId');

    if (res.statusCode != 200) {
      throw Exception('GET /bookings/$bookingId failed: ${res.statusCode} ${res.body}');
    }

    return BookingDetail.fromApi(jsonDecode(res.body) as Map<String, dynamic>);
  }
}