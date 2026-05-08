import 'package:burgess_go/core/models/inspection/inspection_message.dart';
import 'package:burgess_go/features/auth/controllers/auth_controller.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

// 1. The Real-Time Stream Provider
final inspectionMessagesStreamProvider =
    StreamProvider.family<List<InspectionMessage>, int>((ref, inspectionId) {
      return FirebaseFirestore.instance
          .collection('inspections')
          .doc(inspectionId.toString())
          .snapshots()
          .map((snapshot) {
            if (!snapshot.exists || snapshot.data() == null) return [];

            final data = snapshot.data() as Map<String, dynamic>;

            // 🚨 Make sure this key exactly matches what your C# model serializes!
            final rawMessages =
                data['inspectionMessages'] as List<dynamic>? ?? [];

            final messages = rawMessages
                .map(
                  (item) =>
                      InspectionMessage.fromMap(item as Map<String, dynamic>),
                )
                .toList();

            // Sort descending (newest at index 0) for the reverse ListView
            messages.sort((a, b) {
              final dateA =
                  a.sendDate ?? DateTime.fromMillisecondsSinceEpoch(0);
              final dateB =
                  b.sendDate ?? DateTime.fromMillisecondsSinceEpoch(0);
              return dateB.compareTo(dateA);
            });

            return messages;
          });
    });

// 2. The Write Controller
final inspectionMessagesControllerProvider = Provider(
  (ref) => InspectionMessagesController(ref),
);

class InspectionMessagesController {
  final Ref ref;
  InspectionMessagesController(this.ref);

  Future<void> sendMessage(int inspectionId, String text) async {
    if (text.trim().isEmpty) return;

    final user = ref.read(authControllerProvider).user;
    if (user == null) return;

    final newMessage = InspectionMessage(
      senderId: user.securityUserId,
      senderName: user.email, // Adjust if you have a specific name field
      messageText: text.trim(),
      sendDate: DateTime.now(), // Local optimistic timestamp
    );

    // 🚨 The Magic Fat Document Write!
    await FirebaseFirestore.instance
        .collection('inspections')
        .doc(inspectionId.toString())
        .update({
          'inspectionMessages': FieldValue.arrayUnion([
            newMessage.toFirestoreMap(),
          ]),
        });
  }
}
