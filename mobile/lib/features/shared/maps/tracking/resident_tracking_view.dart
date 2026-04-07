import 'dart:async';
import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';

import '../routing/osrm_route_service.dart';
import 'socket_tracking_service.dart';

class CustomerTrackView extends StatefulWidget {
  final String tripId;

  /// Resident destination
  final LatLng? destination;

  const CustomerTrackView({super.key, required this.tripId, this.destination});

  @override
  State<CustomerTrackView> createState() => _CustomerTrackViewState();
}

class _CustomerTrackViewState extends State<CustomerTrackView> {
  static const String _serverUrl = "https://hamro-pani-fyp-backend.onrender.com";

  final _map = MapController();
  late final SocketTrackingService _socket;

  final _osrm = OsrmRouteService();

  LatLng? _driver;
  double _heading = 0.0;
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
      final hdg = (data['heading'] as num?)?.toDouble() ?? 0.0;

      final p = LatLng(lat, lng);
      setState(() {
        _driver = p;
        _heading = hdg;
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
    final center =
        _driver ?? widget.destination ?? const LatLng(27.7172, 85.3240);

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
              options: MapOptions(initialCenter: center, initialZoom: 14),
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
                        strokeWidth: 6,
                        color: Colors.blue.withOpacity(0.7),
                        strokeJoin: StrokeJoin.round,
                        strokeCap: StrokeCap.round,
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
                        child: const Icon(
                          Icons.location_on, // Premium red drop-pin
                          color: Colors.red,
                          size: 42,
                          shadows: [
                            Shadow(color: Colors.black45, blurRadius: 4, offset: Offset(2, 2)),
                          ],
                        ),
                      ),
                    if (_driver != null)
                      Marker(
                        point: _driver!,
                        width: 54,
                        height: 54,
                        child: Transform.rotate(
                          angle: _heading * (math.pi / 180),
                          child: Container(
                            decoration: BoxDecoration(
                              color: Colors.white,
                              shape: BoxShape.circle,
                              border: Border.all(color: Colors.blue.shade200, width: 2),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withOpacity(0.3),
                                  blurRadius: 8,
                                  offset: const Offset(0, 4),
                                ),
                              ],
                            ),
                            child: const Center(
                              child: Icon(
                                Icons.navigation, // Classic triangular vehicle icon
                                color: Colors.blue,
                                size: 30,
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
        ],
      ),
    );
  }
}
