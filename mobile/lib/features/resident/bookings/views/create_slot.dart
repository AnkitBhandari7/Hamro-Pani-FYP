import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';

import 'package:fyp/l10n/app_localizations.dart';
import '../controllers/create_slot_controller.dart';

class ManageSlotsScreen extends ConsumerStatefulWidget {
  const ManageSlotsScreen({super.key});

  @override
  ConsumerState<ManageSlotsScreen> createState() => _ManageSlotsScreenState();
}

class _ManageSlotsScreenState extends ConsumerState<ManageSlotsScreen> {
  final TextEditingController _bookingSlotsController = TextEditingController();
  final TextEditingController _priceController = TextEditingController();
  final TextEditingController _tankerLitersController = TextEditingController();
  final TextEditingController _routeController = TextEditingController();

  @override
  void dispose() {
    _bookingSlotsController.dispose();
    _priceController.dispose();
    _tankerLitersController.dispose();
    _routeController.dispose();
    super.dispose();
  }

  DateTime? _asLocalDateTime(dynamic raw) {
    if (raw == null) return null;
    if (raw is DateTime) return raw.toLocal();
    if (raw is String && raw.trim().isNotEmpty) {
      try {
        return DateTime.parse(raw).toLocal();
      } catch (_) {
        return null;
      }
    }
    return null;
  }

