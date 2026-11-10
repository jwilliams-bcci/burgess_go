import 'package:burgess_go/core/providers/service_providers.dart';
import 'package:burgess_go/features/inspections/models/reschedule_inspection_request.dart';
import 'package:burgess_go/features/inspections/models/schedule_reinspection_request.dart';
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

  Future<bool> scheduleInspection({
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

      // 2. Defense in Depth: Handle C# 200 OK responses that act as failures
      if (response != null && response is Map<String, dynamic>) {
        if (response.containsKey('success') && response['success'] == false) {
          throw Exception(
            response['message'] ?? 'The selected date is not available.',
          );
        }
        if (response.containsKey('error') && response['error'] != null) {
          throw Exception(response['error']);
        }
      }

      final newInspectionId = response['newInspectionId'];
      logger.info("Success! Created new inspection with ID: $newInspectionId");

      return true; // 3. Explicit Success Return
    } catch (e, stackTrace) {
      logger.error(
        "Failed to schedule inspection",
        error: e,
        stackTrace: stackTrace,
      );
      state = state.copyWith(errorMessage: e.toString());
      return false; // 4. Explicit Failure Return
    } finally {
      state = state.copyWith(isBusy: false);
    }
  }

  Future<bool> scheduleReinspection({
    required int inspectionId,
    required DateTime date,
    String? notes,
  }) async {
    state = state.copyWith(isBusy: true, errorMessage: null);
    final logger = ref.read(loggingServiceProvider);

    try {
      final apiClient = ref.read(apiClientProvider);

      final request = ScheduleReinspectionRequest(date: date, notes: notes);

      logger.info(
        "Scheduling Reinspection for Inspection $inspectionId on $date...",
      );

      final response = await apiClient.post(
        '/v1/burgessgo/inspections/$inspectionId/schedulereinspection',
        request.toJson(),
      );

      // 2. Defense in Depth: Handle C# 200 OK responses that act as failures
      if (response != null && response is Map<String, dynamic>) {
        if (response.containsKey('success') && response['success'] == false) {
          throw Exception(
            response['message'] ?? 'The selected date is not available.',
          );
        }
        if (response.containsKey('error') && response['error'] != null) {
          throw Exception(response['error']);
        }
      }

      logger.info("Success! Scheduled reinspection for ID: $inspectionId");

      return true; // 3. Explicit Success Return
    } catch (e, stackTrace) {
      logger.error(
        "Failed to schedule reinspection",
        error: e,
        stackTrace: stackTrace,
      );
      state = state.copyWith(errorMessage: e.toString());
      return false; // 4. Explicit Failure Return
    } finally {
      state = state.copyWith(isBusy: false);
    }
  }

  Future<bool> rescheduleInspection({
    required int inspectionId,
    required DateTime date,
    String? notes,
  }) async {
    state = state.copyWith(isBusy: true, errorMessage: null);
    final logger = ref.read(loggingServiceProvider);

    try {
      final apiClient = ref.read(apiClientProvider);

      final request = RescheduleInspectionRequest(date: date, notes: notes);

      logger.info("Rescheduling Inspection $inspectionId to $date...");

      final response = await apiClient.post(
        '/v1/burgessgo/inspections/$inspectionId/reschedule',
        request.toJson(),
      );

      // Defense in Depth: Handle C# 200 OK responses that act as failures
      if (response != null && response is Map<String, dynamic>) {
        if (response.containsKey('success') && response['success'] == false) {
          throw Exception(
            response['message'] ?? 'The selected date is not available.',
          );
        }
        if (response.containsKey('error') && response['error'] != null) {
          throw Exception(response['error']);
        }
      }

      logger.info("Success! Rescheduled inspection ID: $inspectionId");
      return true;
    } catch (e, stackTrace) {
      logger.error(
        "Failed to reschedule inspection",
        error: e,
        stackTrace: stackTrace,
      );
      state = state.copyWith(errorMessage: e.toString());
      return false;
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
