import 'dart:async';
import 'dart:convert';

import 'package:fyp/core/routes/routes.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:intl/intl.dart';

import 'package:fyp/services/api_service.dart';
import 'package:fyp/models/notification_model.dart';
import 'package:fyp/notifications/notification_service.dart';

class VendorDashboardScreen extends StatefulWidget {
  const VendorDashboardScreen({super.key});

  @override
  State<VendorDashboardScreen> createState() => _VendorDashboardScreenState();
}

class _VendorDashboardScreenState extends State<VendorDashboardScreen> {
  // Student note: Notifications
  List<AppNotification> notifications = [];
  bool loadingNotifications = true;

  // Student note: Dashboard data
  bool loadingRoutes = true;
  bool loadingRequests = true;

  List<Map<String, dynamic>> routes = [];
  List<Map<String, dynamic>> requests = [];

  // Student note: Header info
  String vendorName = "Vendor";
  int todaysJobs = 0;

  // Student note: used to disable confirm/decline button while API is running
  final Set<int> _updatingBookingIds = {};

  StreamSubscription<RemoteMessage>? _onMessageSub;

  @override
  void initState() {
    super.initState();
    _initVendorFCM();
    _loadVendorDashboard();
    fetchNotifications();
  }

  @override
  void dispose() {
    _onMessageSub?.cancel();
    super.dispose();
  }

  // Student note: FCM for vendors
  Future<void> _initVendorFCM() async {
    try {
      await FirebaseMessaging.instance.requestPermission();
      await FirebaseMessaging.instance.subscribeToTopic("all_vendors");

      _onMessageSub = FirebaseMessaging.onMessage.listen((RemoteMessage msg) async {
        await fetchNotifications();
        if (!mounted) return;

        final title = msg.notification?.title ?? "New notification";
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

  // Student note: Load dashboard from backend
  Future<void> _loadVendorDashboard() async {
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

      final r = List<Map<String, dynamic>>.from(data['routes'] ?? []);
      final rq = List<Map<String, dynamic>>.from(data['requests'] ?? []);

      if (!mounted) return;
      setState(() {
        vendorName = (vendor['name'] ?? 'Vendor').toString();
        todaysJobs = (stats['todaysJobs'] ?? 0) is num ? (stats['todaysJobs'] as num).toInt() : 0;

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
        loadingRoutes = false;
        loadingRequests = false;
      });
    }
  }

  // ✅ Student note: Confirm / Decline booking request
  Future<void> _updateRequestStatus(int bookingId, String status) async {
    if (_updatingBookingIds.contains(bookingId)) return;

    setState(() => _updatingBookingIds.add(bookingId));

    try {
      // Student note: ApiService.patch signature is patch(endpoint, body)
      final res = await ApiService.patch(
        '/vendors/requests/$bookingId',
        {'status': status},
      );

      if (res.statusCode != 200) {
        throw Exception("HTTP ${res.statusCode}: ${res.body}");
      }

      // refresh dashboard after update
      await _loadVendorDashboard();

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Booking updated: $status")),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Update failed: $e"), backgroundColor: Colors.red),
      );
    } finally {
      if (!mounted) return;
      setState(() => _updatingBookingIds.remove(bookingId));
    }
  }

  // Student note: Load notifications from DB
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

