class ScheduleInspectionRequest {
  final int locationId;
  final int inspectionTypeId;
  final DateTime requestedDate;
  final String? notes;

  ScheduleInspectionRequest({
    required this.locationId,
    required this.inspectionTypeId,
    required this.requestedDate,
    this.notes,
  });

  Map<String, dynamic> toJson() {
    return {
      'locationId': locationId,
      'inspectionTypeId': inspectionTypeId,
      // Always convert to UTC before sending to the C# API!
      'requestedDate': requestedDate.toUtc().toIso8601String(),
      'notes': notes,
    };
  }
}
