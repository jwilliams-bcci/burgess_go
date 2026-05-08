import 'package:burgess_go/features/inspections/models/reschedule_inspection_request.dart';
import 'package:burgess_go/features/inspections/models/schedule_reinspection_request.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:go_router/go_router.dart';

import 'package:burgess_go/core/providers/service_providers.dart';
import 'package:burgess_go/core/models/inspection/inspection.dart';
import 'package:burgess_go/features/inspections/states/inspection_management_state.dart';

// --- PROVIDERS ---

// A simple StreamProvider to watch a single inspection in real-time
final inspectionByIdProvider = StreamProvider.family<Inspection, String>((
  ref,
  inspectionId,
) {
  return FirebaseFirestore.instance
      .collection('inspections')
      .doc(inspectionId)
      .snapshots()
      .map((snapshot) {
        if (!snapshot.exists) throw Exception("Inspection not found");
        return Inspection.fromFirestore(snapshot);
      });
});

final inspectionDetailControllerProvider =
    NotifierProvider.autoDispose<
      InspectionManagementController,
      InspectionManagementState
    >(InspectionManagementController.new);

// --- CONTROLLER ---
class InspectionManagementController
    extends Notifier<InspectionManagementState> {
  @override
  InspectionManagementState build() {
    return InspectionManagementState();
  }

  Future<void> scheduleReinspection(
    BuildContext context,
    Inspection inspection,
    DateTime newDate,
    String? notes,
  ) async {
    _setLoading(true);

    try {
      // 🔥 Use the newly renamed strongly typed DTO
      final request = ScheduleReinspectionRequest(date: newDate, notes: notes);

      final endpoint =
          "/v1/burgessgo/inspections/${inspection.inspectionId}/schedulereinspection";

      final apiClient = ref.read(apiClientProvider);

      // Send the JSON payload from the DTO
      await apiClient.post(endpoint, request.toJson());

      // Sync the dashboard data directly through the sync service
      try {
        await ref.read(syncServiceProvider).syncLocations();
        await ref.read(syncServiceProvider).syncHeaders();
      } catch (syncError) {
        ref
            .read(loggingServiceProvider)
            .error("Background sync failed: $syncError");
      }

      if (context.mounted) {
        // Pop the dialog and show success!
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text("Reinspection successfully scheduled!"),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text("Error scheduling: $e"),
            backgroundColor: Colors.red,
          ),
        );
        // Fallback routing if it fails
        context.go('/super-dash');
      }
    } finally {
      _setLoading(false);
    }
  }

  Future<void> rescheduleInspectionDate(
    BuildContext context,
    Inspection inspection,
    DateTime newDate,
    String? notes,
  ) async {
    _setLoading(true);

    try {
      // 🔥 Use strongly typed DTO
      final request = RescheduleInspectionRequest(date: newDate, notes: notes);

      final endpoint =
          "/v1/burgessgo/inspections/${inspection.inspectionId}/reschedule";

      final apiClient = ref.read(apiClientProvider);

      // Send the JSON payload from the DTO
      await apiClient.post(endpoint, request.toJson());

      // Sync the dashboard data directly through the sync service
      try {
        await ref.read(syncServiceProvider).syncLocations();
        await ref.read(syncServiceProvider).syncHeaders();
      } catch (syncError) {
        ref
            .read(loggingServiceProvider)
            .error("Background sync failed: $syncError");
      }

      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text("Inspection date successfully rescheduled!"),
            backgroundColor: Colors.blue,
          ),
        );
        // Route back to the dashboard upon successful reschedule
        context.go('/super-dash');
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text("Error rescheduling: $e"),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      _setLoading(false);
    }
  }

  Future<void> viewDefects(BuildContext context, Inspection inspection) async {
    context.push('/inspection/${inspection.inspectionId}/defects');
  }

  Future<void> messageConsultant(Inspection inspection) async {
    _setLoading(true);
    await Future.delayed(const Duration(seconds: 1));
    print("TODO: Open Messaging for ${inspection.inspectionId}");
    _setLoading(false);
  }

  Future<void> openAttachments(Inspection inspection) async {
    print("TODO: Fetch and show attachments");
  }

  Future<void> openEnergyDocuments(Inspection inspection) async {
    print("TODO: Fetch and show energy docs");
  }

  void _setLoading(bool value) {
    state = state.copyWith(isLoading: value);
  }
}
