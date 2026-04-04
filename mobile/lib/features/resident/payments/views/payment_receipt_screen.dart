import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';

import 'package:fyp/l10n/app_localizations.dart';
import '../controllers/payment_receipt_controller.dart';

class PaymentReceiptScreen extends StatelessWidget {
  const PaymentReceiptScreen({super.key, required this.bookingId});
  final int bookingId;

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (_) => PaymentReceiptController(bookingId: bookingId),
      child: const _PaymentReceiptView(),
    );
  }
}

class _PaymentReceiptView extends StatelessWidget {
  const _PaymentReceiptView();

  String _formatDateTime(DateTime dt) {
    return DateFormat('MMM dd, yyyy, h:mm a').format(dt.toLocal());
  }

  @override
  Widget build(BuildContext context) {
    final t = AppLocalizations.of(context)!;
    final ctrl = context.watch<PaymentReceiptController>();

    if (ctrl.isLoading) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    if (ctrl.receipt == null) {
      return Scaffold(
        appBar: AppBar(title: Text(t.paymentReceiptTitle)),
        body: Center(child: Text(ctrl.error ?? t.failedToLoadReceipt)),
      );
    }

    final receipt = ctrl.receipt!;

    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: Icon(
            Icons.arrow_back_ios_new_rounded,
            color: Colors.black,
            size: 24.w,
          ),
          onPressed: () => Navigator.pop(context),
          tooltip: t.back,
        ),
        title: Text(
          t.paymentReceiptTitle,
          style: GoogleFonts.poppins(
            fontSize: 20.sp,
            fontWeight: FontWeight.w600,
          ),
        ),
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        padding: EdgeInsets.symmetric(horizontal: 20.w),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            SizedBox(height: 40.h),
            Container(
              width: 90.w,
              height: 90.h,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: Colors.green.withOpacity(0.1),
              ),
              child: Icon(Icons.check_rounded, color: Colors.green, size: 50.w),
            ),
            SizedBox(height: 24.h),
            Text(
              t.paymentSuccessful,
              style: GoogleFonts.poppins(
                fontSize: 26.sp,
                fontWeight: FontWeight.w700,
              ),
              textAlign: TextAlign.center,
            ),
            SizedBox(height: 8.h),
            Text(
              t.thankYouForPurchase,
              style: GoogleFonts.poppins(
                fontSize: 15.sp,
                color: Colors.grey[700],
              ),
              textAlign: TextAlign.center,
            ),
            SizedBox(height: 32.h),
            Text(
              t.nprAmount(receipt.amount.toStringAsFixed(0)),
              style: GoogleFonts.poppins(
                fontSize: 40.sp,
                fontWeight: FontWeight.w800,
                color: Colors.blue[700],
              ),
            ),
            SizedBox(height: 40.h),
            Container(
              width: double.infinity,
              padding: EdgeInsets.all(20.w),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16.r),
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
                  _receiptRow(t.transactionId, receipt.transactionId),
                  _receiptRow(t.dateAndTime, _formatDateTime(receipt.dateTime)),
                  _receiptRow(t.paymentMethod, receipt.paymentMethod),
                  _receiptRow(t.recipient, receipt.recipient),
                  _receiptRow(t.service, receipt.service),
                  _receiptRow(
                    t.quantity,
                    t.litersShort(receipt.quantityLiters),
                  ),
                  SizedBox(height: 16.h),
                  Divider(color: Colors.grey[300], thickness: 1.h),
                  SizedBox(height: 16.h),
                  Text(
                    t.downloadPdf,
                    style: GoogleFonts.poppins(
                      fontSize: 16.sp,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  SizedBox(height: 4.h),
                  Text(
                    t.saveCopyForRecords,
                    style: GoogleFonts.poppins(
                      fontSize: 13.sp,
                      color: Colors.grey[600],
                    ),
                  ),
                  SizedBox(height: 16.h),
                  SizedBox(
                    width: double.infinity,
                    child: OutlinedButton.icon(
                      onPressed: ctrl.isSaving
                          ? null
                          : () async {
                        try {
                          final result = await ctrl.saveReceiptToPhoneFiles();
                          if (!context.mounted) return;

                          if (result == null) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(content: Text(t.saveCancelled)),
                            );
                            return;
                          }

                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(content: Text(t.receiptSaved(result))),
                          );
                        } catch (e) {
                          if (!context.mounted) return;
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text(t.saveFailedWithError(e.toString())),
                              backgroundColor: Colors.red,
                            ),
                          );
                        }
                      },
                      icon: Icon(Icons.download_rounded, size: 20.w),
                      label: Text(
                        t.downloadReceipt,
                        style: GoogleFonts.poppins(
                          fontSize: 14.sp,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      style: OutlinedButton.styleFrom(
                        side: const BorderSide(color: Colors.blue),
                        padding: EdgeInsets.symmetric(vertical: 14.h),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12.r),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            SizedBox(height: 40.h),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () => Navigator.popUntil(context, (r) => r.isFirst),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.black87,
                  padding: EdgeInsets.symmetric(vertical: 16.h),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16.r),
                  ),
                ),
                child: Text(
                  t.backToHome,
                  style: GoogleFonts.poppins(
                    fontSize: 16.sp,
                    fontWeight: FontWeight.w600,
                    color: Colors.white,
                  ),
                ),
              ),
            ),
            SizedBox(height: 60.h),
          ],
        ),
      ),
    );
  }

  Widget _receiptRow(String label, String value) {
    return Padding(
      padding: EdgeInsets.symmetric(vertical: 10.h),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Expanded(
            child: Text(
              label,
              style: GoogleFonts.poppins(
                fontSize: 14.sp,
                color: Colors.grey[700],
              ),
              overflow: TextOverflow.ellipsis,
              maxLines: 1,
            ),
          ),
          SizedBox(width: 10.w),
          Flexible(
            child: Text(
              value,
              textAlign: TextAlign.right,
              style: GoogleFonts.poppins(
                fontSize: 14.sp,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }
}