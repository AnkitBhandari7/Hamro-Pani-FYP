import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';

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

    // ✅ Friendly dialog for overlap
    if (error != null && error.toLowerCase().contains("slot already exists")) {
      await showDialog(
        context: context,
        builder: (_) => AlertDialog(
          title: Text(
            "Cannot Publish Slot",
            style: GoogleFonts.poppins(fontWeight: FontWeight.w700),
          ),
          content: Text(error, style: GoogleFonts.poppins()),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text("OK", style: GoogleFonts.poppins(color: Colors.blue)),
            ),
          ],
        ),
      );
    }

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(error ?? 'Slot published successfully'),
        backgroundColor: error == null ? Colors.green : Colors.red,
        duration: const Duration(seconds: 4),
      ),
    );
  }

  String _formattedEndTime(CreateSlotState state) {
    final time = state.selectedStartTime;
    if (time == null) return 'End time';

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

  Future<void> _showEditDialog(Map<String, dynamic> slot) async {
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
    TimeOfDay pickedTime = startDt != null
        ? TimeOfDay.fromDateTime(startDt)
        : TimeOfDay.now();

    final ok = await showDialog<bool>(
      context: context,
      builder: (_) {
        return AlertDialog(
          title: Text(
            'Edit Slot',
            style: GoogleFonts.poppins(fontWeight: FontWeight.w600),
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Text(
                      'Start: ${pickedTime.format(context)}',
                      style: GoogleFonts.poppins(),
                    ),
                  ),
                  TextButton(
                    onPressed: () async {
                      final t = await showTimePicker(
                        context: context,
                        initialTime: pickedTime,
                      );
                      if (t != null) {
                        pickedTime = t;
                        (context as Element).markNeedsBuild();
                      }
                    },
                    child: Text('Change', style: GoogleFonts.poppins()),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              TextField(
                controller: litersCtrl,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(
                  labelText: 'Tanker Capacity (Liters)',
                ),
              ),
              TextField(
                controller: slotsCtrl,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(labelText: 'Booking Slots'),
              ),
              TextField(
                controller: priceCtrl,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(labelText: 'Price (NPR)'),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () => Navigator.pop(context, true),
              child: const Text('Save'),
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
        const SnackBar(
          content: Text('Invalid inputs'),
          backgroundColor: Colors.red,
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
        content: Text(err ?? 'Slot updated'),
        backgroundColor: err == null ? Colors.green : Colors.red,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(createSlotControllerProvider);
    final controller = ref.read(createSlotControllerProvider.notifier);

    return Scaffold(
      backgroundColor: Colors.grey[100],
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        title: Text(
          'Manage Slots',
          style: GoogleFonts.poppins(
            fontSize: 20.sp,
            fontWeight: FontWeight.w600,
            color: Colors.black,
          ),
        ),
        centerTitle: true,
        actions: [
          IconButton(
            icon: Icon(Icons.refresh, color: Colors.black87, size: 24.w),
            onPressed: () => controller.loadInitialData(),
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: EdgeInsets.all(16.w),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildOpenNewSlotCard(state),
            SizedBox(height: 24.h),
            _buildActiveSlotsSection(state, controller),
          ],
        ),
      ),
    );
  }

  Widget _buildOpenNewSlotCard(CreateSlotState state) {
    final controller = ref.read(createSlotControllerProvider.notifier);

    return Container(
      padding: EdgeInsets.all(20.w),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20.r),
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
          Text(
            'Open New Slot',
            style: GoogleFonts.poppins(
              fontSize: 18.sp,
              fontWeight: FontWeight.w600,
            ),
          ),
          SizedBox(height: 14.h),

          Text(
            'SELECT DATE',
            style: GoogleFonts.poppins(
              fontSize: 12.sp,
              color: Colors.grey[600],
            ),
          ),
          SizedBox(height: 8.h),
          Wrap(
            spacing: 8.w,
            children: [
              _buildDateChip(
                'Today',
                state.selectedDateFilter == 'Today',
                () => controller.setDateFilter('Today'),
              ),
              _buildDateChip(
                'Tomorrow',
                state.selectedDateFilter == 'Tomorrow',
                () => controller.setDateFilter('Tomorrow'),
              ),
            ],
          ),
          SizedBox(height: 16.h),

          Row(
            children: [
              Expanded(
                child: GestureDetector(
                  onTap: _selectTime,
                  child: Container(
                    padding: EdgeInsets.symmetric(
                      horizontal: 12.w,
                      vertical: 12.h,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.grey[100],
                      borderRadius: BorderRadius.circular(12.r),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          controller.formattedSelectedTime,
                          style: GoogleFonts.poppins(fontSize: 14.sp),
                        ),
                        Icon(Icons.access_time, size: 20.w, color: Colors.grey),
                      ],
                    ),
                  ),
                ),
              ),
              SizedBox(width: 12.w),
              Expanded(
                child: Container(
                  padding: EdgeInsets.symmetric(
                    horizontal: 12.w,
                    vertical: 12.h,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.grey[100],
                    borderRadius: BorderRadius.circular(12.r),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        _formattedEndTime(state),
                        style: GoogleFonts.poppins(
                          fontSize: 14.sp,
                          color: Colors.grey[800],
                        ),
                      ),
                      Icon(
                        Icons.access_time,
                        size: 20.w,
                        color: Colors.grey[400],
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),

          SizedBox(height: 16.h),

          Text(
            'TANKER CAPACITY (LITERS)',
            style: GoogleFonts.poppins(
              fontSize: 12.sp,
              color: Colors.grey[600],
            ),
          ),
          SizedBox(height: 8.h),
          TextField(
            controller: _tankerLitersController,
            keyboardType: TextInputType.number,
            decoration: InputDecoration(
              filled: true,
              fillColor: Colors.grey[100],
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12.r),
                borderSide: BorderSide.none,
              ),
            ),
          ),
          SizedBox(height: 12.h),

          Text(
            'TOTAL BOOKING SLOTS',
            style: GoogleFonts.poppins(
              fontSize: 12.sp,
              color: Colors.grey[600],
            ),
          ),
          SizedBox(height: 8.h),
          TextField(
            controller: _bookingSlotsController,
            keyboardType: TextInputType.number,
            decoration: InputDecoration(
              filled: true,
              fillColor: Colors.grey[100],
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12.r),
                borderSide: BorderSide.none,
              ),
            ),
          ),
          SizedBox(height: 12.h),

          Text(
            'PRICE (NPR)',
            style: GoogleFonts.poppins(
              fontSize: 12.sp,
              color: Colors.grey[600],
            ),
          ),
          SizedBox(height: 8.h),
          TextField(
            controller: _priceController,
            keyboardType: TextInputType.number,
            decoration: InputDecoration(
              filled: true,
              fillColor: Colors.grey[100],
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12.r),
                borderSide: BorderSide.none,
              ),
            ),
          ),
          SizedBox(height: 12.h),

          Text(
            'DELIVERY ROUTE / AREA',
            style: GoogleFonts.poppins(
              fontSize: 12.sp,
              color: Colors.grey[600],
            ),
          ),
          SizedBox(height: 8.h),
          TextField(
            controller: _routeController,
            decoration: InputDecoration(
              hintText: 'e.g. Maitidevi, Ward 29',
              filled: true,
              fillColor: Colors.grey[100],
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12.r),
                borderSide: BorderSide.none,
              ),
            ),
          ),
          SizedBox(height: 18.h),

          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: state.isPublishing ? null : _onPublishPressed,
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.blue,
                padding: EdgeInsets.symmetric(vertical: 14.h),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(30.r),
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
                  : Text(
                      'Publish Slot →',
                      style: GoogleFonts.poppins(
                        fontSize: 16.sp,
                        fontWeight: FontWeight.w600,
                        color: Colors.white,
                      ),
                    ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildActiveSlotsSection(
    CreateSlotState state,
    CreateSlotController controller,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Active Slots',
          style: GoogleFonts.poppins(
            fontSize: 18.sp,
            fontWeight: FontWeight.w600,
          ),
        ),
        SizedBox(height: 16.h),

        if (state.isLoading)
          const Center(child: CircularProgressIndicator())
        else if (state.slots.isEmpty)
          Text(
            'No active slots',
            style: GoogleFonts.poppins(color: Colors.grey[600]),
          )
        else
          ...state.slots.map(
            (slot) => Padding(
              padding: EdgeInsets.only(bottom: 16.h),
              child: _buildSlotCard(slot, controller),
            ),
          ),
      ],
    );
  }

  Widget _buildDateChip(String label, bool isSelected, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 10.h),
        decoration: BoxDecoration(
          color: isSelected ? Colors.blue : Colors.grey[100],
          borderRadius: BorderRadius.circular(30.r),
        ),
        child: Text(
          label,
          style: GoogleFonts.poppins(
            color: isSelected ? Colors.white : Colors.black87,
            fontSize: 14.sp,
            fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
          ),
        ),
      ),
    );
  }

  Widget _buildSlotCard(
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
    final priceText = price == null ? '—' : 'NPR $price';
    final location = (slot['location'] ?? '').toString();

    final startDt = _asLocalDateTime(slot['startDt'] ?? slot['startTime']);
    final endDt = _asLocalDateTime(slot['endDt'] ?? slot['endTime']);

    final dateText = (slot['date']?.toString().trim().isNotEmpty ?? false)
        ? slot['date'].toString()
        : (startDt != null
              ? DateFormat('MMM dd').format(startDt).toUpperCase()
              : '—');

    final timeText = (slot['time']?.toString().trim().isNotEmpty ?? false)
        ? slot['time'].toString()
        : (startDt != null && endDt != null
              ? '${DateFormat('hh:mm a').format(startDt)} - ${DateFormat('hh:mm a').format(endDt)}'
              : '—');

    return Container(
      padding: EdgeInsets.all(16.w),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20.r),
        boxShadow: [
          BoxShadow(
            color: Colors.black12,
            blurRadius: 8,
            offset: Offset(0, 4.h),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text(
                dateText,
                style: GoogleFonts.poppins(fontWeight: FontWeight.w700),
              ),
              SizedBox(width: 12.w),
              Expanded(
                child: Text(
                  timeText,
                  style: GoogleFonts.poppins(fontSize: 13.sp),
                ),
              ),
              Container(
                padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 6.h),
                decoration: BoxDecoration(
                  color: isFull ? Colors.orange[100] : Colors.green[100],
                  borderRadius: BorderRadius.circular(20.r),
                ),
                child: Text(
                  (slot['status'] ?? '').toString(),
                  style: GoogleFonts.poppins(
                    fontSize: 12.sp,
                    fontWeight: FontWeight.w600,
                    color: isFull ? Colors.orange[800] : Colors.green[800],
                  ),
                ),
              ),
            ],
          ),
          SizedBox(height: 8.h),

          Text(
            "Location: $location",
            style: GoogleFonts.poppins(color: Colors.grey[700]),
          ),
          SizedBox(height: 8.h),

          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                "Slots: $totalSlots",
                style: GoogleFonts.poppins(
                  fontSize: 12.sp,
                  color: Colors.grey[700],
                ),
              ),
              Text(
                "Tanker: ${liters}L",
                style: GoogleFonts.poppins(
                  fontSize: 12.sp,
                  color: Colors.grey[700],
                ),
              ),
            ],
          ),
          SizedBox(height: 6.h),
          Text(
            "Price: $priceText",
            style: GoogleFonts.poppins(
              fontSize: 12.sp,
              color: Colors.grey[700],
            ),
          ),
          SizedBox(height: 8.h),

          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                '$booked/$totalSlots booked',
                style: GoogleFonts.poppins(
                  fontSize: 12.sp,
                  color: Colors.grey[700],
                ),
              ),
              Text(
                '${totalSlots == 0 ? 0 : (((totalSlots - booked) / totalSlots) * 100).round()}% available',
                style: GoogleFonts.poppins(
                  fontSize: 12.sp,
                  color: Colors.grey[700],
                ),
              ),
            ],
          ),
          SizedBox(height: 8.h),

          LinearProgressIndicator(
            value: progress,
            backgroundColor: Colors.grey[200],
            valueColor: AlwaysStoppedAnimation<Color>(
              isFull || !isOpen ? Colors.orange : Colors.blue,
            ),
            minHeight: 6.h,
            borderRadius: BorderRadius.circular(3.r),
          ),
          SizedBox(height: 12.h),

          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              if (isOpen && !isFull)
                TextButton.icon(
                  onPressed: () => _showEditDialog(slot),
                  icon: const Icon(Icons.edit, color: Colors.blue),
                  label: Text(
                    'Edit',
                    style: GoogleFonts.poppins(
                      color: Colors.blue,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              if (isOpen && !isFull)
                TextButton.icon(
                  onPressed: () async {
                    final err = await controller.markFull(slotId, location);
                    if (!mounted) return;
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text(err ?? 'Marked full'),
                        backgroundColor: err == null
                            ? Colors.green
                            : Colors.red,
                      ),
                    );
                  },
                  icon: const Icon(Icons.block, color: Colors.orange),
                  label: Text(
                    'Mark Full',
                    style: GoogleFonts.poppins(
                      color: Colors.orange,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              TextButton.icon(
                onPressed: () async {
                  final err = await controller.deleteSlot(slotId);
                  if (!mounted) return;
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(err ?? 'Slot cancelled'),
                      backgroundColor: err == null ? Colors.green : Colors.red,
                    ),
                  );
                },
                icon: const Icon(Icons.cancel, color: Colors.red),
                label: Text(
                  'Cancel',
                  style: GoogleFonts.poppins(
                    color: Colors.red,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
