import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:fyp/services/api_service.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:fyp/core/routes/app_navigation.dart';
import 'package:fyp/core/routes/routes.dart';
import 'package:fyp/l10n/app_localizations.dart';
import 'package:fyp/features/shared/notifications/models/notification_model.dart';
import 'package:fyp/features/shared/notifications/services/notification_service.dart';
import 'package:fyp/features/resident/bookings/services/tanker_service.dart';
import 'package:fyp/features/resident/complaints/views/complaint_detail_screen.dart';
import 'package:fyp/features/resident/profile/views/profile_screen.dart' show BookingModel, IssueModel;
import 'package:fyp/features/resident/bookings/views/booking_detail_screen.dart';
import 'package:fyp/features/resident/bookings/views/my_bookings_history_screen.dart';

// main dashboard screen for resident users
// shows greeting, supply card, quick actions, nearby tankers, and reports
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
  State<ResidentDashboardScreen> createState() =>
      _ResidentDashboardScreenState();
}

class _ResidentDashboardScreenState extends State<ResidentDashboardScreen> {
  // color constants for the dashboard
  static const Color primaryBlue = Color(0xFF2563EB);
  static const Color lightBlue = Color(0xFF3B82F6);
  static const Color bgColor = Color(0xFFF8FAFC);
  static const Color cardColor = Colors.white;
  static const Color textDark = Color(0xFF0F172A);
  static const Color textMuted = Color(0xFF64748B);
  static const Color textLight = Color(0xFF94A3B8);
  static const Color greenBg = Color(0xFFDCFCE7);
  static const Color greenText = Color(0xFF16A34A);
  static const Color yellowBg = Color(0xFFFEF9C3);
  static const Color yellowText = Color(0xFFCA8A04);

  int _navIndex = 0;

  List<BookingModel> _bookings = [];
  List<IssueModel> _issues = [];
  int _bookingPage = 0;
  int _issuePage = 0;
  final int _pageSize = 5;

  // data lists
  List<AppNotification> notifications = [];
  bool loadingReports = true;
  List<Map<String, dynamic>> myReports = [];
  bool loadingNearby = true;
  List<Map<String, dynamic>> nearbyTankers = [];

  // get ward name from the ward object (can be string or map)
  String? _extractWardName(dynamic w) {
    if (w == null) return null;
    if (w is Map && w['name'] != null) return w['name'].toString();
    if (w is String) {
      final s = w.trim();
      final matchName = RegExp(
        r'name:\s*([^}]+)',
        caseSensitive: false,
      ).firstMatch(s);
      if (matchName != null) return matchName.group(1)?.trim();
      return s;
    }
    return w.toString();
  }

  String get wardName => _extractWardName(widget.ward) ?? '';

  // format ward text for display like "Kathmandu, Ward 4"
  String prettyWardTextForLocale(AppLocalizations t) {
    final name = wardName.trim();
    if (name.isEmpty) return t.wardNotSet;

    final match = RegExp(
      r'^(.*)\s+Ward\s*(\d+)$',
      caseSensitive: false,
    ).firstMatch(name);
    if (match != null) {
      final city = match.group(1)!.trim();
      final number = match.group(2)!.trim();
      return t.cityWard(city, number);
    }
    return name;
  }

  // fetch notifications from server
  Future<void> fetchNotifications() async {
    try {
      final data = await NotificationService.getNotifications();
      if (!mounted) return;
      setState(() => notifications = data);
    } catch (_) {}
  }

