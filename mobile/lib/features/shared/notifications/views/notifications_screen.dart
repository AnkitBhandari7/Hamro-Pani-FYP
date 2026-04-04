import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:fyp/features/shared/notifications/models/notification_model.dart';
import 'package:fyp/l10n/app_localizations.dart';
import '../controllers/notifications_controller.dart';
import '../screens/pdf_viewer_screen.dart';
import 'package:fyp/features/vendor/bookings/services/vendor_booking_service.dart';

class NotificationsScreen extends StatelessWidget {
  static const String route = '/notifications';
  const NotificationsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (_) => NotificationsController(),
      child: const _View(),
    );
  }
}

class _View extends StatefulWidget {
  const _View();

  @override
  State<_View> createState() => _ViewState();
}

class _ViewState extends State<_View> {
  // Vendor deliveries state
  bool _isVendor = false;
  bool _loadingDeliveries = false;
  bool _updatingDelivery = false;
  List<VendorBookingItem> _deliveryItems = [];
  List<VendorBookingItem> _allOrderItems = [];
  bool _loadingOrders = false;

  @override
  void initState() {
    super.initState();
    _checkIfVendor();
  }

  Future<void> _checkIfVendor() async {
    try {
      final confirmed = await VendorBookingService.getVendorBookings(
          status: 'CONFIRMED');
      if (!mounted) return;
      setState(() {
        _isVendor = true;
        _deliveryItems = confirmed;
      });
      // Also load all orders for the Orders tab
      await _loadAllOrders();
    } catch (_) {
      // Not a vendor or API error — hide deliveries tab
    }
  }

  Future<void> _loadDeliveries() async {
    setState(() => _loadingDeliveries = true);
    try {
      _deliveryItems = await VendorBookingService.getVendorBookings(
          status: 'CONFIRMED');
    } catch (_) {}
    if (mounted) setState(() => _loadingDeliveries = false);
  }

  Future<void> _loadAllOrders() async {
    setState(() => _loadingOrders = true);
    try {
      // Load all statuses
      final confirmed = await VendorBookingService.getVendorBookings(status: 'CONFIRMED');
      final delivered = await VendorBookingService.getVendorBookings(status: 'DELIVERED');
      final completed = await VendorBookingService.getVendorBookings(status: 'COMPLETED');
      final cancelled = await VendorBookingService.getVendorBookings(status: 'CANCELLED');
      _allOrderItems = [...confirmed, ...delivered, ...completed, ...cancelled];
    } catch (_) {}
    if (mounted) setState(() => _loadingOrders = false);
  }

