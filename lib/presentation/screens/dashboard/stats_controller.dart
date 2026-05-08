import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/legacy.dart';
import '../../../core/models/inspection/inspection.dart';

// --- ENUMS ---
enum DateRange { thisWeek, thisMonth, last90Days, allTime }

// --- MODELS ---
class CommunityStats {
  final String name;
  final double passRate;
  final double avgDefectsPerInspection;
  final double avgDaysToPass;

  CommunityStats({
    required this.name,
    required this.passRate,
    required this.avgDefectsPerInspection,
    required this.avgDaysToPass,
  });
}

class SuperintendentStats {
  final String name;
  final int total;
  final int passed;
  final int failed;
  final int cancelled;

  SuperintendentStats({
    required this.name,
    required this.total,
    required this.passed,
    required this.failed,
    required this.cancelled,
  });

  double get passRate {
    int valid = passed + failed;
    if (valid == 0) return 0.0;
    return (passed / valid) * 100;
  }
}

class DashboardStats {
  final int totalInspections;
  final int passedCount;
  final int failedCount;
  final int cancelledCount;
  final double passRate;
  final List<CommunityStats> communityStats;
  final List<SuperintendentStats> superintendentStats;

  DashboardStats({
    required this.totalInspections,
    required this.passedCount,
    required this.failedCount,
    required this.cancelledCount,
    required this.passRate,
    required this.communityStats,
    required this.superintendentStats,
  });

  factory DashboardStats.empty() {
    return DashboardStats(
      totalInspections: 0,
      passedCount: 0,
      failedCount: 0,
      cancelledCount: 0,
      passRate: 0.0,
      communityStats: [],
      superintendentStats: [],
    );
  }
}

// --- CONTROLLER ---
class StatsController extends StateNotifier<AsyncValue<DashboardStats>> {
  StatsController() : super(const AsyncValue.loading());

  void calculateStats(List<Inspection> allInspections, DateRange range) {
    // 1. FILTER BY DATE RANGE
    List<Inspection> inspections = _filterByDate(allInspections, range);

    if (inspections.isEmpty) {
      state = AsyncValue.data(DashboardStats.empty());
      return;
    }

    // 2. GLOBAL COUNTERS
    int total = inspections.length;
    int passed = 0;
    int failed = 0;
    int cancelled = 0;

    // 3. BUCKETS
    final Map<String, List<Inspection>> communityBuckets = {};
    final Map<String, List<Inspection>> superBuckets = {};
    final Map<String, List<Inspection>> lifecycleBuckets = {};

    for (var i in inspections) {
      // Classify Status
      final status = ResolutionHelper.classify(i.resolution);
      if (status == InspectionStatus.pass)
        passed++;
      else if (status == InspectionStatus.fail)
        failed++;
      else
        cancelled++;

      // Bucket by Community
      final commName = i.community ?? "Unknown";
      if (!communityBuckets.containsKey(commName))
        communityBuckets[commName] = [];
      communityBuckets[commName]!.add(i);

      // Bucket by Superintendent
      final superName = (i.superName == null || i.superName!.isEmpty)
          ? "Unassigned"
          : i.superName!;
      if (!superBuckets.containsKey(superName)) superBuckets[superName] = [];
      superBuckets[superName]!.add(i);

      // Bucket by Lifecycle
      final lifecycleKey = "${i.locationId}_${i.inspectionTypeId}";
      if (!lifecycleBuckets.containsKey(lifecycleKey))
        lifecycleBuckets[lifecycleKey] = [];
      lifecycleBuckets[lifecycleKey]!.add(i);
    }

    // 4. COMMUNITY STATS
    List<CommunityStats> commStatsList = [];
    communityBuckets.forEach((name, items) {
      int cPass = 0;
      int cFail = 0;
      double totalDefects = 0;

      for (var i in items) {
        final status = ResolutionHelper.classify(i.resolution);
        if (status == InspectionStatus.pass) cPass++;
        if (status == InspectionStatus.fail) cFail++;

        if (status == InspectionStatus.pass ||
            status == InspectionStatus.fail) {
          totalDefects += (i.submission?.inspectionTotal ?? 0);
        }
      }

      int cValid = cPass + cFail;
      double cRate = cValid == 0 ? 0.0 : (cPass / cValid) * 100;
      double cAvgDefects = cValid == 0 ? 0.0 : totalDefects / cValid;

      // Cycle Time Logic
      double totalDays = 0;
      int measuredCycles = 0;
      Set<String> localLifecycleKeys = items
          .map((i) => "${i.locationId}_${i.inspectionTypeId}")
          .toSet();

      for (var key in localLifecycleKeys) {
        final cycle = lifecycleBuckets[key]!;
        final passItem = cycle.firstWhere(
          (i) =>
              ResolutionHelper.classify(i.resolution) == InspectionStatus.pass,
          orElse: () => Inspection(
            inspectionId: -1,
            inspectionDate: DateTime.now(),
            fromCache: false,
          ),
        );

        if (passItem.inspectionId != -1) {
          cycle.sort(
            (a, b) => (a.inspectionDate ?? DateTime.now()).compareTo(
              b.inspectionDate ?? DateTime.now(),
            ),
          );
          final firstItem = cycle.first;
          if (passItem.inspectionDate != null &&
              firstItem.inspectionDate != null) {
            totalDays += passItem.inspectionDate!
                .difference(firstItem.inspectionDate!)
                .inDays;
            measuredCycles++;
          }
        }
      }
      double cAvgDays = measuredCycles == 0 ? 0.0 : totalDays / measuredCycles;

      commStatsList.add(
        CommunityStats(
          name: name,
          passRate: cRate,
          avgDefectsPerInspection: cAvgDefects,
          avgDaysToPass: cAvgDays,
        ),
      );
    });
    commStatsList.sort((a, b) => a.passRate.compareTo(b.passRate));

    // 5. SUPERINTENDENT STATS
    List<SuperintendentStats> superStatsList = [];
    superBuckets.forEach((name, items) {
      int sPass = 0;
      int sFail = 0;
      int sCancel = 0;

      for (var i in items) {
        final status = ResolutionHelper.classify(i.resolution);
        if (status == InspectionStatus.pass)
          sPass++;
        else if (status == InspectionStatus.fail)
          sFail++;
        else
          sCancel++;
      }

      superStatsList.add(
        SuperintendentStats(
          name: name,
          total: items.length,
          passed: sPass,
          failed: sFail,
          cancelled: sCancel,
        ),
      );
    });
    superStatsList.sort((a, b) => b.total.compareTo(a.total));

    state = AsyncValue.data(
      DashboardStats(
        totalInspections: total,
        passedCount: passed,
        failedCount: failed,
        cancelledCount: cancelled,
        passRate: (passed + failed) == 0
            ? 0
            : (passed / (passed + failed)) * 100,
        communityStats: commStatsList,
        superintendentStats: superStatsList,
      ),
    );
  }

