import 'dart:async';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:burgess_go/core/models/location/location.dart';
import 'package:burgess_go/features/auth/controllers/auth_controller.dart';
import 'package:burgess_go/features/locations/repositories/location_repository.dart';

// --- PROVIDER ---
final locationListControllerProvider =
    NotifierProvider.autoDispose<
      LocationListController,
      AsyncValue<List<Location>>
    >(LocationListController.new);

// --- CONTROLLER ---
class LocationListController extends Notifier<AsyncValue<List<Location>>> {
  StreamSubscription? _sub;

  @override
  AsyncValue<List<Location>> build() {
    // Automatically cancel the stream when we navigate away from the list screen
    ref.onDispose(() => _sub?.cancel());

    final user = ref.watch(authControllerProvider).user;
    if (user == null) {
      return const AsyncValue.data([]);
    }

    final repo = ref.read(locationRepositoryProvider);

    // Clear any old subscription before making a new one
    _sub?.cancel();

    _sub = repo
        .watchLocationsForUser(user)
        .listen(
          (locations) {
            state = AsyncValue.data(locations);
          },
          onError: (err, stack) {
            state = AsyncValue.error(err, stack);
          },
        );

    return const AsyncValue.loading();
  }

  void _fetchLocations() {
    final user = ref.read(authControllerProvider).user;
    if (user == null) {
      state = const AsyncValue.data([]);
      return;
    }

    final repo = ref.read(locationRepositoryProvider);
    _sub = repo
        .watchLocationsForUser(user)
        .listen(
          (locations) {
            state = AsyncValue.data(locations);
          },
          onError: (err, stack) {
            state = AsyncValue.error(err, stack);
          },
        );
  }
}
