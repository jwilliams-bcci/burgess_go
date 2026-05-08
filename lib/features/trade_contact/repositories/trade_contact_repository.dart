import 'package:burgess_go/features/trade_contact/models/trade_contact.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

final tradeContactRepositoryProvider = Provider<TradeContactRepository>((ref) {
  return TradeContactRepository(FirebaseFirestore.instance);
});

class TradeContactRepository {
  final FirebaseFirestore _db;

  TradeContactRepository(this._db);

  Stream<List<TradeContact>> watchContacts(int securityUserId) {
    return _db
        .collection('users')
        .doc(securityUserId.toString())
        .collection('contacts')
        .orderBy('name')
        .snapshots()
        .map((snapshot) {
          try {
            return snapshot.docs
                .map((doc) => TradeContact.fromFirestore(doc))
                .toList();
          } catch (e) {
            print("🚨 ERROR parsing TradeContact: $e");
            return <TradeContact>[];
          }
        });
  }

  Future<void> addContact(int securityUserId, TradeContact contact) async {
    final userDoc = _db.collection('users').doc(securityUserId.toString());

    // Ensure the parent doc exists so the subcollection doesn't float in the void
    await userDoc.set({
      'securityUserId': securityUserId,
      'lastUpdated': FieldValue.serverTimestamp(),
    }, SetOptions(merge: true));

    await userDoc.collection('contacts').add(contact.toFirestore());
  }
}
