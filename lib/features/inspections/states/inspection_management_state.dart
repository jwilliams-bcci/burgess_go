class InspectionManagementState {
  final bool isLoading;
  final String? errorMessage;

  InspectionManagementState({this.isLoading = false, this.errorMessage});

  InspectionManagementState copyWith({bool? isLoading, String? errorMessage}) {
    return InspectionManagementState(
      isLoading: isLoading ?? this.isLoading,
      errorMessage: errorMessage, // Nullable override
    );
  }
}
