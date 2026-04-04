import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import 'package:fyp/l10n/app_localizations.dart';
import '../controllers/complaint_detail_controller.dart';

class ComplaintDetailScreen extends StatelessWidget {
  const ComplaintDetailScreen({super.key, required this.complaintId});
  final int complaintId;

  Color _statusColor(String s) {
    switch (s.toUpperCase()) {
      case "RESOLVED":
        return const Color(0xFF16A34A);
      case "IN_REVIEW":
        return const Color(0xFF2563EB);
      case "REJECTED":
        return const Color(0xFFEF4444);
      case "OPEN":
        return const Color(0xFFF97316);
      default:
        return const Color(0xFF64748B);
    }
  }

  String _statusLabel(AppLocalizations t, String s) {
    switch (s.toUpperCase()) {
      case "RESOLVED":
        return t.complaintStatusResolved;
      case "IN_REVIEW":
        return t.complaintStatusInReview;
      case "REJECTED":
        return t.complaintStatusRejected;
      case "OPEN":
        return t.complaintStatusOpen;
      default:
        return s;
    }
  }

  @override
  Widget build(BuildContext context) {
    final t = AppLocalizations.of(context)!;
    final localeTag = Localizations.localeOf(context).toLanguageTag();

    return ChangeNotifierProvider(
      create: (_) => ComplaintDetailController(complaintId),
      child: Consumer<ComplaintDetailController>(
        builder: (context, ctrl, _) {
          if (ctrl.isLoading) {
            return const Scaffold(
              backgroundColor: Color(0xFFF8FAFC),
              body: Center(
                child: CircularProgressIndicator(color: Color(0xFF2563EB)),
              ),
            );
          }
          if (ctrl.detail == null) {
            return Scaffold(
              backgroundColor: const Color(0xFFF8FAFC),
              appBar: AppBar(
                backgroundColor: Colors.white,
                surfaceTintColor: Colors.transparent,
                title: Text(
                  t.complaintDetailTitle,
                  style: GoogleFonts.poppins(
                      fontWeight: FontWeight.w700,
                      color: const Color(0xFF0F172A),
                      fontSize: 18.sp),
                ),
                leading: IconButton(
                  icon: Icon(Icons.arrow_back_ios_rounded,
                      color: const Color(0xFF0F172A), size: 20.w),
                  onPressed: () => Navigator.pop(context),
                ),
              ),
              body: Center(
                child: Text(
                  ctrl.error ?? t.failedToLoad,
                  style: GoogleFonts.poppins(color: const Color(0xFF64748B)),
                ),
              ),
            );
          }

          final d = ctrl.detail!;
          final statusColor = _statusColor(d.status);
          final statusText = _statusLabel(t, d.status);

          return Scaffold(
            backgroundColor: const Color(0xFFF8FAFC),
            appBar: AppBar(
              backgroundColor: Colors.white,
              surfaceTintColor: Colors.transparent,
              elevation: 0,
              iconTheme: const IconThemeData(color: Color(0xFF0F172A)),
              centerTitle: true,
              leading: IconButton(
                icon: Icon(Icons.arrow_back_ios_rounded,
                    color: const Color(0xFF0F172A), size: 20.w),
                onPressed: () => Navigator.pop(context),
              ),
              title: Text(
                t.complaintNumberTitle(d.id),
                style: GoogleFonts.poppins(
                  fontSize: 18.sp,
                  fontWeight: FontWeight.w700,
                  color: const Color(0xFF0F172A),
                ),
              ),
            ),
            body: ListView(
              padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 20.h),
              children: [
                // ─── ISSUE DETAILS CARD ──────────────────
                Container(
                  padding: EdgeInsets.all(20.w),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(16.r),
                    border: Border.all(color: const Color(0xFFE2E8F0)),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.03),
                        blurRadius: 8,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Container(
                            padding: EdgeInsets.symmetric(
                              horizontal: 14.w,
                              vertical: 6.h,
                            ),
                            decoration: BoxDecoration(
                              color: statusColor.withValues(alpha: 0.1),
                              borderRadius: BorderRadius.circular(20.r),
                              border: Border.all(
                                  color: statusColor.withValues(alpha: 0.2)),
                            ),
                            child: Row(
                              children: [
                                Container(
                                  width: 6.w,
                                  height: 6.w,
                                  decoration: BoxDecoration(
                                    color: statusColor,
                                    shape: BoxShape.circle,
                                  ),
                                ),
                                SizedBox(width: 6.w),
                                Text(
                                  statusText.toUpperCase(),
                                  style: GoogleFonts.poppins(
                                    fontSize: 11.sp,
                                    color: statusColor,
                                    fontWeight: FontWeight.w700,
                                    letterSpacing: 0.5,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const Spacer(),
                          Row(
                            children: [
                              Icon(Icons.access_time_rounded,
                                  size: 14.w, color: const Color(0xFF94A3B8)),
                              SizedBox(width: 4.w),
                              Text(
                                DateFormat('MMM dd, h:mm a', localeTag)
                                    .format(d.createdAt.toLocal()),
                                style: GoogleFonts.poppins(
                                  fontSize: 12.sp,
                                  color: const Color(0xFF64748B),
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                      SizedBox(height: 16.h),
                      Divider(color: const Color(0xFFF1F5F9), height: 1),
                      SizedBox(height: 16.h),
                      
                      Text(
                        t.bookingNumberLine(d.bookingId),
                        style: GoogleFonts.poppins(
                            fontSize: 16.sp,
                            fontWeight: FontWeight.w700,
                            color: const Color(0xFF0F172A)),
                      ),
                      SizedBox(height: 12.h),
                      Text(
                        d.message,
                        style: GoogleFonts.poppins(
                          fontSize: 14.sp,
                          color: const Color(0xFF334155),
                          height: 1.5,
                        ),
                      ),
                    ],
                  ),
                ),
                SizedBox(height: 20.h),
                
                // ─── PHOTOS EXAMINER ────────────────────
                if (d.photoUrls.isNotEmpty)
                  Container(
                    padding: EdgeInsets.all(20.w),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(16.r),
                      border: Border.all(color: const Color(0xFFE2E8F0)),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.03),
                          blurRadius: 8,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Container(
                              padding: EdgeInsets.all(8.w),
                              decoration: BoxDecoration(
                                color: const Color(0xFFEFF6FF),
                                borderRadius: BorderRadius.circular(10.r),
                              ),
                              child: Icon(Icons.photo_library_outlined,
                                  size: 18.w, color: const Color(0xFF2563EB)),
                            ),
                            SizedBox(width: 10.w),
                            Text(
                              t.photos.toUpperCase(),
                              style: GoogleFonts.poppins(
                                fontSize: 13.sp,
                                fontWeight: FontWeight.w700,
                                color: const Color(0xFF334155),
                                letterSpacing: 0.5,
                              ),
                            ),
                          ],
                        ),
                        SizedBox(height: 16.h),
                        Wrap(
                          spacing: 12.w,
                          runSpacing: 12.h,
                          children: d.photoUrls.map((url) {
                            return GestureDetector(
                              onTap: () {
                                _showImageDialog(context, url);
                              },
                              child: Container(
                                decoration: BoxDecoration(
                                  borderRadius: BorderRadius.circular(12.r),
                                  border: Border.all(color: const Color(0xFFE2E8F0)),
                                ),
                                child: ClipRRect(
                                  borderRadius: BorderRadius.circular(12.r),
                                  child: Image.network(
                                    url,
                                    width: 110.w,
                                    height: 110.h,
                                    fit: BoxFit.cover,
                                    errorBuilder: (context, error, stackTrace) => Container(
                                      width: 110.w,
                                      height: 110.h,
                                      color: const Color(0xFFF1F5F9),
                                      child: Icon(Icons.broken_image_rounded,
                                          color: const Color(0xFF94A3B8), size: 28.w),
                                    ),
                                  ),
                                ),
                              ),
                            );
                          }).toList(),
                        ),
                      ],
                    ),
                  ),
              ],
            ),
          );
        },
      ),
    );
  }

