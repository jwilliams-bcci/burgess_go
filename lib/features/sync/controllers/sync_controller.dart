import 'dart:async';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:burgess_go/core/providers/service_providers.dart';

// --- PROVIDER ---
final syncControllerProvider =
    AsyncNotifierProvider.autoDispose<SyncController, void>(SyncController.new);

// --- CONTROLLER ---
class SyncController extends AsyncNotifier<void> {
  @override
  FutureOr<void> build() {
    // We don't need to do anything on boot.
    // The state starts as AsyncData(null) automatically.
  }

  Future<void> performInitialSync() async {
    final service = ref.read(syncServiceProvider);
    final logger = ref.read(loggingServiceProvider);

    logger.info('🚀 Starting Initial Sync Sequence...');

    // Set state to loading so the UI can show a spinner
    state = const AsyncLoading();

    // AsyncValue.guard automatically wraps the try/catch block!
    state = await AsyncValue.guard(() async {
      await service.syncLocations();
      await service.syncHeaders();
      logger.info('✅ Initial Sync Successful.');
    });

    if (state.hasError) {
      logger.error('❌ Initial Sync Failed: ${state.error}');
    }
  }

  Future<void> syncLocationHistory(int locationId) async {
    final service = ref.read(syncServiceProvider);
    final logger = ref.read(loggingServiceProvider);

    state = const AsyncLoading();

    state = await AsyncValue.guard(() async {
      await service.syncLocationDetails(locationId);
      logger.info('✅ Location $locationId Sync Successful.');
    });

    if (state.hasError) {
      logger.error('❌ Location Sync Failed: ${state.error}');
    }
  }
}
