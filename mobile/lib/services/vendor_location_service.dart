import 'dart:async';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:geolocator/geolocator.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

/// Periodically saves the vendor's GPS to the backend DB every 15 seconds
/// during an active booking/delivery. Stops automatically on dispose.
///
/// This runs ALONGSIDE the socket broadcast — belt-and-suspenders:
/// • Socket: instant broadcast to resident map
/// • REST: durable DB save so resident can poll even if socket drops
class VendorLocationService {
  static const String _baseUrl = 'https://hamro-pani-fyp-backend.onrender.com';
  static const Duration _interval = Duration(seconds: 15);

  Timer? _timer;
  bool _running = false;

  /// Starts the periodic location push. Call from VendorRouteView.initState().
  Future<void> start() async {
    if (_running) return;
    _running = true;

    // Send immediately on start (don't wait 15s for first update)
    await _sendLocation();

    _timer = Timer.periodic(_interval, (_) async {
      if (!_running) return;
      await _sendLocation();
    });

    debugPrint('VendorLocationService: started (every ${_interval.inSeconds}s)');
  }

  /// Stops the timer. Call from VendorRouteView.dispose().
  void stop() {
    _running = false;
    _timer?.cancel();
    _timer = null;
    debugPrint('VendorLocationService: stopped');
  }

  Future<void> _sendLocation() async {
    try {
      // Get current position
      final pos = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
      );

      // Get Firebase auth token
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) {
        debugPrint('VendorLocationService: no Firebase user — skipping');
        return;
      }
      final token = await user.getIdToken(false); // false = use cached token
      if (token == null) return;

      // POST to backend
      final res = await http.post(
        Uri.parse('$_baseUrl/vendors/location'),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
        body: jsonEncode({
          'lat': pos.latitude,
          'lng': pos.longitude,
        }),
      ).timeout(const Duration(seconds: 8));

      if (res.statusCode == 200) {
        debugPrint(
          'VendorLocationService: saved (${pos.latitude.toStringAsFixed(5)}, '
          '${pos.longitude.toStringAsFixed(5)})',
        );
      } else {
        debugPrint('VendorLocationService: backend error ${res.statusCode}');
      }
    } on TimeoutException {
      debugPrint('VendorLocationService: request timed out');
    } catch (e) {
      // Non-fatal — don't crash the vendor's screen if network fails
      debugPrint('VendorLocationService: error $e');
    }
  }
}
