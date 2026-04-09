import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import 'package:fyp/l10n/app_localizations.dart';
import '../services/booking_service.dart';
import '../controllers/my_bookings_history_controller.dart';
import 'package:fyp/features/resident/bookings/views/booking_detail_screen.dart';

class MyBookingsHistoryScreen extends StatelessWidget {
  final bool isTab;
  const MyBookingsHistoryScreen({super.key, this.isTab = false});

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (_) => MyBookingsHistoryController(),
      child: _View(isTab),
    );
  }
}

class _View extends StatelessWidget {
  final bool isTab;
  const _View(this.isTab);

  Color _statusColor(String s) {
    switch (s.toUpperCase()) {
      case "COMPLETED":
        return Colors.green;
      case "CANCELLED":
        return Colors.red;
      case "CONFIRMED":
        return Colors.blue;
      case "PENDING":
        return Colors.orange;
      default:
        return Colors.grey;
    }
  }

  String _statusLabel(AppLocalizations t, String s) {
    switch (s.toUpperCase()) {
      case "COMPLETED":
        return t.bookingStatusCompleted;
      case "CANCELLED":
        return t.bookingStatusCancelled;
      case "CONFIRMED":
        return t.bookingStatusConfirmed;
      case "PENDING":
        return t.bookingStatusPending;
      default:
        return s;
    }
  }

