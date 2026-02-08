// mobile/lib/booking/tanker_booking_controller.dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'tanker_booking_service.dart';

/// Immutable state for the tanker booking vendor screen
class TankerBookingState {
  final String selectedDateFilter; // "Today" | "Tomorrow" | "Custom"
  final TimeOfDay? selectedStartTime;
  final List<Map<String, dynamic>> routes; // raw backend routes
  final List<Map<String, dynamic>> slots; // UI-ready slots
  final bool isLoading;
  final bool isPublishing;

  const TankerBookingState({
    this.selectedDateFilter = 'Today',
    this.selectedStartTime,
    this.routes = const [],
    this.slots = const [],
    this.isLoading = false,
    this.isPublishing = false,
  });

  TankerBookingState copyWith({
    String? selectedDateFilter,
    TimeOfDay? selectedStartTime,
    List<Map<String, dynamic>>? routes,
    List<Map<String, dynamic>>? slots,
    bool? isLoading,
    bool? isPublishing,
  }) {
    return TankerBookingState(
      selectedDateFilter: selectedDateFilter ?? this.selectedDateFilter,
      selectedStartTime: selectedStartTime ?? this.selectedStartTime,
      routes: routes ?? this.routes,
      slots: slots ?? this.slots,
      isLoading: isLoading ?? this.isLoading,
      isPublishing: isPublishing ?? this.isPublishing,
    );
  }
}

/// Riverpod 3: use Notifier instead of StateNotifier
class TankerBookingController extends Notifier<TankerBookingState> {
  late final TankerBookingService _service;

  @override
  TankerBookingState build() {
    // read dependencies here
    _service = ref.read(tankerBookingServiceProvider);

    // load initial data after build (cannot be async)
    Future.microtask(loadInitialData);

    // initial state
    return const TankerBookingState();
  }

  /// Load vendor routes + slots on screen start / refresh
  Future<void> loadInitialData() async {
    state = state.copyWith(isLoading: true);
    try {
      final routes = await _service.fetchMyRoutes();
      final slots = _buildSlotsFromRoutes(routes);
      state = state.copyWith(routes: routes, slots: slots);
    } catch (_) {
      state = state.copyWith(routes: [], slots: []);
    } finally {
      state = state.copyWith(isLoading: false);
    }
  }

  List<Map<String, dynamic>> _buildSlotsFromRoutes(
      List<Map<String, dynamic>> routes) {
    final List<Map<String, dynamic>> uiSlots = [];

    for (final route in routes) {
      final routeName = (route['name'] ?? '').toString();
      final slotList = (route['slots'] as List<dynamic>? ?? [])
          .cast<Map<String, dynamic>>();

      for (final slotJson in slotList) {
        uiSlots.add(_slotToUiMap(routeName, slotJson));
      }
    }

    return uiSlots;
  }

  Map<String, dynamic> _slotToUiMap(
      String routeName, Map<String, dynamic> slotJson) {
    final capacity = (slotJson['capacity'] ?? 0) as int;
    final bookedCount = (slotJson['bookedCount'] ?? 0) as int;
    final dbStatus = (slotJson['status'] ?? 'OPEN').toString();

    final startStr = slotJson['startTime']?.toString() ?? '';
    final endStr = slotJson['endTime']?.toString() ?? '';
    final dateStr = slotJson['date']?.toString() ?? '';

    final start = DateTime.tryParse(startStr) ?? DateTime.now();
    final end = DateTime.tryParse(endStr) ?? start.add(const Duration(hours: 2));
    final date = DateTime.tryParse(dateStr) ?? start;

    final dateLabel = _service.buildDateLabel(date);
    final timeRange = _service.buildTimeRange(start, end);

    final uiStatus = bookedCount >= capacity ? 'FULL' : dbStatus;

    return {
      'slotId': slotJson['id'],
      'date': dateLabel,
      'time': timeRange,
      'status': uiStatus,
      'location': routeName,
      'booked': bookedCount,
      'total': capacity,
    };
  }

  void setDateFilter(String value) {
    state = state.copyWith(selectedDateFilter: value);
  }

  void setStartTime(TimeOfDay value) {
    state = state.copyWith(selectedStartTime: value);
  }

  String get formattedSelectedTime {
    final time = state.selectedStartTime;
    if (time == null) return 'Select Time';

    final now = DateTime.now();
    final dt = DateTime(
      now.year,
      now.month,
      now.day,
      time.hour,
      time.minute,
    );

    final range = _service.buildTimeRange(dt, dt);
    return range.split(' - ').first;
  }

  /// Returns null on success; error message on failure
  Future<String?> publishSlot({
    required String capacityText,
    required String routeText,
  }) async {
    if (state.selectedStartTime == null) {
      return 'Please select a start time';
    }

    final capacity = int.tryParse(capacityText);
    if (capacity == null || capacity <= 0) {
      return 'Please enter a valid capacity';
    }

    final routeName = routeText.trim();
    if (routeName.isEmpty) {
      return 'Please enter a delivery route/area';
    }

    final now = DateTime.now();
    DateTime date;

    switch (state.selectedDateFilter) {
      case 'Today':
        date = DateTime(now.year, now.month, now.day);
        break;
      case 'Tomorrow':
        final tmr = now.add(const Duration(days: 1));
        date = DateTime(tmr.year, tmr.month, tmr.day);
        break;
      case 'Custom':
      // TODO: attach a proper date picker here
        date = DateTime(now.year, now.month, now.day);
        break;
      default:
        date = DateTime(now.year, now.month, now.day);
    }

    final startDateTime = DateTime(
      date.year,
      date.month,
      date.day,
      state.selectedStartTime!.hour,
      state.selectedStartTime!.minute,
    );
    final endDateTime = startDateTime.add(const Duration(hours: 2));

    state = state.copyWith(isPublishing: true);

    try {
      // 1) Find existing route with same name (case-insensitive)
      Map<String, dynamic>? route;
      for (final r in state.routes) {
        final rName = (r['name'] ?? '').toString().toLowerCase();
        if (rName == routeName.toLowerCase()) {
          route = r;
          break;
        }
      }

      // 2) If not found, create new route
      if (route == null) {
        const defaultWardId = 16; // TODO: use vendor's actual ward
        final newRoute = await _service.createRoute(
          wardId: defaultWardId,
          name: routeName,
        );
        final newRoutes = [...state.routes, newRoute];
        state = state.copyWith(routes: newRoutes);
        route = newRoute;
      }

      final routeId = route['id'] as int;

      // 3) Create slot
      final createdSlot = await _service.createSlot(
        routeId: routeId,
        date: date,
        startTime: startDateTime,
        endTime: endDateTime,
        capacity: capacity,
      );

      final uiSlot = _slotToUiMap(routeName, createdSlot);
      final updatedSlots = [uiSlot, ...state.slots];
      state = state.copyWith(slots: updatedSlots);

      return null;
    } catch (_) {
      return 'Failed to publish slot. Please try again.';
    } finally {
      state = state.copyWith(isPublishing: false);
    }
  }
}

/// Riverpod 3 provider using NotifierProvider
final tankerBookingControllerProvider =
NotifierProvider<TankerBookingController, TankerBookingState>(
      () => TankerBookingController(),
);