import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import 'package:fyp/features/shared/notifications/models/notification_model.dart';
import '../controllers/notifications_controller.dart';

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

class _View extends StatelessWidget {
  const _View();

  @override
  Widget build(BuildContext context) {
    final ctrl = context.watch<NotificationsController>();

    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: Icon(
            Icons.arrow_back_ios_new_rounded,
            color: Colors.black,
            size: 22.w,
          ),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          'Notifications',
          style: GoogleFonts.poppins(
            fontSize: 20.sp,
            fontWeight: FontWeight.w600,
            color: Colors.black,
          ),
        ),
        centerTitle: true,
        actions: [
          IconButton(
            icon: Icon(
              Icons.check_circle_outline_rounded,
              color: Colors.blue,
              size: 26.w,
            ),
            onPressed: () async {
              try {
                await context
                    .read<NotificationsController>()
                    .markAllReadPermanent();
                if (!context.mounted) return;
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text("Marked all as read")),
                );
              } catch (e) {
                if (!context.mounted) return;
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text("Failed: $e"),
                    backgroundColor: Colors.red,
                  ),
                );
              }
            },
          ),
        ],
      ),
      body: ctrl.isLoading
          ? const Center(child: CircularProgressIndicator())
          : (ctrl.error != null)
          ? Center(child: Text(ctrl.error!))
          : RefreshIndicator(
              onRefresh: ctrl.refresh,
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
                          "All",
                          ctrl.selectedTab == "All",
                          () => ctrl.changeTab("All"),
                        ),
                        SizedBox(width: 12.w),
                        _tab(
                          "Unread (${ctrl.unreadCount})",
                          ctrl.selectedTab == "Unread",
                          () => ctrl.changeTab("Unread"),
                        ),
                        SizedBox(width: 12.w),
                        _tab(
                          "Orders",
                          ctrl.selectedTab == "Orders",
                          () => ctrl.changeTab("Orders"),
                        ),
                        SizedBox(width: 12.w),
                        _tab(
                          "System",
                          ctrl.selectedTab == "System",
                          () => ctrl.changeTab("System"),
                        ),
                      ],
                    ),
                  ),

                  SizedBox(height: 16.h),

                  Expanded(
                    child: ctrl.notifications.isEmpty
                        ? ListView(
                            physics: const AlwaysScrollableScrollPhysics(),
                            children: [
                              SizedBox(height: 80.h),
                              Icon(
                                Icons.notifications_off,
                                size: 80.w,
                                color: Colors.grey[400],
                              ),
                              SizedBox(height: 16.h),
                              Center(
                                child: Text(
                                  "No notifications yet",
                                  style: GoogleFonts.poppins(
                                    fontSize: 16.sp,
                                    color: Colors.grey[700],
                                  ),
                                ),
                              ),
                              SizedBox(height: 6.h),
                              Center(
                                child: Text(
                                  "We'll notify you when something new arrives",
                                  style: GoogleFonts.poppins(
                                    fontSize: 13.sp,
                                    color: Colors.grey[500],
                                  ),
                                ),
                              ),
                            ],
                          )
                        : ListView.builder(
                            physics: const AlwaysScrollableScrollPhysics(),
                            padding: EdgeInsets.symmetric(horizontal: 16.w),
                            itemCount: ctrl.notifications.length + 1,
                            itemBuilder: (context, index) {
                              if (index == ctrl.notifications.length) {
                                return Padding(
                                  padding: EdgeInsets.all(24.w),
                                  child: Text(
                                    "You've reached the end of your notifications",
                                    style: GoogleFonts.poppins(
                                      fontSize: 13.sp,
                                      color: Colors.grey[600],
                                    ),
                                    textAlign: TextAlign.center,
                                  ),
                                );
                              }

                              final n = ctrl.notifications[index];
                              return _tile(context, n, ctrl);
                            },
                          ),
                  ),
                ],
              ),
            ),
    );
  }

  Widget _tab(String label, bool selected, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: EdgeInsets.symmetric(horizontal: 20.w, vertical: 10.h),
        decoration: BoxDecoration(
          color: selected ? Colors.white : Colors.transparent,
          borderRadius: BorderRadius.circular(30.r),
          border: Border.all(
            color: selected ? Colors.orange : Colors.transparent,
          ),
          boxShadow: selected
              ? [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.04),
                    blurRadius: 8,
                    offset: Offset(0, 3.h),
                  ),
                ]
              : [],
        ),
        child: Text(
          label,
          style: GoogleFonts.poppins(
            fontSize: 14.sp,
            fontWeight: FontWeight.w600,
            color: selected ? Colors.orange : Colors.grey[700],
          ),
        ),
      ),
    );
  }

  Widget _tile(
    BuildContext context,
    AppNotification n,
    NotificationsController ctrl,
  ) {
    final timeAgo = ctrl.timeAgo(n.createdAt);
    final bubbleColor = n.iconColor.withOpacity(0.10);

    return InkWell(
      borderRadius: BorderRadius.circular(16.r),
      onTap: () async {
        // Open detail immediately
        _openDetailSheet(context, n);

        // Mark read permanently (DB)
        try {
          await ctrl.markAsReadPermanent(n.id);
        } catch (_) {
          // If fails, keep UI read; next refresh may revert depending on backend
        }
      },
      child: Container(
        margin: EdgeInsets.only(bottom: 12.h),
        padding: EdgeInsets.all(16.w),
        decoration: BoxDecoration(
          color: n.isUnread ? const Color(0xFFF7FBFF) : Colors.white,
          borderRadius: BorderRadius.circular(16.r),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.04),
              blurRadius: 10,
              offset: Offset(0, 4.h),
            ),
          ],
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // icon bubble
            Container(
              width: 48.w,
              height: 48.w,
              decoration: BoxDecoration(
                color: bubbleColor,
                borderRadius: BorderRadius.circular(12.r),
              ),
              child: Icon(n.icon, color: n.iconColor, size: 24.w),
            ),
            SizedBox(width: 12.w),

            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      if (n.isUnread)
                        Container(
                          width: 8.w,
                          height: 8.w,
                          decoration: const BoxDecoration(
                            color: Colors.blue,
                            shape: BoxShape.circle,
                          ),
                        ),
                      if (n.isUnread) SizedBox(width: 8.w),
                      Expanded(
                        child: Text(
                          n.title,
                          style: GoogleFonts.poppins(
                            fontSize: 15.sp,
                            fontWeight: FontWeight.w600,
                            color: Colors.black,
                          ),
                        ),
                      ),
                      Text(
                        timeAgo,
                        style: GoogleFonts.poppins(
                          fontSize: 11.sp,
                          color: Colors.grey[500],
                        ),
                      ),
                    ],
                  ),
                  SizedBox(height: 6.h),
                  Text(
                    n.message,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: GoogleFonts.poppins(
                      fontSize: 13.sp,
                      color: Colors.grey[700],
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _openDetailSheet(BuildContext context, AppNotification n) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) {
        final formatted = DateFormat(
          'MMM dd, yyyy • h:mm a',
        ).format(n.createdAt.toLocal());

        return Container(
          padding: EdgeInsets.only(
            left: 16,
            right: 16,
            top: 12,
            bottom: MediaQuery.of(context).viewInsets.bottom + 24,
          ),
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.vertical(top: Radius.circular(22)),
          ),
          child: SafeArea(
            top: false,
            child: SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Center(
                    child: Container(
                      width: 50,
                      height: 5,
                      margin: const EdgeInsets.only(bottom: 14),
                      decoration: BoxDecoration(
                        color: Colors.grey[300],
                        borderRadius: BorderRadius.circular(100),
                      ),
                    ),
                  ),
                  Row(
                    children: [
                      Container(
                        width: 44,
                        height: 44,
                        decoration: BoxDecoration(
                          color: n.iconColor.withOpacity(0.12),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Icon(n.icon, color: n.iconColor),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          n.title,
                          style: GoogleFonts.poppins(
                            fontSize: 16,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Text(
                    formatted,
                    style: GoogleFonts.poppins(
                      color: Colors.grey[600],
                      fontSize: 12,
                    ),
                  ),
                  const SizedBox(height: 14),
                  Text(
                    n.message,
                    style: GoogleFonts.poppins(
                      fontSize: 14,
                      color: Colors.grey[800],
                    ),
                  ),
                  const SizedBox(height: 18),
                  Align(
                    alignment: Alignment.centerRight,
                    child: TextButton(
                      onPressed: () => Navigator.pop(context),
                      child: Text(
                        "Close",
                        style: GoogleFonts.poppins(
                          color: Colors.blue,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}