  Future<void> fetchMyReports() async {
    if (!mounted) return;
    setState(() => loadingReports = true);

    try {
      final res = await ApiService.get('/profile/me');
      if (res.statusCode != 200) {
        throw Exception("Failed to load profile (${res.statusCode})");
      }

      final data = jsonDecode(res.body) as Map<String, dynamic>;
      
      final bks = ((data['bookings'] ?? []) as List)
          .map((e) => BookingModel.fromJson(e as Map<String, dynamic>))
          .toList()
        ..sort((a, b) => b.createdAt.compareTo(a.createdAt));
        
      final iss = ((data['issues'] ?? []) as List)
          .map((e) => IssueModel.fromJson(e as Map<String, dynamic>))
          .toList()
        ..sort((a, b) => b.createdAt.compareTo(a.createdAt));

      if (!mounted) return;
      setState(() {
        _bookings = bks;
        _issues = iss;
        loadingReports = false;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() => loadingReports = false);
    }
  }

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

  String _formatDateList(DateTime dt) => DateFormat('MMM d, yyyy • hh:mm a').format(dt.toLocal());
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
  
  Widget _buildPagination({
    required int page,
    required int totalItems,
    required VoidCallback onPrev,
    required VoidCallback onNext,
  }) {
    final totalPages = _totalPages(totalItems);
    return Padding(
      padding: EdgeInsets.symmetric(vertical: 20.h),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          IconButton(onPressed: page > 0 ? onPrev : null, icon: Icon(Icons.chevron_left_rounded, size: 24.w)),
          Text("Page ${page + 1} of $totalPages", style: GoogleFonts.poppins(fontSize: 12.sp, fontWeight: FontWeight.w500, color: const Color(0xFF64748B))),
          IconButton(onPressed: (page + 1) < totalPages ? onNext : null, icon: Icon(Icons.chevron_right_rounded, size: 24.w)),
        ],
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
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: EdgeInsets.all(16.w),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16.r),
          border: Border.all(color: const Color(0xFFE2E8F0)),
          boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.03), blurRadius: 8, offset: const Offset(0, 2))],
        ),
        child: Row(
          children: [
            Container(
              height: 46.w, width: 46.w,
              decoration: BoxDecoration(color: const Color(0xFFF8FAFC), shape: BoxShape.circle, border: Border.all(color: const Color(0xFFE2E8F0))),
              child: Icon(icon, size: 22.w, color: const Color(0xFF0F172A)),
            ),
            SizedBox(width: 14.w),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title, style: GoogleFonts.poppins(fontSize: 15.sp, fontWeight: FontWeight.w700, color: const Color(0xFF0F172A))),
                  SizedBox(height: 4.h),
                  Text(subtitle, style: GoogleFonts.poppins(fontSize: 12.sp, color: const Color(0xFF64748B))),
                ],
              ),
            ),
            SizedBox(width: 10.w),
            Container(
              padding: EdgeInsets.symmetric(horizontal: 10.w, vertical: 6.h),
              decoration: BoxDecoration(color: statusColor.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(10.r)),
              child: Text(status, style: GoogleFonts.poppins(fontSize: 10.sp, fontWeight: FontWeight.w700, color: statusColor, letterSpacing: 0.5)),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBookingsTab(AppLocalizations t) {
    if (loadingReports) return const Center(child: CircularProgressIndicator());
    return SingleChildScrollView(
      physics: const AlwaysScrollableScrollPhysics(),
      child: Padding(
        padding: EdgeInsets.all(16.w),
        child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(height: 12.h),
          Text(t.tabBookings, style: GoogleFonts.poppins(fontSize: 22.sp, fontWeight: FontWeight.w700, color: textDark)),
          SizedBox(height: 20.h),
          if (_bookings.isEmpty)
            Center(child: Text(t.noBookingsYet, style: GoogleFonts.poppins(color: textMuted)))
          else ...[
            ..._visibleBookings.map((b) => Padding(
              padding: EdgeInsets.only(bottom: 12.h),
              child: _activityItem(
                icon: Icons.local_shipping_rounded,
                title: "Booking #${b.id}",
                subtitle: "${b.routeLocation ?? "-"} • ${_formatTimeRange(b.slotStartTime, b.slotEndTime)} • ${_formatDateList(b.createdAt)}",
                status: b.status,
                statusColor: _bookingStatusColor(b.status),
                onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => BookingDetailScreen(bookingId: b.id))),
              ),
            )),
            _buildPagination(
              page: _bookingPage,
              totalItems: _bookings.length,
              onPrev: () => setState(() => _bookingPage--),
              onNext: () => setState(() => _bookingPage++),
            ),
          ],
        ],
      ),
    ),
    );
  }

  Widget _buildReportsTab(AppLocalizations t) {
    if (loadingReports) return const Center(child: CircularProgressIndicator());
    return SingleChildScrollView(
      physics: const AlwaysScrollableScrollPhysics(),
      child: Padding(
        padding: EdgeInsets.all(16.w),
        child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(height: 12.h),
          Text(t.tabComplaints, style: GoogleFonts.poppins(fontSize: 22.sp, fontWeight: FontWeight.w700, color: textDark)),
          SizedBox(height: 20.h),
          if (_issues.isEmpty)
            Center(child: Text(t.noComplaintsYet, style: GoogleFonts.poppins(color: textMuted)))
          else ...[
            ..._visibleIssues.map((i) => Padding(
              padding: EdgeInsets.only(bottom: 12.h),
              child: _activityItem(
                icon: Icons.warning_amber_rounded,
                title: i.title,
                subtitle: "Complaint #${i.id} • ${_formatDateList(i.createdAt)}",
                status: i.status,
                statusColor: _issueStatusColor(i.status),
                onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => ComplaintDetailScreen(complaintId: i.id))),
              ),
            )),
            _buildPagination(
              page: _issuePage,
              totalItems: _issues.length,
              onPrev: () => setState(() => _issuePage--),
              onNext: () => setState(() => _issuePage++),
            ),
          ],
        ],
      ),
    ),
    );
  }

  // fetch nearby available tankers for the horizontal scroll list
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
        filter: "available_now",
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

  // helper to load png icons with fallback
  Widget pngIcon(String asset, {double size = 22, Color? tint}) {
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

  // format date like "Sep 12, 2023"
  String _formatDateLabel(DateTime dt) {
    return DateFormat('MMM d, yyyy').format(dt.toLocal());
  }

  // format time like "4:00 PM"
  String _formatTimeLabel(DateTime dt) {
    return DateFormat('h:mm a').format(dt.toLocal());
  }

  // get relative day text like "Today", "Yesterday"
  String _relativeDayLocalized(AppLocalizations t, DateTime dt) {
    final now = DateTime.now();
    final d = dt.toLocal();
    final today = DateTime(now.year, now.month, now.day);
    final dateOnly = DateTime(d.year, d.month, d.day);
    final diff = dateOnly.difference(today).inDays;

    if (diff == 0) return t.today;
    if (diff == -1) return t.yesterday;
    return DateFormat('MMM d').format(d);
  }

  // navigate to profile screen
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

  // navigate to find tankers screen
  void _openBookings() {
    AppNavigation.push(context, AppRoutes.findTankers);
  }

  // navigate to report issue screen then refresh reports
  Future<void> _openReportIssue() async {
    await AppNavigation.push(context, AppRoutes.reportIssue);
    await fetchMyReports();
  }

  @override
  Widget build(BuildContext context) {
    final t = AppLocalizations.of(context)!;
    final now = DateTime.now();
    final currentTime = _formatTimeLabel(now);
    final currentDate = _formatDateLabel(now);
    final prettyWardText = prettyWardTextForLocale(t);

    return Scaffold(
      backgroundColor: bgColor,
      floatingActionButton: Container(
        height: 58.w,
        width: 58.w,
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            colors: [primaryBlue, lightBlue],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          shape: BoxShape.circle,
          boxShadow: [
            BoxShadow(
              color: primaryBlue.withOpacity(0.35),
              blurRadius: 14,
              offset: const Offset(0, 6),
            ),
          ],
        ),
        child: FloatingActionButton(
          backgroundColor: Colors.transparent,
          elevation: 0,
          onPressed: _openBookings,
          tooltip: t.bookTanker,
          child: Icon(Icons.water_drop_rounded, color: Colors.white, size: 26.w),
        ),
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerDocked,
      bottomNavigationBar: _buildBottomBar(t),
      body: SafeArea(
        child: IndexedStack(
          index: _navIndex,
          children: [
            SingleChildScrollView(
              physics: const AlwaysScrollableScrollPhysics(),
              child: Padding(
                padding: EdgeInsets.symmetric(horizontal: 16.w),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                SizedBox(height: 12.h),

                // outer white container to hold all dashboard content
                Container(
                  padding: EdgeInsets.all(18.w),
                  decoration: BoxDecoration(
                    color: cardColor,
                    borderRadius: BorderRadius.circular(24.r),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.04),
                        blurRadius: 16,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // greeting header row
                      _buildHeader(t, prettyWardText),
                      SizedBox(height: 22.h),

                      // today's supply section title
                      _buildSupplyTitle(t),
                      SizedBox(height: 14.h),

                      // blue gradient next supply card
                      _buildNextSupplyCard(t, currentTime, currentDate),
                      SizedBox(height: 20.h),

                      // quick action buttons row
                      _buildQuickActions(t),
                      SizedBox(height: 24.h),

                      // nearby tankers horizontal scroll section
                      _buildNearbyTankersSection(t),
                      SizedBox(height: 24.h),

                      // your reports section
                      _buildReportsSection(t),

                      SizedBox(height: 100.h),
                    ],
                  ),
                ),
                SizedBox(height: 16.h),
              ],
            ),
          ),
        ),
        const MyBookingsHistoryScreen(isTab: true),
        const SizedBox(), // Fab index
        _buildReportsTab(t),
        const SizedBox(), // Profile handled by onTap
        ],
        ),
      ),
    );
  }

  // header with greeting, ward location, and notification bell
  Widget _buildHeader(AppLocalizations t, String prettyWardText) {
    return Row(
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // greeting text like "Namaste, Aarya"
              Row(
                children: [
                  Flexible(
                    child: Text(
                      t.namaste(widget.userName),
                      style: GoogleFonts.poppins(
                        fontSize: 15.sp,
                        color: textMuted,
                        fontWeight: FontWeight.w500,
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  SizedBox(width: 4.w),
                  Text('👋', style: TextStyle(fontSize: 16.sp)),
                ],
              ),
              SizedBox(height: 6.h),

              // ward location with pin icon
              Row(
                children: [
                  Icon(
                    Icons.location_on,
                    size: 18.w,
                    color: primaryBlue,
                  ),
                  SizedBox(width: 6.w),
                  Expanded(
                    child: Text(
                      prettyWardText,
                      style: GoogleFonts.poppins(
                        fontSize: 19.sp,
                        fontWeight: FontWeight.w700,
                        color: textDark,
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),

        // notification bell with red dot
        Stack(
          children: [
            Container(
              padding: EdgeInsets.all(10.w),
              decoration: BoxDecoration(
                color: cardColor,
                borderRadius: BorderRadius.circular(14.r),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.06),
                    blurRadius: 10,
                    offset: const Offset(0, 3),
                  ),
                ],
              ),
              child: GestureDetector(
                onTap: () =>
                    Navigator.pushNamed(context, AppRoutes.notifications),
                child: Icon(
                  Icons.notifications_none_rounded,
                  size: 24.w,
                  color: const Color(0xFF475569),
                ),
              ),
            ),
            if (notifications.isNotEmpty)
              Positioned(
                right: 10.w,
                top: 10.h,
                child: Container(
                  width: 9.w,
                  height: 9.w,
                  decoration: const BoxDecoration(
                    color: Color(0xFFEF4444),
                    shape: BoxShape.circle,
                  ),
                ),
              ),
          ],
        ),
      ],
    );
  }

  // "Today's Supply" title with "On Schedule" badge
  Widget _buildSupplyTitle(AppLocalizations t) {
    return Row(
      children: [
        Expanded(
          child: Text(
            t.todaysSupply,
            style: GoogleFonts.poppins(
              fontSize: 18.sp,
              fontWeight: FontWeight.w700,
              color: textDark,
            ),
            overflow: TextOverflow.ellipsis,
          ),
        ),
        SizedBox(width: 10.w),
        Container(
          padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 5.h),
          decoration: BoxDecoration(
            color: greenBg,
            borderRadius: BorderRadius.circular(20.r),
          ),
          child: Text(
            t.onSchedule,
            style: GoogleFonts.poppins(
              fontSize: 12.sp,
              fontWeight: FontWeight.w600,
              color: greenText,
            ),
          ),
        ),
      ],
    );
  }

  // blue gradient card showing next supply time
  Widget _buildNextSupplyCard(
      AppLocalizations t, String currentTime, String currentDate) {
    return Container(
      width: double.infinity,
      padding: EdgeInsets.all(20.w),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF1D4ED8), Color(0xFF3B82F6)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(22.r),
        boxShadow: [
          BoxShadow(
            color: primaryBlue.withOpacity(0.3),
            blurRadius: 16,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // top row: "Next Supply" label and water drop icon
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                t.nextSupply,
                style: GoogleFonts.poppins(
                  fontSize: 14.sp,
                  color: Colors.white.withOpacity(0.85),
                ),
              ),
              Container(
                height: 42.w,
                width: 42.w,
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.2),
                  shape: BoxShape.circle,
                ),
                child: Center(
                  child: Icon(
                    Icons.water_drop_rounded,
                    size: 20.w,
                    color: Colors.white,
                  ),
                ),
              ),
            ],
          ),
          SizedBox(height: 8.h),

          // big time text
          Text(
            currentTime,
            style: GoogleFonts.poppins(
              fontSize: 36.sp,
              fontWeight: FontWeight.w700,
              color: Colors.white,
            ),
          ),
          SizedBox(height: 4.h),

          // expected duration text
          Text(
            t.expectedDurationHours(2),
            style: GoogleFonts.poppins(
              fontSize: 13.sp,
              color: Colors.white.withOpacity(0.8),
            ),
          ),
          SizedBox(height: 14.h),

          // divider
          Container(
            height: 1,
            color: Colors.white.withOpacity(0.2),
          ),
          SizedBox(height: 12.h),

          // bottom row: date and flow status
          Row(
            children: [
              Icon(
                Icons.calendar_today_outlined,
                size: 16.w,
                color: Colors.white.withOpacity(0.9),
              ),
              SizedBox(width: 8.w),
              Expanded(
                child: Text(
                  currentDate,
                  style: GoogleFonts.poppins(
                    color: Colors.white.withOpacity(0.9),
                    fontSize: 13.sp,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              // normal flow badge
              Container(
                padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 5.h),
                decoration: BoxDecoration(
                  color: const Color(0xFFC8E6C9),
                  borderRadius: BorderRadius.circular(20.r),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      width: 7.w,
                      height: 7.w,
                      decoration: const BoxDecoration(
                        color: Color(0xFF4CAF50),
                        shape: BoxShape.circle,
                      ),
                    ),
                    SizedBox(width: 6.w),
                    Text(
                      t.normalFlow,
                      style: GoogleFonts.poppins(
                        fontSize: 11.sp,
                        fontWeight: FontWeight.w600,
                        color: const Color(0xFF388E3C),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  // quick action buttons: Book Tanker and Report Issue
  Widget _buildQuickActions(AppLocalizations t) {
    return Row(
      children: [
        Expanded(
          child: _actionCard(
            title: t.bookTanker,
            icon: Icons.local_shipping_rounded,
            color: const Color(0xFF2563EB),
            onTap: _openBookings,
          ),
        ),
        SizedBox(width: 14.w),
        Expanded(
          child: _actionCard(
            title: t.reportIssue,
            icon: Icons.warning_amber_rounded,
            color: const Color(0xFFF97316),
            onTap: () => _openReportIssue(),
          ),
        ),
      ],
    );
  }

  // single quick action card with icon and label
  Widget _actionCard({
    required String title,
    required IconData icon,
    required Color color,
    required VoidCallback onTap,
  }) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(18.r),
        onTap: onTap,
        child: Container(
          padding: EdgeInsets.symmetric(vertical: 20.h, horizontal: 12.w),
          decoration: BoxDecoration(
            color: cardColor,
            borderRadius: BorderRadius.circular(18.r),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.05),
                blurRadius: 12,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Column(
            children: [
              Container(
                height: 50.w,
                width: 50.w,
                decoration: BoxDecoration(
                  color: color.withOpacity(0.1),
                  shape: BoxShape.circle,
                ),
                child: Icon(icon, color: color, size: 26.w),
              ),
              SizedBox(height: 10.h),
              Text(
                title,
                style: GoogleFonts.poppins(
                  fontSize: 13.sp,
                  fontWeight: FontWeight.w600,
                  color: textDark,
                ),
                textAlign: TextAlign.center,
                overflow: TextOverflow.ellipsis,
                maxLines: 1,
              ),
            ],
          ),
        ),
      ),
    );
  }

  // nearby tankers section with horizontal scrollable cards
  Widget _buildNearbyTankersSection(AppLocalizations t) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // section header row
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Expanded(
              child: Text(
                t.nearbyTankers,
                style: GoogleFonts.poppins(
                  fontSize: 18.sp,
                  fontWeight: FontWeight.w700,
                  color: textDark,
                ),
                overflow: TextOverflow.ellipsis,
              ),
            ),
            GestureDetector(
              onTap: _openBookings,
              child: Text(
                t.viewAll,
                style: GoogleFonts.poppins(
                  fontSize: 14.sp,
                  color: primaryBlue,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ],
        ),
        SizedBox(height: 14.h),

        // loading state
        if (loadingNearby)
          SizedBox(
            height: 200.h,
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              itemCount: 3,
              itemBuilder: (context, index) => _buildTankerShimmer(),
            ),
          )

        // empty state
        else if (nearbyTankers.isEmpty)
          Container(
            width: double.infinity,
            padding: EdgeInsets.all(24.w),
            decoration: BoxDecoration(
              color: const Color(0xFFF8FAFC),
              borderRadius: BorderRadius.circular(16.r),
              border: Border.all(color: const Color(0xFFE2E8F0)),
            ),
            child: Column(
              children: [
                Icon(
                  Icons.local_shipping_outlined,
                  size: 40.w,
                  color: textLight,
                ),
                SizedBox(height: 10.h),
                Text(
                  t.noTankersAvailableNow,
                  style: GoogleFonts.poppins(
                    fontSize: 14.sp,
                    color: textMuted,
                  ),
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          )

        // horizontal scrollable tanker cards
        else
          SizedBox(
            height: 210.h,
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              itemCount: nearbyTankers.length,
              physics: const BouncingScrollPhysics(),
              itemBuilder: (context, index) {
                return _buildTankerCard(t, nearbyTankers[index]);
              },
            ),
          ),
      ],
    );
  }

  // loading shimmer placeholder card for tanker list
  Widget _buildTankerShimmer() {
    return Container(
      width: 220.w,
      margin: EdgeInsets.only(right: 14.w),
      padding: EdgeInsets.all(14.w),
      decoration: BoxDecoration(
        color: const Color(0xFFF8FAFC),
        borderRadius: BorderRadius.circular(18.r),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 44.w,
                height: 44.w,
                decoration: BoxDecoration(
                  color: const Color(0xFFE2E8F0),
                  borderRadius: BorderRadius.circular(12.r),
                ),
              ),
              SizedBox(width: 10.w),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      height: 14.h,
                      width: 100.w,
                      decoration: BoxDecoration(
                        color: const Color(0xFFE2E8F0),
                        borderRadius: BorderRadius.circular(6.r),
                      ),
                    ),
                    SizedBox(height: 6.h),
                    Container(
                      height: 10.h,
                      width: 70.w,
                      decoration: BoxDecoration(
                        color: const Color(0xFFE2E8F0),
                        borderRadius: BorderRadius.circular(6.r),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const Spacer(),
          Container(
            height: 12.h,
            width: 60.w,
            decoration: BoxDecoration(
              color: const Color(0xFFE2E8F0),
              borderRadius: BorderRadius.circular(6.r),
            ),
          ),
          SizedBox(height: 12.h),
          Container(
            height: 38.h,
            decoration: BoxDecoration(
              color: const Color(0xFFE2E8F0),
              borderRadius: BorderRadius.circular(10.r),
            ),
          ),
        ],
      ),
    );
  }

  // individual tanker card for horizontal scroll
  Widget _buildTankerCard(AppLocalizations t, Map<String, dynamic> tank) {
    final name = (tank['name'] ?? t.vendor).toString();
    final status = (tank['status'] ?? '').toString().toUpperCase();

    // extract capacity in liters
    final int capacity = (tank['tankerCapacityLiters'] ?? 0) is num
        ? (tank['tankerCapacityLiters'] as num).toInt()
        : 0;

    // extract price
    final priceRaw = tank['price'];
    final int priceInt = priceRaw is num ? priceRaw.toInt() : 0;

    final double rating = (tank['ratingAverage'] as num?)?.toDouble() ?? 0.0;
    
    // check if vendor is available
    final bool isAvailable = status == 'AVAILABLE';

    return GestureDetector(
      onTap: _openBookings,
      child: Container(
        width: 220.w,
        margin: EdgeInsets.only(right: 14.w),
        padding: EdgeInsets.all(14.w),
        decoration: BoxDecoration(
          color: cardColor,
          borderRadius: BorderRadius.circular(18.r),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 12,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // top row: avatar and vendor name
            Row(
              children: [
                // vendor icon with colored bg
                Container(
                  width: 44.w,
                  height: 44.w,
                  decoration: BoxDecoration(
                    color: const Color(0xFFEFF6FF),
                    borderRadius: BorderRadius.circular(12.r),
                  ),
                  child: Icon(
                    Icons.local_shipping_rounded,
                    color: primaryBlue,
                    size: 22.w,
                  ),
                ),
                SizedBox(width: 10.w),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        name,
                        style: GoogleFonts.poppins(
                          fontSize: 14.sp,
                          fontWeight: FontWeight.w700,
                          color: textDark,
                        ),
                        overflow: TextOverflow.ellipsis,
                        maxLines: 1,
                      ),
                      SizedBox(height: 3.h),
                      // star rating row
                      Row(
                        children: [
                          Icon(
                            Icons.star_rounded,
                            size: 14.w,
                            color: const Color(0xFFFBBF24),
                          ),
                          SizedBox(width: 3.w),
                          Flexible(
                            child: Text(
                              rating == 0 ? '0' : rating.toStringAsFixed(1),
                              style: GoogleFonts.poppins(
                                fontSize: 11.sp,
                                color: textMuted,
                              ),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),

            SizedBox(height: 14.h),

            // capacity and price row
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                // capacity text
                Text(
                  capacity > 0
                      ? t.litersShort(capacity)
                      : '12,000 Ltr',
                  style: GoogleFonts.poppins(
                    fontSize: 13.sp,
                    color: textMuted,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                // price text in highlight color
                Text(
                  priceInt > 0
                      ? 'Rs. ${_formatPrice(priceInt)}'
                      : 'Rs. 3,500',
                  style: GoogleFonts.poppins(
                    fontSize: 14.sp,
                    color: primaryBlue,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ],
            ),

            const Spacer(),

            // book now button
            SizedBox(
              width: double.infinity,
              child: isAvailable
                  ? ElevatedButton(
                      onPressed: _openBookings,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFFEFF6FF),
                        foregroundColor: primaryBlue,
                        elevation: 0,
                        padding: EdgeInsets.symmetric(vertical: 10.h),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12.r),
                        ),
                      ),
                      child: Text(
                        t.bookTanker,
                        style: GoogleFonts.poppins(
                          fontSize: 13.sp,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    )
                  : OutlinedButton(
                      onPressed: _openBookings,
                      style: OutlinedButton.styleFrom(
                        foregroundColor: textMuted,
                        padding: EdgeInsets.symmetric(vertical: 10.h),
                        side: BorderSide(color: const Color(0xFFE2E8F0)),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12.r),
                        ),
                      ),
                      child: Text(
                        t.viewDetails,
                        style: GoogleFonts.poppins(
                          fontSize: 13.sp,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
            ),
          ],
        ),
      ),
    );
  }

  // your reports section with latest report card
  Widget _buildReportsSection(AppLocalizations t) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          t.yourReports,
          style: GoogleFonts.poppins(
            fontSize: 18.sp,
            fontWeight: FontWeight.w700,
            color: textDark,
          ),
        ),
        SizedBox(height: 12.h),

        // loading state
        if (loadingReports)
          _buildReportShimmer()

        // empty state
        else if (_issues.isEmpty)
          Container(
            width: double.infinity,
            padding: EdgeInsets.all(20.w),
            decoration: BoxDecoration(
              color: const Color(0xFFF8FAFC),
              borderRadius: BorderRadius.circular(16.r),
              border: Border.all(color: const Color(0xFFE2E8F0)),
            ),
            child: Row(
              children: [
                Icon(
                  Icons.check_circle_outline_rounded,
                  size: 24.w,
                  color: greenText,
                ),
                SizedBox(width: 12.w),
                Expanded(
                  child: Text(
                    t.noReportsYet,
                    style: GoogleFonts.poppins(
                      fontSize: 14.sp,
                      color: textMuted,
                    ),
                  ),
                ),
              ],
            ),
          )

        // show latest report card
        else
          _buildReportCard(t, _issues.first),
      ],
    );
  }

  // shimmer style placeholder for report loading
  Widget _buildReportShimmer() {
    return Container(
      padding: EdgeInsets.all(16.w),
      decoration: BoxDecoration(
        color: const Color(0xFFF8FAFC),
        borderRadius: BorderRadius.circular(16.r),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      child: Row(
        children: [
          Container(
            width: 44.w,
            height: 44.w,
            decoration: BoxDecoration(
              color: const Color(0xFFE2E8F0),
              shape: BoxShape.circle,
            ),
          ),
          SizedBox(width: 12.w),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  height: 14.h,
                  width: 120.w,
                  decoration: BoxDecoration(
                    color: const Color(0xFFE2E8F0),
                    borderRadius: BorderRadius.circular(6.r),
                  ),
                ),
                SizedBox(height: 8.h),
                Container(
                  height: 10.h,
                  width: 160.w,
                  decoration: BoxDecoration(
                    color: const Color(0xFFE2E8F0),
                    borderRadius: BorderRadius.circular(6.r),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // report card showing complaint title, ticket and status
  Widget _buildReportCard(AppLocalizations t, IssueModel r) {
    final complaintId = r.id;
    final title = r.title.isNotEmpty ? r.title : t.issue;
    final status = r.status.isNotEmpty ? r.status : 'IN_REVIEW';
    final createdAt = r.createdAt;

    final statusUpper = status.toUpperCase();
    final label = statusUpper == "IN_REVIEW" ? t.inReview : status;

    // pick status color based on status
    final Color statusBg;
    final Color statusFg;
    if (statusUpper == 'RESOLVED') {
      statusBg = greenBg;
      statusFg = greenText;
    } else if (statusUpper == 'REJECTED') {
      statusBg = const Color(0xFFFEE2E2);
      statusFg = const Color(0xFFEF4444);
    } else {
      statusBg = const Color(0xFFEFF6FF);
      statusFg = primaryBlue;
    }

    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(18.r),
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) =>
                  ComplaintDetailScreen(complaintId: complaintId),
            ),
          );
        },
        child: Container(
          padding: EdgeInsets.all(16.w),
          decoration: BoxDecoration(
            color: cardColor,
            borderRadius: BorderRadius.circular(18.r),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.04),
                blurRadius: 10,
                offset: const Offset(0, 3),
              ),
            ],
          ),
          child: Row(
            children: [
              // yellow circle icon
              Container(
                height: 44.w,
                width: 44.w,
                decoration: const BoxDecoration(
                  color: yellowBg,
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  Icons.flag_outlined,
                  color: yellowText,
                  size: 22.w,
                ),
              ),
              SizedBox(width: 12.w),

              // title and ticket info
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: GoogleFonts.poppins(
                        fontSize: 14.sp,
                        fontWeight: FontWeight.w600,
                        color: textDark,
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                    SizedBox(height: 3.h),
                    Text(
                      t.ticketWithDate(
                        complaintId.toString(),
                        _relativeDayLocalized(t, createdAt),
                      ),
                      style: GoogleFonts.poppins(
                        fontSize: 12.sp,
                        color: textMuted,
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
              SizedBox(width: 8.w),

              // status badge
              Container(
                padding: EdgeInsets.symmetric(
                  horizontal: 12.w,
                  vertical: 5.h,
                ),
                decoration: BoxDecoration(
                  color: statusBg,
                  borderRadius: BorderRadius.circular(10.r),
                ),
                child: Text(
                  label,
                  style: GoogleFonts.poppins(
                    fontSize: 11.sp,
                    fontWeight: FontWeight.w700,
                    color: statusFg,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // bottom navigation bar with notch for fab
  Widget _buildBottomBar(AppLocalizations t) {
    final inactive = const Color(0xFF94A3B8);

    Widget navItem({
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
            if (index == 4) {
              _openProfile();
              return;
            }
            setState(() => _navIndex = index);
            if (index == 0) onTap();
          },
          child: Center(
            child: SizedBox(
              height: 40.h,
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(icon, color: color, size: 20.w),
                  SizedBox(height: 3.h),
                  SizedBox(
                    height: 13.h,
                    child: FittedBox(
                      fit: BoxFit.scaleDown,
                      child: Text(
                        label,
                        style: GoogleFonts.poppins(
                          fontSize: 10.sp,
                          color: color,
                          fontWeight:
                              isActive ? FontWeight.w600 : FontWeight.w500,
                        ),
                      ),
                    ),
                  ),
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
      color: cardColor,
      elevation: 12,
      child: SizedBox(
        height: 72.h,
        child: Row(
          children: [
            navItem(
              index: 0,
              icon: Icons.home_rounded,
              label: t.home,
              onTap: () {},
            ),
            navItem(
              index: 1,
              icon: Icons.receipt_long_rounded,
              label: t.bookings,
              onTap: () {},
            ),
            SizedBox(width: 60.w), // space for fab
            navItem(
              index: 3,
              icon: Icons.access_time_rounded,
              label: t.reports,
              onTap: () {},
            ),
            navItem(
              index: 4,
              icon: Icons.person_outline_rounded,
              label: t.profile,
              onTap: () {}, // Handled directly inside navItem logic
            ),
          ],
        ),
      ),
    );
  }

  // format price with comma separator
  String _formatPrice(int price) {
    if (price >= 1000) {
      return '${price ~/ 1000},${(price % 1000).toString().padLeft(3, '0')}';
    }
    return price.toString();
  }
}

// notification bottom sheet (kept same as original)
class _NotificationSheet extends StatelessWidget {
  final List<AppNotification> notifications;

  const _NotificationSheet({required this.notifications});

  @override
  Widget build(BuildContext context) {
    final t = AppLocalizations.of(context)!;

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
                  t.notificationsTitle,
                  style: GoogleFonts.poppins(
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const Spacer(),
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: Text(
                    t.close,
                    style:
                        GoogleFonts.poppins(color: const Color(0xFF1976D2)),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Expanded(
              child: notifications.isEmpty
                  ? Center(
                      child: Text(
                        t.noNotifications,
                        style: GoogleFonts.poppins(),
                      ),
                    )
                  : ListView.separated(
                      itemCount: notifications.length,
                      separatorBuilder: (_, __) =>
                          const Divider(height: 10),
                      itemBuilder: (context, index) {
                        final n = notifications[index];
                        return ListTile(
                          contentPadding: EdgeInsets.zero,
                          title: Text(
                            n.title,
                            style: GoogleFonts.poppins(
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          subtitle: Text(
                            n.message,
                            style: GoogleFonts.poppins(fontSize: 12),
                          ),
                          trailing: Text(
                            DateFormat('hh:mm a')
                                .format(n.createdAt.toLocal()),
                            style: GoogleFonts.poppins(
                              fontSize: 11,
                              color: Colors.grey[600],
                            ),
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