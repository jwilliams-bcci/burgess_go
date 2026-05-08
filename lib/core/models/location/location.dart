import 'package:burgess_go/core/models/location/energy_document.dart';
import 'package:burgess_go/core/models/location/inspection_type.dart';
import 'package:burgess_go/core/models/location/location_attachment.dart';
import 'package:burgess_go/core/models/location/location_history.dart';
import 'package:burgess_go/utils/json_helper.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';

class Location {
  final int locationId;
  final int? divisionId;
  final String? ekotropeProjectId;
  final int? communityId;
  final String? community;
  final String? address;
  final String? lotNumber;
  final String? city;
  final String? elevationPhotoUrl;
  final List<LocationHistory>? locationHistories;
  final List<LocationAttachment>? locationAttachments;
  final List<EnergyDocument>? energyDocuments;
  final List<InspectionType>? availableInspectionTypes;
  final GeoPoint? coordinates;
  final DateTime? editDate;
  final bool isClosedOut;

  Location({
    required this.locationId,
    this.address,
    this.lotNumber,
    this.city,
    this.communityId,
    this.community,
    this.divisionId,
    this.ekotropeProjectId,
    this.coordinates,
    this.elevationPhotoUrl,
    List<LocationHistory>? locationHistories,
    List<LocationAttachment>? locationAttachments,
    List<EnergyDocument>? energyDocuments,
    List<InspectionType>? availableInspectionTypes,
    this.editDate,
    this.isClosedOut = false,
  }) : locationHistories = locationHistories ?? const [],
       locationAttachments = locationAttachments ?? const [],
       energyDocuments = energyDocuments ?? const [],
       availableInspectionTypes = availableInspectionTypes ?? const [];

  factory Location.fromFirestore(DocumentSnapshot snapshot) {
    final data = snapshot.data() as Map<String, dynamic>? ?? {};

    return Location(
      locationId: int.parse(snapshot.id),
      address: data['address'] as String?,
      lotNumber: data['lotNumber'] as String?,
      city: data['city'] as String?,
      communityId: data['communityId'] as int?,
      community: data['community'] as String?,
      divisionId: data['divisionId'] as int?,
      ekotropeProjectId: data['ekotropeProjectId'] as String?,
      elevationPhotoUrl: data['elevationPhotoUrl'] as String?,
      locationHistories:
          (data['locationHistories'] as List<dynamic>?)
              ?.map(
                (item) => LocationHistory.fromMap(item as Map<String, dynamic>),
              )
              .toList() ??
          const [],
      locationAttachments:
          (data['locationAttachments'] as List<dynamic>?)
              ?.map(
                (item) =>
                    LocationAttachment.fromMap(item as Map<String, dynamic>),
              )
              .toList() ??
          const [],
      energyDocuments:
          (data['energyDocuments'] as List<dynamic>?)
              ?.map(
                (item) => EnergyDocument.fromMap(item as Map<String, dynamic>),
              )
              .toList() ??
          const [],
      availableInspectionTypes:
          (data['availableInspectionTypes'] as List<dynamic>?)
              ?.map(
                (item) => InspectionType.fromMap(item as Map<String, dynamic>),
              )
              .toList() ??
          const [],
      coordinates: data['coordinates'] as GeoPoint?,
      editDate: parseDateTimeFromTimestamp(data['editDate']),
      isClosedOut: data['isClosedOut'] as bool? ?? false,
    );
  }

  Map<String, dynamic> toFirestoreMap() {
    final Map<String, dynamic> data = {
      'locationId': locationId,
      'address': address,
      'lotNumber': lotNumber,
      'city': city,
      'communityId': communityId,
      'community': community,
      'divisionId': divisionId,
      'ekotropeProjectId': ekotropeProjectId,
      'elevationPhotoUrl': elevationPhotoUrl,
      'locationHistories': locationHistories
          ?.map((e) => e.toFirestoreMap())
          .toList(),
      'locationAttachments': locationAttachments
          ?.map((e) => e.toFirestoreMap())
          .toList(),
      'energyDocuments': energyDocuments
          ?.map((e) => e.toFirestoreMap())
          .toList(),
      'availableInspectionTypes': availableInspectionTypes
          ?.map((e) => e.toFirestoreMap())
          .toList(),
      'coordinates': coordinates,
      'editDate': FieldValue.serverTimestamp(),
      'isClosedOut': isClosedOut,
    };
    return data;
  }

  Location copyWith({
    int? locationId,
    String? address,
    String? lotNumber,
    String? city,
    int? communityId,
    String? community,
    int? divisionId,
    String? ekotropeProjectId,
    String? elevationPhotoUrl,
    List<LocationHistory>? locationHistories,
    List<LocationAttachment>? locationAttachments,
    List<EnergyDocument>? energyDocuments,
    List<InspectionType>? availableInspectionTypes,
    GeoPoint? coordinates,
    DateTime? editDate,
    bool? isClosedOut,
  }) {
    return Location(
      locationId: locationId ?? this.locationId,
      address: address ?? this.address,
      city: city ?? this.city,
      communityId: communityId ?? this.communityId,
      community: community ?? this.community,
      divisionId: divisionId ?? this.divisionId,
      ekotropeProjectId: ekotropeProjectId ?? this.ekotropeProjectId,
      elevationPhotoUrl: elevationPhotoUrl ?? this.elevationPhotoUrl,
      locationHistories: locationHistories ?? this.locationHistories,
      locationAttachments: locationAttachments ?? this.locationAttachments,
      energyDocuments: energyDocuments ?? this.energyDocuments,
      availableInspectionTypes:
          availableInspectionTypes ?? this.availableInspectionTypes,
      coordinates: coordinates ?? this.coordinates,
      editDate: editDate ?? this.editDate,
      isClosedOut: isClosedOut ?? this.isClosedOut,
    );
  }
}
