import 'package:burgess_go/core/providers/holiday_provider.dart';
import 'package:burgess_go/features/auth/controllers/auth_controller.dart';
import 'package:burgess_go/core/models/inspection/inspection.dart';
import 'package:burgess_go/features/inspections/widgets/schedule_date_dialog.dart';
import 'package:burgess_go/core/utils/scheduling_helper.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../controllers/superintendent_dash_controller.dart';
import 'package:intl/intl.dart';
import 'package:showcaseview/showcaseview.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:burgess_go/features/locations/repositories/location_repository.dart';

class SuperintendentDashScreen extends ConsumerStatefulWidget {
  const SuperintendentDashScreen({super.key});

  @override
  ConsumerState<SuperintendentDashScreen> createState() =>
      _SuperintendentDashScreenState();
}

class _SuperintendentDashScreenState
    extends ConsumerState<SuperintendentDashScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _animationController;

  final GlobalKey _helpKey = GlobalKey();
  final GlobalKey _fabKey = GlobalKey();
  final GlobalKey _scheduleTabKey = GlobalKey();
  final GlobalKey _actionBoardTabKey = GlobalKey();

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    )..repeat(reverse: true);

    ShowcaseView.register();

    WidgetsBinding.instance.addPostFrameCallback((_) async {
      final prefs = await SharedPreferences.getInstance();
      final hasSeenHelp = prefs.getBool('hasSeenHelpTutorial') ?? false;

      if (!hasSeenHelp && mounted) {
        ShowcaseView.get().startShowCase([_helpKey]);
        await prefs.setBool('hasSeenHelpTutorial', true);
      }
    });
  }

  @override
  void dispose() {
    _animationController.dispose();
    ShowcaseView.get().unregister();
    super.dispose();
  }

  // --- HELPER: 7:30 AM Cutoff Rule ---
  bool _canCancelInspection(Inspection inspection) {
    if (inspection.inspectionDate == null) return false;

    final now = DateTime.now();
    final inspDate = inspection.inspectionDate!;

    final isToday = DateUtils.isSameDay(inspDate, now);
    final isFuture = inspDate.isAfter(
      DateTime(now.year, now.month, now.day, 23, 59, 59),
    );

    // Future days can always be cancelled
    if (isFuture) return true;

    // Same day cancellation cutoff is strictly 7:30 AM
    if (isToday) {
      final cutoff = DateTime(now.year, now.month, now.day, 7, 30);
      return now.isBefore(cutoff);
    }

    // Past dates cannot be cancelled
    return false;
  }

  Future<void> _openRescheduleDialog(
    BuildContext context,
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
          .read(superintendentDashControllerProvider.notifier)
          .rescheduleInspection(
            inspectionId: inspectionId,
            date: result['date'] as DateTime,
            notes: result['notes'] as String?,
          );

      if (!context.mounted) return;

      if (success) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text("Inspection rescheduled successfully!"),
            backgroundColor: Colors.blue,
            behavior: SnackBarBehavior.floating,
          ),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text("Failed to reschedule inspection."),
            backgroundColor: Colors.red,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    }
  }

  Future<void> _openReinspectionDialog(
    BuildContext context,
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
          .read(superintendentDashControllerProvider.notifier)
          .scheduleReinspection(
            inspectionId: inspectionId,
            date: result['date'] as DateTime,
            notes: result['notes'] as String?,
          );

      if (!context.mounted) return;

      if (success) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text("Reinspection scheduled successfully!"),
            backgroundColor: Colors.green,
            behavior: SnackBarBehavior.floating,
          ),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text("Failed to schedule reinspection."),
            backgroundColor: Colors.red,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    }
  }

  // --- HELPER: Schedule Options Context Menu ---
  void _showScheduleOptions(BuildContext context, Inspection inspection) {
    final canCancel = _canCancelInspection(inspection);
    final canReschedule = inspection.inspectionDate != null
        ? SchedulingHelper.canRescheduleToday(inspection.inspectionDate!)
        : true;

    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (BuildContext bottomSheetContext) {
        return SafeArea(
          child: Wrap(
            children: [
              Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Inspection Options',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: Colors.blueGrey[900],
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      inspection.address ?? 'Selected Inspection',
                      style: TextStyle(fontSize: 13, color: Colors.grey[600]),
                    ),
                  ],
                ),
              ),
              const Divider(height: 1),

              // 1. Cancel Option
              ListTile(
                leading: CircleAvatar(
                  backgroundColor: canCancel
                      ? Colors.red[50]
                      : Colors.grey[200],
                  child: Icon(
                    Icons.cancel_outlined,
                    color: canCancel ? Colors.red[700] : Colors.grey[500],
                  ),
                ),
                title: Text(
                  'Cancel Inspection',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    color: canCancel ? Colors.red[900] : Colors.grey[600],
                  ),
                ),
                subtitle: Text(
                  canCancel
                      ? 'Cancel this scheduled inspection'
                      : 'Cutoff passed (same-day must be before 7:30 AM)',
                  style: TextStyle(
                    fontSize: 12,
                    color: canCancel ? Colors.grey[600] : Colors.red[700],
                  ),
                ),
                onTap: () {
                  Navigator.pop(bottomSheetContext);
                  if (canCancel) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text(
                          "Cancellation coming soon, please contact Burgess for cancellations.",
                        ),
                        behavior: SnackBarBehavior.floating,
                      ),
                    );
                  } else {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text(
                          "Same-day cancellations must be requested prior to 7:30 AM. Please contact Burgess dispatch directly.",
                        ),
                        backgroundColor: Colors.orange,
                        behavior: SnackBarBehavior.floating,
                        duration: Duration(seconds: 4),
                      ),
                    );
                  }
                },
              ),

              // 2. Reschedule Option
              ListTile(
                leading: CircleAvatar(
                  backgroundColor: canReschedule
                      ? Colors.orange[50]
                      : Colors.grey[200],
                  child: Icon(
                    Icons.edit_calendar,
                    color: canReschedule
                        ? Colors.orange[700]
                        : Colors.grey[500],
                  ),
                ),
                title: Text(
                  'Reschedule',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    color: canReschedule ? Colors.black87 : Colors.grey[600],
                  ),
                ),
                subtitle: Text(
                  canReschedule
                      ? 'Move this inspection to another date'
                      : 'Cutoff passed (same-day must be before 7:30 AM)',
                  style: TextStyle(
                    fontSize: 12,
                    color: canReschedule ? Colors.grey[600] : Colors.red[700],
                  ),
                ),
                onTap: () {
                  Navigator.pop(bottomSheetContext);
                  if (canReschedule) {
                    _openRescheduleDialog(context, inspection.inspectionId);
                  } else {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text(
                          "Same-day reschedules must be requested prior to 7:30 AM. Please contact Burgess dispatch directly.",
                        ),
                        backgroundColor: Colors.orange,
                        behavior: SnackBarBehavior.floating,
                        duration: Duration(seconds: 4),
                      ),
                    );
                  }
                },
              ),

              // 3. Go To Home Option (Original default behavior)
              ListTile(
                leading: CircleAvatar(
                  backgroundColor: const Color(0xFFE6EDF5),
                  child: const Icon(Icons.home_work, color: Color(0xFF003366)),
                ),
                title: const Text(
                  'Go To Home',
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
                subtitle: const Text('Manage location details and history'),
                onTap: () {
                  Navigator.pop(bottomSheetContext);
                  context.pushNamed(
                    'location_management',
                    pathParameters: {
                      'locationId': inspection.locationId.toString(),
                    },
                  );
                },
              ),
              const SizedBox(height: 16),
            ],
          ),
        );
      },
    );
  }

  // --- HELPER: Action Bottom Sheet ---
  void _showAddOptions(BuildContext context) {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (BuildContext context) {
        return SafeArea(
          child: Wrap(
            children: [
              Padding(
                padding: const EdgeInsets.all(16.0),
                child: Text(
                  'What would you like to do?',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Colors.blueGrey[900],
                  ),
                ),
              ),
              ListTile(
                leading: CircleAvatar(
                  backgroundColor: const Color(0xFFE6EDF5),
                  child: const Icon(Icons.home_work, color: Color(0xFF003366)),
                ),
                title: const Text(
                  'Add New Address',
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
                subtitle: const Text('Create a new home or lot in the system'),
                onTap: () {
                  Navigator.pop(context);
                  context.push('/add-location');
                },
              ),
              ListTile(
                leading: CircleAvatar(
                  backgroundColor: Colors.orange[100],
                  child: Icon(Icons.calendar_month, color: Colors.orange[900]),
                ),
                title: const Text(
                  'Schedule Inspection',
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
                subtitle: const Text(
                  'Request an inspection for an existing address',
                ),
                onTap: () {
                  Navigator.pop(context);
                  context.push('/locations');
                },
              ),
              const SizedBox(height: 24),
            ],
          ),
        );
      },
    );
  }

  // --- HELPER: Action Board Options Bottom Sheet ---
  void _showActionBoardOptions(BuildContext context, Inspection inspection) {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (BuildContext bottomSheetContext) {
        return SafeArea(
          child: Wrap(
            children: [
              Padding(
                padding: const EdgeInsets.all(16.0),
                child: Text(
                  'Action Board Options',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Colors.blueGrey[900],
                  ),
                ),
              ),
              ListTile(
                leading: CircleAvatar(
                  backgroundColor: Colors.orange[50],
                  child: Icon(Icons.replay, color: Colors.orange[700]),
                ),
                title: const Text(
                  'Schedule Reinspection',
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
                subtitle: const Text(
                  'Request a reinspection date for this home',
                ),
                onTap: () {
                  Navigator.pop(bottomSheetContext);
                  _openReinspectionDialog(context, inspection.inspectionId);
                },
              ),
              ListTile(
                leading: CircleAvatar(
                  backgroundColor: Colors.red[50],
                  child: Icon(
                    Icons.fact_check_outlined,
                    color: Colors.red[700],
                  ),
                ),
                title: const Text(
                  'Go to Defects',
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
                subtitle: const Text(
                  'View and dispatch failed punch list items',
                ),
                onTap: () {
                  Navigator.pop(bottomSheetContext);
                  context.push(
                    '/inspection/${inspection.inspectionId}/defects',
                  );
                },
              ),
              ListTile(
                leading: CircleAvatar(
                  backgroundColor: Colors.blue[50],
                  child: Icon(Icons.picture_as_pdf, color: Colors.blue[700]),
                ),
                title: const Text(
                  'View PDF Report',
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
                subtitle: const Text(
                  'Download or view the official inspection report',
                ),
                onTap: () async {
                  Navigator.pop(bottomSheetContext);

                  if (inspection.locationId == null) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Invalid Location ID.'),
                        backgroundColor: Colors.orange,
                      ),
                    );
                    return;
                  }

                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Fetching PDF link...'),
                      behavior: SnackBarBehavior.floating,
                      duration: Duration(seconds: 2),
                    ),
                  );

                  try {
                    final locationRepo = ref.read(locationRepositoryProvider);
                    final location = await locationRepo.getLocationById(
                      inspection.locationId!,
                    );

                    if (location == null ||
                        location.locationHistories == null) {
                      if (context.mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text('Could not find location data.'),
                            backgroundColor: Colors.orange,
                          ),
                        );
                      }
                      return;
                    }

                    final history = location.locationHistories!
                        .where((h) => h.inspectionId == inspection.inspectionId)
                        .firstOrNull;

                    if (history == null || history.reportLink.isEmpty) {
                      if (context.mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text(
                              'PDF report not yet available for this inspection.',
                            ),
                            backgroundColor: Colors.orange,
                          ),
                        );
                      }
                      return;
                    }

                    final uri = Uri.parse(history.reportLink);
                    if (await canLaunchUrl(uri)) {
                      await launchUrl(
                        uri,
                        mode: LaunchMode.externalApplication,
                      );
                    } else {
                      if (context.mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text('Could not open the PDF link.'),
                            backgroundColor: Colors.red,
                          ),
                        );
                      }
                    }
                  } catch (e) {
                    if (context.mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text('Error loading PDF: $e'),
                          backgroundColor: Colors.red,
                        ),
                      );
                    }
                  }
                },
              ),
              const SizedBox(height: 24),
            ],
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    ref.watch(holidayProvider);

    final state = ref.watch(superintendentDashControllerProvider);
    final hasFailedItems = state.failedInspections.isNotEmpty;

    return DefaultTabController(
      length: 2,
      child: Scaffold(
        backgroundColor: Colors.grey[100],
        appBar: AppBar(
          title: const Text("Dashboard"),
          backgroundColor: const Color(0xFF003366),
          foregroundColor: Colors.white,
          actions: [
            Showcase(
              key: _helpKey,
              description: 'Need help? Tap here for tutorials and guides.',
              child: IconButton(
                icon: const Icon(Icons.help_outline, color: Colors.white),
                tooltip: 'Help & Tutorials',
                onPressed: () => _showHelpMenu(context),
              ),
            ),
            const SizedBox(width: 8),
          ],
          bottom: TabBar(
            labelColor: Colors.white,
            unselectedLabelColor: Colors.white60,
            indicatorColor: Colors.orange,
            indicatorWeight: 4,
            tabs: [
              Showcase(
                key: _scheduleTabKey,
                title: 'Schedule',
                description:
                    'This tab will show all your upcoming inspections scheduled for the next 7 days.',
                child: const Tab(
                  text: 'SCHEDULE',
                  icon: Icon(Icons.calendar_month),
                ),
              ),
              Showcase(
                key: _actionBoardTabKey,
                title: 'Action Board',
                description:
                    'This tab will show you all your current addresses that have a failed inspection and NO scheduled reinspection.',
                child: !hasFailedItems
                    ? const Tab(
                        text: 'ACTION BOARD',
                        icon: Icon(Icons.check_circle_outline),
                      )
                    : Tab(
                        icon: AnimatedBuilder(
                          animation: _animationController,
                          builder: (context, child) {
                            return Icon(
                              Icons.warning_amber_rounded,
                              color: Color.lerp(
                                Colors.white,
                                Colors.redAccent,
                                _animationController.value,
                              ),
                            );
                          },
                        ),
                        child: AnimatedBuilder(
                          animation: _animationController,
                          builder: (context, child) {
                            return Text(
                              'ACTION BOARD',
                              style: TextStyle(
                                color: Color.lerp(
                                  Colors.white,
                                  Colors.redAccent,
                                  _animationController.value,
                                ),
                                fontWeight: FontWeight.bold,
                              ),
                            );
                          },
                        ),
                      ),
              ),
            ],
          ),
        ),
        floatingActionButton: Showcase(
          key: _fabKey,
          title: 'New Inspection / Location',
          description: 'Tap here to add a new inspection or home.',
          child: FloatingActionButton.extended(
            onPressed: () => _showAddOptions(context),
            backgroundColor: const Color(0xFFF27D00),
            foregroundColor: Colors.white,
            elevation: 4,
            icon: const Icon(Icons.add),
            label: const Text(
              'NEW',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
          ),
        ),
        body: state.isLoading
            ? const Center(child: CircularProgressIndicator())
            : RefreshIndicator(
                onRefresh: () => ref
                    .read(superintendentDashControllerProvider.notifier)
                    .syncDashboard(),
                child: TabBarView(
                  children: [
                    _buildInspectionList(
                      context,
                      state.upcomingInspections,
                      "No inspections scheduled for the next 7 days.",
                      isActionBoard: false,
                    ),
                    _buildInspectionList(
                      context,
                      state.failedInspections,
                      "No failed inspections. Great job!",
                      isActionBoard: true,
                    ),
                  ],
                ),
              ),
      ),
    );
  }

  // --- HELPER: Status Chip ---
  Widget _buildStatusChip(Inspection inspection, bool isActionBoard) {
    Color bgColor;
    Color textColor;
    String label;

    if (isActionBoard) {
      bgColor = Colors.red.shade100;
      textColor = Colors.red.shade900;
      label = 'FAILED';
    } else if (inspection.inspectionStatusId == 11) {
      bgColor = Colors.orange.shade100;
      textColor = Colors.orange.shade900;
      label = 'PENDING';
    } else {
      bgColor = Colors.green.shade100;
      textColor = Colors.green.shade900;
      label = 'SCHEDULED';
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(6),
      ),
      child: Text(
        label,
        style: TextStyle(
          color: textColor,
          fontSize: 12,
          fontWeight: FontWeight.bold,
          letterSpacing: 0.5,
        ),
      ),
    );
  }

  // --- HELPER: Date Header ---
  Widget _buildDateHeader(DateTime? date) {
    if (date == null) {
      return _headerText('Unscheduled');
    }

    final now = DateTime.now();
    String label;

    if (DateUtils.isSameDay(date, now)) {
      label = 'Today';
    } else if (DateUtils.isSameDay(date, now.add(const Duration(days: 1)))) {
      label = 'Tomorrow';
    } else {
      label = DateFormat('EEEE, MMM d').format(date);
    }

    return _headerText(label);
  }

  Widget _headerText(String label) {
    return Padding(
      padding: const EdgeInsets.only(top: 16.0, bottom: 8.0, left: 4.0),
      child: Text(
        label,
        style: TextStyle(
          fontSize: 18,
          fontWeight: FontWeight.bold,
          color: Colors.blueGrey[900],
          letterSpacing: 0.5,
        ),
      ),
    );
  }

  // --- HELPER: List Builder ---
  Widget _buildInspectionList(
    BuildContext context,
    List<Inspection> inspections,
    String emptyMessage, {
    required bool isActionBoard,
  }) {
    if (inspections.isEmpty) {
      return ListView(
        children: [
          SizedBox(height: MediaQuery.of(context).size.height * 0.3),
          Center(
            child: Text(
              emptyMessage,
              style: TextStyle(color: Colors.grey[600], fontSize: 16),
            ),
          ),
        ],
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(12),
      itemCount: inspections.length,
      itemBuilder: (context, index) {
        final inspection = inspections[index];
        final dateStr = inspection.inspectionDate != null
            ? DateFormat('EEE, MMM d').format(inspection.inspectionDate!)
            : 'Unscheduled';

        bool showHeader = false;
        if (!isActionBoard) {
          if (index == 0) {
            showHeader = true;
          } else {
            final prevInspection = inspections[index - 1];
            showHeader = !DateUtils.isSameDay(
              inspection.inspectionDate,
              prevInspection.inspectionDate,
            );
          }
        }

        final communityName = inspection.community ?? 'Unknown Community';
        final lotNumber = inspection.lotNumber ?? '';

        final card = Card(
          elevation: 0,
          margin: const EdgeInsets.only(bottom: 12),
          shape: RoundedRectangleBorder(
            side: BorderSide(
              color: isActionBoard
                  ? Colors.red.withValues(alpha: 0.4)
                  : Colors.grey.withValues(alpha: 0.2),
              width: 1,
            ),
            borderRadius: BorderRadius.circular(12),
          ),
          child: InkWell(
            borderRadius: BorderRadius.circular(12),
            onTap: () {
              if (isActionBoard) {
                _showActionBoardOptions(context, inspection);
              } else {
                _showScheduleOptions(context, inspection);
              }
            },
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // --- ROW 1: Community & Status Chip ---
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(
                        child: Text(
                          lotNumber.isNotEmpty
                              ? '$communityName - Lot $lotNumber'
                              : communityName,
                          style: TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w700,
                            color: Colors.blue[900],
                            letterSpacing: 0.3,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      const SizedBox(width: 8),
                      _buildStatusChip(inspection, isActionBoard),
                    ],
                  ),
                  const SizedBox(height: 8),

                  // --- ROW 2: Address ---
                  Text(
                    inspection.address ?? 'Unknown Address',
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 18,
                    ),
                  ),
                  const SizedBox(height: 4),

                  // --- ROW 3: Inspection Type ---
                  Text(
                    inspection.inspectionType ?? 'General Inspection',
                    style: TextStyle(color: Colors.grey[700], fontSize: 15),
                  ),
                  const SizedBox(height: 12),
                  const Divider(height: 1),
                  const SizedBox(height: 12),

                  // --- ROW 4: Date Info & Context Action Icon ---
                  Row(
                    children: [
                      Icon(
                        isActionBoard
                            ? Icons.warning_amber_rounded
                            : Icons.calendar_today,
                        size: 16,
                        color: isActionBoard
                            ? Colors.red[700]
                            : Colors.grey[600],
                      ),
                      const SizedBox(width: 6),
                      Text(
                        isActionBoard ? "Failed on $dateStr" : dateStr,
                        style: TextStyle(
                          color: isActionBoard
                              ? Colors.red[700]
                              : Colors.grey[700],
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const Spacer(),
                      // Three dots on the Schedule tab, chevron on the Action Board
                      Icon(
                        isActionBoard ? Icons.chevron_right : Icons.more_vert,
                        color: Colors.grey[500],
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        );

        if (showHeader) {
          return Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            mainAxisSize: MainAxisSize.min,
            children: [_buildDateHeader(inspection.inspectionDate), card],
          );
        }

        return card;
      },
    );
  }

  // --- HELPER: Help Menu Bottom Sheet ---
  void _showHelpMenu(BuildContext context) {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (BuildContext bottomSheetContext) {
        return SafeArea(
          child: Wrap(
            children: [
              Padding(
                padding: const EdgeInsets.all(16.0),
                child: Text(
                  'Tutorials & Help',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Colors.blueGrey[900],
                  ),
                ),
              ),
              ListTile(
                leading: CircleAvatar(
                  backgroundColor: Colors.teal[50],
                  child: Icon(Icons.tour, color: Colors.teal[700]),
                ),
                title: const Text(
                  'Dashboard Tour',
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
                subtitle: const Text(
                  'Learn how to use the Action Board and Schedule.',
                ),
                onTap: () {
                  Navigator.pop(bottomSheetContext);
                  ShowcaseView.get().startShowCase([
                    _scheduleTabKey,
                    _actionBoardTabKey,
                    _fabKey,
                  ]);
                },
              ),
              ListTile(
                leading: CircleAvatar(
                  backgroundColor: Colors.indigo[50],
                  child: Icon(Icons.menu_open, color: Colors.indigo[700]),
                ),
                title: const Text(
                  'App Menu Tour',
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
                subtitle: const Text(
                  'Learn about the main navigation options.',
                ),
                onTap: () {
                  Navigator.pop(bottomSheetContext);
                  ref.read(drawerTutorialTriggerProvider.notifier).trigger();
                  Scaffold.of(context).openDrawer();
                },
              ),
              const SizedBox(height: 24),
            ],
          ),
        );
      },
    );
  }
}
