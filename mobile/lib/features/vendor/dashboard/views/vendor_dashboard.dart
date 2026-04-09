import 'dart:async';
import 'dart:convert';
import 'package:fyp/core/routes/routes.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:intl/intl.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:fyp/services/api_service.dart';
import 'package:fyp/features/shared/notifications/models/notification_model.dart';
import 'package:fyp/features/shared/notifications/services/notification_service.dart';
import 'package:fyp/features/vendor/deliveries/history/vendor_delivery_history_screen.dart';
import 'package:fyp/features/shared/maps/tracking/vendor_route_view.dart';
import 'package:fyp/l10n/app_localizations.dart';
import 'package:fyp/features/vendor/complaints/reportscreen.dart';

class VendorDashboardScreen extends StatefulWidget {
  const VendorDashboardScreen({super.key});

  @override
  State<VendorDashboardScreen> createState() => _VendorDashboardScreenState();
}

class _VendorDashboardScreenState extends State<VendorDashboardScreen>
    with WidgetsBindingObserver {
  // Bottom nav tabs:
  // 0 = Home, 1 = Reports(Complaints), 2 = History, 3 = Profile
  int _tabIndex = 0;

  // Notifications
  List<AppNotification> notifications = [];
  bool loadingNotifications = true;

  bool get hasUnreadNotifications => notifications.any((n) => n.isUnread);

  // Complaints (vendor reports tab)
  bool loadingComplaints = true;
  List<Map<String, dynamic>> complaints = [];

  // Dashboard data
  bool loadingRoutes = true;
  bool loadingRequests = true;

  List<Map<String, dynamic>> routes = [];
  List<Map<String, dynamic>> requests = [];

  // Header info
  String companyName = "Vendor Company";
  String contactName = "Vendor";
  String logoUrl = "";
  int vendorId = 0;

  int todaysJobs = 0;

  // Delivered + rating stats
  int deliveredCount = 0;
  double ratingAverage = 0.0;
  int ratedCount = 0;

  final Set<int> _updatingBookingIds = {};
  StreamSubscription<RemoteMessage>? _onMessageSub;

  Future<void> _openVendorProfile() async {
    await Navigator.pushNamed(context, AppRoutes.vendorProfile);
    if (!mounted) return;
    await _refreshAll();
  }

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);

    _initVendorFCM();
    _refreshAll();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _onMessageSub?.cancel();
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      _refreshAll();
    }
  }

  Future<void> _refreshAll() async {
    await Future.wait([
      _loadVendorDashboard(),
      fetchNotifications(),
      fetchVendorComplaints(),
    ]);
  }

  Future<void> _initVendorFCM() async {
    try {
      await FirebaseMessaging.instance.requestPermission();
      await FirebaseMessaging.instance.subscribeToTopic("all_vendors");

      _onMessageSub =
          FirebaseMessaging.onMessage.listen((RemoteMessage msg) async {
            await _refreshAll();

            if (!mounted) return;

            final l10n = AppLocalizations.of(context);
            final title = msg.notification?.title ??
                (l10n?.newNotification ?? "New notification");
            final body = msg.notification?.body ?? "";
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(body.isEmpty ? title : "$title\n$body"),
                behavior: SnackBarBehavior.floating,
              ),
            );
          });
    } catch (e) {
      debugPrint("Vendor FCM init error: $e");
    }
  }

  DateTime? _parseDateTime(dynamic raw) {
    if (raw == null) return null;
    try {
      return DateTime.parse(raw.toString());
    } catch (_) {
      return null;
    }
  }

  bool _isActiveSlotNow(Map<String, dynamic> r) {
    final start = _parseDateTime(r['startTime']);
    final end = _parseDateTime(r['endTime']);
    if (start == null || end == null) return false;

    final now = DateTime.now().toLocal();
    final s = start.toLocal();
    final e = end.toLocal();

    return (now.isAfter(s) || now.isAtSameMomentAs(s)) &&
        (now.isBefore(e) || now.isAtSameMomentAs(e));
  }

  bool _isWithinLast24Hours(dynamic createdAtRaw) {
    final dt = _parseDateTime(createdAtRaw);
    if (dt == null) return false;
    final cutoff = DateTime.now().toLocal().subtract(const Duration(hours: 24));
    return dt.toLocal().isAfter(cutoff);
  }

  List<Map<String, dynamic>> _sortRoutesForUi(
      List<Map<String, dynamic>> input) {
    final list = [...input];

    list.sort((a, b) {
      final aActive = _isActiveSlotNow(a);
      final bActive = _isActiveSlotNow(b);
      if (aActive != bActive) return aActive ? -1 : 1;

      final aEnd = _parseDateTime(a['endTime']);
      final bEnd = _parseDateTime(b['endTime']);
      if (aEnd != null && bEnd != null) {
        final c = bEnd.compareTo(aEnd);
        if (c != 0) return c;
      }

      final aStart = _parseDateTime(a['startTime']);
      final bStart = _parseDateTime(b['startTime']);
      if (aStart != null && bStart != null) {
        final c = bStart.compareTo(aStart);
        if (c != 0) return c;
      }

      final aDate = _parseDateTime(a['routeDate']);
      final bDate = _parseDateTime(b['routeDate']);
      if (aDate != null && bDate != null) {
        final c = bDate.compareTo(aDate);
        if (c != 0) return c;
      }

      return 0;
    });

    return list;
  }

  Future<void> _loadVendorDashboard() async {
    if (!mounted) return;

    setState(() {
      loadingRoutes = true;
      loadingRequests = true;
    });

    try {
      final res = await ApiService.get('/vendors/dashboard');
      if (res.statusCode != 200) {
        throw Exception("HTTP ${res.statusCode}: ${res.body}");
      }

      final data = jsonDecode(res.body) as Map<String, dynamic>;

      final vendor = (data['vendor'] ?? {}) as Map<String, dynamic>;
      final stats = (data['stats'] ?? {}) as Map<String, dynamic>;

      final r0 = List<Map<String, dynamic>>.from(data['routes'] ?? []);
      final rq = List<Map<String, dynamic>>.from(data['requests'] ?? []);
      final r = _sortRoutesForUi(r0);

      int toInt(dynamic v) {
        if (v is num) return v.toInt();
        return int.tryParse(v?.toString() ?? '') ?? 0;
      }

      double toDouble(dynamic v) {
        if (v is num) return v.toDouble();
        return double.tryParse(v?.toString() ?? '') ?? 0.0;
      }

      if (!mounted) return;
      setState(() {
        vendorId = (vendor['id'] is num) ? (vendor['id'] as num).toInt() : 0;
        companyName = (vendor['companyName'] ?? 'Vendor Company').toString();
        contactName = (vendor['contactName'] ?? 'Vendor').toString();
        logoUrl = (vendor['logoUrl'] ?? '').toString();

        todaysJobs = toInt(stats['todaysJobs']);
        deliveredCount = toInt(stats['deliveredCount']);
        ratingAverage = toDouble(stats['ratingAverage']);
        ratedCount = toInt(stats['ratedCount']);

        routes = r;
        requests = rq;

        loadingRoutes = false;
        loadingRequests = false;
      });
    } catch (e) {
      debugPrint("Vendor dashboard load error: $e");
      if (!mounted) return;
      setState(() {
        routes = [];
        requests = [];
        deliveredCount = 0;
        ratingAverage = 0.0;
        ratedCount = 0;
        loadingRoutes = false;
        loadingRequests = false;
      });
    }
  }

  Future<void> fetchVendorComplaints() async {
    if (!mounted) return;
    setState(() => loadingComplaints = true);

    try {
      final res = await ApiService.get('/complaints/vendor');
      if (res.statusCode != 200) {
        throw Exception("HTTP ${res.statusCode}: ${res.body}");
      }

      final decoded = jsonDecode(res.body);
      final list = (decoded is List) ? decoded : <dynamic>[];

      final mapped = list
          .whereType<Map>()
          .map((e) => Map<String, dynamic>.from(e))
          .toList();

      mapped.sort((a, b) {
        final ad = _parseDateTime(a['createdAt']) ??
            DateTime.fromMillisecondsSinceEpoch(0);
        final bd = _parseDateTime(b['createdAt']) ??
            DateTime.fromMillisecondsSinceEpoch(0);
        return bd.compareTo(ad);
      });

      if (!mounted) return;
      setState(() {
        complaints = mapped;
        loadingComplaints = false;
      });
    } catch (e) {
      debugPrint("Error fetching vendor complaints: $e");
      if (!mounted) return;
      setState(() {
        complaints = [];
        loadingComplaints = false;
      });
    }
  }

  Future<void> _updateRequestStatus(int bookingId, String status) async {
    final l10n = AppLocalizations.of(context);

    if (_updatingBookingIds.contains(bookingId)) return;
    setState(() => _updatingBookingIds.add(bookingId));

    try {
      final res = await ApiService.patch(
          '/vendors/requests/$bookingId', {'status': status});
      if (res.statusCode != 200) {
        throw Exception("HTTP ${res.statusCode}: ${res.body}");
      }

      await _loadVendorDashboard();

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(l10n != null
              ? l10n.bookingUpdated(status)
              : "Booking updated: $status"),
        ),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(l10n != null
              ? l10n.updateFailed(e.toString())
              : "Update failed: $e"),
          backgroundColor: Colors.red,
        ),
      );
    } finally {
      if (!mounted) return;
      setState(() => _updatingBookingIds.remove(bookingId));
    }
  }

  Future<void> fetchNotifications() async {
    if (!mounted) return;
    setState(() => loadingNotifications = true);

    try {
      final data = await NotificationService.getNotifications();
      if (!mounted) return;
      setState(() {
        notifications = data;
        loadingNotifications = false;
      });
    } catch (e) {
      debugPrint("Error fetching vendor notifications: $e");
      if (!mounted) return;
      setState(() => loadingNotifications = false);
    }
  }

  Widget _statCard({
    required String value,
    required String label,
    required Color bgColor,
    required Color valueColor,
    required Color borderColor,
  }) {
    return Container(
      padding: EdgeInsets.symmetric(vertical: 14.h, horizontal: 10.w),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(14.r),
        border: Border.all(color: borderColor, width: 1.5),
      ),
      child: Column(
        children: [
          Text(
            value,
            style: GoogleFonts.poppins(
              fontSize: 26.sp,
              fontWeight: FontWeight.bold,
              color: valueColor,
            ),
          ),
          SizedBox(height: 4.h),
          Text(
            label,
            style: GoogleFonts.poppins(
              fontSize: 10.sp,
              fontWeight: FontWeight.w600,
              color: const Color(0xFF64748B),
              letterSpacing: 0.5,
            ),
            textAlign: TextAlign.center,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }

  Color _statusColor(String status) {
    final s = status.toUpperCase();
    if (s == "PENDING") return Colors.orange;
    if (s == "CONFIRMED") return Colors.green;
    if (s == "DELIVERED") return Colors.purple;
    if (s == "COMPLETED") return Colors.blue;
    if (s == "CANCELLED") return Colors.red;
    return Colors.grey;
  }

  String _timeLabel(dynamic dtRaw) {
    if (dtRaw == null) return "-";
    try {
      final dt = DateTime.parse(dtRaw.toString());
      return DateFormat("h:mm a").format(dt.toLocal());
    } catch (_) {
      return "-";
    }
  }

  String _dateChip(dynamic createdAtRaw) {
    if (createdAtRaw == null) return "";
    try {
      final dt = DateTime.parse(createdAtRaw.toString());
      return DateFormat("MMM dd").format(dt.toLocal());
    } catch (_) {
      return "";
    }
  }

  String _ratingCardValue() {
    if (ratedCount <= 0) return "—";
    return ratingAverage.toStringAsFixed(1);
  }

  String _complaintStatus(dynamic s) {
    final v = (s ?? "OPEN").toString();
    return v.toUpperCase();
  }

  String _complaintTitleFromMessage(String msg, AppLocalizations l10n) {
    final lines = msg.split('\n');
    for (final line in lines) {
      if (line.toLowerCase().startsWith("issue type:")) {
        final x = line.split(":").skip(1).join(":").trim();
        if (x.isNotEmpty) return x;
      }
    }
    return l10n.issue;
  }

  void _openComplaintSheet(Map<String, dynamic> c, AppLocalizations l10n) {
    final id = c['id'];
    final status = _complaintStatus(c['status']);
    final createdAt = _parseDateTime(c['createdAt'])?.toLocal();
    final msg = (c['message'] ?? '').toString();
    final wardName = (c['wardName'] ?? '').toString();
    final residentName = ((c['resident'] is Map) ? c['resident']['name'] : null)
        ?.toString() ??
        l10n.resident;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      builder: (_) {
        return Padding(
          padding: EdgeInsets.only(
            left: 16.w,
            right: 16.w,
            top: 12.h,
            bottom: 16.h + MediaQuery.of(context).viewInsets.bottom,
          ),
          child: SingleChildScrollView( // ✅ avoids overflow inside sheet too
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  "Complaint #$id",
                  style: GoogleFonts.poppins(
                      fontSize: 18.sp, fontWeight: FontWeight.w700),
                ),
                SizedBox(height: 6.h),
                Text(
                  createdAt != null
                      ? DateFormat('MMM dd, yyyy • h:mm a').format(createdAt)
                      : "—",
                  style: GoogleFonts.poppins(
                      color: Colors.grey[600], fontSize: 12.sp),
                ),
                if (wardName.trim().isNotEmpty) ...[
                  SizedBox(height: 6.h),
                  Text(
                    l10n.wardNameLabel(wardName),
                    style: GoogleFonts.poppins(
                        color: Colors.grey[600], fontSize: 12.sp),
                  ),
                ],
                SizedBox(height: 10.h),
                Row(
                  children: [
                    Container(
                      padding: EdgeInsets.symmetric(
                          horizontal: 10.w, vertical: 6.h),
                      decoration: BoxDecoration(
                        color: Colors.blue.withOpacity(0.08),
                        borderRadius: BorderRadius.circular(999),
                      ),
                      child: Text(
                        status,
                        style: GoogleFonts.poppins(
                          fontWeight: FontWeight.w700,
                          color: Colors.blue[700],
                        ),
                      ),
                    ),
                    SizedBox(width: 10.w),
                    Expanded(
                      child: Text(
                        "From: $residentName",
                        style: GoogleFonts.poppins(
                            fontSize: 13.sp, fontWeight: FontWeight.w600),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
                SizedBox(height: 12.h),
                Text(
                  msg,
                  style: GoogleFonts.poppins(
                      fontSize: 13.sp, color: Colors.grey[800]),
                ),
                SizedBox(height: 16.h),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: () => Navigator.pop(context),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.blue,
                      foregroundColor: Colors.white,
                      padding: EdgeInsets.symmetric(vertical: 12.h),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14.r),
                      ),
                      elevation: 0,
                    ),
                    child: Text(
                      l10n.close,
                      style: GoogleFonts.poppins(fontWeight: FontWeight.w700),
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildHomeTab(AppLocalizations l10n) {
    final showCompany =
    companyName.trim().isNotEmpty ? companyName.trim() : l10n.vendorCompany;
    final showContact =
    contactName.trim().isNotEmpty ? contactName.trim() : l10n.vendor;

    final activeRoutes = routes.where(_isActiveSlotNow).toList();
    final recentRequests =
    requests.where((rq) => _isWithinLast24Hours(rq['createdAt'])).toList();

    return RefreshIndicator(
      onRefresh: _refreshAll,
      child: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: EdgeInsets.all(16.w),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // vendor header with avatar, name, Vendor ID, notification bell
            Row(
              children: [
                Container(
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    border: Border.all(color: const Color(0xFFE2E8F0), width: 2),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.08),
                        blurRadius: 8,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: CircleAvatar(
                    radius: 26.w,
                    backgroundColor: const Color(0xFFEFF6FF),
                    backgroundImage: logoUrl.trim().isNotEmpty 
                        ? CachedNetworkImageProvider(logoUrl, errorListener: (err) => debugPrint('Vendor Avatar 404: $err')) as ImageProvider 
                        : null,
                    child: logoUrl.trim().isEmpty
                        ? Icon(Icons.local_shipping_rounded,
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
                        showCompany,
                        style: GoogleFonts.poppins(
                          fontSize: 18.sp,
                          fontWeight: FontWeight.w700,
                          color: const Color(0xFF0F172A),
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                      SizedBox(height: 2.h),
                      Text(
                        '${l10n.vendorId}: $vendorId',
                        style: GoogleFonts.poppins(
                          fontSize: 12.sp,
                          color: const Color(0xFF94A3B8),
                          fontWeight: FontWeight.w500,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
                Stack(
                  children: [
                    Container(
                      padding: EdgeInsets.all(8.w),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(12.r),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.06),
                            blurRadius: 8,
                            offset: const Offset(0, 2),
                          ),
                        ],
                      ),
                      child: GestureDetector(
                        onTap: () => Navigator.pushNamed(context, AppRoutes.notifications),
                        child: Icon(Icons.notifications_none_rounded,
                            size: 24.w, color: const Color(0xFF475569)),
                      ),
                    ),
                    if (hasUnreadNotifications)
                      Positioned(
                        right: 8,
                        top: 8,
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
            ),
            SizedBox(height: 20.h),

            // stat cards row: Today's Jobs, Delivered, Rating
            Row(
              children: [
                Expanded(
                  child: _statCard(
                    value: '$todaysJobs',
                    label: l10n.todaysJobs.toUpperCase(),
                    bgColor: const Color(0xFFEFF6FF),
                    valueColor: const Color(0xFF2563EB),
                    borderColor: const Color(0xFFBFDBFE),
                  ),
                ),
                SizedBox(width: 10.w),
                Expanded(
                  child: _statCard(
                    value: deliveredCount <= 0 ? '—' : '$deliveredCount',
                    label: l10n.delivered.toUpperCase(),
                    bgColor: const Color(0xFFF0FDF4),
                    valueColor: const Color(0xFF16A34A),
                    borderColor: const Color(0xFFBBF7D0),
                  ),
                ),
                SizedBox(width: 10.w),
                Expanded(
                  child: _statCard(
                    value: _ratingCardValue(),
                    label: l10n.rating.toUpperCase(),
                    bgColor: const Color(0xFFFFF7ED),
                    valueColor: const Color(0xFFF97316),
                    borderColor: const Color(0xFFFED7AA),
                  ),
                ),
              ],
            ),

            SizedBox(height: 28.h),

            // divider
            Container(
              height: 1,
              color: const Color(0xFFE2E8F0),
            ),
            SizedBox(height: 20.h),

            // Active Routes header
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  l10n.activeRoutes,
                  style: GoogleFonts.poppins(
                    fontSize: 18.sp,
                    fontWeight: FontWeight.w700,
                    color: const Color(0xFF0F172A),
                  ),
                ),
                GestureDetector(
                  onTap: () async {
                    await Navigator.of(context).pushNamed(AppRoutes.manageSlots);
                    if (!mounted) return;
                    await _loadVendorDashboard();
                  },
                  child: Text(
                    '+ ${l10n.newSchedule}',
                    style: GoogleFonts.poppins(
                      fontSize: 14.sp,
                      fontWeight: FontWeight.w600,
                      color: const Color(0xFF2563EB),
                    ),
                  ),
                ),
              ],
            ),
            SizedBox(height: 14.h),

            if (loadingRoutes)
              _buildShimmerCard()
            else if (activeRoutes.isEmpty)
              _emptyInfoCard(
                icon: Icons.route_outlined,
                title: l10n.noActiveRoutes,
                subtitle: l10n.noActiveRoutesSubtitle,
              )
            else
              Column(
                children: activeRoutes.map((r) => _routeCard(r, l10n)).toList(),
              ),

            SizedBox(height: 24.h),

            // Recent Requests header
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  l10n.recentRequests,
                  style: GoogleFonts.poppins(
                    fontSize: 18.sp,
                    fontWeight: FontWeight.w700,
                    color: const Color(0xFF0F172A),
                  ),
                ),
                GestureDetector(
                  onTap: () => setState(() => _tabIndex = 2),
                  child: Text(
                    l10n.viewAll,
                    style: GoogleFonts.poppins(
                      fontSize: 14.sp,
                      fontWeight: FontWeight.w600,
                      color: const Color(0xFF2563EB),
                    ),
                  ),
                ),
              ],
            ),
            SizedBox(height: 16.h),

            if (loadingRequests)
              _buildShimmerCard()
            else if (recentRequests.isEmpty)
              _emptyInfoCard(
                icon: Icons.receipt_long_outlined,
                title: l10n.noRequests,
                subtitle: l10n.noRequestsSubtitle,
              )
            else
              Column(
                children: recentRequests.map((rq) {
                  final int bookingId = (rq['bookingId'] is num)
                      ? (rq['bookingId'] as num).toInt()
                      : int.tryParse(
                      (rq['bookingId'] ?? rq['id'] ?? "0").toString()) ??
                      0;

                  final residentName =
                  (rq['residentName'] ?? l10n.resident).toString();
                  final wardName = (rq['wardName'] ?? "-").toString();
                  final status = (rq['status'] ?? "PENDING").toString();
                  final dateChip = _dateChip(rq['createdAt']);
                  final timeChip = _timeLabel(rq['slotStartTime']);

                  final isPending = status.toUpperCase() == "PENDING";
                  final isConfirmed = status.toUpperCase() == "CONFIRMED";
                  final isUpdating = _updatingBookingIds.contains(bookingId);

                  // date chip split: "Oct" and "24"
                  final dateParts = dateChip.split(' ');
                  final monthStr = dateParts.isNotEmpty ? dateParts[0] : '';
                  final dayStr = dateParts.length > 1 ? dateParts[1] : '';

                  // status badge colors
                  Color statusBg;
                  Color statusFg;
                  final su = status.toUpperCase();
                  if (su == 'PENDING') {
                    statusBg = const Color(0xFFFFF7ED);
                    statusFg = const Color(0xFFF97316);
                  } else if (su == 'CONFIRMED') {
                    statusBg = const Color(0xFFF0FDF4);
                    statusFg = const Color(0xFF16A34A);
                  } else if (su == 'CANCELLED') {
                    statusBg = const Color(0xFFFEF2F2);
                    statusFg = const Color(0xFFEF4444);
                  } else {
                    statusBg = const Color(0xFFEFF6FF);
                    statusFg = const Color(0xFF2563EB);
                  }

                  return Container(
                    margin: EdgeInsets.only(bottom: 14.h),
                    padding: EdgeInsets.all(16.w),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(18.r),
                      border: Border.all(color: const Color(0xFFE2E8F0)),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.04),
                          blurRadius: 10,
                          offset: const Offset(0, 3),
                        ),
                      ],
                    ),
                    child: Column(
                      children: [
                        Row(
                          children: [
                            // styled date chip
                            if (dateChip.isNotEmpty)
                              Container(
                                width: 52.w,
                                padding: EdgeInsets.symmetric(vertical: 8.h),
                                decoration: BoxDecoration(
                                  color: const Color(0xFFF8FAFC),
                                  borderRadius: BorderRadius.circular(12.r),
                                  border: Border.all(color: const Color(0xFFE2E8F0)),
                                ),
                                child: Column(
                                  children: [
                                    Text(
                                      monthStr.toUpperCase(),
                                      style: GoogleFonts.poppins(
                                        fontSize: 10.sp,
                                        fontWeight: FontWeight.w600,
                                        color: const Color(0xFFEF4444),
                                      ),
                                    ),
                                    Text(
                                      dayStr,
                                      style: GoogleFonts.poppins(
                                        fontSize: 20.sp,
                                        fontWeight: FontWeight.w700,
                                        color: const Color(0xFF0F172A),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            SizedBox(width: 12.w),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    residentName,
                                    style: GoogleFonts.poppins(
                                      fontSize: 14.sp,
                                      fontWeight: FontWeight.w700,
                                      color: const Color(0xFF0F172A),
                                    ),
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                  SizedBox(height: 2.h),
                                  Row(
                                    children: [
                                      Icon(Icons.location_on_outlined,
                                          size: 14.w,
                                          color: const Color(0xFF94A3B8)),
                                      SizedBox(width: 4.w),
                                      Expanded(
                                        child: Text(
                                          wardName,
                                          style: GoogleFonts.poppins(
                                            fontSize: 12.sp,
                                            color: const Color(0xFF94A3B8),
                                          ),
                                          overflow: TextOverflow.ellipsis,
                                        ),
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                            ),
                            // status badge or time
                            if (isPending)
                              Container(
                                padding: EdgeInsets.symmetric(
                                    horizontal: 10.w, vertical: 4.h),
                                decoration: BoxDecoration(
                                  color: statusBg,
                                  borderRadius: BorderRadius.circular(8.r),
                                ),
                                child: Text(
                                  status.toUpperCase(),
                                  style: GoogleFonts.poppins(
                                    fontSize: 10.sp,
                                    fontWeight: FontWeight.w700,
                                    color: statusFg,
                                  ),
                                ),
                              )
                            else
                              Text(
                                timeChip,
                                style: GoogleFonts.poppins(
                                  fontSize: 13.sp,
                                  fontWeight: FontWeight.w600,
                                  color: const Color(0xFF334155),
                                ),
                              ),
                          ],
                        ),
                        // Pending: Confirm + Decline buttons
                        if (isPending) ...[
                          SizedBox(height: 14.h),
                          Row(
                            children: [
                              Expanded(
                                child: ElevatedButton(
                                  onPressed: isUpdating
                                      ? null
                                      : () => _updateRequestStatus(
                                      bookingId, "CONFIRMED"),
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: const Color(0xFF2563EB),
                                    foregroundColor: Colors.white,
                                    elevation: 0,
                                    padding: EdgeInsets.symmetric(vertical: 10.h),
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(10.r),
                                    ),
                                  ),
                                  child: isUpdating
                                      ? SizedBox(
                                    height: 18.w,
                                    width: 18.w,
                                    child: const CircularProgressIndicator(
                                        strokeWidth: 2,
                                        color: Colors.white),
                                  )
                                      : Text(
                                    l10n.confirm,
                                    style: GoogleFonts.poppins(
                                        fontWeight: FontWeight.w600,
                                        fontSize: 13.sp),
                                  ),
                                ),
                              ),
                              SizedBox(width: 10.w),
                              Expanded(
                                child: OutlinedButton(
                                  onPressed: isUpdating
                                      ? null
                                      : () => _updateRequestStatus(
                                      bookingId, "CANCELLED"),
                                  style: OutlinedButton.styleFrom(
                                    foregroundColor: const Color(0xFF475569),
                                    padding: EdgeInsets.symmetric(vertical: 10.h),
                                    side: const BorderSide(
                                        color: Color(0xFFE2E8F0)),
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(10.r),
                                    ),
                                  ),
                                  child: Text(
                                    l10n.decline,
                                    style: GoogleFonts.poppins(
                                        fontWeight: FontWeight.w600,
                                        fontSize: 13.sp),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ],
                        // Confirmed: show "Booking Confirmed" + Route button
                        if (isConfirmed) ...[
                          SizedBox(height: 10.h),
                          Row(
                            children: [
                              Container(
                                width: 24.w,
                                height: 24.w,
                                decoration: const BoxDecoration(
                                  color: Color(0xFF16A34A),
                                  shape: BoxShape.circle,
                                ),
                                child: Icon(Icons.check,
                                    size: 14.w, color: Colors.white),
                              ),
                              SizedBox(width: 8.w),
                              Expanded(
                                child: Text(
                                  'Booking Confirmed',
                                  style: GoogleFonts.poppins(
                                    fontSize: 13.sp,
                                    fontWeight: FontWeight.w600,
                                    color: const Color(0xFF16A34A),
                                  ),
                                ),
                              ),
                              // Route button → map tracking
                              SizedBox(
                                height: 34.h,
                                child: ElevatedButton.icon(
                                  onPressed: () {
                                    Navigator.push(
                                      context,
                                      MaterialPageRoute(
                                        builder: (_) =>
                                            VendorRouteView(bookingId: bookingId),
                                      ),
                                    );
                                  },
                                  icon: Icon(Icons.route_rounded,
                                      size: 16.w, color: Colors.white),
                                  label: Text(
                                    l10n.route,
                                    style: GoogleFonts.poppins(
                                      fontSize: 12.sp,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: const Color(0xFF2563EB),
                                    foregroundColor: Colors.white,
                                    elevation: 0,
                                    padding: EdgeInsets.symmetric(
                                        horizontal: 12.w),
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(8.r),
                                    ),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ],
                      ],
                    ),
                  );
                }).toList(),
              ),
            SizedBox(height: 100.h),
          ],
        ),
      ),
    );
  }

  Widget _buildReportsTab(AppLocalizations l10n) {
    return RefreshIndicator(
      onRefresh: fetchVendorComplaints,
      child: ListView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: EdgeInsets.all(16.w),
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  l10n.reports,
                  style: GoogleFonts.poppins(
                      fontSize: 18.sp, fontWeight: FontWeight.w700),
                ),
              ),
              TextButton(
                onPressed: fetchVendorComplaints,
                child: Text(l10n.refresh,
                    style: GoogleFonts.poppins(color: Colors.blue)),
              ),
            ],
          ),
          SizedBox(height: 12.h),
          if (loadingComplaints)
            const Center(
              child: Padding(
                padding: EdgeInsets.all(16),
                child: CircularProgressIndicator(),
              ),
            )
          else if (complaints.isEmpty)
            _emptyInfoCard(
              icon: Icons.report_outlined,
              title: l10n.noReportsYet,
              subtitle: l10n.noReportsYet,
            )
          else
            ...complaints.map((c) {
              final id = c['id'] ?? '';
              final status = _complaintStatus(c['status']);
              final msg = (c['message'] ?? '').toString();
              final createdAt = _parseDateTime(c['createdAt'])?.toLocal();
              final wardName = (c['wardName'] ?? '').toString();
              final title = _complaintTitleFromMessage(msg, l10n);

              return InkWell(
                onTap: () => _openComplaintSheet(c, l10n),
                borderRadius: BorderRadius.circular(16.r),
                child: Container(
                  margin: EdgeInsets.only(bottom: 12.h),
                  padding: EdgeInsets.all(16.w),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(16.r),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.05),
                        blurRadius: 10,
                        offset: Offset(0, 4.h),
                      ),
                    ],
                  ),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Container(
                        width: 44.w,
                        height: 44.w,
                        decoration: BoxDecoration(
                          color: Colors.red.withOpacity(0.08),
                          borderRadius: BorderRadius.circular(12.r),
                        ),
                        child: const Icon(Icons.report, color: Colors.red),
                      ),
                      SizedBox(width: 12.w),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Expanded(
                                  child: Text(
                                    title,
                                    style: GoogleFonts.poppins(
                                        fontWeight: FontWeight.w700),
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                                Container(
                                  padding: EdgeInsets.symmetric(
                                      horizontal: 10.w, vertical: 5.h),
                                  decoration: BoxDecoration(
                                    color: Colors.blue.withOpacity(0.08),
                                    borderRadius: BorderRadius.circular(999),
                                  ),
                                  child: Text(
                                    status,
                                    style: GoogleFonts.poppins(
                                      fontSize: 12.sp,
                                      fontWeight: FontWeight.w700,
                                      color: Colors.blue[700],
                                    ),
                                  ),
                                ),
                              ],
                            ),
                            SizedBox(height: 6.h),
                            Text(
                              "Complaint #$id"
                                  "${wardName.trim().isNotEmpty ? " • $wardName" : ""}"
                                  "${createdAt != null ? " • ${DateFormat('MMM dd, h:mm a').format(createdAt)}" : ""}",
                              style: GoogleFonts.poppins(
                                  fontSize: 12.sp,
                                  color: Colors.grey[600]),
                              overflow: TextOverflow.ellipsis,
                            ),
                            SizedBox(height: 6.h),
                            Text(
                              msg,
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                              style: GoogleFonts.poppins(
                                  fontSize: 13.sp,
                                  color: Colors.grey[800]),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              );
            }),
          SizedBox(height: 100.h),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    final body = switch (_tabIndex) {
      0 => _buildHomeTab(l10n),
      1 => VendorComplaintReportScreen(
        isLoading: loadingComplaints,
        complaints: complaints,
        onRefresh: fetchVendorComplaints,
      ),
      2 => VendorDeliveryHistoryScreen(
        onBack: () => setState(() => _tabIndex = 0),
      ),
      _ => _buildHomeTab(l10n),
    };

    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      body: SafeArea(child: body),

      floatingActionButton: _tabIndex == 0
          ? Container(
        height: 56.w,
        width: 56.w,
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            colors: [Color(0xFF2563EB), Color(0xFF3B82F6)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          shape: BoxShape.circle,
          boxShadow: [
            BoxShadow(
              color: const Color(0xFF2563EB).withOpacity(0.35),
              blurRadius: 14,
              offset: const Offset(0, 6),
            ),
          ],
        ),
        child: FloatingActionButton(
          backgroundColor: Colors.transparent,
          elevation: 0,
          onPressed: () async {
            await Navigator.of(context).pushNamed(AppRoutes.manageSlots);
            if (!mounted) return;
            await _loadVendorDashboard();
          },
          tooltip: l10n.add,
          child: Icon(Icons.add_rounded, size: 30.w, color: Colors.white),
        ),
      )
          : null,
      floatingActionButtonLocation: FloatingActionButtonLocation.centerDocked,


      bottomNavigationBar: BottomAppBar(
        shape: const CircularNotchedRectangle(),
        notchMargin: 8,
        child: SafeArea(
          top: false,
          child: SizedBox(
            height: 72.h,
            child: Row(
              children: [
                _bottomItem(Icons.home_rounded, l10n.home, _tabIndex == 0,
                    onTap: () => setState(() => _tabIndex = 0)),
                _bottomItem(Icons.report_gmailerrorred_rounded, l10n.reports, _tabIndex == 1,
                    onTap: () => setState(() => _tabIndex = 1)),
                SizedBox(width: 40.w),
                _bottomItem(Icons.history_rounded, l10n.history, _tabIndex == 2,
                    onTap: () => setState(() => _tabIndex = 2)),
                _bottomItem(Icons.person_outline_rounded, l10n.profile, false, onTap: _openVendorProfile),
              ],
            ),
          ),
        ),
      ),
    );
  }

  /*
  Widget _buildProfileRedirect(AppLocalizations l10n) {
    return Center(
      child: Padding(
        padding: EdgeInsets.all(16.w),
        child: ElevatedButton.icon(
          onPressed: () {
            Navigator.pushNamed(context, AppRoutes.vendorProfile).then((_) {
              if (!mounted) return;
              _loadVendorDashboard();
              setState(() => _tabIndex = 0);
            });
          },
          icon: const Icon(Icons.person),
          label: Text(
            l10n.profile,
            style: GoogleFonts.poppins(fontWeight: FontWeight.w700),
          ),
        ),
      ),
    );
  }

  */

  Widget _routeCard(Map<String, dynamic> r, AppLocalizations l10n) {
    final wardName = (r['wardName'] ?? '-').toString();
    final location = (r['location'] ?? '-').toString();
    final isActive = _isActiveSlotNow(r);
    final statusLabel = isActive ? l10n.active : 'Scheduled';
    final percent = (r['percentBooked'] ?? 0) is num
        ? (r['percentBooked'] as num).toInt()
        : 0;
    final slotsTotal = (r['slotsTotal'] ?? 0) is num ? (r['slotsTotal'] as num).toInt() : 0;
    final slotsUsed = (r['slotsUsed'] ?? 0) is num ? (r['slotsUsed'] as num).toInt() : 0;
    final start = _timeLabel(r['startTime']);
    final end = _timeLabel(r['endTime']);

    return Container(
      margin: EdgeInsets.only(bottom: 16.h),
      padding: EdgeInsets.all(16.w),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18.r),
        border: Border.all(color: const Color(0xFFE2E8F0)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 10,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // header row: icon, name, status badge
          Row(
            children: [
              Container(
                width: 40.w,
                height: 40.w,
                decoration: BoxDecoration(
                  color: const Color(0xFFF1F5F9),
                  borderRadius: BorderRadius.circular(10.r),
                ),
                child: Icon(Icons.local_shipping_rounded,
                    size: 20.w, color: const Color(0xFF475569)),
              ),
              SizedBox(width: 10.w),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '$wardName - $location',
                      style: GoogleFonts.poppins(
                        fontSize: 14.sp,
                        fontWeight: FontWeight.w700,
                        color: const Color(0xFF0F172A),
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                    SizedBox(height: 2.h),
                    Text(
                      'Tanker: 12,000L Capacity',
                      style: GoogleFonts.poppins(
                        fontSize: 12.sp,
                        color: const Color(0xFF94A3B8),
                      ),
                    ),
                  ],
                ),
              ),
              Container(
                padding: EdgeInsets.symmetric(horizontal: 10.w, vertical: 4.h),
                decoration: BoxDecoration(
                  color: isActive
                      ? const Color(0xFFDCFCE7)
                      : const Color(0xFFF1F5F9),
                  borderRadius: BorderRadius.circular(8.r),
                ),
                child: Text(
                  statusLabel,
                  style: GoogleFonts.poppins(
                    fontSize: 11.sp,
                    fontWeight: FontWeight.w600,
                    color: isActive
                        ? const Color(0xFF16A34A)
                        : const Color(0xFF64748B),
                  ),
                ),
              ),
            ],
          ),
          SizedBox(height: 14.h),

          // timeline: start and end
          Container(
            padding: EdgeInsets.all(12.w),
            decoration: BoxDecoration(
              color: const Color(0xFFF8FAFC),
              borderRadius: BorderRadius.circular(12.r),
            ),
            child: Column(
              children: [
                Row(
                  children: [
                    Container(
                      width: 10.w,
                      height: 10.w,
                      decoration: const BoxDecoration(
                        color: Color(0xFF2563EB),
                        shape: BoxShape.circle,
                      ),
                    ),
                    SizedBox(width: 10.w),
                    Expanded(
                      child: Text(
                        l10n.startLabel(start),
                        style: GoogleFonts.poppins(
                          fontSize: 13.sp,
                          color: const Color(0xFF334155),
                        ),
                      ),
                    ),
                  ],
                ),
                // connecting line
                Padding(
                  padding: EdgeInsets.only(left: 4.w),
                  child: Row(
                    children: [
                      Container(
                        width: 2,
                        height: 20.h,
                        color: const Color(0xFFCBD5E1),
                      ),
                    ],
                  ),
                ),
                Row(
                  children: [
                    Container(
                      width: 10.w,
                      height: 10.w,
                      decoration: const BoxDecoration(
                        color: Color(0xFFEF4444),
                        shape: BoxShape.circle,
                      ),
                    ),
                    SizedBox(width: 10.w),
                    Expanded(
                      child: Text(
                        l10n.endLabel(end),
                        style: GoogleFonts.poppins(
                          fontSize: 13.sp,
                          color: const Color(0xFF334155),
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),

          SizedBox(height: 14.h),

          // bottom row: stops/bookings count + edit/delete icons
          Row(
            children: [
              Expanded(
                child: Text(
                  '$slotsUsed Stops • $slotsTotal Bookings',
                  style: GoogleFonts.poppins(
                    fontSize: 12.sp,
                    color: const Color(0xFF64748B),
                  ),
                ),
              ),
              GestureDetector(
                onTap: () async {
                  await Navigator.of(context).pushNamed(AppRoutes.manageSlots);
                  if (!mounted) return;
                  await _loadVendorDashboard();
                },
                child: Container(
                  padding: EdgeInsets.all(6.w),
                  child: Icon(Icons.edit_outlined,
                      size: 18.w, color: const Color(0xFF64748B)),
                ),
              ),
              SizedBox(width: 8.w),
              Container(
                padding: EdgeInsets.all(6.w),
                child: Icon(Icons.stop_rounded,
                    size: 18.w, color: const Color(0xFF2563EB)),
              ),
            ],
          ),

          // progress bar row
          if (!isActive) ...[
            SizedBox(height: 10.h),
            Row(
              children: [
                Icon(Icons.access_time_rounded,
                    size: 14.w, color: const Color(0xFF94A3B8)),
                SizedBox(width: 6.w),
                Expanded(
                  child: Text(
                    'Starts at ${_timeLabel(r['startTime'])} Today',
                    style: GoogleFonts.poppins(
                      fontSize: 12.sp,
                      color: const Color(0xFF94A3B8),
                    ),
                  ),
                ),
              ],
            ),
            SizedBox(height: 8.h),
            ClipRRect(
              borderRadius: BorderRadius.circular(999),
              child: LinearProgressIndicator(
                value: (percent.clamp(0, 100)) / 100.0,
                minHeight: 6.h,
                backgroundColor: const Color(0xFFE2E8F0),
                color: const Color(0xFF2563EB),
              ),
            ),
            SizedBox(height: 4.h),
            Align(
              alignment: Alignment.centerRight,
              child: Text(
                l10n.percentBooked(percent),
                style: GoogleFonts.poppins(
                  fontSize: 11.sp,
                  color: const Color(0xFF94A3B8),
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }

  // shimmer loading placeholder card
  Widget _buildShimmerCard() {
    return Container(
      padding: EdgeInsets.all(16.w),
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
                width: 40.w, height: 40.w,
                decoration: BoxDecoration(
                  color: const Color(0xFFE2E8F0),
                  borderRadius: BorderRadius.circular(10.r),
                ),
              ),
              SizedBox(width: 10.w),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      height: 14.h, width: 140.w,
                      decoration: BoxDecoration(
                        color: const Color(0xFFE2E8F0),
                        borderRadius: BorderRadius.circular(6.r),
                      ),
                    ),
                    SizedBox(height: 6.h),
                    Container(
                      height: 10.h, width: 100.w,
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
          SizedBox(height: 14.h),
          Container(
            height: 60.h,
            decoration: BoxDecoration(
              color: const Color(0xFFE2E8F0),
              borderRadius: BorderRadius.circular(10.r),
            ),
          ),
        ],
      ),
    );
  }

  Widget _emptyInfoCard({
    required IconData icon,
    required String title,
    required String subtitle,
  }) {
    return Container(
      width: double.infinity,
      padding: EdgeInsets.all(18.w),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20.r),
        boxShadow: [
          BoxShadow(
            color: Colors.black12,
            blurRadius: 8,
            offset: Offset(0, 4.h),
          ),
        ],
      ),
      child: Row(
        children: [
          CircleAvatar(
            radius: 22.r,
            backgroundColor: Colors.blue[50],
            child: Icon(icon, color: Colors.blue),
          ),
          SizedBox(width: 14.w),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: GoogleFonts.poppins(
                      fontWeight: FontWeight.w600, fontSize: 16.sp),
                ),
                SizedBox(height: 4.h),
                Text(
                  subtitle,
                  style: GoogleFonts.poppins(
                      color: Colors.grey[600], fontSize: 13.sp),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }


  Widget _bottomItem(
      IconData icon,
      String label,
      bool active, {
        VoidCallback? onTap,
      }) {
    final color = active ? Colors.blue : Colors.grey;

    return Expanded(
      child: InkWell(
        onTap: onTap,
        child: Center(
          child: SizedBox(
            height: 56.h,
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(icon, color: color, size: 22.w),
                SizedBox(height: 3.h),
                SizedBox(
                  height: 12.h,
                  child: FittedBox(
                    fit: BoxFit.scaleDown,
                    child: Text(
                      label,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: GoogleFonts.poppins(
                        fontSize: 11.sp,
                        color: color,
                        fontWeight: active ? FontWeight.w700 : FontWeight.w500,
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
}