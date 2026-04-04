import 'package:flutter/material.dart';
import 'delivery_service.dart';

class VendorDeliveryHistoryController extends ChangeNotifier {
  bool isLoading = true;
  String? error;

  List<Delivery> deliveries = [];
  VendorDeliveryStats stats = VendorDeliveryStats(
    totalDeliveries: 0,
    totalEarnings: 0,
    avgRating: 0,
  );

  VendorDeliveryHistoryController() {
    load();
  }

  Future<void> load() async {
    isLoading = true;
    error = null;
    notifyListeners();

    try {
      final resp = await DeliveryService.getVendorDeliveries(limit: 150);
      deliveries = resp.deliveries;
      stats = resp.stats;
    } catch (e) {
      error = e.toString();
    } finally {
      isLoading = false;
      notifyListeners();
    }
  }

  Future<void> refresh() => load();
}
