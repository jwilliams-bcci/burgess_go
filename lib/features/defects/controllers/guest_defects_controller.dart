import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:image_picker/image_picker.dart';

import 'package:burgess_go/core/models/inspection/inspection.dart';
import 'package:burgess_go/core/models/inspection/submission_detail.dart';
import 'package:burgess_go/features/defects/states/defects_state.dart';
import 'package:burgess_go/features/defects/states/guest_defects_state.dart';

// --- PROVIDER ---
// 🔥 Dropped .family and upgraded to NotifierProvider!
final guestDefectsControllerProvider =
    NotifierProvider.autoDispose<GuestDefectsController, GuestDefectsState>(
      GuestDefectsController.new,
    );

// --- CONTROLLER ---
class GuestDefectsController extends Notifier<GuestDefectsState> {
  @override
  GuestDefectsState build() {
    return GuestDefectsState();
  }

  Future<void> loadSession(
    String inspectionIdStr,
    String listId,
    String urlToken,
  ) async {
    try {
      state = state.copyWith(isLoading: true);

      final inspectionId = int.tryParse(inspectionIdStr);
      if (inspectionId == null) throw "Invalid ID format";

      // 1. Fetch the Parent Inspection to get the Address for the UI
      final inspectionDoc = await FirebaseFirestore.instance
          .collection('inspections')
          .doc(inspectionId.toString())
          .get();

      if (!inspectionDoc.exists) throw "Inspection not found.";

      final inspection = Inspection.fromFirestore(inspectionDoc);

      // 2. Fetch the specific Trade Punch List
      final punchListDoc = await FirebaseFirestore.instance
          .collection('inspections')
          .doc(inspectionId.toString())
          .collection('tradePunchLists')
          .doc(listId)
          .get();

      if (!punchListDoc.exists) throw "Work order not found.";

      final data = punchListDoc.data()!;

      // 3. Verify the token matches THIS specific list
      if (data['guestToken'] != urlToken) {
        throw "Invalid or expired access token.";
      }

      final tradeName = data['tradeName'] ?? "Vendor";
      final List<dynamic> rawItems = data['items'] ?? [];
      List<SubmissionDetail> actualDetails = [];
      Map<String, bool> reqPhotos = {};
      Map<String, String> upPhotos = {};
      Set<String> completed = {};

      // 4. Fetch the full defect data
      for (var rawItem in rawItems) {
        final isCustom = rawItem['isCustom'] ?? false;
        final defectId = rawItem['defectId'];
        final description = rawItem['description'];

        reqPhotos[defectId] = rawItem['requirePhoto'] ?? false;
        if (rawItem['tradePhotoUrl'] != null) {
          upPhotos[defectId] = rawItem['tradePhotoUrl'];
        }

        if (rawItem['isCompleted'] == true) {
          completed.add(defectId);
        }

        if (isCustom) {
          // The "Lazy" Mock: Allows Custom items to seamlessly use the existing UI
          actualDetails.add(
            SubmissionDetail(
              id: defectId,
              detailItemId: 0,
              itemNumber: 0,
              itemDescription: description,
              defectCategory: "Custom Tasks",
              detailStatusId: 2,
            ),
          );
        } else {
          // It's a real defect, fetch it
          final doc = await FirebaseFirestore.instance
              .collection('inspections')
              .doc(inspectionId.toString())
              .collection('submissionDetails')
              .doc(defectId)
              .get();

          if (doc.exists) {
            actualDetails.add(SubmissionDetail.fromFirestore(doc));
          }
        }
      }

      final groups = _groupAndSort(actualDetails);

      state = GuestDefectsState(
        isLoading: false,
        isVerified: true,
        tradeName: tradeName,
        inspection: inspection,
        defectGroups: groups,
        requirePhotoMap: reqPhotos,
        uploadedPhotoMap: upPhotos,
        completedItems: completed,
      );
    } catch (e) {
      state = GuestDefectsState(
        isLoading: false,
        isVerified: false,
        errorMessage: e.toString(),
      );
    }
  }

