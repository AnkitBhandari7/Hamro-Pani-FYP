import 'dart:async';
import 'dart:convert';

import 'package:cached_network_image/cached_network_image.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:http/http.dart' as http;

import 'package:fyp/core/routes/app_navigation.dart';
import 'package:fyp/core/routes/routes.dart';
import 'package:fyp/l10n/app_localizations.dart';

import 'package:fyp/features/shared/notifications/models/notification_model.dart';
import 'package:fyp/features/shared/notifications/services/notification_service.dart';
import 'package:fyp/features/ward_admin/complaints/reportscreen.dart';

class WardAdminDashboardScreen extends StatefulWidget {
  const WardAdminDashboardScreen({super.key});

  @override
  State<WardAdminDashboardScreen> createState() =>
      _WardAdminDashboardScreenState();
}

class _WardAdminDashboardScreenState extends State<WardAdminDashboardScreen> {
  int _selectedIndex = 0;

  bool _loading = true;
  String _name = "Ward Admin";
  String _profileImageUrl = "";
  int? _myUserId;

  List<Map<String, dynamic>> _mySchedules = [];

  List<AppNotification> _notifications = [];
  bool get _hasUnread => _notifications.any((n) => n.isUnread);

  static const String baseUrl = "http://10.0.2.2:3000";

  StreamSubscription<User?>? _authSub;

  @override
  void initState() {
    super.initState();
    _authSub = FirebaseAuth.instance.authStateChanges().listen((user) {
      if (!mounted) return;
      if (user == null) {
        Navigator.of(context)
            .pushNamedAndRemoveUntil(AppRoutes.login, (r) => false);
      }
    });
    _loadAll();
  }

  Future<void> _loadAll() async {
    await Future.wait([
      _loadDashboard(),
      _loadNotifications(),
    ]);
  }

  Future<void> _loadNotifications() async {
    try {
      final data = await NotificationService.getNotifications();
      if (!mounted) return;
      setState(() => _notifications = data);
    } catch (_) {}
  }

  @override
  void dispose() {
    _authSub?.cancel();
    super.dispose();
  }

