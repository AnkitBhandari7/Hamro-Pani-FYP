import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:http/http.dart' as http;
import 'package:firebase_auth/firebase_auth.dart';
import 'package:intl/intl.dart';
import 'package:image_picker/image_picker.dart';
import '../../core/routes/app_navigation.dart';
import '../../core/routes/routes.dart';
import 'package:fyp/notifications/fcm_service.dart';
import 'package:fyp/booking/history/my_bookings_history_screen.dart';
import 'package:fyp/booking/detail/booking_detail_screen.dart';
import 'package:fyp/complaint/detail/complaint_detail_screen.dart';




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
    DateTime? parseDt(dynamic v) {
      if (v == null) return null;
      return DateTime.tryParse(v.toString());
    }

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

  int selectedTab = 0;

  bool _isSaving = false;
  bool _loadingProfile = true;

  // Profile photo
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

  final List<String> wards = [
    ...List.generate(32, (i) => "Kathmandu Ward ${i + 1}"),
    ...List.generate(29, (i) => "Lalitpur Ward ${i + 1}"),
    ...List.generate(10, (i) => "Bhaktapur Ward ${i + 1}"),
  ];

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

  String? _wardNameFrom(dynamic wardRaw) {
    if (wardRaw == null) return null;
    if (wardRaw is String) return wardRaw;
    if (wardRaw is Map) return wardRaw['name']?.toString();
    return wardRaw.toString();
  }

  Future<String?> _getFirebaseToken() async {
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) return null;
      return await user.getIdToken(true);
    } catch (e) {
      debugPrint("Error getting Firebase token: $e");
      return null;
    }
  }

  String _formatDate(DateTime dt) {
    return DateFormat('MMM d, yyyy • hh:mm a').format(dt.toLocal());
  }

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
    if (r == "WARD_ADMIN") return "Ward Admin";
    if (r == "ADMIN") return "Admin";
    return "Resident";
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
      final newUrl = (data['profileImageUrl'] ?? '').toString();

      // cache-bust so updated image shows immediately
      final refreshedUrl = newUrl.contains("?")
          ? newUrl
          : "$newUrl?t=${DateTime.now().millisecondsSinceEpoch}";

      setState(() => _profileImageUrl = refreshedUrl);

      _showSnackBar("Profile photo updated!", isError: false);
    } catch (e) {
      debugPrint("Photo upload error: $e");
      _showSnackBar("Photo upload failed: $e", isError: true);
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
      _showSnackBar("Profile photo removed!", isError: false);
    } catch (e) {
      debugPrint("Delete photo error: $e");
      _showSnackBar("Remove photo failed: $e", isError: true);
    } finally {
      if (mounted) setState(() => _uploadingPhoto = false);
    }
  }

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

      final newWard = _wardNameFrom(user['ward']);
      final role = (user['role'] ?? 'RESIDENT').toString();
      final photoUrl = (user['profileImageUrl'] ?? '').toString();

      setState(() {
        _nameController.text = (user['name'] ?? '').toString();
        _phoneController.text = (user['phone'] ?? '').toString();
        _emailController.text = (user['email'] ?? '').toString();

        _roleLabel = _roleToLabel(role);

        selectedWard = newWard;
        _originalWard = newWard;

        _profileImageUrl = photoUrl;

        _bookings = ((data['bookings'] ?? []) as List)
            .map((e) => BookingModel.fromJson(e as Map<String, dynamic>))
            .toList();

        _issues = ((data['issues'] ?? []) as List)
            .map((e) => IssueModel.fromJson(e as Map<String, dynamic>))
            .toList();

        _loadingProfile = false;
      });
    } catch (e) {
      debugPrint("Load profile error: $e");
      if (!mounted) return;
      setState(() => _loadingProfile = false);
      _showSnackBar("Failed to load profile: $e", isError: true);
    }
  }

  Future<void> _saveProfile() async {
    if (selectedWard == null) {
      _showSnackBar("Please select your ward", isError: true);
      return;
    }

    final name = _nameController.text.trim();
    final phone = _phoneController.text.trim();

    if (name.isEmpty) {
      _showSnackBar("Please enter your full name", isError: true);
      return;
    }

    setState(() => _isSaving = true);

    try {
      final idToken = await _getFirebaseToken();
      if (idToken == null) {
        _showSnackBar("Not authenticated. Please login again.", isError: true);
        return;
      }

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
        _showSnackBar("Failed to save profile", isError: true);
        return;
      }

      final decoded = jsonDecode(updateResponse.body);
      final userData = (decoded is Map && decoded['user'] != null) ? decoded['user'] : decoded;

      final wardRaw = userData['ward'];
      final newWardName = _wardNameFrom(wardRaw) ?? (selectedWard ?? '');

      // Update Firebase display name
      await FirebaseAuth.instance.currentUser?.updateDisplayName(name);

      // Update FCM subscription if ward changed
      try {
        final fcmService = FCMService();

        if (oldWardName != null && oldWardName.isNotEmpty && oldWardName != newWardName) {
          await fcmService.unsubscribeFromWard(oldWardName);
        }
        if (newWardName.isNotEmpty && oldWardName != newWardName) {
          await fcmService.subscribeToWard(newWardName);
        }
      } catch (e) {
        debugPrint("FCM subscription error (non-fatal): $e");
      }

      _showSnackBar("Profile saved successfully!", isError: false);

      _originalWard = newWardName;

      await Future.delayed(const Duration(milliseconds: 250));
      if (!mounted) return;

      AppNavigation.offAll(
        context,
        AppRoutes.home,
        arguments: {
          'role': userData['role'] ?? 'RESIDENT',
          'userName': userData['name'] ?? name,
          'phone': userData['phone'] ?? phone,
          'email': userData['email'] ?? _emailController.text.trim(),
          'ward': wardRaw ?? newWardName,
        },
      );
    } catch (e) {
      debugPrint("Save error: $e");
      _showSnackBar("Network error: $e", isError: true);
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  Future<void> _logout() async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text("Logout", style: GoogleFonts.poppins(fontWeight: FontWeight.bold)),
        content: Text("Are you sure you want to logout?", style: GoogleFonts.poppins()),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text("Cancel", style: GoogleFonts.poppins(color: Colors.grey)),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: Text("Logout", style: GoogleFonts.poppins(color: Colors.red)),
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
      } catch (e) {
        debugPrint("FCM unsubscribe error: $e");
      }

      await FirebaseAuth.instance.signOut();

      if (!mounted) return;
      AppNavigation.offAll(context, AppRoutes.login);
    } catch (e) {
      _showSnackBar("Logout failed: $e", isError: true);
    }
  }

  void _showSnackBar(String message, {bool isError = false}) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: isError ? Colors.red : Colors.green,
        behavior: SnackBarBehavior.floating,
        margin: const EdgeInsets.all(16),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final displayName =
    _nameController.text.trim().isNotEmpty ? _nameController.text.trim() : widget.userName;

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
          "My Profile",
          style: GoogleFonts.poppins(fontSize: 20, fontWeight: FontWeight.w600, color: Colors.black),
        ),
        actions: [
          _isSaving
              ? const Padding(
            padding: EdgeInsets.all(16.0),
            child: SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2)),
          )
              : TextButton(
            onPressed: _saveProfile,
            child: Text("Save", style: GoogleFonts.poppins(color: Colors.blue, fontWeight: FontWeight.w600)),
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
            children: [
              // Header
              Column(
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
                          style: GoogleFonts.poppins(
                            fontSize: 40,
                            fontWeight: FontWeight.bold,
                            color: Colors.blue,
                          ),
                        )
                            : null,
                      ),

                      // Change photo
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
                    "$_roleLabel • ${selectedWard ?? "No ward selected"}",
                    style: GoogleFonts.poppins(fontSize: 14, color: Colors.grey[600]),
                  ),
                ],
              ),

              const SizedBox(height: 24),

              // Stats
              Row(
                children: [
                  Expanded(child: _buildStatCard("${_bookings.length}", "Bookings", Colors.blue[50]!)),
                  const SizedBox(width: 12),
                  Expanded(child: _buildStatCard("${_issues.length}", "Reports", Colors.orange[50]!)),
                ],
              ),

              const SizedBox(height: 32),

              _buildSection(
                title: "Personal Details",
                child: Column(
                  children: [
                    _buildEditableField(label: "FULL NAME", controller: _nameController, icon: Icons.person),
                    const SizedBox(height: 16),
                    _buildEditableField(label: "PHONE NUMBER", controller: _phoneController, icon: Icons.phone),
                    const SizedBox(height: 16),
                    _buildEditableField(label: "EMAIL", controller: _emailController, icon: Icons.email, enabled: false),
                    const SizedBox(height: 16),
                    _buildWardSelector(),
                  ],
                ),
              ),

              const SizedBox(height: 32),

              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text("Recent Activity", style: GoogleFonts.poppins(fontSize: 18, fontWeight: FontWeight.w600)),
                  TextButton(
                    onPressed: () {
                      // "See all" for bookings history screen
                      if (selectedTab == 0) {
                        Navigator.push(
                          context,
                          MaterialPageRoute(builder: (_) => const MyBookingsHistoryScreen()),
                        );
                      } else {
                        // Optional: if you later create complaints history screen, navigate there.
                        _showSnackBar("Complaints history screen not added yet", isError: false);
                      }
                    },
                    child: Text("See all", style: GoogleFonts.poppins(color: Colors.blue, fontWeight: FontWeight.w600)),
                  ),
                ],
              ),
              const SizedBox(height: 12),

              Container(
                decoration: BoxDecoration(color: Colors.grey[200], borderRadius: BorderRadius.circular(30)),
                child: Row(
                  children: [
                    Expanded(child: _buildActivityTab("Bookings", 0)),
                    Expanded(child: _buildActivityTab("Complaints", 1)),
                  ],
                ),
              ),
              const SizedBox(height: 16),

              if (selectedTab == 0) ...[
                if (_bookings.isEmpty)
                  _emptyCard("No bookings yet")
                else
                  ..._bookings.map(
                        (b) => Padding(
                      padding: const EdgeInsets.only(bottom: 12),
                      child: _buildActivityItem(
                        icon: Icons.local_shipping,
                        title: "Booking #${b.id}",
                        subtitle:
                        "${b.routeLocation ?? "-"} • ${_formatTimeRange(b.slotStartTime, b.slotEndTime)} • ${_formatDate(b.createdAt)}",
                        status: b.status,
                        statusColor: _bookingStatusColor(b.status),

                        // OPEN Booking Detail
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(builder: (_) => BookingDetailScreen(bookingId: b.id)),
                          );
                        },
                      ),
                    ),
                  ),
              ] else ...[
                if (_issues.isEmpty)
                  _emptyCard("No complaints yet")
                else
                  ..._issues.map(
                        (i) => Padding(
                      padding: const EdgeInsets.only(bottom: 12),
                      child: _buildActivityItem(
                        icon: Icons.warning,
                        title: i.title,
                        subtitle: "Complaint #${i.id} • ${_formatDate(i.createdAt)}",
                        status: i.status,
                        statusColor: _issueStatusColor(i.status),

                        // OPEN Complaint Detail
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(builder: (_) => ComplaintDetailScreen(complaintId: i.id)),
                          );
                        },
                      ),
                    ),
                  ),
              ],

              const SizedBox(height: 32),

              SizedBox(
                width: double.infinity,
                child: OutlinedButton.icon(
                  onPressed: _logout,
                  icon: const Icon(Icons.logout, color: Colors.red),
                  label: Text(
                    "Logout",
                    style: GoogleFonts.poppins(color: Colors.red, fontWeight: FontWeight.w600),
                  ),
                  style: OutlinedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    side: const BorderSide(color: Colors.red),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                ),
              ),

              const SizedBox(height: 100),
            ],
          ),
        ),
      ),
    );
  }

  // UI helpers

  Widget _emptyCard(String text) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10, offset: const Offset(0, 4))],
      ),
      child: Text(text, style: GoogleFonts.poppins(color: Colors.grey[700])),
    );
  }

  Widget _buildStatCard(String value, String label, Color color) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(color: color, borderRadius: BorderRadius.circular(16)),
      child: Column(
        children: [
          Text(value, style: GoogleFonts.poppins(fontSize: 28, fontWeight: FontWeight.bold)),
          Text(label, style: GoogleFonts.poppins(fontSize: 12, color: Colors.grey[700])),
        ],
      ),
    );
  }

  Widget _buildSection({required String title, required Widget child}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(title, style: GoogleFonts.poppins(fontSize: 18, fontWeight: FontWeight.w600)),
        const SizedBox(height: 12),
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10, offset: const Offset(0, 4))],
          ),
          child: child,
        ),
      ],
    );
  }

  Widget _buildEditableField({
    required String label,
    required TextEditingController controller,
    required IconData icon,
    bool enabled = true,
  }) {
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

  Widget _buildWardSelector() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text("WARD", style: GoogleFonts.poppins(fontSize: 12, color: Colors.grey[600])),
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
                        "Select Your Ward",
                        style: GoogleFonts.poppins(fontSize: 18, fontWeight: FontWeight.bold),
                      ),
                    ),
                    Expanded(
                      child: ListView.builder(
                        controller: scrollController,
                        itemCount: wards.length,
                        itemBuilder: (context, index) => ListTile(
                          title: Text(wards[index], style: GoogleFonts.poppins()),
                          trailing: selectedWard == wards[index] ? const Icon(Icons.check_circle, color: Colors.blue) : null,
                          onTap: () => Navigator.pop(context, wards[index]),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            );

            if (picked != null) {
              setState(() => selectedWard = picked);
            }
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
                  child: Text(
                    selectedWard ?? "Select your ward",
                    style: GoogleFonts.poppins(
                      fontSize: 16,
                      color: selectedWard != null ? Colors.black : Colors.grey,
                    ),
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
        if (selectedWard != null && selectedWard != _originalWard)
          Padding(
            padding: const EdgeInsets.only(top: 8),
            child: Text(
              "Tap 'Save' to update your ward",
              style: GoogleFonts.poppins(fontSize: 12, color: Colors.orange[700]),
            ),
          ),
      ],
    );
  }

  Widget _buildActivityTab(String title, int index) {
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

  Widget _buildActivityItem({
    required IconData icon,
    required String title,
    required String subtitle,
    required String status,
    required Color statusColor,
    required VoidCallback onTap,
  }) {
    final Color lightBg = statusColor.withOpacity(0.1);
    final Color darkText = statusColor;

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
                style: GoogleFonts.poppins(fontSize: 10, fontWeight: FontWeight.w600, color: darkText),
              ),
            ),
          ],
        ),
      ),
    );
  }
}