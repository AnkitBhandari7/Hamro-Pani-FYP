import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../services/vendor_service.dart';

class VendorDetailsController extends ChangeNotifier {
  bool _isLoading = true;
  bool get isLoading => _isLoading;

  // UI fields
  String tankerImageUrl =
      'https://images.unsplash.com/photo-1601581875039-e8c26e3e88fe?w=800&auto=format&fit=crop&q=80';

  String vendorName = 'Vendor';
  String statusLabel = 'Available Now';

  String wardName = '';
  String location = '';

  int tankerCapacityLiters = 12000;
  int bookingSlotsUsed = 0;
  int bookingSlotsTotal = 0;

  int? price; // NPR
  DateTime? startTime;
  DateTime? endTime;

  VendorDetailsController({
    required Map<String, dynamic> vendor,
    required int? slotId,
  }) {
    _init(vendor, slotId);
  }

  String get priceLabel => price == null ? '—' : 'NPR $price/tanker';

  String get timeRangeLabel {
    if (startTime == null || endTime == null) return '—';
    final fmt = DateFormat('hh:mm a');
    return '${fmt.format(startTime!.toLocal())} - ${fmt.format(endTime!.toLocal())}';
  }

  String get bookingLabel {
    if (bookingSlotsTotal <= 0) return '—';
    return '$bookingSlotsUsed/$bookingSlotsTotal booked';
  }

  Future<void> _init(Map<String, dynamic> vendor, int? slotId) async {
    // 1) Fill quick from passed vendor map
    vendorName = (vendor['name'] ?? vendorName).toString();

    final st = (vendor['status'] ?? '').toString().toUpperCase();
    statusLabel = st.isEmpty
        ? statusLabel
        : (st == 'AVAILABLE' ? 'Available Now' : st);

    final vPrice = vendor['price'];
    if (vPrice is num) price = vPrice.toInt();
    tankerCapacityLiters = (vendor['tankerCapacityLiters'] is num)
        ? (vendor['tankerCapacityLiters'] as num).toInt()
        : tankerCapacityLiters;

    bookingSlotsUsed = (vendor['slotsUsed'] is num)
        ? (vendor['slotsUsed'] as num).toInt()
        : bookingSlotsUsed;
    bookingSlotsTotal = (vendor['slotsTotal'] is num)
        ? (vendor['slotsTotal'] as num).toInt()
        : bookingSlotsTotal;

    // 2) Load accurate details from backend by slotId
    if (slotId != null) {
      try {
        final user = FirebaseAuth.instance.currentUser;
        final token = await user?.getIdToken(true);
        if (token != null && token.isNotEmpty) {
          final data = await VendorDetailsService.getSlotDetails(
            token: token,
            slotId: slotId,
          );

          vendorName = (data['vendor']?['name'] ?? vendorName).toString();
          statusLabel = (data['status'] ?? statusLabel).toString();

          wardName = (data['route']?['wardName'] ?? '').toString();
          location = (data['route']?['location'] ?? '').toString();

          tankerCapacityLiters = (data['tankerCapacityLiters'] is num)
              ? (data['tankerCapacityLiters'] as num).toInt()
              : tankerCapacityLiters;

          bookingSlotsUsed = (data['bookingSlotsUsed'] is num)
              ? (data['bookingSlotsUsed'] as num).toInt()
              : bookingSlotsUsed;

          bookingSlotsTotal = (data['bookingSlotsTotal'] is num)
              ? (data['bookingSlotsTotal'] as num).toInt()
              : bookingSlotsTotal;

          final p = data['price'];
          price = (p is num) ? p.toInt() : price;

          final s1 = data['startTime']?.toString();
          final s2 = data['endTime']?.toString();
          if (s1 != null) startTime = DateTime.tryParse(s1);
          if (s2 != null) endTime = DateTime.tryParse(s2);
        }
      } catch (_) {
        // keep fallback values
      }
    }

    _isLoading = false;
    notifyListeners();
  }
}
