import 'dart:convert';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:http/http.dart' as http;
import 'package:image_picker/image_picker.dart';
import 'package:intl/intl.dart';

import '../booking/detail/booking_detail_screen.dart';
import '../booking/history/my_bookings_history_screen.dart';
import '../complaint/detail/complaint_detail_screen.dart';
import '../core/routes/app_navigation.dart';
import '../core/routes/routes.dart';
import '../notifications/fcm_service.dart';
import 'widgets/profile_menu_section.dart';

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
    DateTime? parseDt(dynamic v) => v == null ? null : DateTime.tryParse(v.toString());
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
      id: (json['id'] ?? 0) is int ? (json['id'] ?? 0) : int.tryParse(json['id'].toString()) ?? 0,
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
  static const String _baseUrl = "http://10.0.2.2:3000";

  bool _loadingProfile = true;
  bool _isSaving = false;

  // Recent activity toggle (button)
  bool _showRecentActivity = false;
  int selectedTab = 0;

  // Pagination
  static const int _pageSize = 2;
  int _bookingPage = 0;
  int _issuePage = 0;

  // Profile photo
  String _profileImageUrl = "";
  bool _uploadingPhoto = false;
  final ImagePicker _picker = ImagePicker();

  // Ward
  String? selectedWard;
  String? _originalWard;

  // Language
  String _language = "EN"; // EN/NP from backend

  String _roleLabel = "Resident";

  late TextEditingController _nameController;
  late TextEditingController _phoneController;
  late TextEditingController _emailController;

  List<BookingModel> _bookings = [];
  List<IssueModel> _issues = [];
  List<SavedLocationModel> _locations = [];

  // English wards
  final List<String> wards = [
    ...List.generate(32, (i) => "Kathmandu Ward ${i + 1}"),
    ...List.generate(29, (i) => "Lalitpur Ward ${i + 1}"),
    ...List.generate(10, (i) => "Bhaktapur Ward ${i + 1}"),
  ];

  //  Nepali wards
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

  String _formatDate(DateTime dt) => DateFormat('MMM d, yyyy • hh:mm a').format(dt.toLocal());

  String _formatTimeRange(DateTime? start, DateTime? end) {
    if (start == null || end == null) return "-";
    final fmt = DateFormat('hh:mm a');
    return "${fmt.format(start.toLocal())} - ${fmt.format(end.toLocal())}";
  }

  Color _bookingStatusColor(String status) {
    final s = status.toUpperCase();
    if (s == "COMPLETED") return Colors.green;
    if (s == "CONFIRMED") return Colors.blue;
    if (s == "CANCELLED") return Colors.red;
    return Colors.orange;
  }

  Color _issueStatusColor(String status) {
    final s = status.toUpperCase();
    if (s == "RESOLVED") return Colors.green;
    if (s == "IN_REVIEW") return Colors.blue;
    return Colors.orange;
  }

  String _roleToLabel(String role) {
    final r = role.toUpperCase();
    if (r == "VENDOR") return "Vendor";
    // if (r == "WARD_ADMIN") return "Ward Admin";
    if (r == "ADMIN") return "Admin";
    return "Resident";
  }

  //  localized role label
  String _roleLocalized(AppLocalizations t) {
    final r = _roleLabel.toUpperCase().trim();
    if (r == "VENDOR") return t.vendor;
    // if (r == "WARD_ADMIN" || r == "WARD ADMIN") return t.wardAdmin;
    if (r == "ADMIN") return t.admin;
    return t.resident;
  }

  // display ward in Nepali while keeping backend value in English
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


  // Photo upload / delete

  Future<void> _pickAndUploadPhoto() async {
    try {
      final picked = await _picker.pickImage(
        source: ImageSource.gallery,
        imageQuality: 85,
      );
      if (picked == null) return;

      final idToken = await _getFirebaseToken();
      if (idToken == null) throw Exception("Not authenticated. Please login again.");

      setState(() => _uploadingPhoto = true);

      final request = http.MultipartRequest(
        'POST',
        Uri.parse("$_baseUrl/profile/me/photo"),
      );

      request.headers['Authorization'] = 'Bearer $idToken';
      request.files.add(await http.MultipartFile.fromPath('photo', picked.path));

      final streamed = await request.send();
      final res = await http.Response.fromStream(streamed);

      if (res.statusCode != 200) {
        throw Exception("Upload failed: ${res.statusCode} - ${res.body}");
      }

      final data = jsonDecode(res.body) as Map<String, dynamic>;

      // backend returns { profileImageUrl: "http://..." }
      final newUrl = (data['profileImageUrl'] ?? '').toString();

      // cache bust so updated image shows immediately
      final refreshedUrl = newUrl.contains("?") ? newUrl : "$newUrl?t=${DateTime.now().millisecondsSinceEpoch}";

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
        title: Text("Remove Photo", style: GoogleFonts.poppins(fontWeight: FontWeight.bold)),
        content: Text("Do you want to remove your profile photo?", style: GoogleFonts.poppins()),
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
      if (idToken == null) throw Exception("Not authenticated. Please login again.");

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


  // Pagination

  int _totalPages(int totalItems) => ((totalItems / _pageSize).ceil() <= 0) ? 1 : (totalItems / _pageSize).ceil();

  List<BookingModel> get _visibleBookings {
    final start = _bookingPage * _pageSize;
    if (start >= _bookings.length) return [];
    final end = (start + _pageSize).clamp(0, _bookings.length);
    return _bookings.sublist(start, end);
  }

  List<IssueModel> get _visibleIssues {
    final start = _issuePage * _pageSize;
    if (start >= _issues.length) return [];
    final end = (start + _pageSize).clamp(0, _issues.length);
    return _issues.sublist(start, end);
  }

  Widget _buildPagination({
    required int page,
    required int totalItems,
    required VoidCallback onPrev,
    required VoidCallback onNext,
  }) {
    final totalPages = _totalPages(totalItems);

    return Padding(
      padding: const EdgeInsets.only(top: 6),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          IconButton(onPressed: page > 0 ? onPrev : null, icon: const Icon(Icons.chevron_left)),
          Text("Page ${page + 1} of $totalPages", style: GoogleFonts.poppins(fontSize: 12, color: Colors.grey[700])),
          IconButton(onPressed: (page + 1) < totalPages ? onNext : null, icon: const Icon(Icons.chevron_right)),
        ],
      ),
    );
  }


  //  Save profile

  Future<void> _loadProfile() async {
    setState(() => _loadingProfile = true);

    try {
      final idToken = await _getFirebaseToken();
      if (idToken == null) throw Exception("Not authenticated. Please login again.");

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

        _language = (user['language'] ?? 'EN').toString();

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
      if (idToken == null) throw Exception("Not authenticated. Please login again.");

      final oldWardName = _originalWard;

      final updateResponse = await http.patch(
        Uri.parse('$_baseUrl/auth/update-profile'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $idToken',
        },
        body: jsonEncode({
          'name': name,
          'phone': phone,
          'ward': selectedWard,
        }),
      );

      if (updateResponse.statusCode != 200) {
        throw Exception("HTTP ${updateResponse.statusCode}: ${updateResponse.body}");
      }

      await FirebaseAuth.instance.currentUser?.updateDisplayName(name);

      try {
        final fcmService = FCMService();
        if (oldWardName != null && oldWardName.isNotEmpty && oldWardName != selectedWard) {
          await fcmService.unsubscribeFromWard(oldWardName);
        }
        if (selectedWard != null && selectedWard!.isNotEmpty && oldWardName != selectedWard) {
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


  // Saved Locations API

  Future<void> _addLocationDialog() async {
    // open map picker first
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

    //  ask label + set default
    final labelCtrl = TextEditingController();
    bool makeDefault = false;

    final ok = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: Text("Save Location", style: GoogleFonts.poppins(fontWeight: FontWeight.bold)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: labelCtrl,
              decoration: const InputDecoration(hintText: "Label (Home/Office)"),
            ),
            const SizedBox(height: 8),
            StatefulBuilder(
              builder: (ctx, setSt) => CheckboxListTile(
                value: makeDefault,
                onChanged: (v) => setSt(() => makeDefault = v == true),
                title: Text("Set as default", style: GoogleFonts.poppins()),
                controlAffinity: ListTileControlAffinity.leading,
              ),
            )
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text("Cancel")),
          TextButton(onPressed: () => Navigator.pop(context, true), child: const Text("Save")),
        ],
      ),
    );

    if (ok != true) return;

    // send to backend
    try {
      final token = await _getFirebaseToken();
      if (token == null) throw Exception("Not authenticated");

      final res = await http.post(
        Uri.parse("$_baseUrl/profile/locations"),
        headers: {'Content-Type': 'application/json', 'Authorization': 'Bearer $token'},
        body: jsonEncode({
          'label': labelCtrl.text.trim().isEmpty ? "Home" : labelCtrl.text.trim(),
          'address': "Pinned location", //
          'lat': lat,
          'lng': lng,
          'isDefault': makeDefault,
        }),
      );

      if (res.statusCode != 201) throw Exception("HTTP ${res.statusCode}: ${res.body}");

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

      if (res.statusCode != 200) throw Exception("HTTP ${res.statusCode}: ${res.body}");
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

      if (res.statusCode != 200) throw Exception("HTTP ${res.statusCode}: ${res.body}");
      await _loadProfile();
    } catch (e) {
      _snack("Delete failed: $e", isError: true);
    }
  }

  // UI helpers

  void _snack(String msg, {required bool isError}) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(msg),
        backgroundColor: isError ? Colors.red : Colors.green,
        behavior: SnackBarBehavior.floating,
        margin: const EdgeInsets.all(16),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      ),
    );
  }

  Widget _sectionTitle(String t) => Text(t, style: GoogleFonts.poppins(fontSize: 18, fontWeight: FontWeight.w600));

  Widget _card({required Widget child}) => Container(
    padding: const EdgeInsets.all(16),
    decoration: BoxDecoration(
      color: Colors.white,
      borderRadius: BorderRadius.circular(16),
      boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10, offset: const Offset(0, 4))],
    ),
    child: child,
  );

  @override
  Widget build(BuildContext context) {
    final t = AppLocalizations.of(context)!;

    final displayName = _nameController.text.trim().isNotEmpty ? _nameController.text.trim() : widget.userName;
    final photoUrl = _absPhotoUrl(_profileImageUrl);

    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.black),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          t.myProfile,
          style: GoogleFonts.poppins(
            fontSize: 20,
            fontWeight: FontWeight.w600,
            color: Colors.black,
          ),
        ),
        actions: [
          _isSaving
              ? const Padding(
            padding: EdgeInsets.all(16.0),
            child: SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2)),
          )
              : TextButton(
            onPressed: _saveProfile,
            child: Text(
              t.save,
              style: GoogleFonts.poppins(color: Colors.blue, fontWeight: FontWeight.w600),
            ),
          ),
        ],
      ),
      body: _loadingProfile
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
        onRefresh: _loadProfile,
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Column(
                  children: [
                    Stack(
                      children: [
                        CircleAvatar(
                          radius: 50,
                          backgroundColor: Colors.blue[100],
                          backgroundImage: photoUrl.isNotEmpty ? NetworkImage(photoUrl) : null,
                          child: photoUrl.isEmpty
                              ? Text(
                            displayName.isNotEmpty ? displayName[0].toUpperCase() : "U",
                            style: GoogleFonts.poppins(fontSize: 40, fontWeight: FontWeight.bold, color: Colors.blue),
                          )
                              : null,
                        ),

                        // Upload photo
                        Positioned(
                          right: 2,
                          bottom: 2,
                          child: InkWell(
                            onTap: _uploadingPhoto ? null : _pickAndUploadPhoto,
                            child: Container(
                              padding: const EdgeInsets.all(8),
                              decoration: BoxDecoration(
                                color: Colors.blue,
                                shape: BoxShape.circle,
                                border: Border.all(color: Colors.white, width: 2),
                              ),
                              child: _uploadingPhoto
                                  ? const SizedBox(
                                width: 18,
                                height: 18,
                                child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                              )
                                  : const Icon(Icons.camera_alt, color: Colors.white, size: 18),
                            ),
                          ),
                        ),

                        // Delete photo
                        if (photoUrl.isNotEmpty)
                          Positioned(
                            left: 2,
                            bottom: 2,
                            child: InkWell(
                              onTap: _uploadingPhoto ? null : _deletePhoto,
                              child: Container(
                                padding: const EdgeInsets.all(8),
                                decoration: BoxDecoration(
                                  color: Colors.red,
                                  shape: BoxShape.circle,
                                  border: Border.all(color: Colors.white, width: 2),
                                ),
                                child: const Icon(Icons.delete, color: Colors.white, size: 18),
                              ),
                            ),
                          ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    Text(displayName, style: GoogleFonts.poppins(fontSize: 22, fontWeight: FontWeight.bold)),
                    Text(
                      "${_roleLocalized(t)} • ${_displayWardLabel(context, selectedWard) ?? t.noWardSelected}",
                      style: GoogleFonts.poppins(fontSize: 14, color: Colors.grey[600]),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),

              // Stats
              Row(
                children: [
                  Expanded(child: _statCard("${_bookings.length}", t.bookings, Colors.blue[50]!)),
                  const SizedBox(width: 12),
                  Expanded(child: _statCard("${_issues.length}", t.reports, Colors.orange[50]!)),
                ],
              ),

              const SizedBox(height: 32),

              _sectionTitle(t.personalDetails),
              const SizedBox(height: 12),
              _card(
                child: Column(
                  children: [
                    _field(t.fullName.toUpperCase(), _nameController, Icons.person),
                    const SizedBox(height: 16),
                    _field(t.phoneNumber.toUpperCase(), _phoneController, Icons.phone),
                    const SizedBox(height: 16),
                    _field(t.emailLabel.toUpperCase(), _emailController, Icons.email, enabled: false),
                    const SizedBox(height: 16),
                    _wardSelector(),
                  ],
                ),
              ),

              const SizedBox(height: 32),

              // Saved locations
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  _sectionTitle(t.savedLocations),
                  TextButton(
                    onPressed: _addLocationDialog,
                    child: Text(
                      t.addNew,
                      style: GoogleFonts.poppins(color: Colors.blue, fontWeight: FontWeight.w600),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              if (_locations.isEmpty)
                _card(child: Text(t.noSavedLocationsYet, style: GoogleFonts.poppins(color: Colors.grey[700])))
              else
                ..._locations.map((l) => Padding(
                  padding: const EdgeInsets.only(bottom: 12),
                  child: _locationCard(l),
                )),

              const SizedBox(height: 20),

              // Recent activity toggle button
              SizedBox(
                width: double.infinity,
                child: OutlinedButton(
                  onPressed: () => setState(() => _showRecentActivity = !_showRecentActivity),
                  style: OutlinedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                  child: Text(
                    _showRecentActivity ? t.hideRecentActivity : t.showRecentActivity,
                    style: GoogleFonts.poppins(fontWeight: FontWeight.w600, color: Colors.blue),
                  ),
                ),
              ),

              if (_showRecentActivity) ...[
                const SizedBox(height: 20),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    _sectionTitle(t.recentActivity),
                    TextButton(
                      onPressed: () {
                        if (selectedTab == 0) {
                          Navigator.push(context, MaterialPageRoute(builder: (_) => const MyBookingsHistoryScreen()));
                        } else {
                          _snack(t.complaintsHistoryNotAdded, isError: false);
                        }
                      },
                      child: Text(
                        t.seeAll,
                        style: GoogleFonts.poppins(color: Colors.blue, fontWeight: FontWeight.w600),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Container(
                  decoration: BoxDecoration(color: Colors.grey[200], borderRadius: BorderRadius.circular(30)),
                  child: Row(
                    children: [
                      Expanded(child: _activityTab(t.tabBookings, 0)),
                      Expanded(child: _activityTab(t.tabComplaints, 1)),
                    ],
                  ),
                ),
                const SizedBox(height: 16),
                if (selectedTab == 0) ...[
                  if (_bookings.isEmpty)
                    _card(child: Text(t.noBookingsYet, style: GoogleFonts.poppins(color: Colors.grey[700])))
                  else ...[
                    ..._visibleBookings.map((b) => Padding(
                      padding: const EdgeInsets.only(bottom: 12),
                      child: _activityItem(
                        icon: Icons.local_shipping,
                        title: "Booking #${b.id}",
                        subtitle:
                        "${b.routeLocation ?? "-"} • ${_formatTimeRange(b.slotStartTime, b.slotEndTime)} • ${_formatDate(b.createdAt)}",
                        status: b.status,
                        statusColor: _bookingStatusColor(b.status),
                        onTap: () => Navigator.push(
                          context,
                          MaterialPageRoute(builder: (_) => BookingDetailScreen(bookingId: b.id)),
                        ),
                      ),
                    )),
                    _buildPagination(
                      page: _bookingPage,
                      totalItems: _bookings.length,
                      onPrev: () => setState(() => _bookingPage--),
                      onNext: () => setState(() => _bookingPage++),
                    )
                  ]
                ] else ...[
                  if (_issues.isEmpty)
                    _card(child: Text(t.noComplaintsYet, style: GoogleFonts.poppins(color: Colors.grey[700])))
                  else ...[
                    ..._visibleIssues.map((i) => Padding(
                      padding: const EdgeInsets.only(bottom: 12),
                      child: _activityItem(
                        icon: Icons.warning,
                        title: i.title,
                        subtitle: "Complaint #${i.id} • ${_formatDate(i.createdAt)}",
                        status: i.status,
                        statusColor: _issueStatusColor(i.status),
                        onTap: () => Navigator.push(
                          context,
                          MaterialPageRoute(builder: (_) => ComplaintDetailScreen(complaintId: i.id)),
                        ),
                      ),
                    )),
                    _buildPagination(
                      page: _issuePage,
                      totalItems: _issues.length,
                      onPrev: () => setState(() => _issuePage--),
                      onNext: () => setState(() => _issuePage++),
                    )
                  ]
                ],
              ],

              const SizedBox(height: 32),

              ProfileMenuSection(
                onChangePassword: () => Navigator.pushNamed(context, AppRoutes.changePassword),
                onLanguage: () => Navigator.pushNamed(context, AppRoutes.languagePreference),
                onLogout: _logout,
              ),

              const SizedBox(height: 100),
            ],
          ),
        ),
      ),
    );
  }

  // small UI widgets
  Widget _statCard(String value, String label, Color color) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(color: color, borderRadius: BorderRadius.circular(16)),
      child: Column(
        children: [
          Text(value, style: GoogleFonts.poppins(fontSize: 24, fontWeight: FontWeight.bold)),
          const SizedBox(height: 4),
          Text(label, style: GoogleFonts.poppins(fontSize: 12, color: Colors.grey[700])),
        ],
      ),
    );
  }

  Widget _field(String label, TextEditingController controller, IconData icon, {bool enabled = true}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: GoogleFonts.poppins(fontSize: 12, color: Colors.grey[600])),
        const SizedBox(height: 8),
        TextField(
          controller: controller,
          enabled: enabled,
          decoration: InputDecoration(
            prefixIcon: Icon(icon, color: Colors.grey),
            filled: true,
            fillColor: enabled ? Colors.grey[100] : Colors.grey[200],
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
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
          style: GoogleFonts.poppins(fontSize: 12, color: Colors.grey[600]),
        ),
        const SizedBox(height: 8),
        GestureDetector(
          onTap: () async {
            final String? picked = await showModalBottomSheet<String>(
              context: context,
              isScrollControlled: true,
              shape: const RoundedRectangleBorder(
                borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
              ),
              builder: (context) => DraggableScrollableSheet(
                initialChildSize: 0.6,
                minChildSize: 0.3,
                maxChildSize: 0.9,
                expand: false,
                builder: (context, scrollController) => Column(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(16),
                      child: Text(
                        t.selectYourWard,
                        style: GoogleFonts.poppins(fontSize: 18, fontWeight: FontWeight.bold),
                      ),
                    ),
                    Expanded(
                      child: ListView.builder(
                        controller: scrollController,
                        itemCount: _wardsByLocale.length,
                        itemBuilder: (context, index) {
                          final wardLabel = _wardsByLocale[index];
                          return ListTile(
                            title: Text(wardLabel, style: GoogleFonts.poppins()),
                            trailing: selectedWard == wardLabel
                                ? const Icon(Icons.check_circle, color: Colors.blue)
                                : null,
                            onTap: () => Navigator.pop(context, wardLabel),
                          );
                        },
                      ),
                    ),
                  ],
                ),
              ),
            );

            if (picked != null) setState(() => selectedWard = picked);
          },
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
            decoration: BoxDecoration(
              color: Colors.grey[100],
              borderRadius: BorderRadius.circular(12),
              border: (selectedWard != _originalWard) ? Border.all(color: Colors.blue, width: 2) : null,
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
                          fontSize: 16,
                          color: selectedWard != null ? Colors.black : Colors.grey,
                        ),
                      );
                    },
                  ),
                ),
                Icon(
                  Icons.keyboard_arrow_down,
                  color: (selectedWard != _originalWard) ? Colors.blue : Colors.grey,
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
    final icon = loc.label.toLowerCase().contains("home") ? Icons.home : Icons.storefront;

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10, offset: const Offset(0, 4))],
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 38,
            height: 38,
            decoration: BoxDecoration(color: Colors.blue.withOpacity(0.12), borderRadius: BorderRadius.circular(12)),
            child: Icon(icon, color: Colors.blue),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Text(loc.label, style: GoogleFonts.poppins(fontWeight: FontWeight.w600)),
                    const SizedBox(width: 8),
                    if (loc.isDefault)
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                        decoration: BoxDecoration(color: Colors.green.withOpacity(0.12), borderRadius: BorderRadius.circular(20)),
                        child: Text(
                          t.defaultBadge,
                          style: GoogleFonts.poppins(fontSize: 10, fontWeight: FontWeight.w600, color: Colors.green[800]),
                        ),
                      ),
                  ],
                ),
                const SizedBox(height: 4),
                Text(loc.address, style: GoogleFonts.poppins(fontSize: 12, color: Colors.grey[700])),
                const SizedBox(height: 8),
                Row(
                  children: [
                    TextButton(
                      onPressed: () => _setDefaultLocation(loc.id),
                      child: Text(t.setDefault, style: GoogleFonts.poppins(color: Colors.blue)),
                    ),
                    TextButton(
                      onPressed: () => _deleteLocation(loc.id),
                      child: Text(t.delete, style: GoogleFonts.poppins(color: Colors.red)),
                    ),
                  ],
                )
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _activityTab(String title, int index) {
    return GestureDetector(
      onTap: () => setState(() => selectedTab = index),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 12),
        decoration: BoxDecoration(
          color: selectedTab == index ? Colors.white : Colors.transparent,
          borderRadius: BorderRadius.circular(30),
        ),
        child: Text(
          title,
          textAlign: TextAlign.center,
          style: GoogleFonts.poppins(
            fontWeight: selectedTab == index ? FontWeight.w600 : FontWeight.normal,
            color: selectedTab == index ? Colors.blue : Colors.grey[700],
          ),
        ),
      ),
    );
  }

  Widget _activityItem({
    required IconData icon,
    required String title,
    required String subtitle,
    required String status,
    required Color statusColor,
    required VoidCallback onTap,
  }) {
    final lightBg = statusColor.withOpacity(0.1);

    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10, offset: const Offset(0, 4))],
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(color: lightBg, borderRadius: BorderRadius.circular(12)),
              child: Icon(icon, color: statusColor, size: 24),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title, style: GoogleFonts.poppins(fontWeight: FontWeight.w600)),
                  const SizedBox(height: 2),
                  Text(
                    subtitle,
                    style: GoogleFonts.poppins(fontSize: 12, color: Colors.grey[600]),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              decoration: BoxDecoration(color: lightBg, borderRadius: BorderRadius.circular(20)),
              child: Text(
                status,
                style: GoogleFonts.poppins(fontSize: 10, fontWeight: FontWeight.w600, color: statusColor),
              ),
            ),
          ],
        ),
      ),
    );
  }
}