  Future<void> _markDelivered(int bookingId) async {
    if (_updatingDelivery) return;
    setState(() => _updatingDelivery = true);
    try {
      await VendorBookingService.markDelivered(bookingId);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(AppLocalizations.of(context)!.markedAsDelivered),
          backgroundColor: const Color(0xFF16A34A),
          behavior: SnackBarBehavior.floating,
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        ),
      );
      await _loadDeliveries();
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('${AppLocalizations.of(context)!.actionFailed}: $e'),
          backgroundColor: const Color(0xFFEF4444),
          behavior: SnackBarBehavior.floating,
        ),
      );
    } finally {
      if (mounted) setState(() => _updatingDelivery = false);
    }
  }

  String? _extractPdfUrl(String message) {
    final reg = RegExp(r'(https?:\/\/[^\s]+\.pdf)', caseSensitive: false);
    final m = reg.firstMatch(message);
    return m?.group(0);
  }

  @override
  Widget build(BuildContext context) {
    final t = AppLocalizations.of(context)!;
    final ctrl = context.watch<NotificationsController>();

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
          tooltip: t.back,
        ),
        title: Text(
          t.notificationsTitle,
          style: GoogleFonts.poppins(
            fontSize: 18.sp,
            fontWeight: FontWeight.w700,
            color: const Color(0xFF0F172A),
          ),
        ),
        centerTitle: true,
        actions: [
          GestureDetector(
            onTap: () async {
              try {
                await context
                    .read<NotificationsController>()
                    .markAllReadPermanent();
                if (!context.mounted) return;
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(t.markedAllAsRead),
                    behavior: SnackBarBehavior.floating,
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10)),
                  ),
                );
              } catch (e) {
                if (!context.mounted) return;
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(t.failedWithError(e.toString())),
                    backgroundColor: const Color(0xFFEF4444),
                    behavior: SnackBarBehavior.floating,
                  ),
                );
              }
            },
            child: Container(
              margin: EdgeInsets.only(right: 12.w),
              padding: EdgeInsets.symmetric(horizontal: 10.w, vertical: 6.h),
              decoration: BoxDecoration(
                color: const Color(0xFFEFF6FF),
                borderRadius: BorderRadius.circular(8.r),
                border: Border.all(color: const Color(0xFFBFDBFE)),
              ),
              child: Icon(Icons.done_all_rounded,
                  size: 20.w, color: const Color(0xFF2563EB)),
            ),
          ),
        ],
      ),
      body: ctrl.isLoading
          ? const Center(child: CircularProgressIndicator())
          : (ctrl.error != null)
              ? Center(
                  child: Padding(
                    padding: EdgeInsets.all(16.w),
                    child: Text(
                      t.loadFailed(ctrl.error!),
                      style: GoogleFonts.poppins(
                          color: const Color(0xFFEF4444)),
                      textAlign: TextAlign.center,
                    ),
                  ),
                )
              : RefreshIndicator(
                  onRefresh: () async {
                    await ctrl.refresh();
                    if (_isVendor) {
                      await _loadDeliveries();
                      await _loadAllOrders();
                    }
                  },
                  color: const Color(0xFF2563EB),
                  child: Column(
                    children: [
                      SizedBox(height: 12.h),

                      // Tabs
                      SingleChildScrollView(
                        scrollDirection: Axis.horizontal,
                        padding: EdgeInsets.symmetric(horizontal: 16.w),
                        child: Row(
                          children: [
                            _tab(
                              t.tabAll,
                              ctrl.selectedTab ==
                                  NotificationsTab.all.key,
                              () => ctrl.changeTab(
                                  NotificationsTab.all.key),
                            ),
                            SizedBox(width: 8.w),
                            _tab(
                              t.tabUnread(ctrl.unreadCount),
                              ctrl.selectedTab ==
                                  NotificationsTab.unread.key,
                              () => ctrl.changeTab(
                                  NotificationsTab.unread.key),
                            ),
                            SizedBox(width: 8.w),
                            _tab(
                              t.tabOrders,
                              ctrl.selectedTab ==
                                  NotificationsTab.orders.key,
                              () => ctrl.changeTab(
                                  NotificationsTab.orders.key),
                            ),
                            SizedBox(width: 8.w),
                            _tab(
                              t.tabSystem,
                              ctrl.selectedTab ==
                                  NotificationsTab.system.key,
                              () => ctrl.changeTab(
                                  NotificationsTab.system.key),
                            ),
                            SizedBox(width: 8.w),
                            _tab(
                              'Reports',
                              ctrl.selectedTab ==
                                  NotificationsTab.reports.key,
                              () => ctrl.changeTab(
                                  NotificationsTab.reports.key),
                            ),
                            // Deliveries tab for vendors
                            if (_isVendor) ...[
                              SizedBox(width: 8.w),
                              _tab(
                                '${t.delivered} (${_deliveryItems.length})',
                                ctrl.selectedTab == 'Deliveries',
                                () => ctrl.changeTab('Deliveries'),
                              ),
                            ],
                          ],
                        ),
                      ),

                      SizedBox(height: 14.h),

                      // Content
                      Expanded(
                        child: ctrl.selectedTab == 'Deliveries'
                            ? _buildDeliveriesTab(t)
                            : (ctrl.selectedTab == NotificationsTab.orders.key && _isVendor)
                                ? _buildOrdersTab(t)
                                : _buildNotificationsList(ctrl, t),
                      ),
                    ],
                  ),
                ),
    );
  }

  // ─── Notifications List ──────────────────────────
  Widget _buildNotificationsList(
      NotificationsController ctrl, AppLocalizations t) {
    if (ctrl.notifications.isEmpty) {
      return ListView(
        physics: const AlwaysScrollableScrollPhysics(),
        children: [
          SizedBox(height: 80.h),
          Container(
            width: 64.w,
            height: 64.w,
            margin: EdgeInsets.symmetric(horizontal: 150.w),
            decoration: BoxDecoration(
              color: const Color(0xFFF1F5F9),
              borderRadius: BorderRadius.circular(18.r),
            ),
            child: Icon(Icons.notifications_off_rounded,
                size: 32.w, color: const Color(0xFF94A3B8)),
          ),
          SizedBox(height: 16.h),
          Center(
            child: Text(
              t.noNotificationsYet,
              style: GoogleFonts.poppins(
                fontSize: 16.sp,
                fontWeight: FontWeight.w600,
                color: const Color(0xFF334155),
              ),
              textAlign: TextAlign.center,
            ),
          ),
          SizedBox(height: 6.h),
          Center(
            child: Padding(
              padding: EdgeInsets.symmetric(horizontal: 24.w),
              child: Text(
                t.notificationsEmptySubtitle,
                style: GoogleFonts.poppins(
                  fontSize: 13.sp,
                  color: const Color(0xFF94A3B8),
                ),
                textAlign: TextAlign.center,
              ),
            ),
          ),
        ],
      );
    }

    return ListView.builder(
      physics: const AlwaysScrollableScrollPhysics(),
      padding: EdgeInsets.symmetric(horizontal: 16.w),
      itemCount: ctrl.notifications.length + 1,
      itemBuilder: (context, index) {
        if (index == ctrl.notifications.length) {
          return Padding(
            padding: EdgeInsets.all(24.w),
            child: Text(
              t.notificationsEnd,
              style: GoogleFonts.poppins(
                fontSize: 13.sp,
                color: const Color(0xFF94A3B8),
              ),
              textAlign: TextAlign.center,
            ),
          );
        }
        final n = ctrl.notifications[index];
        return _tile(context, n, ctrl);
      },
    );
  }

  // ─── Deliveries Tab ──────────────────────────
  Widget _buildDeliveriesTab(AppLocalizations t) {
    if (_loadingDeliveries) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_deliveryItems.isEmpty) {
      return ListView(
        physics: const AlwaysScrollableScrollPhysics(),
        children: [
          SizedBox(height: 80.h),
          Container(
            width: 64.w,
            height: 64.w,
            margin: EdgeInsets.symmetric(horizontal: 150.w),
            decoration: BoxDecoration(
              color: const Color(0xFFF0FDF4),
              borderRadius: BorderRadius.circular(18.r),
            ),
            child: Icon(Icons.check_circle_outline_rounded,
                size: 32.w, color: const Color(0xFF16A34A)),
          ),
          SizedBox(height: 16.h),
          Center(
            child: Text(
              t.noBookingsFound,
              style: GoogleFonts.poppins(
                fontSize: 16.sp,
                fontWeight: FontWeight.w600,
                color: const Color(0xFF334155),
              ),
            ),
          ),
          SizedBox(height: 6.h),
          Center(
            child: Text(
              'All confirmed bookings have been delivered',
              style: GoogleFonts.poppins(
                fontSize: 13.sp,
                color: const Color(0xFF94A3B8),
              ),
            ),
          ),
        ],
      );
    }

    final localeTag = Localizations.localeOf(context).toLanguageTag();

    return ListView.builder(
      physics: const AlwaysScrollableScrollPhysics(),
      padding: EdgeInsets.symmetric(horizontal: 16.w),
      itemCount: _deliveryItems.length,
      itemBuilder: (context, index) {
        final b = _deliveryItems[index];
        final timeText = (b.startTime != null && b.endTime != null)
            ? "${DateFormat('MMM dd, h:mm a', localeTag).format(b.startTime!)} – ${DateFormat('h:mm a', localeTag).format(b.endTime!)}"
            : "—";

        return Container(
          margin: EdgeInsets.only(bottom: 14.h),
          padding: EdgeInsets.all(16.w),
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
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // header row
              Row(
                children: [
                  Container(
                    width: 44.w,
                    height: 44.w,
                    decoration: BoxDecoration(
                      color: const Color(0xFFEFF6FF),
                      borderRadius: BorderRadius.circular(12.r),
                      border: Border.all(color: const Color(0xFFBFDBFE)),
                    ),
                    child: Icon(Icons.local_shipping_rounded,
                        size: 22.w, color: const Color(0xFF2563EB)),
                  ),
                  SizedBox(width: 12.w),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          t.bookingNumberTitle(b.bookingId),
                          style: GoogleFonts.poppins(
                            fontSize: 15.sp,
                            fontWeight: FontWeight.w700,
                            color: const Color(0xFF0F172A),
                          ),
                        ),
                        SizedBox(height: 2.h),
                        Text(
                          b.residentName,
                          style: GoogleFonts.poppins(
                            fontSize: 13.sp,
                            color: const Color(0xFF64748B),
                          ),
                        ),
                      ],
                    ),
                  ),
                  Container(
                    padding: EdgeInsets.symmetric(
                        horizontal: 10.w, vertical: 4.h),
                    decoration: BoxDecoration(
                      color: const Color(0xFFEFF6FF),
                      borderRadius: BorderRadius.circular(8.r),
                    ),
                    child: Text(
                      t.bookingStatusConfirmed,
                      style: GoogleFonts.poppins(
                        fontSize: 10.sp,
                        fontWeight: FontWeight.w700,
                        color: const Color(0xFF2563EB),
                      ),
                    ),
                  ),
                ],
              ),

              SizedBox(height: 12.h),

              // detail rows
              Container(
                padding: EdgeInsets.all(12.w),
                decoration: BoxDecoration(
                  color: const Color(0xFFF8FAFC),
                  borderRadius: BorderRadius.circular(12.r),
                ),
                child: Column(
                  children: [
                    _deliveryInfoRow(
                      Icons.location_on_outlined,
                      '${b.location}${b.wardName.trim().isNotEmpty ? " • ${b.wardName}" : ""}',
                    ),
                    SizedBox(height: 8.h),
                    _deliveryInfoRow(
                        Icons.access_time_rounded, timeText),
                    SizedBox(height: 8.h),
                    _deliveryInfoRow(Icons.water_drop_outlined,
                        t.tankerLabel(b.liters)),
                    if (b.residentPhone.trim().isNotEmpty) ...[
                      SizedBox(height: 8.h),
                      _deliveryInfoRow(
                          Icons.phone_outlined, b.residentPhone),
                    ],
                    if (b.price != null) ...[
                      SizedBox(height: 8.h),
                      _deliveryInfoRow(Icons.payments_outlined,
                          t.priceLabel(b.price.toString())),
                    ],
                  ],
                ),
              ),

              SizedBox(height: 14.h),

              // Mark Delivered button
              SizedBox(
                width: double.infinity,
                height: 44.h,
                child: ElevatedButton.icon(
                  onPressed:
                      _updatingDelivery ? null : () => _markDelivered(b.bookingId),
                  icon: _updatingDelivery
                      ? SizedBox(
                          width: 18.w,
                          height: 18.w,
                          child: const CircularProgressIndicator(
                              strokeWidth: 2, color: Colors.white),
                        )
                      : Icon(Icons.check_circle_rounded,
                          size: 20.w, color: Colors.white),
                  label: Text(
                    t.markDelivered,
                    style: GoogleFonts.poppins(
                      fontWeight: FontWeight.w600,
                      fontSize: 14.sp,
                    ),
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF16A34A),
                    foregroundColor: Colors.white,
                    elevation: 0,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12.r),
                    ),
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _deliveryInfoRow(IconData icon, String text) {
    return Row(
      children: [
        Icon(icon, size: 16.w, color: const Color(0xFF94A3B8)),
        SizedBox(width: 8.w),
        Expanded(
          child: Text(
            text,
            style: GoogleFonts.poppins(
              fontSize: 13.sp,
              color: const Color(0xFF475569),
            ),
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ],
    );
  }

  // ─── Orders Tab (Vendor) ─────────────────
  Widget _buildOrdersTab(AppLocalizations t) {
    if (_loadingOrders) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_allOrderItems.isEmpty) {
      return ListView(
        physics: const AlwaysScrollableScrollPhysics(),
        children: [
          SizedBox(height: 80.h),
          Container(
            width: 64.w,
            height: 64.w,
            margin: EdgeInsets.symmetric(horizontal: 150.w),
            decoration: BoxDecoration(
              color: const Color(0xFFEFF6FF),
              borderRadius: BorderRadius.circular(18.r),
            ),
            child: Icon(Icons.shopping_bag_outlined,
                size: 32.w, color: const Color(0xFF2563EB)),
          ),
          SizedBox(height: 16.h),
          Center(
            child: Text(
              t.noBookingsFound,
              style: GoogleFonts.poppins(
                fontSize: 16.sp,
                fontWeight: FontWeight.w600,
                color: const Color(0xFF334155),
              ),
            ),
          ),
        ],
      );
    }

    final localeTag = Localizations.localeOf(context).toLanguageTag();

    return ListView.builder(
      physics: const AlwaysScrollableScrollPhysics(),
      padding: EdgeInsets.symmetric(horizontal: 16.w),
      itemCount: _allOrderItems.length,
      itemBuilder: (context, index) {
        final b = _allOrderItems[index];

        // Status colors
        Color statusBg;
        Color statusFg;
        IconData statusIcon;
        switch (b.status) {
          case 'CONFIRMED':
            statusBg = const Color(0xFFEFF6FF);
            statusFg = const Color(0xFF2563EB);
            statusIcon = Icons.check_circle_outline_rounded;
            break;
          case 'DELIVERED':
            statusBg = const Color(0xFFF5F3FF);
            statusFg = const Color(0xFF7C3AED);
            statusIcon = Icons.local_shipping_rounded;
            break;
          case 'COMPLETED':
            statusBg = const Color(0xFFF0FDF4);
            statusFg = const Color(0xFF16A34A);
            statusIcon = Icons.task_alt_rounded;
            break;
          case 'CANCELLED':
            statusBg = const Color(0xFFFEF2F2);
            statusFg = const Color(0xFFEF4444);
            statusIcon = Icons.cancel_outlined;
            break;
          default:
            statusBg = const Color(0xFFF1F5F9);
            statusFg = const Color(0xFF64748B);
            statusIcon = Icons.info_outline_rounded;
        }

        final timeText = (b.startTime != null && b.endTime != null)
            ? "${DateFormat('MMM dd, h:mm a', localeTag).format(b.startTime!)} – ${DateFormat('h:mm a', localeTag).format(b.endTime!)}"
            : "—";

        return Container(
          margin: EdgeInsets.only(bottom: 14.h),
          padding: EdgeInsets.all(16.w),
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
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header: icon + booking ID + status badge
              Row(
                children: [
                  Container(
                    width: 42.w,
                    height: 42.w,
                    decoration: BoxDecoration(
                      color: statusBg,
                      borderRadius: BorderRadius.circular(12.r),
                    ),
                    child: Icon(statusIcon, size: 22.w, color: statusFg),
                  ),
                  SizedBox(width: 12.w),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          t.bookingNumberTitle(b.bookingId),
                          style: GoogleFonts.poppins(
                            fontSize: 15.sp,
                            fontWeight: FontWeight.w700,
                            color: const Color(0xFF0F172A),
                          ),
                        ),
                        SizedBox(height: 2.h),
                        Text(
                          b.residentName,
                          style: GoogleFonts.poppins(
                            fontSize: 13.sp,
                            color: const Color(0xFF64748B),
                          ),
                        ),
                      ],
                    ),
                  ),
                  Container(
                    padding: EdgeInsets.symmetric(
                        horizontal: 10.w, vertical: 4.h),
                    decoration: BoxDecoration(
                      color: statusBg,
                      borderRadius: BorderRadius.circular(8.r),
                      border: Border.all(
                          color: statusFg.withValues(alpha: 0.3)),
                    ),
                    child: Text(
                      b.status,
                      style: GoogleFonts.poppins(
                        fontSize: 10.sp,
                        fontWeight: FontWeight.w700,
                        color: statusFg,
                      ),
                    ),
                  ),
                ],
              ),

              SizedBox(height: 12.h),

              // Detail rows
              Container(
                padding: EdgeInsets.all(12.w),
                decoration: BoxDecoration(
                  color: const Color(0xFFF8FAFC),
                  borderRadius: BorderRadius.circular(12.r),
                ),
                child: Column(
                  children: [
                    _deliveryInfoRow(
                      Icons.location_on_outlined,
                      '${b.location}${b.wardName.trim().isNotEmpty ? " • ${b.wardName}" : ""}',
                    ),
                    SizedBox(height: 6.h),
                    _deliveryInfoRow(Icons.access_time_rounded, timeText),
                    SizedBox(height: 6.h),
                    _deliveryInfoRow(
                        Icons.water_drop_outlined, t.tankerLabel(b.liters)),
                    if (b.price != null) ...[
                      SizedBox(height: 6.h),
                      _deliveryInfoRow(Icons.payments_outlined,
                          t.priceLabel(b.price.toString())),
                    ],
                  ],
                ),
              ),

              // Mark Delivered button for confirmed orders
              if (b.canMarkDelivered) ...[
                SizedBox(height: 12.h),
                SizedBox(
                  width: double.infinity,
                  height: 42.h,
                  child: ElevatedButton.icon(
                    onPressed: _updatingDelivery
                        ? null
                        : () => _markDelivered(b.bookingId),
                    icon: _updatingDelivery
                        ? SizedBox(
                            width: 16.w,
                            height: 16.w,
                            child: const CircularProgressIndicator(
                                strokeWidth: 2, color: Colors.white),
                          )
                        : Icon(Icons.check_circle_rounded,
                            size: 18.w, color: Colors.white),
                    label: Text(
                      t.markDelivered,
                      style: GoogleFonts.poppins(
                        fontWeight: FontWeight.w600,
                        fontSize: 13.sp,
                      ),
                    ),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF16A34A),
                      foregroundColor: Colors.white,
                      elevation: 0,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10.r),
                      ),
                    ),
                  ),
                ),
              ],
            ],
          ),
        );
      },
    );
  }


  Widget _tab(String label, bool selected, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 8.h),
        decoration: BoxDecoration(
          color: selected ? const Color(0xFF2563EB) : Colors.white,
          borderRadius: BorderRadius.circular(10.r),
          border: Border.all(
            color: selected
                ? const Color(0xFF2563EB)
                : const Color(0xFFE2E8F0),
          ),
          boxShadow: selected
              ? [
                  BoxShadow(
                    color: const Color(0xFF2563EB).withValues(alpha: 0.2),
                    blurRadius: 8,
                    offset: const Offset(0, 3),
                  ),
                ]
              : [],
        ),
        child: Text(
          label,
          style: GoogleFonts.poppins(
            fontSize: 13.sp,
            fontWeight: FontWeight.w600,
            color: selected ? Colors.white : const Color(0xFF64748B),
          ),
        ),
      ),
    );
  }

  // ─── Notification Tile ───────────────────
  Widget _tile(BuildContext context, AppNotification n,
      NotificationsController ctrl) {
    final timeAgo = ctrl.timeAgoLocalized(context, n.createdAt);
    final pdfUrl = _extractPdfUrl(n.message);

    return GestureDetector(
      onTap: () async {
        _openDetailSheet(context, n);
        try {
          await ctrl.markAsReadPermanent(n.id);
        } catch (_) {}
      },
      child: Container(
        margin: EdgeInsets.only(bottom: 12.h),
        padding: EdgeInsets.all(16.w),
        decoration: BoxDecoration(
          color: n.isUnread ? const Color(0xFFFAFCFF) : Colors.white,
          borderRadius: BorderRadius.circular(16.r),
          border: Border.all(
            color: n.isUnread
                ? const Color(0xFFBFDBFE)
                : const Color(0xFFE2E8F0),
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.04),
              blurRadius: 10,
              offset: const Offset(0, 3),
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
                color: n.iconColor.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(12.r),
              ),
              child: Icon(n.icon, color: n.iconColor, size: 22.w),
            ),
            SizedBox(width: 12.w),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      if (n.isUnread) ...[
                        Container(
                          width: 8.w,
                          height: 8.w,
                          decoration: const BoxDecoration(
                            color: Color(0xFF2563EB),
                            shape: BoxShape.circle,
                          ),
                        ),
                        SizedBox(width: 6.w),
                      ],
                      Expanded(
                        child: Text(
                          n.title,
                          style: GoogleFonts.poppins(
                            fontSize: 14.sp,
                            fontWeight: FontWeight.w700,
                            color: const Color(0xFF0F172A),
                          ),
                        ),
                      ),
                      Text(
                        timeAgo,
                        style: GoogleFonts.poppins(
                          fontSize: 11.sp,
                          color: const Color(0xFF94A3B8),
                        ),
                      ),
                    ],
                  ),
                  SizedBox(height: 4.h),
                  Text(
                    n.message,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: GoogleFonts.poppins(
                      fontSize: 13.sp,
                      color: const Color(0xFF64748B),
                    ),
                  ),
                  if (pdfUrl != null) ...[
                    SizedBox(height: 8.h),
                    Container(
                      padding: EdgeInsets.symmetric(
                          horizontal: 10.w, vertical: 5.h),
                      decoration: BoxDecoration(
                        color: const Color(0xFFFEF2F2),
                        borderRadius: BorderRadius.circular(8.r),
                        border: Border.all(
                            color: const Color(0xFFFECACA)),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.picture_as_pdf_rounded,
                              color: const Color(0xFFEF4444),
                              size: 14.w),
                          SizedBox(width: 4.w),
                          Text(
                            "PDF attached",
                            style: GoogleFonts.poppins(
                              fontSize: 11.sp,
                              fontWeight: FontWeight.w600,
                              color: const Color(0xFFEF4444),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                  if (n.ward.trim().isNotEmpty) ...[
                    SizedBox(height: 4.h),
                    Row(
                      children: [
                        Icon(Icons.location_on_outlined,
                            size: 12.w,
                            color: const Color(0xFF94A3B8)),
                        SizedBox(width: 4.w),
                        Expanded(
                          child: Text(
                            n.ward,
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
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ─── Detail Bottom Sheet ─────────────────
  void _openDetailSheet(BuildContext context, AppNotification n) {
    final t = AppLocalizations.of(context)!;
    final pdfUrl = _extractPdfUrl(n.message);

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) {
        final formatted =
            DateFormat('MMM dd, yyyy • h:mm a').format(n.createdAt.toLocal());

        return Container(
          constraints: BoxConstraints(
            maxHeight: MediaQuery.of(context).size.height * 0.8,
          ),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius:
                BorderRadius.vertical(top: Radius.circular(24.r)),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // drag handle
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
                  padding: EdgeInsets.only(
                    left: 20.w,
                    right: 20.w,
                    top: 20.h,
                    bottom:
                        MediaQuery.of(context).viewInsets.bottom + 24.h,
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // icon + title
                      Row(
                        children: [
                          Container(
                            width: 44.w,
                            height: 44.w,
                            decoration: BoxDecoration(
                              color:
                                  n.iconColor.withValues(alpha: 0.12),
                              borderRadius: BorderRadius.circular(12.r),
                            ),
                            child: Icon(n.icon, color: n.iconColor,
                                size: 22.w),
                          ),
                          SizedBox(width: 12.w),
                          Expanded(
                            child: Text(
                              n.title,
                              style: GoogleFonts.poppins(
                                fontSize: 18.sp,
                                fontWeight: FontWeight.w700,
                                color: const Color(0xFF0F172A),
                              ),
                            ),
                          ),
                        ],
                      ),
                      SizedBox(height: 14.h),

                      // info rows
                      _sheetInfoRow(
                          Icons.calendar_today_rounded, formatted),
                      if (n.ward.trim().isNotEmpty)
                        _sheetInfoRow(
                            Icons.location_on_outlined, n.ward),
                      SizedBox(height: 12.h),

                      // divider
                      Container(
                          height: 1,
                          color: const Color(0xFFE2E8F0)),
                      SizedBox(height: 12.h),

                      // message
                      Container(
                        width: double.infinity,
                        padding: EdgeInsets.all(14.w),
                        decoration: BoxDecoration(
                          color: const Color(0xFFF8FAFC),
                          borderRadius: BorderRadius.circular(12.r),
                          border: Border.all(
                              color: const Color(0xFFE2E8F0)),
                        ),
                        child: Text(
                          n.message,
                          style: GoogleFonts.poppins(
                            fontSize: 14.sp,
                            color: const Color(0xFF475569),
                            height: 1.5,
                          ),
                        ),
                      ),

                      // PDF button
                      if (pdfUrl != null) ...[
                        SizedBox(height: 16.h),
                        SizedBox(
                          width: double.infinity,
                          height: 44.h,
                          child: ElevatedButton.icon(
                            icon: Icon(Icons.picture_as_pdf_rounded,
                                size: 20.w),
                            label: Text(
                              "View PDF",
                              style: GoogleFonts.poppins(
                                  fontWeight: FontWeight.w600),
                            ),
                            onPressed: () {
                              Navigator.pop(context);
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (_) => PdfViewerScreen(
                                    pdfUrl: pdfUrl,
                                    title: n.title,
                                  ),
                                ),
                              );
                            },
                            style: ElevatedButton.styleFrom(
                              backgroundColor:
                                  const Color(0xFFEF4444),
                              foregroundColor: Colors.white,
                              elevation: 0,
                              shape: RoundedRectangleBorder(
                                borderRadius:
                                    BorderRadius.circular(12.r),
                              ),
                            ),
                          ),
                        ),
                      ],

                      SizedBox(height: 18.h),

                      // close
                      SizedBox(
                        width: double.infinity,
                        height: 44.h,
                        child: OutlinedButton(
                          onPressed: () => Navigator.pop(context),
                          style: OutlinedButton.styleFrom(
                            foregroundColor: const Color(0xFF475569),
                            side: const BorderSide(
                                color: Color(0xFFE2E8F0)),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12.r),
                            ),
                          ),
                          child: Text(
                            t.close,
                            style: GoogleFonts.poppins(
                                fontWeight: FontWeight.w600),
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
      },
    );
  }

  Widget _sheetInfoRow(IconData icon, String label) {
    return Padding(
      padding: EdgeInsets.only(bottom: 8.h),
      child: Row(
        children: [
          Icon(icon, size: 16.w, color: const Color(0xFF94A3B8)),
          SizedBox(width: 8.w),
          Expanded(
            child: Text(
              label,
              style: GoogleFonts.poppins(
                fontSize: 13.sp,
                color: const Color(0xFF475569),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

enum NotificationsTab {
  all('All'),
  unread('Unread'),
  orders('Orders'),
  system('System'),
  reports('Reports');

  const NotificationsTab(this.key);
  final String key;
}