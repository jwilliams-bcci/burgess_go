import 'package:burgess_go/core/models/inspection/detail_item.dart';
import 'package:burgess_go/core/models/inspection/inspection_attachment.dart';
import 'package:burgess_go/core/models/inspection/inspection_message.dart';
import 'package:burgess_go/core/models/inspection/submission.dart';
import 'package:burgess_go/core/models/inspection/submission_detail.dart';
import 'package:burgess_go/utils/json_helper.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class Inspection {
  final int inspectionId;
  final DateTime? inspectionDate;
  final int? divisionId;
  final int? locationId;
  final int? builderId;
  final String? builderName;
  final int? inspectorId;
  final int? inspectorSecurityUserId;
  final String? inspector;
  final int? communityId;
  final String? community;
  final String? lotNumber;
  final String? address;
  final String? city;
  final int? inspectionClass;
  final int? inspectionTypeId;
  final String? inspectionType;
  final bool? reinspect;
  final int? inspectionOrder;
  final int? inspectionStatusId;
  final String? inspectionStatus;
  final int? builderPersonnelId;
  final int? superintendentSecurityUserId;
  final String? superName;
  final String? superPhone;
  final String? superEmailAddress;
  final int? superintendentPresent;
  final int? resolutionId;
  final String? resolution;
  final String? notes;
  final String? jobNumber;
  final bool? requireRiskAssessment;
  final String? ekotropeProjectId;
  final String? jotformLink;
  final DateTime? editDate;
  final List<DetailItem>? detailItems;
  final int? inspectionTotal;
  final List<InspectionMessage>? inspectionMessages;
  final List<InspectionAttachment>? inspectionAttachments;
  final List<SubmissionDetail>? reinspectItems;
  final Submission? submission;
  bool isComplete;
  final bool isUploaded;
  final bool fromCache;
  final String? guestToken;

  Inspection({
    required this.inspectionId,
    this.inspectionDate,
    this.divisionId,
    this.locationId,
    this.builderName,
    this.builderId,
    this.superName,
    this.inspectorId,
    this.inspectorSecurityUserId,
    this.inspector,
    this.communityId,
    this.community,
    this.lotNumber,
    this.address,
    this.city,
    this.inspectionClass,
    this.inspectionTypeId,
    this.inspectionType,
    this.reinspect,
    this.inspectionOrder,
    this.inspectionStatusId,
    this.inspectionStatus,
    this.builderPersonnelId,
    this.superintendentSecurityUserId,
    this.superPhone,
    this.superEmailAddress,
    this.superintendentPresent,
    this.resolution,
    this.resolutionId,
    this.notes,
    this.jobNumber,
    this.requireRiskAssessment,
    this.ekotropeProjectId,
    this.jotformLink,
    this.editDate,
    this.detailItems,
    this.inspectionTotal,
    this.inspectionMessages,
    List<InspectionAttachment>? inspectionAttachments,
    this.reinspectItems,
    this.submission,
    this.isComplete = false,
    this.isUploaded = false,
    required this.fromCache,
    this.guestToken,
  }) : inspectionAttachments = inspectionAttachments ?? const [];

  factory Inspection.fromFirestore(DocumentSnapshot snapshot) {
    final data = snapshot.data() as Map<String, dynamic>? ?? {};

    return Inspection(
      inspectionId: data['inspectionId'] as int,
      inspectionDate: parseDateTimeFromTimestamp(data['inspectionDate']),
      divisionId: data['divisionId'] as int?,
      locationId: data['locationId'] as int?,
      builderId: data['builderId'] as int?,
      builderName: data['builderName'] as String?,
      inspectorId: data['inspectorId'] as int?,
      inspectorSecurityUserId: data['inspectorSecurityUserId'] as int?,
      inspector: data['inspector'] as String?,
      communityId: data['communityId'] as int?,
      community: data['community'] as String?,
      lotNumber: data['lotNumber'] as String?,
      address: data['address'] as String?,
      city: data['city'] as String?,
      inspectionClass: data['inspectionClass'] as int?,
      inspectionTypeId: data['inspectionTypeId'] as int?,
      inspectionType: data['inspectionType'] as String?,
      reinspect: data['reinspect'] as bool?,
      inspectionOrder: data['inspectionOrder'] as int?,
      inspectionStatusId: data['inspectionStatusId'] as int?,
      inspectionStatus: data['inspectionStatus'] as String?,
      builderPersonnelId: data['builderPersonnelId'] as int?,
      superintendentSecurityUserId:
          data['superintendentSecurityUserId'] as int?,
      superName: data['superName'] as String?,
      superPhone: data['superPhone'] as String?,
      superEmailAddress: data['superEmailAddress'] as String?,
      resolutionId: data['resolutionId'] as int?,
      resolution: data['resolution'] as String?,
      notes: data['notes'] as String?,
      jobNumber: data['jobNumber'] as String?,
      requireRiskAssessment: data['requireRiskAssessment'] as bool?,
      ekotropeProjectId: data['ekotropeProjectId'] as String?,
      jotformLink: data['jotformLink'] as String?,
      editDate: parseDateTimeFromTimestamp(data['editDate']),
      inspectionTotal: data['inspectionTotal'] as int?,
      detailItems: (data['detailItems'] as List<dynamic>?)
          ?.map((item) => DetailItem.fromMap(item as Map<String, dynamic>))
          .toList(),
      inspectionAttachments: (data['inspectionAttachments'] as List<dynamic>?)
          ?.map(
            (item) =>
                InspectionAttachment.fromMap(item as Map<String, dynamic>),
          )
          .toList(),
      reinspectItems: (data['reinspectItems'] as List<dynamic>?)
          ?.map(
            (item) => SubmissionDetail.fromMap(item as Map<String, dynamic>),
          )
          .toList(),
      submission: data['submission'] == null
          ? null
          : Submission.fromMap(data['submission'] as Map<String, dynamic>),
      isComplete: data['isComplete'] as bool? ?? false,
      isUploaded: data['isUploaded'] as bool? ?? false,
      fromCache: snapshot.metadata.isFromCache,
      guestToken: data['guestToken'] as String?,
    );
  }

  Map<String, dynamic> toFirestoreMap() {
    final Map<String, dynamic> data = {
      'inspectionId': inspectionId,
      'inspectionDate': Timestamp.fromDate(inspectionDate!),
      'divisionId': divisionId,
      'locationId': locationId,
      'builderId': builderId,
      'builderName': builderName,
      'inspectorId': inspectorId,
      'inspectorSecurityUserId': inspectorSecurityUserId,
      'inspector': inspector,
      'communityId': communityId,
      'community': community,
      'lotNumber': lotNumber,
      'address': address,
      'city': city,
      'inspectionClass': inspectionClass,
      'inspectionTypeId': inspectionTypeId,
      'inspectionType': inspectionType,
      'reinspect': reinspect,
      'inspectionOrder': inspectionOrder,
      'inspectionStatusId': inspectionStatusId,
      'inspectionStatus': inspectionStatus,
      'builderPersonnelId': builderPersonnelId,
      'superintendentSecurityUserId': superintendentSecurityUserId,
      'superName': superName,
      'superPhone': superPhone,
      'superEmailAddress': superEmailAddress,
      'resolutionId': resolutionId,
      'resolution': resolution,
      'notes': notes,
      'jobNumber': jobNumber,
      'inspectionTotal': inspectionTotal,
      'requireRiskAssessment': requireRiskAssessment,
      'ekotropeProjectId': ekotropeProjectId,
      'jotformLink': jotformLink,
      'inspectionAttachments': inspectionAttachments
          ?.map((e) => e.toFirestoreMap())
          .toList(),
      'editDate': FieldValue.serverTimestamp(),
      'isComplete': isComplete,
      'isUploaded': isUploaded,
      'submission': submission?.toFirestoreMap(),
      'guestToken': guestToken,
    };
    return data;
  }

  Inspection copyWith({
    int? inspectionId,
    DateTime? inspectionDate,
    int? divisionId,
    int? locationId,
    String? builderName,
    int? builderId,
    String? superName,
    int? inspectorId,
    int? inspectorSecurityUserId,
    String? inspector,
    String? community,
    int? communityId,
    String? city,
    int? inspectionClass,
    int? inspectionTypeId,
    String? inspectionType,
    bool? reinspect,
    int? inspectionOrder,
    String? lotNumber,
    String? address,
    int? inspectionStatusId,
    String? inspectionStatus,
    int? builderPersonnelId,
    int? superintendentSecurityUserId,
    String? superPhone,
    String? superEmailAddress,
    int? superintendentPresent,
    String? incompleteReason,
    int? incompleteReasonId,
    String? notes,
    String? jobNumber,
    bool? requireRiskAssessment,
    String? ekotropeProjectId,
    String? jotformLink,
    DateTime? editDate,
    int? inspectionTotal,
    List<DetailItem>? detailItems,
    List<InspectionMessage>? inspectionMessages,
    List<InspectionAttachment>? inspectionAttachments,
    List<SubmissionDetail>? reinspectItems,
    Submission? submission,
    bool? isComplete,
    bool? isUploaded,
    bool? fromCache,
    String? guestToken,
  }) {
    return Inspection(
      inspectionId: inspectionId ?? this.inspectionId,
      inspectionDate: inspectionDate ?? this.inspectionDate,
      divisionId: divisionId ?? this.divisionId,
      locationId: locationId ?? this.locationId,
      builderName: builderName ?? this.builderName,
      builderId: builderId ?? this.builderId,
      superName: superName ?? this.superName,
      inspectorId: inspectorId ?? this.inspectorId,
      inspectorSecurityUserId:
          inspectorSecurityUserId ?? this.inspectorSecurityUserId,
      inspector: inspector ?? this.inspector,
      community: community ?? this.community,
      communityId: communityId ?? this.communityId,
      city: city ?? this.city,
      inspectionClass: inspectionClass ?? this.inspectionClass,
      inspectionTypeId: inspectionTypeId ?? this.inspectionTypeId,
      inspectionType: inspectionType ?? this.inspectionType,
      reinspect: reinspect ?? this.reinspect,
      inspectionOrder: inspectionOrder ?? this.inspectionOrder,
      lotNumber: lotNumber ?? this.lotNumber,
      address: address ?? this.address,
      inspectionStatusId: inspectionStatusId ?? this.inspectionStatusId,
      inspectionStatus: inspectionStatus ?? this.inspectionStatus,
      builderPersonnelId: builderPersonnelId ?? this.builderPersonnelId,
      superintendentSecurityUserId:
          superintendentSecurityUserId ?? this.superintendentSecurityUserId,
      superPhone: superPhone ?? this.superPhone,
      superEmailAddress: superEmailAddress ?? this.superEmailAddress,
      superintendentPresent:
          superintendentPresent ?? this.superintendentPresent,
      resolution: incompleteReason ?? resolution,
      resolutionId: incompleteReasonId ?? resolutionId,
      notes: notes ?? this.notes,
      jobNumber: jobNumber ?? this.jobNumber,
      requireRiskAssessment:
          requireRiskAssessment ?? this.requireRiskAssessment,
      ekotropeProjectId: ekotropeProjectId ?? this.ekotropeProjectId,
      jotformLink: jotformLink ?? this.jotformLink,
      editDate: editDate ?? this.editDate,
      inspectionTotal: inspectionTotal ?? this.inspectionTotal,
      detailItems: detailItems ?? this.detailItems,
      inspectionMessages: inspectionMessages ?? this.inspectionMessages,
      inspectionAttachments:
          inspectionAttachments ?? this.inspectionAttachments,
      reinspectItems: reinspectItems ?? this.reinspectItems,
      submission: submission ?? this.submission,
      isComplete: isComplete ?? this.isComplete,
      isUploaded: isUploaded ?? this.isUploaded,
      fromCache: fromCache ?? this.fromCache,
      guestToken: guestToken ?? this.guestToken,
    );
  }
}
