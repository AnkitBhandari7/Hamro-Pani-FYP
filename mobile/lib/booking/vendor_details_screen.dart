import 'package:firebase_auth/firebase_auth.dart';
import 'package:fyp/booking/payments/esewa_payment_service.dart';
import 'package:fyp/booking/tanker_service.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';

import 'vendor_details_controller.dart';

class VendorDetailsScreen extends StatelessWidget {
  const VendorDetailsScreen({
    super.key,
    required this.vendor,
    required this.nextSlotId,
  });

  final Map<String, dynamic> vendor;
  final int? nextSlotId;

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (_) => VendorDetailsController(vendor: vendor, slotId: nextSlotId),
      child: _VendorDetailsContent(nextSlotId: nextSlotId),
    );
  }
}

class _VendorDetailsContent extends StatefulWidget {
  const _VendorDetailsContent({required this.nextSlotId});
  final int? nextSlotId;

  @override
  State<_VendorDetailsContent> createState() => _VendorDetailsContentState();
}

class _VendorDetailsContentState extends State<_VendorDetailsContent> {
  bool _booking = false;
  String _paymentMethod = "CASH"; // CASH | ESEWA

  Future<String> _getTokenOrThrow() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) throw Exception("Not logged in");

    final String? token = await user.getIdToken(true);
    if (token == null || token.trim().isEmpty) {
      throw Exception("Failed to get token");
    }

    return token;
  }

  @override
  Widget build(BuildContext context) {
    final controller = Provider.of<VendorDetailsController>(context);

    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.arrow_back, color: Colors.black, size: 28.w),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          'Vendor Details',
          style: GoogleFonts.poppins(fontSize: 20.sp, fontWeight: FontWeight.w600),
        ),
        centerTitle: true,
      ),
      body: controller.isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
        padding: EdgeInsets.symmetric(horizontal: 16.w),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            SizedBox(height: 16.h),

            // Image
            Stack(
              alignment: Alignment.topRight,
              children: [
                ClipRRect(
                  borderRadius: BorderRadius.circular(16.r),
                  child: Image.network(
                    controller.tankerImageUrl,
                    height: 220.h,
                    width: double.infinity,
                    fit: BoxFit.cover,
                    errorBuilder: (_, __, ___) => Container(
                      height: 220.h,
                      color: Colors.blue[100],
                      child: Center(
                        child: Icon(Icons.local_shipping, size: 80.w, color: Colors.blue),
                      ),
                    ),
                  ),
                ),
                Positioned(
                  top: 12.h,
                  right: 12.w,
                  child: Container(
                    padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 6.h),
                    decoration: BoxDecoration(
                      color: Colors.green[700],
                      borderRadius: BorderRadius.circular(20.r),
                    ),
                    child: Text(
                      'VERIFIED',
                      style: GoogleFonts.poppins(
                        fontSize: 12.sp,
                        color: Colors.white,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ),
              ],
            ),

            SizedBox(height: 24.h),

            // Vendor name + status
            Text(
              controller.vendorName,
              style: GoogleFonts.poppins(fontSize: 22.sp, fontWeight: FontWeight.w700),
            ),
            SizedBox(height: 8.h),
            Row(
              children: [
                Icon(Icons.check_circle, color: Colors.green, size: 20.w),
                SizedBox(width: 6.w),
                Text(
                  controller.statusLabel,
                  style: GoogleFonts.poppins(
                    fontSize: 14.sp,
                    color: Colors.green[700],
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),

            if (controller.location.isNotEmpty || controller.wardName.isNotEmpty) ...[
              SizedBox(height: 10.h),
              Text(
                '${controller.location}${controller.wardName.isNotEmpty ? " • ${controller.wardName}" : ""}',
                style: GoogleFonts.poppins(fontSize: 13.sp, color: Colors.grey[700]),
              ),
            ],

            SizedBox(height: 24.h),

            _buildSectionHeader('SLOT DETAILS'),
            SizedBox(height: 12.h),

            Row(
              children: [
                Expanded(
                  child: _infoCard(
                    icon: Icons.schedule,
                    label: 'Time',
                    value: controller.timeRangeLabel,
                  ),
                ),
                SizedBox(width: 12.w),
                Expanded(
                  child: _infoCard(
                    icon: Icons.event_available,
                    label: 'Booking',
                    value: controller.bookingLabel,
                  ),
                ),
              ],
            ),

            SizedBox(height: 12.h),
            Row(
              children: [
                Expanded(
                  child: _infoCard(
                    icon: Icons.opacity,
                    label: 'Tanker',
                    value: '${controller.tankerCapacityLiters} L',
                  ),
                ),
                SizedBox(width: 12.w),
                Expanded(
                  child: _infoCard(
                    icon: Icons.payments_outlined,
                    label: 'Price',
                    value: controller.priceLabel,
                  ),
                ),
              ],
            ),

            SizedBox(height: 24.h),

            _buildSectionHeader('PAYMENT METHOD'),
            SizedBox(height: 10.h),

            Row(
              children: [
                ChoiceChip(
                  label: Text('Cash', style: GoogleFonts.poppins()),
                  selected: _paymentMethod == "CASH",
                  onSelected: (_) => setState(() => _paymentMethod = "CASH"),
                ),
                SizedBox(width: 10.w),
                ChoiceChip(
                  label: Text('eSewa', style: GoogleFonts.poppins()),
                  selected: _paymentMethod == "ESEWA",
                  onSelected: (_) => setState(() => _paymentMethod = "ESEWA"),
                ),
              ],
            ),

            SizedBox(height: 28.h),

            // Confirm Booking
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: (widget.nextSlotId == null || _booking)
                    ? null
                    : () async {
                  setState(() => _booking = true);

                  try {
                    final token = await _getTokenOrThrow();
                    final slotId = widget.nextSlotId!;

                    // Book first creates booking + payment row
                    final bookingRes = await TankerService.bookTankerSlot(
                      token: token,
                      slotId: slotId,
                      paymentMethod: _paymentMethod, // CASH or ESEWA
                    );

                    final booking = Map<String, dynamic>.from(bookingRes['booking'] as Map);
                    final payment = Map<String, dynamic>.from(bookingRes['payment'] as Map);

                    final bookingId = (booking['id'] as num).toInt();
                    final amountStr = payment['amount'].toString();
                    final amount = double.tryParse(amountStr) ?? 0.0;

                    // CASH
                    if (_paymentMethod.toUpperCase() == "CASH") {
                      if (!mounted) return;
                      Navigator.pop(context, true);
                      return;
                    }

                    // ESEWA
                    final refId = await EsewaPaymentService.pay(
                      bookingId: bookingId,
                      totalAmount: amount,
                      productName: "Hamro Pani Tanker Booking",
                    );

                    // cancelled/failed cancel booking to free slot
                    if (refId == null) {
                      try {
                        await TankerService.cancelBooking(token: token, bookingId: bookingId);
                      } catch (_) {}

                      if (!mounted) return;
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text("Payment cancelled")),
                      );
                      return;
                    }

                    // verify mark payment PAID permanently in DB
                    await TankerService.verifyEsewaPayment(
                      token: token,
                      bookingId: bookingId,
                      refId: refId,
                    );

                    if (!mounted) return;
                    Navigator.pop(context, true);
                  } catch (e) {
                    if (!mounted) return;
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text("Booking failed: $e"),
                        backgroundColor: Colors.red,
                      ),
                    );
                  } finally {
                    if (mounted) setState(() => _booking = false);
                  }
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.blue,
                  padding: EdgeInsets.symmetric(vertical: 16.h),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16.r),
                  ),
                ),
                child: _booking
                    ? const SizedBox(
                  height: 20,
                  width: 20,
                  child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                )
                    : Text(
                  widget.nextSlotId == null ? 'No Slot Available' : 'Confirm Booking →',
                  style: GoogleFonts.poppins(
                    fontSize: 16.sp,
                    fontWeight: FontWeight.w600,
                    color: Colors.white,
                  ),
                ),
              ),
            ),

            SizedBox(height: 16.h),

            Center(
              child: Text(
                'IMMEDIATE DISPATCH AVAILABLE',
                style: GoogleFonts.poppins(
                  fontSize: 12.sp,
                  color: Colors.green[700],
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),

            SizedBox(height: 100.h),
          ],
        ),
      ),
    );
  }

  Widget _infoCard({
    required IconData icon,
    required String label,
    required String value,
  }) {
    return Container(
      padding: EdgeInsets.all(16.w),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16.r),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 8, offset: Offset(0, 2.h))],
      ),
      child: Column(
        children: [
          Icon(icon, color: Colors.blue, size: 32.w),
          SizedBox(height: 8.h),
          Text(label, style: GoogleFonts.poppins(fontSize: 12.sp, color: Colors.grey[600])),
          SizedBox(height: 4.h),
          Text(
            value,
            textAlign: TextAlign.center,
            style: GoogleFonts.poppins(fontSize: 14.sp, fontWeight: FontWeight.w700),
          ),
        ],
      ),
    );
  }

  Widget _buildSectionHeader(String title) {
    return Text(
      title,
      style: GoogleFonts.poppins(fontSize: 16.sp, fontWeight: FontWeight.w700),
    );
  }
}