import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';

import 'package:burgess_go/features/defects/states/defects_state.dart';
import 'package:burgess_go/features/defects/states/guest_defects_state.dart';
import 'package:burgess_go/core/models/inspection/submission_detail.dart';
import 'package:burgess_go/services/ai_service.dart';
import '../controllers/guest_defects_controller.dart';

class GuestDefectsScreen extends ConsumerStatefulWidget {
  final String inspectionId;
  final String listId;
  final String token;

  const GuestDefectsScreen({
    super.key,
    required this.inspectionId,
    required this.listId,
    required this.token,
  });

  @override
  ConsumerState<GuestDefectsScreen> createState() => _GuestDefectsScreenState();
}

class _GuestDefectsScreenState extends ConsumerState<GuestDefectsScreen> {
  final AIService _aiService = AIService();
  String? _analyzingItemId;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref
          .read(guestDefectsControllerProvider.notifier)
          .loadSession(widget.inspectionId, widget.listId, widget.token);
    });
  }

  Future<void> _analyzeDefect(SubmissionDetail detail) async {
    setState(() => _analyzingItemId = detail.id);

    try {
      final explanation = await _aiService.explainDefect(
        detail.defectCategory ?? "General",
        detail.itemDescription ?? "Unknown defect",
      );

      if (mounted) _showAIResultDialog(detail, explanation);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text("AI Error: $e")));
      }
    } finally {
      if (mounted) setState(() => _analyzingItemId = null);
    }
  }

  void _showAIResultDialog(SubmissionDetail detail, String explanation) {
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
        content: SingleChildScrollView(
          child: Column(
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

  void _showDefectPhoto(String url) {
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

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(guestDefectsControllerProvider);

    if (state.isLoading) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    if (!state.isVerified) {
      return Scaffold(
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.lock_person, size: 64, color: Colors.red),
              const SizedBox(height: 16),
              Text(
                state.errorMessage ?? "Access Denied",
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
        ),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: Text(state.inspection?.address ?? "Inspection Items"),
        backgroundColor: Colors.teal[800],
        foregroundColor: Colors.white,
      ),
      body: ListView.builder(
        padding: const EdgeInsets.only(bottom: 40),
        itemCount: state.defectGroups.length,
        itemBuilder: (context, index) {
          return _buildStatusSection(state.defectGroups[index], state);
        },
      ),
    );
  }

  Widget _buildStatusSection(DefectGroup group, GuestDefectsState state) {
    Color headerColor;
    switch (group.statusId) {
      case 2:
        headerColor = Colors.red[100]!;
        break;
      case 3:
        headerColor = Colors.green[100]!;
        break;
      case 6:
        headerColor = Colors.blue[100]!;
        break;
      case 4:
        headerColor = Colors.grey[300]!;
        break;
      default:
        headerColor = Colors.grey[200]!;
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          color: headerColor,
          child: Text(
            group.label.toUpperCase(),
            style: const TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 16,
              letterSpacing: 1.2,
            ),
          ),
        ),
        ...group.categories.map((catGroup) {
          return Column(
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
                (detail) => _buildDetailTile(detail, state),
              ),
            ],
          );
        }),
      ],
    );
  }

  Widget _buildDetailTile(SubmissionDetail detail, GuestDefectsState state) {
    final isNC = detail.detailStatusId == 2;

    return Container(
      decoration: BoxDecoration(
        border: Border(bottom: BorderSide(color: Colors.grey[200]!)),
        color: Colors.white,
      ),
      padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.only(top: 6, right: 12),
            child: Icon(Icons.circle, size: 10, color: Colors.grey[400]),
          ),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (detail.defectCategory != null)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 4),
                    child: Text(
                      detail.defectCategory!.toUpperCase(),
                      style: TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                        color: Colors.blue[800],
                      ),
                    ),
                  ),
                Text(
                  detail.itemDescription ?? 'No Description',
                  style: const TextStyle(fontWeight: FontWeight.w500),
                ),
                if (detail.comment != null && detail.comment!.isNotEmpty)
                  Padding(
                    padding: const EdgeInsets.only(top: 4.0),
                    child: Text(
                      "Note: ${detail.comment}",
                      style: TextStyle(color: Colors.grey[600], fontSize: 13),
                    ),
                  ),
              ],
            ),
          ),
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (detail.fileLink != null && detail.fileLink!.isNotEmpty)
                IconButton(
                  icon: const Icon(
                    Icons.photo_camera_outlined,
                    color: Colors.blue,
                  ),
                  onPressed: () => _showDefectPhoto(detail.fileLink!),
                ),

              // --- AI ROBOT ICON ---
              if (isNC)
                Padding(
                  padding: const EdgeInsets.only(left: 8),
                  child: _analyzingItemId == detail.id
                      ? const SizedBox(
                          width: 24,
                          height: 24,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: Colors.purple,
                          ),
                        )
                      : IconButton(
                          icon: Icon(
                            Icons.smart_toy_outlined,
                            color: Colors.purple[400],
                          ),
                          tooltip: "Explain Code Violation",
                          onPressed: () => _analyzeDefect(detail),
                          style: IconButton.styleFrom(
                            backgroundColor: Colors.purple.withOpacity(0.05),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(8),
                            ),
                          ),
                        ),
                ),

              const SizedBox(width: 8),

              // --- TRADE COMPLETION LOGIC ---
              if (state.completedItems.contains(detail.id))
                InkWell(
                  onTap: state.uploadedPhotoMap.containsKey(detail.id)
                      ? () =>
                            _showDefectPhoto(state.uploadedPhotoMap[detail.id]!)
                      : null,
                  child: Container(
                    padding: const EdgeInsets.all(4),
                    decoration: BoxDecoration(
                      color: Colors.green[50],
                      border: Border.all(color: Colors.green),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Row(
                      children: [
                        const Icon(
                          Icons.check_circle,
                          color: Colors.green,
                          size: 16,
                        ),
                        const SizedBox(width: 4),
                        const Text(
                          "Completed",
                          style: TextStyle(
                            color: Colors.green,
                            fontSize: 10,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        if (state.uploadedPhotoMap.containsKey(detail.id))
                          const Padding(
                            padding: EdgeInsets.only(left: 4.0),
                            child: Icon(
                              Icons.photo_camera,
                              color: Colors.green,
                              size: 12,
                            ),
                          ),
                      ],
                    ),
                  ),
                )
              else
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    if (state.requirePhotoMap[detail.id] != true)
                      IconButton(
                        icon: const Icon(
                          Icons.check_circle_outline,
                          color: Colors.green,
                        ),
                        tooltip: "Mark Complete",
                        onPressed: () {
                          if (detail.id != null) {
                            ref
                                .read(guestDefectsControllerProvider.notifier)
                                .markItemComplete(
                                  widget.inspectionId,
                                  widget.listId,
                                  detail.id!,
                                );
                          }
                        },
                      ),
                    Column(
                      children: [
                        IconButton(
                          icon: const Icon(
                            Icons.add_a_photo,
                            color: Colors.blue,
                          ),
                          onPressed: () async {
                            final picker = ImagePicker();
                            final image = await picker.pickImage(
                              source: ImageSource.camera,
                              imageQuality: 70,
                            );
                            if (image != null && detail.id != null) {
                              ref
                                  .read(guestDefectsControllerProvider.notifier)
                                  .uploadTradePhoto(
                                    widget.inspectionId,
                                    widget.listId,
                                    detail.id!,
                                    image,
                                  );
                            }
                          },
                        ),
                        if (state.requirePhotoMap[detail.id] == true)
                          const Text(
                            "Required",
                            style: TextStyle(
                              color: Colors.red,
                              fontSize: 9,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                      ],
                    ),
                  ],
                ),
            ],
          ),
        ],
      ),
    );
  }
}
