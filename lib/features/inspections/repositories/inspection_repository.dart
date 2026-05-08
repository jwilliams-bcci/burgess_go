import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:rxdart/rxdart.dart';

import 'package:burgess_go/core/providers/service_providers.dart';
import 'package:burgess_go/core/services/logging_service.dart';
import 'package:burgess_go/core/models/user/user_profile.dart';
import 'package:burgess_go/core/models/inspection/inspection.dart';
import 'package:burgess_go/core/models/inspection/submission_detail.dart';

// --- PROVIDER ---
final inspectionRepositoryProvider = Provider<IInspectionRepository>((ref) {
  final logger = ref.watch(loggingServiceProvider);
  return InspectionRepository(
    firestore: FirebaseFirestore.instance,
    logger: logger,
  );
});

// --- INTERFACE ---
abstract class IInspectionRepository {
  Stream<List<Inspection>> watchInspectionsForUser(UserProfile user);
  Future<Inspection?> getInspection(int inspectionId);
  Future<List<Inspection>> getInspectionsByLocation(int locationId);
  Stream<List<Inspection>> watchInspectionsByLocation(int locationId);
  Stream<List<SubmissionDetail>> watchDefects(int inspectionId);
  Future<void> updateDefectStatus(
    int inspectionId,
    String defectId,
    int newStatus,
  );
}

// --- REPOSITORY ---
class InspectionRepository extends IInspectionRepository {
  final FirebaseFirestore _db;
  final ILoggingService _logger;

  InspectionRepository({
    required FirebaseFirestore firestore,
    required ILoggingService logger,
  }) : _db = firestore,
       _logger = logger;

  @override
  Stream<List<Inspection>> watchInspectionsForUser(UserProfile user) {
    final cutoffDate = DateTime.now().subtract(const Duration(days: 180));

    return _db
        .collection('inspections')
        .where('allowedUserIds', arrayContains: user.securityUserId)
        .where('inspectionDate', isGreaterThan: cutoffDate)
        .snapshots()
        .map((snapshot) {
          final inspections = snapshot.docs
              .map((doc) => Inspection.fromFirestore(doc))
              .toList();

          // Sort the final list by date descending
          inspections.sort(
            (a, b) => (b.inspectionDate ?? DateTime(2000)).compareTo(
              a.inspectionDate ?? DateTime(2000),
            ),
          );

          return inspections;
        });
  }

  @override
  Future<Inspection?> getInspection(int inspectionId) async {
    final doc = await _db
        .collection('inspections')
        .doc(inspectionId.toString())
        .get();
    if (doc.exists) {
      return Inspection.fromFirestore(doc);
    }
    return null;
  }

  @override
  Future<List<Inspection>> getInspectionsByLocation(int locationId) async {
    try {
      final snapshot = await _db
          .collection('inspections')
          .where('locationId', isEqualTo: locationId)
          .get();

      final inspections = snapshot.docs
          .map((doc) => Inspection.fromFirestore(doc))
          .toList();

      // Sort by date descending so the newest inspections are at the top
      inspections.sort(
        (a, b) => (b.inspectionDate ?? DateTime(2000)).compareTo(
          a.inspectionDate ?? DateTime(2000),
        ),
      );

      return inspections;
    } catch (e, stackTrace) {
      _logger.error(
        "Error fetching inspections for location $locationId: $e",
        error: e,
        stackTrace: stackTrace,
      );
      return [];
    }
  }

  @override
  Stream<List<Inspection>> watchInspectionsByLocation(int locationId) {
    return _db
        .collection('inspections')
        .where('locationId', isEqualTo: locationId)
        .snapshots()
        .map((snapshot) {
          final inspections = snapshot.docs
              .map((doc) => Inspection.fromFirestore(doc))
              .toList();

          // Sort by date descending so newest are on top
          inspections.sort(
            (a, b) => (b.inspectionDate ?? DateTime(2000)).compareTo(
              a.inspectionDate ?? DateTime(2000),
            ),
          );

          return inspections;
        });
  }

  @override
  Stream<List<SubmissionDetail>> watchDefects(int inspectionId) {
    return _db
        .collection('inspections')
        .doc(inspectionId.toString())
        .collection('submissionDetails')
        .snapshots()
        .map((snapshot) {
          return snapshot.docs
              .map((doc) => SubmissionDetail.fromFirestore(doc))
              .toList();
        });
  }

  @override
  Future<void> updateDefectStatus(
    int inspectionId,
    String defectId,
    int newStatus,
  ) async {
    _logger.info(
      "Updating defect $defectId in inspection $inspectionId to status $newStatus",
    );
    await _db
        .collection('inspections')
        .doc(inspectionId.toString())
        .collection('submissionDetails')
        .doc(defectId)
        .update({'detailStatusId': newStatus});
  }
}