  void _showNotifications() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => DraggableScrollableSheet(
        initialChildSize: 0.6,
        minChildSize: 0.4,
        maxChildSize: 0.9,
        builder: (_, controller) => Container(
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
          ),
          child: Column(
            children: [
              Container(
                margin: EdgeInsets.only(top: 12.h),
                width: 60.w,
                height: 6.h,
                decoration: BoxDecoration(
                  color: Colors.grey[300],
                  borderRadius: BorderRadius.circular(3.r),
                ),
              ),
              Padding(
                padding: EdgeInsets.all(16.w),
                child: Row(
                  children: [
                    Text("Notifications",
                        style: GoogleFonts.poppins(fontSize: 20.sp, fontWeight: FontWeight.bold)),
                    const Spacer(),
                    IconButton(onPressed: fetchNotifications, icon: const Icon(Icons.refresh)),
                  ],
                ),
              ),
              Expanded(
                child: loadingNotifications
                    ? const Center(child: CircularProgressIndicator())
                    : notifications.isEmpty
                    ? Center(
                  child: Text(
                    "No notifications yet",
                    style: GoogleFonts.poppins(fontSize: 16.sp, color: Colors.grey[600]),
                  ),
                )
                    : ListView.builder(
                  controller: controller,
                  itemCount: notifications.length,
                  itemBuilder: (context, index) {
                    final n = notifications[index];
                    return ListTile(
                      leading: const Icon(Icons.water_drop, color: Colors.blue),
                      title: Text(n.title, style: GoogleFonts.poppins(fontWeight: FontWeight.w600)),
                      subtitle: Text(n.message, style: GoogleFonts.poppins(color: Colors.grey[700])),
                      trailing: Text(
                        DateFormat('hh:mm a').format(n.createdAt),
                        style: GoogleFonts.poppins(fontSize: 12.sp, color: Colors.grey),
                      ),
                    );
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // Student note: UI helpers
  Widget _statCard({required String value, required String label, required Color color}) {
    return Container(
      padding: EdgeInsets.all(16.w),
      decoration: BoxDecoration(color: color, borderRadius: BorderRadius.circular(16.r)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(value, style: GoogleFonts.poppins(fontSize: 26.sp, fontWeight: FontWeight.bold)),
          SizedBox(height: 4.h),
          Text(label, style: GoogleFonts.poppins(fontSize: 12.sp, color: Colors.grey[700])),
        ],
      ),
    );
  }

  Color _statusColor(String status) {
    final s = status.toUpperCase();
    if (s == "PENDING") return Colors.orange;
    if (s == "CONFIRMED") return Colors.green;
    if (s == "COMPLETED" || s == "DELIVERED") return Colors.blue;
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[50],
      body: SafeArea(
        child: SingleChildScrollView(
          padding: EdgeInsets.all(16.w),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header
              Row(
                children: [
                  CircleAvatar(
                    radius: 28.w,
                    backgroundColor: Colors.grey[300],
                    child: Icon(Icons.person, size: 32.w, color: Colors.grey),
                  ),
                  SizedBox(width: 12.w),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          vendorName,
                          style: GoogleFonts.poppins(fontSize: 18.sp, fontWeight: FontWeight.bold),
                        ),
                        Text(
                          "Vendor Dashboard",
                          style: GoogleFonts.poppins(fontSize: 14.sp, color: Colors.grey[600]),
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    icon: Icon(Icons.notifications_outlined, size: 28.w),
                    onPressed: _showNotifications,
                  ),
                ],
              ),

              SizedBox(height: 24.h),

              // Stats row
              Row(
                children: [
                  Expanded(child: _statCard(value: "$todaysJobs", label: "TODAY'S JOBS", color: Colors.blue[50]!)),
                  SizedBox(width: 12.w),
                  Expanded(child: _statCard(value: "—", label: "SUCCESS", color: Colors.green[50]!)),
                  SizedBox(width: 12.w),
                  Expanded(child: _statCard(value: "—", label: "RATING", color: Colors.orange[50]!)),
                ],
              ),

              SizedBox(height: 32.h),

              // Active Routes header
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text("Active Routes", style: GoogleFonts.poppins(fontSize: 18.sp, fontWeight: FontWeight.w600)),
                  TextButton(
                    onPressed: _loadVendorDashboard,
                    child: Text("Refresh", style: GoogleFonts.poppins(color: Colors.blue)),
                  ),
                ],
              ),
              SizedBox(height: 16.h),

              // Routes list
              if (loadingRoutes)
                const Center(child: CircularProgressIndicator())
              else if (routes.isEmpty)
                _emptyInfoCard(
                  icon: Icons.route_outlined,
                  title: "No routes created",
                  subtitle: "Create routes and open slots to receive bookings.",
                )
              else
                Column(
                  children: routes.map((r) {
                    final wardName = (r['wardName'] ?? "-").toString();
                    final location = (r['location'] ?? "-").toString();
                    final status = (r['status'] ?? "Scheduled").toString();
                    final percent = (r['percentBooked'] ?? 0) is num ? (r['percentBooked'] as num).toInt() : 0;

                    final start = _timeLabel(r['startTime']);
                    final end = _timeLabel(r['endTime']);

                    return Container(
                      margin: EdgeInsets.only(bottom: 16.h),
                      padding: EdgeInsets.all(16.w),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(20.r),
                        boxShadow: [BoxShadow(color: Colors.black12, blurRadius: 8, offset: Offset(0, 4.h))],
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Expanded(
                                child: Text(
                                  wardName,
                                  style: GoogleFonts.poppins(fontWeight: FontWeight.w700),
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                              Container(
                                padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 4.h),
                                decoration: BoxDecoration(
                                  color: status.toLowerCase() == "active" ? Colors.green[100] : Colors.grey[200],
                                  borderRadius: BorderRadius.circular(20.r),
                                ),
                                child: Text(status, style: GoogleFonts.poppins(fontSize: 12.sp)),
                              ),
                            ],
                          ),
                          SizedBox(height: 8.h),
                          Text("Location: $location", style: GoogleFonts.poppins(color: Colors.grey[700])),
                          SizedBox(height: 8.h),

                          Row(
                            children: [
                              Icon(Icons.circle, size: 10.sp, color: Colors.blue),
                              SizedBox(width: 8.w),
                              Text("Start: $start", style: GoogleFonts.poppins(fontSize: 13.sp)),
                            ],
                          ),
                          SizedBox(height: 6.h),
                          Row(
                            children: [
                              Icon(Icons.circle, size: 10.sp, color: Colors.red),
                              SizedBox(width: 8.w),
                              Text("End: $end", style: GoogleFonts.poppins(fontSize: 13.sp)),
                            ],
                          ),

                          SizedBox(height: 12.h),

                          Row(
                            children: [
                              Expanded(
                                child: ClipRRect(
                                  borderRadius: BorderRadius.circular(999),
                                  child: LinearProgressIndicator(
                                    value: (percent.clamp(0, 100)) / 100.0,
                                    minHeight: 8.h,
                                    backgroundColor: Colors.grey[200],
                                    color: Colors.blue,
                                  ),
                                ),
                              ),
                              SizedBox(width: 10.w),
                              Text(
                                "$percent% Booked",
                                style: GoogleFonts.poppins(fontSize: 12.sp, color: Colors.grey[700]),
                              ),
                            ],
                          ),
                        ],
                      ),
                    );
                  }).toList(),
                ),

              SizedBox(height: 24.h),

              // Recent Requests header
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text("Recent Requests", style: GoogleFonts.poppins(fontSize: 18.sp, fontWeight: FontWeight.w600)),
                ],
              ),
              SizedBox(height: 16.h),

