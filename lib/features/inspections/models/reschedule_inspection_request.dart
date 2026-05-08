class RescheduleInspectionRequest {
  final DateTime date;
  final String? notes;

  RescheduleInspectionRequest({required this.date, this.notes});

  Map<String, dynamic> toJson() {
    return {
      // Always convert to UTC before sending to the C# API!
      'date': date.toUtc().toIso8601String(),
      'notes': notes,
    };
  }
}
