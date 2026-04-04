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

  bool isSubmittingConfirm = false;

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

  Future<void> confirmDeliveryAndRate({
    required int rating,
    String? comment,
  }) async {
    if (isSubmittingConfirm) return;

    isSubmittingConfirm = true;
    notifyListeners();

    try {
      await BookingService.confirmDeliveryAndRate(
        bookingId: bookingId,
        rating: rating,
        comment: comment,
      );
      await load();
    } finally {
      isSubmittingConfirm = false;
      notifyListeners();
    }
  }
}