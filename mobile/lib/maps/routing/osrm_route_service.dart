import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:latlong2/latlong.dart';

class OsrmRouteService {
  /// Free OSRM public server (good for testing)
  static const String _base = "https://router.project-osrm.org";

  /// Returns route polyline points between [start] and [end]
  /// OSRM expects lng,lat order in URL
  Future<List<LatLng>> getDrivingRoute({
    required LatLng start,
    required LatLng end,
  }) async {
    final url =
        "$_base/route/v1/driving/${start.longitude},${start.latitude};${end.longitude},${end.latitude}"
        "?overview=full&geometries=geojson";

    final res = await http.get(Uri.parse(url));
    if (res.statusCode != 200) {
      throw Exception("OSRM HTTP ${res.statusCode}: ${res.body}");
    }

    final data = jsonDecode(res.body) as Map<String, dynamic>;
    final routes = (data['routes'] as List?) ?? [];
    if (routes.isEmpty) return [];

    final geometry = routes[0]['geometry'] as Map<String, dynamic>?;
    final coords = (geometry?['coordinates'] as List?) ?? [];

    // coordinates = [ [lng,lat], [lng,lat], ... ]
    return coords.map((c) {
      final lng = (c[0] as num).toDouble();
      final lat = (c[1] as num).toDouble();
      return LatLng(lat, lng);
    }).toList();
  }
}