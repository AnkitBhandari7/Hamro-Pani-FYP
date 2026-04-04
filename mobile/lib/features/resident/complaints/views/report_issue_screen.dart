import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';

import 'package:fyp/core/routes/routes.dart';
import 'package:fyp/l10n/app_localizations.dart';

import '../controllers/report_issue_controller.dart';

class ReportIssueScreen extends StatelessWidget {
  const ReportIssueScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (_) => ReportIssueController(),
      child: const _ReportIssueView(),
    );
  }
}

class _ReportIssueView extends StatelessWidget {
  const _ReportIssueView();

  Future<void> _showPickPhotoSheet(
    BuildContext context,
    ReportIssueController ctrl,
  ) async {
    final t = AppLocalizations.of(context)!;

    await showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (sheetCtx) {
        return Container(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.vertical(top: Radius.circular(24.r)),
          ),
          child: SafeArea(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  margin: EdgeInsets.only(top: 12.h, bottom: 8.h),
                  width: 40.w,
                  height: 4.h,
                  decoration: BoxDecoration(
                    color: const Color(0xFFCBD5E1),
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
                Padding(
                  padding: EdgeInsets.symmetric(horizontal: 20.w, vertical: 12.h),
                  child: Row(
                    children: [
                      Text(
                        t.photoEvidence,
                        style: GoogleFonts.poppins(
                          fontSize: 18.sp,
                          fontWeight: FontWeight.w700,
                          color: const Color(0xFF0F172A),
                        ),
                      ),
                    ],
                  ),
                ),
                ListTile(
                  leading: Container(
                    padding: EdgeInsets.all(10.w),
                    decoration: BoxDecoration(
                      color: const Color(0xFF2563EB).withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(10.r),
                    ),
                    child: Icon(Icons.photo_library_rounded,
                        color: const Color(0xFF2563EB), size: 22.w),
                  ),
                  title: Text(
                    t.chooseFromGallery,
                    style: GoogleFonts.poppins(
                        fontSize: 15.sp,
                        fontWeight: FontWeight.w500,
                        color: const Color(0xFF334155)),
                  ),
                  onTap: () async {
                    Navigator.pop(sheetCtx);
                    await ctrl.addPhotosFromGallery();
                  },
                ),
                ListTile(
                  leading: Container(
                    padding: EdgeInsets.all(10.w),
                    decoration: BoxDecoration(
                      color: const Color(0xFF7C3AED).withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(10.r),
                    ),
                    child: Icon(Icons.camera_alt_rounded,
                        color: const Color(0xFF7C3AED), size: 22.w),
                  ),
                  title: Text(
                    t.takePhoto,
                    style: GoogleFonts.poppins(
                        fontSize: 15.sp,
                        fontWeight: FontWeight.w500,
                        color: const Color(0xFF334155)),
                  ),
                  onTap: () async {
                    Navigator.pop(sheetCtx);
                    await ctrl.addPhotoFromCamera();
                  },
                ),
                SizedBox(height: 16.h),
              ],
            ),
          ),
        );
      },
    );
  }

  Future<void> _pickLocation(
    BuildContext context,
    ReportIssueController ctrl,
  ) async {
    final picked = await Navigator.pushNamed(context, AppRoutes.locationPicker);

    if (picked is! Map) return;

    final lat = (picked['lat'] as num?)?.toDouble();
    final lng = (picked['lng'] as num?)?.toDouble();
    if (lat == null || lng == null) return;

    final address = picked['address']?.toString();
    ctrl.setPickedCoordinates(lat: lat, lng: lng, address: address);
  }

  // ─── UI Helpers ──────────────────────────────
  Widget _sectionHeader(String title) {
    return Padding(
      padding: EdgeInsets.symmetric(horizontal: 4.w),
      child: Text(
        title.toUpperCase(),
        style: GoogleFonts.poppins(
          fontSize: 12.sp,
          fontWeight: FontWeight.w600,
          color: const Color(0xFF94A3B8),
          letterSpacing: 0.5,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final t = AppLocalizations.of(context)!;
    final ctrl = Provider.of<ReportIssueController>(context);

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
          t.reportIssue,
          style: GoogleFonts.poppins(
            fontSize: 18.sp,
            fontWeight: FontWeight.w700,
            color: const Color(0xFF0F172A),
          ),
        ),
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 20.h),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ─── INFO CARD ──────────────────────────
            Container(
              padding: EdgeInsets.all(16.w),
              decoration: BoxDecoration(
                color: const Color(0xFFEFF6FF),
                borderRadius: BorderRadius.circular(16.r),
                border: Border.all(color: const Color(0xFFBFDBFE)),
              ),
              child: Row(
                children: [
                  Container(
                    padding: EdgeInsets.all(10.w),
                    decoration: BoxDecoration(
                      color: const Color(0xFF2563EB).withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(12.r),
                    ),
                    child: Icon(Icons.info_outline_rounded,
                        color: const Color(0xFF2563EB), size: 22.w),
                  ),
                  SizedBox(width: 14.w),
                  Expanded(
                    child: Text(
                      t.reportInfoHint,
                      style: GoogleFonts.poppins(
                        fontSize: 13.sp,
                        color: const Color(0xFF1E3A8A),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            SizedBox(height: 24.h),

            // ─── ISSUE TYPE ─────────────────────────
            _sectionHeader(t.whatsTheProblem),
            SizedBox(height: 12.h),

            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: ctrl.issueTypes.map((issue) {
                final code = issue.code;
                final label = issue.labelFor(t);
                final isSelected = ctrl.selectedIssueCode == code;

                return GestureDetector(
                  onTap: () => ctrl.selectIssue(code),
                  child: Container(
                    width: 104.w,
                    padding: EdgeInsets.symmetric(vertical: 18.h, horizontal: 8.w),
                    decoration: BoxDecoration(
                      color: isSelected ? const Color(0xFFEFF6FF) : Colors.white,
                      borderRadius: BorderRadius.circular(16.r),
                      border: Border.all(
                        color: isSelected
                            ? const Color(0xFF2563EB)
                            : const Color(0xFFE2E8F0),
                        width: isSelected ? 2 : 1,
                      ),
                      boxShadow: [
                        if (!isSelected)
                          BoxShadow(
                            color: Colors.black.withValues(alpha: 0.02),
                            blurRadius: 8,
                            offset: const Offset(0, 2),
                          ),
                      ],
                    ),
                    child: Column(
                      children: [
                        Container(
                          padding: EdgeInsets.all(12.w),
                          decoration: BoxDecoration(
                            color: isSelected
                                ? const Color(0xFF2563EB).withValues(alpha: 0.1)
                                : const Color(0xFFF1F5F9),
                            shape: BoxShape.circle,
                          ),
                          child: Icon(
                            issue.icon,
                            size: 28.w,
                            color: isSelected
                                ? const Color(0xFF2563EB)
                                : const Color(0xFF64748B),
                          ),
                        ),
                        SizedBox(height: 12.h),
                        Text(
                          label,
                          textAlign: TextAlign.center,
                          style: GoogleFonts.poppins(
                            fontSize: 12.sp,
                            color: isSelected
                                ? const Color(0xFF1E3A8A)
                                : const Color(0xFF475569),
                            fontWeight: isSelected
                                ? FontWeight.w700
                                : FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              }).toList(),
            ),

            SizedBox(height: 28.h),

            // ─── DESCRIPTION ────────────────────────
            _sectionHeader(t.description),
            SizedBox(height: 12.h),
            TextField(
              controller: ctrl.descriptionController,
              maxLines: 4,
              style: GoogleFonts.poppins(
                fontSize: 14.sp,
                fontWeight: FontWeight.w500,
                color: const Color(0xFF0F172A),
              ),
              decoration: InputDecoration(
                hintText: t.describeIssueHint,
                hintStyle: GoogleFonts.poppins(
                  fontSize: 14.sp,
                  color: const Color(0xFF94A3B8),
                ),
                filled: true,
                fillColor: Colors.white,
                contentPadding: EdgeInsets.all(16.w),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(16.r),
                  borderSide: const BorderSide(color: Color(0xFFE2E8F0)),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(16.r),
                  borderSide: const BorderSide(color: Color(0xFFE2E8F0)),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(16.r),
                  borderSide:
                      const BorderSide(color: Color(0xFF2563EB), width: 1.5),
                ),
              ),
            ),

            SizedBox(height: 28.h),

            // ─── LOCATION MAP ───────────────────────
            _sectionHeader(t.location),
            SizedBox(height: 12.h),
            GestureDetector(
              onTap: () => _pickLocation(context, ctrl),
              child: Container(
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16.r),
                  border: Border.all(color: const Color(0xFFE2E8F0)),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.02),
                      blurRadius: 8,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(16.r),
                  child: Stack(
                    children: [
                      Container(
                        height: 180.h,
                        width: double.infinity,
                        color: const Color(0xFFF8FAFC),
                        child: CustomPaint(
                          painter: GridPatternPainter(),
                        ),
                      ),
                      Positioned.fill(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Container(
                              padding: EdgeInsets.all(14.w),
                              decoration: BoxDecoration(
                                color: ctrl.hasPickedLocation
                                    ? const Color(0xFFDCFCE7)
                                    : Colors.white,
                                shape: BoxShape.circle,
                                boxShadow: [
                                  BoxShadow(
                                    color: ctrl.hasPickedLocation
                                        ? const Color(0xFF22C55E).withValues(alpha: 0.2)
                                        : Colors.black.withValues(alpha: 0.05),
                                    blurRadius: 10,
                                    offset: const Offset(0, 4),
                                  )
                                ],
                                border: Border.all(
                                  color: ctrl.hasPickedLocation
                                      ? const Color(0xFF16A34A).withValues(alpha: 0.3)
                                      : const Color(0xFFE2E8F0),
                                ),
                              ),
                              child: Icon(
                                ctrl.hasPickedLocation
                                    ? Icons.location_on_rounded
                                    : Icons.map_rounded,
                                size: 36.w,
                                color: ctrl.hasPickedLocation
                                    ? const Color(0xFF16A34A)
                                    : const Color(0xFF94A3B8),
                              ),
                            ),
                            SizedBox(height: 12.h),
                            Padding(
                              padding: EdgeInsets.symmetric(horizontal: 24.w),
                              child: Text(
                                ctrl.hasPickedLocation
                                    ? t.selectedLocationLabel(ctrl.locationLabel)
                                    : t.tapToPickLocation,
                                textAlign: TextAlign.center,
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                                style: GoogleFonts.poppins(
                                  fontSize: 13.sp,
                                  fontWeight: FontWeight.w600,
                                  color: ctrl.hasPickedLocation
                                      ? const Color(0xFF16A34A)
                                      : const Color(0xFF64748B),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                      Positioned(
                        top: 12.h,
                        right: 12.w,
                        child: Container(
                          padding: EdgeInsets.symmetric(
                            horizontal: 12.w,
                            vertical: 6.h,
                          ),
                          decoration: BoxDecoration(
                            color: ctrl.hasPickedLocation
                                ? const Color(0xFF16A34A)
                                : const Color(0xFF2563EB),
                            borderRadius: BorderRadius.circular(20.r),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(
                                ctrl.hasPickedLocation
                                    ? Icons.check_circle_outline_rounded
                                    : Icons.touch_app_rounded,
                                color: Colors.white,
                                size: 14.w,
                              ),
                              SizedBox(width: 4.w),
                              Text(
                                ctrl.hasPickedLocation
                                    ? t.selected
                                    : t.pickOnMap,
                                style: GoogleFonts.poppins(
                                  fontSize: 11.sp,
                                  color: Colors.white,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),

            SizedBox(height: 28.h),

            // ─── PHOTO EVIDENCE ─────────────────────
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                _sectionHeader(t.photoEvidence),
                Text(
                  t.photosCount(
                      ctrl.photoPaths.length, ReportIssueController.maxPhotos),
                  style: GoogleFonts.poppins(
                    fontSize: 12.sp,
                    color: const Color(0xFF94A3B8),
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
            SizedBox(height: 12.h),

            Wrap(
              spacing: 12.w,
              runSpacing: 12.h,
              children: [
                for (int i = 0; i < ctrl.photoPaths.length; i++)
                  Stack(
                    children: [
                      Container(
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(16.r),
                          border: Border.all(color: const Color(0xFFE2E8F0)),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withValues(alpha: 0.05),
                              blurRadius: 8,
                              offset: const Offset(0, 2),
                            ),
                          ],
                        ),
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(16.r),
                          child: Image.file(
                            File(ctrl.photoPaths[i]),
                            width: 100.w,
                            height: 100.h,
                            fit: BoxFit.cover,
                            errorBuilder: (context, error, stackTrace) => Container(
                              width: 100.w,
                              height: 100.h,
                              color: const Color(0xFFF1F5F9),
                              child: Center(
                                child: Icon(Icons.broken_image_rounded,
                                    color: const Color(0xFF94A3B8), size: 28.w),
                              ),
                            ),
                          ),
                        ),
                      ),
                      Positioned(
                        top: -6.h,
                        right: -6.w,
                        child: GestureDetector(
                          onTap: () => ctrl.removePhotoAt(i),
                          child: Container(
                            padding: EdgeInsets.all(4.w),
                            decoration: BoxDecoration(
                              color: const Color(0xFFEF4444),
                              shape: BoxShape.circle,
                              border: Border.all(color: Colors.white, width: 2),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withValues(alpha: 0.1),
                                  blurRadius: 4,
                                  offset: const Offset(0, 2),
                                )
                              ],
                            ),
                            child: Icon(Icons.close_rounded,
                                color: Colors.white, size: 14.w),
                          ),
                        ),
                      ),
                    ],
                  ),
                if (ctrl.canAddMorePhotos)
                  GestureDetector(
                    onTap: () => _showPickPhotoSheet(context, ctrl),
                    child: Container(
                      width: 100.w,
                      height: 100.h,
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(16.r),
                        border: Border.all(
                            color: const Color(0xFFCBD5E1),
                            style: BorderStyle.solid), // Dashed borders need custom painter, using solid
                      ),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Container(
                            padding: EdgeInsets.all(8.w),
                            decoration: BoxDecoration(
                              color: const Color(0xFFF1F5F9),
                              shape: BoxShape.circle,
                            ),
                            child: Icon(Icons.add_a_photo_rounded,
                                size: 20.w, color: const Color(0xFF64748B)),
                          ),
                          SizedBox(height: 8.h),
                          Text(
                            t.addPhoto,
                            style: GoogleFonts.poppins(
                              fontSize: 12.sp,
                              fontWeight: FontWeight.w500,
                              color: const Color(0xFF64748B),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
              ],
            ),

            SizedBox(height: 40.h),

            // ─── SUBMIT BUTTON ──────────────────────
            SizedBox(
              width: double.infinity,
              height: 52.h,
              child: ElevatedButton(
                onPressed:
                    ctrl.isSubmitting ? null : () => ctrl.submitReport(context),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF2563EB),
                  foregroundColor: Colors.white,
                  elevation: 0,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16.r),
                  ),
                  disabledBackgroundColor: const Color(0xFF93C5FD),
                ),
                child: ctrl.isSubmitting
                    ? SizedBox(
                        height: 20.w,
                        width: 20.w,
                        child: const CircularProgressIndicator(
                          strokeWidth: 2.5,
                          color: Colors.white,
                        ),
                      )
                    : Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(
                            t.submitReportArrow.replaceAll("->", "").trim(), // Strip plain arrow
                            style: GoogleFonts.poppins(
                              fontSize: 15.sp,
                              fontWeight: FontWeight.w700,
                              color: Colors.white,
                            ),
                          ),
                          SizedBox(width: 8.w),
                          Icon(Icons.arrow_forward_rounded,
                              color: Colors.white, size: 20.w),
                        ],
                      ),
              ),
            ),
            SizedBox(height: 40.h),
          ],
        ),
      ),
    );
  }
}

// Custom Painter for Map Placeholder Background Line Grid Pattern
class GridPatternPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = const Color(0xFFE2E8F0)
      ..strokeWidth = 1.0;

    double step = 20.0;

    for (double i = 0; i <= size.width; i += step) {
      canvas.drawLine(Offset(i, 0), Offset(i, size.height), paint);
    }
    for (double i = 0; i <= size.height; i += step) {
      canvas.drawLine(Offset(0, i), Offset(size.width, i), paint);
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}