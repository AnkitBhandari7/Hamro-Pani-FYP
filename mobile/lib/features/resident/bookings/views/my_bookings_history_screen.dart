import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import '../services/booking_service.dart';
import '../controllers/my_bookings_history_controller.dart';
import 'package:fyp/features/resident/bookings/views/booking_detail_screen.dart';

class MyBookingsHistoryScreen extends StatelessWidget {
  const MyBookingsHistoryScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (_) => MyBookingsHistoryController(),
      child: const _View(),
    );
  }
}

class _View extends StatelessWidget {
  const _View();

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

  @override
  Widget build(BuildContext context) {
    final ctrl = context.watch<MyBookingsHistoryController>();

    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: Icon(
            Icons.arrow_back_ios_new_rounded,
            color: Colors.black,
            size: 24.w,
          ),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          'My Bookings',
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
          ? Center(child: Text(ctrl.error!))
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
                        "History",
                        style: GoogleFonts.poppins(
                          fontSize: 14.sp,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ),
                  SizedBox(height: 24.h),
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
                        ...entry.value.map((b) => _card(context, b)),
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

  Widget _card(BuildContext context, BookingSummary b) {
    final statusColor = _statusColor(b.status);

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
                ),
              ),
              Container(
                padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 6.h),
                decoration: BoxDecoration(
                  color: statusColor.withOpacity(0.12),
                  borderRadius: BorderRadius.circular(20.r),
                ),
                child: Text(
                  b.status[0] + b.status.substring(1).toLowerCase(),
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
              Text(
                DateFormat('MMM dd, h:mm a').format(b.slotStart.toLocal()),
                style: GoogleFonts.poppins(
                  fontSize: 13.sp,
                  color: Colors.grey[700],
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
                "${b.liters} Liters",
                style: GoogleFonts.poppins(
                  fontSize: 13.sp,
                  color: Colors.grey[800],
                ),
              ),
              const Spacer(),
              if (b.price != null)
                Text(
                  "NRs. ${b.price}",
                  style: GoogleFonts.poppins(
                    fontSize: 14.sp,
                    fontWeight: FontWeight.w600,
                    color: Colors.blue,
                  ),
                ),
            ],
          ),
          SizedBox(height: 16.h),
          Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              TextButton(
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) =>
                          BookingDetailScreen(bookingId: b.bookingId),
                    ),
                  );
                },
                child: Text(
                  "View Details",
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
                    "Re-book",
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
