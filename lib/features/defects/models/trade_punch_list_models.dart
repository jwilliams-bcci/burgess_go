import 'package:cloud_firestore/cloud_firestore.dart';

/// This represents an individual item within a trade's work order.
class TradeReviewItem {
  final String defectId;
  final String description;
  final bool requirePhoto;
  final bool isCustom;

  TradeReviewItem({
    required this.defectId,
    required this.description,
    this.requirePhoto = false,
    this.isCustom = false,
  });

  Map<String, dynamic> toMap() {
    return {
      'defectId': defectId,
      'description': description,
      'requirePhoto': requirePhoto,
      'isCustom': isCustom,
      'isCompleted': false,
    };
  }
}

class TradePunchList {
  final String? id;
  final int inspectionId;
  final String tradeContactId;
  final String tradeName;
  final List<TradeReviewItem> items;
  final DateTime sentAt;
  final String status;

  TradePunchList({
    this.id,
    required this.inspectionId,
    required this.tradeContactId,
    required this.tradeName,
    required this.items,
    required this.sentAt,
    this.status = 'Sent',
  });

  Map<String, dynamic> toFirestore() {
    return {
      'inspectionId': inspectionId,
      'tradeContactId': tradeContactId,
      'tradeName': tradeName,
      'items': items.map((i) => i.toMap()).toList(),
      'sentAt': FieldValue.serverTimestamp(),
      'status': status,
    };
  }
}
