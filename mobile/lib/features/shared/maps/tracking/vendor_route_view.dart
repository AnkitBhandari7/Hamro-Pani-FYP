import 'dart:async';
import 'dart:convert';
import 'dart:math' as math;

import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:geolocator/geolocator.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:http/http.dart' as http;
import 'package:latlong2/latlong.dart';

import '../routing/osrm_route_service.dart';
import 'socket_tracking_service.dart';
import '../../../../services/vendor_location_service.dart';

/// Vendor's active delivery map screen (Pathao-style).
/// Shows vendor's own moving location + resident's destination.
/// • Socket: instant broadcast to resident
/// • REST (VendorLocationService): durable DB save every 15s
class VendorRouteView extends StatefulWidget {
  final int bookingId;
  const VendorRouteView({super.key, required this.bookingId});

  @override
  State<VendorRouteView> createState() => _VendorRouteViewState();
}

class _VendorRouteViewState extends State<VendorRouteView> {
  static const String _baseUrl = 'https://hamro-pani-fyp-backend.onrender.com';

  final _map = MapController();
  final _osrm = OsrmRouteService();
  late final SocketTrackingService _socket;
  late final VendorLocationService _locationService;

  LatLng? _vendor;
  double _heading = 0.0;
  LatLng? _dest;
  String _destLabel = '';
  String _status = 'Loading destination...';
  List<LatLng> _route = [];

  StreamSubscription<Position>? _posSub;
  Timer? _routeDebounce;

  Future<String?> _token() async {
    final u = FirebaseAuth.instance.currentUser;
    if (u == null) return null;
    return await u.getIdToken(true);
  }

  @override
  void initState() {
    super.initState();

    // Socket — instant broadcast to resident
    _socket = SocketTrackingService(serverUrl: _baseUrl);
    _socket.connect();
    _socket.onConnect(() => _socket.joinTrip(widget.bookingId.toString()));

    // REST — durable DB save every 15 s
    _locationService = VendorLocationService();
    _locationService.start();

    _loadDestination();
    _startVendorLocation();
  }

