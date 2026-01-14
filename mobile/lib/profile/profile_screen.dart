import 'dart:convert';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:http/http.dart' as http;
import 'package:intl/intl.dart';

import '../../core/routes/app_navigation.dart';
import '../../core/routes/routes.dart';
import 'package:fyp/notifications/fcm_service.dart';

class SavedLocationModel {
  final int id;
  final String title;
  final String address;
  final bool isDefault;

  SavedLocationModel({
    required this.id,
    required this.title,
    required this.address,
    required this.isDefault,
  });

  factory SavedLocationModel.fromJson(Map<String, dynamic> json) {
    return SavedLocationModel(
      id: json['id'],
      title: (json['title'] ?? '').toString(),
      address: (json['address'] ?? '').toString(),
      isDefault: json['isDefault'] == true,
    );
  }
}

class BookingModel {
  final int id;
  final String status;
  final int? liters;
  final double? price;
  final DateTime createdAt;

  BookingModel({
    required this.id,
    required this.status,
    required this.createdAt,
    this.liters,
    this.price,
  });

  factory BookingModel.fromJson(Map<String, dynamic> json) {
    return BookingModel(
      id: json['id'],
      status: (json['status'] ?? 'PENDING').toString(),
      liters: json['liters'],
      price: json['price'] == null ? null : (json['price'] as num).toDouble(),
      createdAt: DateTime.parse(json['createdAt']),
    );
  }
}

class IssueModel {
  final int id;
  final String title;
  final String status;
  final DateTime createdAt;

  IssueModel({
    required this.id,
    required this.title,
    required this.status,
    required this.createdAt,
  });

