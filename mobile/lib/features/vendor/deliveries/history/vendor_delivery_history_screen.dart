import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import 'delivery_service.dart';
import 'vendor_delivery_history_controller.dart';

import 'package:fyp/l10n/app_localizations.dart';

class VendorDeliveryHistoryScreen extends StatelessWidget {
  final VoidCallback? onBack;
  const VendorDeliveryHistoryScreen({super.key, this.onBack});

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (_) => VendorDeliveryHistoryController(),
      child: _View(onBack: onBack),
    );
  }
}

class _View extends StatelessWidget {
  final VoidCallback? onBack;
  const _View({this.onBack});

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

  String _localizedStatus(AppLocalizations l10n, String status) {
    switch (status.toUpperCase()) {
      case 'DELIVERED':
        return l10n.statusDelivered;
      case 'CANCELLED':
        return l10n.statusCancelled;
      case 'PENDING':
        return l10n.statusPending;
      default:
        return status;
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final ctrl = context.watch<VendorDeliveryHistoryController>();

    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: onBack != null
            ? IconButton(
                icon: Icon(
                  Icons.arrow_back_ios_new_rounded,
                  color: Colors.black,
                  size: 24.w,
                ),
                onPressed: onBack,
                tooltip: l10n.back,
              )
            : null,
        title: Text(
          l10n.deliveryHistory,
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
            l10n.loadFailed(ctrl.error!),
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
            Row(
              children: [
                Expanded(
                  child: _statCard(
                    title: l10n.totalDeliveries.toUpperCase(),
                    value: ctrl.stats.totalDeliveries.toString(),
                    icon: Icons.local_shipping_outlined,
                    color: Colors.blue,
                  ),
                ),
                SizedBox(width: 12.w),
                Expanded(
                  child: _statCard(
                    title: l10n.totalEarnings.toUpperCase(),
                    value: l10n.nprAmount(
                      ctrl.stats.totalEarnings.toStringAsFixed(0),
                    ),
                    icon: Icons.currency_rupee_rounded,
                    color: Colors.green,
                  ),
                ),
              ],
            ),
            SizedBox(height: 12.h),
            _statCard(
              title: l10n.avgRating.toUpperCase(),
              value: ctrl.stats.avgRating.toStringAsFixed(1),
              icon: Icons.star_rounded,
              color: Colors.amber,
            ),
            SizedBox(height: 20.h),
            ...ctrl.deliveries.map((d) => _deliveryCard(l10n, d)),
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
              Expanded(
                child: Text(
                  title,
                  style: GoogleFonts.poppins(
                    fontSize: 12.sp,
                    color: Colors.grey[700],
                  ),
                  overflow: TextOverflow.ellipsis,
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

  Widget _deliveryCard(AppLocalizations l10n, Delivery d) {
    final statusColor = _statusColor(d.status);
    final statusLabel = _localizedStatus(l10n, d.status);

    final formattedDateTime =
    DateFormat('MMM dd, h:mm a').format(d.dateTime.toLocal());

    final payment = (d.paymentMethod.trim().isEmpty)
        ? l10n.notApplicable
        : d.paymentMethod;

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
                  statusLabel,
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
                formattedDateTime,
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
                l10n.liters(d.quantityLiters),
                style: GoogleFonts.poppins(
                  fontSize: 14.sp,
                  color: Colors.grey[800],
                ),
              ),
              const Spacer(),
              Text(
                payment,
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