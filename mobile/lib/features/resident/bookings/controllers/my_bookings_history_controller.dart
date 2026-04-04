import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../services/booking_service.dart';

class MyBookingsHistoryController extends ChangeNotifier {
  bool isLoading = true;
  String? error;
  List<BookingSummary> bookings = [];

  MyBookingsHistoryController() {
    load();
  }

  Future<void> load() async {
    isLoading = true;
    error = null;
    notifyListeners();

    try {
      bookings = await BookingService.getMyBookings();
    } catch (e) {
      error = e.toString();
    } finally {
      isLoading = false;
      notifyListeners();
    }
  }

  Future<void> refresh() => load();

  /// Locale-aware grouping (e.g. Nepali month names when locale is ne)
  Map<String, List<BookingSummary>> groupedForLocale(Locale locale) {
    final localeTag = locale.toLanguageTag();

    final map = <String, List<BookingSummary>>{};
    for (final b in bookings) {
      final key = DateFormat('MMMM yyyy', localeTag)
          .format(b.slotStart.toLocal())
          .toUpperCase();
      map.putIfAbsent(key, () => []).add(b);
    }
    return map;
  }

  /// Backwards-compatible getter (uses English if caller doesn't provide locale)
  Map<String, List<BookingSummary>> get grouped {
    final map = <String, List<BookingSummary>>{};
    for (final b in bookings) {
      final key = DateFormat('MMMM yyyy')
          .format(b.slotStart.toLocal())
          .toUpperCase();
      map.putIfAbsent(key, () => []).add(b);
    }
    return map;
  }
}