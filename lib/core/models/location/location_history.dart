import 'package:burgess_go/utils/json_helper.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class LocationHistory {
  final int inspectionId;
  final int inspectionTypeId;
  final String inspectionType;
  final String resolution;
  final DateTime? submissionDate;
  final String inspector;
  final String reportLink;

  LocationHistory({
    required this.inspectionId,
    required this.inspectionTypeId,
    required this.inspectionType,
    required this.resolution,
    this.submissionDate,
    required this.inspector,
    required this.reportLink,
  });

  factory LocationHistory.fromMap(Map<String, dynamic> data) {
    return LocationHistory(
      // Provide a fallback of 0 for missing integers
      inspectionId: data['inspectionId'] as int? ?? 0,
      inspectionTypeId: data['inspectionTypeId'] as int? ?? 0,

      // Provide a fallback of '' or 'Unknown' for missing strings
      inspectionType: data['inspectionType'] as String? ?? 'Unknown Type',
      resolution: data['resolution'] as String? ?? 'Unknown',
      submissionDate: parseDateTimeFromTimestamp(data['submissionDate']),
      inspector: data['inspector'] as String? ?? 'Unknown',
      reportLink: data['reportLink'] as String? ?? '',
    );
  }

  Map<String, dynamic> toFirestoreMap() {
    return {
      'inspectionId': inspectionId,
      'inspectionTypeId': inspectionTypeId,
      'inspectionType': inspectionType,
      'resolution': resolution,
      'submissionDate': submissionDate != null
          ? Timestamp.fromDate(submissionDate!)
          : null,
      'inspector': inspector,
      'reportLink': reportLink,
    };
  }

  LocationHistory copyWith({
    int? inspectionId,
    int? inspectionTypeId,
    String? inspectionType,
    String? resolution,
    DateTime? submissionDate,
    String? inspector,
    String? reportLink,
    String? firebaseLink,
  }) {
    return LocationHistory(
      inspectionId: inspectionId ?? this.inspectionId,
      inspectionTypeId: inspectionTypeId ?? this.inspectionTypeId,
      inspectionType: inspectionType ?? this.inspectionType,
      resolution: resolution ?? this.resolution,
      submissionDate: submissionDate ?? this.submissionDate,
      inspector: inspector ?? this.inspector,
      reportLink: reportLink ?? this.reportLink,
    );
  }
}