  Future<void> _loadDestination() async {
    try {
      final t = await _token();
      if (t == null) throw Exception('Not authenticated');

      final res = await http.get(
        Uri.parse('$_baseUrl/vendors/bookings/${widget.bookingId}/destination'),
        headers: {'Authorization': 'Bearer $t'},
      );

      if (res.statusCode != 200) {
        throw Exception('HTTP ${res.statusCode}: ${res.body}');
      }

      final data = jsonDecode(res.body) as Map<String, dynamic>;
      final d = data['destination'] as Map<String, dynamic>;

      final dest = LatLng(
        (d['lat'] as num).toDouble(),
        (d['lng'] as num).toDouble(),
      );

      setState(() {
        _dest = dest;
        _destLabel = (d['label'] ?? 'Destination').toString();
        _status = 'Navigating to ${_destLabel}';
      });

      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) _map.move(dest, 14);
      });
      _scheduleRouteUpdate();
    } catch (e) {
      setState(() => _status = 'Failed to load destination');
    }
  }

  Future<void> _startVendorLocation() async {
    try {
      final enabled = await Geolocator.isLocationServiceEnabled();
      if (!enabled) throw Exception('Location disabled');

      var perm = await Geolocator.checkPermission();
      if (perm == LocationPermission.denied) {
        perm = await Geolocator.requestPermission();
      }
      if (perm == LocationPermission.denied ||
          perm == LocationPermission.deniedForever) {
        throw Exception('Location permission denied');
      }

      // 1. Instant grab — renders map immediately without waiting for movement
      Position? pos = await Geolocator.getLastKnownPosition();
      if (pos != null) {
         _updateVendorPosition(pos);
      }

      // 2. Fetch fresh but don't hang if GPS is weak or emulator is mocked poorly
      try {
        pos = await Geolocator.getCurrentPosition(
          desiredAccuracy: LocationAccuracy.high,
          timeLimit: const Duration(seconds: 10),
        );
        _updateVendorPosition(pos);
      } catch (e) {
        debugPrint('Geolocator getCurrentPosition timed out or failed: $e');
      }

      // 2. Continuous stream for live movement
      _posSub = Geolocator.getPositionStream(
        locationSettings: const LocationSettings(
          accuracy: LocationAccuracy.high,
          distanceFilter: 5, // metres
        ),
      ).listen(_updateVendorPosition);

      setState(() => _status = 'Live tracking active...');
    } catch (e) {
      setState(() => _status = 'Location error: $e');
    }
  }

  void _updateVendorPosition(Position pos) {
    final p = LatLng(pos.latitude, pos.longitude);
    final hdg = pos.heading.isFinite ? pos.heading : 0.0;

    if (!mounted) return;
    setState(() {
      _vendor = p;
      _heading = hdg;
    });

    // Broadcast via socket (instant for resident)
    _socket.sendUpdate(
      tripId: widget.bookingId.toString(),
      lat: pos.latitude,
      lng: pos.longitude,
      heading: pos.heading.isFinite ? pos.heading : null,
      speed: pos.speed.isFinite ? pos.speed : null,
    );

    _map.move(p, 16);
    _scheduleRouteUpdate();
  }

  void _scheduleRouteUpdate() {
    if (_vendor == null || _dest == null) return;
    _routeDebounce?.cancel();
    _routeDebounce = Timer(const Duration(seconds: 2), _loadRoute);
  }

  Future<void> _loadRoute() async {
    final v = _vendor;
    final d = _dest;
    if (v == null || d == null) return;
    try {
      final pts = await _osrm.getDrivingRoute(start: v, end: d);
      if (!mounted) return;
      setState(() => _route = pts);
    } catch (_) {}
  }

  @override
  void dispose() {
    _socket.disconnect();
    _locationService.stop();
    _posSub?.cancel();
    _routeDebounce?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final center = _vendor ?? _dest ?? const LatLng(27.7172, 85.3240);

    return Scaffold(
      backgroundColor: const Color(0xFF0F172A),
      appBar: AppBar(
        backgroundColor: const Color(0xFF1E293B),
        foregroundColor: Colors.white,
        title: Text(
          'Delivery #${widget.bookingId}',
          style: GoogleFonts.poppins(fontWeight: FontWeight.w600, fontSize: 16),
        ),
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(32),
          child: Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
            color: const Color(0xFF0F172A),
            child: Text(
              _status,
              style: GoogleFonts.poppins(
                fontSize: 12,
                color: const Color(0xFF94A3B8),
              ),
            ),
          ),
        ),
      ),
      body: Column(
        children: [
          Expanded(
            child: FlutterMap(
              mapController: _map,
              options: MapOptions(initialCenter: center, initialZoom: 15),
              children: [
                TileLayer(
                  urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                  userAgentPackageName: 'com.hamropani.fyp',
                ),
                if (_route.isNotEmpty)
                  PolylineLayer(
                    polylines: [
                      Polyline(
                        points: _route,
                        strokeWidth: 5,
                        color: const Color(0xFF3B82F6).withValues(alpha: 0.85),
                        strokeJoin: StrokeJoin.round,
                        strokeCap: StrokeCap.round,
                      ),
                    ],
                  ),
                MarkerLayer(
                  markers: [
                    // Resident destination — red drop-pin
                    if (_dest != null)
                      Marker(
                        point: _dest!,
                        width: 50,
                        height: 60,
                        child: Column(
                          children: [
                            Container(
                              padding: const EdgeInsets.all(6),
                              decoration: BoxDecoration(
                                color: const Color(0xFFEF4444),
                                shape: BoxShape.circle,
                                boxShadow: [
                                  BoxShadow(
                                    color: Colors.black.withValues(alpha: 0.4),
                                    blurRadius: 8,
                                    offset: const Offset(0, 4),
                                  ),
                                ],
                              ),
                              child: const Icon(
                                Icons.home_rounded,
                                color: Colors.white,
                                size: 18,
                              ),
                            ),
                            const SizedBox(
                              height: 2,
                              width: 2,
                              child: DecoratedBox(
                                decoration: BoxDecoration(color: Color(0xFFEF4444)),
                              ),
                            ),
                          ],
                        ),
                      ),
                    // Vendor vehicle — rotating navigation arrow
                    if (_vendor != null)
                      Marker(
                        point: _vendor!,
                        width: 54,
                        height: 54,
                        child: Transform.rotate(
                          angle: _heading * (math.pi / 180),
                          child: Container(
                            decoration: BoxDecoration(
                              color: Colors.white,
                              shape: BoxShape.circle,
                              border: Border.all(
                                  color: const Color(0xFF3B82F6), width: 2.5),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withValues(alpha: 0.35),
                                  blurRadius: 12,
                                  offset: const Offset(0, 4),
                                ),
                              ],
                            ),
                            child: const Center(
                              child: Icon(
                                Icons.local_shipping_rounded,
                                color: Color(0xFF3B82F6),
                                size: 28,
                              ),
                            ),
                          ),
                        ),
                      ),
                  ],
                ),
              ],
            ),
          ),
          // Bottom info bar
          if (_dest != null)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
              decoration: const BoxDecoration(
                color: Color(0xFF1E293B),
                border: Border(
                  top: BorderSide(color: Color(0xFF334155)),
                ),
              ),
              child: Row(
                children: [
                  const Icon(Icons.location_on_rounded,
                      color: Color(0xFFEF4444), size: 20),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'Delivering to: $_destLabel',
                      style: GoogleFonts.poppins(
                        color: Colors.white,
                        fontWeight: FontWeight.w600,
                        fontSize: 14,
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }
}
