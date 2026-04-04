import 'dart:convert';

import 'package:fyp/services/api_service.dart';

class ComplaintDetail {
  final int id;
  final int bookingId;
  final String status;
  final String message;
  final DateTime createdAt;
  final List<String> photoUrls;

  ComplaintDetail({
    required this.id,
    required this.bookingId,
    required this.status,
    required this.message,
    required this.createdAt,
    required this.photoUrls,
  });

  factory ComplaintDetail.fromApi(Map<String, dynamic> json) {
    final photos = (json['photos'] as List? ?? const [])
        .map((e) => (e as Map)['photoUrl'].toString())
        .toList();

    return ComplaintDetail(
      id: (json['id'] as num).toInt(),
      bookingId: (json['bookingId'] as num).toInt(),
      status: (json['status'] ?? 'OPEN').toString(),
      message: (json['message'] ?? '').toString(),
      createdAt: DateTime.parse(json['createdAt'].toString()),
      photoUrls: photos,
    );
  }
}

class ComplaintService {
  static Future<ComplaintDetail> getComplaintDetail(int complaintId) async {
    final res = await ApiService.get('/complaints/$complaintId');

    if (res.statusCode != 200) {
      throw Exception(
        'GET /complaints/$complaintId failed: ${res.statusCode} ${res.body}',
      );
    }

    return ComplaintDetail.fromApi(
      jsonDecode(res.body) as Map<String, dynamic>,
    );
  }
}
