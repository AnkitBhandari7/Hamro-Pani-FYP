import 'package:flutter/material.dart';

import 'package:fyp/features/resident/bookings/services/booking_service.dart';

class BookingDetailController extends ChangeNotifier {
  BookingDetailController(this.bookingId) {
    load();
  }

  final int bookingId;

  bool isLoading = true;
  BookingDetail? detail;
  String? error;

  Future<void> load() async {
    isLoading = true;
    error = null;
    notifyListeners();

    try {
      detail = await BookingService.getBookingDetail(bookingId);
    } catch (e) {
      error = e.toString();
    } finally {
      isLoading = false;
      notifyListeners();
    }
  }
}
