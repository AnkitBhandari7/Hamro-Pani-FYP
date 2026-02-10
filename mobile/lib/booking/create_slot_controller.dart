import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'create_slot_service.dart';

class CreateSlotState {
  final String selectedDateFilter; // Today | Tomorrow | Custom
  final TimeOfDay? selectedStartTime;

  final List<Map<String, dynamic>> routes; // raw backend routes
  final List<Map<String, dynamic>> slots;  // UI-ready slots

  final bool isLoading;
  final bool isPublishing;

  const CreateSlotState({
    this.selectedDateFilter = 'Today',
    this.selectedStartTime,
    this.routes = const [],
    this.slots = const [],
    this.isLoading = false,
    this.isPublishing = false,
  });

  CreateSlotState copyWith({
    String? selectedDateFilter,
    TimeOfDay? selectedStartTime,
    List<Map<String, dynamic>>? routes,
    List<Map<String, dynamic>>? slots,
    bool? isLoading,
    bool? isPublishing,
  }) {
    return CreateSlotState(
      selectedDateFilter: selectedDateFilter ?? this.selectedDateFilter,
      selectedStartTime: selectedStartTime ?? this.selectedStartTime,
      routes: routes ?? this.routes,
      slots: slots ?? this.slots,
      isLoading: isLoading ?? this.isLoading,
      isPublishing: isPublishing ?? this.isPublishing,
    );
  }
}

class CreateSlotController extends Notifier<CreateSlotState> {
  late final CreateSlotService _service;

  @override
  CreateSlotState build() {
    _service = ref.read(createSlotServiceProvider);
    Future.microtask(loadInitialData);
    return const CreateSlotState();
  }

  // Student note: refresh vendor routes + slots
  Future<void> loadInitialData() async {
    state = state.copyWith(isLoading: true);
    try {
      final routes = await _service.fetchMyRoutes();
      final slots = _buildSlotsFromRoutes(routes);
      state = state.copyWith(routes: routes, slots: slots);
    } catch (e, st) {
      debugPrint('loadInitialData error: $e');
      debugPrint(st.toString());
      state = state.copyWith(routes: const [], slots: const []);
    } finally {
      state = state.copyWith(isLoading: false);
    }
  }

  List<Map<String, dynamic>> _buildSlotsFromRoutes(List<Map<String, dynamic>> routes) {
    final uiSlots = <Map<String, dynamic>>[];

    for (final route in routes) {
      final routeLocation = (route['location'] ?? '').toString();

      final slotList = (route['slots'] as List<dynamic>? ?? [])
          .map((e) => Map<String, dynamic>.from(e as Map))
          .toList();

      for (final slotJson in slotList) {
        uiSlots.add(_slotToUiMap(routeLocation, slotJson));
      }
    }

    return uiSlots;
  }

  Map<String, dynamic> _slotToUiMap(String routeLocation, Map<String, dynamic> slotJson) {
    // ERD fields
    final capacity = (slotJson['capacity'] ?? 0) as int;
    final bookedCount = (slotJson['bookedCount'] ?? 0) as int;

    final startStr = slotJson['startTime']?.toString() ?? '';
    final endStr = slotJson['endTime']?.toString() ?? '';

    final start = DateTime.tryParse(startStr) ?? DateTime.now();
    final end = DateTime.tryParse(endStr) ?? start.add(const Duration(hours: 2));

    final dateLabel = _service.buildDateLabel(start);
    final timeRange = _service.buildTimeRange(start, end);

    // Student note: compute status from counts
    final uiStatus = bookedCount >= capacity ? 'FULL' : 'OPEN';

    return {
      'slotId': slotJson['id'],
      'date': dateLabel,
      'time': timeRange,
      'status': uiStatus,
      'location': routeLocation,
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
    final dt = DateTime(now.year, now.month, now.day, time.hour, time.minute);
    final range = _service.buildTimeRange(dt, dt);
    return range.split(' - ').first;
  }

  // Student note: publish = create route (if needed) then create slot
  Future<String?> publishSlot({
    required String capacityText,
    required String routeText, // we will use this as "location"
  }) async {
    if (state.selectedStartTime == null) return 'Please select a start time';

    final capacity = int.tryParse(capacityText.trim());
    if (capacity == null || capacity <= 0) return 'Please enter a valid capacity';

    final location = routeText.trim();
    if (location.isEmpty) return 'Please enter a delivery route/area';

    // Student note: choose date from chips
    final now = DateTime.now();
    DateTime routeDate;
    if (state.selectedDateFilter == 'Tomorrow') {
      final t = now.add(const Duration(days: 1));
      routeDate = DateTime(t.year, t.month, t.day);
    } else {
      routeDate = DateTime(now.year, now.month, now.day);
    }

    final startDateTime = DateTime(
      routeDate.year,
      routeDate.month,
      routeDate.day,
      state.selectedStartTime!.hour,
      state.selectedStartTime!.minute,
    );
    final endDateTime = startDateTime.add(const Duration(hours: 2));

    state = state.copyWith(isPublishing: true);

    try {
      // Student note: try to reuse route for same day + same location
      Map<String, dynamic>? route;
      for (final r in state.routes) {
        final rLocation = (r['location'] ?? '').toString().toLowerCase();
        final rDateStr = (r['routeDate'] ?? '').toString();
        final rDate = DateTime.tryParse(rDateStr);

        final sameDay = rDate != null &&
            rDate.year == routeDate.year &&
            rDate.month == routeDate.month &&
            rDate.day == routeDate.day;

        if (sameDay && rLocation == location.toLowerCase()) {
          route = r;
          break;
        }
      }

      // Student note: if route not found, create new one
      if (route == null) {
        // TODO: best is to use vendor's real wardId from /auth/me
        const defaultWardId = 1;

        final newRoute = await _service.createRoute(
          wardId: defaultWardId,
          routeDate: routeDate,
          location: location,
        );

        state = state.copyWith(routes: [...state.routes, newRoute]);
        route = newRoute;
      }

      final routeId = route['id'] as int;

      // Student note: create slot under that route
      final createdSlot = await _service.createSlot(
        routeId: routeId,
        startTime: startDateTime,
        endTime: endDateTime,
        capacity: capacity,
      );

      final uiSlot = _slotToUiMap(location, createdSlot);
      state = state.copyWith(slots: [uiSlot, ...state.slots]);

      return null;
    } catch (e, st) {
      debugPrint('publishSlot error: $e');
      debugPrint(st.toString());
      return 'Failed to publish slot. Please try again.';
    } finally {
      state = state.copyWith(isPublishing: false);
    }
  }
}

final createSlotControllerProvider =
NotifierProvider<CreateSlotController, CreateSlotState>(() => CreateSlotController());