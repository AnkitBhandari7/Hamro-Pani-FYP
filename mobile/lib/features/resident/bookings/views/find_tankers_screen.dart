import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';

import 'package:fyp/l10n/app_localizations.dart';
import '../controllers/find_tankers_controller.dart';
import 'vendor_details_screen.dart';

// main find tankers screen widget
// wraps the content with a provider for the controller
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

  // returns the right color based on vendor status
  Color _getStatusColor(String status) {
    switch (status.toUpperCase()) {
      case 'AVAILABLE':
        return const Color(0xFF22C55E);
      case 'BUSY':
        return const Color(0xFFF97316);
      case 'LOW_STOCK':
        return const Color(0xFFEAB308);
      default:
        return Colors.grey;
    }
  }

  // returns background color for status chip
  Color _getStatusBgColor(String status) {
    switch (status.toUpperCase()) {
      case 'AVAILABLE':
        return const Color(0xFFDCFCE7);
      case 'BUSY':
        return const Color(0xFFFFF7ED);
      case 'LOW_STOCK':
        return const Color(0xFFFEF9C3);
      default:
        return Colors.grey.shade100;
    }
  }

  // get translated status text
  String _statusLabel(AppLocalizations t, String status) {
    switch (status.toUpperCase()) {
      case 'AVAILABLE':
        return t.tankerStatusAvailable;
      case 'BUSY':
        return t.tankerStatusBusy;
      case 'LOW_STOCK':
        return t.tankerStatusLowStock;
      default:
        return status;
    }
  }

  @override
  Widget build(BuildContext context) {
    final t = AppLocalizations.of(context)!;
    final controller = Provider.of<FindTankersController>(context);
    final demandMessage = controller.getDemandMessage(t);

    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // top header section with title and notification bell
            _buildHeader(context, t),

            // scrollable content below header
            Expanded(
              child: RefreshIndicator(
                onRefresh: controller.fetchTankers,
                color: const Color(0xFF2563EB),
                child: CustomScrollView(
                  physics: const AlwaysScrollableScrollPhysics(),
                  slivers: [
                    // search bar
                    SliverToBoxAdapter(
                      child: _buildSearchBar(t, controller),
                    ),

                    // filter chips row
                    SliverToBoxAdapter(
                      child: _buildFilterChips(t, controller),
                    ),

                    // demand banner (only shown when filter is available now)
                    if (demandMessage.isNotEmpty)
                      SliverToBoxAdapter(
                        child: _buildDemandBanner(t, demandMessage),
                      ),

                    // nearby vendors heading
                    SliverToBoxAdapter(
                      child: _buildSectionHeader(t),
                    ),

                    // vendor list / loading / error / empty states
                    _buildVendorList(context, t, controller),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // top header with back arrow, title and bell icon
  Widget _buildHeader(BuildContext context, AppLocalizations t) {
    return Container(
      padding: EdgeInsets.fromLTRB(20.w, 12.h, 20.w, 8.h),
      child: Row(
        children: [
          // back button
          GestureDetector(
            onTap: () => Navigator.pop(context),
            child: Container(
              padding: EdgeInsets.all(8.w),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12.r),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.05),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Icon(
                Icons.arrow_back_ios_new_rounded,
                size: 20.w,
                color: const Color(0xFF1E293B),
              ),
            ),
          ),
          SizedBox(width: 16.w),

          // title and subtitle
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  t.findTankersTitle,
                  style: GoogleFonts.poppins(
                    fontSize: 22.sp,
                    fontWeight: FontWeight.w700,
                    color: const Color(0xFF0F172A),
                  ),
                ),
              ],
            ),
          ),

          // notification bell
          Container(
            padding: EdgeInsets.all(10.w),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12.r),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.05),
                  blurRadius: 8,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Icon(
              Icons.notifications_outlined,
              size: 22.w,
              color: const Color(0xFF475569),
            ),
          ),
        ],
      ),
    );
  }

  // search text field with rounded border
  Widget _buildSearchBar(AppLocalizations t, FindTankersController controller) {
    return Padding(
      padding: EdgeInsets.fromLTRB(20.w, 16.h, 20.w, 12.h),
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16.r),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.04),
              blurRadius: 12,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: TextField(
          controller: controller.searchController,
          style: GoogleFonts.poppins(
            fontSize: 14.sp,
            color: const Color(0xFF1E293B),
          ),
          decoration: InputDecoration(
            hintText: t.searchTankersHint,
            hintStyle: GoogleFonts.poppins(
              fontSize: 14.sp,
              color: const Color(0xFF94A3B8),
            ),
            prefixIcon: Padding(
              padding: EdgeInsets.only(left: 16.w, right: 12.w),
              child: Icon(
                Icons.search_rounded,
                color: const Color(0xFF94A3B8),
                size: 22.w,
              ),
            ),
            prefixIconConstraints: BoxConstraints(minHeight: 22.w),
            filled: true,
            fillColor: Colors.white,
            contentPadding: EdgeInsets.symmetric(
              horizontal: 20.w,
              vertical: 14.h,
            ),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(16.r),
              borderSide: BorderSide(
                color: const Color(0xFFE2E8F0),
                width: 1.2,
              ),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(16.r),
              borderSide: BorderSide(
                color: const Color(0xFFE2E8F0),
                width: 1.2,
              ),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(16.r),
              borderSide: BorderSide(
                color: const Color(0xFF2563EB),
                width: 1.5,
              ),
            ),
          ),
        ),
      ),
    );
  }

  // horizontal scrollable filter chips
  Widget _buildFilterChips(
      AppLocalizations t, FindTankersController controller) {
    return Padding(
      padding: EdgeInsets.symmetric(horizontal: 20.w),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: Row(
          children: [
            _filterChip(
              icon: Icons.tune_rounded,
              label: t.filterAll,
              selected:
                  controller.selectedFilter == FindTankersController.filterAll,
              onTap: () =>
                  controller.setFilter(FindTankersController.filterAll),
            ),
            SizedBox(width: 10.w),
            _filterChip(
              label: t.filterAvailableNow,
              selected: controller.selectedFilter ==
                  FindTankersController.filterAvailableNow,
              onTap: () => controller
                  .setFilter(FindTankersController.filterAvailableNow),
            ),
            SizedBox(width: 10.w),
            _filterChip(
              label: t.filterLowStock,
              selected: controller.selectedFilter ==
                  FindTankersController.filterLowStock,
              onTap: () =>
                  controller.setFilter(FindTankersController.filterLowStock),
            ),
          ],
        ),
      ),
    );
  }

  // individual filter chip widget
  Widget _filterChip({
    IconData? icon,
    required String label,
    required bool selected,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 10.h),
        decoration: BoxDecoration(
          gradient: selected
              ? const LinearGradient(
                  colors: [Color(0xFF2563EB), Color(0xFF3B82F6)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                )
              : null,
          color: selected ? null : Colors.white,
          borderRadius: BorderRadius.circular(24.r),
          border: selected
              ? null
              : Border.all(color: const Color(0xFFE2E8F0), width: 1.2),
          boxShadow: selected
              ? [
                  BoxShadow(
                    color: const Color(0xFF2563EB).withOpacity(0.25),
                    blurRadius: 8,
                    offset: const Offset(0, 3),
                  ),
                ]
              : [],
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (icon != null) ...[
              Icon(
                icon,
                size: 16.w,
                color: selected ? Colors.white : const Color(0xFF475569),
              ),
              SizedBox(width: 6.w),
            ],
            Text(
              label,
              style: GoogleFonts.poppins(
                fontSize: 13.sp,
                color: selected ? Colors.white : const Color(0xFF475569),
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    );
  }

  // blue gradient demand banner card
  Widget _buildDemandBanner(AppLocalizations t, String message) {
    return Padding(
      padding: EdgeInsets.fromLTRB(20.w, 16.h, 20.w, 0),
      child: Container(
        padding: EdgeInsets.all(18.w),
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            colors: [Color(0xFF1D4ED8), Color(0xFF3B82F6)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(18.r),
          boxShadow: [
            BoxShadow(
              color: const Color(0xFF2563EB).withOpacity(0.3),
              blurRadius: 16,
              offset: const Offset(0, 6),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // title row with icon
            Row(
              children: [
                Icon(
                  Icons.trending_up_rounded,
                  color: Colors.white,
                  size: 22.w,
                ),
                SizedBox(width: 8.w),
                Expanded(
                  child: Text(
                    t.currentDemandHigh,
                    style: GoogleFonts.poppins(
                      fontSize: 17.sp,
                      fontWeight: FontWeight.w700,
                      color: Colors.white,
                    ),
                  ),
                ),
              ],
            ),
            SizedBox(height: 8.h),

            // message text
            Text(
              message,
              style: GoogleFonts.poppins(
                fontSize: 13.sp,
                color: Colors.white.withOpacity(0.85),
                height: 1.5,
              ),
            ),
            SizedBox(height: 12.h),

            // peak hours chip
            Container(
              padding: EdgeInsets.symmetric(horizontal: 14.w, vertical: 7.h),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.2),
                borderRadius: BorderRadius.circular(20.r),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    Icons.access_time_rounded,
                    size: 14.w,
                    color: Colors.white,
                  ),
                  SizedBox(width: 6.w),
                  Text(
                    t.peakHoursLabel("8AM - 11AM"),
                    style: GoogleFonts.poppins(
                      fontSize: 12.sp,
                      color: Colors.white,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  // section header with "Nearby Vendors" and "View Map"
  Widget _buildSectionHeader(AppLocalizations t) {
    return Padding(
      padding: EdgeInsets.fromLTRB(20.w, 20.h, 20.w, 12.h),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Expanded(
            child: Text(
              t.nearbyVendors,
              style: GoogleFonts.poppins(
                fontSize: 18.sp,
                fontWeight: FontWeight.w700,
                color: const Color(0xFF0F172A),
              ),
              overflow: TextOverflow.ellipsis,
            ),
          ),
          GestureDetector(
            onTap: () {
              // view map action (not implemented yet)
            },
            child: Row(
              children: [
                Icon(
                  Icons.map_outlined,
                  size: 16.w,
                  color: const Color(0xFF2563EB),
                ),
                SizedBox(width: 4.w),
                Text(
                  t.viewMap,
                  style: GoogleFonts.poppins(
                    fontSize: 14.sp,
                    color: const Color(0xFF2563EB),
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // handles loading, error, empty, and loaded states for vendor list
  Widget _buildVendorList(
    BuildContext context,
    AppLocalizations t,
    FindTankersController controller,
  ) {
    // loading shimmer state
    if (controller.isLoading) {
      return SliverList(
        delegate: SliverChildBuilderDelegate(
          (context, index) => _buildShimmerCard(),
          childCount: 3,
        ),
      );
    }

    // error state with retry button
    if (controller.errorMessage != null) {
      return SliverFillRemaining(
        hasScrollBody: false,
        child: Center(
          child: Padding(
            padding: EdgeInsets.symmetric(horizontal: 32.w),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Container(
                  padding: EdgeInsets.all(20.w),
                  decoration: BoxDecoration(
                    color: const Color(0xFFFEE2E2),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    Icons.wifi_off_rounded,
                    size: 48.w,
                    color: const Color(0xFFEF4444),
                  ),
                ),
                SizedBox(height: 20.h),
                Text(
                  t.errorLabel,
                  style: GoogleFonts.poppins(
                    fontSize: 18.sp,
                    fontWeight: FontWeight.w700,
                    color: const Color(0xFF1E293B),
                  ),
                ),
                SizedBox(height: 8.h),
                Text(
                  t.tryDifferentSearch,
                  style: GoogleFonts.poppins(
                    fontSize: 14.sp,
                    color: const Color(0xFF64748B),
                  ),
                  textAlign: TextAlign.center,
                ),
                SizedBox(height: 20.h),
                ElevatedButton.icon(
                  onPressed: controller.fetchTankers,
                  icon: const Icon(Icons.refresh_rounded),
                  label: Text(
                    t.filterAll, // using "All" as retry label fallback
                    style: GoogleFonts.poppins(fontWeight: FontWeight.w600),
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF2563EB),
                    foregroundColor: Colors.white,
                    padding: EdgeInsets.symmetric(
                      horizontal: 24.w,
                      vertical: 12.h,
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12.r),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      );
    }

    // empty state when no vendors found
    if (controller.tankers.isEmpty) {
      return SliverFillRemaining(
        hasScrollBody: false,
        child: Center(
          child: Padding(
            padding: EdgeInsets.symmetric(horizontal: 32.w),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Container(
                  padding: EdgeInsets.all(24.w),
                  decoration: BoxDecoration(
                    color: const Color(0xFFEFF6FF),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    Icons.local_shipping_outlined,
                    size: 56.w,
                    color: const Color(0xFF3B82F6),
                  ),
                ),
                SizedBox(height: 20.h),
                Text(
                  t.noVendorsFound,
                  style: GoogleFonts.poppins(
                    fontSize: 17.sp,
                    fontWeight: FontWeight.w700,
                    color: const Color(0xFF1E293B),
                  ),
                ),
                SizedBox(height: 8.h),
                Text(
                  t.tryDifferentSearch,
                  style: GoogleFonts.poppins(
                    fontSize: 14.sp,
                    color: const Color(0xFF94A3B8),
                    height: 1.5,
                  ),
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          ),
        ),
      );
    }

    // vendor cards list
    return SliverPadding(
      padding: EdgeInsets.symmetric(horizontal: 20.w),
      sliver: SliverList(
        delegate: SliverChildBuilderDelegate(
          (context, index) {
            final vendor = controller.tankers[index];
            return _vendorCard(context, t, controller, vendor);
          },
          childCount: controller.tankers.length,
        ),
      ),
    );
  }

  // loading placeholder card with shimmer-like appearance
  Widget _buildShimmerCard() {
    return Padding(
      padding: EdgeInsets.symmetric(horizontal: 20.w, vertical: 6.h),
      child: Container(
        padding: EdgeInsets.all(16.w),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(18.r),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.04),
              blurRadius: 12,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                // avatar placeholder
                Container(
                  width: 56.w,
                  height: 56.w,
                  decoration: BoxDecoration(
                    color: const Color(0xFFF1F5F9),
                    borderRadius: BorderRadius.circular(14.r),
                  ),
                ),
                SizedBox(width: 14.w),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // name placeholder
                      Container(
                        height: 16.h,
                        width: 140.w,
                        decoration: BoxDecoration(
                          color: const Color(0xFFF1F5F9),
                          borderRadius: BorderRadius.circular(8.r),
                        ),
                      ),
                      SizedBox(height: 8.h),
                      // subtitle placeholder
                      Container(
                        height: 12.h,
                        width: 100.w,
                        decoration: BoxDecoration(
                          color: const Color(0xFFF1F5F9),
                          borderRadius: BorderRadius.circular(8.r),
                        ),
                      ),
                    ],
                  ),
                ),
                // status chip placeholder
                Container(
                  height: 28.h,
                  width: 72.w,
                  decoration: BoxDecoration(
                    color: const Color(0xFFF1F5F9),
                    borderRadius: BorderRadius.circular(14.r),
                  ),
                ),
              ],
            ),
            SizedBox(height: 14.h),
            // info row placeholder
            Row(
              children: [
                Container(
                  height: 12.h,
                  width: 80.w,
                  decoration: BoxDecoration(
                    color: const Color(0xFFF1F5F9),
                    borderRadius: BorderRadius.circular(6.r),
                  ),
                ),
                SizedBox(width: 16.w),
                Container(
                  height: 12.h,
                  width: 80.w,
                  decoration: BoxDecoration(
                    color: const Color(0xFFF1F5F9),
                    borderRadius: BorderRadius.circular(6.r),
                  ),
                ),
              ],
            ),
            SizedBox(height: 14.h),
            // button placeholder
            Container(
              height: 44.h,
              width: double.infinity,
              decoration: BoxDecoration(
                color: const Color(0xFFF1F5F9),
                borderRadius: BorderRadius.circular(12.r),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // vendor card showing name, status, capacity, next time, and action button
  Widget _vendorCard(
    BuildContext context,
    AppLocalizations t,
    FindTankersController controller,
    Map<String, dynamic> vendor,
  ) {
    final statusRaw = (vendor['status'] ?? 'UNKNOWN').toString();
    final statusColor = _getStatusColor(statusRaw);
    final statusBgColor = _getStatusBgColor(statusRaw);
    final statusText = _statusLabel(t, statusRaw);

    // build the slots used text
    final int used = (vendor['slotsUsed'] ?? 0) is num
        ? (vendor['slotsUsed'] as num).toInt()
        : 0;
    final int total = (vendor['slotsTotal'] ?? 0) is num
        ? (vendor['slotsTotal'] as num).toInt()
        : 0;

    final String slotsText =
        (total > 0) ? t.slotsUsedLabel(used, total) : "—";

    // get next slot id for navigation
    final slotIdRaw = vendor['nextSlotId'];
    final int? nextSlotId = slotIdRaw is num
        ? slotIdRaw.toInt()
        : int.tryParse(slotIdRaw?.toString() ?? "");

    // figure out tanker capacity
    final int capacity = (vendor['tankerCapacityLiters'] ?? 0) is num
        ? (vendor['tankerCapacityLiters'] as num).toInt()
        : 0;

    // figure out price if available
    final priceRaw = vendor['price'];
    final int priceInt = priceRaw is num ? priceRaw.toInt() : 0;

    // is vendor available for booking?
    final bool isAvailable = statusRaw.toUpperCase() == 'AVAILABLE';
    final bool isBusy = statusRaw.toUpperCase() == 'BUSY';

    return Container(
      margin: EdgeInsets.only(bottom: 14.h),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18.r),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 14,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(18.r),
        child: InkWell(
          borderRadius: BorderRadius.circular(18.r),
          onTap: () => _navigateToDetails(context, t, controller, vendor, nextSlotId),
          child: Padding(
            padding: EdgeInsets.all(16.w),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // top row: avatar, name, location, status
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // vendor avatar with rating badge
                    _buildVendorAvatar(vendor),
                    SizedBox(width: 14.w),

                    // name and location
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            (vendor['name'] ?? t.vendor).toString(),
                            style: GoogleFonts.poppins(
                              fontSize: 15.sp,
                              fontWeight: FontWeight.w700,
                              color: const Color(0xFF0F172A),
                            ),
                            overflow: TextOverflow.ellipsis,
                            maxLines: 1,
                          ),
                          SizedBox(height: 4.h),
                          Row(
                            children: [
                              Icon(
                                Icons.location_on_outlined,
                                size: 14.w,
                                color: const Color(0xFF94A3B8),
                              ),
                              SizedBox(width: 3.w),
                              Expanded(
                                child: Text(
                                  '${vendor['location'] ?? ''} • ${vendor['distance'] ?? ''}',
                                  style: GoogleFonts.poppins(
                                    fontSize: 12.sp,
                                    color: const Color(0xFF64748B),
                                  ),
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),

                    SizedBox(width: 8.w),

                    // status chip
                    Container(
                      padding: EdgeInsets.symmetric(
                        horizontal: 10.w,
                        vertical: 5.h,
                      ),
                      decoration: BoxDecoration(
                        color: statusBgColor,
                        borderRadius: BorderRadius.circular(8.r),
                      ),
                      child: Text(
                        statusText.toUpperCase(),
                        style: GoogleFonts.poppins(
                          fontSize: 10.sp,
                          color: statusColor,
                          fontWeight: FontWeight.w700,
                          letterSpacing: 0.5,
                        ),
                      ),
                    ),
                  ],
                ),

                SizedBox(height: 14.h),

                // divider line
                Container(
                  height: 1,
                  color: const Color(0xFFF1F5F9),
                ),

                SizedBox(height: 12.h),

                // info row: capacity, next time (uses Wrap for nepali)
                Wrap(
                  spacing: 20.w,
                  runSpacing: 8.h,
                  children: [
                    // tanker capacity info
                    if (capacity > 0)
                      _infoItem(
                        icon: Icons.water_drop_outlined,
                        text: '${(capacity / 1000).toStringAsFixed(0)},000 L',
                        color: const Color(0xFF3B82F6),
                      ),

                    // slots text
                    _infoItem(
                      icon: Icons.confirmation_number_outlined,
                      text: slotsText,
                      color: const Color(0xFF8B5CF6),
                    ),

                    // next available time
                    if (vendor['nextTime'] != null)
                      _infoItem(
                        icon: Icons.schedule_outlined,
                        text: t.nextLabel(vendor['nextTime'].toString()),
                        color: const Color(0xFFF59E0B),
                      ),
                  ],
                ),

                SizedBox(height: 14.h),

                // action button - book now or check schedule
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: () => _navigateToDetails(
                        context, t, controller, vendor, nextSlotId),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: isAvailable
                          ? const Color(0xFF2563EB)
                          : Colors.transparent,
                      foregroundColor:
                          isAvailable ? Colors.white : const Color(0xFF2563EB),
                      elevation: isAvailable ? 0 : 0,
                      padding: EdgeInsets.symmetric(vertical: 13.h),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14.r),
                        side: isAvailable
                            ? BorderSide.none
                            : BorderSide(
                                color: const Color(0xFF2563EB),
                                width: 1.5,
                              ),
                      ),
                    ),
                    child: Text(
                      isAvailable
                          ? (priceInt > 0
                              ? '${t.bookTanker} • NPR ${_formatPrice(priceInt)}'
                              : t.bookTanker)
                          : (isBusy
                              ? t.viewDetails
                              : t.viewDetails),
                      style: GoogleFonts.poppins(
                        fontSize: 14.sp,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // avatar with colored icon and rating overlay
  Widget _buildVendorAvatar(Map<String, dynamic> vendor) {
    // we dont have real images yet, so use a styled icon
    return Stack(
      clipBehavior: Clip.none,
      children: [
        Container(
          width: 56.w,
          height: 56.w,
          decoration: BoxDecoration(
            color: const Color(0xFFEFF6FF),
            borderRadius: BorderRadius.circular(14.r),
          ),
          child: Icon(
            Icons.local_shipping_rounded,
            color: const Color(0xFF3B82F6),
            size: 28.w,
          ),
        ),

        // rating badge at top left corner
        Positioned(
          top: -4.h,
          left: -4.w,
          child: Container(
            padding: EdgeInsets.symmetric(horizontal: 6.w, vertical: 2.h),
            decoration: BoxDecoration(
              color: const Color(0xFFFBBF24),
              borderRadius: BorderRadius.circular(8.r),
              boxShadow: [
                BoxShadow(
                  color: const Color(0xFFFBBF24).withOpacity(0.4),
                  blurRadius: 4,
                  offset: const Offset(0, 1),
                ),
              ],
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  Icons.star_rounded,
                  size: 10.w,
                  color: Colors.white,
                ),
                SizedBox(width: 2.w),
                Text(
                  '4.5',
                  style: GoogleFonts.poppins(
                    fontSize: 9.sp,
                    fontWeight: FontWeight.w700,
                    color: Colors.white,
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  // small info row item with icon and text
  Widget _infoItem({
    required IconData icon,
    required String text,
    required Color color,
  }) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          padding: EdgeInsets.all(4.w),
          decoration: BoxDecoration(
            color: color.withOpacity(0.1),
            borderRadius: BorderRadius.circular(6.r),
          ),
          child: Icon(icon, size: 14.w, color: color),
        ),
        SizedBox(width: 6.w),
        Flexible(
          child: Text(
            text,
            style: GoogleFonts.poppins(
              fontSize: 12.sp,
              color: const Color(0xFF475569),
              fontWeight: FontWeight.w500,
            ),
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ],
    );
  }

  // navigate to vendor details screen
  void _navigateToDetails(
    BuildContext context,
    AppLocalizations t,
    FindTankersController controller,
    Map<String, dynamic> vendor,
    int? nextSlotId,
  ) async {
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
        SnackBar(content: Text(t.bookedSuccessfully)),
      );
    }
  }

  // format price with commas
  String _formatPrice(int price) {
    if (price >= 1000) {
      return '${price ~/ 1000},${(price % 1000).toString().padLeft(3, '0')}';
    }
    return price.toString();
  }
}