import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';

import '../routing/osrm_route_service.dart';
import 'socket_tracking_service.dart';

class CustomerTrackView extends StatefulWidget {
  final String tripId;

  /// Resident destination
  final LatLng? destination;

  const CustomerTrackView({
    super.key,
    required this.tripId,
    this.destination,
  });

  @override
  State<CustomerTrackView> createState() => _CustomerTrackViewState();
}

class _CustomerTrackViewState extends State<CustomerTrackView> {
  static const String _serverUrl = "http://10.0.2.2:3000";

  final _map = MapController();
  late final SocketTrackingService _socket;

  final _osrm = OsrmRouteService();

  LatLng? _driver;
  List<LatLng> _routePoints = [];
  String _status = "Connecting...";

  Timer? _routeDebounce;

  @override
  void initState() {
    super.initState();

    _socket = SocketTrackingService(serverUrl: _serverUrl);
    _socket.connect();

    _socket.onConnect(() {
      setState(() => _status = "Connected");
      _socket.joinTrip(widget.tripId);
    });

    _socket.onDisconnect(() => setState(() => _status = "Disconnected"));
    _socket.onError((e) => setState(() => _status = "Socket error: $e"));

    _socket.onPosition((data) {
      if (data['tripId']?.toString() != widget.tripId) return;

      final lat = (data['lat'] as num).toDouble();
      final lng = (data['lng'] as num).toDouble();

      final p = LatLng(lat, lng);
      setState(() {
        _driver = p;
        _status = "Live";
      });

      _map.move(p, 16);

      // ✅ update route driver -> destination (throttle to avoid too many HTTP calls)
      if (widget.destination != null) {
        _routeDebounce?.cancel();
        _routeDebounce = Timer(const Duration(seconds: 2), () async {
          await _loadRoute();
        });
      }
    });

    // if destination exists but driver not yet => route waits
  }

  Future<void> _loadRoute() async {
    final driver = _driver;
    final dest = widget.destination;
    if (driver == null || dest == null) return;

    try {
      final pts = await _osrm.getDrivingRoute(start: driver, end: dest);
      if (!mounted) return;
      setState(() => _routePoints = pts);
    } catch (e) {
      // non-fatal
      debugPrint("OSRM route error: $e");
    }
  }

  @override
  void dispose() {
    _routeDebounce?.cancel();
    _socket.disconnect();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final center = _driver ?? widget.destination ?? const LatLng(27.7172, 85.3240);

    return Scaffold(
      appBar: AppBar(title: const Text("Track Driver")),
      body: Column(
        children: [
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(12),
            color: Colors.black87,
            child: Text(
              "Trip: ${widget.tripId} | $_status",
              style: const TextStyle(color: Colors.white),
            ),
          ),
          Expanded(
            child: FlutterMap(
              mapController: _map,
              options: MapOptions(
                initialCenter: center,
                initialZoom: 14,
              ),
              children: [
                TileLayer(
                  urlTemplate: "https://tile.openstreetmap.org/{z}/{x}/{y}.png",
                  userAgentPackageName: "com.example.fyp",
                ),

                // ✅ Route polyline
                if (_routePoints.isNotEmpty)
                  PolylineLayer(
                    polylines: [
                      Polyline(
                        points: _routePoints,
                        strokeWidth: 5,
                        color: Colors.blue,
                      ),
                    ],
                  ),

                MarkerLayer(
                  markers: [
                    if (widget.destination != null)
                      Marker(
                        point: widget.destination!,
                        width: 50,
                        height: 50,
                        child: const Icon(Icons.flag, color: Colors.red, size: 36),
                      ),
                    if (_driver != null)
                      Marker(
                        point: _driver!,
                        width: 50,
                        height: 50,
                        child: const Icon(Icons.local_shipping, color: Colors.blue, size: 36),
                      ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}