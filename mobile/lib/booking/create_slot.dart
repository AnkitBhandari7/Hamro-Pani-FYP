
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';

import 'create_slot_controller.dart';

class ManageSlotsScreen extends ConsumerStatefulWidget {
  const ManageSlotsScreen({super.key});

  @override
  ConsumerState<ManageSlotsScreen> createState() => _ManageSlotsScreenState();
}

class _ManageSlotsScreenState extends ConsumerState<ManageSlotsScreen> {
  final TextEditingController _capacityController =
  TextEditingController(text: '10'); // Total tanker slots
  final TextEditingController _routeController = TextEditingController();

  @override
  void dispose() {
    _capacityController.dispose();
    _routeController.dispose();
    super.dispose();
  }

  Future<void> _selectTime() async {
    final controller = ref.read(createSlotControllerProvider.notifier);

    final picked = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.now(),
    );

    if (picked != null) {
      controller.setStartTime(picked);
    }
  }

  Future<void> _onPublishPressed() async {
    final controller = ref.read(createSlotControllerProvider.notifier);

    final error = await controller.publishSlot(
      capacityText: _capacityController.text,
      routeText: _routeController.text,
    );

    if (!mounted) return;

    final msg = error ?? 'Slot published successfully';
    final color = error == null ? Colors.green : Colors.red;

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(msg),
        backgroundColor: color,
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
        leading: IconButton(
          icon: Icon(Icons.menu, color: Colors.black, size: 28.w),
          onPressed: () {},
        ),
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
            _buildOpenNewSlotCard(state, controller),
            SizedBox(height: 24.h),
            _buildActiveSlotsSection(state),
            SizedBox(height: 24.h),
          ],
        ),
      ),
    );
  }

  // --------------------------------------------------
  // Helper: derived end time (start + 2 hours)
  // --------------------------------------------------
  String _formattedEndTime(CreateSlotState state) {
    final time = state.selectedStartTime;
    if (time == null) return 'End time';

    final now = DateTime.now();
    final start = DateTime(
      now.year,
      now.month,
      now.day,
      time.hour,
      time.minute,
    );

    final end = start.add(const Duration(hours: 2));

    // DateTime does NOT have hourOfPeriod. Use hour % 12.
    final int hour12 = (end.hour % 12 == 0) ? 12 : (end.hour % 12);
    final String minute = end.minute.toString().padLeft(2, '0');
    final String period = end.hour >= 12 ? 'PM' : 'AM';

    return '$hour12:$minute $period';
  }


  // Open New Slot card

  Widget _buildOpenNewSlotCard(
      CreateSlotState state,
      CreateSlotController controller,
      ) {
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
          // Header with + icon
          Row(
            children: [
              Icon(Icons.add_circle_outline, color: Colors.blue, size: 22.w),
              SizedBox(width: 8.w),
              Text(
                'Open New Slot',
                style: GoogleFonts.poppins(
                  fontSize: 18.sp,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
          SizedBox(height: 20.h),

          // DATE
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
            runSpacing: 8.h,
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
              _buildDateChip(
                'mm/dd/yyyy',
                state.selectedDateFilter == 'Custom',
                    () => controller.setDateFilter('Custom'),
              ),
            ],
          ),
          SizedBox(height: 20.h),

          // START & END TIME row
          Row(
            children: [
              // START
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'START TIME',
                      style: GoogleFonts.poppins(
                        fontSize: 12.sp,
                        color: Colors.grey[600],
                      ),
                    ),
                    SizedBox(height: 8.h),
                    GestureDetector(
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
                              style: GoogleFonts.poppins(
                                fontSize: 14.sp,
                              ),
                            ),
                            Icon(
                              Icons.access_time,
                              size: 20.w,
                              color: Colors.grey,
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              SizedBox(width: 12.w),

              // END
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'END TIME',
                      style: GoogleFonts.poppins(
                        fontSize: 12.sp,
                        color: Colors.grey[600],
                      ),
                    ),
                    SizedBox(height: 8.h),
                    Container(
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
                  ],
                ),
              ),
            ],
          ),
          SizedBox(height: 20.h),

          // TOTAL TANKER SLOTS
          Text(
            'TOTAL TANKER SLOTS',
            style: GoogleFonts.poppins(
              fontSize: 12.sp,
              color: Colors.grey[600],
            ),
          ),
          SizedBox(height: 8.h),
          TextField(
            controller: _capacityController,
            keyboardType: TextInputType.number,
            decoration: InputDecoration(
              filled: true,
              fillColor: Colors.grey[100],
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12.r),
                borderSide: BorderSide.none,
              ),
              suffixIcon: Padding(
                padding: EdgeInsets.all(12.w),
                child: Icon(
                  Icons.local_shipping,
                  color: Colors.blue,
                  size: 20.w,
                ),
              ),
            ),
          ),
          SizedBox(height: 20.h),

          // DELIVERY ROUTE / AREA
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
              hintStyle: GoogleFonts.poppins(color: Colors.grey[500]),
              filled: true,
              fillColor: Colors.grey[100],
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12.r),
                borderSide: BorderSide.none,
              ),
              prefixIcon: Icon(
                Icons.pin_drop,
                color: Colors.grey,
                size: 20.w,
              ),
            ),
          ),
          SizedBox(height: 24.h),

          // Publish button
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


  // Active Slots section

  Widget _buildActiveSlotsSection(CreateSlotState state) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Header + filter
        Row(
          children: [
            Expanded(
              child: Text(
                'Active Slots',
                style: GoogleFonts.poppins(
                  fontSize: 18.sp,
                  fontWeight: FontWeight.w600,
                ),
                overflow: TextOverflow.ellipsis,
              ),
            ),
            SizedBox(width: 8.w),
            Wrap(
              spacing: 8.w,
              children: [
                _buildFilterChip('All', true),
                _buildFilterChip('Pending', false),
              ],
            ),
          ],
        ),
        SizedBox(height: 16.h),
        if (state.isLoading)
          Center(
            child: Padding(
              padding: EdgeInsets.symmetric(vertical: 24.h),
              child: const CircularProgressIndicator(),
            ),
          )
        else if (state.slots.isEmpty)
          Padding(
            padding: EdgeInsets.symmetric(vertical: 24.h),
            child: Text(
              'No active slots',
              style: GoogleFonts.poppins(color: Colors.grey[600]),
            ),
          )
        else
          ...state.slots.map(
                (slot) => Padding(
              padding: EdgeInsets.only(bottom: 16.h),
              child: _buildSlotCard(slot),
            ),
          ),
      ],
    );
  }


  // Small UI helpers

  Widget _buildDateChip(
      String label,
      bool isSelected,
      VoidCallback onTap,
      ) {
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

  Widget _buildFilterChip(String label, bool isSelected) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 8.h),
      decoration: BoxDecoration(
        color: isSelected ? Colors.blue : Colors.grey[200],
        borderRadius: BorderRadius.circular(30.r),
      ),
      child: Text(
        label,
        style: GoogleFonts.poppins(
          fontSize: 12.sp,
          color: isSelected ? Colors.white : Colors.black87,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }

  Widget _buildSlotCard(Map<String, dynamic> slot) {
    final bool isOpen = slot['status'] == 'OPEN';
    final bool isFull = slot['status'] == 'FULL';
    final int booked = (slot['booked'] ?? 0) as int;
    final int total = (slot['total'] ?? 0) as int;
    final double progress = total == 0 ? 0 : booked / total;

    final statusText = isFull ? 'FULL' : slot['status'];

    final double availablePercent = total == 0 ? 0 : ((total - booked) / total * 100);

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
          // Date + time + status
          Row(
            children: [
              Container(
                padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 6.h),
                decoration: BoxDecoration(
                  color: slot['date'] == 'TODAY' ? Colors.blue[50] : Colors.grey[100],
                  borderRadius: BorderRadius.circular(20.r),
                ),
                child: Text(
                  slot['date'],
                  style: GoogleFonts.poppins(
                    fontSize: 12.sp,
                    color: slot['date'] == 'TODAY' ? Colors.blue : Colors.grey[800],
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
              SizedBox(width: 12.w),
              Text(
                slot['time'],
                style: GoogleFonts.poppins(
                  fontSize: 14.sp,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const Spacer(),
              Container(
                padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 6.h),
                decoration: BoxDecoration(
                  color: isFull
                      ? Colors.orange[100]
                      : isOpen
                      ? Colors.green[100]
                      : Colors.orange[100],
                  borderRadius: BorderRadius.circular(20.r),
                ),
                child: Text(
                  statusText,
                  style: GoogleFonts.poppins(
                    fontSize: 12.sp,
                    color: isFull
                        ? Colors.orange[800]
                        : isOpen
                        ? Colors.green[800]
                        : Colors.orange[800],
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
          SizedBox(height: 12.h),

          // Location
          Row(
            children: [
              Icon(Icons.location_on, size: 16.w, color: Colors.grey),
              SizedBox(width: 4.w),
              Text(
                slot['location'],
                style: GoogleFonts.poppins(
                  fontSize: 14.sp,
                  color: Colors.grey[700],
                ),
              ),
            ],
          ),
          SizedBox(height: 12.h),

          // Booked / total + availability %
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                '$booked/$total Slots Booked',
                style: GoogleFonts.poppins(
                  fontSize: 12.sp,
                  color: Colors.grey[700],
                ),
              ),
              Text(
                '${availablePercent.round()}% Available',
                style: GoogleFonts.poppins(
                  fontSize: 12.sp,
                  color: Colors.grey[700],
                ),
              ),
            ],
          ),
          SizedBox(height: 8.h),

          // Progress bar
          LinearProgressIndicator(
            value: progress,
            backgroundColor: Colors.grey[200],
            valueColor: AlwaysStoppedAnimation<Color>(
              isFull || !isOpen ? Colors.orange : Colors.blue,
            ),
            minHeight: 6.h,
            borderRadius: BorderRadius.circular(3.r),
          ),
          SizedBox(height: 16.h),

          // Actions
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              if (isOpen && !isFull) ...[
                _buildActionButton('Edit Details', Icons.edit, Colors.blue, () {}),
                _buildActionButton('Mark Full', Icons.block, Colors.orange, () {}),
              ] else ...[
                _buildActionButton('Cancel Slot', Icons.cancel, Colors.red, () {}),
              ],
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildActionButton(
      String label,
      IconData icon,
      Color color,
      VoidCallback onTap,
      ) {
    return TextButton.icon(
      onPressed: onTap,
      icon: Icon(icon, size: 16.w, color: color),
      label: Text(
        label,
        style: GoogleFonts.poppins(
          fontSize: 12.sp,
          color: color,
          fontWeight: FontWeight.w600,
        ),
      ),
      style: TextButton.styleFrom(
        padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 6.h),
      ),
    );
  }
}