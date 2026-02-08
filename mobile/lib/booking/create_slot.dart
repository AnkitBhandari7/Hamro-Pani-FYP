// mobile/lib/booking/tanker_booking_screen.dart
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';

import 'tanker_booking_controller.dart';

class ManageSlotsScreen extends ConsumerStatefulWidget {
  const ManageSlotsScreen({super.key});

  @override
  ConsumerState<ManageSlotsScreen> createState() =>
      _ManageSlotsScreenState();
}

class _ManageSlotsScreenState extends ConsumerState<ManageSlotsScreen> {
  final TextEditingController _capacityController =
  TextEditingController(text: '12000');
  final TextEditingController _routeController = TextEditingController();

  @override
  void dispose() {
    _capacityController.dispose();
    _routeController.dispose();
    super.dispose();
  }

  Future<void> _selectTime() async {
    final controller =
    ref.read(tankerBookingControllerProvider.notifier);

    final picked = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.now(),
    );

    if (picked != null) {
      controller.setStartTime(picked);
    }
  }

  Future<void> _onPublishPressed() async {
    final controller =
    ref.read(tankerBookingControllerProvider.notifier);

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
    final state = ref.watch(tankerBookingControllerProvider);
    final controller =
    ref.read(tankerBookingControllerProvider.notifier);

    return Scaffold(
      backgroundColor: Colors.grey[50],
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
            icon: Icon(Icons.refresh, color: Colors.black, size: 28.w),
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
            SizedBox(height: 32.h),
            _buildActiveSlotsSection(state),
            SizedBox(height: 100.h),
          ],
        ),
      ),
      bottomNavigationBar: BottomAppBar(
        shape: const CircularNotchedRectangle(),
        notchMargin: 8,
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          children: [
            _buildNavItem(Icons.home, 'Home', false),
            _buildNavItem(Icons.calendar_month, 'Slots', true),
            const SizedBox(width: 60),
            _buildNavItem(Icons.book, 'Book', false),
            _buildNavItem(Icons.notifications, 'Alerts', false),
            _buildNavItem(Icons.person, 'Profile', false),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {},
        backgroundColor: Colors.blue,
        child: Icon(Icons.add, size: 32.w),
      ),
      floatingActionButtonLocation:
      FloatingActionButtonLocation.centerDocked,
    );
  }

  Widget _buildOpenNewSlotCard(
      TankerBookingState state,
      TankerBookingController controller,
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
          Text(
            'Open New Slot',
            style: GoogleFonts.poppins(
              fontSize: 18.sp,
              fontWeight: FontWeight.w600,
            ),
          ),
          SizedBox(height: 20.h),

          Text(
            'DATE',
            style: GoogleFonts.poppins(
              fontSize: 12.sp,
              color: Colors.grey[600],
            ),
          ),
          SizedBox(height: 8.h),
          Wrap(
            spacing: 12.w,
            runSpacing: 8.h,
            children: [
              _buildDateChip(
                'Today',
                state.selectedDateFilter == 'Today',
                    () => controller.setDateFilter('Today'),
              ),
              SizedBox(width: 12.w),
              _buildDateChip(
                'Tomorrow',
                state.selectedDateFilter == 'Tomorrow',
                    () => controller.setDateFilter('Tomorrow'),
              ),
              SizedBox(width: 12.w),
              _buildDateChip(
                'mm/dd/yyyy',
                state.selectedDateFilter == 'Custom',
                    () => controller.setDateFilter('Custom'),
              ),
            ],
          ),
          SizedBox(height: 20.h),

          Row(
            children: [
              // START TIME
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
                          mainAxisAlignment:
                          MainAxisAlignment.spaceBetween,
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
              SizedBox(width: 16.w),

              // CAPACITY
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'CAPACITY (L)',
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
                            Icons.water_drop,
                            color: Colors.blue,
                            size: 20.w,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          SizedBox(height: 20.h),

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
              hintText: 'e.g. Baluwatar, Ward 4 & 5',
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

          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: state.isPublishing ? null : _onPublishPressed,
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.blue,
                padding: EdgeInsets.symmetric(vertical: 16.h),
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

  Widget _buildActiveSlotsSection(TankerBookingState state) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
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

  Widget _buildDateChip(
      String label,
      bool isSelected,
      VoidCallback onTap,
      ) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding:
        EdgeInsets.symmetric(horizontal: 16.w, vertical: 10.h),
        decoration: BoxDecoration(
          color: isSelected ? Colors.blue : Colors.grey[100],
          borderRadius: BorderRadius.circular(30.r),
        ),
        child: Text(
          label,
          style: GoogleFonts.poppins(
            color: isSelected ? Colors.white : Colors.black87,
            fontSize: 14.sp,
            fontWeight:
            isSelected ? FontWeight.w600 : FontWeight.normal,
          ),
        ),
      ),
    );
  }

  Widget _buildFilterChip(String label, bool isSelected) {
    return Container(
      padding:
      EdgeInsets.symmetric(horizontal: 16.w, vertical: 8.h),
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
              Container(
                padding: EdgeInsets.symmetric(
                  horizontal: 12.w,
                  vertical: 6.h,
                ),
                decoration: BoxDecoration(
                  color: slot['date'] == 'TODAY'
                      ? Colors.blue[50]
                      : Colors.grey[100],
                  borderRadius: BorderRadius.circular(20.r),
                ),
                child: Text(
                  slot['date'],
                  style: GoogleFonts.poppins(
                    fontSize: 12.sp,
                    color: slot['date'] == 'TODAY'
                        ? Colors.blue
                        : Colors.grey[800],
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
                padding: EdgeInsets.symmetric(
                  horizontal: 12.w,
                  vertical: 6.h,
                ),
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

          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Booked: $booked L',
                style: GoogleFonts.poppins(
                  fontSize: 12.sp,
                  color: Colors.grey[700],
                ),
              ),
              Text(
                'Total: $total L',
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
              isFull || !isOpen ? Colors.orange : Colors.green,
            ),
            minHeight: 8.h,
            borderRadius: BorderRadius.circular(4.r),
          ),
          SizedBox(height: 16.h),

          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              if (isOpen && !isFull) ...[
                _buildActionButton(
                  'Edit Details',
                  Icons.edit,
                  Colors.blue,
                      () {},
                ),
                _buildActionButton(
                  'Mark Full',
                  Icons.block,
                  Colors.orange,
                      () {},
                ),
              ] else ...[
                _buildActionButton(
                  'Cancel Slot',
                  Icons.cancel,
                  Colors.red,
                      () {},
                ),
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
        padding: EdgeInsets.symmetric(
          horizontal: 12.w,
          vertical: 6.h,
        ),
      ),
    );
  }

  Widget _buildNavItem(IconData icon, String label, bool isSelected) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(
          icon,
          color: isSelected ? Colors.blue : Colors.grey,
          size: 24.w,
        ),
        Text(
          label,
          style: GoogleFonts.poppins(
            fontSize: 10.sp,
            color: isSelected ? Colors.blue : Colors.grey,
          ),
        ),
      ],
    );
  }
}