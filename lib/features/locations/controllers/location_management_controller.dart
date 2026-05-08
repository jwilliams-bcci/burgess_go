import 'package:burgess_go/core/providers/service_providers.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:burgess_go/core/models/location/location.dart';
import 'package:burgess_go/features/locations/states/location_management_state.dart';
import 'package:burgess_go/features/inspections/models/schedule_inspection_request.dart';

final locationManagementControllerProvider =
    NotifierProvider.autoDispose<
      LocationManagementController,
      LocationManagementState
    >(LocationManagementController.new);

class LocationManagementController extends Notifier<LocationManagementState> {
  @override
  LocationManagementState build() {
    return LocationManagementState();
  }

  Future<void> scheduleInspection({
    required Location location,
    required int inspectionTypeId,
    required DateTime date,
    String? notes,
  }) async {
    state = state.copyWith(isBusy: true, errorMessage: null);
    final logger = ref.read(loggingServiceProvider);

    try {
      final apiClient = ref.read(apiClientProvider);

      final request = ScheduleInspectionRequest(
        locationId: location.locationId,
        inspectionTypeId: inspectionTypeId,
        requestedDate: date,
        notes: notes,
      );

      logger.info(
        "Scheduling Inspection Type $inspectionTypeId for Location ${location.locationId} on $date...",
      );

      final response = await apiClient.post(
        '/v1/burgessgo/inspections',
        request.toJson(),
      );

      final newInspectionId = response['newInspectionId'];
      logger.info("Success! Created new inspection with ID: $newInspectionId");
    } catch (e, stackTrace) {
      logger.error(
        "Failed to schedule inspection",
        error: e,
        stackTrace: stackTrace,
      );
      state = state.copyWith(errorMessage: e.toString());
    } finally {
      state = state.copyWith(isBusy: false);
    }
  }

  Future<bool> toggleLocationClosedStatus(
    Location location,
    bool isClosedOut,
  ) async {
    state = state.copyWith(isBusy: true, errorMessage: null);
    try {
      await ref
          .read(firestoreServiceProvider)
          .updateLocationClosedStatus(location.locationId, isClosedOut);

      return true;
    } catch (e) {
      ref
          .read(loggingServiceProvider)
          .error("Failed to update closed status", error: e);
      state = state.copyWith(errorMessage: "Failed to update status: $e");
      return false;
    } finally {
      state = state.copyWith(isBusy: false);
    }
  }

  Future<void> uploadAttachment(Location location) async {
    // TODO: Implement file picker and Firestore upload using location.locationId
  }
}
