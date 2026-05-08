import 'package:burgess_go/models/i_uploadable.dart';
import 'package:burgess_go/utils/json_helper.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:uuid/uuid.dart';

class InspectionAttachment implements IUploadable {
  @override
  final String id;
  @override
  final String? fileName;
  @override
  final String? localPath;

  final int? inspectionAttachmentId;
  final int? userId;
  final int? inspectionId;
  final String? fileExtension;
  final String? remoteUrl;
  final String? comment;
  final DateTime? uploadedDate;
  final bool isUploaded;

  InspectionAttachment({
    required this.id,
    this.inspectionAttachmentId,
    this.userId,
    this.inspectionId,
    this.fileName,
    this.fileExtension,
    this.remoteUrl,
    this.comment,
    this.uploadedDate,
    this.localPath,
    this.isUploaded = false,
  });

  /// Creates an instance from data fetched from Firestore/API.
  factory InspectionAttachment.fromMap(Map<String, dynamic> json) {
    return InspectionAttachment(
      // 🔥 Fallback to 'ID' to match Firestore, then standard fields
      id: (json['ID'] ?? json['inspectionAttachmentId'] ?? const Uuid().v4())
          .toString(),
      inspectionAttachmentId: json['inspectionAttachmentId'] as int?,
      userId: json['userId'] as int?,
      inspectionId: json['inspectionId'] as int?,
      // 🔥 Look for 'Filename' (capital F) first, then fallback to 'fileName'
      fileName: (json['Filename'] ?? json['fileName']) as String?,
      fileExtension: json['fileExtension'] as String?,
      // 🔥 Look for 'Url' (capital U) first, then fallback to 'fileLink'
      remoteUrl: (json['Url'] ?? json['fileLink']) as String?,
      comment: json['comment'] as String?,
      uploadedDate: parseDateTimeFromTimestamp(json['uploadedDate']),
      isUploaded: true,
    );
  }

  /// Converts the object to a map for storing in Firestore.
  /// Note: We only store the remote data, not the local state.
  Map<String, dynamic> toFirestoreMap() {
    return {
      'inspectionAttachmentId': inspectionAttachmentId,
      'userId': userId,
      'inspectionId': inspectionId,
      'fileName': fileName,
      'fileExtension': fileExtension,
      'fileLink': remoteUrl,
      'comment': comment,
      'uploadedDate': uploadedDate != null
          ? Timestamp.fromDate(uploadedDate!)
          : null,
    };
  }

  InspectionAttachment copyWith({
    String? id,
    int? inspectionAttachmentId,
    int? userId,
    int? inspectionId,
    String? fileName,
    String? fileExtension,
    String? remoteUrl,
    String? comment,
    DateTime? uploadedDate,
    String? localPath,
    bool? isUploaded,
  }) {
    return InspectionAttachment(
      id: id ?? this.id,
      inspectionAttachmentId:
          inspectionAttachmentId ?? this.inspectionAttachmentId,
      userId: userId ?? this.userId,
      inspectionId: inspectionId ?? this.inspectionId,
      fileName: fileName ?? this.fileName,
      fileExtension: fileExtension ?? this.fileExtension,
      remoteUrl: remoteUrl ?? this.remoteUrl,
      comment: comment ?? this.comment,
      uploadedDate: uploadedDate ?? this.uploadedDate,
      localPath: localPath ?? this.localPath,
      isUploaded: isUploaded ?? this.isUploaded,
    );
  }
}
