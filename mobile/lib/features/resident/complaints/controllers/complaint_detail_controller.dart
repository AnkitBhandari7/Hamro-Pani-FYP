import 'package:flutter/material.dart';
import '../services/complaint_service.dart';

class ComplaintDetailController extends ChangeNotifier {
  ComplaintDetailController(this.complaintId) {
    load();
  }

  final int complaintId;

  bool isLoading = true;
  ComplaintDetail? detail;
  String? error;

  Future<void> load() async {
    isLoading = true;
    error = null;
    notifyListeners();

    try {
      detail = await ComplaintService.getComplaintDetail(complaintId);
    } catch (e) {
      error = e.toString();
    } finally {
      isLoading = false;
      notifyListeners();
    }
  }
}