  factory IssueModel.fromJson(Map<String, dynamic> json) {
    return IssueModel(
      id: json['id'],
      title: (json['title'] ?? '').toString(),
      status: (json['status'] ?? 'OPEN').toString(),
      createdAt: DateTime.parse(json['createdAt']),
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

  int selectedTab = 0; // 0 = Bookings, 1 = Issues Reported

  bool _isSaving = false;
  bool _loadingProfile = true;

  String? selectedWard;
  String? _originalWard; // ward loaded from backend (to unsubscribe properly)

  late TextEditingController _nameController;
  late TextEditingController _phoneController;
  late TextEditingController _emailController;

  List<SavedLocationModel> _locations = [];
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

  Color _bookingStatusColor(String status) {
    final s = status.toUpperCase();
    if (s == "DELIVERED") return Colors.green;
    if (s == "CONFIRMED") return Colors.blue;
    if (s == "CANCELLED") return Colors.red;
    return Colors.orange; // PENDING / default
  }

  Color _issueStatusColor(String status) {
    final s = status.toUpperCase();
    if (s == "RESOLVED") return Colors.green;
    if (s == "IN_REVIEW") return Colors.blue;
    return Colors.orange; // OPEN / default
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

      final newWard = (user['ward'] as String?);

      setState(() {
        _nameController.text = (user['name'] ?? '').toString();
        _phoneController.text = (user['phone'] ?? '').toString();
        _emailController.text = (user['email'] ?? '').toString();

        selectedWard = newWard;
        _originalWard = newWard;

        _locations = ((data['locations'] ?? []) as List)
            .map((e) => SavedLocationModel.fromJson(e as Map<String, dynamic>))
            .toList();

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

      final oldWard = _originalWard;

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

      final String newWard = (userData['ward'] ?? selectedWard ?? '').toString();

      // Update FCM subscription if ward changed
      try {
        final fcmService = FCMService();

        if (oldWard != null && oldWard.isNotEmpty && oldWard != newWard) {
          await fcmService.unsubscribeFromWard(oldWard);
        }
        if (newWard.isNotEmpty && oldWard != newWard) {
          await fcmService.subscribeToWard(newWard);
        }
      } catch (e) {
        debugPrint("FCM subscription error (non-fatal): $e");
      }

      _showSnackBar("Profile saved successfully!", isError: false);

      // Refresh local screen data too
      _originalWard = newWard;

      // Navigate back to home with updated data
      await Future.delayed(const Duration(milliseconds: 250));
      if (!mounted) return;

      AppNavigation.offAll(
        context,
        AppRoutes.home,
        arguments: {
          'role': userData['role'] ?? 'Resident',
          'userName': userData['name'] ?? name,
          'phone': userData['phone'] ?? phone,
          'email': userData['email'] ?? _emailController.text.trim(),
          'ward': newWard,
        },
      );
    } catch (e) {
      debugPrint("Save error: $e");
      _showSnackBar("Network error: $e", isError: true);
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  Future<void> _openLocationForm({SavedLocationModel? existing}) async {
    final titleC = TextEditingController(text: existing?.title ?? "");
    final addressC = TextEditingController(text: existing?.address ?? "");

    final ok = await showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
        final bottom = MediaQuery.of(context).viewInsets.bottom;
        return Padding(
          padding: EdgeInsets.only(left: 16, right: 16, top: 16, bottom: bottom + 16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                existing == null ? "Add New Location" : "Edit Location",
                style: GoogleFonts.poppins(fontSize: 18, fontWeight: FontWeight.w600),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: titleC,
                decoration: const InputDecoration(labelText: "Title (Home/Office/etc)"),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: addressC,
                maxLines: 3,
                decoration: const InputDecoration(labelText: "Address"),
              ),
              const SizedBox(height: 16),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () {
                    if (titleC.text.trim().isEmpty || addressC.text.trim().isEmpty) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text("Please enter title and address")),
                      );
                      return;
                    }
                    Navigator.pop(context, true);
                  },
                  child: const Text("Save"),
                ),
              ),
            ],
          ),
        );
      },
    );

    if (ok != true) return;

    try {
      final idToken = await _getFirebaseToken();
      if (idToken == null) throw Exception("Not authenticated");

      if (existing == null) {
        final res = await http.post(
          Uri.parse("$_baseUrl/profile/locations"),
          headers: {
            'Authorization': 'Bearer $idToken',
            'Content-Type': 'application/json',
          },
          body: jsonEncode({'title': titleC.text.trim(), 'address': addressC.text.trim()}),
        );

        if (res.statusCode != 201 && res.statusCode != 200) {
          throw Exception("Failed to add location (${res.statusCode})");
        }
      } else {
        final res = await http.patch(
          Uri.parse("$_baseUrl/profile/locations/${existing.id}"),
          headers: {
            'Authorization': 'Bearer $idToken',
            'Content-Type': 'application/json',
          },
          body: jsonEncode({'title': titleC.text.trim(), 'address': addressC.text.trim()}),
        );

        if (res.statusCode != 200) {
          throw Exception("Failed to update location (${res.statusCode})");
        }
      }

      await _loadProfile();
    } catch (e) {
      debugPrint("Location save error: $e");
      _showSnackBar("Failed to save location: $e", isError: true);
    }
  }

  Future<void> _deleteLocation(int id) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text("Delete location", style: GoogleFonts.poppins(fontWeight: FontWeight.w600)),
        content: Text("Are you sure you want to delete this location?", style: GoogleFonts.poppins()),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: Text("Cancel", style: GoogleFonts.poppins())),
          TextButton(
              onPressed: () => Navigator.pop(context, true),
              child: Text("Delete", style: GoogleFonts.poppins(color: Colors.red))),
        ],
      ),
    );

    if (confirm != true) return;

    try {
      final idToken = await _getFirebaseToken();
      if (idToken == null) throw Exception("Not authenticated");

      final res = await http.delete(
        Uri.parse("$_baseUrl/profile/locations/$id"),
        headers: {'Authorization': 'Bearer $idToken'},
      );

      if (res.statusCode != 200) {
        throw Exception("Failed to delete (${res.statusCode})");
      }

      await _loadProfile();
    } catch (e) {
      debugPrint("Delete location error: $e");
      _showSnackBar("Failed to delete location: $e", isError: true);
    }
  }

  Future<void> _setDefaultLocation(int id) async {
    try {
      final idToken = await _getFirebaseToken();
      if (idToken == null) throw Exception("Not authenticated");

      final res = await http.patch(
        Uri.parse("$_baseUrl/profile/locations/$id/default"),
        headers: {'Authorization': 'Bearer $idToken'},
      );

      if (res.statusCode != 200) {
        throw Exception("Failed to set default (${res.statusCode})");
      }

      await _loadProfile();
    } catch (e) {
      debugPrint("Set default error: $e");
      _showSnackBar("Failed to set default: $e", isError: true);
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
      // Unsubscribe from ward topic
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
    final displayName = _nameController.text.trim().isNotEmpty ? _nameController.text.trim() : widget.userName;

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
              // Profile Header
              Column(
                children: [
                  Stack(
                    children: [
                      CircleAvatar(
                        radius: 50,
                        backgroundColor: Colors.blue[100],
                        child: Text(
                          displayName.isNotEmpty ? displayName[0].toUpperCase() : "U",
                          style: GoogleFonts.poppins(
                            fontSize: 40,
                            fontWeight: FontWeight.bold,
                            color: Colors.blue,
                          ),
                        ),
                      ),
                      Positioned(
                        bottom: 0,
                        right: 0,
                        child: CircleAvatar(
                          radius: 18,
                          backgroundColor: Colors.blue,
                          child: const Icon(Icons.camera_alt, color: Colors.white, size: 18),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Text(
                    displayName,
                    style: GoogleFonts.poppins(fontSize: 22, fontWeight: FontWeight.bold),
                  ),
                  Text(
                    "Resident • ${selectedWard ?? "No ward selected"}",
                    style: GoogleFonts.poppins(fontSize: 14, color: Colors.grey[600]),
                  ),
                ],
              ),

              const SizedBox(height: 24),

              // Stats Row (dynamic counts from DB)
              Row(
                children: [
                  Expanded(child: _buildStatCard("${_bookings.length}", "Bookings", Colors.blue[50]!)),
                  const SizedBox(width: 12),
                  Expanded(child: _buildStatCard("${_issues.length}", "Reports", Colors.orange[50]!)),
                ],
              ),

              const SizedBox(height: 32),

              // Personal Details
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

              // Saved Locations
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text("Saved Locations", style: GoogleFonts.poppins(fontSize: 18, fontWeight: FontWeight.w600)),
                  TextButton(
                    onPressed: () => _openLocationForm(),
                    child: Text("+ Add New", style: GoogleFonts.poppins(color: Colors.blue)),
                  ),
                ],
              ),
              const SizedBox(height: 12),

              if (_locations.isEmpty)
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(16),
                    boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10, offset: const Offset(0, 4))],
                  ),
                  child: Text("No saved locations yet", style: GoogleFonts.poppins(color: Colors.grey[700])),
                )
              else
                Column(
                  children: _locations.map((loc) {
                    return Padding(
                      padding: const EdgeInsets.only(bottom: 12),
                      child: _buildLocationCardDb(
                        title: loc.title,
                        address: loc.address,
                        isDefault: loc.isDefault,
                        onSetDefault: () => _setDefaultLocation(loc.id),
                        onEdit: () => _openLocationForm(existing: loc),
                        onDelete: () => _deleteLocation(loc.id),
                      ),
                    );
                  }).toList(),
                ),

              const SizedBox(height: 32),

              // Recent Activity Tabs
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text("Recent Activity", style: GoogleFonts.poppins(fontSize: 18, fontWeight: FontWeight.w600)),
                ],
              ),
              const SizedBox(height: 12),
              Container(
                decoration: BoxDecoration(color: Colors.grey[200], borderRadius: BorderRadius.circular(30)),
                child: Row(
                  children: [
                    Expanded(child: _buildActivityTab("Bookings", 0)),
                    Expanded(child: _buildActivityTab("Issues Reported", 1)),
                  ],
                ),
              ),
              const SizedBox(height: 16),

              // Activity Items (from DB)
              if (selectedTab == 0) ...[
                if (_bookings.isEmpty)
                  _emptyCard("No bookings yet")
                else
                  ..._bookings.map((b) => Padding(
                    padding: const EdgeInsets.only(bottom: 12),
                    child: _buildActivityItem(
                      icon: Icons.local_shipping,
                      title: "Booking #${b.id}",
                      subtitle:
                      "${b.liters ?? '-'} Liters • Rs ${b.price?.toStringAsFixed(0) ?? '-'} • ${_formatDate(b.createdAt)}",
                      status: b.status,
                      statusColor: _bookingStatusColor(b.status),
                      onTap: () {},
                    ),
                  )),
              ] else ...[
                if (_issues.isEmpty)
                  _emptyCard("No issues yet")
                else
                  ..._issues.map((i) => Padding(
                    padding: const EdgeInsets.only(bottom: 12),
                    child: _buildActivityItem(
                      icon: Icons.warning,
                      title: i.title,
                      subtitle: "Issue #${i.id} • ${_formatDate(i.createdAt)}",
                      status: i.status,
                      statusColor: _issueStatusColor(i.status),
                      onTap: () {},
                    ),
                  )),
              ],

              const SizedBox(height: 32),

              // Logout Button
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
      bottomNavigationBar: BottomNavigationBar(
        type: BottomNavigationBarType.fixed,
        selectedItemColor: Colors.blue,
        unselectedItemColor: Colors.grey,
        currentIndex: 4,
        onTap: (index) {
          if (index == 0) Navigator.pop(context);
        },
        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.home), label: "Home"),
          BottomNavigationBarItem(icon: Icon(Icons.schedule), label: "Schedule"),
          BottomNavigationBarItem(icon: Icon(Icons.add_circle), label: "Book"),
          BottomNavigationBarItem(icon: Icon(Icons.notifications), label: "Alerts"),
          BottomNavigationBarItem(icon: Icon(Icons.person), label: "Profile"),
        ],
      ),
    );
  }

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

  Widget _buildLocationCardDb({
    required String title,
    required String address,
    required bool isDefault,
    required VoidCallback onSetDefault,
    required VoidCallback onEdit,
    required VoidCallback onDelete,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10, offset: const Offset(0, 4))],
      ),
      child: Row(
        children: [
          const Icon(Icons.place, color: Colors.blue, size: 32),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Flexible(child: Text(title, style: GoogleFonts.poppins(fontWeight: FontWeight.w600))),
                    if (isDefault)
                      Container(
                        margin: const EdgeInsets.only(left: 8),
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(color: Colors.blue[50], borderRadius: BorderRadius.circular(12)),
                        child: Text("DEFAULT", style: GoogleFonts.poppins(fontSize: 10, color: Colors.blue)),
                      ),
                  ],
                ),
                const SizedBox(height: 4),
                Text(address, style: GoogleFonts.poppins(fontSize: 14, color: Colors.grey[600])),
                TextButton(
                  onPressed: onSetDefault,
                  child: Text("Set Default", style: GoogleFonts.poppins(color: Colors.blue)),
                ),
              ],
            ),
          ),
          PopupMenuButton<String>(
            onSelected: (v) {
              if (v == "edit") onEdit();
              if (v == "delete") onDelete();
            },
            itemBuilder: (_) => const [
              PopupMenuItem(value: "edit", child: Text("Edit")),
              PopupMenuItem(value: "delete", child: Text("Delete")),
            ],
          ),
        ],
      ),
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