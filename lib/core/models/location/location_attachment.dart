import 'package:burgess_go/models/i_uploadable.dart';
import 'package:burgess_go/utils/json_helper.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import 'package:uuid/uuid.dart';

class LocationAttachment implements IUploadable {
  @override
  final String id;
  @override
  final String? fileName;
  @override
  final String? localPath;

  final int? locationAttachmentId;
  final int? userId;
  final int? locationId;
  final String? fileExtension;
  final String? remoteUrl;
  final String? comment;
  final DateTime? uploadedDate;
  final bool isUploaded;

  LocationAttachment({
    required this.id,
    this.locationAttachmentId,
    this.userId,
    this.locationId,
    this.fileName,
    this.fileExtension,
    this.remoteUrl,
    this.comment,
    this.uploadedDate,
    this.localPath,
    this.isUploaded = false,
  });

  factory LocationAttachment.fromMap(Map<String, dynamic> json) {
    return LocationAttachment(
      // 🔥 Fallback to 'ID' to match Firestore screenshot, then standard fields
      id: (json['ID'] ?? json['locationAttachmentId'] ?? const Uuid().v4())
          .toString(),
      locationAttachmentId: json['locationAttachmentId'] as int?,
      userId: json['userId'] as int?,
      locationId: json['locationId'] as int?,
      fileName: (json['Filename'] ?? json['fileName']) as String?,
      fileExtension: json['fileExtension'] as String?,
      remoteUrl: (json['Url'] ?? json['fileLink']) as String?,
      comment: json['comment'] as String?,
      uploadedDate: parseDateTimeFromTimestamp(json['uploadedDate']),
      isUploaded: true,
    );
  }

  Map<String, dynamic> toFirestoreMap() {
    return {
      'locationAttachmentId': locationAttachmentId,
      'userId': userId,
      'locationId': locationId,
      'fileName': fileName,
      'fileExtension': fileExtension,
      'fileLink': remoteUrl,
      'comment': comment,
      'uploadedDate': uploadedDate != null
          ? Timestamp.fromDate(uploadedDate!)
          : null,
    };
  }

  LocationAttachment copyWith({
    String? id,
    int? locationAttachmentId,
    int? userId,
    int? locationId,
    String? fileName,
    String? fileExtension,
    String? remoteUrl,
    String? comment,
    DateTime? uploadedDate,
    String? localPath,
    bool? isUploaded,
  }) {
    return LocationAttachment(
      id: id ?? this.id,
      locationAttachmentId: locationAttachmentId ?? this.locationAttachmentId,
      userId: userId ?? this.userId,
      locationId: locationId ?? this.locationId,
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
