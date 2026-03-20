import 'dart:async';
import 'dart:convert';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:http/http.dart' as http;

import 'package:fyp/core/routes/app_navigation.dart';
import 'package:fyp/core/routes/routes.dart';

class WardAdminDashboardScreen extends StatefulWidget {
  const WardAdminDashboardScreen({super.key});

  @override
  State<WardAdminDashboardScreen> createState() =>
      _WardAdminDashboardScreenState();
}

class _WardAdminDashboardScreenState extends State<WardAdminDashboardScreen> {
  int _selectedIndex = 0;

  // Dashboard state
  bool _loading = true;
  String _name = "Ward Admin";
  String _profileImageUrl = "";
  int? _myUserId;

  List<Map<String, dynamic>> _mySchedules = [];

  static const String baseUrl = "http://10.0.2.2:3000";

  StreamSubscription<User?>? _authSub;

  @override
  void initState() {
    super.initState();

    // ✅ If user logs out anywhere, immediately go to login and stop future loads.
    _authSub = FirebaseAuth.instance.authStateChanges().listen((user) {
      if (!mounted) return;
      if (user == null) {
        Navigator.of(
          context,
        ).pushNamedAndRemoveUntil(AppRoutes.login, (r) => false);
      }
    });

    _loadDashboard();
  }

  @override
  void dispose() {
    _authSub?.cancel();
    super.dispose();
  }

