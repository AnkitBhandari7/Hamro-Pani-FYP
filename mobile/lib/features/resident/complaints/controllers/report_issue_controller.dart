import 'dart:io';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

import '../services/report_issue_service.dart';

class ReportIssueController extends ChangeNotifier {
  static const int maxPhotos = 5;

  String? selectedIssue;
  final descriptionController = TextEditingController();

  final List<String> photoPaths = [];
  bool isSubmitting = false;

  // Location (picked from map)
  double? lat;
  double? lng;

  // Display labels (you can later reverse-geocode)
  String wardLabel = 'Ward 4';
  String locationLabel = 'Tap to pick from map';

  final List<Map<String, dynamic>> issueTypes = [
    {'label': 'Missed Delivery', 'icon': Icons.local_shipping_outlined},
    {'label': 'Poor Quality', 'icon': Icons.water_drop_outlined},
    {'label': 'Severe Delay', 'icon': Icons.timer_off_outlined},
  ];

  final ImagePicker _picker = ImagePicker();

  void selectIssue(String issue) {
    selectedIssue = issue;
    notifyListeners();
  }

  /// Use this if you auto-detect ward/location later
  void setDetectedLocation({required String ward, required String location}) {
    wardLabel = ward.trim().isEmpty ? wardLabel : ward.trim();
    locationLabel = location.trim().isEmpty ? locationLabel : location.trim();
    notifyListeners();
  }

  /// ✅ Called after map picker returns lat/lng
  void setPickedCoordinates({required double lat, required double lng}) {
    this.lat = lat;
    this.lng = lng;

    // simple label for now (free). Later you can reverse geocode.
    locationLabel = "${lat.toStringAsFixed(6)}, ${lng.toStringAsFixed(6)}";
    notifyListeners();
  }

  bool get hasPickedLocation => lat != null && lng != null;

  bool get canAddMorePhotos => photoPaths.length < maxPhotos;

  Future<void> addPhotoFromCamera() async {
    if (!canAddMorePhotos) return;

    try {
      final XFile? picked = await _picker.pickImage(
        source: ImageSource.camera,
        imageQuality: 75,
      );
      if (picked == null) return;

      final f = File(picked.path);
      if (!await f.exists()) return;

      photoPaths.add(picked.path);
      notifyListeners();
    } catch (e) {
      debugPrint("addPhotoFromCamera error: $e");
    }
  }

  Future<void> addPhotosFromGallery() async {
    if (!canAddMorePhotos) return;

    try {
      final List<XFile> picked = await _picker.pickMultiImage(imageQuality: 75);
      if (picked.isEmpty) return;

      for (final x in picked) {
        if (!canAddMorePhotos) break;

        final f = File(x.path);
        if (await f.exists()) {
          photoPaths.add(x.path);
        }
      }

      notifyListeners();
    } catch (e) {
      debugPrint("addPhotosFromGallery error: $e");
    }
  }

  void removePhotoAt(int index) {
    if (index < 0 || index >= photoPaths.length) return;
    photoPaths.removeAt(index);
    notifyListeners();
  }

  Future<String> _requireToken() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) throw Exception("Not authenticated");

    final String? token = await user.getIdToken(true);
    if (token == null || token.trim().isEmpty) {
      throw Exception("Failed to get Firebase token");
    }
    return token;
  }

  Future<void> submitReport(BuildContext context) async {
    final issue = selectedIssue;
    final desc = descriptionController.text.trim();

    if (issue == null || desc.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("Please select an issue type and enter description."),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    // ✅ require user to pick location
    if (!hasPickedLocation) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("Please pick a location from map."),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    if (isSubmitting) return;

    isSubmitting = true;
    notifyListeners();

    try {
      final token = await _requireToken();

      await ReportIssueService.submitIssue(
        token: token,
        issueType: issue,
        description: desc,
        ward: wardLabel,
        location: locationLabel,
        lat: lat!, // ✅
        lng: lng!, // ✅
        photoPaths: photoPaths,
      );

      if (!context.mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("Report submitted successfully"),
          backgroundColor: Colors.green,
        ),
      );

      // reset
      selectedIssue = null;
      descriptionController.clear();
      photoPaths.clear();
      lat = null;
      lng = null;
      locationLabel = 'Tap to pick from map';
      notifyListeners();

      Navigator.pop(context);
    } catch (e) {
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text("Submit failed: $e"),
          backgroundColor: Colors.red,
        ),
      );
    } finally {
      isSubmitting = false;
      notifyListeners();
    }
  }

  @override
  void dispose() {
    descriptionController.dispose();
    super.dispose();
  }
}
