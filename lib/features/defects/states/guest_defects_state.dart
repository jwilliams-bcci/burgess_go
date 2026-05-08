import 'package:burgess_go/core/models/inspection/inspection.dart';
import 'package:burgess_go/features/defects/states/defects_state.dart';

class GuestDefectsState {
  final bool isLoading;
  final bool isVerified;
  final String? errorMessage;
  final String? tradeName;
  final Inspection? inspection;
  final List<DefectGroup> defectGroups;
  final Map<String, bool> requirePhotoMap;
  final Map<String, String> uploadedPhotoMap;
  final Set<String> completedItems;

  GuestDefectsState({
    this.isLoading = true,
    this.isVerified = false,
    this.errorMessage,
    this.tradeName,
    this.inspection,
    this.defectGroups = const [],
    this.requirePhotoMap = const {},
    this.uploadedPhotoMap = const {},
    this.completedItems = const {},
  });

  GuestDefectsState copyWith({
    bool? isLoading,
    bool? isVerified,
    String? errorMessage,
    String? tradeName,
    Inspection? inspection,
    List<DefectGroup>? defectGroups,
    Map<String, bool>? requirePhotoMap,
    Map<String, String>? uploadedPhotoMap,
    Set<String>? completedItems,
  }) {
    return GuestDefectsState(
      isLoading: isLoading ?? this.isLoading,
      isVerified: isVerified ?? this.isVerified,
      errorMessage: errorMessage ?? this.errorMessage,
      tradeName: tradeName ?? this.tradeName,
      inspection: inspection ?? this.inspection,
      defectGroups: defectGroups ?? this.defectGroups,
      requirePhotoMap: requirePhotoMap ?? this.requirePhotoMap,
      uploadedPhotoMap: uploadedPhotoMap ?? this.uploadedPhotoMap,
      completedItems: completedItems ?? this.completedItems,
    );
  }
}
