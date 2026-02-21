import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'create_slot_service.dart';

class CreateSlotState {
  final String selectedDateFilter; // Today | Tomorrow
  final TimeOfDay? selectedStartTime;

  final List<Map<String, dynamic>> routes; // raw backend routes
  final List<Map<String, dynamic>> slots; // UI-ready slots

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

class CreateSlotController extends AutoDisposeNotifier<CreateSlotState> {
  late final CreateSlotService _service;

  @override
  CreateSlotState build() {
    _service = ref.read(createSlotServiceProvider);
    Future.microtask(loadInitialData);
    return const CreateSlotState();
  }


  // Helpers

  int _asInt(dynamic v, {int fallback = 0}) {
    if (v is int) return v;
    if (v is num) return v.toInt();
    return int.tryParse((v ?? '').toString()) ?? fallback;
  }

  DateTime? _parseToLocalDateTime(dynamic raw) {
    if (raw == null) return null;

    if (raw is DateTime) return raw.toLocal();

    final s = raw.toString().trim();
    if (s.isEmpty) return null;

    try {

      return DateTime.parse(s).toLocal();
    } catch (_) {
      return null;
    }
  }

  DateTime _dateOnly(DateTime d) => DateTime(d.year, d.month, d.day);


  // Load

  Future<void> loadInitialData() async {
    state = state.copyWith(isLoading: true);
    try {
      final routes = await _service.fetchMyRoutes();
      final slots = _buildSlotsFromRoutes(routes);
      state = state.copyWith(routes: routes, slots: slots);
    } catch (e) {
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

    // sort by newest start time
    uiSlots.sort((a, b) {
      final ad = a['startDt'] as DateTime? ?? DateTime(0);
      final bd = b['startDt'] as DateTime? ?? DateTime(0);
      return bd.compareTo(ad);
    });

    return uiSlots;
  }

  Map<String, dynamic> _slotToUiMap(String routeLocation, Map<String, dynamic> slotJson) {
    final capacity = _asInt(slotJson['capacity']);
    final bookedCount = _asInt(slotJson['bookedCount']);
    final price = slotJson['price'];

    // Parse backend times and force LOCAL
    final start = _parseToLocalDateTime(slotJson['startTime']) ?? DateTime.now();
    final end =
        _parseToLocalDateTime(slotJson['endTime']) ?? start.add(const Duration(hours: 2));

    // Build labels from LOCAL times
    final dateLabel = _service.buildDateLabel(start);
    final timeRange = _service.buildTimeRange(start, end);

    final uiStatus = bookedCount >= capacity && capacity > 0 ? 'FULL' : 'OPEN';

    return {
      'slotId': _asInt(slotJson['id']),
      'date': dateLabel,
      'time': timeRange,
      'status': uiStatus,
      'location': routeLocation,
      'booked': bookedCount,
      'total': capacity,
      'price': price,
      'startDt': start,
      'endDt': end,
    };
  }


  // UI setters

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


  // CREATE

  Future<String?> publishSlot({
    required String capacityText,
    required String priceText,
    required String routeText,
  }) async {
    if (state.selectedStartTime == null) return 'Please select a start time';

    final capacity = int.tryParse(capacityText.trim());
    if (capacity == null || capacity <= 0) return 'Please enter a valid capacity';

    final price = int.tryParse(priceText.trim());
    if (price == null || price <= 0) return 'Please enter a valid price';

    final location = routeText.trim();
    if (location.isEmpty) return 'Please enter a delivery route/area';


    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);

    final routeDate = state.selectedDateFilter == 'Tomorrow'
        ? today.add(const Duration(days: 1))
        : today;

    // local selected start/end (service will send UTC)
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
      // reuse route for same day + same location
      Map<String, dynamic>? route;
      for (final r in state.routes) {
        final rLocation = (r['location'] ?? '').toString().toLowerCase();


        final rDate = _parseToLocalDateTime(r['routeDate']);
        final sameDay = rDate != null && _dateOnly(rDate) == _dateOnly(routeDate);

        if (sameDay && rLocation == location.toLowerCase()) {
          route = r;
          break;
        }
      }

      if (route == null) {
        const defaultWardId = 1;
        final newRoute = await _service.createRoute(
          wardId: defaultWardId,
          routeDate: routeDate,
          location: location,
        );
        state = state.copyWith(routes: [...state.routes, newRoute]);
        route = newRoute;
      }

      final routeId = _asInt(route['id']);
      if (routeId <= 0) return 'Invalid routeId received from backend';

      final createdSlot = await _service.createSlot(
        routeId: routeId,
        startTime: startDateTime,
        endTime: endDateTime,
        capacity: capacity,
        price: price,
      );

      final uiSlot = _slotToUiMap(location, createdSlot);
      state = state.copyWith(slots: [uiSlot, ...state.slots]);

      return null;
    } catch (e) {
      return 'Failed to publish slot. Please try again.';
    } finally {
      state = state.copyWith(isPublishing: false);
    }
  }


  // UPDATE

  Future<String?> updateSlot({
    required int slotId,
    required String location,
    DateTime? startTime,
    DateTime? endTime,
    int? capacity,
    int? price,
  }) async {
    try {
      final updated = await _service.updateSlot(
        slotId: slotId,
        startTime: startTime,
        endTime: endTime,
        capacity: capacity,
        price: price,
      );

      final updatedUi = _slotToUiMap(location, updated);

      final newSlots = [...state.slots];
      final idx = newSlots.indexWhere((s) => s['slotId'] == slotId);
      if (idx != -1) newSlots[idx] = updatedUi;

      state = state.copyWith(slots: newSlots);
      return null;
    } catch (e) {
      return 'Failed to update slot';
    }
  }


  // UPDATE (Mark Full)

  Future<String?> markFull(int slotId, String location) async {
    try {
      final updated = await _service.markSlotFull(slotId);
      final updatedUi = _slotToUiMap(location, updated);

      final newSlots = [...state.slots];
      final idx = newSlots.indexWhere((s) => s['slotId'] == slotId);
      if (idx != -1) newSlots[idx] = updatedUi;

      state = state.copyWith(slots: newSlots);
      return null;
    } catch (e) {
      return 'Failed to mark full';
    }
  }


  // DELETE

  Future<String?> deleteSlot(int slotId) async {
    try {
      await _service.deleteSlot(slotId);
      state = state.copyWith(
        slots: state.slots.where((s) => s['slotId'] != slotId).toList(),
      );
      return null;
    } catch (e) {
      return 'Failed to delete slot';
    }
  }
}

// autoDispose provider
final createSlotControllerProvider =
AutoDisposeNotifierProvider<CreateSlotController, CreateSlotState>(
    CreateSlotController.new);