  Future<String> _requireToken() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) throw Exception("Not authenticated");
    final token = await user.getIdToken(true);
    if (token == null || token.trim().isEmpty) {
      throw Exception("Failed to get Firebase token");
    }
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
    if (FirebaseAuth.instance.currentUser == null) return;
    if (mounted) setState(() => _loading = true);

    try {
      final token = await _requireToken();

      final profileRes = await http.get(
        Uri.parse("$baseUrl/admin/profile/me"),
        headers: {"Authorization": "Bearer $token"},
      );

      if (profileRes.statusCode != 200) {
        throw Exception(
            "Profile load failed: ${profileRes.statusCode} ${profileRes.body}");
      }

      final profile = _decodeJson(profileRes.body);
      _myUserId = (profile["id"] as num?)?.toInt();
      _name = (profile["name"] ?? "Ward Admin").toString();
      _profileImageUrl = (profile["profileImageUrl"] ?? "").toString();

      final schRes = await http.get(
        Uri.parse("$baseUrl/schedules"),
        headers: {"Authorization": "Bearer $token"},
      );

      if (schRes.statusCode != 200) {
        throw Exception(
            "Schedules load failed: ${schRes.statusCode} ${schRes.body}");
      }

      final List<dynamic> all = jsonDecode(schRes.body) as List<dynamic>;
      final myId = _myUserId;
      final filtered = <Map<String, dynamic>>[];

      for (final item in all) {
        if (item is! Map) continue;
        final m = Map<String, dynamic>.from(item);
        final createdBy = m["createdBy"];
        final createdById = (createdBy is Map) ? createdBy["id"] : null;

        if (myId != null &&
            createdById != null &&
            createdById.toString() == myId.toString()) {
          filtered.add(m);
        }
      }

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
      setState(() => _mySchedules = filtered);
    } catch (e) {
      if (FirebaseAuth.instance.currentUser == null) return;
      if (mounted) {
        final l10n = AppLocalizations.of(context);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(l10n != null
                ? l10n.dashboardLoadFailed(e.toString())
                : "Dashboard load failed: $e"),
            backgroundColor: const Color(0xFFEF4444),
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10)),
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  void _onBottomNavTap(int index) async {
    setState(() => _selectedIndex = index);

    switch (index) {
      case 0:
        break;
      case 1:
        await Navigator.push(
          context,
          MaterialPageRoute(
              builder: (_) => const WardAdminComplaintReportScreen()),
        );
        if (!mounted) return;
        setState(() => _selectedIndex = 0);
        await _loadAll();
        break;
      case 2:
        AppNavigation.push(context, AppRoutes.newSchedule);
        break;
      case 3:
        Navigator.pushNamed(context, AppRoutes.wardAdminProfile)
            .then((_) async {
          if (!mounted) return;
          if (FirebaseAuth.instance.currentUser == null) return;
          await _loadAll();
        });
        break;
    }
  }

  // ─── Schedule Details Sheet ────────────────
  void _openScheduleDetails(Map<String, dynamic> s) {
    final l10n = AppLocalizations.of(context)!;

    final ward = s["ward"];
    final wardName =
        (ward is Map ? ward["wardName"] : null)?.toString() ?? "—";
    final createdBy = s["createdBy"];
    final createdByName =
        (createdBy is Map ? createdBy["name"] : null)?.toString() ?? "—";
    final createdByEmail =
        (createdBy is Map ? createdBy["email"] : null)?.toString() ?? "—";

    final scheduleDate =
        DateTime.tryParse((s["scheduleDate"] ?? "").toString())?.toLocal();
    final startTime =
        DateTime.tryParse((s["startTime"] ?? "").toString())?.toLocal();
    final endTime =
        DateTime.tryParse((s["endTime"] ?? "").toString())?.toLocal();

    final dateStr =
        scheduleDate != null ? _dateYMD(scheduleDate) : "—";
    final timeStr = (startTime != null && endTime != null)
        ? "${_timeHHmm(startTime)} - ${_timeHHmm(endTime)}"
        : "—";

    bool showDebugJson = false;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) {
        return StatefulBuilder(
          builder: (context, setModalState) {
            return Container(
              constraints: BoxConstraints(
                maxHeight: MediaQuery.of(context).size.height * 0.75,
              ),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius:
                    BorderRadius.vertical(top: Radius.circular(24.r)),
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
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
                  Flexible(
                    child: SingleChildScrollView(
                      padding: EdgeInsets.fromLTRB(
                          20.w, 20.h, 20.w, 16.h),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            l10n.schedulePostedWard(wardName),
                            style: GoogleFonts.poppins(
                              fontSize: 20.sp,
                              fontWeight: FontWeight.w700,
                              color: const Color(0xFF0F172A),
                            ),
                          ),
                          SizedBox(height: 14.h),
                          Row(
                            children: [
                              _detailChip(Icons.calendar_today_rounded,
                                  dateStr, const Color(0xFF2563EB)),
                              SizedBox(width: 10.w),
                              _detailChip(Icons.access_time_rounded,
                                  timeStr, const Color(0xFF7C3AED)),
                            ],
                          ),
                          SizedBox(height: 18.h),
                          Container(
                              height: 1,
                              color: const Color(0xFFE2E8F0)),
                          SizedBox(height: 14.h),
                          Row(
                            children: [
                              Icon(Icons.person_outline_rounded,
                                  size: 18.w,
                                  color: const Color(0xFF64748B)),
                              SizedBox(width: 6.w),
                              Text(
                                l10n.postedBy,
                                style: GoogleFonts.poppins(
                                  fontSize: 14.sp,
                                  fontWeight: FontWeight.w700,
                                  color: const Color(0xFF334155),
                                ),
                              ),
                            ],
                          ),
                          SizedBox(height: 10.h),
                          _infoRow(l10n.name, createdByName),
                          _infoRow(l10n.email, createdByEmail),
                          if (kDebugMode) ...[
                            SizedBox(height: 16.h),
                            Container(
                                height: 1,
                                color: const Color(0xFFE2E8F0)),
                            SizedBox(height: 8.h),
                            Row(
                              children: [
                                Expanded(
                                  child: Text(
                                    l10n.technicalDetails,
                                    style: GoogleFonts.poppins(
                                        fontSize: 13.sp,
                                        fontWeight: FontWeight.w600,
                                        color:
                                            const Color(0xFF64748B)),
                                  ),
                                ),
                                GestureDetector(
                                  onTap: () => setModalState(() =>
                                      showDebugJson = !showDebugJson),
                                  child: Container(
                                    padding: EdgeInsets.symmetric(
                                        horizontal: 10.w,
                                        vertical: 4.h),
                                    decoration: BoxDecoration(
                                      color: const Color(0xFFEFF6FF),
                                      borderRadius:
                                          BorderRadius.circular(6.r),
                                    ),
                                    child: Text(
                                      showDebugJson
                                          ? l10n.hide
                                          : l10n.show,
                                      style: GoogleFonts.poppins(
                                        fontSize: 12.sp,
                                        fontWeight: FontWeight.w600,
                                        color:
                                            const Color(0xFF2563EB),
                                      ),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                            if (showDebugJson)
                              Container(
                                width: double.infinity,
                                margin: EdgeInsets.only(top: 8.h),
                                padding: EdgeInsets.all(12.w),
                                decoration: BoxDecoration(
                                  color: const Color(0xFFF8FAFC),
                                  borderRadius:
                                      BorderRadius.circular(12.r),
                                  border: Border.all(
                                      color: const Color(0xFFE2E8F0)),
                                ),
                                child: Text(
                                  const JsonEncoder.withIndent("  ")
                                      .convert(s),
                                  style: GoogleFonts.robotoMono(
                                      fontSize: 11.sp),
                                ),
                              ),
                          ],
                          SizedBox(height: 20.h),
                          SizedBox(
                            width: double.infinity,
                            height: 48.h,
                            child: ElevatedButton(
                              onPressed: () => Navigator.pop(context),
                              style: ElevatedButton.styleFrom(
                                backgroundColor:
                                    const Color(0xFF2563EB),
                                foregroundColor: Colors.white,
                                elevation: 0,
                                shape: RoundedRectangleBorder(
                                    borderRadius:
                                        BorderRadius.circular(14.r)),
                              ),
                              child: Text(
                                l10n.close,
                                style: GoogleFonts.poppins(
                                    fontSize: 15.sp,
                                    fontWeight: FontWeight.w700),
                              ),
                            ),
                          ),
                          SizedBox(height: 10.h),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  Widget _detailChip(IconData icon, String text, Color color) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 10.w, vertical: 6.h),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(10.r),
        border: Border.all(color: color.withValues(alpha: 0.2)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14.w, color: color),
          SizedBox(width: 4.w),
          Flexible(
            child: Text(
              text,
              style: GoogleFonts.poppins(
                  fontSize: 11.sp,
                  fontWeight: FontWeight.w600,
                  color: color),
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }

  Widget _infoRow(String label, String value) {
    return Padding(
      padding: EdgeInsets.only(bottom: 6.h),
      child: Row(
        children: [
          SizedBox(
            width: 80.w,
            child: Text(label,
                style: GoogleFonts.poppins(
                    fontSize: 13.sp,
                    color: const Color(0xFF94A3B8))),
          ),
          Expanded(
            child: Text(value,
                style: GoogleFonts.poppins(
                    fontSize: 13.sp,
                    fontWeight: FontWeight.w600,
                    color: const Color(0xFF0F172A))),
          ),
        ],
      ),
    );
  }

  // ─── Build ──────────────────────────────────
  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final displayName =
        _name.trim().isEmpty ? l10n.wardAdmin : _name.trim();

    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      body: SafeArea(
        child: _loading
            ? const Center(child: CircularProgressIndicator())
            : RefreshIndicator(
                onRefresh: _loadAll,
                color: const Color(0xFF2563EB),
                child: SingleChildScrollView(
                  physics: const AlwaysScrollableScrollPhysics(),
                  padding: EdgeInsets.all(16.w),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // ─── Header ─────────────────
                      _buildHeader(l10n, displayName),
                      SizedBox(height: 24.h),

                      // ─── Greeting ───────────────
                      Text(
                        l10n.namaste(displayName),
                        style: GoogleFonts.poppins(
                          fontSize: 26.sp,
                          fontWeight: FontWeight.w700,
                          color: const Color(0xFF0F172A),
                        ),
                      ),
                      SizedBox(height: 2.h),
                      Text(
                        l10n.recentOverview,
                        style: GoogleFonts.poppins(
                          fontSize: 14.sp,
                          color: const Color(0xFF64748B),
                        ),
                      ),
                      SizedBox(height: 24.h),

                      // ─── Supply Status Card ─────
                      _buildSupplyStatusCard(l10n),
                      SizedBox(height: 24.h),

                      // ─── Quick Actions ──────────
                      _sectionHeader(l10n.quickActions,
                          Icons.flash_on_rounded, const Color(0xFFF97316)),
                      SizedBox(height: 12.h),
                      Row(
                        children: [
                          Expanded(
                            child: _buildQuickActionCard(
                              icon: Icons.calendar_month_rounded,
                              iconColor: const Color(0xFF2563EB),
                              title: l10n.postSchedule,
                              subtitle: l10n.updateTimings,
                              onTap: () => AppNavigation.push(
                                  context, AppRoutes.newSchedule),
                            ),
                          ),
                          SizedBox(width: 12.w),
                          Expanded(
                            child: _buildQuickActionCard(
                              icon: Icons.campaign_rounded,
                              iconColor: const Color(0xFF7C3AED),
                              title: l10n.sendNotice,
                              subtitle: l10n.announceUpdates,
                              onTap: () => AppNavigation.push(
                                  context, AppRoutes.sendNotice),
                            ),
                          ),
                        ],
                      ),
                      SizedBox(height: 28.h),

                      // ─── Recent Schedules ───────
                      _sectionHeader(l10n.recentUpdatesMySchedules,
                          Icons.history_rounded, const Color(0xFF2563EB)),
                      SizedBox(height: 12.h),

                      if (_mySchedules.isEmpty)
                        _emptyCard(l10n.noSchedulesPostedYet,
                            Icons.event_busy_rounded)
                      else
                        ..._mySchedules.take(5).map((s) {
                          final ward = s["ward"];
                          final wardName =
                              (ward is Map ? ward["wardName"] : null)
                                      ?.toString() ??
                                  l10n.ward;

                          final scheduleDate = DateTime.tryParse(
                                  (s["scheduleDate"] ?? "").toString())
                              ?.toLocal();
                          final startTime = DateTime.tryParse(
                                  (s["startTime"] ?? "").toString())
                              ?.toLocal();
                          final endTime = DateTime.tryParse(
                                  (s["endTime"] ?? "").toString())
                              ?.toLocal();

                          final dateStr = scheduleDate != null
                              ? _dateYMD(scheduleDate)
                              : "—";
                          final timeStr =
                              (startTime != null && endTime != null)
                                  ? "${_timeHHmm(startTime)} – ${_timeHHmm(endTime)}"
                                  : "—";

                          return _buildScheduleCard(
                            wardName: wardName,
                            dateStr: dateStr,
                            timeStr: timeStr,
                            subtitle: l10n.postedByYouTapToOpen,
                            onTap: () => _openScheduleDetails(s),
                          );
                        }),

                      SizedBox(height: 100.h),
                    ],
                  ),
                ),
              ),
      ),
      bottomNavigationBar: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.06),
              blurRadius: 10,
              offset: const Offset(0, -2),
            ),
          ],
        ),
        child: BottomNavigationBar(
          type: BottomNavigationBarType.fixed,
          backgroundColor: Colors.white,
          selectedItemColor: const Color(0xFF2563EB),
          unselectedItemColor: const Color(0xFF94A3B8),
          selectedLabelStyle: GoogleFonts.poppins(
              fontSize: 12.sp, fontWeight: FontWeight.w600),
          unselectedLabelStyle: GoogleFonts.poppins(fontSize: 11.sp),
          currentIndex: _selectedIndex,
          onTap: _onBottomNavTap,
          elevation: 0,
          items: [
            BottomNavigationBarItem(
                icon: const Icon(Icons.home_rounded),
                label: l10n.home),
            BottomNavigationBarItem(
                icon: const Icon(Icons.report_rounded),
                label: l10n.reports),
            BottomNavigationBarItem(
                icon: const Icon(Icons.calendar_month_rounded),
                label: l10n.schedules),
            BottomNavigationBarItem(
                icon: const Icon(Icons.person_rounded),
                label: l10n.profile),
          ],
        ),
      ),
    );
  }

  // ─── Header ─────────────────────────────────
  Widget _buildHeader(AppLocalizations l10n, String displayName) {
    return Container(
      padding: EdgeInsets.all(14.w),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18.r),
        border: Border.all(color: const Color(0xFFE2E8F0)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 10,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              border: Border.all(
                  color: const Color(0xFFE2E8F0), width: 2.w),
            ),
            child: CircleAvatar(
              radius: 24.w,
              backgroundColor: const Color(0xFFEFF6FF),
              backgroundImage: _profileImageUrl.isNotEmpty
                  ? CachedNetworkImageProvider(_profileImageUrl)
                  : null,
              child: _profileImageUrl.isEmpty
                  ? Icon(Icons.person_rounded,
                      size: 26.w, color: const Color(0xFF2563EB))
                  : null,
            ),
          ),
          SizedBox(width: 12.w),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  displayName,
                  style: GoogleFonts.poppins(
                    fontSize: 16.sp,
                    fontWeight: FontWeight.w700,
                    color: const Color(0xFF0F172A),
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
                Row(
                  children: [
                    Icon(Icons.shield_rounded,
                        size: 12.w, color: const Color(0xFF2563EB)),
                    SizedBox(width: 4.w),
                    Text(
                      l10n.appName,
                      style: GoogleFonts.poppins(
                        fontSize: 12.sp,
                        color: const Color(0xFF64748B),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          GestureDetector(
            onTap: () =>
                AppNavigation.push(context, AppRoutes.notifications),
            child: Container(
              padding: EdgeInsets.all(10.w),
              decoration: BoxDecoration(
                color: const Color(0xFFF8FAFC),
                borderRadius: BorderRadius.circular(12.r),
                border: Border.all(color: const Color(0xFFE2E8F0)),
              ),
              child: Stack(
                children: [
                  Icon(Icons.notifications_outlined,
                      size: 24.w, color: const Color(0xFF334155)),
                  if (_hasUnread)
                    Positioned(
                      right: 0,
                      top: 0,
                      child: Container(
                        width: 10.w,
                        height: 10.w,
                        decoration: BoxDecoration(
                          color: const Color(0xFFEF4444),
                          shape: BoxShape.circle,
                          border: Border.all(
                              color: Colors.white, width: 1.5),
                        ),
                      ),
                    ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ─── Supply Status Card ─────────────────────
  Widget _buildSupplyStatusCard(AppLocalizations l10n) {
    return Container(
      padding: EdgeInsets.all(20.w),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF2563EB), Color(0xFF1D4ED8)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(20.r),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF2563EB).withValues(alpha: 0.3),
            blurRadius: 16,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: EdgeInsets.all(10.w),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(12.r),
                ),
                child: Icon(Icons.water_drop_rounded,
                    size: 28.w, color: Colors.white),
              ),
              const Spacer(),
              Container(
                padding: EdgeInsets.symmetric(
                    horizontal: 12.w, vertical: 6.h),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(8.r),
                ),
                child: Text(
                  l10n.supplyStatus,
                  style: GoogleFonts.poppins(
                    fontSize: 12.sp,
                    fontWeight: FontWeight.w600,
                    color: Colors.white.withValues(alpha: 0.9),
                  ),
                ),
              ),
            ],
          ),
          SizedBox(height: 18.h),
          Text(
            l10n.normalFlow,
            style: GoogleFonts.poppins(
              fontSize: 24.sp,
              fontWeight: FontWeight.w700,
              color: Colors.white,
            ),
          ),
          SizedBox(height: 8.h),
          Row(
            children: [
              Container(
                padding: EdgeInsets.all(4.w),
                decoration: BoxDecoration(
                  color: const Color(0xFF22C55E)
                      .withValues(alpha: 0.3),
                  shape: BoxShape.circle,
                ),
                child: Icon(Icons.check_rounded,
                    size: 14.w, color: Colors.white),
              ),
              SizedBox(width: 8.w),
              Text(
                l10n.activeDistribution,
                style: GoogleFonts.poppins(
                  fontSize: 14.sp,
                  color: Colors.white.withValues(alpha: 0.9),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  // ─── Section Header ─────────────────────────
  Widget _sectionHeader(String title, IconData icon, Color color) {
    return Row(
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
            fontSize: 16.sp,
            fontWeight: FontWeight.w700,
            color: const Color(0xFF0F172A),
          ),
        ),
      ],
    );
  }

  // ─── Quick Action Card ──────────────────────
  Widget _buildQuickActionCard({
    required IconData icon,
    required Color iconColor,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: EdgeInsets.all(18.w),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(18.r),
          border: Border.all(color: const Color(0xFFE2E8F0)),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.04),
              blurRadius: 10,
              offset: const Offset(0, 3),
            ),
          ],
        ),
        child: Column(
          children: [
            Container(
              padding: EdgeInsets.all(14.w),
              decoration: BoxDecoration(
                color: iconColor.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(16.r),
              ),
              child: Icon(icon, size: 32.w, color: iconColor),
            ),
            SizedBox(height: 14.h),
            Text(
              title,
              style: GoogleFonts.poppins(
                fontSize: 14.sp,
                fontWeight: FontWeight.w700,
                color: const Color(0xFF0F172A),
              ),
              textAlign: TextAlign.center,
            ),
            SizedBox(height: 4.h),
            Text(
              subtitle,
              style: GoogleFonts.poppins(
                fontSize: 12.sp,
                color: const Color(0xFF94A3B8),
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  // ─── Schedule Card ──────────────────────────
  Widget _buildScheduleCard({
    required String wardName,
    required String dateStr,
    required String timeStr,
    required String subtitle,
    required VoidCallback onTap,
  }) {
    return Padding(
      padding: EdgeInsets.only(bottom: 12.h),
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          padding: EdgeInsets.all(16.w),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16.r),
            border: Border.all(color: const Color(0xFFE2E8F0)),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.04),
                blurRadius: 10,
                offset: const Offset(0, 3),
              ),
            ],
          ),
          child: Row(
            children: [
              Container(
                padding: EdgeInsets.all(10.w),
                decoration: BoxDecoration(
                  color: const Color(0xFFEFF6FF),
                  borderRadius: BorderRadius.circular(12.r),
                ),
                child: Icon(Icons.calendar_today_rounded,
                    color: const Color(0xFF2563EB), size: 22.w),
              ),
              SizedBox(width: 14.w),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      wardName,
                      style: GoogleFonts.poppins(
                        fontSize: 14.sp,
                        fontWeight: FontWeight.w700,
                        color: const Color(0xFF0F172A),
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                    SizedBox(height: 4.h),
                    Row(
                      children: [
                        Flexible(
                          child: _detailChip(Icons.calendar_today_rounded,
                              dateStr, const Color(0xFF2563EB)),
                        ),
                        SizedBox(width: 6.w),
                        Flexible(
                          child: _detailChip(
                              Icons.access_time_rounded,
                              timeStr,
                              const Color(0xFF7C3AED)),
                        ),
                      ],
                    ),
                    SizedBox(height: 6.h),
                    Text(
                      subtitle,
                      style: GoogleFonts.poppins(
                        fontSize: 12.sp,
                        color: const Color(0xFF94A3B8),
                      ),
                    ),
                  ],
                ),
              ),
              Icon(Icons.chevron_right_rounded,
                  size: 22.w, color: const Color(0xFFCBD5E1)),
            ],
          ),
        ),
      ),
    );
  }

  // ─── Empty State Card ───────────────────────
  Widget _emptyCard(String message, IconData icon) {
    return Container(
      width: double.infinity,
      padding: EdgeInsets.symmetric(vertical: 40.h),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18.r),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      child: Column(
        children: [
          Container(
            width: 56.w,
            height: 56.w,
            decoration: BoxDecoration(
              color: const Color(0xFFF1F5F9),
              borderRadius: BorderRadius.circular(16.r),
            ),
            child: Icon(icon,
                color: const Color(0xFF94A3B8), size: 28.w),
          ),
          SizedBox(height: 12.h),
          Text(
            message,
            style: GoogleFonts.poppins(
              fontSize: 14.sp,
              fontWeight: FontWeight.w600,
              color: const Color(0xFF64748B),
            ),
          ),
        ],
      ),
    );
  }
}