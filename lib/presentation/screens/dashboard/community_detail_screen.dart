import 'package:flutter/material.dart';
import '../../../core/models/inspection/inspection.dart';
import 'stats_controller.dart'; // Import for ResolutionHelper

class CommunityDetailScreen extends StatelessWidget {
  final String communityName;
  final List<Inspection> allInspections;

  const CommunityDetailScreen({
    super.key,
    required this.communityName,
    required this.allInspections,
  });

  @override
  Widget build(BuildContext context) {
    // 1. Filter inspections for this community only
    final communityInspections = allInspections
        .where((i) => i.community == communityName)
        .toList();

    // 2. Calculate Overall Stats for Header
    int passedCount = 0;
    int validCount = 0;

    for (var i in communityInspections) {
      final status = ResolutionHelper.classify(i.resolution);
      if (status == InspectionStatus.pass) {
        passedCount++;
        validCount++;
      } else if (status == InspectionStatus.fail) {
        validCount++;
      }
    }

    final passRate = validCount == 0 ? 0.0 : (passedCount / validCount) * 100;

    // 3. GROUP BY INSPECTION TYPE ID
    final Map<dynamic, List<Inspection>> typeBuckets = {};

    for (var i in communityInspections) {
      final id = i.inspectionTypeId;
      if (id != null) {
        if (!typeBuckets.containsKey(id)) {
          typeBuckets[id] = [];
        }
        typeBuckets[id]!.add(i);
      }
    }

    // Convert map to list and calculate stats per type
    final typeStats = typeBuckets.entries.map((entry) {
      final items = entry.value;

      // Calculate Rate
      int tPassed = 0;
      int tValid = 0;
      for (var i in items) {
        final status = ResolutionHelper.classify(i.resolution);
        if (status == InspectionStatus.pass) {
          tPassed++;
          tValid++;
        } else if (status == InspectionStatus.fail) {
          tValid++;
        }
      }

      final tRate = tValid == 0 ? 0.0 : (tPassed / tValid) * 100;

      // Display Name (Clean)
      String rawName = items.first.inspectionType ?? "Unknown";
      String cleanName = _cleanTypeName(rawName);

      // Sort detailed items by date (newest first)
      items.sort(
        (a, b) => (b.inspectionDate ?? DateTime.now()).compareTo(
          a.inspectionDate ?? DateTime.now(),
        ),
      );

      return {
        'type': cleanName,
        'rate': tRate,
        'count': tValid,
        'totalAttempts': items.length,
        'inspections': items, // <--- We now keep the list of items attached
      };
    }).toList();

    // Sort: Lowest Pass Rate first
    typeStats.sort(
      (a, b) => (a['rate'] as double).compareTo(b['rate'] as double),
    );

    return Scaffold(
      backgroundColor: Colors.grey[100],
      appBar: AppBar(
        title: Text(communityName),
        backgroundColor: Colors.white,
        elevation: 0,
        foregroundColor: Colors.black,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // HEADER CARD
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Colors.blue[900],
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    "Overall Health",
                    style: TextStyle(color: Colors.white, fontSize: 16),
                  ),
                  Text(
                    "${passRate.toStringAsFixed(1)}%",
                    style: TextStyle(
                      color: _getColorForRate(passRate),
                      fontSize: 28,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),

            // SECTION 1: BREAKDOWN BY INSPECTION TYPE (EXPANDABLE)
            const Text(
              "Performance by Inspection Type",
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),

            if (typeStats.isEmpty)
              const Padding(
                padding: EdgeInsets.all(8.0),
                child: Text("No inspections found."),
              ),

            ListView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: typeStats.length,
              itemBuilder: (context, index) {
                final stat = typeStats[index];
                final double rate = stat['rate'] as double;
                final int count = stat['totalAttempts'] as int;
                final String groupName = stat['type'] as String;
                final List<Inspection> groupItems =
                    stat['inspections'] as List<Inspection>;

                return Card(
                  margin: const EdgeInsets.only(bottom: 8),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Theme(
                    // Hides the divider line when expanded for a cleaner look
                    data: Theme.of(
                      context,
                    ).copyWith(dividerColor: Colors.transparent),
                    child: ExpansionTile(
                      // HEADER: Clean Name + Stats
                      title: Row(
                        children: [
                          Expanded(
                            child: Text(
                              groupName,
                              style: const TextStyle(
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                          // Pass Rate Pill
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 10,
                              vertical: 4,
                            ),
                            decoration: BoxDecoration(
                              color: _getColorForRate(rate).withOpacity(0.1),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Text(
                              "${rate.toStringAsFixed(0)}%",
                              style: TextStyle(
                                color: _getColorForRate(rate),
                                fontWeight: FontWeight.bold,
                                fontSize: 12,
                              ),
                            ),
                          ),
                        ],
                      ),
                      subtitle: Text(
                        "$count inspections",
                        style: TextStyle(color: Colors.grey[600]),
                      ),
                      // EXPANDED BODY: Individual Items
                      children: groupItems.map((i) {
                        return Container(
                          decoration: BoxDecoration(
                            border: Border(
                              top: BorderSide(color: Colors.grey[100]!),
                            ),
                            color: Colors
                                .grey[50], // Slight background for nested items
                          ),
                          child: ListTile(
                            dense: true,
                            leading: _getStatusIcon(i.resolution),
                            title: Text(
                              // Show full name with the suffix (e.g. "Frame - 2")
                              i.inspectionType ?? "Unknown",
                              style: const TextStyle(
                                fontWeight: FontWeight.w600,
                                fontSize: 13,
                              ),
                            ),
                            subtitle: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(i.address ?? "No Address"),
                                Text(
                                  "${i.resolution} • ${_formatDate(i.inspectionDate)}",
                                  style: TextStyle(
                                    color: Colors.grey[500],
                                    fontSize: 11,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        );
                      }).toList(),
                    ),
                  ),
                );
              },
            ),

            const SizedBox(height: 24),

            // SECTION 2: RECENT FAILS
            const Text(
              "Recent Fails",
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            _buildRecentFailsList(communityInspections),
          ],
        ),
      ),
    );
  }

  // --- HELPERS ---

  String _cleanTypeName(String name) {
    return name.replaceAll(RegExp(r'\s*-\s*\d+$'), '');
  }

  Widget _buildRecentFailsList(List<Inspection> inspections) {
    final fails = inspections
        .where(
          (i) =>
              ResolutionHelper.classify(i.resolution) == InspectionStatus.fail,
        )
        .toList();

    fails.sort(
      (a, b) => (b.inspectionDate ?? DateTime.now()).compareTo(
        a.inspectionDate ?? DateTime.now(),
      ),
    );

    final recentFails = fails.take(10).toList();

    if (recentFails.isEmpty) {
      return const Card(
        child: Padding(
          padding: EdgeInsets.all(16.0),
          child: Text("No recent failures!"),
        ),
      );
    }

    return Column(
      children: recentFails.map((i) {
        return Card(
          elevation: 0,
          margin: const EdgeInsets.only(bottom: 8),
          shape: RoundedRectangleBorder(
            side: BorderSide(color: Colors.red.withOpacity(0.3)),
            borderRadius: BorderRadius.circular(8),
          ),
          child: ListTile(
            leading: const Icon(Icons.warning_amber_rounded, color: Colors.red),
            title: Text(i.address ?? "Unknown Address"),
            subtitle: Text(
              "${_cleanTypeName(i.inspectionType ?? '')} • ${i.resolution}",
            ),
            trailing: Text(
              _formatDate(i.inspectionDate),
              style: const TextStyle(color: Colors.grey, fontSize: 12),
            ),
          ),
        );
      }).toList(),
    );
  }

  Widget _getStatusIcon(String? resolution) {
    final status = ResolutionHelper.classify(resolution);
    if (status == InspectionStatus.pass) {
      return const Icon(Icons.check_circle, color: Colors.green, size: 20);
    }
    if (status == InspectionStatus.fail) {
      return const Icon(Icons.cancel, color: Colors.red, size: 20);
    }
    if (status == InspectionStatus.cancelNoFee ||
        status == InspectionStatus.cancelFee) {
      return const Icon(Icons.pause_circle, color: Colors.orange, size: 20);
    }
    return const Icon(Icons.help, color: Colors.grey, size: 20);
  }

  Color _getColorForRate(double rate) {
    if (rate >= 85) return Colors.green;
    if (rate < 70) return Colors.red;
    return Colors.orange;
  }

  String _formatDate(DateTime? date) {
    if (date == null) return "";
    return "${date.month}/${date.day}";
  }
}