  // Reuse sorting logic (NC -> C -> R -> NA)
  List<DefectGroup> _groupAndSort(List<SubmissionDetail> details) {
    final Map<int, String> statusLabels = {
      2: "Not Complete (NC)",
      3: "Complete (C)",
      6: "Repaired (R)",
      4: "Not Applicable (N/A)",
    };
    final List<int> statusOrder = [2, 3, 6, 4];

    final Map<int, List<SubmissionDetail>> statusBuckets = {};
    for (var item in details) {
      final sId = item.detailStatusId ?? 0;
      if (!statusBuckets.containsKey(sId)) statusBuckets[sId] = [];
      statusBuckets[sId]!.add(item);
    }

    List<DefectGroup> result = [];

    for (var sId in statusOrder) {
      if (statusBuckets.containsKey(sId) && statusBuckets[sId]!.isNotEmpty) {
        final rawItems = statusBuckets[sId]!;
        final categoryGroups = _groupByCategory(rawItems);

        result.add(
          DefectGroup(
            statusId: sId,
            label: statusLabels[sId] ?? "Status $sId",
            categories: categoryGroups,
          ),
        );
        statusBuckets.remove(sId);
      }
    }

    statusBuckets.forEach((sId, list) {
      result.add(
        DefectGroup(
          statusId: sId,
          label: "Other ($sId)",
          categories: _groupByCategory(list),
        ),
      );
    });

    return result;
  }

  List<CategoryGroup> _groupByCategory(List<SubmissionDetail> items) {
    final Map<String, List<SubmissionDetail>> catBuckets = {};

    for (var item in items) {
      final cat = item.defectCategory ?? "Uncategorized";
      if (!catBuckets.containsKey(cat)) catBuckets[cat] = [];
      catBuckets[cat]!.add(item);
    }

    final list = catBuckets.entries.map((e) {
      return CategoryGroup(categoryName: e.key, items: e.value);
    }).toList();

    list.sort((a, b) => a.categoryName.compareTo(b.categoryName));

    return list;
  }

  Future<void> uploadTradePhoto(
    String inspectionId,
    String listId,
    String defectId,
    XFile image,
  ) async {
    try {
      final fileName = "${DateTime.now().millisecondsSinceEpoch}.png";
      final storageRef = FirebaseStorage.instance.ref().child(
        "inspections/$inspectionId/tradeItems/$listId/$fileName",
      );

      final bytes = await image.readAsBytes();
      await storageRef.putData(
        bytes,
        SettableMetadata(contentType: 'image/png'),
      );
      final downloadUrl = await storageRef.getDownloadURL();

      final docRef = FirebaseFirestore.instance
          .collection('inspections')
          .doc(inspectionId)
          .collection('tradePunchLists')
          .doc(listId);
      final doc = await docRef.get();
      final items = List<Map<String, dynamic>>.from(doc.data()!['items']);
      final itemIndex = items.indexWhere((i) => i['defectId'] == defectId);

      if (itemIndex != -1) {
        final isCustom = items[itemIndex]['isCustom'] ?? false;
        items[itemIndex]['tradePhotoUrl'] = downloadUrl;
        items[itemIndex]['isCompleted'] = true;
        await docRef.update({'items': items});

        // Update the Super's Master Defect List
        if (!isCustom) {
          await FirebaseFirestore.instance
              .collection('inspections')
              .doc(inspectionId)
              .collection('submissionDetails')
              .doc(defectId)
              .update({
                'detailStatusId': 10, // Trade Corrected
                'tradePhotoUrl': downloadUrl,
              });
        }

        // Update UI
        final newUpPhotos = Map<String, String>.from(state.uploadedPhotoMap);
        final newCompleted = Set<String>.from(state.completedItems);
        newUpPhotos[defectId] = downloadUrl;
        newCompleted.add(defectId);

        state = state.copyWith(
          uploadedPhotoMap: newUpPhotos,
          completedItems: newCompleted,
        );
      }
    } catch (e) {
      print("Upload error: $e");
    }
  }

  Future<void> markItemComplete(
    String inspectionId,
    String listId,
    String defectId,
  ) async {
    try {
      final docRef = FirebaseFirestore.instance
          .collection('inspections')
          .doc(inspectionId)
          .collection('tradePunchLists')
          .doc(listId);
      final doc = await docRef.get();
      final items = List<Map<String, dynamic>>.from(doc.data()!['items']);
      final itemIndex = items.indexWhere((i) => i['defectId'] == defectId);

      if (itemIndex != -1) {
        final isCustom = items[itemIndex]['isCustom'] ?? false;
        items[itemIndex]['isCompleted'] = true;
        await docRef.update({'items': items});

        if (!isCustom) {
          await FirebaseFirestore.instance
              .collection('inspections')
              .doc(inspectionId)
              .collection('submissionDetails')
              .doc(defectId)
              .update({'detailStatusId': 10}); // Trade Corrected
        }

        final newCompleted = Set<String>.from(state.completedItems);
        newCompleted.add(defectId);
        state = state.copyWith(completedItems: newCompleted);
      }
    } catch (e) {
      print("Mark complete error: $e");
    }
  }
}
