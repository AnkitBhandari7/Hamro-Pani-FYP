import 'dart:io';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

import 'package:fyp/core/routes/routes.dart';
import '../services/ward_admin_profile_service.dart';
import 'package:fyp/l10n/app_localizations.dart';

class WardAdminProfileController extends ChangeNotifier {
  bool _isLoading = true;
  bool _isEditing = false;

  bool get isLoading => _isLoading;
  bool get isEditing => _isEditing;

  String profileImageUrl = '';
  String fullName = '';
  String phoneNumber = '';
  String email = '';

  String wardInfo = '';

  final nameController = TextEditingController();
  final phoneController = TextEditingController();
  final emailController = TextEditingController();

  final ImagePicker _picker = ImagePicker();

  WardAdminProfileController() {
    refreshProfile();
  }

  Future<String> _requireToken() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) throw Exception("Not authenticated");

    final String? token = await user.getIdToken(true);
    if (token == null || token.trim().isEmpty) {
      throw Exception("Failed to get Firebase ID token");
    }
    return token;
  }

  String _wardNameFrom(dynamic wardRaw) {
    if (wardRaw == null) return "";
    if (wardRaw is Map) return (wardRaw['name'] ?? '').toString();
    return wardRaw.toString();
  }

  Future<void> refreshProfile() async {
    _isLoading = true;
    notifyListeners();

    try {
      final token = await _requireToken();
      final data = await WardAdminProfileService.fetchProfile(token);

      fullName = (data['name'] ?? '').toString();
      phoneNumber = (data['phone'] ?? '').toString();
      email = (data['email'] ?? '').toString();
      profileImageUrl = (data['profileImageUrl'] ?? '').toString();

      final wardRaw = data['ward'];
      final wardName = _wardNameFrom(wardRaw);
      wardInfo = wardName; // screen shows localized fallback if empty

      nameController.text = fullName;
      phoneController.text = phoneNumber;
      emailController.text = email;
    } catch (e) {
      debugPrint("WardAdminProfile refresh error: $e");
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  void toggleEditMode() {
    _isEditing = !_isEditing;
    notifyListeners();
  }

  Future<void> saveProfile(BuildContext context) async {
    final t = AppLocalizations.of(context)!;

    try {
      final token = await _requireToken();

      final payload = {
        "name": nameController.text.trim(),
        "phone": phoneController.text.trim(),
      };

      final response = await WardAdminProfileService.updateProfile(
        token,
        payload,
      );
      final user = (response['user'] ?? {}) as Map;

      fullName = (user['name'] ?? '').toString();
      phoneNumber = (user['phone'] ?? '').toString();
      email = (user['email'] ?? '').toString();
      profileImageUrl = (user['profileImageUrl'] ?? '').toString();

      nameController.text = fullName;
      phoneController.text = phoneNumber;
      emailController.text = email;

      _isEditing = false;
      notifyListeners();

      if (context.mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text(t.profileSavedSuccessfully)));
      }

      await refreshProfile();
    } catch (e) {
      debugPrint("saveProfile error: $e");
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
      final file = File(picked.path);

      final url = await WardAdminProfileService.uploadPhoto(token, file);
      profileImageUrl = url;
      notifyListeners();

      if (context.mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text(t.profilePhotoUpdated)));
      }
    } catch (e) {
      debugPrint("pickAndUploadPhoto error: $e");
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text("${t.photoUploadFailed}: $e"),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> onLogout(BuildContext context) async {
    final t = AppLocalizations.of(context)!;

    try {
      await FirebaseAuth.instance.signOut();

      // clear local state
      profileImageUrl = '';
      fullName = '';
      phoneNumber = '';
      email = '';
      wardInfo = '';
      nameController.clear();
      phoneController.clear();
      emailController.clear();
      _isEditing = false;

      notifyListeners();

      if (context.mounted) {
        Navigator.of(
          context,
        ).pushNamedAndRemoveUntil(AppRoutes.login, (route) => false);
      }
    } catch (e) {
      debugPrint("logout error: $e");
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text("${t.logoutFailed}: $e"),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  @override
  void dispose() {
    nameController.dispose();
    phoneController.dispose();
    emailController.dispose();
    super.dispose();
  }
}
