import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:http/http.dart' as http;
import '../../core/routes/app_navigation.dart';
import '../../core/routes/routes.dart';
import 'package:fyp/models/notification_model.dart';
import 'package:fyp/notifications/notification_service.dart';
import 'package:fyp/booking/tanker_service.dart';


class ResidentDashboardScreen extends StatefulWidget {
  final String userName;
  final String phone;
  final String email;


  final dynamic ward;

  const ResidentDashboardScreen({
    super.key,
    required this.userName,
    required this.phone,
    required this.email,
    this.ward,
  });

  @override
  State<ResidentDashboardScreen> createState() => _ResidentDashboardScreenState();
}

class _ResidentDashboardScreenState extends State<ResidentDashboardScreen> {
  static const String _baseUrl = "http://10.0.2.2:3000";


  static const Color bg = Color(0xFFF5F5F5);
  static const Color primaryBlue = Color(0xFF2196F3);
  static const Color primaryBlue2 = Color(0xFF42A5F5);
  static const Color accentBlue = Color(0xFF1976D2);

  static const Color greenTagBg = Color(0xFFE8F5E9);
  static const Color greenTagText = Color(0xFF2E7D32);

  static const Color normalFlowBg = Color(0xFFC8E6C9);
  static const Color normalFlowText = Color(0xFF388E3C);

  static const Color cardWhite = Colors.white;
  static const Color textPrimary = Color(0xFF212121);
  static const Color textSecondary = Color(0xFF757575);

  int _navIndex = 0;

  List<AppNotification> notifications = [];
  bool loadingReports = true;
  List<Map<String, dynamic>> myReports = [];
  bool loadingNearby = true;
  List<Map<String, dynamic>> nearbyTankers = [];


  // Ward helpers

  String? _extractWardName(dynamic w) {
    if (w == null) return null;

    if (w is Map && w['name'] != null) return w['name'].toString();

    if (w is String) {
      final s = w.trim();
      final matchName = RegExp(r'name:\s*([^}]+)', caseSensitive: false).firstMatch(s);
      if (matchName != null) return matchName.group(1)?.trim();
      return s;
    }

    return w.toString();
  }

  String get wardName => _extractWardName(widget.ward) ?? '';

  String get prettyWardText {
    final name = wardName.trim();
    if (name.isEmpty) return "Ward not set";

    final match = RegExp(r'^(.*)\s+Ward\s*(\d+)$', caseSensitive: false).firstMatch(name);
    if (match != null) {
      final city = match.group(1)!.trim();
      final number = match.group(2)!.trim();
      return "$city, Ward $number";
    }
    return name;
  }


  // API

  Future<void> fetchNotifications() async {
    try {
      final data = await NotificationService.getNotifications();
      if (!mounted) return;
      setState(() => notifications = data);
    } catch (_) {}
  }

  Future<void> fetchMyReports() async {
    setState(() => loadingReports = true);
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) throw Exception("Not logged in");
      final token = await user.getIdToken();

      final res = await http.get(
        Uri.parse("$_baseUrl/profile/me"),
        headers: {'Authorization': 'Bearer $token'},
      );

      if (res.statusCode != 200) {
        throw Exception("Failed to load profile (${res.statusCode})");
      }

      final data = jsonDecode(res.body) as Map<String, dynamic>;
      final issues = (data['issues'] as List? ?? []).cast<dynamic>();
      final mapped = issues.map((e) => Map<String, dynamic>.from(e as Map)).toList();

