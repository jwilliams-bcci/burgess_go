import 'package:burgess_go/core/models/inspection/submission_detail.dart';

class DefectsState {
  final Set<String> selectedDefectIds;
  final String? analyzingItemId;

  DefectsState({this.selectedDefectIds = const {}, this.analyzingItemId});

  DefectsState copyWith({
    Set<String>? selectedDefectIds,
    String? Function()? analyzingItemId,
  }) {
    return DefectsState(
      selectedDefectIds: selectedDefectIds ?? this.selectedDefectIds,
      analyzingItemId: analyzingItemId != null
          ? analyzingItemId()
          : this.analyzingItemId,
    );
  }
}

class CategoryGroup {
  final String categoryName;
  final List<SubmissionDetail> items;

  CategoryGroup({required this.categoryName, required this.items});
}

class DefectGroup {
  final int statusId;
  final String label;
  final List<CategoryGroup> categories;

  DefectGroup({
    required this.statusId,
    required this.label,
    required this.categories,
  });
}
