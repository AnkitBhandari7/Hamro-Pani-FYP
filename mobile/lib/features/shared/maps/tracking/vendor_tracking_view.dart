import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:geolocator/geolocator.dart';
import 'package:latlong2/latlong.dart';

import 'socket_tracking_service.dart';

class DriverTrackingView extends StatefulWidget {
  final String tripId;
  const DriverTrackingView({super.key, required this.tripId});

  @override
  State<DriverTrackingView> createState() => _DriverTrackingViewState();
}

class _DriverTrackingViewState extends State<DriverTrackingView> {
  static const String _serverUrl = "http://10.0.2.2:3000"; // emulator -> host

  final _map = MapController();
  late final SocketTrackingService _socket;

  StreamSubscription<Position>? _posSub;

  LatLng? _me;
  String _status = "Starting...";

  @override
  void initState() {
    super.initState();

    _socket = SocketTrackingService(serverUrl: _serverUrl);
    _socket.connect();

    _socket.onConnect(() {
      setState(() => _status = "Connected to server");
      _socket.joinTrip(widget.tripId);
    });
    _socket.onDisconnect(() => setState(() => _status = "Disconnected"));
    _socket.onError((e) => setState(() => _status = "Socket error: $e"));

    _startLocationStream();
  }

  Future<void> _startLocationStream() async {
    try {
      final enabled = await Geolocator.isLocationServiceEnabled();
      if (!enabled) throw Exception("Location is disabled");

      var perm = await Geolocator.checkPermission();
      if (perm == LocationPermission.denied)
        perm = await Geolocator.requestPermission();
      if (perm == LocationPermission.denied ||
          perm == LocationPermission.deniedForever) {
        throw Exception("Location permission denied");
      }

      // stream updates
      _posSub =
          Geolocator.getPositionStream(
            locationSettings: const LocationSettings(
              accuracy: LocationAccuracy.high,
              distanceFilter: 5, // meters
            ),
          ).listen((pos) {
            final me = LatLng(pos.latitude, pos.longitude);
            setState(() => _me = me);

            _map.move(me, 16);

            _socket.sendUpdate(
              tripId: widget.tripId,
              lat: pos.latitude,
              lng: pos.longitude,
              heading: pos.heading.isFinite ? pos.heading : null,
              speed: pos.speed.isFinite ? pos.speed : null,
            );
          });

      setState(() => _status = "Tracking started");
    } catch (e) {
      setState(() => _status = "Tracking failed: $e");
    }
  }

  @override
  void dispose() {
    _posSub?.cancel();
    _socket.disconnect();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final me = _me;

    return Scaffold(
      appBar: AppBar(title: const Text("Driver Tracking")),
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
                initialCenter:
                    me ?? const LatLng(27.7172, 85.3240), // Kathmandu fallback
                initialZoom: 14,
              ),
              children: [
                TileLayer(
                  urlTemplate: "https://tile.openstreetmap.org/{z}/{x}/{y}.png",
                  userAgentPackageName: "com.example.fyp",
                ),
                if (me != null)
                  MarkerLayer(
                    markers: [
                      Marker(
                        point: me,
                        width: 50,
                        height: 50,
                        child: const Icon(
                          Icons.local_shipping,
                          color: Colors.blue,
                          size: 36,
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
