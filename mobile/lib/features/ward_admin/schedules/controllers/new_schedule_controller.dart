import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

import '../models/schedule_payload.dart';
import '../services/schedules_service.dart';

class NewScheduleController extends ChangeNotifier {
  // Tabs: 0 = Manual Entry, 1 = Upload File
  int selectedTab = 0;

  bool notifyResidents = true;
  bool isPublishing = false;

  // Manual entry fields
  DateTime? selectedDate;
  TimeOfDay? startTime;
  TimeOfDay? endTime;

  // ✅ canonical value stored for backend (English always)
  String? selectedWardEnglish;

  final TextEditingController affectedAreasController = TextEditingController();

  // Upload mode (not implemented)
  String? fileName;

  // Canonical English wards (backend/db)
  final List<String> wardsEn = [
    ...List.generate(32, (i) => "Kathmandu Ward ${i + 1}"),
    ...List.generate(29, (i) => "Lalitpur Ward ${i + 1}"),
    ...List.generate(10, (i) => "Bhaktapur Ward ${i + 1}"),
  ];

  // Nepali wards (UI) — index aligned with wardsEn
  final List<String> wardsNe = [
    ...List.generate(32, (i) => "काठमाडौं वडा ${i + 1}"),
    ...List.generate(29, (i) => "ललितपुर वडा ${i + 1}"),
    ...List.generate(10, (i) => "भक्तपुर वडा ${i + 1}"),
  ];

  bool _isNepali(BuildContext context) =>
      Localizations.localeOf(context).languageCode == 'ne';

  List<String> wardsByLocale(BuildContext context) =>
      _isNepali(context) ? wardsNe : wardsEn;

  void setTab(int tab) {
    selectedTab = tab;
    notifyListeners();
  }

  void toggleNotifyResidents(bool value) {
    notifyResidents = value;
    notifyListeners();
  }

  void reset() {
    selectedTab = 0;
    notifyResidents = true;
    selectedDate = null;
    startTime = null;
    endTime = null;
    selectedWardEnglish = null;
    affectedAreasController.clear();
    fileName = null;
    isPublishing = false;
    notifyListeners();
  }

  /// Convert picked label (maybe Nepali) -> store English value for backend.
  void setSelectedWardFromLabel(BuildContext context, String pickedLabel) {
    if (_isNepali(context)) {
      final idx = wardsNe.indexOf(pickedLabel);
      selectedWardEnglish = (idx >= 0) ? wardsEn[idx] : pickedLabel;
    } else {
      selectedWardEnglish = pickedLabel;
    }
    notifyListeners();
  }

  /// Display selected ward in current locale
  String? wardDisplayForLocale(BuildContext context) {
    if (selectedWardEnglish == null) return null;
    if (!_isNepali(context)) return selectedWardEnglish;

    final idx = wardsEn.indexOf(selectedWardEnglish!);
    if (idx >= 0) return wardsNe[idx];
    return selectedWardEnglish;
  }

  Future<void> openWardPicker(BuildContext context) async {
    final wards = wardsByLocale(context);
    final picked = await showModalBottomSheet<String>(
      context: context,
      builder: (_) => ListView.builder(
        itemCount: wards.length,
        itemBuilder: (_, i) => ListTile(
          title: Text(wards[i]),
          onTap: () => Navigator.pop(context, wards[i]),
        ),
      ),
    );

    if (picked != null) setSelectedWardFromLabel(context, picked);
  }

  Future<void> pickDate(BuildContext context) async {
    final picked = await showDatePicker(
      context: context,
      initialDate: DateTime.now(),
      firstDate: DateTime.now(),
      lastDate: DateTime(2030),
    );
    if (picked != null) {
      selectedDate = picked;
      notifyListeners();
    }
  }

  Future<void> pickTime(BuildContext context, {required bool isStart}) async {
    final picked = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.now(),
    );
    if (picked != null) {
      if (isStart) {
        startTime = picked;
      } else {
        endTime = picked;
      }
      notifyListeners();
    }
  }

  // Preview formatting (UI only)
  String formatDatePreview(DateTime? date) {
    if (date == null) return "mm/dd/yyyy";
    return "${date.month.toString().padLeft(2, '0')}/${date.day.toString().padLeft(2, '0')}/${date.year}";
  }

  String formatTimePreview(TimeOfDay? time) {
    if (time == null) return "-- : -- --";
    final hour = time.hourOfPeriod == 0 ? 12 : time.hourOfPeriod;
    final minute = time.minute.toString().padLeft(2, '0');
    final period = time.period == DayPeriod.am ? "AM" : "PM";
    return "$hour:$minute $period";
  }

  // API formatting
  String _formatDateForApi(DateTime date) {
    final y = date.year.toString().padLeft(4, '0');
    final m = date.month.toString().padLeft(2, '0');
    final d = date.day.toString().padLeft(2, '0');
    return "$y-$m-$d";
  }

  String _formatTimeForApi(TimeOfDay time) {
    final hh = time.hour.toString().padLeft(2, '0');
    final mm = time.minute.toString().padLeft(2, '0');
    return "$hh:$mm";
  }

  bool isManualValid() {
    return selectedWardEnglish != null &&
        selectedDate != null &&
        startTime != null &&
        endTime != null &&
        affectedAreasController.text.trim().isNotEmpty;
  }

  SchedulePayload buildPayload() {
    return SchedulePayload(
      wardNameEnglish: selectedWardEnglish!,
      affectedAreas: affectedAreasController.text.trim(),
      supplyDate: _formatDateForApi(selectedDate!),
      startTime: _formatTimeForApi(startTime!),
      endTime: _formatTimeForApi(endTime!),
      notifyResidents: notifyResidents,
    );
  }

  Future<void> publishManualSchedule() async {
    if (!isManualValid()) throw Exception("VALIDATION_FAILED");

    final user = FirebaseAuth.instance.currentUser;
    if (user == null) throw Exception("NOT_AUTHENTICATED");

    final String? idToken = await user.getIdToken(true);
    if (idToken == null || idToken.isEmpty) throw Exception("TOKEN_MISSING");

    isPublishing = true;
    notifyListeners();

    try {
      await SchedulesService.publishSchedule(
        idToken: idToken,
        payload: buildPayload(),
      );
    } finally {
      isPublishing = false;
      notifyListeners();
    }
  }

  @override
  void dispose() {
    affectedAreasController.dispose();
    super.dispose();
  }
}
