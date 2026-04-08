import 'dart:convert';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:http/http.dart' as http;
import 'package:cached_network_image/cached_network_image.dart';
import 'package:image_picker/image_picker.dart';
import 'package:intl/intl.dart';

import 'package:fyp/features/resident/bookings/views/booking_detail_screen.dart';
import 'package:fyp/features/resident/bookings/views/my_bookings_history_screen.dart';
import 'package:fyp/features/resident/complaints/views/complaint_detail_screen.dart';
import 'package:fyp/core/routes/app_navigation.dart';
import 'package:fyp/core/routes/routes.dart';
import 'package:fyp/features/shared/notifications/services/fcm_service.dart';
import '../widgets/profile_menu_section.dart';

import 'package:fyp/l10n/app_localizations.dart';

class BookingModel {
  final int id;
  final String status;
  final DateTime createdAt;
  final String? ward;
  final String? vendorName;
  final String? routeLocation;
  final DateTime? slotStartTime;
  final DateTime? slotEndTime;

  BookingModel({
    required this.id,
    required this.status,
    required this.createdAt,
    this.ward,
    this.vendorName,
    this.routeLocation,
    this.slotStartTime,
    this.slotEndTime,
  });

  factory BookingModel.fromJson(Map<String, dynamic> json) {
    DateTime? parseDt(dynamic v) =>
        v == null ? null : DateTime.tryParse(v.toString());
    return BookingModel(
      id: json['id'],
      status: (json['status'] ?? 'PENDING').toString(),
      createdAt: DateTime.parse(json['createdAt']),
      ward: json['ward']?.toString(),
      vendorName: json['vendorName']?.toString(),
      routeLocation: json['routeLocation']?.toString(),
      slotStartTime: parseDt(json['slotStartTime']),
      slotEndTime: parseDt(json['slotEndTime']),
    );
  }
}

class IssueModel {
  final int id;
  final String title;
  final String status;
  final DateTime createdAt;
  final String? message;

  IssueModel({
    required this.id,
    required this.title,
    required this.status,
    required this.createdAt,
    this.message,
  });

  factory IssueModel.fromJson(Map<String, dynamic> json) {
    return IssueModel(
      id: json['id'],
      title: (json['title'] ?? '').toString(),
      status: (json['status'] ?? 'OPEN').toString(),
      createdAt: DateTime.parse(json['createdAt']),
      message: json['message']?.toString(),
    );
  }
}

class SavedLocationModel {
  final int id;
  final String label;
  final String address;
  final bool isDefault;

  SavedLocationModel({
    required this.id,
    required this.label,
    required this.address,
    required this.isDefault,
  });

  factory SavedLocationModel.fromJson(Map<String, dynamic> json) {
    return SavedLocationModel(
      id: (json['id'] ?? 0) is int
          ? (json['id'] ?? 0)
          : int.tryParse(json['id'].toString()) ?? 0,
      label: (json['label'] ?? '').toString(),
      address: (json['address'] ?? '').toString(),
      isDefault: json['isDefault'] == true || json['is_default'] == true,
    );
  }
}

class ProfileScreen extends StatefulWidget {
  final String userName;
  final String phone;
  final String email;
  final String? ward;

  const ProfileScreen({
    super.key,
    required this.userName,
    required this.phone,
    required this.email,
    this.ward,
  });

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  static const String _baseUrl = "https://hamro-pani-fyp-backend.onrender.com";

  bool _loadingProfile = true;
  bool _isSaving = false;

  bool _showRecentActivity = false;
  int selectedTab = 0;

  static const int _pageSize = 2;
  int _bookingPage = 0;
  int _issuePage = 0;

  String _profileImageUrl = "";
  bool _uploadingPhoto = false;
  final ImagePicker _picker = ImagePicker();

  String? selectedWard;
  String? _originalWard;



  String _roleLabel = "Resident";

  late TextEditingController _nameController;
  late TextEditingController _phoneController;
  late TextEditingController _emailController;

  List<BookingModel> _bookings = [];
  List<IssueModel> _issues = [];
  List<SavedLocationModel> _locations = [];

  final List<String> wards = [
    ...List.generate(32, (i) => "Kathmandu Ward ${i + 1}"),
    ...List.generate(29, (i) => "Lalitpur Ward ${i + 1}"),
    ...List.generate(10, (i) => "Bhaktapur Ward ${i + 1}"),
  ];

  final List<String> _wardsNe = [
    ...List.generate(32, (i) => "काठमाडौं वडा ${i + 1}"),
    ...List.generate(29, (i) => "ललितपुर वडा ${i + 1}"),
    ...List.generate(10, (i) => "भक्तपुर वडा ${i + 1}"),
  ];

