import 'package:burgess_go/utils/json_helper.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:uuid/uuid.dart';

class SubmissionDetail {
  final String id;
  final int? boreInspectionDetailId;
  int? userId;
  int? inspectionId;
  final int detailItemId;
  final String? defectCategory;
  final int itemNumber;
  final String itemDescription;
  final DateTime? createDate;
  int? detailStatusId;
  String? comment;
  String? originalFileLink;
  String? fileLink;
  String? localImagePath;
  int? priorDetailId;
  int? firstDetailId;
  String? lotNumber;
  String? stageOfConstruction;
  final bool? sentToTrade;
  final String? tradePhotoUrl;

  SubmissionDetail({
    String? id,
    this.boreInspectionDetailId,
    this.userId,
    this.inspectionId,
    required this.detailItemId,
    this.defectCategory,
    required this.itemNumber,
    required this.itemDescription,
    this.createDate,
    this.detailStatusId,
    this.comment,
    this.originalFileLink,
    this.fileLink,
    this.localImagePath,
    this.priorDetailId,
    this.firstDetailId,
    this.lotNumber,
    this.stageOfConstruction,
    this.sentToTrade = false,
    this.tradePhotoUrl,
  }) : id = id ?? const Uuid().v4();

  factory SubmissionDetail.fromMap(Map<String, dynamic> json) {
    return SubmissionDetail(
      id: (json['boreInspectionDetailId'] ?? const Uuid().v4()).toString(),
      boreInspectionDetailId: json['boreInspectionDetailId'] as int?,
      userId: json['userId'] as int?,
      inspectionId: json['inspectionId'] as int?,
      detailItemId: json['detailItemId'] as int,
      defectCategory: json['defectCategory'] as String?,
      itemNumber: json['itemNumber'] as int,
      itemDescription: json['itemDescription'] as String,
      createDate: parseDateTimeFromTimestamp(json['createDate']),
      detailStatusId: json['detailStatusId'] as int?,
      comment: json['comment'] as String?,
      originalFileLink: json['originalFileLink'] as String?,
      fileLink: json['fileLink'] as String?,
      priorDetailId: json['priorDetailId'] as int?,
      firstDetailId: json['firstDetailId'] as int?,
      lotNumber: json['lotNumber'] as String?,
      stageOfConstruction: json['stageOfConstruction'] as String?,
      sentToTrade: json['sentToTrade'] as bool? ?? false,
      tradePhotoUrl: json['tradePhotoUrl'] as String?,
    );
  }

  factory SubmissionDetail.fromFirestore(DocumentSnapshot snapshot) {
    final data = snapshot.data() as Map<String, dynamic>? ?? {};

    return SubmissionDetail(
      id: snapshot.id,
      boreInspectionDetailId: data['boreInspectionDetailId'] as int?,
      userId: data['userId'] as int?,
      inspectionId: data['inspectionId'] as int?,
      detailItemId: data['detailItemId'] as int,
      defectCategory: data['defectCategory'] as String?,
      itemNumber: data['itemNumber'] as int,
      itemDescription: data['itemDescription'] as String,
      createDate: parseDateTimeFromTimestamp(data['createDate']),
      detailStatusId: data['detailStatusId'] as int?,
      comment: data['comment'] as String?,
      originalFileLink: data['originalFileLink'] as String?,
      fileLink: data['fileLink'] as String?,
      priorDetailId: data['priorDetailId'] as int?,
      firstDetailId: data['firstDetailId'] as int?,
      lotNumber: data['lotNumber'] as String?,
      stageOfConstruction: data['stageOfConstruction'] as String?,
      sentToTrade: data['sentToTrade'] as bool? ?? false,
      tradePhotoUrl: data['tradePhotoUrl'] as String?,
    );
  }

  Map<String, dynamic> toFirestoreMap() {
    return {
      'boreInspectionDetailId': boreInspectionDetailId,
      'userId': userId,
      'inspectionId': inspectionId,
      'detailItemId': detailItemId,
      'defectCategory': defectCategory,
      'itemDescription': itemDescription,
      'itemNumber': itemNumber,
      'createDate': createDate != null
          ? Timestamp.fromDate(createDate!)
          : FieldValue.serverTimestamp(),
      'detailStatusId': detailStatusId,
      'comment': comment,
      'originalFileLink': originalFileLink,
      'fileLink': fileLink,
      'priorDetailId': priorDetailId,
      'firstDetailId': firstDetailId,
      'lotNumber': lotNumber,
      'stageOfConstruction': stageOfConstruction,
      'sentToTrade': sentToTrade,
      'tradePhotoUrl': tradePhotoUrl,
    };
  }

  SubmissionDetail copyWith({
    String? id,
    int? boreInspectionDetailId,
    int? userId,
    int? inspectionId,
    int? detailItemId,
    String? defectCategory,
    String? itemDescription,
    int? itemNumber,
    DateTime? createDate,
    int? detailStatusId,
    String? comment,
    String? originalFileLink,
    String? fileLink,
    bool clearFileLink = false,
    String? localImagePath,
    bool clearLocalImagePath = false,
    int? priorDetailId,
    int? firstDetailId,
    String? lotNumber,
    String? stageOfConstruction,
    bool? sentToTrade = false,
    String? tradePhotoUrl,
  }) {
    return SubmissionDetail(
      id: id ?? this.id,
      boreInspectionDetailId:
          boreInspectionDetailId ?? this.boreInspectionDetailId,
      userId: userId ?? this.userId,
      inspectionId: inspectionId ?? this.inspectionId,
      detailItemId: detailItemId ?? this.detailItemId,
      defectCategory: defectCategory ?? this.defectCategory,
      itemDescription: itemDescription ?? this.itemDescription,
      itemNumber: itemNumber ?? this.itemNumber,
      createDate: createDate ?? this.createDate,
      detailStatusId: detailStatusId ?? this.detailStatusId,
      comment: comment ?? this.comment,
      originalFileLink: originalFileLink ?? this.originalFileLink,
      fileLink: clearFileLink ? null : (fileLink ?? this.fileLink),
      localImagePath: clearLocalImagePath
          ? null
          : (localImagePath ?? this.localImagePath),
      priorDetailId: priorDetailId ?? this.priorDetailId,
      firstDetailId: firstDetailId ?? this.firstDetailId,
      lotNumber: lotNumber ?? this.lotNumber,
      stageOfConstruction: stageOfConstruction ?? this.stageOfConstruction,
      sentToTrade: sentToTrade ?? this.sentToTrade,
      tradePhotoUrl: tradePhotoUrl ?? this.tradePhotoUrl,
    );
  }
}