  void _showImageDialog(BuildContext context, String url) {
    showDialog(
      context: context,
      builder: (_) => Dialog(
        backgroundColor: Colors.transparent,
        insetPadding: EdgeInsets.all(16.w),
        child: Stack(
          alignment: Alignment.center,
          children: [
            InteractiveViewer(
              clipBehavior: Clip.none,
              child: ClipRRect(
                borderRadius: BorderRadius.circular(16.r),
                child: Image.network(
                  url,
                  fit: BoxFit.contain,
                  errorBuilder: (context, error, stackTrace) => Container(
                    padding: EdgeInsets.all(40.w),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(16.r),
                    ),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.broken_image_rounded,
                            size: 40.w, color: const Color(0xFF94A3B8)),
                        SizedBox(height: 12.h),
                        Text(
                          "Failed to load image",
                          style: GoogleFonts.poppins(
                            color: const Color(0xFF64748B),
                            fontSize: 14.sp,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
            Positioned(
              top: 10.h,
              right: 10.w,
              child: GestureDetector(
                onTap: () => Navigator.pop(context),
                child: Container(
                  padding: EdgeInsets.all(8.w),
                  decoration: BoxDecoration(
                    color: Colors.black.withValues(alpha: 0.5),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(Icons.close_rounded, color: Colors.white, size: 24.w),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}