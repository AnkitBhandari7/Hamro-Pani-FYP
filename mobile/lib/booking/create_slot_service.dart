
import 'package:dio/dio.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

class CreateSlotService {
  const CreateSlotService(this._dio);
  final Dio _dio;


  Map<String, dynamic> _unwrapSlot(dynamic data) {
    if (data is Map) {
      final map = Map<String, dynamic>.from(data);

      if (map['slot'] is Map) {
        return Map<String, dynamic>.from(map['slot'] as Map);
      }

      if (map['data'] is Map) {
        return Map<String, dynamic>.from(map['data'] as Map);
      }

      return map;
    }
    throw Exception('Unexpected response format (expected Map)');
  }

  Future<List<Map<String, dynamic>>> fetchMyRoutes() async {
    final response = await _dio.get('/vendors/routes/my');
    final list = response.data as List<dynamic>;
    return list.map((e) => Map<String, dynamic>.from(e as Map)).toList();
  }

  Future<Map<String, dynamic>> createRoute({
    int? wardId,
    String? ward,
    required DateTime routeDate,
    required String location,
  }) async {
    final response = await _dio.post(
      '/vendors/routes',
      data: {
        if (wardId != null) 'wardId': wardId,
        if (ward != null && ward.trim().isNotEmpty) 'ward': ward.trim(),
        'routeDate': DateFormat('yyyy-MM-dd').format(routeDate),
        'location': location.trim(),
      },
    );

    return Map<String, dynamic>.from(response.data as Map);
  }

  //  create slot (booking slots + price + tanker liters)
  Future<Map<String, dynamic>> createSlot({
    required int routeId,
    required DateTime startTime,
    required DateTime endTime,
    required int bookingSlots,
    required int price,
    required int tankerCapacityLiters,
  }) async {
    final response = await _dio.post(
      '/vendors/routes/$routeId/slots',
      data: {
        'startTime': startTime.toUtc().toIso8601String(),
        'endTime': endTime.toUtc().toIso8601String(),
        'capacity': bookingSlots, // backend uses "capacity" for booking slots
        'price': price,
        'tankerCapacityLiters': tankerCapacityLiters,
      },
    );

    return _unwrapSlot(response.data);
  }

  // update slot
  Future<Map<String, dynamic>> updateSlot({
    required int slotId,
    DateTime? startTime,
    DateTime? endTime,
    int? bookingSlots,
    int? price,
    int? tankerCapacityLiters,
  }) async {
    final response = await _dio.patch(
      '/vendors/slots/$slotId',
      data: {
        if (startTime != null) 'startTime': startTime.toUtc().toIso8601String(),
        if (endTime != null) 'endTime': endTime.toUtc().toIso8601String(),
        if (bookingSlots != null) 'capacity': bookingSlots,
        if (price != null) 'price': price,
        if (tankerCapacityLiters != null) 'tankerCapacityLiters': tankerCapacityLiters,
      },
    );

    return _unwrapSlot(response.data);
  }

  Future<Map<String, dynamic>> markSlotFull(int slotId) async {
    final response = await _dio.patch('/vendors/slots/$slotId/mark-full');
    return _unwrapSlot(response.data);
  }

  Future<void> deleteSlot(int slotId) async {
    await _dio.delete('/vendors/slots/$slotId');
  }

  // UI helpers
  String buildDateLabel(DateTime date) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final target = DateTime(date.year, date.month, date.day);

    if (target == today) return 'TODAY';
    final tomorrow = today.add(const Duration(days: 1));
    if (target == tomorrow) return 'TOMORROW';

    return DateFormat('MMM dd').format(date).toUpperCase();
  }

  String buildTimeRange(DateTime start, DateTime end) {
    final fmt = DateFormat('hh:mm a');
    return '${fmt.format(start.toLocal())} - ${fmt.format(end.toLocal())}';
  }
}

//Providers

final firebaseAuthProvider = Provider<FirebaseAuth>((ref) => FirebaseAuth.instance);

final apiBaseUrlProvider = Provider<String>((ref) {
  const fromEnv = String.fromEnvironment('API_BASE_URL');
  if (fromEnv.isNotEmpty) return fromEnv;

  if (defaultTargetPlatform == TargetPlatform.android) {
    return 'http://10.0.2.2:3000';
  }
  return 'http://localhost:3000';
});

final apiDioProvider = Provider<Dio>((ref) {
  final auth = ref.watch(firebaseAuthProvider);
  final baseUrl = ref.watch(apiBaseUrlProvider);

  final dio = Dio(
    BaseOptions(
      baseUrl: baseUrl,
      connectTimeout: const Duration(seconds: 15),
      receiveTimeout: const Duration(seconds: 15),
      headers: {'Content-Type': 'application/json'},
    ),
  );

  dio.interceptors.add(
    InterceptorsWrapper(
      onRequest: (options, handler) async {
        debugPrint(' [DIO] ${options.method} ${options.uri}');
        final user = auth.currentUser;
        if (user != null) {
          final token = await user.getIdToken();
          options.headers['Authorization'] = 'Bearer $token';
        }
        return handler.next(options);
      },
      onError: (e, handler) {
        debugPrint(' [DIO] ${e.response?.statusCode} ${e.requestOptions.uri}');
        debugPrint(' [DIO] ${e.response?.data}');
        return handler.next(e);
      },
    ),
  );

  return dio;
});

final createSlotServiceProvider = Provider<CreateSlotService>((ref) {
  final dio = ref.watch(apiDioProvider);
  return CreateSlotService(dio);
});