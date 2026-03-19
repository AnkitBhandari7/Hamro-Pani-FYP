import 'dart:async';
import 'dart:convert';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:geolocator/geolocator.dart';
import 'package:http/http.dart' as http;
import 'package:latlong2/latlong.dart';

import '../routing/osrm_route_service.dart';

class VendorRouteView extends StatefulWidget {
  final int bookingId;
  const VendorRouteView({super.key, required this.bookingId});

  @override
  State<VendorRouteView> createState() => _VendorRouteViewState();
}

class _VendorRouteViewState extends State<VendorRouteView> {
  static const String _baseUrl = "http://10.0.2.2:3000";

  final _map = MapController();
  final _osrm = OsrmRouteService();

  LatLng? _vendor;
  LatLng? _dest;
  String _destLabel = "";
  String _status = "Loading destination...";
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
    _loadDestination();
    _startVendorLocation();
  }

  Future<void> _loadDestination() async {
    try {
      final t = await _token();
      if (t == null) throw Exception("Not authenticated");

      final res = await http.get(
        Uri.parse("$_baseUrl/vendors/bookings/${widget.bookingId}/destination"),
        headers: {'Authorization': 'Bearer $t'},
      );

      if (res.statusCode != 200) {
        throw Exception("HTTP ${res.statusCode}: ${res.body}");
      }

      final data = jsonDecode(res.body) as Map<String, dynamic>;
      final d = data['destination'] as Map<String, dynamic>;

      final dest = LatLng((d['lat'] as num).toDouble(), (d['lng'] as num).toDouble());

      setState(() {
        _dest = dest;
        _destLabel = (d['label'] ?? 'Destination').toString();
        _status = "Destination loaded";
      });

      _map.move(dest, 14);

      // Try load route if vendor location already known
      _scheduleRouteUpdate();
    } catch (e) {
      setState(() => _status = "Destination load failed: $e");
    }
  }

  Future<void> _startVendorLocation() async {
    try {
      final enabled = await Geolocator.isLocationServiceEnabled();
      if (!enabled) throw Exception("Location is disabled");

      var perm = await Geolocator.checkPermission();
      if (perm == LocationPermission.denied) perm = await Geolocator.requestPermission();
      if (perm == LocationPermission.denied || perm == LocationPermission.deniedForever) {
        throw Exception("Location permission denied");
      }

      _posSub = Geolocator.getPositionStream(
        locationSettings: const LocationSettings(
          accuracy: LocationAccuracy.high,
          distanceFilter: 5,
        ),
      ).listen((pos) {
        final p = LatLng(pos.latitude, pos.longitude);
        setState(() => _vendor = p);

        _map.move(p, 16);

        _scheduleRouteUpdate();
      });

      setState(() => _status = "Tracking vendor location...");
    } catch (e) {
      setState(() => _status = "Vendor tracking failed: $e");
    }
  }

  void _scheduleRouteUpdate() {
    if (_vendor == null || _dest == null) return;

    _routeDebounce?.cancel();
    _routeDebounce = Timer(const Duration(seconds: 2), () async {
      await _loadRoute();
    });
  }

  Future<void> _loadRoute() async {
    final v = _vendor;
    final d = _dest;
    if (v == null || d == null) return;

    try {
      final pts = await _osrm.getDrivingRoute(start: v, end: d);
      if (!mounted) return;
      setState(() => _route = pts);
    } catch (e) {
      // non-fatal
      debugPrint("Route error: $e");
    }
  }

  @override
  void dispose() {
    _posSub?.cancel();
    _routeDebounce?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final center = _vendor ?? _dest ?? const LatLng(27.7172, 85.3240);

    return Scaffold(
      appBar: AppBar(title: Text("Route to Resident (#${widget.bookingId})")),
      body: Column(
        children: [
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(12),
            color: Colors.black87,
            child: Text(_status, style: const TextStyle(color: Colors.white)),
          ),
          Expanded(
            child: FlutterMap(
              mapController: _map,
              options: MapOptions(initialCenter: center, initialZoom: 14),
              children: [
                TileLayer(
                  urlTemplate: "https://tile.openstreetmap.org/{z}/{x}/{y}.png",
                  userAgentPackageName: "com.example.fyp",
                ),
                if (_route.isNotEmpty)
                  PolylineLayer(
                    polylines: [
                      Polyline(points: _route, strokeWidth: 5, color: Colors.blue),
                    ],
                  ),
                MarkerLayer(
                  markers: [
                    if (_vendor != null)
                      Marker(
                        point: _vendor!,
                        width: 50,
                        height: 50,
                        child: const Icon(Icons.local_shipping, color: Colors.blue, size: 36),
                      ),
                    if (_dest != null)
                      Marker(
                        point: _dest!,
                        width: 50,
                        height: 50,
                        child: const Icon(Icons.flag, color: Colors.red, size: 36),
                      ),
                  ],
                ),
              ],
            ),
          ),
          if (_dest != null)
            Padding(
              padding: const EdgeInsets.all(12),
              child: Text(
                "Destination: $_destLabel",
                style: const TextStyle(fontWeight: FontWeight.w600),
              ),
            ),
        ],
      ),
    );
  }
}