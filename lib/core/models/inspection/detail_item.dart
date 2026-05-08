import 'package:cloud_firestore/cloud_firestore.dart';

class DetailItem {
  final int detailItemId;
  final int itemNumber;
  final String itemDescription;
  final bool reinspectionRequired;
  final String categoryName;
  final bool requiresEntry;
  final bool requiresComment;
  final bool requiresPhoto;
  final bool showC;
  final bool showNC;
  final bool showR;
  final bool showNA;

  DetailItem({
    required this.detailItemId,
    required this.itemNumber,
    required this.itemDescription,
    required this.reinspectionRequired,
    required this.categoryName,
    this.requiresEntry = false,
    this.requiresComment = false,
    this.requiresPhoto = false,
    this.showC = true,
    this.showNC = true,
    this.showR = true,
    this.showNA = true,
  });

  factory DetailItem.fromMap(Map<String, dynamic> data) {
    final dynamic rawDetailId = data['detailItemId'];
    int parsedDetailId = 0;
    if (rawDetailId is int) {
      parsedDetailId = rawDetailId;
    } else if (rawDetailId is String) {
      parsedDetailId = int.tryParse(rawDetailId) ?? 0;
    }

    return DetailItem(
      detailItemId: parsedDetailId,
      itemNumber: data['itemNumber'] as int? ?? 0,
      itemDescription: data['itemDescription'] as String? ?? '',
      reinspectionRequired: data['reinspectionRequired'] as bool? ?? false,
      categoryName: data['categoryName'] as String? ?? '',
      requiresEntry: data['entryRequired'] ?? false,
      requiresComment: data['commentRequired'] ?? false,
      requiresPhoto: data['photoRequired'] ?? false,
      showC: data['showC'] ?? true,
      showNC: data['showNC'] ?? true,
      showR: data['showR'] ?? true,
      showNA: data['showNA'] ?? true,
    );
  }

  factory DetailItem.fromFirestore(DocumentSnapshot snapshot) {
    final data = snapshot.data() as Map<String, dynamic>? ?? {};

    final dynamic rawDetailId = data['detailItemId'];
    int parsedDetailId = 0;
    if (rawDetailId is int) {
      parsedDetailId = rawDetailId;
    } else if (rawDetailId is String) {
      parsedDetailId = int.tryParse(rawDetailId) ?? 0;
    }

    return DetailItem(
      detailItemId: parsedDetailId,
      itemNumber: data['itemNumber'] as int,
      itemDescription: data['itemDescription'] as String,
      reinspectionRequired: data['reinspectionRequired'] as bool,
      categoryName: data['categoryName'] as String,
    );
  }

  Map<String, dynamic> toFirestoreMap() {
    return {
      'detailItemId': detailItemId,
      'itemNumber': itemNumber,
      'itemDescription': itemDescription,
      'reinspectionRequired': reinspectionRequired,
      'categoryName': categoryName,
    };
  }

  DetailItem copyWith({
    int? detailItemId,
    int? itemNumber,
    String? itemDescription,
    bool? reinspectionRequired,
    String? categoryName,
  }) {
    return DetailItem(
      detailItemId: detailItemId ?? this.detailItemId,
      itemNumber: itemNumber ?? this.itemNumber,
      itemDescription: itemDescription ?? this.itemDescription,
      reinspectionRequired: reinspectionRequired ?? this.reinspectionRequired,
      categoryName: categoryName ?? this.categoryName,
    );
  }
}