  // --- FILTER LOGIC ---
  List<Inspection> _filterByDate(List<Inspection> list, DateRange range) {
    if (range == DateRange.allTime) return list;

    final now = DateTime.now();
    DateTime start;

    switch (range) {
      case DateRange.thisWeek:
        // Find last Monday (or today if it's Monday)
        start = now.subtract(Duration(days: now.weekday - 1));
        // Reset to midnight
        start = DateTime(start.year, start.month, start.day);
        break;
      case DateRange.thisMonth:
        start = DateTime(now.year, now.month, 1);
        break;
      case DateRange.last90Days:
        start = now.subtract(const Duration(days: 90));
        start = DateTime(start.year, start.month, start.day);
        break;
      case DateRange.allTime:
        return list;
    }

    return list.where((i) {
      if (i.inspectionDate == null) return false;
      return i.inspectionDate!.isAfter(start) ||
          i.inspectionDate!.isAtSameMomentAs(start);
    }).toList();
  }
}

// --- PROVIDER ---
final statsProvider =
    StateNotifierProvider<StatsController, AsyncValue<DashboardStats>>((ref) {
      return StatsController();
    });

// --- HELPERS ---
enum InspectionStatus { pass, fail, cancelNoFee, cancelFee, other }

class ResolutionHelper {
  static InspectionStatus classify(String? resolution) {
    if (resolution == null) return InspectionStatus.other;
    final res = resolution.trim().toLowerCase();

    if (res == 'passed' || res == 'performed' || res == 'correct & proceed')
      return InspectionStatus.pass;
    if (res == 'failed' || res == 'not ready') return InspectionStatus.fail;
    if (res.contains('cancelled before') || res.contains('deferred'))
      return InspectionStatus.cancelNoFee;
    if (res.contains('cancelled in field')) return InspectionStatus.cancelFee;

    return InspectionStatus.other;
  }
}
