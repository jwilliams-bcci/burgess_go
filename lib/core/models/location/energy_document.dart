import 'package:uuid/uuid.dart';

class EnergyDocument {
  final String id;
  final int? energyDocumentId;
  final int? locationId;
  final String? createUser;
  final String? fileName;
  final String? typeName;
  final String? fileLink;

  EnergyDocument({
    required this.id,
    this.energyDocumentId,
    this.locationId,
    this.createUser,
    this.fileName,
    this.typeName,
    this.fileLink,
  });

  factory EnergyDocument.fromMap(Map<String, dynamic> json) {
    return EnergyDocument(
      id: (json['EnergyDocumentID'] ?? const Uuid().v4()).toString(),
      energyDocumentId: json['EnergyDocumentID'] as int?,
      locationId: json['LocationID'] as int?,
      createUser: json['CreateUser'] as String?,
      fileName: json['FileName'] as String?,
      typeName: json['TypeName'] as String?,
      fileLink: json['FileLink'] as String?,
    );
  }

  Map<String, dynamic> toFirestoreMap() {
    return {
      'EnergyDocumentID': energyDocumentId,
      'LocationID': locationId,
      'CreateUser': createUser,
      'FileName': fileName,
      'TypeName': typeName,
      'FileLink': fileLink,
    };
  }

  EnergyDocument copyWith({
    String? id,
    int? energyDocumentId,
    int? locationId,
    String? createUser,
    String? fileName,
    String? typeName,
    String? fileLink,
  }) {
    return EnergyDocument(
      id: id ?? this.id,
      energyDocumentId: energyDocumentId ?? this.energyDocumentId,
      locationId: locationId ?? this.locationId,
      createUser: createUser ?? this.createUser,
      fileName: fileName ?? this.fileName,
      typeName: typeName ?? this.typeName,
      fileLink: fileLink ?? this.fileLink,
    );
  }
}