  Future<String> _requireToken() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) throw Exception("Not authenticated");

    final String? token = await user.getIdToken(true);
    if (token == null || token.trim().isEmpty)
      throw Exception("Failed to get Firebase token");
    return token;
  }

  Map<String, dynamic> _decodeJson(String body) {
    try {
      return jsonDecode(body) as Map<String, dynamic>;
    } catch (_) {
      return {};
    }
  }

  String _timeHHmm(DateTime dt) {
    final h = dt.hour.toString().padLeft(2, '0');
    final m = dt.minute.toString().padLeft(2, '0');
    return "$h:$m";
  }

  String _dateYMD(DateTime dt) {
    final y = dt.year.toString();
    final mo = dt.month.toString().padLeft(2, '0');
    final d = dt.day.toString().padLeft(2, '0');
    return "$y-$mo-$d";
  }

  Future<void> _loadDashboard() async {
    // ✅ If already logged out, don't load
    if (FirebaseAuth.instance.currentUser == null) return;

    if (mounted) setState(() => _loading = true);

    try {
      final token = await _requireToken();

      // 1) Fetch profile
      final profileRes = await http.get(
        Uri.parse("$baseUrl/admin/profile/me"),
        headers: {"Authorization": "Bearer $token"},
      );

      if (profileRes.statusCode != 200) {
        throw Exception(
          "Profile load failed: ${profileRes.statusCode} ${profileRes.body}",
        );
      }

      final profile = _decodeJson(profileRes.body);
      _myUserId = (profile["id"] as num?)?.toInt();
      _name = (profile["name"] ?? "Ward Admin").toString();
      _profileImageUrl = (profile["profileImageUrl"] ?? "").toString();

      // 2) Fetch schedules (then filter only mine)
      final schRes = await http.get(
        Uri.parse("$baseUrl/schedules"),
        headers: {"Authorization": "Bearer $token"},
      );

      if (schRes.statusCode != 200) {
        throw Exception(
          "Schedules load failed: ${schRes.statusCode} ${schRes.body}",
        );
      }

      final List<dynamic> all = jsonDecode(schRes.body) as List<dynamic>;

      final myId = _myUserId;
      final filtered = <Map<String, dynamic>>[];

      for (final item in all) {
        if (item is! Map) continue;
        final m = Map<String, dynamic>.from(item);

        // createdBy may be null for old records, so handle safely
        final createdBy = m["createdBy"];
        final createdById = (createdBy is Map) ? createdBy["id"] : null;

        if (myId != null &&
            createdById != null &&
            createdById.toString() == myId.toString()) {
          filtered.add(m);
        }
      }

      // sort newest first (scheduleDate desc)
      filtered.sort((a, b) {
        final ad =
            DateTime.tryParse((a["scheduleDate"] ?? "").toString()) ??
            DateTime.fromMillisecondsSinceEpoch(0);
        final bd =
            DateTime.tryParse((b["scheduleDate"] ?? "").toString()) ??
            DateTime.fromMillisecondsSinceEpoch(0);
        return bd.compareTo(ad);
      });

      if (!mounted) return;
      setState(() {
        _mySchedules = filtered;
      });
    } catch (e) {
      // ✅ If user logged out while loading, ignore error
      if (FirebaseAuth.instance.currentUser == null) return;

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text("Dashboard load failed: $e"),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  void _onBottomNavTap(int index) {
    setState(() => _selectedIndex = index);

    switch (index) {
      case 0:
        break;
      case 1:
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text("Opening Reports...")));
        break;
      case 2:
        AppNavigation.push(context, AppRoutes.newSchedule);
        break;
      case 3:
        Navigator.pushNamed(context, AppRoutes.wardAdminProfile).then((_) {
          // ✅ after coming back, refresh only if still logged in and still mounted
          if (!mounted) return;
          if (FirebaseAuth.instance.currentUser == null) return;
          _loadDashboard();
        });
        break;
    }
  }

  @override
  Widget build(BuildContext context) {
    final displayName = _name.trim().isEmpty ? "Ward Admin" : _name.trim();

    return Scaffold(
      backgroundColor: Colors.grey[50],
      body: SafeArea(
        child: _loading
            ? const Center(child: CircularProgressIndicator())
            : RefreshIndicator(
                onRefresh: _loadDashboard,
                child: SingleChildScrollView(
                  physics: const AlwaysScrollableScrollPhysics(),
                  padding: EdgeInsets.all(16.w),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Header
                      Row(
                        children: [
                          CircleAvatar(
                            radius: 28.w,
                            backgroundColor: Colors.blue[100],
                            backgroundImage: _profileImageUrl.isNotEmpty
                                ? NetworkImage(_profileImageUrl)
                                : null,
                            child: _profileImageUrl.isEmpty
                                ? Icon(
                                    Icons.person,
                                    size: 32.w,
                                    color: Colors.blue,
                                  )
                                : null,
                          ),
                          SizedBox(width: 12.w),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  displayName,
                                  style: GoogleFonts.poppins(
                                    fontSize: 18.sp,
                                    fontWeight: FontWeight.w700,
                                  ),
                                ),
                                Text(
                                  "Hamro Pani",
                                  style: GoogleFonts.poppins(
                                    fontSize: 14.sp,
                                    color: Colors.grey[600],
                                  ),
                                ),
                              ],
                            ),
                          ),
                          IconButton(
                            icon: Icon(
                              Icons.notifications_outlined,
                              size: 28.w,
                            ),
                            onPressed: () {
                              AppNavigation.push(
                                context,
                                AppRoutes.notifications,
                              );
                            },
                          ),
                        ],
                      ),

                      SizedBox(height: 24.h),

                      Text(
                        "Namaste, $displayName",
                        style: GoogleFonts.poppins(
                          fontSize: 26.sp,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      Text(
                        "Here is your recent overview.",
                        style: GoogleFonts.poppins(
                          fontSize: 16.sp,
                          color: Colors.grey[700],
                        ),
                      ),

                      SizedBox(height: 32.h),

                      // Supply Status Card
                      Container(
                        padding: EdgeInsets.all(20.w),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(20.r),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.05),
                              blurRadius: 10,
                              offset: Offset(0, 4.h),
                            ),
                          ],
                        ),
                        child: Column(
                          children: [
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text(
                                  "Supply Status",
                                  style: GoogleFonts.poppins(
                                    fontSize: 16.sp,
                                    fontWeight: FontWeight.w600,
                                    color: Colors.grey[600],
                                  ),
                                ),
                                Icon(
                                  Icons.water_drop,
                                  size: 40.w,
                                  color: Colors.blue,
                                ),
                              ],
                            ),
                            SizedBox(height: 16.h),
                            Text(
                              "Normal Flow",
                              style: GoogleFonts.poppins(
                                fontSize: 24.sp,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                            SizedBox(height: 8.h),
                            Row(
                              children: [
                                Icon(
                                  Icons.check_circle,
                                  color: Colors.green,
                                  size: 20.w,
                                ),
                                SizedBox(width: 8.w),
                                Text(
                                  "Active Distribution",
                                  style: GoogleFonts.poppins(
                                    color: Colors.green,
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),

                      SizedBox(height: 32.h),

                      // Quick Actions
                      Text(
                        "Quick Actions",
                        style: GoogleFonts.poppins(
                          fontSize: 18.sp,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      SizedBox(height: 16.h),

                      Row(
                        children: [
                          Expanded(
                            child: GestureDetector(
                              onTap: () => AppNavigation.push(
                                context,
                                AppRoutes.newSchedule,
                              ),
                              child: _buildQuickActionCard(
                                image: 'assets/images/post_schedule.png',
                                title: "Post Schedule",
                                subtitle: "Update timings",
                              ),
                            ),
                          ),
                          SizedBox(width: 16.w),
                          Expanded(
                            child: GestureDetector(
                              onTap: () => AppNavigation.push(
                                context,
                                AppRoutes.sendNotice,
                              ),
                              child: _buildQuickActionCard(
                                image: 'assets/images/se.webp',
                                title: "Send Notice",
                                subtitle: "Announce updates",
                              ),
                            ),
                          ),
                        ],
                      ),

                      SizedBox(height: 32.h),

                      // Recent Updates – only schedules posted by this admin
                      Text(
                        "Recent Updates (My Schedules)",
                        style: GoogleFonts.poppins(
                          fontSize: 18.sp,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      SizedBox(height: 12.h),

                      if (_mySchedules.isEmpty)
                        Container(
                          width: double.infinity,
                          padding: EdgeInsets.all(16.w),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(16.r),
                          ),
                          child: Text(
                            "No schedules posted by you yet.",
                            style: GoogleFonts.poppins(color: Colors.grey[700]),
                          ),
                        )
                      else
                        ..._mySchedules.take(5).map((s) {
                          final ward = s["ward"];
                          final wardName =
                              (ward is Map ? ward["wardName"] : null)
                                  ?.toString() ??
                              "Ward";

                          final scheduleDate = DateTime.tryParse(
                            (s["scheduleDate"] ?? "").toString(),
                          )?.toLocal();
                          final startTime = DateTime.tryParse(
                            (s["startTime"] ?? "").toString(),
                          )?.toLocal();
                          final endTime = DateTime.tryParse(
                            (s["endTime"] ?? "").toString(),
                          )?.toLocal();

                          final dateStr = scheduleDate != null
                              ? _dateYMD(scheduleDate)
                              : "—";
                          final timeStr = (startTime != null && endTime != null)
                              ? "${_timeHHmm(startTime)} - ${_timeHHmm(endTime)}"
                              : "—";

                          return Padding(
                            padding: EdgeInsets.only(bottom: 12.h),
                            child: _buildUpdateCard(
                              icon: Icons.calendar_today,
                              iconColor: Colors.blue,
                              title: "Schedule Posted – $wardName",
                              time: "$dateStr  |  $timeStr",
                              subtitle: "Posted by you",
                            ),
                          );
                        }),

                      SizedBox(height: 100.h),
                    ],
                  ),
                ),
              ),
      ),
      bottomNavigationBar: BottomNavigationBar(
        type: BottomNavigationBarType.fixed,
        selectedItemColor: Colors.blue,
        unselectedItemColor: Colors.grey,
        currentIndex: _selectedIndex,
        onTap: _onBottomNavTap,
        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.home), label: "Home"),
          BottomNavigationBarItem(icon: Icon(Icons.report), label: "Reports"),
          BottomNavigationBarItem(
            icon: Icon(Icons.calendar_month),
            label: "Schedules",
          ),
          BottomNavigationBarItem(icon: Icon(Icons.person), label: "Profile"),
        ],
      ),
    );
  }

  Widget _buildQuickActionCard({
    required String image,
    required String title,
    required String subtitle,
  }) {
    return Container(
      padding: EdgeInsets.all(16.w),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20.r),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: Offset(0, 4.h),
          ),
        ],
      ),
      child: Column(
        children: [
          Image.asset(image, height: 100.h, width: 100.w, fit: BoxFit.cover),
          SizedBox(height: 16.h),
          Text(
            title,
            style: GoogleFonts.poppins(fontWeight: FontWeight.w600),
            textAlign: TextAlign.center,
          ),
          Text(
            subtitle,
            style: GoogleFonts.poppins(fontSize: 12.sp, color: Colors.grey),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildUpdateCard({
    required IconData icon,
    required Color iconColor,
    required String title,
    required String time,
    required String subtitle,
  }) {
    return Container(
      padding: EdgeInsets.all(16.w),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16.r),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 8,
            offset: Offset(0, 2.h),
          ),
        ],
      ),
      child: Row(
        children: [
          Icon(icon, color: iconColor, size: 32.w),
          SizedBox(width: 16.w),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: GoogleFonts.poppins(fontWeight: FontWeight.w600),
                ),
                SizedBox(height: 4.h),
                Text(
                  time,
                  style: GoogleFonts.poppins(
                    fontSize: 12.sp,
                    color: Colors.grey[600],
                  ),
                ),
                SizedBox(height: 4.h),
                Text(
                  subtitle,
                  style: GoogleFonts.poppins(
                    fontSize: 13.sp,
                    color: Colors.grey[800],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
