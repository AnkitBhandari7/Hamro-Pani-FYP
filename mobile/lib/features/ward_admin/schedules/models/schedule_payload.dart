class SchedulePayload {
  final String wardNameEnglish; // ALWAYS English for backend/db consistency
  final String affectedAreas;
  final String supplyDate; // YYYY-MM-DD
  final String startTime; // HH:mm (24-hour)
  final String endTime; // HH:mm (24-hour)
  final bool notifyResidents;

  SchedulePayload({
    required this.wardNameEnglish,
    required this.affectedAreas,
    required this.supplyDate,
    required this.startTime,
    required this.endTime,
    required this.notifyResidents,
  });

  Map<String, dynamic> toJson() => {
    "wardName": wardNameEnglish,
    "affectedAreas": affectedAreas,
    "supplyDate": supplyDate,
    "startTime": startTime,
    "endTime": endTime,
    "notifyResidents": notifyResidents,
  };
}