              // Requests list
              if (loadingRequests)
                const Center(child: CircularProgressIndicator())
              else if (requests.isEmpty)
                _emptyInfoCard(
                  icon: Icons.receipt_long_outlined,
                  title: "No requests",
                  subtitle: "Requests appear when residents book your slots.",
                )
              else
                Column(
                  children: requests.map((rq) {
                    final int bookingId = (rq['bookingId'] is num)
                        ? (rq['bookingId'] as num).toInt()
                        : int.tryParse((rq['bookingId'] ?? rq['id'] ?? "0").toString()) ?? 0;

                    final residentName = (rq['residentName'] ?? "Resident").toString();
                    final wardName = (rq['wardName'] ?? "-").toString();
                    final status = (rq['status'] ?? "PENDING").toString();
                    final dateChip = _dateChip(rq['createdAt']);

                    final isPending = status.toUpperCase() == "PENDING";
                    final isUpdating = _updatingBookingIds.contains(bookingId);

                    return Container(
                      margin: EdgeInsets.only(bottom: 12.h),
                      padding: EdgeInsets.all(16.w),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(20.r),
                        boxShadow: [BoxShadow(color: Colors.black12, blurRadius: 8, offset: Offset(0, 4.h))],
                      ),
                      child: Column(
                        children: [
                          Row(
                            children: [
                              if (dateChip.isNotEmpty)
                                Container(
                                  padding: EdgeInsets.all(12.w),
                                  decoration: BoxDecoration(
                                    color: Colors.blue[50],
                                    borderRadius: BorderRadius.circular(12.r),
                                  ),
                                  child: Text(
                                    dateChip,
                                    style: GoogleFonts.poppins(fontWeight: FontWeight.bold, color: Colors.blue),
                                  ),
                                ),
                              SizedBox(width: 12.w),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(residentName, style: GoogleFonts.poppins(fontWeight: FontWeight.w600)),
                                    Text(
                                      wardName,
                                      style: GoogleFonts.poppins(fontSize: 13.sp, color: Colors.grey[600]),
                                    ),
                                  ],
                                ),
                              ),
                              Text(status, style: GoogleFonts.poppins(color: _statusColor(status))),
                            ],
                          ),

                          // ✅ Confirm / Decline buttons only for PENDING
                          if (isPending) ...[
                            SizedBox(height: 12.h),
                            Row(
                              children: [
                                Expanded(
                                  child: ElevatedButton(
                                    onPressed: isUpdating ? null : () => _updateRequestStatus(bookingId, "CONFIRMED"),
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: Colors.blue,
                                      foregroundColor: Colors.white,
                                      elevation: 0,
                                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12.r)),
                                    ),
                                    child: isUpdating
                                        ? const SizedBox(
                                      height: 18,
                                      width: 18,
                                      child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                                    )
                                        : Text("Confirm", style: GoogleFonts.poppins(fontWeight: FontWeight.w600)),
                                  ),
                                ),
                                SizedBox(width: 10.w),
                                Expanded(
                                  child: OutlinedButton(
                                    onPressed: isUpdating ? null : () => _updateRequestStatus(bookingId, "CANCELLED"),
                                    style: OutlinedButton.styleFrom(
                                      foregroundColor: Colors.black87,
                                      side: BorderSide(color: Colors.grey[300]!),
                                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12.r)),
                                    ),
                                    child: Text("Decline", style: GoogleFonts.poppins(fontWeight: FontWeight.w600)),
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
      ),

      floatingActionButton: FloatingActionButton(
        onPressed: () {
          Navigator.of(context).pushNamed(AppRoutes.manageSlots);
        },
        backgroundColor: Colors.blue,
        child: Icon(Icons.add, size: 32.w),
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerDocked,

      bottomNavigationBar: BottomAppBar(
        shape: const CircularNotchedRectangle(),
        notchMargin: 8,
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          children: [
            _bottomItem(Icons.home, "Home", true),
            _bottomItem(Icons.route, "Routes", false),
            SizedBox(width: 40.w),
            _bottomItem(Icons.history, "History", false),
            _bottomItem(Icons.person, "Profile", false),
          ],
        ),
      ),
    );
  }

  // Student note: simple empty info card
  Widget _emptyInfoCard({required IconData icon, required String title, required String subtitle}) {
    return Container(
      width: double.infinity,
      padding: EdgeInsets.all(18.w),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20.r),
        boxShadow: [BoxShadow(color: Colors.black12, blurRadius: 8, offset: Offset(0, 4.h))],
      ),
      child: Row(
        children: [
          CircleAvatar(radius: 22.r, backgroundColor: Colors.blue[50], child: Icon(icon, color: Colors.blue)),
          SizedBox(width: 14.w),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: GoogleFonts.poppins(fontWeight: FontWeight.w600, fontSize: 16.sp)),
                SizedBox(height: 4.h),
                Text(subtitle, style: GoogleFonts.poppins(color: Colors.grey[600], fontSize: 13.sp)),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _bottomItem(IconData icon, String label, bool active) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, color: active ? Colors.blue : Colors.grey),
        Text(label, style: GoogleFonts.poppins(fontSize: 12.sp, color: active ? Colors.blue : Colors.grey)),
      ],
    );
  }
}