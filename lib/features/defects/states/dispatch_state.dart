import 'package:burgess_go/features/trade_contact/models/trade_contact.dart';
import 'package:burgess_go/features/defects/models/trade_punch_list_models.dart';

class DispatchState {
  final bool isInitialized;
  final List<TradeReviewItem> itemsToDispatch;
  final TradeContact? selectedTrade;
  final bool isSubmitting;
  final String searchQuery;

  DispatchState({
    this.isInitialized = false,
    this.itemsToDispatch = const [],
    this.selectedTrade,
    this.isSubmitting = false,
    this.searchQuery = '',
  });

  DispatchState copyWith({
    bool? isInitialized,
    List<TradeReviewItem>? itemsToDispatch,
    TradeContact? Function()? selectedTrade,
    bool? isSubmitting,
    String? searchQuery,
  }) {
    return DispatchState(
      isInitialized: isInitialized ?? this.isInitialized,
      itemsToDispatch: itemsToDispatch ?? this.itemsToDispatch,
      selectedTrade: selectedTrade != null
          ? selectedTrade()
          : this.selectedTrade,
      isSubmitting: isSubmitting ?? this.isSubmitting,
      searchQuery: searchQuery ?? this.searchQuery,
    );
  }
}
