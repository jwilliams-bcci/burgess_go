import 'dart:async';
import 'package:burgess_go/features/inspections/models/reschedule_inspection_request.dart';
import 'package:burgess_go/features/superintendent_dash/states/superintendent_dash_state.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:burgess_go/core/providers/service_providers.dart';
import 'package:burgess_go/core/models/inspection/inspection.dart';
import 'package:burgess_go/features/auth/controllers/auth_controller.dart';
import 'package:burgess_go/features/inspections/repositories/inspection_repository.dart';
import 'package:burgess_go/features/locations/repositories/location_repository.dart';
import 'package:burgess_go/features/inspections/models/schedule_reinspection_request.dart';

// --- TUTORIAL TRIGGER PROVIDER ---
final drawerTutorialTriggerProvider =
    NotifierProvider<DrawerTutorialTrigger, int>(DrawerTutorialTrigger.new);

class DrawerTutorialTrigger extends Notifier<int> {
  @override
  int build() => 0;

  void trigger() => state++;
}

// --- CONTROLLER PROVIDER ---
final superintendentDashControllerProvider =
    NotifierProvider.autoDispose<
      SuperintendentDashController,
      SuperintendentDashState
    >(SuperintendentDashController.new);

// --- DASHBOARD CONTROLLER ---
class SuperintendentDashController extends Notifier<SuperintendentDashState> {
  StreamSubscription? _inspectionSub;

  IInspectionRepository get _inspectionRepo =>
      ref.read(inspectionRepositoryProvider);

  @override
  SuperintendentDashState build() {
    ref.onDispose(() {
      _inspectionSub?.cancel();
    });

    Future.microtask(_init);

    return SuperintendentDashState();
  }

  void _init() {
    final user = ref.read(authControllerProvider).user;
    if (user == null) return;

    _inspectionSub = _inspectionRepo.watchInspectionsForUser(user).listen((
      allInspections,
    ) {
      // FILTER 1: Action Board (Failed / Status 12)
      final failed = allInspections.where((failedInsp) {
        if (failedInsp.resolutionId != 12) return false;

        final hasReinspection = allInspections.any(
          (otherInsp) =>
              otherInsp.locationId == failedInsp.locationId &&
              otherInsp.inspectionTypeId == failedInsp.inspectionTypeId &&
              otherInsp.inspectionOrder != null &&
              otherInsp.inspectionOrder! > failedInsp.inspectionOrder!,
        );

        return !hasReinspection;
      }).toList();

      // FILTER 2: Schedule (Today -> Next 7 Days)
      final now = DateTime.now();
      final today = DateTime(now.year, now.month, now.day);
      final nextWeek = today.add(const Duration(days: 7));

      final upcoming = allInspections.where((i) {
        if (i.resolutionId == 12) return false;
        if (i.inspectionStatusId != 1 &&
            i.inspectionStatusId != 2 &&
            i.inspectionStatusId != 11) {
          return false;
        }
        if (i.inspectionDate == null) return false;

        final inspDate = DateTime(
          i.inspectionDate!.year,
          i.inspectionDate!.month,
          i.inspectionDate!.day,
        );
        return inspDate.isAfter(today.subtract(const Duration(days: 1))) &&
            inspDate.isBefore(nextWeek.add(const Duration(days: 1)));
      }).toList();

      upcoming.sort((a, b) => a.inspectionDate!.compareTo(b.inspectionDate!));

      // 3. Update the state
      state = state.copyWith(
        inspections: allInspections,
        failedInspections: failed,
        upcomingInspections: upcoming,
        isLoading: false,
      );
    });
  }

  Future<void> syncDashboard() async {
    state = state.copyWith(isLoading: true);
    try {
      await ref.read(syncServiceProvider).syncLocations();
      await ref.read(syncServiceProvider).syncHeaders();
      ref.read(loggingServiceProvider).info("Manual dashboard sync complete.");
    } catch (e) {
      ref.read(loggingServiceProvider).error("Sync failed: $e");
    } finally {
      state = state.copyWith(isLoading: false);
    }
  }

  // --- BUSINESS LOGIC: Reinspection Scheduling ---
  Future<bool> scheduleReinspection({
    required int inspectionId,
    required DateTime date,
    String? notes,
  }) async {
    state = state.copyWith(isLoading: true);
    final logger = ref.read(loggingServiceProvider);

    try {
      final apiClient = ref.read(apiClientProvider);

      // Strict DTO usage
      final request = ScheduleReinspectionRequest(date: date, notes: notes);

      logger.info(
        "Dashboard: Scheduling Reinspection for ID $inspectionId on $date...",
      );

      final response = await apiClient.post(
        '/v1/burgessgo/inspections/$inspectionId/schedulereinspection',
        request.toJson(),
      );

      // Defense in Depth: Handle HTTP 200 responses with internal failure flags
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

      logger.info("Dashboard: Success! Scheduled reinspection.");

      // Automatically refresh the dashboard so the item clears off the action board
      await syncDashboard();

      return true;
    } catch (e, stackTrace) {
      logger.error(
        "Failed to schedule reinspection via Dashboard",
        error: e,
        stackTrace: stackTrace,
      );
      return false;
    } finally {
      // Ensure we clear the loading state even if sync fails
      state = state.copyWith(isLoading: false);
    }
  }

  // --- BUSINESS LOGIC: Reschedule Inspection ---
  Future<bool> rescheduleInspection({
    required int inspectionId,
    required DateTime date,
    String? notes,
  }) async {
    state = state.copyWith(isLoading: true);
    final logger = ref.read(loggingServiceProvider);

    try {
      final apiClient = ref.read(apiClientProvider);

      // Defense in Depth: Strongly typed request payload
      final request = RescheduleInspectionRequest(date: date, notes: notes);

      logger.info(
        "Dashboard: Rescheduling Inspection $inspectionId to $date...",
      );

      final response = await apiClient.post(
        '/v1/burgessgo/inspections/$inspectionId/reschedule',
        request.toJson(),
      );

      // Defense in Depth: Catch soft failures returned as HTTP 200
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

      logger.info(
        "Dashboard: Success! Rescheduled inspection ID: $inspectionId",
      );

      // Refresh dashboard schedule list to reflect new date
      await syncDashboard();

      return true;
    } catch (e, stackTrace) {
      logger.error(
        "Failed to reschedule inspection via Dashboard",
        error: e,
        stackTrace: stackTrace,
      );
      return false;
    } finally {
      state = state.copyWith(isLoading: false);
    }
  }

  // --- BUSINESS LOGIC: PDF Retrieval ---
  Future<String?> getPdfReportLink(int locationId, int inspectionId) async {
    try {
      final locationRepo = ref.read(locationRepositoryProvider);
      final location = await locationRepo.getLocationById(locationId);

      if (location == null || location.locationHistories == null) return null;

      final history = location.locationHistories!
          .where((h) => h.inspectionId == inspectionId)
          .firstOrNull;

      if (history == null || history.reportLink.isEmpty) return null;

      return history.reportLink;
    } catch (e) {
      ref.read(loggingServiceProvider).error("Error fetching PDF link: $e");
      return null;
    }
  }
}