  DateTime _baseDateForFilter(CreateSlotState state) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    if (state.selectedDateFilter == 'Tomorrow') {
      return today.add(const Duration(days: 1));
    }
    return today;
  }

  Future<void> _selectTime() async {
    final controller = ref.read(createSlotControllerProvider.notifier);

    final picked = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.now(),
    );

    if (picked != null) controller.setStartTime(picked);
  }

  Future<void> _onPublishPressed() async {
    final l10n = AppLocalizations.of(context)!;
    final controller = ref.read(createSlotControllerProvider.notifier);

    final error = await controller.publishSlot(
      bookingSlotsText: _bookingSlotsController.text,
      priceText: _priceController.text,
      routeText: _routeController.text,
      tankerCapacityLitersText: _tankerLitersController.text,
    );

    if (!mounted) return;

    if (error == null) {
      _bookingSlotsController.clear();
      _priceController.clear();
      _tankerLitersController.clear();
      _routeController.clear();
      controller.resetForm();
    }

    if (error != null && error.toLowerCase().contains("slot already exists")) {
      await showDialog(
        context: context,
        builder: (_) => AlertDialog(
          shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(18.r)),
          title: Text(
            l10n.cannotPublishSlot,
            style: GoogleFonts.poppins(fontWeight: FontWeight.w700),
          ),
          content: Text(error, style: GoogleFonts.poppins()),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text(
                l10n.ok,
                style: GoogleFonts.poppins(color: const Color(0xFF2563EB)),
              ),
            ),
          ],
        ),
      );
    }

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(error ?? l10n.slotPublishedSuccessfully),
        backgroundColor:
            error == null ? const Color(0xFF16A34A) : const Color(0xFFEF4444),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        duration: const Duration(seconds: 4),
      ),
    );
  }

  String _formattedEndTime(CreateSlotState state, AppLocalizations l10n) {
    final time = state.selectedStartTime;
    if (time == null) return l10n.endTime;

    final base = _baseDateForFilter(state);
    final start = DateTime(
      base.year,
      base.month,
      base.day,
      time.hour,
      time.minute,
    );
    final end = start.add(const Duration(hours: 2));

    return DateFormat('hh:mm a').format(end);
  }

  String _localizeChipLabel(AppLocalizations l10n, String label) {
    final v = label.trim().toUpperCase();
    if (v == 'TODAY') return l10n.today;
    if (v == 'TOMORROW') return l10n.tomorrow;
    return label;
  }

  Future<void> _showEditDialog(Map<String, dynamic> slot) async {
    final l10n = AppLocalizations.of(context)!;
    final controller = ref.read(createSlotControllerProvider.notifier);

    final slotsCtrl = TextEditingController(
      text: (slot['total'] ?? '').toString(),
    );
    final priceCtrl = TextEditingController(
      text: (slot['price'] ?? '').toString(),
    );
    final litersCtrl = TextEditingController(
      text: (slot['tankerCapacityLiters'] ?? '12000').toString(),
    );

    final startDt = _asLocalDateTime(slot['startDt'] ?? slot['startTime']);
    TimeOfDay pickedTime =
        startDt != null ? TimeOfDay.fromDateTime(startDt) : TimeOfDay.now();

    final ok = await showDialog<bool>(
      context: context,
      builder: (_) {
        return AlertDialog(
          shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(18.r)),
          title: Text(
            l10n.editSlot,
            style: GoogleFonts.poppins(
                fontWeight: FontWeight.w700, fontSize: 18.sp),
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Time picker row
              Container(
                padding: EdgeInsets.all(12.w),
                decoration: BoxDecoration(
                  color: const Color(0xFFF8FAFC),
                  borderRadius: BorderRadius.circular(12.r),
                  border: Border.all(color: const Color(0xFFE2E8F0)),
                ),
                child: Row(
                  children: [
                    Icon(Icons.access_time_rounded,
                        size: 18.w, color: const Color(0xFF2563EB)),
                    SizedBox(width: 8.w),
                    Expanded(
                      child: Text(
                        l10n.startTimeLabel(pickedTime.format(context)),
                        style: GoogleFonts.poppins(fontSize: 13.sp),
                      ),
                    ),
                    GestureDetector(
                      onTap: () async {
                        final t = await showTimePicker(
                          context: context,
                          initialTime: pickedTime,
                        );
                        if (t != null) {
                          pickedTime = t;
                          (context as Element).markNeedsBuild();
                        }
                      },
                      child: Container(
                        padding: EdgeInsets.symmetric(
                            horizontal: 10.w, vertical: 4.h),
                        decoration: BoxDecoration(
                          color: const Color(0xFFEFF6FF),
                          borderRadius: BorderRadius.circular(8.r),
                        ),
                        child: Text(
                          l10n.change,
                          style: GoogleFonts.poppins(
                            fontSize: 12.sp,
                            fontWeight: FontWeight.w600,
                            color: const Color(0xFF2563EB),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              SizedBox(height: 12.h),
              _editField(litersCtrl, l10n.tankerCapacityLiters,
                  Icons.water_drop_outlined),
              SizedBox(height: 10.h),
              _editField(slotsCtrl, l10n.bookingSlots,
                  Icons.confirmation_number_outlined),
              SizedBox(height: 10.h),
              _editField(
                  priceCtrl, l10n.priceNpr, Icons.payments_outlined),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: Text(l10n.cancel,
                  style: GoogleFonts.poppins(color: const Color(0xFF64748B))),
            ),
            ElevatedButton(
              onPressed: () => Navigator.pop(context, true),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF2563EB),
                foregroundColor: Colors.white,
                elevation: 0,
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10.r)),
              ),
              child: Text(l10n.save,
                  style: GoogleFonts.poppins(fontWeight: FontWeight.w600)),
            ),
          ],
        );
      },
    );

    if (ok != true) return;

    final newSlots = int.tryParse(slotsCtrl.text.trim());
    final newPrice = int.tryParse(priceCtrl.text.trim());
    final newLiters = int.tryParse(litersCtrl.text.trim());

    if (newSlots == null ||
        newSlots <= 0 ||
        newPrice == null ||
        newPrice <= 0 ||
        newLiters == null ||
        newLiters <= 0) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(l10n.invalidInputs),
          backgroundColor: const Color(0xFFEF4444),
          behavior: SnackBarBehavior.floating,
        ),
      );
      return;
    }

    final base = (startDt ?? DateTime.now()).toLocal();
    final newStart = DateTime(
      base.year,
      base.month,
      base.day,
      pickedTime.hour,
      pickedTime.minute,
    );
    final newEnd = newStart.add(const Duration(hours: 2));

    final err = await controller.updateSlot(
      slotId: slot['slotId'] as int,
      location: (slot['location'] ?? '').toString(),
      startTime: newStart,
      endTime: newEnd,
      bookingSlots: newSlots,
      price: newPrice,
      tankerCapacityLiters: newLiters,
    );

    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(err ?? l10n.slotUpdated),
        backgroundColor:
            err == null ? const Color(0xFF16A34A) : const Color(0xFFEF4444),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  Widget _editField(
      TextEditingController ctrl, String label, IconData icon) {
    return TextField(
      controller: ctrl,
      keyboardType: TextInputType.number,
      style: GoogleFonts.poppins(fontSize: 14.sp, fontWeight: FontWeight.w600),
      decoration: InputDecoration(
        labelText: label,
        labelStyle: GoogleFonts.poppins(
            fontSize: 13.sp, color: const Color(0xFF94A3B8)),
        prefixIcon: Icon(icon, size: 20.w, color: const Color(0xFF94A3B8)),
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
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12.r),
          borderSide: const BorderSide(color: Color(0xFF2563EB)),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final state = ref.watch(createSlotControllerProvider);
    final controller = ref.read(createSlotControllerProvider.notifier);

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
          l10n.manageSlots,
          style: GoogleFonts.poppins(
            fontSize: 18.sp,
            fontWeight: FontWeight.w700,
            color: const Color(0xFF0F172A),
          ),
        ),
        centerTitle: true,
        actions: [
          GestureDetector(
            onTap: () => controller.loadInitialData(),
            child: Container(
              margin: EdgeInsets.only(right: 12.w),
              padding: EdgeInsets.symmetric(horizontal: 10.w, vertical: 6.h),
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
      body: SingleChildScrollView(
        padding: EdgeInsets.all(16.w),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildOpenNewSlotCard(l10n, state),
            SizedBox(height: 24.h),
            _buildActiveSlotsSection(l10n, state, controller),
          ],
        ),
      ),
    );
  }

  // ─── Create Slot Card ──────────────────────
  Widget _buildOpenNewSlotCard(AppLocalizations l10n, CreateSlotState state) {
    final controller = ref.read(createSlotControllerProvider.notifier);

    return Container(
      padding: EdgeInsets.all(20.w),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20.r),
        border: Border.all(color: const Color(0xFFE2E8F0)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          Row(
            children: [
              Container(
                padding: EdgeInsets.all(10.w),
                decoration: BoxDecoration(
                  color: const Color(0xFFEFF6FF),
                  borderRadius: BorderRadius.circular(12.r),
                ),
                child: Icon(Icons.add_circle_outline_rounded,
                    size: 22.w, color: const Color(0xFF2563EB)),
              ),
              SizedBox(width: 12.w),
              Text(
                l10n.openNewSlot,
                style: GoogleFonts.poppins(
                  fontSize: 18.sp,
                  fontWeight: FontWeight.w700,
                  color: const Color(0xFF0F172A),
                ),
              ),
            ],
          ),
          SizedBox(height: 20.h),

          // Date selector
          Text(
            l10n.selectDate.toUpperCase(),
            style: GoogleFonts.poppins(
              fontSize: 11.sp,
              fontWeight: FontWeight.w600,
              color: const Color(0xFF94A3B8),
              letterSpacing: 0.5,
            ),
          ),
          SizedBox(height: 8.h),
          Row(
            children: [
              _dateChip(
                l10n.today,
                state.selectedDateFilter == 'Today',
                () => controller.setDateFilter('Today'),
              ),
              SizedBox(width: 10.w),
              _dateChip(
                l10n.tomorrow,
                state.selectedDateFilter == 'Tomorrow',
                () => controller.setDateFilter('Tomorrow'),
              ),
            ],
          ),
          SizedBox(height: 18.h),

          // Time pickers
          Text(
            'TIME SLOT',
            style: GoogleFonts.poppins(
              fontSize: 11.sp,
              fontWeight: FontWeight.w600,
              color: const Color(0xFF94A3B8),
              letterSpacing: 0.5,
            ),
          ),
          SizedBox(height: 8.h),
          Row(
            children: [
              Expanded(
                child: GestureDetector(
                  onTap: _selectTime,
                  child: Container(
                    padding:
                        EdgeInsets.symmetric(horizontal: 14.w, vertical: 12.h),
                    decoration: BoxDecoration(
                      color: const Color(0xFFF8FAFC),
                      borderRadius: BorderRadius.circular(12.r),
                      border: Border.all(color: const Color(0xFFE2E8F0)),
                    ),
                    child: Row(
                      children: [
                        Icon(Icons.play_circle_outline_rounded,
                            size: 18.w, color: const Color(0xFF2563EB)),
                        SizedBox(width: 8.w),
                        Expanded(
                          child: Text(
                            controller.formattedSelectedTime,
                            style: GoogleFonts.poppins(
                              fontSize: 13.sp,
                              fontWeight: FontWeight.w600,
                              color: const Color(0xFF334155),
                            ),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
              SizedBox(width: 10.w),
              Expanded(
                child: Container(
                  padding:
                      EdgeInsets.symmetric(horizontal: 14.w, vertical: 12.h),
                  decoration: BoxDecoration(
                    color: const Color(0xFFF8FAFC),
                    borderRadius: BorderRadius.circular(12.r),
                    border: Border.all(color: const Color(0xFFE2E8F0)),
                  ),
                  child: Row(
                    children: [
                      Icon(Icons.stop_circle_outlined,
                          size: 18.w, color: const Color(0xFFF97316)),
                      SizedBox(width: 8.w),
                      Expanded(
                        child: Text(
                          _formattedEndTime(state, l10n),
                          style: GoogleFonts.poppins(
                            fontSize: 13.sp,
                            fontWeight: FontWeight.w600,
                            color: const Color(0xFF64748B),
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
          SizedBox(height: 18.h),

          // Input fields
          _inputField(
            controller: _tankerLitersController,
            label: l10n.tankerCapacityLiters,
            icon: Icons.water_drop_outlined,
            iconColor: const Color(0xFF2563EB),
          ),
          SizedBox(height: 12.h),
          _inputField(
            controller: _bookingSlotsController,
            label: l10n.totalBookingSlots,
            icon: Icons.confirmation_number_outlined,
            iconColor: const Color(0xFF7C3AED),
          ),
          SizedBox(height: 12.h),
          _inputField(
            controller: _priceController,
            label: l10n.priceNpr,
            icon: Icons.payments_outlined,
            iconColor: const Color(0xFF16A34A),
          ),
          SizedBox(height: 12.h),
          _inputField(
            controller: _routeController,
            label: l10n.deliveryRouteArea,
            icon: Icons.route_rounded,
            iconColor: const Color(0xFFF97316),
            hint: l10n.deliveryRouteHint,
            isNumber: false,
          ),
          SizedBox(height: 20.h),

          // Publish Button
          SizedBox(
            width: double.infinity,
            height: 48.h,
            child: ElevatedButton(
              onPressed: state.isPublishing ? null : _onPublishPressed,
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF2563EB),
                foregroundColor: Colors.white,
                elevation: 0,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14.r),
                ),
              ),
              child: state.isPublishing
                  ? SizedBox(
                      height: 20.w,
                      width: 20.w,
                      child: const CircularProgressIndicator(
                        strokeWidth: 2,
                        color: Colors.white,
                      ),
                    )
                  : Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.publish_rounded,
                            size: 20.w, color: Colors.white),
                        SizedBox(width: 8.w),
                        Text(
                          l10n.publishSlotArrow,
                          style: GoogleFonts.poppins(
                            fontSize: 15.sp,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ],
                    ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _inputField({
    required TextEditingController controller,
    required String label,
    required IconData icon,
    required Color iconColor,
    String? hint,
    bool isNumber = true,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label.toUpperCase(),
          style: GoogleFonts.poppins(
            fontSize: 11.sp,
            fontWeight: FontWeight.w600,
            color: const Color(0xFF94A3B8),
            letterSpacing: 0.5,
          ),
        ),
        SizedBox(height: 6.h),
        TextField(
          controller: controller,
          keyboardType: isNumber ? TextInputType.number : TextInputType.text,
          style: GoogleFonts.poppins(
            fontSize: 14.sp,
            fontWeight: FontWeight.w600,
            color: const Color(0xFF0F172A),
          ),
          decoration: InputDecoration(
            hintText: hint,
            hintStyle: GoogleFonts.poppins(
              fontSize: 13.sp,
              color: const Color(0xFFCBD5E1),
              fontWeight: FontWeight.w400,
            ),
            prefixIcon:
                Icon(icon, size: 20.w, color: iconColor),
            filled: true,
            fillColor: const Color(0xFFF8FAFC),
            isDense: true,
            contentPadding:
                EdgeInsets.symmetric(horizontal: 14.w, vertical: 14.h),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12.r),
              borderSide: const BorderSide(color: Color(0xFFE2E8F0)),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12.r),
              borderSide: const BorderSide(color: Color(0xFFE2E8F0)),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12.r),
              borderSide: const BorderSide(color: Color(0xFF2563EB)),
            ),
          ),
        ),
      ],
    );
  }

  Widget _dateChip(String label, bool isSelected, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: EdgeInsets.symmetric(horizontal: 20.w, vertical: 10.h),
        decoration: BoxDecoration(
          color: isSelected ? const Color(0xFF2563EB) : Colors.white,
          borderRadius: BorderRadius.circular(10.r),
          border: Border.all(
            color: isSelected
                ? const Color(0xFF2563EB)
                : const Color(0xFFE2E8F0),
          ),
          boxShadow: isSelected
              ? [
                  BoxShadow(
                    color: const Color(0xFF2563EB).withValues(alpha: 0.2),
                    blurRadius: 8,
                    offset: const Offset(0, 3),
                  ),
                ]
              : [],
        ),
        child: Text(
          label,
          style: GoogleFonts.poppins(
            color: isSelected ? Colors.white : const Color(0xFF64748B),
            fontSize: 13.sp,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
    );
  }

  // ─── Active Slots Section ──────────────────
  Widget _buildActiveSlotsSection(
    AppLocalizations l10n,
    CreateSlotState state,
    CreateSlotController controller,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Container(
              padding: EdgeInsets.all(10.w),
              decoration: BoxDecoration(
                color: const Color(0xFFF0FDF4),
                borderRadius: BorderRadius.circular(12.r),
              ),
              child: Icon(Icons.event_available_rounded,
                  size: 22.w, color: const Color(0xFF16A34A)),
            ),
            SizedBox(width: 12.w),
            Text(
              l10n.activeSlots,
              style: GoogleFonts.poppins(
                fontSize: 18.sp,
                fontWeight: FontWeight.w700,
                color: const Color(0xFF0F172A),
              ),
            ),
            const Spacer(),
            if (state.slots.isNotEmpty)
              Container(
                padding:
                    EdgeInsets.symmetric(horizontal: 10.w, vertical: 4.h),
                decoration: BoxDecoration(
                  color: const Color(0xFFF1F5F9),
                  borderRadius: BorderRadius.circular(8.r),
                ),
                child: Text(
                  '${state.slots.length}',
                  style: GoogleFonts.poppins(
                    fontSize: 13.sp,
                    fontWeight: FontWeight.w700,
                    color: const Color(0xFF64748B),
                  ),
                ),
              ),
          ],
        ),
        SizedBox(height: 16.h),
        if (state.isLoading)
          ...[_shimmerSlotCard(), _shimmerSlotCard()]
        else if (state.slots.isEmpty)
          Container(
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
                  child: Icon(Icons.event_busy_rounded,
                      color: const Color(0xFF94A3B8), size: 28.w),
                ),
                SizedBox(height: 12.h),
                Text(
                  l10n.noActiveSlots,
                  style: GoogleFonts.poppins(
                    fontSize: 15.sp,
                    fontWeight: FontWeight.w600,
                    color: const Color(0xFF64748B),
                  ),
                ),
              ],
            ),
          )
        else
          ...state.slots.map(
            (slot) => Padding(
              padding: EdgeInsets.only(bottom: 14.h),
              child: _buildSlotCard(l10n, slot, controller),
            ),
          ),
        SizedBox(height: 40.h),
      ],
    );
  }

  Widget _shimmerSlotCard() {
    return Container(
      margin: EdgeInsets.only(bottom: 14.h),
      padding: EdgeInsets.all(16.w),
      decoration: BoxDecoration(
        color: const Color(0xFFF8FAFC),
        borderRadius: BorderRadius.circular(18.r),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 80.w,
                height: 14.h,
                decoration: BoxDecoration(
                  color: const Color(0xFFE2E8F0),
                  borderRadius: BorderRadius.circular(6.r),
                ),
              ),
              const Spacer(),
              Container(
                width: 50.w,
                height: 24.h,
                decoration: BoxDecoration(
                  color: const Color(0xFFE2E8F0),
                  borderRadius: BorderRadius.circular(8.r),
                ),
              ),
            ],
          ),
          SizedBox(height: 12.h),
          Container(
            width: 180.w,
            height: 12.h,
            decoration: BoxDecoration(
              color: const Color(0xFFE2E8F0),
              borderRadius: BorderRadius.circular(6.r),
            ),
          ),
          SizedBox(height: 12.h),
          Container(
            height: 6.h,
            decoration: BoxDecoration(
              color: const Color(0xFFE2E8F0),
              borderRadius: BorderRadius.circular(3.r),
            ),
          ),
        ],
      ),
    );
  }

  // ─── Slot Card ─────────────────────────────
  Widget _buildSlotCard(
    AppLocalizations l10n,
    Map<String, dynamic> slot,
    CreateSlotController controller,
  ) {
    final int slotId = (slot['slotId'] ?? 0) as int;
    final int booked = (slot['booked'] ?? 0) as int;
    final int totalSlots = (slot['total'] ?? 0) as int;

    final liters = (slot['tankerCapacityLiters'] ?? 12000);
    final double progress = totalSlots == 0 ? 0 : booked / totalSlots;

    final bool isFull = slot['status'] == 'FULL';
    final bool isOpen = slot['status'] == 'OPEN';

    final price = slot['price'];
    final priceText = price == null ? '—' : l10n.nprAmount(price.toString());
    final location = (slot['location'] ?? '').toString();

    final startDt = _asLocalDateTime(slot['startDt'] ?? slot['startTime']);
    final endDt = _asLocalDateTime(slot['endDt'] ?? slot['endTime']);

    final dateTextRaw = (slot['date']?.toString().trim().isNotEmpty ?? false)
        ? slot['date'].toString()
        : (startDt != null
            ? DateFormat('MMM dd').format(startDt).toUpperCase()
            : '—');

    final dateText = _localizeChipLabel(l10n, dateTextRaw);

    final timeText = (slot['time']?.toString().trim().isNotEmpty ?? false)
        ? slot['time'].toString()
        : (startDt != null && endDt != null
            ? '${DateFormat('hh:mm a').format(startDt)} – ${DateFormat('hh:mm a').format(endDt)}'
            : '—');

    final statusLabel = isFull ? l10n.full : l10n.open;

    final availablePct = totalSlots == 0
        ? 0
        : (((totalSlots - booked) / totalSlots) * 100).round();

    // Status colors
    final Color statusBg =
        isFull ? const Color(0xFFFFF7ED) : const Color(0xFFF0FDF4);
    final Color statusFg =
        isFull ? const Color(0xFFF97316) : const Color(0xFF16A34A);

    return Container(
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
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header: date + time + status badge
          Row(
            children: [
              // Date chip
              Container(
                padding:
                    EdgeInsets.symmetric(horizontal: 10.w, vertical: 6.h),
                decoration: BoxDecoration(
                  color: const Color(0xFFEFF6FF),
                  borderRadius: BorderRadius.circular(8.r),
                ),
                child: Text(
                  dateText,
                  style: GoogleFonts.poppins(
                    fontSize: 12.sp,
                    fontWeight: FontWeight.w700,
                    color: const Color(0xFF2563EB),
                  ),
                ),
              ),
              SizedBox(width: 10.w),
              Expanded(
                child: Text(
                  timeText,
                  style: GoogleFonts.poppins(
                    fontSize: 13.sp,
                    fontWeight: FontWeight.w600,
                    color: const Color(0xFF334155),
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              Container(
                padding:
                    EdgeInsets.symmetric(horizontal: 12.w, vertical: 5.h),
                decoration: BoxDecoration(
                  color: statusBg,
                  borderRadius: BorderRadius.circular(8.r),
                  border: Border.all(
                      color: statusFg.withValues(alpha: 0.3)),
                ),
                child: Text(
                  statusLabel,
                  style: GoogleFonts.poppins(
                    fontSize: 11.sp,
                    fontWeight: FontWeight.w700,
                    color: statusFg,
                  ),
                ),
              ),
            ],
          ),
          SizedBox(height: 12.h),

          // Location
          if (location.trim().isNotEmpty)
            Row(
              children: [
                Icon(Icons.location_on_outlined,
                    size: 16.w, color: const Color(0xFF94A3B8)),
                SizedBox(width: 6.w),
                Expanded(
                  child: Text(
                    location,
                    style: GoogleFonts.poppins(
                      fontSize: 13.sp,
                      color: const Color(0xFF64748B),
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
          SizedBox(height: 10.h),

          // Details box
          Container(
            padding: EdgeInsets.all(12.w),
            decoration: BoxDecoration(
              color: const Color(0xFFF8FAFC),
              borderRadius: BorderRadius.circular(12.r),
            ),
            child: Column(
              children: [
                Row(
                  children: [
                    _slotDetailChip(Icons.confirmation_number_outlined,
                        l10n.slotsLabel(totalSlots), const Color(0xFF7C3AED)),
                    SizedBox(width: 12.w),
                    _slotDetailChip(Icons.water_drop_outlined,
                        l10n.tankerLabel(liters), const Color(0xFF2563EB)),
                  ],
                ),
                SizedBox(height: 8.h),
                Row(
                  children: [
                    _slotDetailChip(Icons.payments_outlined,
                        l10n.priceLabel(priceText), const Color(0xFF16A34A)),
                  ],
                ),
              ],
            ),
          ),
          SizedBox(height: 12.h),

          // Progress bar
          Row(
            children: [
              Text(
                l10n.bookedCount(booked, totalSlots),
                style: GoogleFonts.poppins(
                  fontSize: 12.sp,
                  fontWeight: FontWeight.w600,
                  color: const Color(0xFF475569),
                ),
              ),
              const Spacer(),
              Text(
                l10n.availablePercent(availablePct),
                style: GoogleFonts.poppins(
                  fontSize: 12.sp,
                  fontWeight: FontWeight.w600,
                  color: isFull
                      ? const Color(0xFFF97316)
                      : const Color(0xFF16A34A),
                ),
              ),
            ],
          ),
          SizedBox(height: 6.h),
          ClipRRect(
            borderRadius: BorderRadius.circular(4.r),
            child: LinearProgressIndicator(
              value: progress,
              backgroundColor: const Color(0xFFE2E8F0),
              valueColor: AlwaysStoppedAnimation<Color>(
                isFull || !isOpen
                    ? const Color(0xFFF97316)
                    : const Color(0xFF2563EB),
              ),
              minHeight: 6.h,
            ),
          ),
          SizedBox(height: 14.h),

          // Action buttons
          Row(
            children: [
              if (isOpen && !isFull) ...[
                Expanded(
                  child: _actionButton(
                    icon: Icons.edit_outlined,
                    label: l10n.edit,
                    color: const Color(0xFF2563EB),
                    onTap: () => _showEditDialog(slot),
                  ),
                ),
                SizedBox(width: 8.w),
                Expanded(
                  child: _actionButton(
                    icon: Icons.block_rounded,
                    label: l10n.markFull,
                    color: const Color(0xFFF97316),
                    onTap: () async {
                      final err =
                          await controller.markFull(slotId, location);
                      if (!mounted) return;
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text(err ?? l10n.markedFull),
                          backgroundColor: err == null
                              ? const Color(0xFF16A34A)
                              : const Color(0xFFEF4444),
                          behavior: SnackBarBehavior.floating,
                        ),
                      );
                    },
                  ),
                ),
                SizedBox(width: 8.w),
              ],
              Expanded(
                child: _actionButton(
                  icon: Icons.cancel_outlined,
                  label: l10n.cancel,
                  color: const Color(0xFFEF4444),
                  onTap: () async {
                    final err = await controller.deleteSlot(slotId);
                    if (!mounted) return;
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text(err ?? l10n.slotCancelled),
                        backgroundColor: err == null
                            ? const Color(0xFF16A34A)
                            : const Color(0xFFEF4444),
                        behavior: SnackBarBehavior.floating,
                      ),
                    );
                  },
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _slotDetailChip(IconData icon, String text, Color color) {
    return Expanded(
      child: Row(
        children: [
          Icon(icon, size: 14.w, color: color),
          SizedBox(width: 4.w),
          Expanded(
            child: Text(
              text,
              style: GoogleFonts.poppins(
                fontSize: 12.sp,
                color: const Color(0xFF475569),
              ),
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }

  Widget _actionButton({
    required IconData icon,
    required String label,
    required Color color,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: EdgeInsets.symmetric(vertical: 8.h),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.08),
          borderRadius: BorderRadius.circular(10.r),
          border: Border.all(color: color.withValues(alpha: 0.2)),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 16.w, color: color),
            SizedBox(width: 4.w),
            Flexible(
              child: Text(
                label,
                style: GoogleFonts.poppins(
                  fontSize: 12.sp,
                  fontWeight: FontWeight.w600,
                  color: color,
                ),
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
      ),
    );
  }
}