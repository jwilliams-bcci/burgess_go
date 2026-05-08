import 'package:burgess_go/utils/json_helper.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class InspectionMessage {
  final int senderId;
  final String? senderName;
  final DateTime? sendDate;
  final String messageText;

  InspectionMessage({
    required this.senderId,
    this.senderName,
    this.sendDate,
    required this.messageText,
  });

  factory InspectionMessage.fromMap(Map<String, dynamic> data) {
    return InspectionMessage(
      senderId: data['senderId'] as int? ?? 0,
      senderName: data['senderName'] as String?,
      sendDate: parseDateTimeFromTimestamp(data['sendDate']),
      messageText: data['messageText'] as String? ?? '',
    );
  }

  Map<String, dynamic> toFirestoreMap() {
    return {
      'senderId': senderId,
      'senderName': senderName,
      'sendDate': sendDate != null
          ? Timestamp.fromDate(sendDate!)
          : FieldValue.serverTimestamp(),
      'messageText': messageText,
    };
  }

  InspectionMessage copyWith({
    int? senderId,
    String? senderName,
    DateTime? sendDate,
    String? messageText,
  }) {
    return InspectionMessage(
      senderId: senderId ?? this.senderId,
      senderName: senderName ?? this.senderName,
      sendDate: sendDate ?? this.sendDate,
      messageText: messageText ?? this.messageText,
    );
  }
}
