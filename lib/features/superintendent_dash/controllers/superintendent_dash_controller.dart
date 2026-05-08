import 'dart:async';
import 'package:burgess_go/features/superintendent_dash/states/superintendent_dash_state.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:burgess_go/core/providers/service_providers.dart';
import 'package:burgess_go/core/models/inspection/inspection.dart';
import 'package:burgess_go/features/auth/controllers/auth_controller.dart';
import 'package:burgess_go/features/inspections/repositories/inspection_repository.dart';

// --- PROVIDER ---
final superintendentDashControllerProvider =
    NotifierProvider.autoDispose<
      SuperintendentDashController,
      SuperintendentDashState
    >(SuperintendentDashController.new);

// --- CONTROLLER ---
class SuperintendentDashController extends Notifier<SuperintendentDashState> {
  StreamSubscription? _inspectionSub;

  IInspectionRepository get _inspectionRepo =>
      ref.read(inspectionRepositoryProvider);
  //ILocationService get _locationService => ref.read(locationServiceProvider);

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
            i.inspectionStatusId != 11)
          return false;
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
      ref
          .read(loggingServiceProvider)
          .info("Manual dashboard sync complete (Locations & Headers).");
    } catch (e) {
      ref.read(loggingServiceProvider).error("Sync failed: $e");
    } finally {
      state = state.copyWith(isLoading: false);
    }
  }
}
