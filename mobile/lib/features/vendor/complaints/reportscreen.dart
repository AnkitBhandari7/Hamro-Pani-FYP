import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:fyp/l10n/app_localizations.dart';

class VendorComplaintReportScreen extends StatelessWidget {
  const VendorComplaintReportScreen({
    super.key,
    required this.isLoading,
    required this.complaints,
    required this.onRefresh,
  });

  final bool isLoading;
  final List<Map<String, dynamic>> complaints;
  final Future<void> Function() onRefresh;

  DateTime? _parseDateTime(dynamic raw) {
    if (raw == null) return null;
    try {
      return DateTime.parse(raw.toString()).toLocal();
    } catch (_) {
      return null;
    }
  }

  String _complaintStatus(dynamic s) {
    final v = (s ?? "OPEN").toString();
    return v.toUpperCase();
  }

  String _complaintTitleFromMessage(String msg, AppLocalizations l10n) {
    final lines = msg.split('\n');
    for (final line in lines) {
      if (line.toLowerCase().startsWith("issue type:")) {
        final x = line.split(":").skip(1).join(":").trim();
        if (x.isNotEmpty) return x;
      }
    }
    return l10n.issue;
  }

  // Status badge colors
  Color _statusBgColor(String status) {
    switch (status) {
      case 'RESOLVED':
        return const Color(0xFFF0FDF4);
      case 'OPEN':
        return const Color(0xFFFFF7ED);
      case 'IN_PROGRESS':
        return const Color(0xFFEFF6FF);
      case 'CLOSED':
        return const Color(0xFFF1F5F9);
      default:
        return const Color(0xFFF1F5F9);
    }
  }

  Color _statusFgColor(String status) {
    switch (status) {
      case 'RESOLVED':
        return const Color(0xFF16A34A);
      case 'OPEN':
        return const Color(0xFFF97316);
      case 'IN_PROGRESS':
        return const Color(0xFF2563EB);
      case 'CLOSED':
        return const Color(0xFF64748B);
      default:
        return const Color(0xFF64748B);
    }
  }

  IconData _statusIcon(String status) {
    switch (status) {
      case 'RESOLVED':
        return Icons.check_circle_rounded;
      case 'OPEN':
        return Icons.error_rounded;
      case 'IN_PROGRESS':
        return Icons.hourglass_top_rounded;
      case 'CLOSED':
        return Icons.cancel_rounded;
      default:
        return Icons.info_rounded;
    }
  }

  List<Map<String, dynamic>> _extractPhotos(Map<String, dynamic> c) {
    final raw = c['photos'];
    if (raw is List) {
      return raw
          .whereType<Map>()
          .map((e) => Map<String, dynamic>.from(e))
          .toList();
    }
    return const [];
  }

