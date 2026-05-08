import 'package:burgess_go/core/models/common/lookup_item.dart';

class AddLocationState {
  final bool isBusy;
  final bool isLoadingStreets;
  final bool isLoadingStreetNumbers;
  final List<LookupItem> communities;
  final List<LookupItem> streets;
  final List<String> streetNumbers;
  final String? errorMessage;

  AddLocationState({
    this.isBusy = false,
    this.isLoadingStreets = false,
    this.isLoadingStreetNumbers = false,
    this.communities = const [],
    this.streets = const [],
    this.streetNumbers = const [],
    this.errorMessage,
  });

  AddLocationState copyWith({
    bool? isBusy,
    bool? isLoadingStreets,
    bool? isLoadingStreetNumbers,
    List<LookupItem>? communities,
    List<LookupItem>? streets,
    List<String>? streetNumbers,
    String? errorMessage,
  }) {
    return AddLocationState(
      isBusy: isBusy ?? this.isBusy,
      isLoadingStreets: isLoadingStreets ?? this.isLoadingStreets,
      isLoadingStreetNumbers:
          isLoadingStreetNumbers ?? this.isLoadingStreetNumbers,
      communities: communities ?? this.communities,
      streets: streets ?? this.streets,
      streetNumbers: streetNumbers ?? this.streetNumbers,
      errorMessage: errorMessage,
    );
  }
}
