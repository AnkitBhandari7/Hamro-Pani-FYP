import 'dart:convert';

import 'package:fyp/services/api_service.dart';

class BookingSummary {
  final int bookingId;
  final String vendorName;
  final String location;
  final String status;
  final DateTime slotStart;
  final int liters;
  final int? price;
  final bool canRebook;
  final bool isPaid;
  final String? paymentMethod;

  BookingSummary({
    required this.bookingId,
    required this.vendorName,
    required this.location,
    required this.status,
    required this.slotStart,
    required this.liters,
    required this.price,
    required this.canRebook,
    required this.isPaid,
    required this.paymentMethod,
  });

  static BookingSummary fromApi(Map<String, dynamic> b) {
    final slot = (b['slot'] is Map)
        ? Map<String, dynamic>.from(b['slot'] as Map)
        : <String, dynamic>{};
    final route = (slot['route'] is Map)
        ? Map<String, dynamic>.from(slot['route'] as Map)
        : <String, dynamic>{};
    final vendor = (route['vendor'] is Map)
        ? Map<String, dynamic>.from(route['vendor'] as Map)
        : <String, dynamic>{};
    final user = (vendor['user'] is Map)
        ? Map<String, dynamic>.from(vendor['user'] as Map)
        : <String, dynamic>{};
    final ward = (route['ward'] is Map)
        ? Map<String, dynamic>.from(route['ward'] as Map)
        : <String, dynamic>{};

    final vendorName = (user['name'] ?? 'Vendor').toString();

    final loc = (route['location'] ?? '').toString();
    final wardName = (ward['wardName'] ?? '').toString();

    final location = [
      loc.trim().isEmpty ? null : loc.trim(),
      wardName.trim().isEmpty ? null : wardName.trim(),
    ].whereType<String>().join(" • ");

    final startRaw = slot['startTime']?.toString();
    final slotStart =
    (DateTime.tryParse(startRaw ?? '') ?? DateTime.now()).toLocal();

    final liters = (slot['tankerCapacityLiters'] is num)
        ? (slot['tankerCapacityLiters'] as num).toInt()
        : 12000;

    final priceRaw = slot['price'];
    final priceInt = priceRaw is num
        ? priceRaw.toInt()
        : int.tryParse(priceRaw?.toString() ?? '');

    final status = (b['status'] ?? 'PENDING').toString().toUpperCase();
    final canRebook = status == "COMPLETED" || status == "CANCELLED";
    
    final payment = b['payment'] is Map ? Map<String, dynamic>.from(b['payment'] as Map) : null;
    final paymentMethod = payment?['method']?.toString();
    final isPaid = payment?['status']?.toString().toUpperCase() == "COMPLETED";

    return BookingSummary(
      bookingId: (b['id'] as num).toInt(),
      vendorName: vendorName,
      location: location.trim().isEmpty ? "-" : location,
      status: status,
      slotStart: slotStart,
      liters: liters,
      price: priceInt,
      canRebook: canRebook,
      isPaid: isPaid,
      paymentMethod: paymentMethod,
    );
  }
}

class MyRating {
  final int id;
  final int rating;
  final String? comment;
  final DateTime createdAt;

  MyRating({
    required this.id,
    required this.rating,
    required this.comment,
    required this.createdAt,
  });

  static MyRating fromApi(Map<String, dynamic> m) {
    return MyRating(
      id: (m['id'] as num).toInt(),
      rating: (m['rating'] as num).toInt(),
      comment: m['comment']?.toString(),
      createdAt: DateTime.parse(m['createdAt'].toString()).toLocal(),
    );
  }
}

class BookingDetail {
  final int bookingId;
  final String status;

  final int? vendorId;

  final String vendorName;
  final String location;
  final String wardName;

  final DateTime? startTime;
  final DateTime? endTime;

  final int liters;
  final int bookingSlotsUsed;
  final int bookingSlotsTotal;
  final int? price;

  final Map<String, dynamic>? payment;
  final List<Map<String, dynamic>> history;

  final MyRating? myRating;

  BookingDetail({
    required this.bookingId,
    required this.status,
    required this.vendorId,
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
    required this.myRating,
  });

