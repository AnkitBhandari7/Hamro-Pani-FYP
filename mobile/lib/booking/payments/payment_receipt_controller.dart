import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_file_dialog/flutter_file_dialog.dart';
import 'package:path_provider/path_provider.dart';

import 'payment_receipt_pdf_service.dart';
import 'payment_receipt_service.dart';

class PaymentReceiptController extends ChangeNotifier {
  PaymentReceiptController({required this.bookingId}) {
    load();
  }

  final int bookingId;

  bool isLoading = true;
  bool isSaving = false;
  String? error;
  PaymentReceipt? receipt;

  Future<void> load() async {
    isLoading = true;
    error = null;
    notifyListeners();

    try {
      receipt = await PaymentReceiptService.fetchReceiptByBookingId(bookingId);
    } catch (e) {
      error = e.toString();
    } finally {
      isLoading = false;
      notifyListeners();
    }
  }

  /// ✅ Opens system "Save to..." dialog and saves PDF in user selected location.
  /// Returns saved file URI/path string, or null if cancelled.
  Future<String?> saveReceiptToPhoneFiles() async {
    final r = receipt;
    if (r == null) return null;

    isSaving = true;
    notifyListeners();

    try {
      // 1) Build PDF bytes
      final bytes = await PaymentReceiptPdfService.buildPdf(r);

      // 2) Write to a temporary file first
      final tempDir = await getTemporaryDirectory();
      final safeTxn = r.transactionId.replaceAll(RegExp(r'[^a-zA-Z0-9_-]'), '_');
      final tempPath = "${tempDir.path}/receipt_$safeTxn.pdf";
      final tempFile = File(tempPath);
      await tempFile.writeAsBytes(bytes, flush: true);

      // 3) Open native save dialog
      final params = SaveFileDialogParams(
        sourceFilePath: tempFile.path,
        fileName: "receipt_$safeTxn.pdf",
      );

      final result = await FlutterFileDialog.saveFile(params: params);

      // result is null if user cancels
      return result;
    } catch (e) {
      error = e.toString();
      notifyListeners();
      rethrow;
    } finally {
      isSaving = false;
      notifyListeners();
    }
  }
}