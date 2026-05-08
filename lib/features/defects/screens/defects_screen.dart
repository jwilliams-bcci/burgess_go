import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:burgess_go/features/defects/screens/dispatch_screen.dart'; // We'll refactor this next!
import 'package:burgess_go/features/defects/states/defects_state.dart';
import 'package:burgess_go/core/models/inspection/submission_detail.dart';
import '../controllers/defects_controller.dart';
import 'package:burgess_go/core/widgets/sign_off_dialog.dart'; // Adjust path as needed

class DefectsScreen extends ConsumerWidget {
  final int inspectionId;

  const DefectsScreen({super.key, required this.inspectionId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // 1. Watch the data stream
    final groupsAsync = ref.watch(defectGroupsProvider(inspectionId));
    // 2. Watch the UI Controller
    final state = ref.watch(defectsControllerProvider);
    final controller = ref.read(defectsControllerProvider.notifier);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Inspection Defects'),
        backgroundColor: Colors.blue[900],
        foregroundColor: Colors.white,
        actions: [
          // Only show SEND button if we have selections and the data successfully loaded
          if (state.selectedDefectIds.isNotEmpty)
            groupsAsync.maybeWhen(
              data: (groups) => TextButton.icon(
                onPressed: () {
                  final selectedItems = groups
                      .expand((g) => g.categories.expand((c) => c.items))
                      .where(
                        (item) => state.selectedDefectIds.contains(item.id),
                      )
                      .toList();

                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => DispatchScreen(
                        inspectionId: inspectionId,
                        selectedDetails: selectedItems,
                      ),
                    ),
                  );
                },
                icon: const Icon(Icons.send, color: Colors.white),
                label: Text(
                  "SEND (${state.selectedDefectIds.length})",
                  style: const TextStyle(color: Colors.white),
                ),
              ),
              orElse: () => const SizedBox.shrink(),
            ),
        ],
      ),
      body: groupsAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (err, stack) => Center(child: Text("Error: $err")),
        data: (groups) {
          if (groups.isEmpty) {
            return const Center(child: Text("No defects found."));
          }

          return ListView.builder(
            padding: const EdgeInsets.only(bottom: 24),
            itemCount: groups.length,
            itemBuilder: (context, index) {
              return _buildStatusSection(
                context,
                ref,
                groups[index],
                state,
                controller,
              );
            },
          );
        },
      ),
    );
  }

  Widget _buildStatusSection(
    BuildContext context,
    WidgetRef ref,
    DefectGroup group,
    DefectsState state,
    DefectsController controller,
  ) {
    Color headerColor = _getHeaderColor(group.statusId);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          color: headerColor,
          child: Text(
            group.label.toUpperCase(),
            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
          ),
        ),
        ...group.categories.map(
          (catGroup) => Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 6,
                ),
                color: Colors.grey[50],
                child: Text(
                  catGroup.categoryName.toUpperCase(),
                  style: TextStyle(
                    color: Colors.blue[800],
                    fontWeight: FontWeight.w700,
                    fontSize: 12,
                  ),
                ),
              ),
              ...catGroup.items.map(
                (detail) =>
                    _buildDetailTile(context, ref, detail, state, controller),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildDetailTile(
    BuildContext context,
    WidgetRef ref,
    SubmissionDetail detail,
    DefectsState state,
    DefectsController controller,
  ) {
    final isSelected = state.selectedDefectIds.contains(detail.id);
    final isAnalyzing = state.analyzingItemId == detail.id;
    final bool isSent = detail.sentToTrade ?? false;

    return Container(
      decoration: BoxDecoration(
        border: Border(bottom: BorderSide(color: Colors.grey[200]!)),
        color: Colors.white,
      ),
      padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
      child: Row(
        children: [
          isSent
              ? const Padding(
                  padding: EdgeInsets.symmetric(horizontal: 12),
                  child: Icon(Icons.check_circle, color: Colors.blue, size: 24),
                )
              : Checkbox(
                  value: isSelected,
                  onChanged: (_) => controller.toggleSelection(detail.id!),
                ),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  detail.itemDescription,
                  style: TextStyle(
                    fontWeight: FontWeight.w500,
                    color: isSent ? Colors.grey : Colors.black,
                  ),
                ),
                if (detail.comment != null)
                  Text(
                    detail.comment!,
                    style: TextStyle(color: Colors.grey[600], fontSize: 13),
                  ),
              ],
            ),
          ),
          if (detail.fileLink != null && detail.fileLink!.isNotEmpty)
            IconButton(
              icon: const Icon(Icons.image_outlined, color: Colors.blue),
              onPressed: () => _showDefectPhoto(context, detail.fileLink!),
              tooltip: "View Photo",
            ),
          if (detail.tradePhotoUrl != null && detail.tradePhotoUrl!.isNotEmpty)
            IconButton(
              icon: const Icon(Icons.how_to_reg, color: Colors.teal),
              onPressed: () => _showDefectPhoto(context, detail.tradePhotoUrl!),
              tooltip: "View Trade's Proof Photo",
            ),
          if (detail.detailStatusId == 2)
            isAnalyzing
                ? const SizedBox(
                    width: 24,
                    height: 24,
                    child: Padding(
                      padding: EdgeInsets.all(4.0),
                      child: CircularProgressIndicator(strokeWidth: 2),
                    ),
                  )
                : IconButton(
                    icon: const Icon(
                      Icons.smart_toy_outlined,
                      color: Colors.purple,
                    ),
                    onPressed: () => controller.analyzeDefect(context, detail),
                  ),
          IconButton(
            icon: const Icon(Icons.edit_document, color: Colors.red),
            onPressed: () =>
                _showSignOffDialog(context, ref, controller, detail),
          ),
        ],
      ),
    );
  }

  void _showSignOffDialog(
    BuildContext context,
    WidgetRef ref,
    DefectsController controller,
    SubmissionDetail detail,
  ) {
    showDialog(
      context: context,
      builder: (_) => SignOffDialog(
        onSubmit: (bytes, photo) =>
            controller.markAsRepaired(inspectionId, detail.id!),
      ),
    );
  }

  void _showDefectPhoto(BuildContext context, String url) {
    showDialog(
      context: context,
      builder: (_) => Dialog(
        backgroundColor: Colors.transparent,
        child: ClipRRect(
          borderRadius: BorderRadius.circular(12),
          child: Image.network(url, fit: BoxFit.contain),
        ),
      ),
    );
  }

  Color _getHeaderColor(int statusId) {
    switch (statusId) {
      case 2:
        return Colors.red[100]!;
      case 10:
        return Colors.teal[100]!;
      case 3:
        return Colors.green[100]!;
      case 6:
        return Colors.blue[100]!;
      default:
        return Colors.grey[200]!;
    }
  }
}