  @override
  Widget build(BuildContext context) {
    final t = AppLocalizations.of(context)!;
    final ctrl = context.watch<MyBookingsHistoryController>();

    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: isTab
            ? null
            : IconButton(
                icon: Icon(
                  Icons.arrow_back_ios_new_rounded,
                  color: Colors.black,
                  size: 24.w,
                ),
                onPressed: () => Navigator.pop(context),
                tooltip: t.back,
              ),
        title: Text(
          t.myBookingsTitle,
          style: GoogleFonts.poppins(
            fontSize: 20.sp,
            fontWeight: FontWeight.w600,
          ),
        ),
        centerTitle: true,
      ),
      body: ctrl.isLoading
          ? const Center(child: CircularProgressIndicator())
          : (ctrl.error != null)
          ? Center(
        child: Padding(
          padding: EdgeInsets.all(16.w),
          child: Text(
            t.loadFailed(ctrl.error!),
            style: GoogleFonts.poppins(color: Colors.red),
            textAlign: TextAlign.center,
          ),
        ),
      )
          : RefreshIndicator(
        onRefresh: ctrl.refresh,
        child: ListView(
          padding: EdgeInsets.symmetric(horizontal: 16.w),
          children: [
            SizedBox(height: 16.h),
            Center(
              child: Container(
                padding: EdgeInsets.symmetric(
                  horizontal: 24.w,
                  vertical: 10.h,
                ),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(30.r),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.05),
                      blurRadius: 10,
                      offset: Offset(0, 4.h),
                    ),
                  ],
                ),
                child: Text(
                  t.history,
                  style: GoogleFonts.poppins(
                    fontSize: 14.sp,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ),
            SizedBox(height: 24.h),

            if (ctrl.grouped.isEmpty)
              Padding(
                padding: EdgeInsets.only(top: 60.h),
                child: Column(
                  children: [
                    Icon(
                      Icons.receipt_long,
                      size: 72.w,
                      color: Colors.grey[400],
                    ),
                    SizedBox(height: 12.h),
                    Text(
                      t.noBookingsYet,
                      style: GoogleFonts.poppins(
                        fontSize: 16.sp,
                        color: Colors.grey[700],
                        fontWeight: FontWeight.w600,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ],
                ),
              )
            else
              ...ctrl.grouped.entries.map((entry) {
                return Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      entry.key,
                      style: GoogleFonts.poppins(
                        fontSize: 16.sp,
                        fontWeight: FontWeight.w700,
                        color: Colors.grey[800],
                      ),
                    ),
                    SizedBox(height: 12.h),
                    ...entry.value.map((b) => _card(context, t, b)),
                    SizedBox(height: 24.h),
                  ],
                );
              }),

            SizedBox(height: 80.h),
          ],
        ),
      ),
    );
  }

  Widget _card(BuildContext context, AppLocalizations t, BookingSummary b) {
    final statusColor = _statusColor(b.status);
    final statusText = _statusLabel(t, b.status);

    final localeTag = Localizations.localeOf(context).toLanguageTag();
    final dateText = DateFormat('MMM dd, h:mm a', localeTag).format(
      b.slotStart.toLocal(),
    );

    return Container(
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
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              CircleAvatar(
                radius: 24.r,
                backgroundColor: Colors.blue[50],
                child: Icon(
                  Icons.water_drop_rounded,
                  color: Colors.blue,
                  size: 28.w,
                ),
              ),
              SizedBox(width: 12.w),
              Expanded(
                child: Text(
                  b.vendorName,
                  style: GoogleFonts.poppins(
                    fontSize: 16.sp,
                    fontWeight: FontWeight.w700,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              Container(
                padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 6.h),
                decoration: BoxDecoration(
                  color: statusColor.withOpacity(0.12),
                  borderRadius: BorderRadius.circular(20.r),
                ),
                child: Text(
                  statusText,
                  style: GoogleFonts.poppins(
                    fontSize: 12.sp,
                    color: statusColor,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
          SizedBox(height: 8.h),
          Text(
            b.location,
            style: GoogleFonts.poppins(
              fontSize: 14.sp,
              color: Colors.grey[700],
            ),
            overflow: TextOverflow.ellipsis,
            maxLines: 2,
          ),
          SizedBox(height: 12.h),
          Row(
            children: [
              Icon(
                Icons.calendar_today_outlined,
                size: 16.w,
                color: Colors.grey[600],
              ),
              SizedBox(width: 6.w),
              Expanded(
                child: Text(
                  dateText,
                  style: GoogleFonts.poppins(
                    fontSize: 13.sp,
                    color: Colors.grey[700],
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
          SizedBox(height: 8.h),
          Row(
            children: [
              Icon(Icons.water_drop_outlined, size: 16.w, color: Colors.blue),
              SizedBox(width: 6.w),
              Text(
                t.liters(b.liters),
                style: GoogleFonts.poppins(
                  fontSize: 13.sp,
                  color: Colors.grey[800],
                ),
              ),
              const Spacer(),
              if (b.price != null)
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(
                      t.nprAmount(b.price.toString()),
                      style: GoogleFonts.poppins(
                        fontSize: 14.sp,
                        fontWeight: FontWeight.w600,
                        color: Colors.blue,
                      ),
                    ),
                    SizedBox(height: 2.h),
                    Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          b.isPaid ? Icons.check_circle_rounded : Icons.pending_actions_rounded,
                          size: 12.sp,
                          color: b.isPaid ? Colors.green : Colors.orange,
                        ),
                        SizedBox(width: 4.w),
                        Text(
                          b.isPaid
                              ? (b.paymentMethod != null && b.paymentMethod!.toUpperCase() == 'ESEWA'
                                  ? 'Paid via eSewa'
                                  : 'Paid')
                              : 'Unpaid (Cash on Delivery)',
                          style: GoogleFonts.poppins(
                            fontSize: 11.sp,
                            fontWeight: FontWeight.w500,
                            color: b.isPaid ? Colors.green : Colors.orange,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
            ],
          ),
          SizedBox(height: 16.h),
          Wrap(
            alignment: WrapAlignment.end,
            spacing: 10.w,
            runSpacing: 6.h,
            children: [
              TextButton(
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => BookingDetailScreen(bookingId: b.bookingId),
                    ),
                  );
                },
                child: Text(
                  t.viewDetails,
                  style: GoogleFonts.poppins(
                    color: Colors.blue,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
              if (b.canRebook)
                TextButton.icon(
                  onPressed: () {
                    // TODO: implement re-book navigation if needed
                  },
                  icon: Icon(
                    Icons.refresh_rounded,
                    size: 18.w,
                    color: Colors.blue,
                  ),
                  label: Text(
                    t.rebook,
                    style: GoogleFonts.poppins(
                      color: Colors.blue,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
            ],
          ),
        ],
      ),
    );
  }
}