import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';

import 'find_tankers_controller.dart';
import 'vendor_details_screen.dart';

class FindTankersScreen extends StatelessWidget {
  const FindTankersScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (_) => FindTankersController(),
      child: const _FindTankersContent(),
    );
  }
}

class _FindTankersContent extends StatelessWidget {
  const _FindTankersContent();

  Color _getStatusColor(String status) {
    switch (status.toUpperCase()) {
      case 'AVAILABLE':
        return Colors.green;
      case 'BUSY':
        return Colors.orange;
      case 'LOW_STOCK':
        return Colors.amber;
      default:
        return Colors.grey;
    }
  }

  @override
  Widget build(BuildContext context) {
    final controller = Provider.of<FindTankersController>(context);

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.arrow_back, color: Colors.black, size: 28.w),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          'Find Tankers',
          style: GoogleFonts.poppins(fontSize: 20.sp, fontWeight: FontWeight.w600),
        ),
      ),
      body: Column(
        children: [
          Padding(
            padding: EdgeInsets.all(16.w),
            child: TextField(
              controller: controller.searchController,
              decoration: InputDecoration(
                hintText: 'Search by area or vendor name...',
                prefixIcon: const Icon(Icons.search, color: Colors.grey),
                filled: true,
                fillColor: Colors.grey[100],
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(30.r),
                  borderSide: BorderSide.none,
                ),
              ),
            ),
          ),
          Padding(
            padding: EdgeInsets.symmetric(horizontal: 16.w),
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: [
                  _filterChip('All', controller.selectedFilter == 'All',
                          () => controller.setFilter('All')),
                  SizedBox(width: 12.w),
                  _filterChip('Available Now', controller.selectedFilter == 'Available Now',
                          () => controller.setFilter('Available Now')),
                  SizedBox(width: 12.w),
                  _filterChip('Low Stock', controller.selectedFilter == 'Low Stock',
                          () => controller.setFilter('Low Stock')),
                ],
              ),
            ),
          ),
          SizedBox(height: 16.h),

          if (controller.getDemandMessage().isNotEmpty)
            Padding(
              padding: EdgeInsets.symmetric(horizontal: 16.w),
              child: Container(
                padding: EdgeInsets.all(16.w),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [Colors.blue[700]!, Colors.blue[500]!],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(16.r),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Current Demand is High',
                      style: GoogleFonts.poppins(
                        fontSize: 18.sp,
                        fontWeight: FontWeight.w700,
                        color: Colors.white,
                      ),
                    ),
                    SizedBox(height: 8.h),
                    Text(
                      controller.getDemandMessage(),
                      style: GoogleFonts.poppins(fontSize: 14.sp, color: Colors.white70),
                    ),
                    SizedBox(height: 8.h),
                    Container(
                      padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 6.h),
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.25),
                        borderRadius: BorderRadius.circular(20.r),
                      ),
                      child: Text(
                        'Peak Hours: 8AM - 11AM',
                        style: GoogleFonts.poppins(
                          fontSize: 12.sp,
                          color: Colors.white,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),

          SizedBox(height: 16.h),

          Padding(
            padding: EdgeInsets.symmetric(horizontal: 16.w),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Nearby Vendors',
                  style: GoogleFonts.poppins(fontSize: 18.sp, fontWeight: FontWeight.w700),
                ),
                TextButton(
                  onPressed: () {},
                  child: Text('View Map', style: GoogleFonts.poppins(color: Colors.blue)),
                ),
              ],
            ),
          ),

          SizedBox(height: 8.h),

          Expanded(
            child: controller.isLoading
                ? const Center(child: CircularProgressIndicator())
                : ListView.builder(
              padding: EdgeInsets.symmetric(horizontal: 16.w),
              itemCount: controller.tankers.length,
              itemBuilder: (context, index) {
                final vendor = controller.tankers[index];
                return _vendorCard(context, controller, vendor);
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _filterChip(String label, bool selected, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 10.h),
        decoration: BoxDecoration(
          color: selected ? Colors.blue : Colors.grey[200],
          borderRadius: BorderRadius.circular(30.r),
        ),
        child: Text(
          label,
          style: GoogleFonts.poppins(
            fontSize: 14.sp,
            color: selected ? Colors.white : Colors.black87,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
    );
  }

  Widget _vendorCard(
      BuildContext context,
      FindTankersController controller,
      Map<String, dynamic> vendor,
      ) {
    final status = (vendor['status'] ?? 'UNKNOWN').toString();
    final statusColor = _getStatusColor(status);

    final int used = (vendor['slotsUsed'] ?? 0) is num ? (vendor['slotsUsed'] as num).toInt() : 0;
    final int total = (vendor['slotsTotal'] ?? 0) is num ? (vendor['slotsTotal'] as num).toInt() : 0;
    final String slotsText = (total > 0) ? "$used/$total Slots" : "—";

    final slotIdRaw = vendor['nextSlotId'];
    final int? nextSlotId =
    slotIdRaw is num ? slotIdRaw.toInt() : int.tryParse(slotIdRaw?.toString() ?? "");

    const String buttonText = "View Details";

    return Container(
      margin: EdgeInsets.only(bottom: 12.h),
      padding: EdgeInsets.all(16.w),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16.r),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: Offset(0, 4.h),
          )
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              CircleAvatar(
                radius: 28.r,
                backgroundColor: Colors.blue[50],
                child: Icon(Icons.local_shipping, color: Colors.blue, size: 28.w),
              ),
              SizedBox(width: 16.w),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      (vendor['name'] ?? 'Vendor').toString(),
                      style: GoogleFonts.poppins(fontSize: 16.sp, fontWeight: FontWeight.w700),
                      overflow: TextOverflow.ellipsis,
                    ),
                    SizedBox(height: 4.h),
                    Text(
                      '${vendor['location'] ?? ''} • ${vendor['distance'] ?? ''}',
                      style: GoogleFonts.poppins(fontSize: 13.sp, color: Colors.grey[700]),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
              Container(
                padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 6.h),
                decoration: BoxDecoration(
                  color: statusColor.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(20.r),
                ),
                child: Text(
                  status,
                  style: GoogleFonts.poppins(fontSize: 12.sp, color: statusColor, fontWeight: FontWeight.w600),
                ),
              ),
            ],
          ),
          SizedBox(height: 12.h),

          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(slotsText, style: GoogleFonts.poppins(fontSize: 13.sp, color: Colors.grey[700])),
              if (vendor['nextTime'] != null)
                Text(
                  'Next: ${vendor['nextTime']}',
                  style: GoogleFonts.poppins(fontSize: 13.sp, color: Colors.grey[700]),
                ),
            ],
          ),

          SizedBox(height: 12.h),

          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: () async {

                final booked = await Navigator.push<bool>(
                  context,
                  MaterialPageRoute(
                    builder: (_) => ChangeNotifierProvider.value(
                      value: controller,
                      child: VendorDetailsScreen(
                        vendor: vendor,
                        nextSlotId: nextSlotId,
                      ),
                    ),
                  ),
                );

                if (booked == true && context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text("Booked successfully")),
                  );
                }
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.blue,
                foregroundColor: Colors.white,
                padding: EdgeInsets.symmetric(vertical: 12.h),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12.r)),
              ),
              child: Text(buttonText, style: GoogleFonts.poppins(fontSize: 14.sp, fontWeight: FontWeight.w600)),
            ),
          ),
        ],
      ),
    );
  }
}