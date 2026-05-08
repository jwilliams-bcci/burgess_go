import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:burgess_go/core/providers/service_providers.dart';
import 'package:burgess_go/core/models/inspection/submission_detail.dart';
import 'package:burgess_go/features/defects/states/defects_state.dart';
import 'package:burgess_go/services/firestore_service.dart';

// --- DATA PROVIDERS ---
final defectsStreamProvider = StreamProvider.autoDispose
    .family<List<SubmissionDetail>, int>((ref, inspectionId) {
      final firestoreService = FirestoreService();
      return firestoreService.getDefectsStream(inspectionId);
    });

final defectGroupsProvider = Provider.autoDispose
    .family<AsyncValue<List<DefectGroup>>, int>((ref, inspectionId) {
      // Watch the raw stream
      final detailsAsync = ref.watch(defectsStreamProvider(inspectionId));

      // Only process the grouping logic when data actually arrives!
      return detailsAsync.whenData((details) {
        return _groupAndSort(details);
      });
    });

// --- UI CONTROLLER ---
final defectsControllerProvider =
    NotifierProvider.autoDispose<DefectsController, DefectsState>(
      DefectsController.new,
    );

class DefectsController extends Notifier<DefectsState> {
  final FirestoreService _firestoreService = FirestoreService();

  @override
  DefectsState build() {
    return DefectsState();
  }

  void toggleSelection(String defectId) {
    final newSelection = Set<String>.from(state.selectedDefectIds);
    if (newSelection.contains(defectId)) {
      newSelection.remove(defectId);
    } else {
      newSelection.add(defectId);
    }
    state = state.copyWith(selectedDefectIds: newSelection);
  }

  Future<void> analyzeDefect(
    BuildContext context,
    SubmissionDetail detail,
  ) async {
    // Set loading state for this specific item
    state = state.copyWith(analyzingItemId: () => detail.id);

    try {
      final aiService = ref.read(aiServiceProvider);
      final explanation = await aiService.explainDefect(
        detail.defectCategory ?? "General",
        detail.itemDescription,
      );

      if (context.mounted) {
        _showAIResultDialog(context, detail, explanation);
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text("AI Error: $e")));
      }
    } finally {
      // Clear loading state
      state = state.copyWith(analyzingItemId: () => null);
    }
  }

  Future<void> markAsRepaired(int inspectionId, String defectId) async {
    try {
      await _firestoreService.updateDefectStatus(inspectionId, defectId, 6);
      // Because we use a StreamProvider, the UI will instantly auto-refresh!
    } catch (e) {
      print("Error updating defect: $e");
    }
  }

  void _showAIResultDialog(
    BuildContext context,
    SubmissionDetail detail,
    String explanation,
  ) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: Row(
          children: [
            Icon(Icons.smart_toy, color: Colors.purple[400]),
            const SizedBox(width: 8),
            const Text("Code Assistant"),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              "Defect: ${detail.itemDescription}",
              style: const TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 13,
                color: Colors.grey,
              ),
            ),
            const Divider(),
            const SizedBox(height: 8),
            Text(
              explanation,
              style: const TextStyle(fontSize: 15, height: 1.4),
            ),
            const SizedBox(height: 12),
            const Text(
              "Always verify with official code documentation.",
              style: TextStyle(
                fontSize: 11,
                color: Colors.grey,
                fontStyle: FontStyle.italic,
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text("Close"),
          ),
        ],
      ),
    );
  }

  void clearSelection() {
    state = state.copyWith(selectedDefectIds: {});
  }
}

// --- PURE HELPER LOGIC ---
List<DefectGroup> _groupAndSort(List<SubmissionDetail> details) {
  final Map<int, String> statusLabels = {
    2: "Not Complete (NC)",
    10: "Trade Corrected",
    3: "Complete (C)",
    6: "Repaired (R)",
    4: "Not Applicable (N/A)",
  };
  final List<int> statusOrder = [2, 10, 3, 6, 4];

  final Map<int, List<SubmissionDetail>> statusBuckets = {};
  for (var item in details) {
    final sId = item.detailStatusId ?? 0;
    if (!statusBuckets.containsKey(sId)) statusBuckets[sId] = [];
    statusBuckets[sId]!.add(item);
  }

  List<DefectGroup> result = [];

  for (var sId in statusOrder) {
    if (statusBuckets.containsKey(sId) && statusBuckets[sId]!.isNotEmpty) {
      final categoryGroups = _groupByCategory(statusBuckets[sId]!);
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
