import 'dart:async';
import 'dart:convert';
import 'dart:math' as math;

import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:http/http.dart' as http;
import 'package:latlong2/latlong.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:cached_network_image/cached_network_image.dart';

import '../routing/osrm_route_service.dart';
import 'socket_tracking_service.dart';

/// Pathao-style live tracking screen for RESIDENTS.
/// Shows:
/// • Animated vendor vehicle marker (rotating truck icon, moves with GPS)
/// • Resident's destination (red home pin)
/// • Blue OSRM polyline route between them
/// • Bottom sheet: vendor name, phone, distance, ETA, booking status
///
/// Updates:
/// • Primary: Socket listener (instant real-time via WebSocket)
/// • Fallback: REST poll GET /bookings/:id/tracking every 10s if socket drops
class ResidentTrackingScreen extends StatefulWidget {
  final int bookingId;
  const ResidentTrackingScreen({super.key, required this.bookingId});

  @override
  State<ResidentTrackingScreen> createState() => _ResidentTrackingScreenState();
}

class _ResidentTrackingScreenState extends State<ResidentTrackingScreen>
    with TickerProviderStateMixin {
  static const String _baseUrl = 'https://hamro-pani-fyp-backend.onrender.com';

  final _map = MapController();
  final _osrm = OsrmRouteService();
  late final SocketTrackingService _socket;

  // State
  LatLng? _vendor;
  LatLng? _dest;
  double _vendorHeading = 0.0;
  List<LatLng> _route = [];

  // Vendor info from REST
  String _vendorName = 'Loading...';
  String _vendorPhone = '';
  String _vendorImageUrl = '';
  String _bookingStatus = 'CONFIRMED';

  // UI State
  bool _loading = true;
  String? _error;
  Timer? _fallbackTimer;
  Timer? _routeDebounce;

  // Smooth marker animation
  late AnimationController _markerAnim;
  LatLng? _prevVendor;

  @override
  void initState() {
    super.initState();

    _markerAnim = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    );

    // 1. Socket — instant live updates from vendor
    _socket = SocketTrackingService(serverUrl: _baseUrl);
    _socket.connect();
    _socket.onConnect(() {
      debugPrint('ResidentTracking: socket connected');
      _socket.joinTrip(widget.bookingId.toString());
    });

    _socket.onPosition((data) {
      final lat = (data['lat'] as num?)?.toDouble();
      final lng = (data['lng'] as num?)?.toDouble();
      final heading = (data['heading'] as num?)?.toDouble();
      if (lat == null || lng == null) return;
      _onVendorMoved(LatLng(lat, lng), heading);
    });

    // 2. Initial data load (vendor info + last known location)
    _loadTrackingData();

    // 3. Fallback poll every 10s (activates if socket goes quiet for 30s)
    _fallbackTimer = Timer.periodic(const Duration(seconds: 10), (_) {
      _loadTrackingData(silent: true);
    });
  }

  Future<String?> _token() async {
    final u = FirebaseAuth.instance.currentUser;
    if (u == null) return null;
    return u.getIdToken(false);
  }

  Future<void> _loadTrackingData({bool silent = false}) async {
    try {
      final t = await _token();
      if (t == null) return;

      final res = await http.get(
        Uri.parse('$_baseUrl/bookings/${widget.bookingId}/tracking'),
        headers: {'Authorization': 'Bearer $t'},
      ).timeout(const Duration(seconds: 8));

      if (res.statusCode != 200) {
        if (!silent) {
          setState(() {
            _error = 'Could not load tracking data (${res.statusCode})';
            _loading = false;
          });
        }
        return;
      }

      final data = jsonDecode(res.body) as Map<String, dynamic>;
      final vendorData = data['vendor'] as Map<String, dynamic>?;
      final destData = data['destination'] as Map<String, dynamic>?;

      if (!mounted) return;
      setState(() {
        _vendorName = vendorData?['name'] ?? 'Vendor';
        _vendorPhone = vendorData?['phone'] ?? '';
        _vendorImageUrl = vendorData?['imageUrl'] ?? '';
        _bookingStatus = data['status'] ?? 'CONFIRMED';

        if (destData != null) {
          _dest = LatLng(
            (destData['lat'] as num).toDouble(),
            (destData['lng'] as num).toDouble(),
          );
        }

        // Use DB location only if socket hasn't provided one yet
        final dbLat = (vendorData?['currentLat'] as num?)?.toDouble();
        final dbLng = (vendorData?['currentLng'] as num?)?.toDouble();
        if (_vendor == null && dbLat != null && dbLng != null) {
          _vendor = LatLng(dbLat, dbLng);
          _fitCamera();
        }

        _loading = false;
        _error = null;
      });

      _scheduleRouteUpdate();
    } catch (e) {
      if (!silent && mounted) {
        setState(() {
          _error = 'Connection error: $e';
          _loading = false;
        });
      }
    }
  }

  void _onVendorMoved(LatLng newPos, double? heading) {
    if (!mounted) return;
    _prevVendor = _vendor;
    setState(() {
      _vendor = newPos;
      _vendorHeading = heading ?? _vendorHeading;
    });

    // Animate the marker movement
    _markerAnim.forward(from: 0);

    // Keep camera centred on vendor (slightly offset so destination is visible)
    _map.move(newPos, _map.camera.zoom);
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

  void _fitCamera() {
    final v = _vendor;
    final d = _dest;
    if (v == null && d == null) return;
    if (v != null && d != null) {
      final bounds = LatLngBounds.fromPoints([v, d]);
      _map.fitCamera(
        CameraFit.bounds(bounds: bounds, padding: const EdgeInsets.all(60)),
      );
    } else {
      _map.move(v ?? d!, 15);
    }
  }

  double _distanceKm() {
    final v = _vendor;
    final d = _dest;
    if (v == null || d == null) return 0;
    const calc = Distance();
    return calc.as(LengthUnit.Kilometer, v, d);
  }

  String _etaLabel() {
    final km = _distanceKm();
    if (km < 0.1) return 'Arriving now';
    final mins = (km / 30 * 60).round(); // assume 30 km/h avg
    if (mins < 1) return '< 1 min';
    return '$mins min';
  }

  Future<void> _callVendor() async {
    if (_vendorPhone.isEmpty) return;
    final uri = Uri.parse('tel:$_vendorPhone');
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri);
    }
  }

  @override
  void dispose() {
    _socket.disconnect();
    _fallbackTimer?.cancel();
    _routeDebounce?.cancel();
    _markerAnim.dispose();
    super.dispose();
  }

  // ── Status chip color ──────────────────────────────────────────────────────
  Color _statusColor(String s) {
    switch (s.toUpperCase()) {
      case 'CONFIRMED':
        return const Color(0xFF3B82F6);
      case 'COMPLETED':
      case 'DELIVERED':
        return const Color(0xFF16A34A);
      case 'CANCELLED':
        return const Color(0xFFEF4444);
      default:
        return const Color(0xFFF59E0B);
    }
  }

  // ── Build ──────────────────────────────────────────────────────────────────
  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return Scaffold(
        backgroundColor: const Color(0xFF0F172A),
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const CircularProgressIndicator(color: Color(0xFF3B82F6)),
              const SizedBox(height: 16),
              Text(
                'Loading tracking...',
                style: GoogleFonts.poppins(
                    color: const Color(0xFF94A3B8), fontSize: 14),
              ),
            ],
          ),
        ),
      );
    }

    if (_error != null) {
      return Scaffold(
        backgroundColor: const Color(0xFF0F172A),
        appBar: _buildAppBar(),
        body: Center(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.signal_wifi_off_rounded,
                    size: 56, color: Color(0xFF64748B)),
                const SizedBox(height: 16),
                Text(
                  _error!,
                  style: GoogleFonts.poppins(
                      color: const Color(0xFF94A3B8), fontSize: 14),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 20),
                ElevatedButton.icon(
                  onPressed: () => _loadTrackingData(),
                  icon: const Icon(Icons.refresh_rounded),
                  label: const Text('Retry'),
                  style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF3B82F6)),
                ),
              ],
            ),
          ),
        ),
      );
    }

    final center = _vendor ?? _dest ?? const LatLng(27.7172, 85.3240);

    return Scaffold(
      backgroundColor: const Color(0xFF0F172A),
      appBar: _buildAppBar(),
      body: Stack(
        children: [
          // ── Map ────────────────────────────────────────────────────────────
          FlutterMap(
            mapController: _map,
            options: MapOptions(
              initialCenter: center,
              initialZoom: 15,
              onMapReady: _fitCamera,
            ),
            children: [
              TileLayer(
                urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                userAgentPackageName: 'com.hamropani.fyp',
              ),
              // Blue route polyline
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
                  // Destination — red home pin
                  if (_dest != null)
                    Marker(
                      point: _dest!,
                      width: 44,
                      height: 44,
                      child: Container(
                        decoration: BoxDecoration(
                          color: const Color(0xFFEF4444),
                          shape: BoxShape.circle,
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withValues(alpha: 0.4),
                              blurRadius: 8,
                              offset: const Offset(0, 3),
                            ),
                          ],
                        ),
                        child: const Icon(Icons.home_rounded,
                            color: Colors.white, size: 22),
                      ),
                    ),
                  // Vendor vehicle — rotating animated truck
                  if (_vendor != null)
                    Marker(
                      point: _vendor!,
                      width: 56,
                      height: 56,
                      child: AnimatedBuilder(
                        animation: _markerAnim,
                        builder: (_, __) {
                          return Transform.rotate(
                            angle: _vendorHeading * (math.pi / 180),
                            child: Container(
                              decoration: BoxDecoration(
                                color: Colors.white,
                                shape: BoxShape.circle,
                                border: Border.all(
                                    color: const Color(0xFF3B82F6), width: 2.5),
                                boxShadow: [
                                  BoxShadow(
                                    color:
                                        Colors.black.withValues(alpha: 0.35),
                                    blurRadius: 12,
                                    offset: const Offset(0, 4),
                                  ),
                                ],
                              ),
                              child: const Center(
                                child: Icon(
                                  Icons.local_shipping_rounded,
                                  color: Color(0xFF3B82F6),
                                  size: 30,
                                ),
                              ),
                            ),
                          );
                        },
                      ),
                    ),
                ],
              ),
            ],
          ),

          // ── Fit-camera FAB ─────────────────────────────────────────────────
          Positioned(
            right: 12,
            bottom: 220,
            child: FloatingActionButton.small(
              heroTag: 'fit_cam',
              onPressed: _fitCamera,
              backgroundColor: Colors.white,
              child: const Icon(Icons.my_location_rounded,
                  color: Color(0xFF1E293B)),
            ),
          ),

          // ── Bottom Sheet (Pathao-style info panel) ─────────────────────────
          Positioned(
            left: 0,
            right: 0,
            bottom: 0,
            child: _buildBottomPanel(),
          ),
        ],
      ),
    );
  }

  AppBar _buildAppBar() {
    return AppBar(
      backgroundColor: const Color(0xFF1E293B),
      foregroundColor: Colors.white,
      title: Text(
        'Tracking Delivery #${widget.bookingId}',
        style: GoogleFonts.poppins(fontWeight: FontWeight.w600, fontSize: 16),
      ),
    );
  }

  Widget _buildBottomPanel() {
    final distKm = _distanceKm();
    final distLabel = distKm < 1
        ? '${(distKm * 1000).toInt()} m'
        : '${distKm.toStringAsFixed(1)} km';

    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFF1E293B),
        borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.4),
            blurRadius: 20,
            offset: const Offset(0, -4),
          ),
        ],
      ),
      padding: EdgeInsets.fromLTRB(20.w, 16.h, 20.w, 24.h),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Handle bar
          Container(
            width: 40,
            height: 4,
            decoration: BoxDecoration(
              color: const Color(0xFF334155),
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          SizedBox(height: 16.h),

          // ── Vendor row ──────────────────────────────────────────────────
          Row(
            children: [
              // Vendor avatar
              CircleAvatar(
                radius: 26.r,
                backgroundColor: const Color(0xFF334155),
                backgroundImage: _vendorImageUrl.isNotEmpty
                    ? CachedNetworkImageProvider(_vendorImageUrl) as ImageProvider
                    : null,
                onBackgroundImageError: _vendorImageUrl.isNotEmpty
                    ? (_, __) {}
                    : null,
                child: _vendorImageUrl.isEmpty
                    ? const Icon(Icons.person_rounded,
                        color: Color(0xFF94A3B8), size: 28)
                    : null,
              ),
              SizedBox(width: 14.w),

              // Name + status
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      _vendorName,
                      style: GoogleFonts.poppins(
                        color: Colors.white,
                        fontSize: 16.sp,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    SizedBox(height: 4.h),
                    Container(
                      padding: EdgeInsets.symmetric(
                          horizontal: 10.w, vertical: 3.h),
                      decoration: BoxDecoration(
                        color: _statusColor(_bookingStatus)
                            .withValues(alpha: 0.15),
                        borderRadius: BorderRadius.circular(8.r),
                      ),
                      child: Text(
                        _bookingStatus,
                        style: GoogleFonts.poppins(
                          fontSize: 11.sp,
                          fontWeight: FontWeight.w700,
                          color: _statusColor(_bookingStatus),
                          letterSpacing: 0.5,
                        ),
                      ),
                    ),
                  ],
                ),
              ),

              // Call button
              if (_vendorPhone.isNotEmpty)
                GestureDetector(
                  onTap: _callVendor,
                  child: Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: const Color(0xFF16A34A).withValues(alpha: 0.12),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(Icons.phone_rounded,
                        color: Color(0xFF16A34A), size: 22),
                  ),
                ),
            ],
          ),
          SizedBox(height: 16.h),

          // ── Distance + ETA row ──────────────────────────────────────────
          Row(
            children: [
              Expanded(
                child: _infoTile(
                  icon: Icons.directions_car_rounded,
                  label: 'Distance',
                  value: _vendor == null ? '--' : distLabel,
                  color: const Color(0xFF3B82F6),
                ),
              ),
              SizedBox(width: 12.w),
              Expanded(
                child: _infoTile(
                  icon: Icons.schedule_rounded,
                  label: 'ETA',
                  value: _vendor == null ? '--' : _etaLabel(),
                  color: const Color(0xFFF59E0B),
                ),
              ),
              SizedBox(width: 12.w),
              Expanded(
                child: _infoTile(
                  icon: Icons.location_on_rounded,
                  label: 'Destination',
                  value: _dest == null ? '--' : 'Your location',
                  color: const Color(0xFFEF4444),
                ),
              ),
            ],
          ),

          // ── Live indicator ──────────────────────────────────────────────
          if (_vendor != null) ...[
            SizedBox(height: 12.h),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Container(
                  width: 8,
                  height: 8,
                  decoration: const BoxDecoration(
                    color: Color(0xFF16A34A),
                    shape: BoxShape.circle,
                  ),
                ),
                const SizedBox(width: 6),
                Text(
                  'Live tracking active',
                  style: GoogleFonts.poppins(
                    fontSize: 11.sp,
                    color: const Color(0xFF16A34A),
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }

  Widget _infoTile({
    required IconData icon,
    required String label,
    required String value,
    required Color color,
  }) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 10.h),
      decoration: BoxDecoration(
        color: const Color(0xFF0F172A),
        borderRadius: BorderRadius.circular(12.r),
      ),
      child: Column(
        children: [
          Icon(icon, color: color, size: 18.w),
          SizedBox(height: 4.h),
          Text(
            value,
            style: GoogleFonts.poppins(
              fontSize: 13.sp,
              fontWeight: FontWeight.w700,
              color: Colors.white,
            ),
            textAlign: TextAlign.center,
            overflow: TextOverflow.ellipsis,
          ),
          Text(
            label,
            style: GoogleFonts.poppins(
              fontSize: 10.sp,
              color: const Color(0xFF64748B),
            ),
          ),
        ],
      ),
    );
  }
}
