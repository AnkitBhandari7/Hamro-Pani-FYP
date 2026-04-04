import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';

import 'package:fyp/l10n/app_localizations.dart';
import 'package:fyp/services/api_service.dart';

class WardAdminComplaintReportScreen extends StatefulWidget {
  const WardAdminComplaintReportScreen({super.key});

  @override
  State<WardAdminComplaintReportScreen> createState() =>
      _WardAdminComplaintReportScreenState();
}

class _WardAdminComplaintReportScreenState
    extends State<WardAdminComplaintReportScreen> {
  bool loading = true;
  String? error;

  List<Map<String, dynamic>> complaints = [];

  final TextEditingController _searchCtrl = TextEditingController();
  String _search = "";
  String _statusFilter = "ALL";
  String _wardFilter = "ALL";
  String _vendorFilter = "ALL";
  bool _filtersExpanded = false;

  final Set<String> _updatingIds = {};

  @override
  void initState() {
    super.initState();
    _searchCtrl.addListener(() {
      setState(() => _search = _searchCtrl.text.trim());
    });
    load();
  }

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  // ─── Helpers ────────────────────────────
  DateTime? _parseDateTime(dynamic raw) {
    if (raw == null) return null;
    try {
      return DateTime.parse(raw.toString()).toLocal();
    } catch (_) {
      return null;
    }
  }

  String _complaintStatus(dynamic s) =>
      (s ?? "OPEN").toString().toUpperCase();

  Color _statusBgColor(String status) {
    switch (status) {
      case 'OPEN':
        return const Color(0xFFFFF7ED);
      case 'IN_REVIEW':
        return const Color(0xFFEFF6FF);
      case 'RESOLVED':
        return const Color(0xFFF0FDF4);
      case 'REJECTED':
        return const Color(0xFFFEF2F2);
      default:
        return const Color(0xFFF1F5F9);
    }
  }

  Color _statusFgColor(String status) {
    switch (status) {
      case 'OPEN':
        return const Color(0xFFF97316);
      case 'IN_REVIEW':
        return const Color(0xFF2563EB);
      case 'RESOLVED':
        return const Color(0xFF16A34A);
      case 'REJECTED':
        return const Color(0xFFEF4444);
      default:
        return const Color(0xFF64748B);
    }
  }

  IconData _statusIcon(String status) {
    switch (status) {
      case 'OPEN':
        return Icons.error_rounded;
      case 'IN_REVIEW':
        return Icons.hourglass_top_rounded;
      case 'RESOLVED':
        return Icons.check_circle_rounded;
      case 'REJECTED':
        return Icons.cancel_rounded;
      default:
        return Icons.info_rounded;
    }
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

  List<String> get _wardOptions {
    final set = <String>{"ALL"};
    for (final c in complaints) {
      final w = (c['wardName'] ?? '').toString().trim();
      if (w.isNotEmpty) set.add(w);
    }
    return set.toList()..sort();
  }

  List<String> get _vendorOptions {
    final set = <String>{"ALL"};
    for (final c in complaints) {
      final v = (c['vendorName'] ?? '').toString().trim();
      if (v.isNotEmpty) set.add(v);
    }
    return set.toList()..sort();
  }

  void _syncFilterValues() {
    if (!_wardOptions.contains(_wardFilter)) _wardFilter = "ALL";
    if (!_vendorOptions.contains(_vendorFilter)) _vendorFilter = "ALL";
  }

  List<Map<String, dynamic>> get _filteredComplaints {
    bool matchesSearch(Map<String, dynamic> c) {
      if (_search.isEmpty) return true;
      final s = _search.toLowerCase();
      final id = (c['id'] ?? '').toString().toLowerCase();
      final msg = (c['message'] ?? '').toString().toLowerCase();
      final ward = (c['wardName'] ?? '').toString().toLowerCase();
      final vendor = (c['vendorName'] ?? '').toString().toLowerCase();
      final routeLoc = (c['routeLocation'] ?? '').toString().toLowerCase();
      final residentName =
          ((c['resident'] is Map) ? c['resident']['name'] : '')
              .toString()
              .toLowerCase();

      return id.contains(s) ||
          msg.contains(s) ||
          ward.contains(s) ||
          vendor.contains(s) ||
          routeLoc.contains(s) ||
          residentName.contains(s);
    }

    return complaints.where((c) {
      final st = _complaintStatus(c['status']);
      final okStatus = _statusFilter == "ALL" || st == _statusFilter;
      final okWard = _wardFilter == "ALL" ||
          (c['wardName'] ?? '').toString() == _wardFilter;
      final okVendor = _vendorFilter == "ALL" ||
          (c['vendorName'] ?? '').toString() == _vendorFilter;
      return okStatus && okWard && okVendor && matchesSearch(c);
    }).toList();
  }

  // Status counts
  int get _openCount =>
      complaints.where((c) => _complaintStatus(c['status']) == 'OPEN').length;
  int get _reviewCount => complaints
      .where((c) => _complaintStatus(c['status']) == 'IN_REVIEW')
      .length;
  int get _resolvedCount => complaints
      .where((c) => _complaintStatus(c['status']) == 'RESOLVED')
      .length;

  // ─── API ────────────────────────────────
  Future<void> load() async {
    setState(() {
      loading = true;
      error = null;
    });

    try {
      final res = await ApiService.get('/complaints/ward');
      if (res.statusCode != 200) {
        throw Exception("HTTP ${res.statusCode}: ${res.body}");
      }

      final decoded = jsonDecode(res.body);
      final list = (decoded is List) ? decoded : <dynamic>[];

      final mapped = list
          .whereType<Map>()
          .map((e) => Map<String, dynamic>.from(e))
          .toList();

      mapped.sort((a, b) {
        final ad = _parseDateTime(a['createdAt']) ??
            DateTime.fromMillisecondsSinceEpoch(0);
        final bd = _parseDateTime(b['createdAt']) ??
            DateTime.fromMillisecondsSinceEpoch(0);
        return bd.compareTo(ad);
      });

      setState(() {
        complaints = mapped;
        loading = false;
      });
      setState(_syncFilterValues);
    } catch (e) {
      setState(() {
        loading = false;
        error = e.toString();
        complaints = [];
      });
    }
  }

  void _clearFilters() {
    setState(() {
      _searchCtrl.clear();
      _statusFilter = "ALL";
      _wardFilter = "ALL";
      _vendorFilter = "ALL";
    });
  }

  Future<void> _updateComplaintStatus({
    required String complaintId,
    required String newStatus,
  }) async {
    if (_updatingIds.contains(complaintId)) return;
    setState(() => _updatingIds.add(complaintId));

    try {
      final res = await ApiService.patch(
        '/complaints/$complaintId/status',
        {"status": newStatus},
      );

      if (res.statusCode != 200) {
        throw Exception("HTTP ${res.statusCode}: ${res.body}");
      }

      final decoded = jsonDecode(res.body);
      final updatedComplaint =
          (decoded is Map && decoded['complaint'] is Map)
              ? Map<String, dynamic>.from(decoded['complaint'])
              : null;

      final newDbStatus =
          (updatedComplaint?['status'] ?? newStatus).toString();

      final idx = complaints.indexWhere(
          (x) => (x['id'] ?? '').toString() == complaintId);

      if (idx != -1) {
        final next = Map<String, dynamic>.from(complaints[idx]);
        next['status'] = newDbStatus;
        final copy = [...complaints];
        copy[idx] = next;
        setState(() => complaints = copy);
      } else {
        await load();
      }

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text("Status updated: $newDbStatus"),
          backgroundColor: const Color(0xFF16A34A),
          behavior: SnackBarBehavior.floating,
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        ),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text("Failed to update status: $e"),
          backgroundColor: const Color(0xFFEF4444),
          behavior: SnackBarBehavior.floating,
        ),
      );
    } finally {
      if (mounted) setState(() => _updatingIds.remove(complaintId));
    }
  }

  // ─── Image Viewer ───────────────────────
  void _openImageViewer(BuildContext context, String url) {
    showDialog(
      context: context,
      builder: (_) {
        return Dialog(
          backgroundColor: Colors.black,
          insetPadding: EdgeInsets.all(12.w),
          shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16.r)),
          child: Stack(
            children: [
              Positioned.fill(
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(16.r),
                  child: InteractiveViewer(
                    child: Image.network(
                      url,
                      fit: BoxFit.contain,
                      errorBuilder: (c1, e1, s1) => Center(
                        child: Text("Failed to load image",
                            style:
                                GoogleFonts.poppins(color: Colors.white)),
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
                    icon: const Icon(Icons.close_rounded,
                        color: Colors.white),
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
            Text("Photos",
                style: GoogleFonts.poppins(
                    fontSize: 14.sp,
                    fontWeight: FontWeight.w600,
                    color: const Color(0xFF334155))),
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
                    errorBuilder: (c2, e2, s2) => Container(
                      color: const Color(0xFFF8FAFC),
                      child: Icon(Icons.broken_image_outlined,
                          color: const Color(0xFF94A3B8), size: 24.w),
                    ),
                    loadingBuilder: (context, child, progress) {
                      if (progress == null) return child;
                      return Container(
                        color: const Color(0xFFF8FAFC),
                        child: const Center(
                            child: CircularProgressIndicator(
                                strokeWidth: 2)),
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

  // ─── Detail Bottom Sheet ────────────────
  void _openComplaintSheet(
    BuildContext context,
    Map<String, dynamic> c,
    AppLocalizations l10n,
  ) {
    final id = (c['id'] ?? '').toString();
    final currentStatus = _complaintStatus(c['status']);
    String nextStatus = currentStatus;

    final createdAt = _parseDateTime(c['createdAt']);
    final msg = (c['message'] ?? '').toString();
    final wardName = (c['wardName'] ?? '').toString();
    final vendorName = (c['vendorName'] ?? '').toString();
    final vendorPhone = (c['vendorPhone'] ?? '').toString();
    final routeLocation = (c['routeLocation'] ?? '').toString();
    final residentName =
        ((c['resident'] is Map) ? c['resident']['name'] : null)
                ?.toString() ??
            l10n.resident;
    final photos = _extractPhotos(c);

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) {
        return StatefulBuilder(
          builder: (context, setModalState) {
            final isUpdating = _updatingIds.contains(id);

            return Container(
              constraints: BoxConstraints(
                maxHeight: MediaQuery.of(context).size.height * 0.85,
              ),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius:
                    BorderRadius.vertical(top: Radius.circular(24.r)),
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    margin: EdgeInsets.only(top: 12.h),
                    width: 40.w,
                    height: 4.h,
                    decoration: BoxDecoration(
                      color: const Color(0xFFCBD5E1),
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                  Flexible(
                    child: SingleChildScrollView(
                      padding: EdgeInsets.only(
                        left: 20.w,
                        right: 20.w,
                        top: 20.h,
                        bottom: 16.h +
                            MediaQuery.of(context).viewInsets.bottom,
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Header
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
                                  color: _statusBgColor(currentStatus),
                                  borderRadius: BorderRadius.circular(8.r),
                                  border: Border.all(
                                      color: _statusFgColor(currentStatus)
                                          .withValues(alpha: 0.3)),
                                ),
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Icon(_statusIcon(currentStatus),
                                        size: 14.w,
                                        color: _statusFgColor(
                                            currentStatus)),
                                    SizedBox(width: 4.w),
                                    Text(
                                      currentStatus,
                                      style: GoogleFonts.poppins(
                                        fontSize: 11.sp,
                                        fontWeight: FontWeight.w700,
                                        color: _statusFgColor(
                                            currentStatus),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                          SizedBox(height: 16.h),

                          // Info rows
                          _sheetInfoRow(
                            Icons.calendar_today_rounded,
                            createdAt != null
                                ? DateFormat('MMM dd, yyyy • h:mm a')
                                    .format(createdAt)
                                : "—",
                          ),
                          _sheetInfoRow(
                              Icons.person_outline_rounded,
                              l10n.fromPerson(residentName)),
                          if (wardName.trim().isNotEmpty)
                            _sheetInfoRow(Icons.location_city_rounded,
                                l10n.wardNameLabel(wardName)),
                          if (vendorName.trim().isNotEmpty)
                            _sheetInfoRow(
                              Icons.local_shipping_outlined,
                              "${l10n.vendor}: $vendorName${vendorPhone.trim().isNotEmpty ? " ($vendorPhone)" : ""}",
                            ),
                          if (routeLocation.trim().isNotEmpty)
                            _sheetInfoRow(Icons.location_on_outlined,
                                l10n.locationLabel(routeLocation)),

                          SizedBox(height: 12.h),
                          Container(
                              height: 1,
                              color: const Color(0xFFE2E8F0)),
                          SizedBox(height: 12.h),

                          // Message
                          Text("Details",
                              style: GoogleFonts.poppins(
                                  fontSize: 14.sp,
                                  fontWeight: FontWeight.w600,
                                  color: const Color(0xFF334155))),
                          SizedBox(height: 8.h),
                          Container(
                            width: double.infinity,
                            padding: EdgeInsets.all(14.w),
                            decoration: BoxDecoration(
                              color: const Color(0xFFF8FAFC),
                              borderRadius: BorderRadius.circular(12.r),
                              border: Border.all(
                                  color: const Color(0xFFE2E8F0)),
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

                          // Photos
                          if (photos.isNotEmpty)
                            _photosGrid(context, photos),

                          SizedBox(height: 20.h),
                          Container(
                              height: 1,
                              color: const Color(0xFFE2E8F0)),
                          SizedBox(height: 16.h),

                          // Action section
                          Row(
                            children: [
                              Icon(Icons.admin_panel_settings_rounded,
                                  size: 18.w,
                                  color: const Color(0xFF2563EB)),
                              SizedBox(width: 6.w),
                              Text(
                                "Take Action",
                                style: GoogleFonts.poppins(
                                  fontSize: 15.sp,
                                  fontWeight: FontWeight.w700,
                                  color: const Color(0xFF0F172A),
                                ),
                              ),
                            ],
                          ),
                          SizedBox(height: 12.h),

                          DropdownButtonFormField<String>(
                            isExpanded: true,
                            initialValue: nextStatus,
                            items: [
                              _styledDropdownItem(
                                  "OPEN", Icons.error_rounded,
                                  const Color(0xFFF97316)),
                              _styledDropdownItem(
                                  "IN_REVIEW",
                                  Icons.hourglass_top_rounded,
                                  const Color(0xFF2563EB)),
                              _styledDropdownItem(
                                  "RESOLVED",
                                  Icons.check_circle_rounded,
                                  const Color(0xFF16A34A)),
                              _styledDropdownItem(
                                  "REJECTED",
                                  Icons.cancel_rounded,
                                  const Color(0xFFEF4444)),
                            ],
                            onChanged: isUpdating
                                ? null
                                : (v) => setModalState(
                                    () => nextStatus = v ?? currentStatus),
                            style: GoogleFonts.poppins(
                              fontSize: 14.sp,
                              fontWeight: FontWeight.w600,
                              color: const Color(0xFF0F172A),
                            ),
                            decoration: InputDecoration(
                              filled: true,
                              fillColor: const Color(0xFFF8FAFC),
                              labelText: "Status",
                              labelStyle: GoogleFonts.poppins(
                                  color: const Color(0xFF94A3B8)),
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12.r),
                                borderSide: const BorderSide(
                                    color: Color(0xFFE2E8F0)),
                              ),
                              enabledBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12.r),
                                borderSide: const BorderSide(
                                    color: Color(0xFFE2E8F0)),
                              ),
                              focusedBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12.r),
                                borderSide: const BorderSide(
                                    color: Color(0xFF2563EB)),
                              ),
                            ),
                          ),

                          SizedBox(height: 14.h),
                          SizedBox(
                            width: double.infinity,
                            height: 48.h,
                            child: ElevatedButton.icon(
                              onPressed: isUpdating
                                  ? null
                                  : () async {
                                      await _updateComplaintStatus(
                                        complaintId: id,
                                        newStatus: nextStatus,
                                      );
                                      if (context.mounted) {
                                        Navigator.pop(context);
                                      }
                                    },
                              icon: isUpdating
                                  ? SizedBox(
                                      width: 18.w,
                                      height: 18.w,
                                      child:
                                          const CircularProgressIndicator(
                                              strokeWidth: 2,
                                              color: Colors.white),
                                    )
                                  : Icon(Icons.save_rounded,
                                      size: 20.w),
                              label: Text("Save Status",
                                  style: GoogleFonts.poppins(
                                      fontWeight: FontWeight.w600,
                                      fontSize: 14.sp)),
                              style: ElevatedButton.styleFrom(
                                backgroundColor:
                                    const Color(0xFF2563EB),
                                foregroundColor: Colors.white,
                                elevation: 0,
                                shape: RoundedRectangleBorder(
                                  borderRadius:
                                      BorderRadius.circular(12.r),
                                ),
                              ),
                            ),
                          ),

                          SizedBox(height: 10.h),
                          SizedBox(
                            width: double.infinity,
                            height: 44.h,
                            child: OutlinedButton(
                              onPressed: () => Navigator.pop(context),
                              style: OutlinedButton.styleFrom(
                                foregroundColor:
                                    const Color(0xFF475569),
                                side: const BorderSide(
                                    color: Color(0xFFE2E8F0)),
                                shape: RoundedRectangleBorder(
                                  borderRadius:
                                      BorderRadius.circular(12.r),
                                ),
                              ),
                              child: Text(l10n.close,
                                  style: GoogleFonts.poppins(
                                      fontWeight: FontWeight.w600)),
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
      },
    );
  }

  DropdownMenuItem<String> _styledDropdownItem(
      String value, IconData icon, Color color) {
    return DropdownMenuItem(
      value: value,
      child: Row(
        children: [
          Icon(icon, size: 18.w, color: color),
          SizedBox(width: 8.w),
          Text(value,
              style: GoogleFonts.poppins(
                  fontSize: 14.sp, fontWeight: FontWeight.w600)),
        ],
      ),
    );
  }

  Widget _sheetInfoRow(IconData icon, String label) {
    return Padding(
      padding: EdgeInsets.only(bottom: 8.h),
      child: Row(
        children: [
          Icon(icon, size: 16.w, color: const Color(0xFF94A3B8)),
          SizedBox(width: 8.w),
          Expanded(
            child: Text(label,
                style: GoogleFonts.poppins(
                    fontSize: 13.sp,
                    color: const Color(0xFF475569))),
          ),
        ],
      ),
    );
  }

  // ─── Build ──────────────────────────────
  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final list = _filteredComplaints;

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
        ),
        title: Text(
          l10n.reports,
          style: GoogleFonts.poppins(
            fontSize: 18.sp,
            fontWeight: FontWeight.w700,
            color: const Color(0xFF0F172A),
          ),
        ),
        centerTitle: true,
        actions: [
          GestureDetector(
            onTap: load,
            child: Container(
              margin: EdgeInsets.only(right: 12.w),
              padding:
                  EdgeInsets.symmetric(horizontal: 10.w, vertical: 6.h),
              decoration: BoxDecoration(
                color: const Color(0xFFEFF6FF),
                borderRadius: BorderRadius.circular(8.r),
                border: Border.all(color: const Color(0xFFBFDBFE)),
              ),
              child: Icon(Icons.refresh_rounded,
                  size: 20.w, color: const Color(0xFF2563EB)),
            ),
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: load,
        color: const Color(0xFF2563EB),
        child: loading
            ? const Center(child: CircularProgressIndicator())
            : error != null
                ? ListView(
                    physics: const AlwaysScrollableScrollPhysics(),
                    padding: EdgeInsets.all(16.w),
                    children: [
                      Container(
                        padding: EdgeInsets.all(16.w),
                        decoration: BoxDecoration(
                          color: const Color(0xFFFEF2F2),
                          borderRadius: BorderRadius.circular(12.r),
                          border: Border.all(
                              color: const Color(0xFFFECACA)),
                        ),
                        child: Text(error!,
                            style: GoogleFonts.poppins(
                                color: const Color(0xFFEF4444))),
                      ),
                    ],
                  )
                : ListView(
                    physics: const AlwaysScrollableScrollPhysics(),
                    padding: EdgeInsets.all(16.w),
                    children: [
                      // Summary chips
                      if (complaints.isNotEmpty) ...[
                        Row(
                          children: [
                            _summaryChip('Total', complaints.length,
                                const Color(0xFF2563EB),
                                const Color(0xFFEFF6FF)),
                            SizedBox(width: 8.w),
                            _summaryChip('Open', _openCount,
                                const Color(0xFFF97316),
                                const Color(0xFFFFF7ED)),
                            SizedBox(width: 8.w),
                            _summaryChip('Review', _reviewCount,
                                const Color(0xFF2563EB),
                                const Color(0xFFEFF6FF)),
                            SizedBox(width: 8.w),
                            _summaryChip('Resolved', _resolvedCount,
                                const Color(0xFF16A34A),
                                const Color(0xFFF0FDF4)),
                          ],
                        ),
                        SizedBox(height: 16.h),
                      ],

                      // Search + Filters
                      _buildFilters(l10n),
                      SizedBox(height: 16.h),

                      // Results count
                      if (list.isNotEmpty)
                        Padding(
                          padding: EdgeInsets.only(bottom: 10.h),
                          child: Text(
                            '${list.length} results',
                            style: GoogleFonts.poppins(
                              fontSize: 13.sp,
                              fontWeight: FontWeight.w600,
                              color: const Color(0xFF94A3B8),
                            ),
                          ),
                        ),

                      if (list.isEmpty)
                        _emptyCard(l10n)
                      else
                        ...list.map((c) => _complaintCard(c, l10n)),

                      SizedBox(height: 80.h),
                    ],
                  ),
      ),
    );
  }

  Widget _summaryChip(
      String label, int count, Color color, Color bg) {
    return Expanded(
      child: Container(
        padding: EdgeInsets.symmetric(vertical: 10.h),
        decoration: BoxDecoration(
          color: bg,
          borderRadius: BorderRadius.circular(10.r),
          border: Border.all(color: color.withValues(alpha: 0.2)),
        ),
        child: Column(
          children: [
            Text('$count',
                style: GoogleFonts.poppins(
                    fontSize: 18.sp,
                    fontWeight: FontWeight.w700,
                    color: color)),
            Text(label,
                style: GoogleFonts.poppins(
                    fontSize: 10.sp,
                    fontWeight: FontWeight.w600,
                    color: const Color(0xFF64748B))),
          ],
        ),
      ),
    );
  }

  // ─── Filters ────────────────────────────
  Widget _buildFilters(AppLocalizations l10n) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18.r),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      child: Column(
        children: [
          Padding(
            padding: EdgeInsets.all(14.w),
            child: TextField(
              controller: _searchCtrl,
              style: GoogleFonts.poppins(fontSize: 14.sp),
              decoration: InputDecoration(
                prefixIcon: Icon(Icons.search_rounded,
                    size: 22.w, color: const Color(0xFF94A3B8)),
                hintText: "Search complaints...",
                hintStyle: GoogleFonts.poppins(
                    fontSize: 13.sp, color: const Color(0xFFCBD5E1)),
                filled: true,
                fillColor: const Color(0xFFF8FAFC),
                isDense: true,
                contentPadding: EdgeInsets.symmetric(
                    horizontal: 14.w, vertical: 12.h),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12.r),
                  borderSide:
                      const BorderSide(color: Color(0xFFE2E8F0)),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12.r),
                  borderSide:
                      const BorderSide(color: Color(0xFFE2E8F0)),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12.r),
                  borderSide:
                      const BorderSide(color: Color(0xFF2563EB)),
                ),
                suffixIcon: _search.isEmpty
                    ? null
                    : IconButton(
                        onPressed: () => _searchCtrl.clear(),
                        icon: Icon(Icons.close_rounded,
                            size: 18.w,
                            color: const Color(0xFF94A3B8)),
                      ),
              ),
            ),
          ),
          // Filter toggle
          GestureDetector(
            onTap: () =>
                setState(() => _filtersExpanded = !_filtersExpanded),
            child: Container(
              padding: EdgeInsets.symmetric(
                  horizontal: 14.w, vertical: 10.h),
              decoration: BoxDecoration(
                border: Border(
                    top: BorderSide(color: const Color(0xFFE2E8F0))),
              ),
              child: Row(
                children: [
                  Icon(Icons.tune_rounded,
                      size: 18.w, color: const Color(0xFF64748B)),
                  SizedBox(width: 8.w),
                  Text(
                    "Filters",
                    style: GoogleFonts.poppins(
                      fontSize: 13.sp,
                      fontWeight: FontWeight.w600,
                      color: const Color(0xFF64748B),
                    ),
                  ),
                  if (_statusFilter != "ALL" ||
                      _wardFilter != "ALL" ||
                      _vendorFilter != "ALL") ...[
                    SizedBox(width: 6.w),
                    Container(
                      width: 8.w,
                      height: 8.w,
                      decoration: const BoxDecoration(
                        color: Color(0xFF2563EB),
                        shape: BoxShape.circle,
                      ),
                    ),
                  ],
                  const Spacer(),
                  Icon(
                    _filtersExpanded
                        ? Icons.keyboard_arrow_up_rounded
                        : Icons.keyboard_arrow_down_rounded,
                    size: 22.w,
                    color: const Color(0xFF94A3B8),
                  ),
                ],
              ),
            ),
          ),
          // Expandable filters
          if (_filtersExpanded)
            Container(
              padding: EdgeInsets.fromLTRB(14.w, 0, 14.w, 14.w),
              child: Column(
                children: [
                  SizedBox(height: 8.h),
                  _filterDropdown(
                    label: "Status",
                    value: _statusFilter,
                    items: const [
                      "ALL",
                      "OPEN",
                      "IN_REVIEW",
                      "RESOLVED",
                      "REJECTED"
                    ],
                    allLabel: "All Status",
                    onChanged: (v) =>
                        setState(() => _statusFilter = v ?? "ALL"),
                  ),
                  SizedBox(height: 10.h),
                  _filterDropdown(
                    label: "Ward",
                    value: _wardFilter,
                    items: _wardOptions,
                    allLabel: "All Wards",
                    onChanged: (v) =>
                        setState(() => _wardFilter = v ?? "ALL"),
                  ),
                  SizedBox(height: 10.h),
                  _filterDropdown(
                    label: "Vendor",
                    value: _vendorFilter,
                    items: _vendorOptions,
                    allLabel: "All Vendors",
                    onChanged: (v) =>
                        setState(() => _vendorFilter = v ?? "ALL"),
                  ),
                  SizedBox(height: 10.h),
                  SizedBox(
                    width: double.infinity,
                    child: OutlinedButton.icon(
                      onPressed: _clearFilters,
                      icon: Icon(Icons.clear_rounded,
                          size: 18.w,
                          color: const Color(0xFF64748B)),
                      label: Text("Clear Filters",
                          style: GoogleFonts.poppins(
                              fontWeight: FontWeight.w600,
                              color: const Color(0xFF64748B))),
                      style: OutlinedButton.styleFrom(
                        side: const BorderSide(
                            color: Color(0xFFE2E8F0)),
                        shape: RoundedRectangleBorder(
                            borderRadius:
                                BorderRadius.circular(10.r)),
                      ),
                    ),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }

  Widget _filterDropdown({
    required String label,
    required String value,
    required List<String> items,
    required String allLabel,
    required void Function(String?) onChanged,
  }) {
    return DropdownButtonFormField<String>(
      isExpanded: true,
      initialValue: value,
      items: items.map((v) {
        return DropdownMenuItem(
          value: v,
          child: Text(
            v == "ALL" ? allLabel : v,
            overflow: TextOverflow.ellipsis,
            maxLines: 1,
            style: GoogleFonts.poppins(fontSize: 13.sp),
          ),
        );
      }).toList(),
      onChanged: onChanged,
      style: GoogleFonts.poppins(
          fontSize: 13.sp, color: const Color(0xFF0F172A)),
      decoration: InputDecoration(
        labelText: label,
        labelStyle:
            GoogleFonts.poppins(color: const Color(0xFF94A3B8)),
        filled: true,
        fillColor: const Color(0xFFF8FAFC),
        isDense: true,
        contentPadding:
            EdgeInsets.symmetric(horizontal: 14.w, vertical: 12.h),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12.r),
          borderSide: const BorderSide(color: Color(0xFFE2E8F0)),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12.r),
          borderSide: const BorderSide(color: Color(0xFFE2E8F0)),
        ),
      ),
    );
  }

  // ─── Empty State ────────────────────────
  Widget _emptyCard(AppLocalizations l10n) {
    return Container(
      width: double.infinity,
      padding: EdgeInsets.symmetric(vertical: 40.h),
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
            child: Icon(Icons.search_off_rounded,
                color: const Color(0xFF94A3B8), size: 28.w),
          ),
          SizedBox(height: 12.h),
          Text(l10n.noComplaintsYet,
              style: GoogleFonts.poppins(
                  fontSize: 15.sp,
                  fontWeight: FontWeight.w600,
                  color: const Color(0xFF64748B))),
        ],
      ),
    );
  }

  // ─── Complaint Card ─────────────────────
  Widget _complaintCard(Map<String, dynamic> c, AppLocalizations l10n) {
    final id = (c['id'] ?? '').toString();
    final status = _complaintStatus(c['status']);
    final msg = (c['message'] ?? '').toString();
    final wardName = (c['wardName'] ?? '').toString();
    final vendorName = (c['vendorName'] ?? '').toString();
    final createdAt = _parseDateTime(c['createdAt']);
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
            // Status icon
            Container(
              width: 44.w,
              height: 44.w,
              decoration: BoxDecoration(
                color: _statusBgColor(status),
                borderRadius: BorderRadius.circular(12.r),
                border: Border.all(
                    color:
                        _statusFgColor(status).withValues(alpha: 0.2)),
              ),
              child: Icon(_statusIcon(status),
                  color: _statusFgColor(status), size: 22.w),
            ),
            SizedBox(width: 12.w),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Title + status
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
                          borderRadius: BorderRadius.circular(8.r),
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
                  // Meta info
                  Row(
                    children: [
                      Icon(Icons.tag_rounded,
                          size: 12.w,
                          color: const Color(0xFF94A3B8)),
                      SizedBox(width: 3.w),
                      Text(id,
                          style: GoogleFonts.poppins(
                              fontSize: 12.sp,
                              color: const Color(0xFF94A3B8))),
                      if (wardName.trim().isNotEmpty) ...[
                        SizedBox(width: 8.w),
                        Icon(Icons.location_city_rounded,
                            size: 12.w,
                            color: const Color(0xFF94A3B8)),
                        SizedBox(width: 3.w),
                        Expanded(
                          child: Text(wardName,
                              style: GoogleFonts.poppins(
                                  fontSize: 12.sp,
                                  color: const Color(0xFF94A3B8)),
                              overflow: TextOverflow.ellipsis),
                        ),
                      ],
                    ],
                  ),
                  if (vendorName.trim().isNotEmpty) ...[
                    SizedBox(height: 4.h),
                    Row(
                      children: [
                        Icon(Icons.local_shipping_outlined,
                            size: 12.w,
                            color: const Color(0xFF94A3B8)),
                        SizedBox(width: 3.w),
                        Expanded(
                          child: Text(vendorName,
                              style: GoogleFonts.poppins(
                                  fontSize: 12.sp,
                                  fontWeight: FontWeight.w600,
                                  color: const Color(0xFF64748B)),
                              overflow: TextOverflow.ellipsis),
                        ),
                      ],
                    ),
                  ],
                  if (createdAt != null) ...[
                    SizedBox(height: 4.h),
                    Row(
                      children: [
                        Icon(Icons.access_time_rounded,
                            size: 12.w,
                            color: const Color(0xFF94A3B8)),
                        SizedBox(width: 3.w),
                        Text(
                          DateFormat('MMM dd, h:mm a')
                              .format(createdAt),
                          style: GoogleFonts.poppins(
                              fontSize: 12.sp,
                              color: const Color(0xFF94A3B8)),
                        ),
                      ],
                    ),
                  ],
                  SizedBox(height: 8.h),
                  // Message preview
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
            Padding(
              padding: EdgeInsets.only(top: 10.h, left: 4.w),
              child: Icon(Icons.chevron_right_rounded,
                  size: 20.w, color: const Color(0xFFCBD5E1)),
            ),
          ],
        ),
      ),
    );
  }
}