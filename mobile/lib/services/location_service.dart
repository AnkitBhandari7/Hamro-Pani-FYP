import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:geolocator/geolocator.dart';

import 'api_service.dart';

/// Periodically sends the vendor's GPS coordinates to the backend while the
/// vendor app is in the foreground.  The backend stores them so residents can
/// poll for live tracking.
class LocationService {
  static const Duration _interval = Duration(seconds: 15);

  Timer? _timer;
  bool _running = false;

  bool get isRunning => _running;

  /// Request location permissions and start the 15-second update loop.
  Future<void> startVendorLocationUpdates() async {
    if (_running) return;

    final hasPermission = await _requestPermission();
    if (!hasPermission) {
      debugPrint('[LocationService] Permission denied – updates not started');
      return;
    }

    _running = true;
    // Send immediately, then every 15 seconds
    await sendLocationToBackend();
    _timer = Timer.periodic(_interval, (_) => sendLocationToBackend());
    debugPrint('[LocationService] Vendor location updates started');
  }

  /// Cancel the periodic timer and stop sending updates.
  void stopVendorLocationUpdates() {
    _timer?.cancel();
    _timer = null;
    _running = false;
    debugPrint('[LocationService] Vendor location updates stopped');
  }

  /// Fetch the current position and POST it to `POST /vendors/location`.
  Future<void> sendLocationToBackend() async {
    try {
      final enabled = await Geolocator.isLocationServiceEnabled();
      if (!enabled) return;

      final position = await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(
          accuracy: LocationAccuracy.high,
        ),
      );

      await ApiService.post('/vendors/location', {
        'lat': position.latitude,
        'lng': position.longitude,
      });

      debugPrint(
        '[LocationService] Sent location: '
        '${position.latitude}, ${position.longitude}',
      );
    } catch (e) {
      // Non-fatal – the next interval will retry
      debugPrint('[LocationService] sendLocationToBackend error: $e');
    }
  }

  // ---------------------------------------------------------------------------

  Future<bool> _requestPermission() async {
    bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) return false;

    LocationPermission perm = await Geolocator.checkPermission();
    if (perm == LocationPermission.denied) {
      perm = await Geolocator.requestPermission();
    }

    return perm == LocationPermission.whileInUse ||
        perm == LocationPermission.always;
  }
}
