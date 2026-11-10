import 'package:burgess_go/core/models/location/location_history.dart';
import 'package:burgess_go/core/providers/holiday_provider.dart';
import 'package:burgess_go/core/utils/scheduling_helper.dart';
import 'package:burgess_go/features/inspections/widgets/schedule_date_dialog.dart';
import 'package:burgess_go/features/locations/controllers/location_management_controller.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../../core/models/location/location.dart';
import 'package:burgess_go/features/inspections/widgets/inspection_messages_dialog.dart';

class LocationManagementScreen extends ConsumerWidget {
  final Location location;

  const LocationManagementScreen({super.key, required this.location});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // 1. Trigger the holiday fetch in the background so it's cached and ready!
    ref.watch(holidayProvider);

    // Wrap the Scaffold in a PopScope to catch Android Hardware Back Button presses
    return PopScope(
      canPop: context.canPop(), // Allow native pop if stack has history
      onPopInvokedWithResult: (bool didPop, Object? result) {
        // If the system successfully popped (didPop == true), do nothing.
        if (didPop) return;

        // If we are here, the system couldn't pop (stack is empty).
        // Catch the exit and route them back to the list instead!
        context.goNamed('locations_list');
      },
      child: Scaffold(
        backgroundColor: Colors.grey[100],
        appBar: AppBar(
          leading: IconButton(
            icon: const Icon(Icons.arrow_back),
            tooltip: 'Back to Homes',
            onPressed: () {
              // Gracefully handle the AppBar back button animation
              if (context.canPop()) {
                context.pop(); // Uses the native reverse-swipe animation
              } else {
                context.goNamed('locations_list'); // Fallback if deep-linked
              }
            },
          ),
          title: Text(
            location.lotNumber != null && location.lotNumber!.isNotEmpty
                ? "Lot ${location.lotNumber} Details"
                : "Home Details",
          ),
          backgroundColor: const Color(0xFF003366),
          foregroundColor: Colors.white,
        ),
        body: StreamBuilder<DocumentSnapshot>(
          stream: FirebaseFirestore.instance
              .collection('locations')
              .doc(location.locationId.toString())
              .snapshots(),
          builder: (context, snapshot) {
            Location liveLocation = location;

            if (snapshot.hasData && snapshot.data!.exists) {
              liveLocation = Location.fromFirestore(snapshot.data!);
            }

            return SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildHeroHeader(liveLocation),
                  _buildActionGrid(context, ref, liveLocation),

                  const SizedBox(height: 8),

                  Center(
                    child: ConstrainedBox(
                      constraints: const BoxConstraints(maxWidth: 1200),
                      child: _buildInspectionListSection(
                        context,
                        ref,
                        liveLocation,
                      ),
                    ),
                  ),

                  const SizedBox(height: 48),
                ],
              ),
            );
          },
        ),
      ),
    );
  }

  // --- HERO HEADER ---
  Widget _buildHeroHeader(Location location) {
    String addressLine = location.address ?? "Unknown Address";
    if (location.lotNumber != null && location.lotNumber!.isNotEmpty) {
      addressLine = "$addressLine - Lot ${location.lotNumber}";
    }

    return Container(
      height: 220,
      width: double.infinity,
      decoration: BoxDecoration(
        color: const Color(0xFF003366),
        image: location.elevationPhotoUrl != null
            ? DecorationImage(
                image: NetworkImage(location.elevationPhotoUrl!),
                fit: BoxFit.cover,
              )
            : null,
      ),
      child: Container(
        alignment: Alignment.bottomLeft,
        padding: const EdgeInsets.all(20),
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [Colors.transparent, Colors.black87],
          ),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            Expanded(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    addressLine,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      const Icon(
                        Icons.location_city,
                        color: Colors.white70,
                        size: 16,
                      ),
                      const SizedBox(width: 6),
                      Text(
                        location.community ?? 'Unknown Community',
                        style: const TextStyle(
                          color: Colors.white70,
                          fontSize: 16,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            if (location.isClosedOut)
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 14,
                  vertical: 6,
                ),
                decoration: BoxDecoration(
                  color: Colors.redAccent,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.white, width: 1),
                ),
                child: const Text(
                  "CLOSED",
                  style: TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 1,
                    fontSize: 12,
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  // --- ACTION GRID ---
  Widget _buildActionGrid(
    BuildContext context,
    WidgetRef ref,
    Location location,
  ) {
    final isBusy = ref.watch(locationManagementControllerProvider).isBusy;

    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Row(
        children: [
          _actionButton(
            icon: Icons.attach_file,
            label: "Location Attachments",
            color: Colors.green[600]!,
            onTap: () {
              final attachments =
                  (location as dynamic).locationAttachments ?? [];
              _showAttachmentsDialog(
                context,
                "Location Attachments",
                attachments,
              );
            },
          ),
          const SizedBox(width: 12),
          _actionButton(
            icon: location.isClosedOut ? Icons.restore : Icons.archive,
            label: location.isClosedOut ? "Re-open" : "Close Out",
            color: location.isClosedOut ? Colors.teal : Colors.brown[600]!,
            onTap: isBusy ? null : () => _toggleCloseStatus(context, ref),
          ),
        ],
      ),
    );
  }

  Widget _actionButton({
    required IconData icon,
    required String label,
    required Color color,
    required VoidCallback? onTap,
    bool isLoading = false,
  }) {
    return Expanded(
      child: ElevatedButton(
        style: ElevatedButton.styleFrom(
          backgroundColor: color,
          foregroundColor: Colors.white,
          padding: const EdgeInsets.symmetric(vertical: 16),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          elevation: 2,
        ),
        onPressed: onTap,
        child: isLoading
            ? const Center(
                child: SizedBox(
                  height: 20,
                  width: 20,
                  child: CircularProgressIndicator(
                    color: Colors.white,
                    strokeWidth: 2,
                  ),
                ),
              )
            : Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(icon, size: 24),
                  const SizedBox(height: 6),
                  Text(
                    label,
                    style: const TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.bold,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
      ),
    );
  }

  // --- FULL WIDTH SECTION: INSPECTION LIST ---
  Widget _buildInspectionListSection(
    BuildContext context,
    WidgetRef ref,
    Location location,
  ) {
    final contractTypes = location.availableInspectionTypes ?? [];
    const double horizontalPadding = 16.0;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Padding(
          padding: EdgeInsets.symmetric(horizontal: horizontalPadding),
          child: Text(
            "Inspection List",
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: Color(0xFF003366),
            ),
          ),
        ),
        const Padding(
          padding: EdgeInsets.only(
            left: horizontalPadding,
            right: horizontalPadding,
            top: 4.0,
            bottom: 8.0,
          ),
          child: Text(
            "All inspection types for this home.",
            style: TextStyle(color: Colors.grey, fontSize: 13),
          ),
        ),
        if (contractTypes.isEmpty)
          const Padding(
            padding: EdgeInsets.symmetric(horizontal: horizontalPadding),
            child: Text(
              "No contract types assigned.",
              style: TextStyle(fontStyle: FontStyle.italic),
            ),
          )
        else
          Card(
            margin: const EdgeInsets.symmetric(horizontal: horizontalPadding),
            color: Colors.white,
            elevation: 1,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            child: ListView.separated(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: contractTypes.length,
              separatorBuilder: (_, __) =>
                  Divider(height: 1, color: Colors.grey[200]),
              itemBuilder: (context, index) {
                final typeObj = contractTypes[index];
                final String? effectiveStatus = typeObj.iconStatus;

                // Dynamically check for history
                final bool hasHistory =
                    location.locationHistories?.any(
                      (h) => h.inspectionTypeId == typeObj.inspectionTypeId,
                    ) ??
                    false;

                DateTime? inspectionDate;
                try {
                  inspectionDate =
                      (typeObj as dynamic).activeInspectionDate ??
                      (typeObj as dynamic).scheduledDate;
                } catch (_) {}

                String dateSuffixFor = "";
                String dateSuffixOn = "";
                if (inspectionDate != null) {
                  final dateStr =
                      "${inspectionDate.month}/${inspectionDate.day}/${inspectionDate.year}";
                  dateSuffixFor = " for $dateStr";
                  dateSuffixOn = " on $dateStr";
                }

                IconData icon;
                Color iconColor;
                String statusText;
                bool isUnscheduled = false;

                switch (effectiveStatus) {
                  case 'Pass':
                    icon = Icons.check_circle;
                    iconColor = Colors.green;
                    statusText = "Passed$dateSuffixOn";
                    break;
                  case 'Fail':
                    icon = Icons.cancel;
                    iconColor = Colors.red;
                    statusText = "Failed$dateSuffixOn";
                    break;
                  case 'Not Ready':
                    icon = Icons.warning_amber_rounded;
                    iconColor = Colors.orange[800]!;
                    statusText = "Not Ready$dateSuffixOn";
                    break;
                  case 'Complete':
                    icon = Icons.fact_check;
                    iconColor = Colors.blue[800]!;
                    statusText = "Complete$dateSuffixOn";
                    break;
                  case 'Assigned':
                    icon = Icons.person;
                    iconColor = Colors.purple;
                    statusText = "Assigned$dateSuffixFor";
                    break;
                  case 'Scheduled':
                    icon = Icons.schedule;
                    iconColor = Colors.green;
                    statusText = "Scheduled$dateSuffixFor";
                    break;
                  case 'Pending':
                    icon = Icons.schedule;
                    iconColor = Colors.orange;
                    statusText = "Pending$dateSuffixFor";
                    break;
                  default:
                    icon = Icons.radio_button_unchecked;
                    iconColor = Colors.grey[400]!;
                    statusText = "Unscheduled";
                    isUnscheduled = true;
                    break;
                }

                // --- BUILD THE CONTEXT MENU ---
                List<PopupMenuEntry<String>> menuItems = [];

                if (!location.isClosedOut) {
                  if (isUnscheduled) {
                    menuItems.add(
                      PopupMenuItem(
                        value: 'schedule',
                        child: Row(
                          children: [
                            Icon(Icons.calendar_month, color: Colors.blue[700]),
                            const SizedBox(width: 12),
                            const Text('Schedule'),
                          ],
                        ),
                      ),
                    );
                  } else {
                    // Reschedule
                    if (effectiveStatus == 'Scheduled' ||
                        effectiveStatus == 'Assigned') {
                      bool canReschedule = true;
                      if (inspectionDate != null) {
                        canReschedule = SchedulingHelper.canRescheduleToday(
                          inspectionDate,
                        );
                      }

                      if (canReschedule) {
                        menuItems.add(
                          PopupMenuItem(
                            value: 'reschedule',
                            child: Row(
                              children: [
                                Icon(
                                  Icons.edit_calendar,
                                  color: Colors.orange[700],
                                ),
                                const SizedBox(width: 12),
                                const Text('Reschedule'),
                              ],
                            ),
                          ),
                        );
                      }
                    }

                    // Reinspect & View Defects
                    if (effectiveStatus == 'Fail' ||
                        effectiveStatus == 'Not Ready') {
                      menuItems.add(
                        PopupMenuItem(
                          value: 'reinspect',
                          child: Row(
                            children: [
                              Icon(Icons.replay, color: Colors.red[700]),
                              const SizedBox(width: 12),
                              const Text('Reinspect'),
                            ],
                          ),
                        ),
                      );

                      menuItems.add(
                        PopupMenuItem(
                          value: 'view_defects',
                          child: Row(
                            children: [
                              Icon(Icons.fact_check, color: Colors.red[700]),
                              const SizedBox(width: 12),
                              const Text('View Defects'),
                            ],
                          ),
                        ),
                      );
                    }

                    // Message
                    if (effectiveStatus == 'Assigned') {
                      menuItems.add(
                        PopupMenuItem(
                          value: 'message',
                          child: Row(
                            children: [
                              Icon(Icons.message, color: Colors.purple[700]),
                              const SizedBox(width: 12),
                              const Text('Message'),
                            ],
                          ),
                        ),
                      );
                    }

                    // Attachments
                    menuItems.add(
                      PopupMenuItem(
                        value: 'attachments',
                        child: Row(
                          children: [
                            Icon(Icons.attach_file, color: Colors.teal[600]),
                            const SizedBox(width: 12),
                            const Text('Attachments'),
                          ],
                        ),
                      ),
                    );
                  }

                  // History (Applies to any status, as long as it has history entries)
                  if (hasHistory) {
                    menuItems.add(
                      PopupMenuItem(
                        value: 'history',
                        child: Row(
                          children: [
                            Icon(Icons.history, color: Colors.blueGrey[700]),
                            const SizedBox(width: 12),
                            const Text('History'),
                          ],
                        ),
                      ),
                    );
                  }
                }

                Widget? trailingWidget;
                if (menuItems.isNotEmpty) {
                  trailingWidget = PopupMenuButton<String>(
                    icon: const Icon(Icons.more_vert, color: Colors.grey),
                    onSelected: (value) async {
                      switch (value) {
                        case 'schedule':
                          _openScheduleDialog(
                            context,
                            ref,
                            location,
                            preselectedTypeId: typeObj.inspectionTypeId,
                          );
                          break;

                        case 'reschedule':
                          final activeId = typeObj.activeInspectionId;
                          if (activeId != null && activeId > 0) {
                            _openRescheduleDialog(context, ref, activeId);
                          } else {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content: Text(
                                  "Cannot reschedule: active inspection ID not found.",
                                ),
                                backgroundColor: Colors.orange,
                              ),
                            );
                          }
                          break;

                        case 'reinspect':
                          int? targetInspectionId = typeObj.activeInspectionId;
                          if (targetInspectionId == null ||
                              targetInspectionId <= 0) {
                            final histories =
                                location.locationHistories
                                    ?.where(
                                      (h) =>
                                          h.inspectionTypeId ==
                                          typeObj.inspectionTypeId,
                                    )
                                    .toList() ??
                                [];

                            if (histories.isNotEmpty) {
                              histories.sort(
                                (a, b) => (b.submissionDate ?? DateTime(1900))
                                    .compareTo(
                                      a.submissionDate ?? DateTime(1900),
                                    ),
                              );
                              targetInspectionId = histories.first.inspectionId;
                            }
                          }

                          if (targetInspectionId != null &&
                              targetInspectionId > 0) {
                            _openReinspectionDialog(
                              context,
                              ref,
                              targetInspectionId,
                            );
                          } else {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content: Text(
                                  "Cannot reinspect: previous inspection record not found.",
                                ),
                                backgroundColor: Colors.orange,
                              ),
                            );
                          }
                          break;

                        case 'view_defects':
                          int? targetDefectId = typeObj.activeInspectionId;
                          if (targetDefectId == null || targetDefectId <= 0) {
                            final histories =
                                location.locationHistories
                                    ?.where(
                                      (h) =>
                                          h.inspectionTypeId ==
                                          typeObj.inspectionTypeId,
                                    )
                                    .toList() ??
                                [];

                            if (histories.isNotEmpty) {
                              histories.sort(
                                (a, b) => (b.submissionDate ?? DateTime(1900))
                                    .compareTo(
                                      a.submissionDate ?? DateTime(1900),
                                    ),
                              );
                              targetDefectId = histories.first.inspectionId;
                            }
                          }

                          if (targetDefectId != null && targetDefectId > 0) {
                            context.push('/inspection/$targetDefectId/defects');
                          } else {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content: Text(
                                  "Cannot view defects: previous inspection record not found.",
                                ),
                                backgroundColor: Colors.orange,
                              ),
                            );
                          }
                          break;

                        case 'message':
                          final activeId = typeObj.activeInspectionId;
                          if (activeId != null && activeId > 0) {
                            showModalBottomSheet(
                              context: context,
                              isScrollControlled: true,
                              backgroundColor: Colors.white,
                              shape: const RoundedRectangleBorder(
                                borderRadius: BorderRadius.vertical(
                                  top: Radius.circular(16),
                                ),
                              ),
                              builder: (context) => InspectionMessagesDialog(
                                inspectionId: activeId,
                                typeName: typeObj.typeName,
                              ),
                            );
                          } else {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content: Text(
                                  "Still syncing the active inspection. Try again in a moment.",
                                ),
                                backgroundColor: Colors.orange,
                              ),
                            );
                          }
                          break;

                        case 'attachments':
                          final activeId = typeObj.activeInspectionId;
                          if (activeId != null && activeId > 0) {
                            // Show a loading indicator while fetching
                            showDialog(
                              context: context,
                              barrierDismissible: false,
                              builder: (context) => const Center(
                                child: CircularProgressIndicator(),
                              ),
                            );

                            try {
                              final snapshot = await FirebaseFirestore.instance
                                  .collection('inspections')
                                  .doc(activeId.toString())
                                  .collection('inspectionAttachments')
                                  .get();

                              if (!context.mounted) return;
                              Navigator.of(context, rootNavigator: true).pop();

                              final List<dynamic> attachments = snapshot.docs
                                  .map((doc) => doc.data())
                                  .toList();
                              _showAttachmentsDialog(
                                context,
                                "Inspection Attachments",
                                attachments,
                              );
                            } catch (e) {
                              if (!context.mounted) return;
                              // 🔥 Fix: Explicitly use the root navigator to pop the spinner
                              Navigator.of(context, rootNavigator: true).pop();
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                  content: Text(
                                    "Failed to load attachments: $e",
                                  ),
                                  backgroundColor: Colors.red,
                                ),
                              );
                            }
                          } else {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content: Text(
                                  "Cannot load attachments: active inspection ID not found.",
                                ),
                                backgroundColor: Colors.orange,
                              ),
                            );
                          }
                          break;

                        case 'history':
                          final histories =
                              location.locationHistories
                                  ?.where(
                                    (h) =>
                                        h.inspectionTypeId ==
                                        typeObj.inspectionTypeId,
                                  )
                                  .toList() ??
                              [];

                          if (histories.isNotEmpty) {
                            histories.sort(
                              (a, b) => (b.submissionDate ?? DateTime(1900))
                                  .compareTo(
                                    a.submissionDate ?? DateTime(1900),
                                  ),
                            );
                            _showHistoryBottomSheet(
                              context,
                              typeObj.typeName,
                              histories,
                            );
                          } else {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content: Text("No history records found."),
                                backgroundColor: Colors.orange,
                              ),
                            );
                          }
                          break;
                      }
                    },
                    itemBuilder: (BuildContext context) => menuItems,
                  );
                }

                return ListTile(
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 8,
                  ),
                  leading: Icon(icon, color: iconColor, size: 28),
                  title: Text(
                    typeObj.typeName,
                    style: const TextStyle(
                      fontWeight: FontWeight.w600,
                      fontSize: 15,
                    ),
                  ),
                  subtitle: Text(
                    statusText,
                    style: TextStyle(
                      color: isUnscheduled ? Colors.grey[600] : iconColor,
                      fontWeight: isUnscheduled
                          ? FontWeight.normal
                          : FontWeight.w600,
                    ),
                  ),
                  trailing: trailingWidget,
                );
              },
            ),
          ),
      ],
    );
  }

  // --- HISTORY BOTTOM SHEET ---
  void _showHistoryBottomSheet(
    BuildContext context,
    String typeName,
    List<LocationHistory> histories,
  ) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (context) {
        return SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Padding(
                padding: const EdgeInsets.all(16.0),
                child: Text(
                  "$typeName History",
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Colors.blueGrey[900],
                  ),
                ),
              ),
              const Divider(height: 1),
              ConstrainedBox(
                constraints: BoxConstraints(
                  maxHeight: MediaQuery.of(context).size.height * 0.5,
                ),
                child: ListView.separated(
                  shrinkWrap: true,
                  itemCount: histories.length,
                  separatorBuilder: (_, __) => const Divider(height: 1),
                  itemBuilder: (context, index) {
                    final history = histories[index];
                    final isPass = history.resolution.toLowerCase().contains(
                      'pass',
                    );

                    final dateStr = history.submissionDate != null
                        ? "${history.submissionDate!.month}/${history.submissionDate!.day}/${history.submissionDate!.year}"
                        : "Unknown Date";

                    return ListTile(
                      leading: CircleAvatar(
                        backgroundColor: isPass
                            ? Colors.green[100]
                            : Colors.red[100],
                        child: Icon(
                          isPass ? Icons.check : Icons.close,
                          color: isPass ? Colors.green[800] : Colors.red[800],
                        ),
                      ),
                      title: Text(
                        history.resolution,
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          color: isPass ? Colors.green[800] : Colors.red[800],
                        ),
                      ),
                      subtitle: Text(
                        "$dateStr • Inspector: ${history.inspector}",
                      ),
                      trailing: const Icon(Icons.open_in_new),
                      onTap: () async {
                        // Close the bottom sheet first
                        Navigator.pop(context);

                        final String reportUrl = history.reportLink;

                        if (reportUrl.isNotEmpty) {
                          final Uri url = Uri.parse(reportUrl);

                          // Launch the URL
                          final launched = await launchUrl(
                            url,
                            mode: LaunchMode.externalApplication,
                          );

                          if (!launched && context.mounted) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content: Text(
                                  'Could not open the report link.',
                                ),
                                backgroundColor: Colors.red,
                              ),
                            );
                          }
                        } else {
                          if (context.mounted) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content: Text(
                                  'Report link is not available for this record.',
                                ),
                                backgroundColor: Colors.orange,
                              ),
                            );
                          }
                        }
                      },
                    );
                  },
                ),
              ),
              const SizedBox(height: 16),
            ],
          ),
        );
      },
    );
  }

  // --- ATTACHMENTS DIALOG HELPER ---
  void _showAttachmentsDialog(
    BuildContext context,
    String title,
    List<dynamic> attachments,
  ) {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text(
            title,
            style: const TextStyle(fontWeight: FontWeight.bold),
          ),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          content: SizedBox(
            width: double.maxFinite,
            child: attachments.isEmpty
                ? const Padding(
                    padding: EdgeInsets.all(16.0),
                    child: Text(
                      "No attachments available.",
                      style: TextStyle(
                        color: Colors.grey,
                        fontStyle: FontStyle.italic,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  )
                : ListView.separated(
                    shrinkWrap: true,
                    itemCount: attachments.length,
                    separatorBuilder: (_, __) => const Divider(height: 1),
                    itemBuilder: (context, index) {
                      final attachment = attachments[index];
                      String fileName = 'Unknown File';
                      String? remoteUrl;

                      if (attachment is Map) {
                        fileName =
                            (attachment['Filename'] ??
                                    attachment['fileName'] ??
                                    'Unknown File')
                                .toString();
                        remoteUrl =
                            (attachment['Url'] ??
                                    attachment['fileLink'] ??
                                    attachment['remoteUrl'])
                                ?.toString();
                      } else {
                        try {
                          fileName = (attachment.fileName ?? 'Unknown File')
                              .toString();
                          remoteUrl = attachment.remoteUrl?.toString();
                        } catch (_) {}
                      }

                      return ListTile(
                        contentPadding: EdgeInsets.zero,
                        leading: Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: Colors.blue[50],
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Icon(
                            Icons.description,
                            color: Colors.blue[800],
                          ),
                        ),
                        title: Text(
                          fileName,
                          style: const TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        trailing: const Icon(
                          Icons.open_in_new,
                          size: 18,
                          color: Colors.grey,
                        ),
                        onTap: () async {
                          if (remoteUrl != null && remoteUrl.isNotEmpty) {
                            final Uri url = Uri.parse(remoteUrl);

                            // Bypass canLaunchUrl to avoid Android 11+ package visibility (queries) blocks
                            final launched = await launchUrl(
                              url,
                              mode: LaunchMode.externalApplication,
                            );

                            if (!launched && context.mounted) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(
                                  content: Text(
                                    'Could not open link. URL may be invalid or no browser found.',
                                  ),
                                ),
                              );
                            }
                          } else {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content: Text('File URL is not available.'),
                              ),
                            );
                          }
                        },
                      );
                    },
                  ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text(
                "Close",
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
            ),
          ],
        );
      },
    );
  }

  // --- CONTROLLER LOGIC HELPERS ---
  Future<void> _openScheduleDialog(
    BuildContext context,
    WidgetRef ref,
    Location location, {
    int? preselectedTypeId,
  }) async {
    // 2. Read the warmed up holiday list from the provider value
    final holidays = ref.read(holidayProvider).value ?? [];

    final result = await showDialog<Map<String, dynamic>>(
      context: context,
      builder: (context) => ScheduleDateDialog(
        title: "Schedule Inspection",
        companyHolidays: holidays,
        availableInspectionTypes: location.availableInspectionTypes,
        initialInspectionTypeId: preselectedTypeId,
      ),
    );

    if (result != null) {
      final success = await ref
          .read(locationManagementControllerProvider.notifier)
          .scheduleInspection(
            location: location,
            inspectionTypeId: result['inspectionTypeId'] as int,
            date: result['date'] as DateTime,
            notes: result['notes'] as String?,
          );

      if (!context.mounted) return;
      final state = ref.read(locationManagementControllerProvider);

      if (success) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text("Inspection scheduled successfully!"),
            backgroundColor: Colors.green,
            behavior: SnackBarBehavior.floating,
          ),
        );
      } else {
        final errorMsg =
            state.errorMessage?.replaceAll('Exception: ', '') ??
            "Failed to schedule.";
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(errorMsg),
            backgroundColor: Colors.red,
            behavior: SnackBarBehavior.floating,
            duration: const Duration(seconds: 4),
          ),
        );
      }
    }
  }

  Future<void> _openReinspectionDialog(
    BuildContext context,
    WidgetRef ref,
    int inspectionId,
  ) async {
    final holidays = ref.read(holidayProvider).value ?? [];

    final result = await showDialog<Map<String, dynamic>>(
      context: context,
      builder: (context) => ScheduleDateDialog(
        title: "Schedule Reinspection",
        companyHolidays: holidays,
      ),
    );

    if (result != null) {
      final success = await ref
          .read(locationManagementControllerProvider.notifier)
          .scheduleReinspection(
            inspectionId: inspectionId,
            date: result['date'] as DateTime,
            notes: result['notes'] as String?,
          );

      if (!context.mounted) return;
      final state = ref.read(locationManagementControllerProvider);

      if (success) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text("Reinspection scheduled successfully!"),
            backgroundColor: Colors.green,
            behavior: SnackBarBehavior.floating,
          ),
        );
      } else {
        final errorMsg =
            state.errorMessage?.replaceAll('Exception: ', '') ??
            "Failed to schedule.";
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(errorMsg),
            backgroundColor: Colors.red,
            behavior: SnackBarBehavior.floating,
            duration: const Duration(seconds: 4),
          ),
        );
      }
    }
  }

  Future<void> _openRescheduleDialog(
    BuildContext context,
    WidgetRef ref,
    int inspectionId,
  ) async {
    final holidays = ref.read(holidayProvider).value ?? [];

    final result = await showDialog<Map<String, dynamic>>(
      context: context,
      builder: (context) => ScheduleDateDialog(
        title: "Reschedule Inspection",
        companyHolidays: holidays,
      ),
    );

    if (result != null) {
      final success = await ref
          .read(locationManagementControllerProvider.notifier)
          .rescheduleInspection(
            inspectionId: inspectionId,
            date: result['date'] as DateTime,
            notes: result['notes'] as String?,
          );

      if (!context.mounted) return;
      final state = ref.read(locationManagementControllerProvider);

      if (success) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text("Inspection rescheduled successfully!"),
            backgroundColor: Colors.blue,
            behavior: SnackBarBehavior.floating,
          ),
        );
      } else {
        final errorMsg =
            state.errorMessage?.replaceAll('Exception: ', '') ??
            "Failed to reschedule.";
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(errorMsg),
            backgroundColor: Colors.red,
            behavior: SnackBarBehavior.floating,
            duration: const Duration(seconds: 4),
          ),
        );
      }
    }
  }

  Future<void> _toggleCloseStatus(BuildContext context, WidgetRef ref) async {
    final isClosing = !location.isClosedOut;
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(isClosing ? "Close Out Home?" : "Re-open Home?"),
        content: Text(
          isClosing
              ? "This will hide the home from your active list. Are you sure?"
              : "This will restore the home to your active list.",
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text("Cancel"),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: isClosing ? Colors.red : Colors.teal,
              foregroundColor: Colors.white,
            ),
            onPressed: () => Navigator.pop(context, true),
            child: Text(isClosing ? "Yes, Close It" : "Yes, Re-open"),
          ),
        ],
      ),
    );

    if (confirm == true) {
      final success = await ref
          .read(locationManagementControllerProvider.notifier)
          .toggleLocationClosedStatus(location, isClosing);

      if (success && context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(isClosing ? "Home Closed!" : "Home Re-opened!"),
            backgroundColor: Colors.green,
          ),
        );

        if (isClosing) {
          context.goNamed('locations_list');
        }
      }
    }
  }
}