  List<String> get _wardsByLocale {
    final langCode = Localizations.localeOf(context).languageCode;
    return (langCode == 'ne') ? _wardsNe : wards;
  }

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.userName);
    _phoneController = TextEditingController(text: widget.phone);
    _emailController = TextEditingController(text: widget.email);
    selectedWard = widget.ward;

    _loadProfile();
  }

  @override
  void dispose() {
    _nameController.dispose();
    _phoneController.dispose();
    _emailController.dispose();
    super.dispose();
  }

  Future<String?> _getFirebaseToken() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return null;
    return await user.getIdToken(true);
  }

  String _formatDate(DateTime dt) =>
      DateFormat('MMM d, yyyy • hh:mm a').format(dt.toLocal());

  String _formatTimeRange(DateTime? start, DateTime? end) {
    if (start == null || end == null) return "-";
    final fmt = DateFormat('hh:mm a');
    return "${fmt.format(start.toLocal())} – ${fmt.format(end.toLocal())}";
  }

  Color _bookingStatusColor(String status) {
    final s = status.toUpperCase();
    if (s == "COMPLETED" || s == "DELIVERED") return const Color(0xFF16A34A);
    if (s == "CONFIRMED") return const Color(0xFF2563EB);
    if (s == "CANCELLED") return const Color(0xFFDC2626);
    return const Color(0xFFF59E0B);
  }

  Color _issueStatusColor(String status) {
    final s = status.toUpperCase();
    if (s == "RESOLVED") return const Color(0xFF16A34A);
    if (s == "IN_REVIEW") return const Color(0xFF2563EB);
    return const Color(0xFFF97316);
  }

  String _roleToLabel(String role) {
    final r = role.toUpperCase();
    if (r == "VENDOR") return "Vendor";
    if (r == "ADMIN") return "Admin";
    return "Resident";
  }

  String _roleLocalized(AppLocalizations t) {
    final r = _roleLabel.toUpperCase().trim();
    if (r == "VENDOR") return t.vendor;
    if (r == "ADMIN") return t.admin;
    return t.resident;
  }

  String? _displayWardLabel(BuildContext context, String? wardFromBackend) {
    if (wardFromBackend == null) return null;

    final lang = Localizations.localeOf(context).languageCode;
    if (lang != 'ne') return wardFromBackend;

    final w = wardFromBackend.trim();

    final ktm = RegExp(r'^Kathmandu Ward (\d+)$', caseSensitive: false);
    final m1 = ktm.firstMatch(w);
    if (m1 != null) return "काठमाडौं वडा ${m1.group(1)}";

    final lal = RegExp(r'^Lalitpur Ward (\d+)$', caseSensitive: false);
    final m2 = lal.firstMatch(w);
    if (m2 != null) return "ललितपुर वडा ${m2.group(1)}";

    final bha = RegExp(r'^Bhaktapur Ward (\d+)$', caseSensitive: false);
    final m3 = bha.firstMatch(w);
    if (m3 != null) return "भक्तपुर वडा ${m3.group(1)}";

    return wardFromBackend;
  }

  String _absPhotoUrl(String url) {
    final u = url.trim();
    if (u.isEmpty) return "";
    if (u.startsWith("http://") || u.startsWith("https://")) return u;
    if (!u.startsWith("/")) return "$_baseUrl/$u";
    return "$_baseUrl$u";
  }

  Future<void> _pickAndUploadPhoto() async {
    try {
      final picked = await _picker.pickImage(
        source: ImageSource.gallery,
        imageQuality: 85,
      );
      if (picked == null) return;

      final idToken = await _getFirebaseToken();
      if (idToken == null) {
        throw Exception("Not authenticated. Please login again.");
      }

      setState(() => _uploadingPhoto = true);

      final request = http.MultipartRequest(
        'POST',
        Uri.parse("$_baseUrl/profile/me/photo"),
      );

      request.headers['Authorization'] = 'Bearer $idToken';
      request.files.add(
        await http.MultipartFile.fromPath('photo', picked.path),
      );

      final streamed = await request.send();
      final res = await http.Response.fromStream(streamed);

      if (res.statusCode != 200) {
        throw Exception("Upload failed: ${res.statusCode} - ${res.body}");
      }

      final data = jsonDecode(res.body) as Map<String, dynamic>;
      final newUrl = (data['profileImageUrl'] ?? '').toString();
      final refreshedUrl = newUrl.contains("?")
          ? newUrl
          : "$newUrl?t=${DateTime.now().millisecondsSinceEpoch}";

      setState(() => _profileImageUrl = refreshedUrl);
      _snack("Profile photo updated!", isError: false);
    } catch (e) {
      _snack("Photo upload failed: $e", isError: true);
    } finally {
      if (mounted) setState(() => _uploadingPhoto = false);
    }
  }

  Future<void> _deletePhoto() async {
    if (_profileImageUrl.trim().isEmpty) return;

    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(
          "Remove Photo",
          style: GoogleFonts.poppins(fontWeight: FontWeight.bold),
        ),
        content: Text(
          "Do you want to remove your profile photo?",
          style: GoogleFonts.poppins(),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text("Cancel", style: GoogleFonts.poppins(color: Colors.grey)),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: Text("Remove", style: GoogleFonts.poppins(color: Colors.red)),
          ),
        ],
      ),
    );

    if (confirm != true) return;

    try {
      final idToken = await _getFirebaseToken();
      if (idToken == null) {
        throw Exception("Not authenticated. Please login again.");
      }

      setState(() => _uploadingPhoto = true);

      final res = await http.delete(
        Uri.parse("$_baseUrl/profile/me/photo"),
        headers: {'Authorization': 'Bearer $idToken'},
      );

      if (res.statusCode != 200) {
        throw Exception("Delete failed: ${res.statusCode} - ${res.body}");
      }

      setState(() => _profileImageUrl = "");
      _snack("Profile photo removed!", isError: false);
    } catch (e) {
      _snack("Remove photo failed: $e", isError: true);
    } finally {
      if (mounted) setState(() => _uploadingPhoto = false);
    }
  }


  Future<void> _loadProfile() async {
    setState(() => _loadingProfile = true);

    try {
      final idToken = await _getFirebaseToken();
      if (idToken == null) {
        throw Exception("Not authenticated. Please login again.");
      }

      final res = await http.get(
        Uri.parse("$_baseUrl/profile/me"),
        headers: {'Authorization': 'Bearer $idToken'},
      );

      if (res.statusCode != 200) {
        throw Exception("Failed to load profile (${res.statusCode})");
      }

      final data = jsonDecode(res.body) as Map<String, dynamic>;
      final user = data['user'] as Map<String, dynamic>;

      setState(() {
        _nameController.text = (user['name'] ?? '').toString();
        _phoneController.text = (user['phone'] ?? '').toString();
        _emailController.text = (user['email'] ?? '').toString();

        _roleLabel = _roleToLabel((user['role'] ?? 'RESIDENT').toString());
        selectedWard = (user['ward'] ?? widget.ward)?.toString();
        _originalWard = selectedWard;


        _profileImageUrl = (user['profileImageUrl'] ?? '').toString();

        _bookings = ((data['bookings'] ?? []) as List)
            .map((e) => BookingModel.fromJson(e as Map<String, dynamic>))
            .toList();

        _issues = ((data['issues'] ?? []) as List)
            .map((e) => IssueModel.fromJson(e as Map<String, dynamic>))
            .toList();

        _locations = ((data['locations'] ?? []) as List)
            .map((e) => SavedLocationModel.fromJson(e as Map<String, dynamic>))
            .toList();

        _bookingPage = 0;
        _issuePage = 0;

        _loadingProfile = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() => _loadingProfile = false);
      _snack("Failed to load profile: $e", isError: true);
    }
  }

  Future<void> _saveProfile() async {
    if (selectedWard == null) {
      _snack("Please select your ward", isError: true);
      return;
    }
    final name = _nameController.text.trim();
    final phone = _phoneController.text.trim();

    if (name.isEmpty) {
      _snack("Please enter your full name", isError: true);
      return;
    }
    setState(() => _isSaving = true);
    try {
      final idToken = await _getFirebaseToken();
      if (idToken == null) {
        throw Exception("Not authenticated. Please login again.");
      }

      final oldWardName = _originalWard;

      final updateResponse = await http.patch(
        Uri.parse('$_baseUrl/auth/update-profile'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $idToken',
        },
        body: jsonEncode({'name': name, 'phone': phone, 'ward': selectedWard}),
      );

      if (updateResponse.statusCode != 200) {
        throw Exception(
          "HTTP ${updateResponse.statusCode}: ${updateResponse.body}",
        );
      }

      await FirebaseAuth.instance.currentUser?.updateDisplayName(name);

      try {
        final fcmService = FCMService();
        if (oldWardName != null &&
            oldWardName.isNotEmpty &&
            oldWardName != selectedWard) {
          await fcmService.unsubscribeFromWard(oldWardName);
        }
        if (selectedWard != null &&
            selectedWard!.isNotEmpty &&
            oldWardName != selectedWard) {
          await fcmService.subscribeToWard(selectedWard!);
        }
      } catch (_) {}

      setState(() => _originalWard = selectedWard);
      _snack("Profile saved!", isError: false);

      await Future.delayed(const Duration(milliseconds: 200));
      if (!mounted) return;

      AppNavigation.offAll(
        context,
        AppRoutes.home,
        arguments: {
          'role': _roleLabel,
          'userName': name,
          'phone': phone,
          'email': _emailController.text.trim(),
          'ward': selectedWard,
        },
      );
    } catch (e) {
      _snack("Save failed: $e", isError: true);
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  Future<void> _logout() async {
    final t = AppLocalizations.of(context);
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(t?.logOut ?? 'Log out'),
        content: const Text('Are you sure you want to log out?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Logout', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );

    if (confirm != true) return;

    try {
      try {
        final wardToUnsub = selectedWard ?? _originalWard ?? widget.ward;
        if (wardToUnsub != null && wardToUnsub.isNotEmpty) {
          await FCMService().unsubscribeFromWard(wardToUnsub);
        }
      } catch (_) {}

      await FirebaseAuth.instance.signOut();

      if (!mounted) return;
      AppNavigation.offAll(context, AppRoutes.login);
    } catch (e) {
      _snack("Logout failed: $e", isError: true);
    }
  }

  Future<void> _addLocationDialog() async {
    final picked = await Navigator.pushNamed(context, AppRoutes.locationPicker);

    if (picked is! Map) {
      _snack("Location not selected", isError: true);
      return;
    }

    final lat = (picked['lat'] as num?)?.toDouble();
    final lng = (picked['lng'] as num?)?.toDouble();

    if (lat == null || lng == null) {
      _snack("Invalid location selected", isError: true);
      return;
    }

    final labelCtrl = TextEditingController();
    bool makeDefault = false;

    if (!mounted) return;

    final ok = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        backgroundColor: Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16.r)),
        title: Text(
          "Save Location",
          style: GoogleFonts.poppins(
              fontWeight: FontWeight.bold, color: const Color(0xFF0F172A)),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: labelCtrl,
              decoration: InputDecoration(
                hintText: "Label (Home/Office)",
                hintStyle: GoogleFonts.poppins(color: const Color(0xFF94A3B8)),
                filled: true,
                fillColor: const Color(0xFFF8FAFC),
                border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12.r),
                    borderSide: BorderSide.none),
              ),
            ),
            SizedBox(height: 12.h),
            StatefulBuilder(
              builder: (ctx, setSt) => CheckboxListTile(
                value: makeDefault,
                activeColor: const Color(0xFF2563EB),
                onChanged: (v) => setSt(() => makeDefault = v == true),
                title: Text("Set as default",
                    style: GoogleFonts.poppins(fontWeight: FontWeight.w500)),
                controlAffinity: ListTileControlAffinity.leading,
                contentPadding: EdgeInsets.zero,
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text("Cancel",
                style: GoogleFonts.poppins(color: const Color(0xFF64748B))),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: Text("Save",
                style: GoogleFonts.poppins(color: const Color(0xFF2563EB))),
          ),
        ],
      ),
    );

    if (ok != true) return;

    try {
      final token = await _getFirebaseToken();
      if (token == null) throw Exception("Not authenticated");

      final res = await http.post(
        Uri.parse("$_baseUrl/profile/locations"),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
        body: jsonEncode({
          'label':
              labelCtrl.text.trim().isEmpty ? "Home" : labelCtrl.text.trim(),
          'address': "Pinned location",
          'lat': lat,
          'lng': lng,
          'isDefault': makeDefault,
        }),
      );

      if (res.statusCode != 201) {
        throw Exception("HTTP ${res.statusCode}: ${res.body}");
      }

      await _loadProfile();
      _snack("Location saved!", isError: false);
    } catch (e) {
      _snack("Add location failed: $e", isError: true);
    }
  }

  Future<void> _setDefaultLocation(int id) async {
    try {
      final token = await _getFirebaseToken();
      if (token == null) throw Exception("Not authenticated");

      final res = await http.patch(
        Uri.parse("$_baseUrl/profile/locations/$id/default"),
        headers: {'Authorization': 'Bearer $token'},
      );

      if (res.statusCode != 200) {
        throw Exception("HTTP ${res.statusCode}: ${res.body}");
      }
      await _loadProfile();
    } catch (e) {
      _snack("Failed: $e", isError: true);
    }
  }

  Future<void> _deleteLocation(int id) async {
    try {
      final token = await _getFirebaseToken();
      if (token == null) throw Exception("Not authenticated");

      final res = await http.delete(
        Uri.parse("$_baseUrl/profile/locations/$id"),
        headers: {'Authorization': 'Bearer $token'},
      );

      if (res.statusCode != 200) {
        throw Exception("HTTP ${res.statusCode}: ${res.body}");
      }
      await _loadProfile();
    } catch (e) {
      _snack("Delete failed: $e", isError: true);
    }
  }

  void _snack(String msg, {required bool isError}) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(msg),
        backgroundColor:
            isError ? const Color(0xFFEF4444) : const Color(0xFF16A34A),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10.r)),
      ),
    );
  }

  Widget _sectionHeader(String title, IconData icon, Color color) {
    return Padding(
      padding: EdgeInsets.symmetric(horizontal: 4.w),
      child: Row(
        children: [
          Container(
            padding: EdgeInsets.all(8.w),
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(10.r),
            ),
            child: Icon(icon, size: 18.w, color: color),
          ),
          SizedBox(width: 10.w),
          Text(
            title,
            style: GoogleFonts.poppins(
              fontSize: 14.sp,
              fontWeight: FontWeight.w700,
              color: const Color(0xFF334155),
              letterSpacing: 0.3,
            ),
          ),
        ],
      ),
    );
  }

  Widget _card({required Widget child}) => Container(
        padding: EdgeInsets.all(16.w),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16.r),
          border: Border.all(color: const Color(0xFFE2E8F0)),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.03),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: child,
      );

  @override
  Widget build(BuildContext context) {
    final t = AppLocalizations.of(context)!;
    final displayName = _nameController.text.trim().isNotEmpty
        ? _nameController.text.trim()
        : widget.userName;
    final photoUrl = _absPhotoUrl(_profileImageUrl);

    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(
        backgroundColor: Colors.white,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.arrow_back_ios_rounded,
              color: const Color(0xFF0F172A), size: 20.w),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          t.myProfile,
          style: GoogleFonts.poppins(
            fontSize: 18.sp,
            fontWeight: FontWeight.w700,
            color: const Color(0xFF0F172A),
          ),
        ),
        centerTitle: true,
        actions: [
          _isSaving
              ? Padding(
                  padding: EdgeInsets.only(right: 16.w),
                  child: SizedBox(
                    width: 20.w,
                    height: 20.w,
                    child: const CircularProgressIndicator(
                        strokeWidth: 2, color: Color(0xFF2563EB)),
                  ),
                )
              : GestureDetector(
                  onTap: _saveProfile,
                  child: Container(
                    margin: EdgeInsets.only(right: 12.w),
                    padding:
                        EdgeInsets.symmetric(horizontal: 14.w, vertical: 6.h),
                    decoration: BoxDecoration(
                      color: const Color(0xFF16A34A),
                      borderRadius: BorderRadius.circular(10.r),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.check_rounded,
                            size: 18.w, color: Colors.white),
                        SizedBox(width: 4.w),
                        Text(
                          t.save,
                          style: GoogleFonts.poppins(
                            fontSize: 13.sp,
                            fontWeight: FontWeight.w600,
                            color: Colors.white,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
        ],
      ),
      body: _loadingProfile
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
              onRefresh: _loadProfile,
              color: const Color(0xFF2563EB),
              child: SingleChildScrollView(
                physics: const AlwaysScrollableScrollPhysics(),
                padding: EdgeInsets.all(16.w),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // ─── Profile Header ──────────────
                    Container(
                      width: double.infinity,
                      padding: EdgeInsets.all(24.w),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(22.r),
                        border: Border.all(color: const Color(0xFFE2E8F0)),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: 0.04),
                            blurRadius: 12,
                            offset: const Offset(0, 4),
                          ),
                        ],
                      ),
                      child: Column(
                        children: [
                          Stack(
                            alignment: Alignment.bottomRight,
                            children: [
                              Container(
                                decoration: BoxDecoration(
                                  shape: BoxShape.circle,
                                  border: Border.all(
                                    color: const Color(0xFFE2E8F0),
                                    width: 3.w,
                                  ),
                                  boxShadow: [
                                    BoxShadow(
                                      color:
                                          Colors.black.withValues(alpha: 0.08),
                                      blurRadius: 12,
                                      offset: const Offset(0, 4),
                                    ),
                                  ],
                                ),
                                child: CircleAvatar(
                                  radius: 54.r,
                                  backgroundColor: const Color(0xFFF1F5F9),
                                  backgroundImage: photoUrl.isNotEmpty
                                      ? CachedNetworkImageProvider(photoUrl, errorListener: (err) => debugPrint('Avatar 404: $err')) as ImageProvider
                                      : null,
                                  onBackgroundImageError: photoUrl.isNotEmpty ? (_, __) {} : null,
                                  child: photoUrl.isEmpty
                                      ? Text(
                                          displayName.isNotEmpty
                                              ? displayName[0].toUpperCase()
                                              : "U",
                                          style: GoogleFonts.poppins(
                                            fontSize: 40.sp,
                                            fontWeight: FontWeight.bold,
                                            color: const Color(0xFF94A3B8),
                                          ),
                                        )
                                      : null,
                                ),
                              ),
                              Positioned(
                                right: 0,
                                bottom: 0,
                                child: InkWell(
                                  onTap: _uploadingPhoto
                                      ? null
                                      : _pickAndUploadPhoto,
                                  child: Container(
                                    padding: EdgeInsets.all(8.w),
                                    decoration: BoxDecoration(
                                      color: const Color(0xFF2563EB),
                                      shape: BoxShape.circle,
                                      border: Border.all(
                                          color: Colors.white, width: 2.5),
                                      boxShadow: [
                                        BoxShadow(
                                            color: Colors.black
                                                .withValues(alpha: 0.15),
                                            blurRadius: 6,
                                            offset: const Offset(0, 2))
                                      ],
                                    ),
                                    child: _uploadingPhoto
                                        ? SizedBox(
                                            width: 16.w,
                                            height: 16.w,
                                            child:
                                                const CircularProgressIndicator(
                                              strokeWidth: 2,
                                              color: Colors.white,
                                            ),
                                          )
                                        : Icon(Icons.camera_alt_rounded,
                                            color: Colors.white, size: 16.w),
                                  ),
                                ),
                              ),
                              if (photoUrl.isNotEmpty)
                                Positioned(
                                  left: 0,
                                  bottom: 0,
                                  child: InkWell(
                                    onTap: _uploadingPhoto ? null : _deletePhoto,
                                    child: Container(
                                      padding: EdgeInsets.all(8.w),
                                      decoration: BoxDecoration(
                                        color: const Color(0xFFEF4444),
                                        shape: BoxShape.circle,
                                        border: Border.all(
                                            color: Colors.white, width: 2.5),
                                        boxShadow: [
                                          BoxShadow(
                                              color: Colors.black
                                                  .withValues(alpha: 0.15),
                                              blurRadius: 6,
                                              offset: const Offset(0, 2))
                                        ],
                                      ),
                                      child: Icon(Icons.delete_rounded,
                                          color: Colors.white, size: 16.w),
                                    ),
                                  ),
                                ),
                            ],
                          ),
                          SizedBox(height: 16.h),
                          Text(
                            displayName,
                            style: GoogleFonts.poppins(
                              fontSize: 22.sp,
                              fontWeight: FontWeight.w700,
                              color: const Color(0xFF0F172A),
                            ),
                            textAlign: TextAlign.center,
                          ),
                          SizedBox(height: 10.h),
                          Container(
                            padding: EdgeInsets.symmetric(
                                horizontal: 16.w, vertical: 6.h),
                            decoration: BoxDecoration(
                              color: const Color(0xFFEFF6FF),
                              borderRadius: BorderRadius.circular(10.r),
                              border: Border.all(color: const Color(0xFFBFDBFE)),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(Icons.person_rounded,
                                    color: const Color(0xFF2563EB), size: 16.w),
                                SizedBox(width: 6.w),
                                Text(
                                  _roleLocalized(t).toUpperCase(),
                                  style: GoogleFonts.poppins(
                                    fontSize: 13.sp,
                                    fontWeight: FontWeight.w700,
                                    color: const Color(0xFF2563EB),
                                  ),
                                ),
                              ],
                            ),
                          ),
                          SizedBox(height: 8.h),
                          Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(Icons.location_city_rounded,
                                  size: 14.w, color: const Color(0xFF94A3B8)),
                              SizedBox(width: 4.w),
                              Text(
                                _displayWardLabel(context, selectedWard) ??
                                    t.noWardSelected,
                                style: GoogleFonts.poppins(
                                  fontSize: 13.sp,
                                  color: const Color(0xFF64748B),
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                    SizedBox(height: 24.h),

                    // ─── Stats Removed (Now in Dashboard Tabs) ────

                    // ─── Personal Details ────────────
                    _sectionHeader(t.personalDetailsUpper, Icons.person_outlined,
                        const Color(0xFF2563EB)),
                    SizedBox(height: 12.h),
                    _card(
                      child: Column(
                        children: [
                          _field(
                            t.fullName.toUpperCase(),
                            _nameController,
                            Icons.person_outline_rounded,
                          ),
                          SizedBox(height: 16.h),
                          _field(
                            t.phoneNumber.toUpperCase(),
                            _phoneController,
                            Icons.phone_rounded,
                          ),
                          SizedBox(height: 16.h),
                          _field(
                            t.emailLabel.toUpperCase(),
                            _emailController,
                            Icons.email_outlined,
                            enabled: false,
                          ),
                          SizedBox(height: 16.h),
                          _wardSelector(),
                        ],
                      ),
                    ),
                    SizedBox(height: 32.h),

                    // ─── Saved Locations ─────────────
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        _sectionHeader(t.savedLocations,
                            Icons.location_on_outlined, const Color(0xFF16A34A)),
                        GestureDetector(
                          onTap: _addLocationDialog,
                          child: Container(
                            padding: EdgeInsets.symmetric(
                                horizontal: 12.w, vertical: 6.h),
                            decoration: BoxDecoration(
                              color: const Color(0xFFF0FDF4),
                              borderRadius: BorderRadius.circular(8.r),
                              border: Border.all(color: const Color(0xFFBBF7D0)),
                            ),
                            child: Row(
                              children: [
                                Icon(Icons.add_rounded,
                                    size: 16.w, color: const Color(0xFF16A34A)),
                                SizedBox(width: 4.w),
                                Text(
                                  t.addNew,
                                  style: GoogleFonts.poppins(
                                    fontSize: 12.sp,
                                    fontWeight: FontWeight.w600,
                                    color: const Color(0xFF16A34A),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                    SizedBox(height: 12.h),
                    if (_locations.isEmpty)
                      _card(
                        child: Text(
                          t.noSavedLocationsYet,
                          style: GoogleFonts.poppins(
                              color: const Color(0xFF64748B), fontSize: 13.sp),
                        ),
                      )
                    else
                      ..._locations.map(
                        (l) => Padding(
                          padding: EdgeInsets.only(bottom: 12.h),
                          child: _locationCard(l),
                        ),
                      ),
                    SizedBox(height: 24.h),



                    // ─── Menu Items ──────────────────
                    ProfileMenuSection(
                      onChangePassword: () => Navigator.pushNamed(
                        context,
                        AppRoutes.changePassword,
                      ),
                      onForgotPassword: () => Navigator.pushNamed(
                        context,
                        AppRoutes.forgotPassword,
                      ),
                      onLanguage: () => Navigator.pushNamed(
                        context,
                        AppRoutes.languagePreference,
                      ),
                      onLogout: _logout,
                    ),
                    SizedBox(height: 100.h),
                  ],
                ),
              ),
            ),
    );
  }

  // ─── UI Helpers ──────────────────────────────
  Widget _statCard(String value, String label, Color bgColor, Color textColor) {
    return Container(
      padding: EdgeInsets.all(16.w),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(16.r),
        border: Border.all(color: textColor.withValues(alpha: 0.2)),
      ),
      child: Column(
        children: [
          Text(
            value,
            style: GoogleFonts.poppins(
              fontSize: 24.sp,
              fontWeight: FontWeight.w700,
              color: textColor,
            ),
          ),
          SizedBox(height: 4.h),
          Text(
            label,
            style: GoogleFonts.poppins(
                fontSize: 12.sp,
                fontWeight: FontWeight.w600,
                color: textColor.withValues(alpha: 0.8)),
          ),
        ],
      ),
    );
  }

  Widget _field(
    String label,
    TextEditingController controller,
    IconData icon, {
    bool enabled = true,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: GoogleFonts.poppins(
            fontSize: 11.sp,
            fontWeight: FontWeight.w600,
            color: const Color(0xFF94A3B8),
            letterSpacing: 0.5,
          ),
        ),
        SizedBox(height: 8.h),
        TextField(
          controller: controller,
          enabled: enabled,
          style: GoogleFonts.poppins(
            fontSize: 15.sp,
            fontWeight: FontWeight.w600,
            color: const Color(0xFF0F172A),
          ),
          decoration: InputDecoration(
            prefixIcon:
                Icon(icon, color: const Color(0xFF94A3B8), size: 20.w),
            filled: true,
            fillColor:
                enabled ? const Color(0xFFF8FAFC) : const Color(0xFFE2E8F0),
            contentPadding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 12.h),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12.r),
              borderSide: BorderSide(
                  color: enabled ? const Color(0xFFCBD5E1) : Colors.transparent),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12.r),
              borderSide: const BorderSide(color: Color(0xFFCBD5E1)),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12.r),
              borderSide: const BorderSide(color: Color(0xFF2563EB), width: 1.5),
            ),
          ),
        ),
      ],
    );
  }

  Widget _wardSelector() {
    final t = AppLocalizations.of(context)!;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          t.wardLabel.toUpperCase(),
          style: GoogleFonts.poppins(
            fontSize: 11.sp,
            fontWeight: FontWeight.w600,
            color: const Color(0xFF94A3B8),
            letterSpacing: 0.5,
          ),
        ),
        SizedBox(height: 8.h),
        GestureDetector(
          onTap: () async {
            final String? picked = await showModalBottomSheet<String>(
              context: context,
              isScrollControlled: true,
              backgroundColor: Colors.transparent,
              builder: (context) => DraggableScrollableSheet(
                initialChildSize: 0.6,
                minChildSize: 0.3,
                maxChildSize: 0.9,
                builder: (context, scrollController) => Container(
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.vertical(top: Radius.circular(24.r)),
                  ),
                  child: Column(
                    children: [
                      Container(
                        margin: EdgeInsets.only(top: 12.h),
                        width: 40.w,
                        height: 4.h,
                        decoration: BoxDecoration(
                          color: const Color(0xFFCBD5E1),
                          borderRadius: BorderRadius.circular(2),
                        ),
                      ),
                      Container(
                        padding: EdgeInsets.all(20.w),
                        child: Text(
                          t.selectYourWard,
                          style: GoogleFonts.poppins(
                            fontSize: 18.sp,
                            fontWeight: FontWeight.w700,
                            color: const Color(0xFF0F172A),
                          ),
                        ),
                      ),
                      Expanded(
                        child: ListView.builder(
                          controller: scrollController,
                          itemCount: _wardsByLocale.length,
                          itemBuilder: (context, index) {
                            final wardLabel = _wardsByLocale[index];
                            final isSelected = selectedWard == wardLabel;
                            return ListTile(
                              title: Text(
                                wardLabel,
                                style: GoogleFonts.poppins(
                                  fontWeight: isSelected
                                      ? FontWeight.w600
                                      : FontWeight.normal,
                                  color: isSelected
                                      ? const Color(0xFF2563EB)
                                      : const Color(0xFF334155),
                                ),
                              ),
                              trailing: isSelected
                                  ? Icon(Icons.check_circle_rounded,
                                      color: const Color(0xFF2563EB), size: 24.w)
                                  : null,
                              onTap: () => Navigator.pop(context, wardLabel),
                            );
                          },
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            );

            if (picked != null) setState(() => selectedWard = picked);
          },
          child: Container(
            padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 14.h),
            decoration: BoxDecoration(
              color: const Color(0xFFF8FAFC),
              borderRadius: BorderRadius.circular(12.r),
              border: Border.all(
                color: (selectedWard != _originalWard)
                    ? const Color(0xFF2563EB)
                    : const Color(0xFFCBD5E1),
                width: (selectedWard != _originalWard) ? 1.5 : 1.0,
              ),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Builder(
                    builder: (_) {
                      final wardText = _displayWardLabel(context, selectedWard);
                      return Text(
                        wardText ?? t.selectYourWardHint,
                        style: GoogleFonts.poppins(
                          fontSize: 15.sp,
                          fontWeight: FontWeight.w600,
                          color: selectedWard != null
                              ? const Color(0xFF0F172A)
                              : const Color(0xFF94A3B8),
                        ),
                      );
                    },
                  ),
                ),
                Icon(
                  Icons.keyboard_arrow_down_rounded,
                  color: (selectedWard != _originalWard)
                      ? const Color(0xFF2563EB)
                      : const Color(0xFF94A3B8),
                  size: 24.w,
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _locationCard(SavedLocationModel loc) {
    final t = AppLocalizations.of(context)!;
    final isHome = loc.label.toLowerCase().contains("home");
    final icon = isHome ? Icons.home_rounded : Icons.storefront_rounded;
    final iconColor = isHome ? const Color(0xFF2563EB) : const Color(0xFFF97316);

    return Container(
      padding: EdgeInsets.all(16.w),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16.r),
        border: Border.all(color: const Color(0xFFE2E8F0)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.03),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: EdgeInsets.all(10.w),
            decoration: BoxDecoration(
              color: iconColor.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(12.r),
            ),
            child: Icon(icon, color: iconColor, size: 24.w),
          ),
          SizedBox(width: 14.w),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Text(
                      loc.label,
                      style: GoogleFonts.poppins(
                        fontSize: 15.sp,
                        fontWeight: FontWeight.w600,
                        color: const Color(0xFF0F172A),
                      ),
                    ),
                    SizedBox(width: 8.w),
                    if (loc.isDefault)
                      Container(
                        padding: EdgeInsets.symmetric(
                            horizontal: 8.w, vertical: 3.h),
                        decoration: BoxDecoration(
                          color: const Color(0xFFDCFCE7),
                          borderRadius: BorderRadius.circular(20.r),
                        ),
                        child: Text(
                          t.defaultBadge,
                          style: GoogleFonts.poppins(
                            fontSize: 10.sp,
                            fontWeight: FontWeight.w600,
                            color: const Color(0xFF16A34A),
                          ),
                        ),
                      ),
                  ],
                ),
                SizedBox(height: 4.h),
                Text(
                  loc.address,
                  style: GoogleFonts.poppins(
                    fontSize: 13.sp,
                    color: const Color(0xFF64748B),
                  ),
                ),
                SizedBox(height: 10.h),
                Row(
                  children: [
                    GestureDetector(
                      onTap: () => _setDefaultLocation(loc.id),
                      child: Text(
                        t.setDefault,
                        style: GoogleFonts.poppins(
                          fontSize: 13.sp,
                          fontWeight: FontWeight.w600,
                          color: const Color(0xFF2563EB),
                        ),
                      ),
                    ),
                    SizedBox(width: 20.w),
                    GestureDetector(
                      onTap: () => _deleteLocation(loc.id),
                      child: Text(
                        t.delete,
                        style: GoogleFonts.poppins(
                          fontSize: 13.sp,
                          fontWeight: FontWeight.w600,
                          color: const Color(0xFFEF4444),
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
