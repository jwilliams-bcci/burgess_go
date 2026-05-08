class InspectionType {
  final int inspectionTypeId;
  final String typeName;
  final String? iconStatus;
  final int? activeInspectionId;

  InspectionType({
    required this.inspectionTypeId,
    required this.typeName,
    this.iconStatus,
    this.activeInspectionId,
  });

  factory InspectionType.fromMap(Map<String, dynamic> map) {
    return InspectionType(
      inspectionTypeId: map['inspectionTypeId']?.toInt() ?? 0,
      typeName: map['typeName'] ?? '',
      iconStatus: map['iconStatus'],
      activeInspectionId:
          (map['activeInspectionId'] ?? map['ActiveInspectionId'])?.toInt(),
    );
  }

  Map<String, dynamic> toFirestoreMap() {
    return {
      'inspectionTypeId': inspectionTypeId,
      'typeName': typeName,
      'iconStatus': iconStatus,
      'activeInspectionId': activeInspectionId,
    };
  }
}
