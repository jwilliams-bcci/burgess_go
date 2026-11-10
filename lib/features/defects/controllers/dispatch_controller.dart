import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:go_router/go_router.dart';
import 'package:url_launcher/url_launcher.dart'; // 🔥 Re-added for native app launching
import 'package:uuid/uuid.dart';

import 'package:burgess_go/features/trade_contact/models/trade_contact.dart';
import 'package:burgess_go/features/defects/states/dispatch_state.dart';
import 'package:burgess_go/features/defects/models/trade_punch_list_models.dart';
import 'package:burgess_go/core/models/inspection/submission_detail.dart';
import 'package:burgess_go/features/defects/controllers/defects_controller.dart';

final dispatchControllerProvider =
    NotifierProvider.autoDispose<DispatchController, DispatchState>(
      DispatchController.new,
    );

class DispatchController extends Notifier<DispatchState> {
  @override
  DispatchState build() {
    return DispatchState();
  }

  void init(List<SubmissionDetail> selectedDetails) {
    if (!state.isInitialized) {
      state = state.copyWith(
        isInitialized: true,
        itemsToDispatch: selectedDetails
            .map(
              (d) => TradeReviewItem(
                defectId: d.id,
                description: d.itemDescription,
              ),
            )
            .toList(),
      );
    }
  }

  void selectTrade(TradeContact? contact) {
    state = state.copyWith(selectedTrade: () => contact);
  }

  void togglePhotoRequirement(String defectId) {
    state = state.copyWith(
      itemsToDispatch: [
        for (final item in state.itemsToDispatch)
          if (item.defectId == defectId)
            TradeReviewItem(
              defectId: item.defectId,
              description: item.description,
              requirePhoto: !item.requirePhoto,
              isCustom: item.isCustom,
            )
          else
            item,
      ],
    );
  }

  void addCustomItem(String description) {
    final newItem = TradeReviewItem(
      defectId: 'custom_${DateTime.now().millisecondsSinceEpoch}',
      description: description,
      isCustom: true,
      requirePhoto: false,
    );
    state = state.copyWith(
      itemsToDispatch: [...state.itemsToDispatch, newItem],
    );
  }

  void removeItem(String defectId) {
    state = state.copyWith(
      itemsToDispatch: state.itemsToDispatch
          .where((i) => i.defectId != defectId)
          .toList(),
    );
  }

  Future<void> sendToTrade(
    int inspectionId,
    BuildContext context, {
    required String method,
  }) async {
    if (state.selectedTrade == null || state.itemsToDispatch.isEmpty) return;

    state = state.copyWith(isSubmitting: true);

    try {
      final batch = FirebaseFirestore.instance.batch();
      final punchListRef = FirebaseFirestore.instance
          .collection('inspections')
          .doc(inspectionId.toString())
          .collection('tradePunchLists')
          .doc();

      final token = const Uuid().v4();

      // 🔥 THE FIX: Explicitly inject the '/#/' to bypass web server 404s!
      String baseUrl = kIsWeb
          ? "${Uri.base.origin}/#"
          : "https://go.burgess-inc.com/#";

      final shareUrl =
          "$baseUrl/guest?inspectionId=$inspectionId&listId=${punchListRef.id}&token=$token";

      // 1. Write the payload to Firestore
      batch.set(punchListRef, {
        'tradeName': state.selectedTrade!.name,
        'tradeContactId': state.selectedTrade!.id,
        'tradeEmail': state.selectedTrade!.email,
        'sentAt': FieldValue.serverTimestamp(),
        'status': 'Sent',
        'guestToken': token,
        'shareUrl': shareUrl,
        'items': state.itemsToDispatch.map((i) => i.toMap()).toList(),
      });

      for (var item in state.itemsToDispatch) {
        if (!item.isCustom) {
          final defectRef = FirebaseFirestore.instance
              .collection('inspections')
              .doc(inspectionId.toString())
              .collection('submissionDetails')
              .doc(item.defectId);

          batch.update(defectRef, {'sentToTrade': true});
        }
      }

      // 2. Commit to Firestore
      await batch.commit();

      // 3. Always copy to clipboard as a bulletproof backup
      await Clipboard.setData(ClipboardData(text: shareUrl));

      // 4. Generate the custom message payload
      final String messageBody =
          "Hello ${state.selectedTrade!.name},\n\nHere is your requested punch list for inspection #$inspectionId.\n\nView and update items here: $shareUrl";

      // 5. Launch the Native App based on user choice
      if (method == 'sms' && state.selectedTrade!.phone != null) {
        // Build Uri safely to handle spaces and special characters for OS parsers
        final Uri smsUri = Uri(
          scheme: 'sms',
          path: state.selectedTrade!.phone,
          queryParameters: <String, String>{'body': messageBody},
        );
        // Bypass canLaunchUrl to avoid Android 11+ Package Visibility query restrictions
        await launchUrl(smsUri, mode: LaunchMode.externalApplication);
      } else if (method == 'email' && state.selectedTrade!.email != null) {
        final Uri emailUri = Uri(
          scheme: 'mailto',
          path: state.selectedTrade!.email,
          queryParameters: <String, String>{
            'subject': 'Punch List for Inspection #$inspectionId',
            'body': messageBody,
          },
        );
        await launchUrl(emailUri, mode: LaunchMode.externalApplication);
      }

      if (context.mounted) {
        // 🔥 WIPE IT OUT: Safely clear out the checkboxes from the previous screen
        ref.read(defectsControllerProvider.notifier).clearSelection();

        // 🔥 POP: Instantly removes this Dispatch screen from the stack!
        context.pop();

        String successMessage = "Link Copied to Clipboard!";
        if (method == 'sms')
          successMessage = "Text message opened & Link Copied!";
        if (method == 'email') successMessage = "Email opened & Link Copied!";

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(successMessage),
            backgroundColor: Colors.green[700],
            duration: const Duration(seconds: 4),
          ),
        );
      }
    } catch (e) {
      debugPrint("Dispatch Error: $e");
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text("Failed to send list: $e"),
            backgroundColor: Colors.red[700],
          ),
        );
      }
    } finally {
      state = state.copyWith(isSubmitting: false);
    }
  }
}
