import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import 'delivery_service.dart';
import 'vendor_delivery_history_controller.dart';

class VendorDeliveryHistoryScreen extends StatelessWidget {
  const VendorDeliveryHistoryScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (_) => VendorDeliveryHistoryController(),
      child: const _View(),
    );
  }
}

class _View extends StatelessWidget {
  const _View();

  Color _statusColor(String status) {
    switch (status.toUpperCase()) {
      case 'DELIVERED':
        return Colors.green;
      case 'CANCELLED':
        return Colors.red;
      case 'PENDING':
        return Colors.orange;
      default:
        return Colors.grey;
    }
  }

  @override
  Widget build(BuildContext context) {
    final ctrl = context.watch<VendorDeliveryHistoryController>();

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
          'Delivery History',
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

                  Row(
                    children: [
                      Expanded(
                        child: _statCard(
                          title: "TOTAL DELIVERIES",
                          value: ctrl.stats.totalDeliveries.toString(),
                          icon: Icons.local_shipping_outlined,
                          color: Colors.blue,
                        ),
                      ),
                      SizedBox(width: 12.w),
                      Expanded(
                        child: _statCard(
                          title: "TOTAL EARNINGS",
                          value:
                              "NPR ${ctrl.stats.totalEarnings.toStringAsFixed(0)}",
                          icon: Icons.currency_rupee_rounded,
                          color: Colors.green,
                        ),
                      ),
                    ],
                  ),
                  SizedBox(height: 12.h),
                  _statCard(
                    title: "AVG RATING",
                    value: ctrl.stats.avgRating.toStringAsFixed(1),
                    icon: Icons.star_rounded,
                    color: Colors.amber,
                  ),

                  SizedBox(height: 20.h),

                  ...ctrl.deliveries.map((d) => _deliveryCard(d)),

                  SizedBox(height: 60.h),
                ],
              ),
            ),
    );
  }

  Widget _statCard({
    required String title,
    required String value,
    required IconData icon,
    required Color color,
  }) {
    return Container(
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
              Icon(icon, color: color, size: 20.w),
              SizedBox(width: 8.w),
              Text(
                title,
                style: GoogleFonts.poppins(
                  fontSize: 12.sp,
                  color: Colors.grey[700],
                ),
              ),
            ],
          ),
          SizedBox(height: 12.h),
          Text(
            value,
            style: GoogleFonts.poppins(
              fontSize: 24.sp,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }

  Widget _deliveryCard(Delivery d) {
    final statusColor = _statusColor(d.status);

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
                radius: 20.r,
                backgroundColor: Colors.blue[50],
                child: Icon(Icons.person, color: Colors.blue, size: 24.w),
              ),
              SizedBox(width: 12.w),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      d.customerName,
                      style: GoogleFonts.poppins(
                        fontSize: 16.sp,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    if (d.address.trim().isNotEmpty)
                      Text(
                        d.address,
                        style: GoogleFonts.poppins(
                          fontSize: 13.sp,
                          color: Colors.grey[700],
                        ),
                      ),
                  ],
                ),
              ),
              Container(
                padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 6.h),
                decoration: BoxDecoration(
                  color: statusColor.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(20.r),
                ),
                child: Text(
                  d.status,
                  style: GoogleFonts.poppins(
                    fontSize: 12.sp,
                    color: statusColor,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
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
                DateFormat('MMM dd, h:mm a').format(d.dateTime.toLocal()),
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
                "${d.quantityLiters} L",
                style: GoogleFonts.poppins(
                  fontSize: 14.sp,
                  color: Colors.grey[800],
                ),
              ),
              const Spacer(),
              Text(
                d.paymentMethod,
                style: GoogleFonts.poppins(
                  fontSize: 13.sp,
                  color: Colors.grey[700],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
