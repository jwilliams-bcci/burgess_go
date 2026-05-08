import 'package:burgess_go/features/auth/controllers/auth_controller.dart';
import 'package:burgess_go/core/models/inspection/inspection.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../controllers/superintendent_dash_controller.dart';
import 'package:intl/intl.dart';

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

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    )..repeat(reverse: true);
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
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
                  backgroundColor: Colors.blue[100],
                  child: Icon(Icons.home_work, color: Colors.blue[900]),
                ),
                title: const Text(
                  'Add New Location',
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
                  'Request an inspection for an existing location',
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

  @override
  Widget build(BuildContext context) {
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
            // Note: Since Firestore streams are real-time, you might not even need this sync button anymore!
            IconButton(
              icon: const Icon(Icons.sync),
              onPressed: () => ref
                  .read(superintendentDashControllerProvider.notifier)
                  .syncDashboard(),
            ),
            IconButton(
              icon: const Icon(Icons.logout),
              onPressed: () =>
                  ref.read(authControllerProvider.notifier).logout(),
            ),
          ],
          bottom: TabBar(
            labelColor: Colors.white,
            unselectedLabelColor: Colors.white60,
            indicatorColor: Colors.orange,
            indicatorWeight: 4,
            tabs: [
              const Tab(text: 'SCHEDULE', icon: Icon(Icons.calendar_month)),
              if (!hasFailedItems)
                const Tab(
                  text: 'ACTION BOARD',
                  icon: Icon(Icons.check_circle_outline),
                )
              else
                Tab(
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
            ],
          ),
        ),
        floatingActionButton: FloatingActionButton.extended(
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
        body: state.isLoading
            ? const Center(child: CircularProgressIndicator())
            : RefreshIndicator(
                onRefresh: () => ref
                    .read(superintendentDashControllerProvider.notifier)
                    .syncDashboard(),
                child: TabBarView(
                  children: [
                    // 🔥 locationMetadata map is GONE!
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

        // 🔥 Look how simple this is now! Direct from the Inspection object.
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
              context.go('/location/${inspection.locationId}');
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

                  // --- ROW 4: Date Info ---
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
                      Icon(Icons.chevron_right, color: Colors.grey[400]),
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
}
