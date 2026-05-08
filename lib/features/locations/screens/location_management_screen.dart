import 'package:burgess_go/core/models/location/location_history.dart';
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
    final isDesktop = MediaQuery.of(context).size.width > 900;

    return Scaffold(
      backgroundColor: Colors.grey[100],
      appBar: AppBar(
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
          // Default to the location passed via constructor while loading
          Location liveLocation = location;

          // If Firestore has new data, use it instantly!
          if (snapshot.hasData && snapshot.data!.exists) {
            liveLocation = Location.fromFirestore(snapshot.data!);
          }

          return SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildHeroHeader(liveLocation), // Pass the liveLocation down
                _buildActionGrid(context, ref, liveLocation),

                const SizedBox(height: 8),

                Center(
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 1200),
                    child: _buildInspectionListSection(
                      context,
                      ref,
                      liveLocation, // Pass the liveLocation down
                      isDesktop: isDesktop,
                    ),
                  ),
                ),

                const SizedBox(height: 48),
              ],
            ),
          );
        },
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
        color: const Color(0xFF003366), // Fallback Burgess Blue
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
              // Trigger the generic dialog using data from the Location document
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

  // --- RESPONSIVE TILE BUTTON HELPER ---
  Widget _buildTileAction({
    required bool isDesktop,
    required IconData icon,
    required String label,
    required Color color,
    required VoidCallback onTap,
  }) {
    if (isDesktop) {
      return Padding(
        padding: const EdgeInsets.only(left: 8.0),
        child: OutlinedButton.icon(
          onPressed: onTap,
          icon: Icon(icon, size: 18, color: color),
          label: Text(
            label,
            style: TextStyle(color: color, fontWeight: FontWeight.bold),
          ),
          style: OutlinedButton.styleFrom(
            side: BorderSide(color: color),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(8),
            ),
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          ),
        ),
      );
    } else {
      return Padding(
        padding: const EdgeInsets.only(left: 4.0),
        child: Tooltip(
          message: label,
          child: IconButton(
            icon: Icon(icon, color: color, size: 22),
            onPressed: onTap,
            splashRadius: 20,
            constraints: const BoxConstraints(), // Minimizes default padding
            padding: const EdgeInsets.all(8),
          ),
        ),
      );
    }
  }

  // --- FULL WIDTH SECTION: INSPECTION LIST ---
  Widget _buildInspectionListSection(
    BuildContext context,
    WidgetRef ref,
    Location location, {
    required bool isDesktop,
  }) {
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

                IconData icon;
                Color iconColor;
                String statusText;
                bool isUnscheduled = false;

                switch (effectiveStatus) {
                  case 'Pass':
                    icon = Icons.check_circle;
                    iconColor = Colors.green;
                    statusText = "Passed";
                    break;
                  case 'Fail':
                    icon = Icons.cancel;
                    iconColor = Colors.red;
                    statusText = "Failed";
                    break;
                  case 'Complete':
                    icon = Icons.fact_check;
                    iconColor = Colors.blue[800]!;
                    statusText = "Complete";
                    break;
                  case 'Assigned':
                    icon = Icons.person;
                    iconColor = Colors.purple;
                    statusText = "Assigned";
                    break;
                  case 'Scheduled':
                    icon = Icons.schedule;
                    iconColor = Colors.green;
                    statusText = "Scheduled";
                    break;
                  case 'Pending':
                    icon = Icons.schedule;
                    iconColor = Colors.orange;
                    statusText = "Pending";
                    break;
                  default: // 'Unknown' or Unscheduled
                    icon = Icons.radio_button_unchecked;
                    iconColor = Colors.grey[400]!;
                    statusText = "Unscheduled";
                    isUnscheduled = true;
                    break;
                }

                List<Widget> actionButtons = [];

                if (!location.isClosedOut) {
                  // 1. Schedule vs Reschedule Logic
                  if (isUnscheduled) {
                    actionButtons.add(
                      _buildTileAction(
                        isDesktop: isDesktop,
                        icon: Icons.calendar_month,
                        label: "Schedule",
                        color: Colors.blue[700]!,
                        onTap: () =>
                            _openScheduleDialog(context, ref, location),
                      ),
                    );
                  } else if (effectiveStatus == 'Scheduled' ||
                      effectiveStatus == 'Assigned') {
                    DateTime? inspectionDate;
                    try {
                      inspectionDate =
                          (typeObj as dynamic).inspectionDate ??
                          (typeObj as dynamic).scheduledDate;
                    } catch (_) {}

                    bool canReschedule = true;
                    if (inspectionDate != null) {
                      canReschedule = SchedulingHelper.canRescheduleToday(
                        inspectionDate,
                      );
                    }

                    actionButtons.add(
                      _buildTileAction(
                        isDesktop: isDesktop,
                        icon: Icons.edit_calendar,
                        label: "Reschedule",
                        color: canReschedule
                            ? Colors.orange[700]!
                            : Colors.grey,
                        onTap: () {
                          if (canReschedule) {
                            _openScheduleDialog(context, ref, location);
                          } else {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content: Text(
                                  "Cannot reschedule past 7:30 AM on the day of the inspection.",
                                ),
                                backgroundColor: Colors.red,
                              ),
                            );
                          }
                        },
                      ),
                    );
                  }

                  // 2. Attachments (Inspection Specific)
                  if (!isUnscheduled) {
                    actionButtons.add(
                      _buildTileAction(
                        isDesktop: isDesktop,
                        icon: Icons.attach_file,
                        label: "Attachments",
                        color: Colors.teal[600]!,
                        onTap: () {
                          // Trigger the generic dialog using data from the Inspection document
                          final attachments =
                              (typeObj as dynamic).inspectionAttachments ?? [];
                          _showAttachmentsDialog(
                            context,
                            "Inspection Attachments",
                            attachments,
                          );
                        },
                      ),
                    );
                  }

                  // 3. Message Consultant
                  if (effectiveStatus == 'Assigned') {
                    actionButtons.add(
                      _buildTileAction(
                        isDesktop: isDesktop,
                        icon: Icons.message,
                        label: "Message",
                        color: Colors.purple[700]!,
                        onTap: () {
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
                        },
                      ),
                    );
                  }

                  // 4. View History
                  if (effectiveStatus == 'Complete' ||
                      effectiveStatus == 'Fail') {
                    actionButtons.add(
                      _buildTileAction(
                        isDesktop: isDesktop,
                        icon: Icons.history,
                        label: "History",
                        color: Colors.blueGrey[700]!,
                        onTap: () {
                          // 1. Get all histories for THIS specific type
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

                            // 2. Open the Bottom Sheet Timeline!
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
                        },
                      ),
                    );
                  }
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
                  trailing: actionButtons.isNotEmpty
                      ? Row(
                          mainAxisSize: MainAxisSize.min,
                          children: actionButtons,
                        )
                      : null,
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
              // Constrain the height so it doesn't take over the whole screen if there are many records
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

                    // Format the date nicely
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
                      trailing: const Icon(Icons.chevron_right),
                      onTap: () {
                        // Pop the bottom sheet first
                        Navigator.pop(context);
                        // Then route to the specific defects screen!
                        context.push(
                          '/inspection/${history.inspectionId}/defects',
                        );
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

                      // 🔥 SAFETY: Handle raw JSON Maps natively if the model didn't parse them
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
                      }
                      // 🔥 SAFETY: Handle strongly typed Dart objects
                      else {
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
                            if (await canLaunchUrl(url)) {
                              await launchUrl(
                                url,
                                mode: LaunchMode.externalApplication,
                              );
                            } else {
                              if (context.mounted) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(
                                    content: Text(
                                      'Could not open link. URL may be invalid.',
                                    ),
                                  ),
                                );
                              }
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
    Location location,
  ) async {
    final result = await showDialog<Map<String, dynamic>>(
      context: context,
      builder: (context) => ScheduleDateDialog(
        title: "Schedule Inspection",
        availableInspectionTypes: location.availableInspectionTypes,
      ),
    );

    if (result != null) {
      await ref
          .read(locationManagementControllerProvider.notifier)
          .scheduleInspection(
            location: location,
            inspectionTypeId: result['inspectionTypeId'] as int,
            date: result['date'] as DateTime,
            notes: result['notes'] as String?,
          );

      if (!context.mounted) return;
      final state = ref.read(locationManagementControllerProvider);

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            state.errorMessage ?? "Inspection scheduled successfully!",
          ),
          backgroundColor: state.errorMessage != null
              ? Colors.red
              : Colors.green,
          behavior: SnackBarBehavior.floating,
        ),
      );
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
        context.pop();
      }
    }
  }
}
