import 'package:cloud_firestore/cloud_firestore.dart';

class TradeContact {
  final String? id;
  final String name;
  final String trade;
  final String? phone;
  final String? email;
  final int ownerId; // The securityUserId of the Superintendent

  TradeContact({
    this.id,
    required this.name,
    required this.trade,
    this.phone,
    this.email,
    required this.ownerId,
  });

  Map<String, dynamic> toFirestore() {
    return {
      'name': name,
      'trade': trade,
      'phone': phone,
      'email': email,
      'ownerId': ownerId,
      'updatedAt': FieldValue.serverTimestamp(),
    };
  }

  factory TradeContact.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return TradeContact(
      id: doc.id,
      name: data['name'] ?? '',
      trade: data['trade'] ?? '',
      phone: data['phone'],
      email: data['email'],
      ownerId: data['ownerId'] ?? 0,
    );
  }
}
