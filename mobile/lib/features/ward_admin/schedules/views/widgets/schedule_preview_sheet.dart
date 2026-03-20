import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:google_fonts/google_fonts.dart';

import 'package:fyp/l10n/app_localizations.dart';
import '../../controllers/new_schedule_controller.dart';

class SchedulePreviewSheet extends StatelessWidget {
  final NewScheduleController c;

  const SchedulePreviewSheet({super.key, required this.c});

  @override
  Widget build(BuildContext context) {
    final t = AppLocalizations.of(context)!;

    return Container(
      height: MediaQuery.of(context).size.height * 0.88,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(32.r)),
      ),
      child: Column(
        children: [
          Container(
            margin: EdgeInsets.only(top: 12.h),
            width: 60.w,
            height: 6.h,
            decoration: BoxDecoration(
              color: Colors.grey[300],
              borderRadius: BorderRadius.circular(3.r),
            ),
          ),
          SizedBox(height: 16.h),
          Padding(
            padding: EdgeInsets.symmetric(horizontal: 24.w),
            child: Row(
              children: [
                Icon(Icons.visibility, color: Colors.blue, size: 28.w),
                SizedBox(width: 12.w),
                Expanded(
                  child: Text(
                    t.schedulePreviewTitle,
                    style: GoogleFonts.poppins(
                      fontSize: 22.sp,
                      fontWeight: FontWeight.bold,
                    ),
                    overflow: TextOverflow.ellipsis,
                    maxLines: 1,
                  ),
                ),
              ],
            ),
          ),
          SizedBox(height: 8.h),
          Padding(
            padding: EdgeInsets.symmetric(horizontal: 24.w),
            child: Text(
              t.schedulePreviewSubtitle,
              style: GoogleFonts.poppins(
                fontSize: 14.sp,
                color: Colors.grey[600],
              ),
              textAlign: TextAlign.center,
            ),
          ),
          SizedBox(height: 24.h),
          Expanded(
            child: SingleChildScrollView(
              padding: EdgeInsets.symmetric(horizontal: 24.w),
              child: Container(
                padding: EdgeInsets.all(24.w),
                decoration: BoxDecoration(
                  color: const Color(0xFFE8F4FF),
                  borderRadius: BorderRadius.circular(24.r),
                  border: Border.all(color: Colors.blue[200]!, width: 2),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(Icons.water_drop, color: Colors.blue, size: 32.w),
                        SizedBox(width: 12.w),
                        Expanded(
                          child: Text(
                            t.waterSupplyScheduleTitle,
                            style: GoogleFonts.poppins(
                              fontSize: 20.sp,
                              fontWeight: FontWeight.bold,
                            ),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                    SizedBox(height: 24.h),
                    _row(
                      label: t.wardLabel,
                      value: c.wardDisplayForLocale(context) ?? t.notSelected,
                      icon: Icons.location_on,
                    ),
                    SizedBox(height: 16.h),
                    _row(
                      label: t.affectedAreas,
                      value: c.affectedAreasController.text.trim().isEmpty
                          ? t.notSpecified
                          : c.affectedAreasController.text.trim(),
                      icon: Icons.map,
                    ),
                    SizedBox(height: 16.h),
                    _row(
                      label: t.supplyDate,
                      value: c.formatDatePreview(c.selectedDate),
                      icon: Icons.calendar_today,
                    ),
                    SizedBox(height: 16.h),
                    Row(
                      children: [
                        Expanded(
                          child: _row(
                            label: t.startTimeLabel,
                            value: c.formatTimePreview(c.startTime),
                            icon: Icons.access_time,
                          ),
                        ),
                        SizedBox(width: 16.w),
                        Expanded(
                          child: _row(
                            label: t.endTimeLabel,
                            value: c.formatTimePreview(c.endTime),
                            icon: Icons.access_time_filled,
                          ),
                        ),
                      ],
                    ),
                    SizedBox(height: 24.h),
                    Divider(color: Colors.grey[400]),
                    SizedBox(height: 16.h),
                    Row(
                      children: [
                        Icon(
                          Icons.notifications_active,
                          color: c.notifyResidents ? Colors.blue : Colors.grey,
                          size: 28.w,
                        ),
                        SizedBox(width: 12.w),
                        Expanded(
                          child: Text(
                            c.notifyResidents
                                ? t.residentsWillBeNotified
                                : t.noNotificationsWillBeSent,
                            style: GoogleFonts.poppins(
                              fontSize: 16.sp,
                              color: c.notifyResidents
                                  ? Colors.blue[700]
                                  : Colors.grey[600],
                              fontWeight: FontWeight.w600,
                            ),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ),
          Padding(
            padding: EdgeInsets.all(24.w),
            child: ElevatedButton(
              onPressed: () => Navigator.pop(context),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.blue,
                padding: EdgeInsets.symmetric(vertical: 16.h),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(30.r),
                ),
                minimumSize: const Size(double.infinity, 56),
              ),
              child: Text(
                t.closePreview,
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
    );
  }

  Widget _row({
    required String label,
    required String value,
    required IconData icon,
  }) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, color: Colors.blue[700], size: 24.w),
        SizedBox(width: 16.w),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: GoogleFonts.poppins(
                  fontSize: 12.sp,
                  color: Colors.grey[600],
                  fontWeight: FontWeight.w600,
                ),
              ),
              SizedBox(height: 4.h),
              Text(
                value,
                style: GoogleFonts.poppins(
                  fontSize: 16.sp,
                  fontWeight: FontWeight.w600,
                ),
                overflow: TextOverflow.ellipsis,
                maxLines: 2,
              ),
            ],
          ),
        ),
      ],
    );
  }
}
