import 'dart:io';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

import 'package:fyp/core/routes/app_navigation.dart';
import 'package:fyp/core/routes/routes.dart';
import '../services/vendor_profile_service.dart';

import 'package:fyp/l10n/app_localizations.dart';

class VendorProfileController extends ChangeNotifier {
  bool _isLoading = true;
  bool get isLoading => _isLoading;

  bool _isEditing = false;
  bool get isEditing => _isEditing;

  bool _photoBusy = false;
  bool get photoBusy => _photoBusy;

  // display values
  String logoUrl = "";
  String contactName = ""; // users.name
  String companyName = ""; // vendors.company_name
  String email = "";
  String phone = "";
  String address = "";
  String vendorId = "";
  String deliveries = "0";
  String tankers = "0";
  String location = "";

  // form controllers
  final contactNameController = TextEditingController();
  final companyNameController = TextEditingController();
  final phoneController = TextEditingController();
  final addressController = TextEditingController();
  final tankerCountController = TextEditingController();

  final ImagePicker _picker = ImagePicker();

  VendorProfileController() {
    refresh();
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

  String _s(dynamic v) => (v ?? '').toString();

  String _i(dynamic v) {
    if (v is num) return v.toInt().toString();
    return int.tryParse(_s(v))?.toString() ?? "0";
  }

  Future<void> refresh() async {
    _isLoading = true;
    notifyListeners();

    try {
      final token = await _requireToken();
      final data = await VendorProfileService.fetchVendorProfile(token);

      final v = (data['vendor'] ?? {}) as Map;

      vendorId = _s(v['vendorId']);
      contactName = _s(v['contactName']);
      companyName = _s(v['companyName']);
      email = _s(v['email']);
      phone = _s(v['phone']);
      address = _s(v['address']);
      deliveries = _i(v['deliveries']);
      tankers = _i(v['tankerCount']);
      logoUrl = _s(v['logoUrl']);

      // NOTE: keep location text in UI based on locale when showing.
      // Here we store raw address; UI can display fallback.
      location = address.trim().isNotEmpty ? address.trim() : "";

      contactNameController.text = contactName;
      companyNameController.text = companyName;
      phoneController.text = phone;
      addressController.text = address;
      tankerCountController.text = tankers;
    } catch (e) {
      debugPrint("Vendor profile refresh error: $e");
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  void onEditProfile() {
    _isEditing = !_isEditing;
    notifyListeners();
  }

  Future<void> save(BuildContext context) async {
    final t = AppLocalizations.of(context)!;

    try {
      final token = await _requireToken();

      final payload = {
        "contactName": contactNameController.text.trim(),
        "companyName": companyNameController.text.trim(),
        "phone": phoneController.text.trim(),
        "address": addressController.text.trim(),
        "tankerCount": int.tryParse(tankerCountController.text.trim()) ?? 0,
      };

      await VendorProfileService.updateVendorProfile(token, payload);

      contactName = payload["contactName"] as String;
      companyName = payload["companyName"] as String;
      phone = payload["phone"] as String;
      address = payload["address"] as String;
      tankers = (payload["tankerCount"] as int).toString();
      location = address.trim().isNotEmpty ? address.trim() : "";

      _isEditing = false;
      notifyListeners();

      if (context.mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text(t.profileSaved)));
      }

      await refresh();
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text("${t.saveFailed}: $e"),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> pickAndUploadPhoto(BuildContext context) async {
    final t = AppLocalizations.of(context)!;

    try {
      final picked = await _picker.pickImage(
        source: ImageSource.gallery,
        imageQuality: 85,
      );
      if (picked == null) return;

      final token = await _requireToken();
      _photoBusy = true;
      notifyListeners();

      final url = await VendorProfileService.uploadVendorPhoto(
        token,
        File(picked.path),
      );
      logoUrl = url;

      if (context.mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text(t.photoUpdated)));
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text("${t.photoUploadFailed}: $e"),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      _photoBusy = false;
      notifyListeners();
    }
  }

  Future<void> deletePhoto(BuildContext context) async {
    final t = AppLocalizations.of(context)!;

    if (logoUrl.trim().isEmpty) return;

    try {
      final token = await _requireToken();
      _photoBusy = true;
      notifyListeners();

      await VendorProfileService.deleteVendorPhoto(token);
      logoUrl = "";

      if (context.mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text(t.photoRemoved)));
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text("${t.removeFailed}: $e"),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      _photoBusy = false;
      notifyListeners();
    }
  }

  Future<void> onLogout(BuildContext context) async {
    await FirebaseAuth.instance.signOut();
    if (!context.mounted) return;
    AppNavigation.offAll(context, AppRoutes.login);
  }

  @override
  void dispose() {
    contactNameController.dispose();
    companyNameController.dispose();
    phoneController.dispose();
    addressController.dispose();
    tankerCountController.dispose();
    super.dispose();
  }
}