      if (!mounted) return;
      setState(() {
        myReports = mapped;
        loadingReports = false;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() => loadingReports = false);
    }
  }

  Future<void> fetchNearbyTankers() async {
    if (!mounted) return;
    setState(() => loadingNearby = true);

    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) throw Exception("Not logged in");

      final String? token = await user.getIdToken(true);
      if (token == null || token.trim().isEmpty) {
        throw Exception("Failed to get token");
      }

      final data = await TankerService.getNearbyTankers(
        token: token,
        filter: "available_now", // ✅ only vendors with available slots
      );

      if (!mounted) return;
      setState(() {
        nearbyTankers = data;
        loadingNearby = false;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        nearbyTankers = [];
        loadingNearby = false;
      });
    }
  }

  @override
  void initState() {
    super.initState();
    fetchNotifications();
    fetchMyReports();
    fetchNearbyTankers();
  }


  // UI helpers

  Widget pngIcon(
      String asset, {
        double size = 22,
        Color? tint,
      }) {
    return Image.asset(
      asset,
      height: size,
      width: size,
      color: tint,
      fit: BoxFit.contain,
      errorBuilder: (_, __, ___) => Icon(
        Icons.image_not_supported,
        size: size,
        color: tint ?? Colors.grey,
      ),
    );
  }

  BoxDecoration _softCard() {
    return BoxDecoration(
      color: cardWhite,
      borderRadius: BorderRadius.circular(20),
      boxShadow: [
        BoxShadow(
          color: Colors.black.withOpacity(0.06),
          blurRadius: 14,
          offset: const Offset(0, 6),
        )
      ],
    );
  }

  String _formatDateLabel(DateTime dt) {
    return DateFormat('MMM d, yyyy').format(dt.toLocal());
  }

  String _formatTimeLabel(DateTime dt) {
    return DateFormat('h:mm a').format(dt.toLocal());
  }

  String _relativeDay(DateTime dt) {
    final now = DateTime.now();
    final d = dt.toLocal();
    final today = DateTime(now.year, now.month, now.day);
    final dateOnly = DateTime(d.year, d.month, d.day);
    final diff = dateOnly.difference(today).inDays;
    if (diff == 0) return "Today";
    if (diff == -1) return "Yesterday";
    return DateFormat('MMM d').format(d);
  }

  void _openProfile() {
    AppNavigation.push(
      context,
      AppRoutes.profile,
      arguments: {
        'userName': widget.userName,
        'phone': widget.phone,
        'email': widget.email,
        'ward': widget.ward,
      },
    );
  }

  void _openBookings() {

    AppNavigation.push(context, AppRoutes.findTankers);
  }

  void _openReportIssue() {

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text("Open Report Issue")),
    );
  }


  // Build

  @override
  Widget build(BuildContext context) {
    final now = DateTime.now();
    final currentTime = _formatTimeLabel(now);
    final currentDate = _formatDateLabel(now);

    return Scaffold(
      backgroundColor: bg,
      floatingActionButton: FloatingActionButton(
        backgroundColor: primaryBlue,
        onPressed: _openBookings,
        child: Icon(Icons.local_shipping, color: Colors.white, size: 26),
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerDocked,
      bottomNavigationBar: _buildBottomBar(),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Container(
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(22),
            ),
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(18),
              physics: const AlwaysScrollableScrollPhysics(),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Header
                  Row(
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              "Namaste, ${widget.userName}",
                              style: GoogleFonts.poppins(
                                fontSize: 15,
                                color: const Color(0xFF60708F),
                                fontWeight: FontWeight.w500,
                              ),
                              overflow: TextOverflow.ellipsis,
                            ),
                            const SizedBox(height: 6),
                            Row(
                              children: [
                                Icon(Icons.location_on, size: 18, color: accentBlue),
                                const SizedBox(width: 6),
                                Expanded(
                                  child: Text(
                                    prettyWardText,
                                    style: GoogleFonts.poppins(
                                      fontSize: 20,
                                      fontWeight: FontWeight.w700,
                                      color: textPrimary,
                                    ),
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                      Stack(
                        children: [
                          Container(
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(16),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withOpacity(0.06),
                                  blurRadius: 12,
                                  offset: const Offset(0, 6),
                                )
                              ],
                            ),
                            child: IconButton(
                              onPressed: () {
                                showModalBottomSheet(
                                  context: context,
                                  isScrollControlled: true,
                                  shape: const RoundedRectangleBorder(
                                    borderRadius: BorderRadius.vertical(top: Radius.circular(18)),
                                  ),
                                  builder: (_) => _NotificationSheet(notifications: notifications),
                                );
                              },
                              icon: const Icon(Icons.notifications_none, size: 26),
                            ),
                          ),
                          if (notifications.isNotEmpty)
                            Positioned(
                              right: 12,
                              top: 12,
                              child: Container(
                                width: 10,
                                height: 10,
                                decoration: const BoxDecoration(
                                  color: Color(0xFFF44336),
                                  shape: BoxShape.circle,
                                ),
                              ),
                            ),
                        ],
                      ),
                    ],
                  ),

                  const SizedBox(height: 18),

                  // Today's Supply row
                  Row(
                    children: [
                      Text(
                        "Today's Supply",
                        style: GoogleFonts.poppins(
                          fontSize: 18,
                          fontWeight: FontWeight.w700,
                          color: textPrimary,
                        ),
                      ),
                      const SizedBox(width: 10),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
                        decoration: BoxDecoration(
                          color: greenTagBg,
                          borderRadius: BorderRadius.circular(22),
                        ),
                        child: Text(
                          "On Schedule",
                          style: GoogleFonts.poppins(
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                            color: greenTagText,
                          ),
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 14),

                  // Next Supply gradient card
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(18),
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                        colors: [primaryBlue, primaryBlue2],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      borderRadius: BorderRadius.circular(24),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              "Next Supply",
                              style: GoogleFonts.poppins(
                                fontSize: 14,
                                color: Colors.white.withOpacity(0.85),
                              ),
                            ),
                            Container(
                              height: 42,
                              width: 42,
                              decoration: BoxDecoration(
                                color: Colors.white.withOpacity(0.22),
                                shape: BoxShape.circle,
                              ),
                              child: Center(
                                child: pngIcon(
                                  'assets/icons/drop.png',
                                  size: 18,
                                  tint: Colors.white,
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 10),
                        Text(
                          currentTime,
                          style: GoogleFonts.poppins(
                            fontSize: 38,
                            fontWeight: FontWeight.w700,
                            color: Colors.white,
                          ),
                        ),
                        const SizedBox(height: 6),
                        Text(
                          "Expected duration: 2 hours",
                          style: GoogleFonts.poppins(
                            fontSize: 13,
                            color: Colors.white.withOpacity(0.85),
                          ),
                        ),
                        const SizedBox(height: 14),
                        Divider(color: Colors.white.withOpacity(0.25)),
                        const SizedBox(height: 10),
                        Row(
                          children: [
                            pngIcon('assets/icons/calendar.png', size: 18, tint: Colors.white),
                            const SizedBox(width: 10),
                            Text(
                              currentDate,
                              style: GoogleFonts.poppins(
                                color: Colors.white.withOpacity(0.9),
                                fontSize: 13,
                              ),
                            ),
                            const Spacer(),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                              decoration: BoxDecoration(
                                color: normalFlowBg,
                                borderRadius: BorderRadius.circular(22),
                              ),
                              child: Row(
                                children: [
                                  Container(
                                    width: 7,
                                    height: 7,
                                    decoration: const BoxDecoration(
                                      color: Color(0xFF4CAF50),
                                      shape: BoxShape.circle,
                                    ),
                                  ),
                                  const SizedBox(width: 8),
                                  Text(
                                    "Normal Flow",
                                    style: GoogleFonts.poppins(
                                      fontSize: 12,
                                      fontWeight: FontWeight.w600,
                                      color: normalFlowText,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        )
                      ],
                    ),
                  ),

                  const SizedBox(height: 18),

                  // Quick Actions: Book Tanker + Report Issue
                  Row(
                    children: [
                      Expanded(
                        child: _actionCard(
                          icon: Icons.local_shipping,
                          title: "Book Tanker",
                          onTap: _openBookings,
                        ),
                      ),

                      const SizedBox(width: 14),
                      Expanded(
                        child: _actionCard(
                          icon: Icons.report_gmailerrorred,
                          title: "Report Issue",
                          onTap: _openReportIssue,
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 22),

                  // Nearby tankers
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        "Nearby Tankers",
                        style: GoogleFonts.poppins(
                          fontSize: 18,
                          fontWeight: FontWeight.w700,
                          color: textPrimary,
                        ),
                      ),
                      TextButton(
                        onPressed: _openBookings, // ✅ open Find Tankers screen
                        child: Text(
                          "View All",
                          style: GoogleFonts.poppins(
                            color: accentBlue,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      )
                    ],
                  ),

                  const SizedBox(height: 10),

                  if (loadingNearby)
                    const Center(
                      child: Padding(
                        padding: EdgeInsets.all(12),
                        child: CircularProgressIndicator(),
                      ),
                    )
                  else if (nearbyTankers.isEmpty)
                    Container(
                      decoration: _softCard(),
                      padding: const EdgeInsets.all(16),
                      child: Text(
                        "No tankers available right now",
                        style: GoogleFonts.poppins(color: textSecondary),
                      ),
                    )
                  else
                    Column(
                      children: nearbyTankers.take(2).map((t) {
                        final name = (t['name'] ?? 'Vendor').toString();
                        final status = (t['status'] ?? '').toString();

                        return Container(
                          width: double.infinity,
                          margin: const EdgeInsets.only(bottom: 12),
                          decoration: _softCard(),
                          padding: const EdgeInsets.all(14),
                          child: Row(
                            children: [
                              CircleAvatar(
                                radius: 18,
                                backgroundColor: Colors.blue[50],
                                child: const Icon(Icons.local_shipping, color: Color(0xFF1976D2)),
                              ),
                              const SizedBox(width: 10),
                              Expanded(
                                child: Text(
                                  name,
                                  style: GoogleFonts.poppins(fontWeight: FontWeight.w700),
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                              if (status.isNotEmpty)
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                                  decoration: BoxDecoration(
                                    color: const Color(0xFFE3F2FD),
                                    borderRadius: BorderRadius.circular(18),
                                  ),
                                  child: Text(
                                    status,
                                    style: GoogleFonts.poppins(
                                      fontSize: 11,
                                      fontWeight: FontWeight.w700,
                                      color: accentBlue,
                                    ),
                                  ),
                                ),
                            ],
                          ),
                        );
                      }).toList(),
                    ),

                  const SizedBox(height: 22),
                  // Your Reports
                  Text(
                    "Your Reports",
                    style: GoogleFonts.poppins(
                      fontSize: 18,
                      fontWeight: FontWeight.w700,
                      color: textPrimary,
                    ),
                  ),
                  const SizedBox(height: 10),

                  if (loadingReports)
                    const Center(
                      child: Padding(
                        padding: EdgeInsets.all(12),
                        child: CircularProgressIndicator(),
                      ),
                    )
                  else if (myReports.isEmpty)
                    Container(
                      decoration: _softCard(),
                      padding: const EdgeInsets.all(16),
                      child: Text(
                        "No reports yet",
                        style: GoogleFonts.poppins(color: textSecondary),
                      ),
                    )
                  else
                    _reportCard(myReports.first),

                  const SizedBox(height: 110),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  // Quick action card
  Widget _actionCard({
    required IconData icon,
    required String title,
    required VoidCallback onTap,
  }) {
    return InkWell(
      borderRadius: BorderRadius.circular(18),
      onTap: onTap,
      child: Container(
        decoration: _softCard(),
        padding: const EdgeInsets.symmetric(vertical: 18, horizontal: 12),
        child: Column(
          children: [
            Container(
              height: 46,
              width: 46,
              decoration: BoxDecoration(
                color: Colors.grey[100],
                shape: BoxShape.circle,
              ),
              child: Icon(icon, color: accentBlue),
            ),
            const SizedBox(height: 10),
            Text(
              title,
              style: GoogleFonts.poppins(fontWeight: FontWeight.w700),
            )
          ],
        ),
      ),
    );
  }

  //Nearby tanker card
  Widget _nearbyTankerCard({
    required String name,
    required String capacityText,
    required String priceText,
    required String slotsText,
  }) {
    return Container(
      decoration: _softCard(),
      padding: const EdgeInsets.all(14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // header
          Row(
            children: [
              CircleAvatar(
                radius: 18,
                backgroundColor: Colors.green[200],
                child: const Icon(Icons.water_drop, color: Colors.white),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  name,
                  style: GoogleFonts.poppins(fontWeight: FontWeight.w700),
                  overflow: TextOverflow.ellipsis,
                  maxLines: 1,
                ),
              ),
            ],
          ),

          const SizedBox(height: 8),

          //  Slots info
          Row(
            children: [
              Icon(Icons.event_seat, size: 14, color: Colors.grey[700]),
              const SizedBox(width: 6),
              Expanded(
                child: Text(
                  "$slotsText Slots",
                  style: GoogleFonts.poppins(fontSize: 12, color: textSecondary),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),

          const SizedBox(height: 10),

          // capacity + price row
          Row(
            children: [
              Flexible(
                flex: 6,
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                  decoration: BoxDecoration(
                    color: Colors.grey[100],
                    borderRadius: BorderRadius.circular(18),
                  ),
                  child: Text(
                    capacityText,
                    style: GoogleFonts.poppins(fontSize: 12),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Flexible(
                flex: 4,
                child: Align(
                  alignment: Alignment.centerRight,
                  child: FittedBox(
                    fit: BoxFit.scaleDown,
                    child: Text(
                      priceText,
                      style: GoogleFonts.poppins(
                        fontWeight: FontWeight.w700,
                        color: accentBlue,
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),

          const SizedBox(height: 12),


          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: _openBookings,
              style: ElevatedButton.styleFrom(
                elevation: 0,
                backgroundColor: const Color(0xFFE3F2FD),
                foregroundColor: accentBlue,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
              child: FittedBox(
                fit: BoxFit.scaleDown,
                child: Text(
                  "Book Now",
                  style: GoogleFonts.poppins(fontWeight: FontWeight.w700),
                ),
              ),
            ),
          )
        ],
      ),
    );
  }

  // Report card
  Widget _reportCard(Map<String, dynamic> r) {
    final id = r['id'];
    final title = (r['title'] ?? 'Issue').toString();
    final status = (r['status'] ?? 'IN_REVIEW').toString();
    final createdAt = DateTime.tryParse((r['createdAt'] ?? '').toString());

    final label = status.toUpperCase() == "IN_REVIEW" ? "In Review" : status;

    return Container(
      decoration: _softCard(),
      padding: const EdgeInsets.all(16),
      child: Row(
        children: [
          Container(
            height: 44,
            width: 44,
            decoration: const BoxDecoration(
              color: Color(0xFFFFF9C4),
              shape: BoxShape.circle,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: GoogleFonts.poppins(fontWeight: FontWeight.w700),
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 2),
                Text(
                  "Ticket #$id • ${createdAt != null ? _relativeDay(createdAt) : '-'}",
                  style: GoogleFonts.poppins(fontSize: 12, color: textSecondary),
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: const Color(0xFFE3F2FD),
              borderRadius: BorderRadius.circular(18),
            ),
            child: Text(
              label,
              style: GoogleFonts.poppins(
                fontSize: 12,
                fontWeight: FontWeight.w700,
                color: accentBlue,
              ),
            ),
          ),
        ],
      ),
    );
  }

  // Bottom bar
  Widget _buildBottomBar() {
    final inactive = Colors.grey[500]!;

    Widget item({
      required int index,
      required IconData icon,
      required String label,
      required VoidCallback onTap,
    }) {
      final isActive = _navIndex == index;
      final color = isActive ? primaryBlue : inactive;

      return Expanded(
        child: InkWell(
          onTap: () {
            setState(() => _navIndex = index);
            onTap();
          },
          child: Center(
            child: SizedBox(
              height: 36,
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(icon, color: color, size: 18),
                  const SizedBox(height: 2),
                  SizedBox(
                    height: 12,
                    child: FittedBox(
                      fit: BoxFit.scaleDown,
                      child: Text(
                        label,
                        style: GoogleFonts.poppins(fontSize: 10, color: color),
                      ),
                    ),
                  )
                ],
              ),
            ),
          ),
        ),
      );
    }

    return BottomAppBar(
      shape: const CircularNotchedRectangle(),
      notchMargin: 10,
      child: SizedBox(
        height: 78,
        child: Row(
          children: [
            item(index: 0, icon: Icons.home, label: 'Home', onTap: () {}),
            item(index: 1, icon: Icons.receipt_long, label: 'Bookings', onTap: _openBookings),
            const SizedBox(width: 60),
            item(index: 3, icon: Icons.chat_bubble_outline, label: 'Reports', onTap: _openReportIssue),
            item(index: 4, icon: Icons.person, label: 'Profile', onTap: _openProfile),
          ],
        ),
      ),
    );
  }
}

//Notification bottom sheet
class _NotificationSheet extends StatelessWidget {
  final List<AppNotification> notifications;

  const _NotificationSheet({required this.notifications});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 420,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 10, 16, 16),
        child: Column(
          children: [
            Container(
              height: 4,
              width: 44,
              decoration: BoxDecoration(
                color: Colors.grey[400],
                borderRadius: BorderRadius.circular(100),
              ),
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Text(
                  "Notifications",
                  style: GoogleFonts.poppins(fontSize: 16, fontWeight: FontWeight.w700),
                ),
                const Spacer(),
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: Text(
                    "Close",
                    style: GoogleFonts.poppins(color: const Color(0xFF1976D2)),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Expanded(
              child: notifications.isEmpty
                  ? Center(child: Text("No notifications", style: GoogleFonts.poppins()))
                  : ListView.separated(
                itemCount: notifications.length,
                separatorBuilder: (_, __) => const Divider(height: 10),
                itemBuilder: (context, index) {
                  final n = notifications[index];
                  return ListTile(
                    contentPadding: EdgeInsets.zero,
                    title: Text(n.title, style: GoogleFonts.poppins(fontWeight: FontWeight.w600)),
                    subtitle: Text(n.message, style: GoogleFonts.poppins(fontSize: 12)),
                    trailing: Text(
                      DateFormat('hh:mm a').format(n.createdAt.toLocal()),
                      style: GoogleFonts.poppins(fontSize: 11, color: Colors.grey[600]),
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}