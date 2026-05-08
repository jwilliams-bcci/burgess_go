import 'package:burgess_go/utils/json_helper.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class Submission {
  final int? statusId;
  final int? locationId;
  int? inspectionTotal;
  bool? superPresent;
  DateTime? startTime;
  DateTime? endTime;
  bool? training;
  int? traineeId;
  String? resolutionChangeReason;
  int? numberRepaired;
  bool? wasteIdentified;

  Submission({
    this.statusId,
    this.locationId,
    this.inspectionTotal,
    this.superPresent,
    this.startTime,
    this.endTime,
    this.training,
    this.traineeId,
    this.resolutionChangeReason,
    this.numberRepaired,
    this.wasteIdentified,
  });

  factory Submission.fromMap(Map<String, dynamic> data) {
    return Submission(
      statusId: data['statusId'] as int?,
      locationId: data['locationId'] as int?,
      inspectionTotal: data['inspectionTotal'] as int?,
      superPresent: data['superPresent'] as bool?,
      startTime: parseDateTimeFromTimestamp(data['startTime']),
      endTime: parseDateTimeFromTimestamp(data['endTime']),
      training: data['training'] as bool?,
      traineeId: data['traineeId'] as int?,
      resolutionChangeReason: data['resolutionChangeReason'] as String?,
      numberRepaired: data['numberRepaired'] as int?,
      wasteIdentified: data['wasteIdentified'] as bool?,
    );
  }

  Map<String, dynamic> toFirestoreMap({bool isCreating = false}) {
    return {
      'statusId': statusId,
      'locationId': locationId,
      'inspectionTotal': inspectionTotal,
      'superPresent': superPresent,
      'startTime': startTime != null ? Timestamp.fromDate(startTime!) : null,
      'endTime': endTime != null ? Timestamp.fromDate(endTime!) : null,
      'training': training,
      'traineeId': traineeId,
      'resolutionChangeReason': resolutionChangeReason,
      'numberRepaired': numberRepaired,
      'wasteIdentified': wasteIdentified,
    };
  }

  Submission copyWith({
    int? statusId,
    int? locationId,
    int? inspectionTotal,
    bool? superPresent,
    DateTime? startTime,
    DateTime? endTime,
    bool? training,
    int? traineeId,
    String? resolutionChangeReason,
    int? numberRepaired,
    bool? wasteIdentified,
  }) {
    return Submission(
      statusId: statusId ?? this.statusId,
      locationId: locationId ?? this.locationId,
      inspectionTotal: inspectionTotal ?? this.inspectionTotal,
      superPresent: superPresent ?? this.superPresent,
      startTime: startTime ?? this.startTime,
      endTime: endTime ?? this.endTime,
      training: training ?? this.training,
      traineeId: traineeId ?? this.traineeId,
      resolutionChangeReason:
          resolutionChangeReason ?? this.resolutionChangeReason,
      numberRepaired: numberRepaired ?? this.numberRepaired,
      wasteIdentified: wasteIdentified ?? this.wasteIdentified,
    );
  }
}
