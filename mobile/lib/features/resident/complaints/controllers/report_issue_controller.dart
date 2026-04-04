import 'dart:io';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

import 'package:fyp/l10n/app_localizations.dart';
import '../services/report_issue_service.dart';

class ReportIssueType {
  final String code; // stable backend code
  final IconData icon;

  const ReportIssueType({required this.code, required this.icon});

  String labelFor(AppLocalizations t) {
    switch (code) {
      case 'MISSED_DELIVERY':
        return t.issueMissedDelivery;
      case 'POOR_QUALITY':
        return t.issuePoorQuality;
      case 'SEVERE_DELAY':
        return t.issueSevereDelay;
      default:
        return code;
    }
  }
}

class ReportIssueController extends ChangeNotifier {
  static const int maxPhotos = 5;

  String? selectedIssueCode;
  final descriptionController = TextEditingController();

  final List<String> photoPaths = [];
  bool isSubmitting = false;

  // Location (picked from map)
  double? lat;
  double? lng;

  // Display labels
  String wardLabel = 'Ward 4';
  String locationLabel = '';

  final List<ReportIssueType> issueTypes = const [
    ReportIssueType(code: 'MISSED_DELIVERY', icon: Icons.local_shipping_outlined),
    ReportIssueType(code: 'POOR_QUALITY', icon: Icons.water_drop_outlined),
    ReportIssueType(code: 'SEVERE_DELAY', icon: Icons.timer_off_outlined),
  ];

  final ImagePicker _picker = ImagePicker();

  void selectIssue(String code) {
    selectedIssueCode = code;
    notifyListeners();
  }

  /// Use this if you auto-detect ward/location later
  void setDetectedLocation({required String ward, required String location}) {
    wardLabel = ward.trim().isEmpty ? wardLabel : ward.trim();
    locationLabel = location.trim().isEmpty ? locationLabel : location.trim();
    notifyListeners();
  }

  /// Called after map picker returns lat/lng (and optional resolved address)
  void setPickedCoordinates({required double lat, required double lng, String? address}) {
    this.lat = lat;
    this.lng = lng;

    locationLabel = (address != null && address.trim().isNotEmpty)
        ? address.trim()
        : "${lat.toStringAsFixed(6)}, ${lng.toStringAsFixed(6)}";
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
    final t = AppLocalizations.of(context)!;

    final issueCode = selectedIssueCode;
    final desc = descriptionController.text.trim();

    if (issueCode == null || desc.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(t.selectIssueAndDescription),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    if (!hasPickedLocation) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(t.pickLocationFromMap),
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
        issueType: issueCode, // ✅ send stable code to backend
        description: desc,
        ward: wardLabel,
        location: locationLabel.isEmpty ? t.locationNotSet : locationLabel,
        lat: lat!,
        lng: lng!,
        photoPaths: photoPaths,
      );

      if (!context.mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(t.reportSubmittedSuccessfully),
          backgroundColor: Colors.green,
        ),
      );

      // reset
      selectedIssueCode = null;
      descriptionController.clear();
      photoPaths.clear();
      lat = null;
      lng = null;
      locationLabel = '';
      notifyListeners();

      Navigator.pop(context);
    } catch (e) {
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(t.submitFailedWithError(e.toString())),
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