  static BookingDetail fromApi(Map<String, dynamic> d) {
    final slot = (d['slot'] is Map)
        ? Map<String, dynamic>.from(d['slot'] as Map)
        : <String, dynamic>{};
    final route = (slot['route'] is Map)
        ? Map<String, dynamic>.from(slot['route'] as Map)
        : <String, dynamic>{};
    final ward = (route['ward'] is Map)
        ? Map<String, dynamic>.from(route['ward'] as Map)
        : <String, dynamic>{};
    final vendor = (route['vendor'] is Map)
        ? Map<String, dynamic>.from(route['vendor'] as Map)
        : <String, dynamic>{};
    final user = (vendor['user'] is Map)
        ? Map<String, dynamic>.from(vendor['user'] as Map)
        : <String, dynamic>{};

    DateTime? parseDt(dynamic v) {
      if (v == null) return null;
      return DateTime.tryParse(v.toString())?.toLocal();
    }

    final vendorName = (user['name'] ?? 'Vendor').toString();
    final location = (route['location'] ?? '').toString();
    final wardName = (ward['wardName'] ?? '').toString();

    final vendorIdRaw = route['vendorId'];
    final int? vendorId = vendorIdRaw is num
        ? vendorIdRaw.toInt()
        : int.tryParse(vendorIdRaw?.toString() ?? '');

    final liters = (slot['tankerCapacityLiters'] is num)
        ? (slot['tankerCapacityLiters'] as num).toInt()
        : 12000;

    final bookingSlotsUsed = (slot['bookedCount'] is num)
        ? (slot['bookedCount'] as num).toInt()
        : 0;

    final bookingSlotsTotal = (slot['capacity'] is num)
        ? (slot['capacity'] as num).toInt()
        : 0;

    final priceRaw = slot['price'];
    final priceInt = priceRaw is num
        ? priceRaw.toInt()
        : int.tryParse(priceRaw?.toString() ?? '');

    final payment = d['payment'] is Map
        ? Map<String, dynamic>.from(d['payment'] as Map)
        : null;

    final statusHistory = (d['statusHistory'] as List? ?? const [])
        .map((e) => Map<String, dynamic>.from(e as Map))
        .toList()
      ..sort((a, b) {
        final adt = DateTime.tryParse(a['changedAt']?.toString() ?? '');
        final bdt = DateTime.tryParse(b['changedAt']?.toString() ?? '');
        if (adt == null && bdt == null) return 0;
        if (adt == null) return 1;
        if (bdt == null) return -1;
        return bdt.compareTo(adt);
      });

    final myRating = (d['myRating'] is Map)
        ? MyRating.fromApi(Map<String, dynamic>.from(d['myRating'] as Map))
        : null;

    return BookingDetail(
      bookingId: (d['id'] as num).toInt(),
      status: (d['status'] ?? 'PENDING').toString().toUpperCase(),
      vendorId: vendorId,
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
      myRating: myRating,
    );
  }

  bool get canConfirmDelivery =>
      (status.toUpperCase() == "DELIVERED" || status.toUpperCase() == "COMPLETED") &&
          myRating == null;
}

class BookingService {
  static Future<List<BookingSummary>> getMyBookings() async {
    final res = await ApiService.get('/bookings/my');

    if (res.statusCode != 200) {
      throw Exception('GET /bookings/my failed: ${res.statusCode} ${res.body}');
    }

    final decoded = jsonDecode(res.body);
    if (decoded is! List) return [];

    return decoded
        .cast<dynamic>()
        .map((e) => BookingSummary.fromApi(Map<String, dynamic>.from(e as Map)))
        .toList();
  }

  static Future<BookingDetail> getBookingDetail(int bookingId) async {
    final res = await ApiService.get('/bookings/$bookingId');

    if (res.statusCode != 200) {
      throw Exception(
        'GET /bookings/$bookingId failed: ${res.statusCode} ${res.body}',
      );
    }

    return BookingDetail.fromApi(jsonDecode(res.body) as Map<String, dynamic>);
  }

  static Future<void> confirmDeliveryAndRate({
    required int bookingId,
    required int rating,
    String? comment,
  }) async {
    final res = await ApiService.post(
      '/bookings/$bookingId/confirm-delivery',
      {
        'rating': rating,
        if (comment != null && comment.trim().isNotEmpty)
          'comment': comment.trim(),
      },
    );

    if (res.statusCode < 200 || res.statusCode >= 300) {
      throw Exception(
        'POST /bookings/$bookingId/confirm-delivery failed: ${res.statusCode} ${res.body}',
      );
    }
  }
}