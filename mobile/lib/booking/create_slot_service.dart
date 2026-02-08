
import 'package:dio/dio.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

class CreateSlotService {
  const CreateSlotService(this._dio);

  final Dio _dio;

  /// GET /vendors/routes/my
  Future<List<Map<String, dynamic>>> fetchMyRoutes() async {
    final response = await _dio.get('/vendors/routes/my');

    final list = response.data as List<dynamic>;
    return list
        .map((e) => Map<String, dynamic>.from(e as Map))
        .toList();
  }

  /// POST /vendors/routes

  Future<Map<String, dynamic>> createRoute({
    int? wardId,
    String? ward,
    required String name,
    String? description,
  }) async {
    if ((ward == null || ward.trim().isEmpty) && wardId == null) {
      throw ArgumentError('Either ward or wardId must be provided');
    }

    final response = await _dio.post(
      '/vendors/routes',
      data: {
        if (wardId != null) 'wardId': wardId,
        if (ward != null && ward.trim().isNotEmpty) 'ward': ward.trim(),
        'name': name,
        if (description != null && description.trim().isNotEmpty)
          'description': description.trim(),
      },
    );

    return Map<String, dynamic>.from(response.data as Map);
  }

  /// POST /vendors/routes/:routeId/slots
  Future<Map<String, dynamic>> createSlot({
    required int routeId,
    required DateTime date,
    required DateTime startTime,
    required DateTime endTime,
    required int capacity,
  }) async {
    // Send date-only so backend parses it cleanly
    final dateOnly = DateFormat('yyyy-MM-dd').format(date);

    final response = await _dio.post(
      '/vendors/routes/$routeId/slots',
      data: {
        'date': dateOnly,
        'startTime': startTime.toIso8601String(),
        'endTime': endTime.toIso8601String(),
        'capacity': capacity,
      },
    );

    return Map<String, dynamic>.from(response.data as Map);
  }

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
    return '${fmt.format(start)} - ${fmt.format(end)}';
  }
}


// Providers


final firebaseAuthProvider = Provider<FirebaseAuth>((ref) {
  return FirebaseAuth.instance;
});

/// Base URL provider:
/// - Android emulator: http://10.0.2.2:3000

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
      baseUrl: baseUrl, // <-- THIS MUST MATCH YOUR NODE SERVER
      connectTimeout: const Duration(seconds: 15),
      receiveTimeout: const Duration(seconds: 15),
      headers: {
        'Content-Type': 'application/json',
      },
    ),
  );

  dio.interceptors.add(
    InterceptorsWrapper(
      onRequest: (options, handler) async {
        // Debug: confirm the exact URL being hit
        debugPrint('➡️ [DIO] ${options.method} ${options.uri}');

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