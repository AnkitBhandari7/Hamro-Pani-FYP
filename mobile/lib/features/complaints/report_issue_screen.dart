import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';

import 'package:fyp/core/routes/routes.dart';

import 'report_issue_controller.dart';

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

  Future<void> _showPickPhotoSheet(BuildContext context, ReportIssueController ctrl) async {
    await showModalBottomSheet(
      context: context,
      builder: (sheetCtx) {
        return SafeArea(
          child: Wrap(
            children: [
              ListTile(
                leading: const Icon(Icons.photo_library),
                title: Text("Choose from Gallery", style: GoogleFonts.poppins()),
                onTap: () async {
                  Navigator.pop(sheetCtx);
                  await ctrl.addPhotosFromGallery();
                },
              ),
              ListTile(
                leading: const Icon(Icons.camera_alt),
                title: Text("Take Photo", style: GoogleFonts.poppins()),
                onTap: () async {
                  Navigator.pop(sheetCtx);
                  await ctrl.addPhotoFromCamera();
                },
              ),
            ],
          ),
        );
      },
    );
  }

  Future<void> _pickLocation(BuildContext context, ReportIssueController ctrl) async {
    final picked = await Navigator.pushNamed(context, AppRoutes.locationPicker);

    if (picked is! Map) return;

    final lat = (picked['lat'] as num?)?.toDouble();
    final lng = (picked['lng'] as num?)?.toDouble();
    if (lat == null || lng == null) return;

    ctrl.setPickedCoordinates(lat: lat, lng: lng);
  }

  @override
  Widget build(BuildContext context) {
    final ctrl = Provider.of<ReportIssueController>(context);

    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.arrow_back, color: Colors.black, size: 28.w),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          'Report Issue',
          style: GoogleFonts.poppins(fontSize: 20.sp, fontWeight: FontWeight.w600),
        ),
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        padding: EdgeInsets.symmetric(horizontal: 16.w),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            SizedBox(height: 16.h),

            Text(
              "WHAT'S THE PROBLEM?",
              style: GoogleFonts.poppins(
                fontSize: 14.sp,
                fontWeight: FontWeight.w600,
                color: Colors.grey[700],
              ),
            ),
            SizedBox(height: 12.h),

            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: ctrl.issueTypes.map((issue) {
                final isSelected = ctrl.selectedIssue == issue['label'];
                return GestureDetector(
                  onTap: () => ctrl.selectIssue((issue['label'] ?? '').toString()),
                  child: Container(
                    width: 100.w,
                    padding: EdgeInsets.symmetric(vertical: 16.h),
                    decoration: BoxDecoration(
                      color: isSelected ? Colors.blue[50] : Colors.white,
                      borderRadius: BorderRadius.circular(16.r),
                      border: Border.all(
                        color: isSelected ? Colors.blue : Colors.grey[300]!,
                        width: 2,
                      ),
                    ),
                    child: Column(
                      children: [
                        Icon(
                          issue['icon'] as IconData,
                          size: 32.w,
                          color: isSelected ? Colors.blue : Colors.grey[600],
                        ),
                        SizedBox(height: 8.h),
                        Text(
                          (issue['label'] ?? '').toString(),
                          textAlign: TextAlign.center,
                          style: GoogleFonts.poppins(
                            fontSize: 12.sp,
                            color: isSelected ? Colors.blue[800] : Colors.grey[800],
                            fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              }).toList(),
            ),

            SizedBox(height: 32.h),

            Text(
              "Description",
              style: GoogleFonts.poppins(
                fontSize: 14.sp,
                fontWeight: FontWeight.w600,
                color: Colors.grey[700],
              ),
            ),
            SizedBox(height: 8.h),
            TextField(
              controller: ctrl.descriptionController,
              maxLines: 4,
              decoration: InputDecoration(
                hintText: 'Please describe the issue in detail...',
                hintStyle: GoogleFonts.poppins(fontSize: 14.sp, color: Colors.grey[500]),
                filled: true,
                fillColor: Colors.white,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(16.r),
                  borderSide: BorderSide.none,
                ),
                contentPadding: EdgeInsets.all(16.w),
              ),
            ),

            SizedBox(height: 32.h),

            // ✅ Location (map picker)
            Text(
              "Location",
              style: GoogleFonts.poppins(
                fontSize: 14.sp,
                fontWeight: FontWeight.w600,
                color: Colors.grey[700],
              ),
            ),
            SizedBox(height: 8.h),
            GestureDetector(
              onTap: () => _pickLocation(context, ctrl),
              child: Stack(
                children: [
                  ClipRRect(
                    borderRadius: BorderRadius.circular(16.r),
                    child: Container(
                      height: 180.h,
                      color: Colors.blue[50],
                      child: Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.map, size: 60.w, color: Colors.blue[300]),
                            SizedBox(height: 8.h),
                            Text(
                              ctrl.hasPickedLocation
                                  ? 'Selected\n${ctrl.locationLabel}'
                                  : 'Tap to pick location from map',
                              textAlign: TextAlign.center,
                              style: GoogleFonts.poppins(fontSize: 14.sp, color: Colors.blue[800]),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                  Positioned(
                    top: 12.h,
                    right: 12.w,
                    child: Container(
                      padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 6.h),
                      decoration: BoxDecoration(
                        color: ctrl.hasPickedLocation ? Colors.green : Colors.blue,
                        borderRadius: BorderRadius.circular(20.r),
                      ),
                      child: Text(
                        ctrl.hasPickedLocation ? 'Selected' : 'Pick on map',
                        style: GoogleFonts.poppins(
                          fontSize: 12.sp,
                          color: Colors.white,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),

            SizedBox(height: 32.h),

            Text(
              "Photo Evidence",
              style: GoogleFonts.poppins(
                fontSize: 14.sp,
                fontWeight: FontWeight.w600,
                color: Colors.grey[700],
              ),
            ),
            SizedBox(height: 8.h),

            Wrap(
              spacing: 12.w,
              runSpacing: 12.h,
              children: [
                for (int i = 0; i < ctrl.photoPaths.length; i++)
                  Stack(
                    children: [
                      ClipRRect(
                        borderRadius: BorderRadius.circular(12.r),
                        child: Image.file(
                          File(ctrl.photoPaths[i]),
                          width: 100.w,
                          height: 100.h,
                          fit: BoxFit.cover,
                          errorBuilder: (_, __, ___) => Container(
                            width: 100.w,
                            height: 100.h,
                            color: Colors.grey[300],
                            child: const Center(child: Icon(Icons.broken_image)),
                          ),
                        ),
                      ),
                      Positioned(
                        top: -4.h,
                        right: -4.w,
                        child: GestureDetector(
                          onTap: () => ctrl.removePhotoAt(i),
                          child: CircleAvatar(
                            radius: 14.r,
                            backgroundColor: Colors.red,
                            child: Icon(Icons.close, color: Colors.white, size: 16.w),
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
                        color: Colors.grey[200],
                        borderRadius: BorderRadius.circular(12.r),
                        border: Border.all(color: Colors.grey[400]!),
                      ),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.add_a_photo, size: 30.w, color: Colors.grey[700]),
                          SizedBox(height: 4.h),
                          Text(
                            'ADD PHOTO',
                            style: GoogleFonts.poppins(fontSize: 12.sp, color: Colors.grey[700]),
                          ),
                          SizedBox(height: 2.h),
                          Text(
                            '${ctrl.photoPaths.length}/${ReportIssueController.maxPhotos}',
                            style: GoogleFonts.poppins(fontSize: 10.sp, color: Colors.grey[600]),
                          ),
                        ],
                      ),
                    ),
                  ),
              ],
            ),

            SizedBox(height: 16.h),

            Container(
              padding: EdgeInsets.all(12.w),
              decoration: BoxDecoration(
                color: Colors.blue[50],
                borderRadius: BorderRadius.circular(12.r),
              ),
              child: Row(
                children: [
                  Icon(Icons.info_outline, color: Colors.blue, size: 20.w),
                  SizedBox(width: 8.w),
                  Expanded(
                    child: Text(
                      "Once submitted, your ticket status will be trackable in the History tab.",
                      style: GoogleFonts.poppins(fontSize: 13.sp, color: Colors.blue[800]),
                    ),
                  ),
                ],
              ),
            ),

            SizedBox(height: 32.h),

            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: ctrl.isSubmitting ? null : () => ctrl.submitReport(context),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.blue,
                  padding: EdgeInsets.symmetric(vertical: 16.h),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16.r)),
                ),
                child: ctrl.isSubmitting
                    ? const SizedBox(
                  height: 18,
                  width: 18,
                  child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                )
                    : Text(
                  'Submit Report →',
                  style: GoogleFonts.poppins(
                    fontSize: 16.sp,
                    fontWeight: FontWeight.w600,
                    color: Colors.white,
                  ),
                ),
              ),
            ),

            SizedBox(height: 100.h),
          ],
        ),
      ),
    );
  }
}