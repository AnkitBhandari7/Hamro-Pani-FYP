import 'dart:convert';
import 'package:http/http.dart' as http;

class NominatimSearchService {
  /// Nominatim usage policy: add a real user-agent.
  /// In production, you should proxy via your backend or add rate limiting.
  Future<List<NominatimPlace>> search(String query) async {
    final q = query.trim();
    if (q.isEmpty) return [];

    final uri = Uri.https('nominatim.openstreetmap.org', '/search', {
      'q': q,
      'format': 'json',
      'addressdetails': '1',
      'limit': '8',
      'countrycodes': 'np', // Nepal only (remove if you want worldwide)
    });

    final res = await http.get(
      uri,
      headers: {
        'User-Agent': 'hamro-pani-student-app/1.0 (contact: student)',
        'Accept-Language': 'en',
      },
    );

    if (res.statusCode != 200) {
      throw Exception("Search HTTP ${res.statusCode}: ${res.body}");
    }

    final list = jsonDecode(res.body) as List;
    return list
        .map((e) => NominatimPlace.fromJson(e as Map<String, dynamic>))
        .toList();
  }
}

class NominatimPlace {
  final String displayName;
  final double lat;
  final double lng;

  NominatimPlace({
    required this.displayName,
    required this.lat,
    required this.lng,
  });

  factory NominatimPlace.fromJson(Map<String, dynamic> json) {
    return NominatimPlace(
      displayName: (json['display_name'] ?? '').toString(),
      lat: double.parse(json['lat'].toString()),
      lng: double.parse(json['lon'].toString()),
    );
  }
}
