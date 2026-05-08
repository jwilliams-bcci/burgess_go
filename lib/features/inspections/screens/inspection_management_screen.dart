import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:burgess_go/core/providers/holiday_provider.dart';
import 'package:burgess_go/core/utils/scheduling_helper.dart';
import 'package:burgess_go/features/inspections/widgets/schedule_date_dialog.dart';
import '../controllers/inspection_management_controller.dart';

class InspectionManagementScreen extends ConsumerWidget {
  final String inspectionId;

  const InspectionManagementScreen({super.key, required this.inspectionId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // 🔥 Watch the real-time stream using the ID from the URL!
    final inspectionAsync = ref.watch(inspectionByIdProvider(inspectionId));

    // .when() forces us to handle loading, errors, and success states safely
    return inspectionAsync.when(
      loading: () =>
          const Scaffold(body: Center(child: CircularProgressIndicator())),
      error: (error, stack) => Scaffold(
        appBar: AppBar(title: const Text('Error')),
        body: Center(child: Text('Error loading inspection: $error')),
      ),
      data: (inspection) {
        // 1. Watch the state
        final state = ref.watch(inspectionDetailControllerProvider);
        // 2. Read the controller (for actions)
        final controller = ref.read(
          inspectionDetailControllerProvider.notifier,
        );

        // Normalize strings
        final status = inspection.inspectionStatus?.toLowerCase() ?? '';
        final resolution = inspection.resolution?.toLowerCase() ?? '';

        final isComplete = status.contains('complete');
        final isAssigned = status.contains('assigned');
        final isPassed = resolution.contains('pass');

        return Scaffold(
          appBar: AppBar(
            title: Text("Inspection #${inspection.inspectionId}"),
            backgroundColor: Colors.blue[900],
            foregroundColor: Colors.white,
          ),
          body: Stack(
            children: [
              // MAIN CONTENT
              SingleChildScrollView(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    // Header
                    Text(
                      inspection.address ?? "No Address",
                      style: const TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      "${inspection.inspectionType} • ${inspection.community ?? ''}",
                      style: TextStyle(color: Colors.grey[700], fontSize: 14),
                    ),
                    const Divider(height: 32),

                    // --- CONDITIONAL ACTIONS ---
                    if (inspection.resolutionId == 12)
                      _buildActionButton(
                        icon: Icons.autorenew,
                        label: "Schedule Reinspection",
                        color: Colors.red[700]!,
                        onTap: () async {
                          final holidays = await ref.read(
                            holidayProvider.future,
                          );

                          final result = await showDialog<Map<String, dynamic>>(
                            context: context,
                            builder: (context) => ScheduleDateDialog(
                              title: "Schedule Reinspection",
                              companyHolidays: holidays,
                            ),
                          );

                          if (result != null && result['date'] != null) {
                            controller.scheduleReinspection(
                              context,
                              inspection,
                              result['date'],
                              result['notes'],
                            );
                          }
                        },
                      ),

                    if (inspection.resolutionId != 12 &&
                        inspection.isComplete != true)
                      _buildActionButton(
                        icon: Icons.edit_calendar,
                        label: "Reschedule Date",
                        color: Colors.blue[700]!,
                        onTap: () async {
                          // ENFORCE RULE 1: The 7:30 AM Lockout
                          if (inspection.inspectionDate != null) {
                            final canReschedule =
                                SchedulingHelper.canRescheduleToday(
                                  inspection.inspectionDate!,
                                );
                            if (!canReschedule) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(
                                  content: Text(
                                    "It is past 7:30 AM. Today's inspection cannot be rescheduled.",
                                  ),
                                  backgroundColor: Colors.red,
                                ),
                              );
                              return;
                            }
                          }
                          final holidays = await ref.read(
                            holidayProvider.future,
                          );

                          final result = await showDialog<Map<String, dynamic>>(
                            context: context,
                            builder: (context) => ScheduleDateDialog(
                              title: "Reschedule Inspection",
                              companyHolidays: holidays,
                            ),
                          );

                          if (result != null && result['date'] != null) {
                            controller.rescheduleInspectionDate(
                              context,
                              inspection,
                              result['date'],
                              result['notes'],
                            );
                          }
                        },
                      ),

                    if (isComplete && !isPassed)
                      _buildActionButton(
                        icon: Icons.warning_amber_rounded,
                        label: "View Defects",
                        color: Colors.red[700]!,
                        onTap: () =>
                            controller.viewDefects(context, inspection),
                      ),

                    if (isAssigned)
                      _buildActionButton(
                        icon: Icons.message_outlined,
                        label: "Message Consultant",
                        color: Colors.blue[700]!,
                        onTap: () => controller.messageConsultant(inspection),
                      ),

                    // --- STATIC ACTIONS ---
                    _buildActionButton(
                      icon: Icons.attach_file,
                      label: "Attachments",
                      color: Colors.grey[700]!,
                      onTap: () => controller.openAttachments(inspection),
                    ),

                    _buildActionButton(
                      icon: Icons.bolt,
                      label: "Energy Documents",
                      color: Colors.green[700]!,
                      onTap: () => controller.openEnergyDocuments(inspection),
                    ),
                  ],
                ),
              ),

              // LOADING OVERLAY
              if (state.isLoading)
                Container(
                  color: Colors.black.withOpacity(0.3),
                  child: const Center(child: CircularProgressIndicator()),
                ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildActionButton({
    required IconData icon,
    required String label,
    required Color color,
    required VoidCallback onTap,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12.0),
      child: ElevatedButton(
        onPressed: onTap,
        style: ElevatedButton.styleFrom(
          backgroundColor: color,
          foregroundColor: Colors.white,
          padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 20),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          elevation: 2,
          alignment: Alignment.centerLeft,
        ),
        child: Row(
          children: [
            Icon(icon, size: 24),
            const SizedBox(width: 16),
            Text(
              label,
              style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
            const Spacer(),
            const Icon(
              Icons.arrow_forward_ios,
              size: 16,
              color: Colors.white70,
            ),
          ],
        ),
      ),
    );
  }
}
