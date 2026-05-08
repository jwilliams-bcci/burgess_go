import 'package:burgess_go/features/auth/controllers/auth_controller.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:burgess_go/core/providers/service_providers.dart';
import 'package:burgess_go/core/models/common/lookup_item.dart';
import 'package:burgess_go/features/locations/models/create_location_request.dart';
import 'package:burgess_go/features/locations/states/add_location_state.dart';

// --- PROVIDER ---
final addLocationControllerProvider =
    NotifierProvider.autoDispose<AddLocationController, AddLocationState>(
      AddLocationController.new,
    );

// --- CONTROLLER ---
class AddLocationController extends Notifier<AddLocationState> {
  @override
  AddLocationState build() {
    // Fetch communities as soon as the controller initializes
    Future.microtask(_fetchCommunities);

    // Start in a busy state while the initial communities load
    return AddLocationState(isBusy: true);
  }

  Future<void> _fetchCommunities() async {
    try {
      final apiClient = ref.read(apiClientProvider);
      final response = await apiClient.get(
        '/v1/burgessgo/locations/communities',
      );

      final List<LookupItem> rawLoaded = (response as List)
          .map((json) => LookupItem.fromJson(json))
          .toList();

      final uniqueMap = <int, LookupItem>{};
      for (var item in rawLoaded) {
        uniqueMap[item.id] = item;
      }

      state = state.copyWith(
        communities: uniqueMap.values.toList(),
        isBusy: false,
      );
    } catch (e) {
      state = state.copyWith(
        isBusy: false,
        errorMessage: "Failed to load communities: $e",
      );
    }
  }

  Future<void> fetchStreetsForCommunity(int communityId) async {
    // Clear out any old streets/numbers and show the loading indicator for the street dropdown
    state = state.copyWith(
      isLoadingStreets: true,
      errorMessage: null,
      streets: [],
      streetNumbers: [],
    );

    try {
      final apiClient = ref.read(apiClientProvider);
      final response = await apiClient.get(
        '/v1/burgessgo/locations/communities/$communityId/streets',
      );

      final List<LookupItem> rawLoaded = (response as List)
          .map((json) => LookupItem.fromJson(json))
          .toList();

      // 🔥 FIX: Deduplicate streets by ID
      final uniqueMap = <int, LookupItem>{};
      for (var item in rawLoaded) {
        uniqueMap[item.id] = item;
      }

      state = state.copyWith(
        streets: uniqueMap.values.toList(),
        isLoadingStreets: false,
      );
    } catch (e) {
      state = state.copyWith(
        isLoadingStreets: false,
        errorMessage: "Failed to load streets: $e",
      );
    }
  }

  Future<void> fetchStreetNumbers(int communityId, int streetNameId) async {
    state = state.copyWith(
      isLoadingStreetNumbers: true,
      errorMessage: null,
      streetNumbers: [],
    );

    try {
      final apiClient = ref.read(apiClientProvider);
      final response = await apiClient.get(
        '/v1/burgessgo/locations/communities/$communityId/streets/$streetNameId/numbers',
      );

      // The API returns a simple array of strings: ["101", "102A", "103"]
      final List<String> rawLoaded = (response as List)
          .map((e) => e.toString())
          .toList();

      // 🔥 FIX: Deduplicate street numbers using a Set
      final List<String> uniqueNumbers = rawLoaded.toSet().toList();

      state = state.copyWith(
        streetNumbers: uniqueNumbers,
        isLoadingStreetNumbers: false,
      );
    } catch (e) {
      state = state.copyWith(
        isLoadingStreetNumbers: false,
        errorMessage: "Failed to load street numbers: $e",
      );
    }
  }

  Future<bool> createLocation(CreateLocationRequest request) async {
    state = state.copyWith(isBusy: true, errorMessage: null);

    final logger = ref.read(loggingServiceProvider);
    final apiClient = ref.read(apiClientProvider);

    try {
      logger.info("Submitting new location to API...");
      final response = await apiClient.post(
        '/v1/burgessgo/locations',
        request.toJson(),
      );

      final newLocationId = response['newLocationId'];
      logger.info("Successfully created location ID: $newLocationId");

      state = state.copyWith(isBusy: false);
      return true;
    } catch (e) {
      logger.error("Failed to create location", error: e);

      String cleanError = e.toString().replaceAll(
        RegExp(r'Exception: API Error \d+: '),
        '',
      );

      state = state.copyWith(isBusy: false, errorMessage: cleanError);
      return false; // Failed
    }
  }
}
