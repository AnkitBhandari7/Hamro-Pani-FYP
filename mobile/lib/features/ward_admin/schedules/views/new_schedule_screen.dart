import 'package:dotted_border/dotted_border.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';

import 'package:fyp/l10n/app_localizations.dart';
import '../controllers/new_schedule_controller.dart';
import 'widgets/schedule_preview_sheet.dart';

class NewScheduleScreen extends StatelessWidget {
  const NewScheduleScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (_) => NewScheduleController(),
      child: const _NewScheduleContent(),
    );
  }
}

class _NewScheduleContent extends StatelessWidget {
  const _NewScheduleContent();

  Future<void> _pickFile(BuildContext context) async {
    final t = AppLocalizations.of(context)!;
    final c = context.read<NewScheduleController>();

    final result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: const ['csv', 'pdf'],
      // Important: helps on platforms where `path` can be null
      withData: true,
    );

    if (result == null || result.files.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(t.pleaseSelectAFile)),
      );
      return;
    }

    final f = result.files.single;

    // If both path and bytes are null, we can't upload
    if (f.path == null && f.bytes == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(t.pleaseSelectAFile)),
      );
      return;
    }

    c.setPickedFile(
      fileName: f.name,
      filePath: f.path,
      fileBytes: f.bytes,
    );

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text("Selected: ${f.name}")),
    );
  }

  void _showPreview(BuildContext context) {
    final c = context.read<NewScheduleController>();
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => SchedulePreviewSheet(c: c),
    );
  }

  @override
  Widget build(BuildContext context) {
    final t = AppLocalizations.of(context)!;
    final c = context.watch<NewScheduleController>();

    final isUploadMode = c.selectedTab == 1;

    return Scaffold(
      backgroundColor: const Color(0xFFE8F4FF),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.black),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          t.newSchedule,
          style: GoogleFonts.poppins(
            fontSize: 20.sp,
            fontWeight: FontWeight.w600,
            color: Colors.black,
          ),
        ),
        centerTitle: true,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh, color: Colors.black),
            tooltip: t.reset,
            onPressed: c.reset,
          ),
        ],
      ),
      body: Padding(
        padding: EdgeInsets.all(20.w),
        child: Column(
          children: [
            // Toggle tabs
            Container(
              padding: EdgeInsets.all(4.w),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(30.r),
              ),
              child: Row(
                children: [
                  Expanded(
                    child: _toggle(
                      title: t.manualEntry,
                      icon: Icons.edit_outlined,
                      selected: !isUploadMode,
                      onTap: () => c.setTab(0),
                    ),
                  ),
                  Expanded(
                    child: _toggle(
                      title: t.uploadFile,
                      icon: Icons.cloud_upload_outlined,
                      selected: isUploadMode,
                      onTap: () => c.setTab(1),
                    ),
                  ),
                ],
              ),
            ),
            SizedBox(height: 24.h),

            Expanded(
              child: SingleChildScrollView(
                child: Column(
                  children: [
                    if (isUploadMode) ...[
                      GestureDetector(
                        onTap: () => _pickFile(context),
                        child: DottedBorder(
                          borderType: BorderType.RRect,
                          radius: Radius.circular(24.r),
                          dashPattern: const [8, 8],
                          color: Colors.grey[400]!,
                          strokeWidth: 2,
                          child: Container(
                            padding: EdgeInsets.symmetric(vertical: 40.h),
                            width: double.infinity,
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(24.r),
                            ),
                            child: Column(
                              children: [
                                Icon(
                                  Icons.cloud_upload_outlined,
                                  size: 64.w,
                                  color: Colors.blue[300],
                                ),
                                SizedBox(height: 16.h),
                                Text(
                                  t.dragDropOrTapToUpload,
                                  style: GoogleFonts.poppins(
                                    fontSize: 16.sp,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                                SizedBox(height: 8.h),
                                Text(
                                  t.selectScheduleFileToBegin,
                                  style: GoogleFonts.poppins(
                                    fontSize: 14.sp,
                                    color: Colors.grey[600],
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                      SizedBox(height: 16.h),

                      // Selected file display
                      if (c.fileName != null)
                        Container(
                          padding: EdgeInsets.all(16.w),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(16.r),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withOpacity(0.05),
                                blurRadius: 16,
                                offset: Offset(0, 6.h),
                              ),
                            ],
                          ),
                          child: Row(
                            children: [
                              Icon(Icons.insert_drive_file, color: Colors.blue, size: 22.w),
                              SizedBox(width: 10.w),
                              Expanded(
                                child: Text(
                                  c.fileName!,
                                  style: GoogleFonts.poppins(fontSize: 14.sp, fontWeight: FontWeight.w600),
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                              TextButton(
                                onPressed: c.isPublishing ? null : () => _pickFile(context),
                                child: Text("Change", style: GoogleFonts.poppins()),
                              ),
                              IconButton(
                                tooltip: "Remove",
                                onPressed: c.isPublishing ? null : c.clearPickedFile,
                                icon: const Icon(Icons.close),
                              ),
                            ],
                          ),
                        ),
                    ],

                    if (!isUploadMode) ...[
                      _card(
                        icon: Icons.location_on,
                        title: t.locationDetails,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              t.wardNumber,
                              style: GoogleFonts.poppins(
                                fontSize: 12.sp,
                                color: Colors.grey[600],
                              ),
                            ),
                            SizedBox(height: 8.h),
                            GestureDetector(
                              onTap: () => c.openWardPicker(context),
                              child: Container(
                                padding: EdgeInsets.symmetric(
                                  horizontal: 16.w,
                                  vertical: 16.h,
                                ),
                                decoration: BoxDecoration(
                                  color: Colors.grey[100],
                                  borderRadius: BorderRadius.circular(16.r),
                                ),
                                child: Row(
                                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                  children: [
                                    Text(
                                      c.wardDisplayForLocale(context) ?? t.selectWard,
                                      style: GoogleFonts.poppins(fontSize: 16.sp),
                                    ),
                                    const Icon(Icons.keyboard_arrow_down),
                                  ],
                                ),
                              ),
                            ),
                            SizedBox(height: 16.h),
                            Text(
                              t.affectedAreasUpper,
                              style: GoogleFonts.poppins(
                                fontSize: 12.sp,
                                color: Colors.grey[600],
                              ),
                            ),
                            SizedBox(height: 8.h),
                            TextField(
                              controller: c.affectedAreasController,
                              maxLines: 4,
                              decoration: InputDecoration(
                                hintText: t.affectedAreasHint,
                                hintStyle: GoogleFonts.poppins(color: Colors.grey[500]),
                                filled: true,
                                fillColor: Colors.grey[100],
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(16.r),
                                  borderSide: BorderSide.none,
                                ),
                                contentPadding: EdgeInsets.all(16.w),
                              ),
                            ),
                          ],
                        ),
                      ),
                      _card(
                        icon: Icons.access_time,
                        iconColor: Colors.orange,
                        title: t.dateTime,
                        child: Column(
                          children: [
                            Text(
                              t.supplyDateUpper,
                              style: GoogleFonts.poppins(
                                fontSize: 12.sp,
                                color: Colors.grey[600],
                              ),
                            ),
                            SizedBox(height: 8.h),
                            GestureDetector(
                              onTap: () => c.pickDate(context),
                              child: Container(
                                padding: EdgeInsets.symmetric(
                                  horizontal: 16.w,
                                  vertical: 16.h,
                                ),
                                decoration: BoxDecoration(
                                  color: Colors.grey[100],
                                  borderRadius: BorderRadius.circular(16.r),
                                ),
                                child: Row(
                                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                  children: [
                                    Text(
                                      c.formatDatePreview(c.selectedDate),
                                      style: GoogleFonts.poppins(fontSize: 16.sp),
                                    ),
                                    const Icon(Icons.calendar_today),
                                  ],
                                ),
                              ),
                            ),
                            SizedBox(height: 16.h),
                            Row(
                              children: [
                                Expanded(
                                  child: _timeField(
                                    label: t.startTimeUpper,
                                    value: c.formatTimePreview(c.startTime),
                                    onTap: () => c.pickTime(context, isStart: true),
                                  ),
                                ),
                                SizedBox(width: 16.w),
                                Expanded(
                                  child: _timeField(
                                    label: t.endTimeUpper,
                                    value: c.formatTimePreview(c.endTime),
                                    onTap: () => c.pickTime(context, isStart: false),
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ],

                    // Notify toggle card
                    SizedBox(height: 16.h),
                    Container(
                      padding: EdgeInsets.all(20.w),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(24.r),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.05),
                            blurRadius: 20,
                            offset: Offset(0, 8.h),
                          ),
                        ],
                      ),
                      child: Row(
                        children: [
                          Icon(Icons.notifications_outlined, color: Colors.purple[400], size: 24.w),
                          SizedBox(width: 16.w),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  t.notifyResidents,
                                  style: GoogleFonts.poppins(
                                    fontSize: 16.sp,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                                Text(
                                  t.alertAffectedUsers,
                                  style: GoogleFonts.poppins(
                                    fontSize: 12.sp,
                                    color: Colors.grey,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          Switch(
                            value: c.notifyResidents,
                            onChanged: c.toggleNotifyResidents,
                            activeThumbColor: Colors.blue,
                          ),
                        ],
                      ),
                    ),

                    SizedBox(height: 40.h),

                    Row(
                      children: [
                        Expanded(
                          child: OutlinedButton(
                            onPressed: isUploadMode
                                ? null
                                : () => _showPreview(context),
                            style: OutlinedButton.styleFrom(
                              padding: EdgeInsets.symmetric(vertical: 16.h),
                              side: BorderSide(color: Colors.grey[400]!),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(30.r),
                              ),
                            ),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(Icons.visibility, size: 20.w),
                                SizedBox(width: 8.w),
                                Text(
                                  t.preview,
                                  style: GoogleFonts.poppins(
                                    fontSize: 16.sp,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                        SizedBox(width: 16.w),
                        Expanded(
                          child: ElevatedButton(
                            onPressed: c.isPublishing
                                ? null
                                : () async {
                              // UPLOAD MODE
                              if (isUploadMode) {
                                if (!c.isUploadValid()) {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    SnackBar(content: Text(t.pleaseSelectAFile)),
                                  );
                                  return;
                                }

                                try {
                                  await c.publishUploadedSchedule();
                                  if (!context.mounted) return;

                                  ScaffoldMessenger.of(context).showSnackBar(
                                    SnackBar(content: Text(t.schedulePublishedSuccessfully)),
                                  );
                                  Navigator.pop(context);
                                } catch (e) {
                                  if (!context.mounted) return;
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    SnackBar(content: Text("${t.errorLabel}: $e")),
                                  );
                                }
                                return;
                              }

                              // MANUAL MODE
                              if (!c.isManualValid()) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(content: Text(t.scheduleFillAllRequiredFields)),
                                );
                                return;
                              }

                              try {
                                await c.publishManualSchedule();
                                if (!context.mounted) return;

                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(content: Text(t.schedulePublishedSuccessfully)),
                                );
                                Navigator.pop(context);
                              } catch (e) {
                                if (!context.mounted) return;
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(content: Text("${t.errorLabel}: $e")),
                                );
                              }
                            },
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.blue,
                              padding: EdgeInsets.symmetric(vertical: 16.h),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(30.r),
                              ),
                            ),
                            child: c.isPublishing
                                ? const SizedBox(
                              width: 20,
                              height: 20,
                              child: CircularProgressIndicator(
                                color: Colors.white,
                                strokeWidth: 2,
                              ),
                            )
                                : Text(
                              t.publishArrow,
                              style: GoogleFonts.poppins(
                                fontSize: 16.sp,
                                fontWeight: FontWeight.bold,
                                color: Colors.white,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _toggle({
    required String title,
    required IconData icon,
    required bool selected,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: EdgeInsets.symmetric(vertical: 12.h),
        decoration: BoxDecoration(
          color: selected ? Colors.blue : Colors.transparent,
          borderRadius: BorderRadius.circular(30.r),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              icon,
              color: selected ? Colors.white : Colors.grey[700],
              size: 20.w,
            ),
            SizedBox(width: 8.w),
            Text(
              title,
              style: GoogleFonts.poppins(
                fontSize: 14.sp,
                color: selected ? Colors.white : Colors.grey[700],
                fontWeight: selected ? FontWeight.w600 : FontWeight.normal,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _timeField({
    required String label,
    required String value,
    required VoidCallback onTap,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: GoogleFonts.poppins(fontSize: 12.sp, color: Colors.grey[600]),
        ),
        SizedBox(height: 8.h),
        GestureDetector(
          onTap: onTap,
          child: Container(
            padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 16.h),
            decoration: BoxDecoration(
              color: Colors.grey[100],
              borderRadius: BorderRadius.circular(16.r),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(value, style: GoogleFonts.poppins(fontSize: 16.sp)),
                const Icon(Icons.access_time),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _card({
    required IconData icon,
    Color iconColor = Colors.blue,
    required String title,
    required Widget child,
  }) {
    return Container(
      padding: EdgeInsets.all(20.w),
      margin: EdgeInsets.only(bottom: 24.h),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24.r),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 20,
            offset: Offset(0, 8.h),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, color: iconColor, size: 24.w),
              SizedBox(width: 12.w),
              Text(
                title,
                style: GoogleFonts.poppins(
                  fontSize: 18.sp,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
          SizedBox(height: 20.h),
          child,
        ],
      ),
    );
  }
}