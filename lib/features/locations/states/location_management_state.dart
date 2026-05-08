class LocationManagementState {
  final bool isBusy;
  final String? errorMessage;

  LocationManagementState({this.isBusy = false, this.errorMessage});

  LocationManagementState copyWith({bool? isBusy, String? errorMessage}) {
    return LocationManagementState(
      isBusy: isBusy ?? this.isBusy,
      errorMessage: errorMessage, // Nullable override
    );
  }
}
