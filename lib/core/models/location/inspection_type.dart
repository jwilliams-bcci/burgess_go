import 'package:cloud_firestore/cloud_firestore.dart';

class InspectionType {
  final int inspectionTypeId;
  final String typeName;
  final String? iconStatus;
  final int? activeInspectionId;
  final DateTime? activeInspectionDate;

  InspectionType({
    required this.inspectionTypeId,
    required this.typeName,
    this.iconStatus,
    this.activeInspectionId,
    this.activeInspectionDate,
  });

  factory InspectionType.fromMap(Map<String, dynamic> map) {
    return InspectionType(
      inspectionTypeId: map['inspectionTypeId']?.toInt() ?? 0,
      typeName: map['typeName'] ?? '',
      iconStatus: map['iconStatus'],
      activeInspectionId:
          (map['activeInspectionId'] ?? map['ActiveInspectionId'])?.toInt(),
      activeInspectionDate: map['activeInspectionDate'] != null
          ? (map['activeInspectionDate'] is Timestamp
                ? (map['activeInspectionDate'] as Timestamp).toDate()
                : DateTime.tryParse(map['activeInspectionDate'].toString()))
          : null,
    );
  }

  Map<String, dynamic> toFirestoreMap() {
    return {
      'inspectionTypeId': inspectionTypeId,
      'typeName': typeName,
      'iconStatus': iconStatus,
      'activeInspectionId': activeInspectionId,
      'activeInspectionDate': activeInspectionDate?.toIso8601String(),
    };
  }
}