  void _openImageViewer(BuildContext context, String url) {
    showDialog(
      context: context,
      builder: (_) {
        return Dialog(
          backgroundColor: Colors.black,
          insetPadding: EdgeInsets.all(12.w),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16.r),
          ),
          child: Stack(
            children: [
              Positioned.fill(
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(16.r),
                  child: InteractiveViewer(
                    child: Image.network(
                      url,
                      fit: BoxFit.contain,
                      errorBuilder: (_, __, ___) => Center(
                        child: Text("Failed to load image",
                            style: GoogleFonts.poppins(color: Colors.white)),
                      ),
                      loadingBuilder: (context, child, progress) {
                        if (progress == null) return child;
                        return const Center(
                            child: CircularProgressIndicator(
                                color: Colors.white));
                      },
                    ),
                  ),
                ),
              ),
              Positioned(
                right: 8,
                top: 8,
                child: Container(
                  decoration: BoxDecoration(
                    color: Colors.black54,
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: IconButton(
                    onPressed: () => Navigator.pop(context),
                    icon:
                        const Icon(Icons.close_rounded, color: Colors.white),
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _photosGrid(
      BuildContext context, List<Map<String, dynamic>> photos) {
    if (photos.isEmpty) return const SizedBox.shrink();

    final urls = photos
        .map((p) => (p['photoUrl'] ?? '').toString())
        .where((u) => u.trim().isNotEmpty)
        .toList();

    if (urls.isEmpty) return const SizedBox.shrink();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(height: 16.h),
        Row(
          children: [
            Icon(Icons.photo_library_rounded,
                size: 16.w, color: const Color(0xFF64748B)),
            SizedBox(width: 6.w),
            Text(
              "Photos",
              style: GoogleFonts.poppins(
                fontSize: 14.sp,
                fontWeight: FontWeight.w600,
                color: const Color(0xFF334155),
              ),
            ),
          ],
        ),
        SizedBox(height: 10.h),
        Wrap(
          spacing: 10.w,
          runSpacing: 10.w,
          children: urls.map((url) {
            return GestureDetector(
              onTap: () => _openImageViewer(context, url),
              child: Container(
                width: 80.w,
                height: 80.w,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(12.r),
                  border: Border.all(color: const Color(0xFFE2E8F0)),
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(11.r),
                  child: Image.network(
                    url,
                    fit: BoxFit.cover,
                    errorBuilder: (_, __, ___) => Container(
                      color: const Color(0xFFF8FAFC),
                      child: Icon(Icons.broken_image_outlined,
                          color: const Color(0xFF94A3B8), size: 24.w),
                    ),
                    loadingBuilder: (context, child, progress) {
                      if (progress == null) return child;
                      return Container(
                        color: const Color(0xFFF8FAFC),
                        child: const Center(
                            child: CircularProgressIndicator(strokeWidth: 2)),
                      );
                    },
                  ),
                ),
              ),
            );
          }).toList(),
        ),
      ],
    );
  }

  void _openComplaintSheet(
      BuildContext context, Map<String, dynamic> c, AppLocalizations l10n) {
    final id = (c['id'] ?? '').toString();
    final status = _complaintStatus(c['status']);
    final createdAt = _parseDateTime(c['createdAt']);
    final msg = (c['message'] ?? '').toString();
    final wardName = (c['wardName'] ?? '').toString();
    final residentName =
        ((c['resident'] is Map) ? c['resident']['name'] : null)?.toString() ??
            l10n.resident;

    final photos = _extractPhotos(c);

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) {
        return Container(
          constraints: BoxConstraints(
            maxHeight: MediaQuery.of(context).size.height * 0.85,
          ),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.vertical(top: Radius.circular(24.r)),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // drag handle
              Container(
                margin: EdgeInsets.only(top: 12.h),
                width: 40.w,
                height: 4.h,
                decoration: BoxDecoration(
                  color: const Color(0xFFCBD5E1),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              // scrollable content
              Flexible(
                child: SingleChildScrollView(
                  padding: EdgeInsets.only(
                    left: 20.w,
                    right: 20.w,
                    top: 20.h,
                    bottom: 16.h + MediaQuery.of(context).viewInsets.bottom,
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // header row: complaint number + status badge
                      Row(
                        children: [
                          Expanded(
                            child: Text(
                              l10n.complaintNumber(id),
                              style: GoogleFonts.poppins(
                                fontSize: 20.sp,
                                fontWeight: FontWeight.w700,
                                color: const Color(0xFF0F172A),
                              ),
                            ),
                          ),
                          Container(
                            padding: EdgeInsets.symmetric(
                                horizontal: 12.w, vertical: 6.h),
                            decoration: BoxDecoration(
                              color: _statusBgColor(status),
                              borderRadius: BorderRadius.circular(8.r),
                              border: Border.all(
                                  color: _statusFgColor(status)
                                      .withValues(alpha: 0.3)),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(_statusIcon(status),
                                    size: 14.w,
                                    color: _statusFgColor(status)),
                                SizedBox(width: 4.w),
                                Text(
                                  status,
                                  style: GoogleFonts.poppins(
                                    fontSize: 11.sp,
                                    fontWeight: FontWeight.w700,
                                    color: _statusFgColor(status),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),

                      SizedBox(height: 16.h),

                      // info rows
                      _sheetInfoRow(
                        icon: Icons.calendar_today_rounded,
                        label: createdAt != null
                            ? DateFormat('MMM dd, yyyy • h:mm a')
                                .format(createdAt)
                            : "—",
                      ),
                      if (wardName.trim().isNotEmpty)
                        _sheetInfoRow(
                          icon: Icons.location_on_outlined,
                          label: wardName,
                        ),
                      _sheetInfoRow(
                        icon: Icons.person_outline_rounded,
                        label: residentName,
                      ),

                      SizedBox(height: 16.h),

                      // divider
                      Container(
                          height: 1, color: const Color(0xFFE2E8F0)),
                      SizedBox(height: 16.h),

                      // message
                      Text(
                        "Details",
                        style: GoogleFonts.poppins(
                          fontSize: 14.sp,
                          fontWeight: FontWeight.w600,
                          color: const Color(0xFF334155),
                        ),
                      ),
                      SizedBox(height: 8.h),
                      Container(
                        width: double.infinity,
                        padding: EdgeInsets.all(14.w),
                        decoration: BoxDecoration(
                          color: const Color(0xFFF8FAFC),
                          borderRadius: BorderRadius.circular(12.r),
                          border:
                              Border.all(color: const Color(0xFFE2E8F0)),
                        ),
                        child: Text(
                          msg,
                          style: GoogleFonts.poppins(
                            fontSize: 13.sp,
                            color: const Color(0xFF475569),
                            height: 1.5,
                          ),
                        ),
                      ),

                      // photos
                      if (photos.isNotEmpty)
                        _photosGrid(context, photos),

                      SizedBox(height: 24.h),

                      // close button
                      SizedBox(
                        width: double.infinity,
                        height: 48.h,
                        child: ElevatedButton(
                          onPressed: () => Navigator.pop(context),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFF2563EB),
                            foregroundColor: Colors.white,
                            elevation: 0,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12.r),
                            ),
                          ),
                          child: Text(
                            l10n.close,
                            style: GoogleFonts.poppins(
                              fontWeight: FontWeight.w600,
                              fontSize: 14.sp,
                            ),
                          ),
                        ),
                      ),
                      SizedBox(height: 8.h),
                    ],
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _sheetInfoRow({required IconData icon, required String label}) {
    return Padding(
      padding: EdgeInsets.only(bottom: 10.h),
      child: Row(
        children: [
          Icon(icon, size: 18.w, color: const Color(0xFF94A3B8)),
          SizedBox(width: 10.w),
          Expanded(
            child: Text(
              label,
              style: GoogleFonts.poppins(
                fontSize: 13.sp,
                color: const Color(0xFF475569),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _emptyInfoCard({
    required IconData icon,
    required String title,
    required String subtitle,
  }) {
    return Container(
      width: double.infinity,
      padding: EdgeInsets.symmetric(vertical: 40.h, horizontal: 20.w),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18.r),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      child: Column(
        children: [
          Container(
            width: 56.w,
            height: 56.w,
            decoration: BoxDecoration(
              color: const Color(0xFFF1F5F9),
              borderRadius: BorderRadius.circular(16.r),
            ),
            child: Icon(icon, color: const Color(0xFF94A3B8), size: 28.w),
          ),
          SizedBox(height: 14.h),
          Text(
            title,
            style: GoogleFonts.poppins(
              fontWeight: FontWeight.w600,
              fontSize: 16.sp,
              color: const Color(0xFF334155),
            ),
          ),
          SizedBox(height: 4.h),
          Text(
            subtitle,
            style: GoogleFonts.poppins(
              color: const Color(0xFF94A3B8),
              fontSize: 13.sp,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _shimmerCard() {
    return Container(
      margin: EdgeInsets.only(bottom: 14.h),
      padding: EdgeInsets.all(16.w),
      decoration: BoxDecoration(
        color: const Color(0xFFF8FAFC),
        borderRadius: BorderRadius.circular(18.r),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      child: Row(
        children: [
          Container(
            width: 44.w,
            height: 44.w,
            decoration: BoxDecoration(
              color: const Color(0xFFE2E8F0),
              borderRadius: BorderRadius.circular(12.r),
            ),
          ),
          SizedBox(width: 12.w),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  height: 14.h,
                  width: 150.w,
                  decoration: BoxDecoration(
                    color: const Color(0xFFE2E8F0),
                    borderRadius: BorderRadius.circular(6.r),
                  ),
                ),
                SizedBox(height: 8.h),
                Container(
                  height: 10.h,
                  width: 100.w,
                  decoration: BoxDecoration(
                    color: const Color(0xFFE2E8F0),
                    borderRadius: BorderRadius.circular(6.r),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    // count stats
    final openCount =
        complaints.where((c) => _complaintStatus(c['status']) == 'OPEN').length;
    final resolvedCount = complaints
        .where((c) => _complaintStatus(c['status']) == 'RESOLVED')
        .length;

    return RefreshIndicator(
      onRefresh: onRefresh,
      color: const Color(0xFF2563EB),
      child: ListView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: EdgeInsets.all(16.w),
        children: [
          // header
          Row(
            children: [
              Expanded(
                child: Text(
                  l10n.reports,
                  style: GoogleFonts.poppins(
                    fontSize: 22.sp,
                    fontWeight: FontWeight.w700,
                    color: const Color(0xFF0F172A),
                  ),
                ),
              ),
              GestureDetector(
                onTap: onRefresh,
                child: Container(
                  padding:
                      EdgeInsets.symmetric(horizontal: 14.w, vertical: 8.h),
                  decoration: BoxDecoration(
                    color: const Color(0xFFEFF6FF),
                    borderRadius: BorderRadius.circular(10.r),
                    border: Border.all(color: const Color(0xFFBFDBFE)),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.refresh_rounded,
                          size: 16.w, color: const Color(0xFF2563EB)),
                      SizedBox(width: 4.w),
                      Text(
                        l10n.refresh,
                        style: GoogleFonts.poppins(
                          fontSize: 13.sp,
                          fontWeight: FontWeight.w600,
                          color: const Color(0xFF2563EB),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
          SizedBox(height: 16.h),

          // summary chips
          if (!isLoading && complaints.isNotEmpty) ...[
            Row(
              children: [
                _summaryChip(
                  label: 'Total',
                  count: complaints.length,
                  color: const Color(0xFF2563EB),
                  bg: const Color(0xFFEFF6FF),
                ),
                SizedBox(width: 10.w),
                _summaryChip(
                  label: 'Open',
                  count: openCount,
                  color: const Color(0xFFF97316),
                  bg: const Color(0xFFFFF7ED),
                ),
                SizedBox(width: 10.w),
                _summaryChip(
                  label: 'Resolved',
                  count: resolvedCount,
                  color: const Color(0xFF16A34A),
                  bg: const Color(0xFFF0FDF4),
                ),
              ],
            ),
            SizedBox(height: 18.h),
          ],

          // loading
          if (isLoading) ...[
            _shimmerCard(),
            _shimmerCard(),
            _shimmerCard(),
          ] else if (complaints.isEmpty)
            _emptyInfoCard(
              icon: Icons.report_outlined,
              title: l10n.noComplaintsYet,
              subtitle: l10n.noComplaintsYet,
            )
          else
            ...complaints.map((c) {
              final id = (c['id'] ?? '').toString();
              final status = _complaintStatus(c['status']);
              final msg = (c['message'] ?? '').toString();
              final createdAt = _parseDateTime(c['createdAt']);
              final wardName = (c['wardName'] ?? '').toString();
              final title = _complaintTitleFromMessage(msg, l10n);

              return GestureDetector(
                onTap: () => _openComplaintSheet(context, c, l10n),
                child: Container(
                  margin: EdgeInsets.only(bottom: 14.h),
                  padding: EdgeInsets.all(16.w),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(18.r),
                    border: Border.all(color: const Color(0xFFE2E8F0)),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.04),
                        blurRadius: 10,
                        offset: const Offset(0, 3),
                      ),
                    ],
                  ),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // status icon
                      Container(
                        width: 44.w,
                        height: 44.w,
                        decoration: BoxDecoration(
                          color: _statusBgColor(status),
                          borderRadius: BorderRadius.circular(12.r),
                          border: Border.all(
                            color: _statusFgColor(status)
                                .withValues(alpha: 0.2),
                          ),
                        ),
                        child: Icon(
                          _statusIcon(status),
                          color: _statusFgColor(status),
                          size: 22.w,
                        ),
                      ),
                      SizedBox(width: 12.w),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            // title + status badge
                            Row(
                              children: [
                                Expanded(
                                  child: Text(
                                    title,
                                    style: GoogleFonts.poppins(
                                      fontSize: 14.sp,
                                      fontWeight: FontWeight.w700,
                                      color: const Color(0xFF0F172A),
                                    ),
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                                SizedBox(width: 8.w),
                                Container(
                                  padding: EdgeInsets.symmetric(
                                      horizontal: 10.w, vertical: 4.h),
                                  decoration: BoxDecoration(
                                    color: _statusBgColor(status),
                                    borderRadius:
                                        BorderRadius.circular(8.r),
                                  ),
                                  child: Text(
                                    status,
                                    style: GoogleFonts.poppins(
                                      fontSize: 10.sp,
                                      fontWeight: FontWeight.w700,
                                      color: _statusFgColor(status),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                            SizedBox(height: 6.h),
                            // meta info
                            Row(
                              children: [
                                Icon(Icons.tag_rounded,
                                    size: 12.w,
                                    color: const Color(0xFF94A3B8)),
                                SizedBox(width: 4.w),
                                Text(
                                  id,
                                  style: GoogleFonts.poppins(
                                    fontSize: 12.sp,
                                    color: const Color(0xFF94A3B8),
                                  ),
                                ),
                                if (wardName.trim().isNotEmpty) ...[
                                  SizedBox(width: 8.w),
                                  Icon(Icons.location_on_outlined,
                                      size: 12.w,
                                      color: const Color(0xFF94A3B8)),
                                  SizedBox(width: 2.w),
                                  Expanded(
                                    child: Text(
                                      wardName,
                                      style: GoogleFonts.poppins(
                                        fontSize: 12.sp,
                                        color: const Color(0xFF94A3B8),
                                      ),
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ),
                                ],
                              ],
                            ),
                            if (createdAt != null) ...[
                              SizedBox(height: 4.h),
                              Row(
                                children: [
                                  Icon(Icons.access_time_rounded,
                                      size: 12.w,
                                      color: const Color(0xFF94A3B8)),
                                  SizedBox(width: 4.w),
                                  Text(
                                    DateFormat('MMM dd, h:mm a')
                                        .format(createdAt),
                                    style: GoogleFonts.poppins(
                                      fontSize: 12.sp,
                                      color: const Color(0xFF94A3B8),
                                    ),
                                  ),
                                ],
                              ),
                            ],
                            SizedBox(height: 8.h),
                            // message preview
                            Text(
                              msg,
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                              style: GoogleFonts.poppins(
                                fontSize: 13.sp,
                                color: const Color(0xFF475569),
                                height: 1.4,
                              ),
                            ),
                          ],
                        ),
                      ),
                      // chevron
                      Padding(
                        padding: EdgeInsets.only(top: 10.h, left: 4.w),
                        child: Icon(Icons.chevron_right_rounded,
                            size: 20.w, color: const Color(0xFFCBD5E1)),
                      ),
                    ],
                  ),
                ),
              );
            }),

          SizedBox(height: 100.h),
        ],
      ),
    );
  }

  Widget _summaryChip({
    required String label,
    required int count,
    required Color color,
    required Color bg,
  }) {
    return Expanded(
      child: Container(
        padding: EdgeInsets.symmetric(vertical: 12.h, horizontal: 10.w),
        decoration: BoxDecoration(
          color: bg,
          borderRadius: BorderRadius.circular(12.r),
          border: Border.all(color: color.withValues(alpha: 0.2)),
        ),
        child: Column(
          children: [
            Text(
              '$count',
              style: GoogleFonts.poppins(
                fontSize: 22.sp,
                fontWeight: FontWeight.w700,
                color: color,
              ),
            ),
            SizedBox(height: 2.h),
            Text(
              label,
              style: GoogleFonts.poppins(
                fontSize: 11.sp,
                fontWeight: FontWeight.w600,
                color: const Color(0xFF64748B),
              ),
            ),
          ],
        ),
      ),
    );
  }
}