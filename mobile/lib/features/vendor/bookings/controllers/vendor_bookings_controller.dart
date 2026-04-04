import 'package:flutter/material.dart';
import '../services/vendor_booking_service.dart';

class VendorBookingsController extends ChangeNotifier {
  VendorBookingsController() {
    load();
  }

  bool isLoading = true;
  bool isUpdating = false;
  String? error;

  String selectedStatus = "CONFIRMED"; // default tab
  List<VendorBookingItem> items = [];

  Future<void> setStatus(String status) async {
    if (selectedStatus == status) return; // ✅ no reload if same tab
    selectedStatus = status;
    await load();
  }

  Future<void> load() async {
    isLoading = true;
    error = null;
    notifyListeners();

    try {
      items = await VendorBookingService.getVendorBookings(
        status: selectedStatus,
      );
    } catch (e) {
      error = e.toString();
      items = [];
    } finally {
      isLoading = false;
      notifyListeners();
    }
  }

  Future<void> markDelivered(int bookingId) async {
    if (isUpdating) return;

    isUpdating = true;
    error = null;
    notifyListeners();

    try {
      await VendorBookingService.markDelivered(bookingId);

      // Refresh list so item moves from CONFIRMED -> DELIVERED tab
      await load();
    } catch (e) {
      error = e.toString();
      notifyListeners();
    } finally {
      isUpdating = false;
      notifyListeners();
    }
  }
}