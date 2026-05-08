import 'package:burgess_go/core/models/inspection/inspection.dart';
import 'package:burgess_go/core/models/inspection/submission_detail.dart';
import 'package:burgess_go/core/models/location/location.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:rxdart/rxdart.dart';
import 'dart:async';
import '../core/models/user/user_profile.dart';

class FirestoreService {
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  /// Main Dashboard Query: Fetches inspections based on the user's scope.
  Stream<List<Inspection>> getInspectionsForUser(UserProfile user) {
    CollectionReference inspectionsRef = _db.collection('inspections');
    Query baseQuery = inspectionsRef;

    // --- 1. COMMUNITY STREAM (The "Broad" Access) ---
    Stream<List<Inspection>> communityStream = Stream.value([]);

    if (user.communityIds.isNotEmpty) {
      if (user.communityIds.length <= 10) {
        final cutoffDate = DateTime.now().subtract(const Duration(days: 180));

        communityStream = baseQuery
            .where('communityId', whereIn: user.communityIds)
            .where('inspectionDate', isGreaterThan: cutoffDate) // <--- ADD THIS
            .orderBy('inspectionDate', descending: true)
            .snapshots()
            .map(_mapQuerySnapshotToInspections);
      } else {
        // Handle >10 items chunking logic
        communityStream = _getChunkedInspections(
          field: 'communityId',
          values: user.communityIds,
          baseQuery: baseQuery,
        );
      }
    }
    // Fallback to Division/Builder if no communities
    else if (user.divisionIds.isNotEmpty) {
      communityStream = baseQuery
          .where('divisionId', whereIn: user.divisionIds.take(10).toList())
          .orderBy('inspectionDate', descending: true)
          .snapshots()
          .map(_mapQuerySnapshotToInspections);
    } else if (user.builderIds.isNotEmpty) {
      communityStream = baseQuery
          .where('builderId', whereIn: user.builderIds)
          .snapshots()
          .map(_mapQuerySnapshotToInspections);
    }

    // --- 2. LOCATION OVERRIDE STREAM (The "Exception" Access) ---
    Stream<List<Inspection>> locationOverrideStream = Stream.value([]);

    if (user.locationIds.isNotEmpty) {
      print("🔍 Debug: Querying specific locations: ${user.locationIds}");

      locationOverrideStream = baseQuery
          .where('locationId', whereIn: user.locationIds)
          .orderBy('inspectionDate', descending: true)
          .snapshots()
          .map((snap) {
            print(
              "🔍 Debug: Found ${snap.docs.length} location-specific inspections",
            );
            return _mapQuerySnapshotToInspections(snap);
          });
    }

    // --- 3. MERGE THE STREAMS ---
    // startWith([]) ensures the UI loads even if one stream is waiting
    return Rx.combineLatest2<
      List<Inspection>,
      List<Inspection>,
      List<Inspection>
    >(communityStream.startWith([]), locationOverrideStream.startWith([]), (
      communityInspections,
      locationInspections,
    ) {
      // FIXME: BUG - RACE CONDITION IN STREAM MERGE
      // The Community Stream and Location Stream can return the same inspection.
      // If one stream returns "stale" data (null startTime) and the other returns "fresh" data,
      // the current logic blindly overwrites or duplicates, causing UI flickering (Green -> Blue).
      // TODO: Implement "Smart Merging" to check editDate/startTime before overwriting.

      // 1. Start with the Community Map
      final Map<int, Inspection> mergedMap = {};
      for (var item in communityInspections) {
        mergedMap[item.inspectionId] = item;
      }

      // 2. carefully merge Location items
      for (var newItem in locationInspections) {
        if (mergedMap.containsKey(newItem.inspectionId)) {
          final existingItem = mergedMap[newItem.inspectionId]!;

          // --- SMART CHECK: Who has the better data? ---

          // Check 1: Does the new one have a start time?
          bool newHasStart = newItem.submission?.startTime != null;
          bool existingHasStart = existingItem.submission?.startTime != null;

          // If the existing one has data, but the new one is null, KEEP the existing one!
          // (This prevents the 'Stale' stream from overwriting the 'Fresh' stream)
          if (existingHasStart && !newHasStart) {
            continue; // Skip overwriting
          }

          // Check 2: (Optional) Compare editDate if available
          DateTime existingDate = existingItem.editDate ?? DateTime(2000);
          DateTime newDate = newItem.editDate ?? DateTime(2000);
          if (existingDate.isAfter(newDate)) {
            continue; // Existing is newer, don't overwrite
          }
        }

        // If we passed the checks (or it didn't exist yet), add/overwrite it
        mergedMap[newItem.inspectionId] = newItem;
      }

      // 3. Convert back to list and sort
      final uniqueList = mergedMap.values.toList();
      uniqueList.sort(
        (a, b) => (b.inspectionDate ?? DateTime.now()).compareTo(
          a.inspectionDate ?? DateTime.now(),
        ),
      );

      return uniqueList;
    });
  }

  /// Fetches the specific defects (Submission Details) for a single inspection.
  /// This is called only when the user taps on a card.
  Future<List<SubmissionDetail>> getSubmissionDetails(
    String inspectionId,
  ) async {
    try {
      final snapshot = await _db
          .collection('inspections')
          .doc(inspectionId)
          .collection(
            'submissionDetail',
          ) // Ensure this matches your Firestore subcollection name
          .get();

      return snapshot.docs
          .map((doc) => SubmissionDetail.fromFirestore(doc))
          .toList();
    } catch (e) {
      print("Error fetching details: $e");
      return [];
    }
  }

  /// Fetches Locations by a list of IDs, handling Firestore 'whereIn' limits.
  Future<List<Location>> getLocationsByIds(List<int> locationIds) async {
    if (locationIds.isEmpty) return [];

    // 1. Deduplicate & Convert to String (since Doc IDs are strings)
    final uniqueIds = locationIds.toSet().toList();
    List<Location> loadedLocations = [];

    // 2. Chunking Logic (Firestore 'whereIn' limit is 10)
    for (var i = 0; i < uniqueIds.length; i += 10) {
      final end = (i + 10 < uniqueIds.length) ? i + 10 : uniqueIds.length;
      final chunk = uniqueIds.sublist(i, end);

      // Convert ints to strings for the query
      final chunkStrings = chunk.map((id) => id.toString()).toList();

      try {
        final snapshot = await _db
            .collection('locations')
            .where(FieldPath.documentId, whereIn: chunkStrings)
            .get();

        final chunkLocations = snapshot.docs
            .map((doc) => Location.fromFirestore(doc))
            .toList();

        loadedLocations.addAll(chunkLocations);
      } catch (e) {
        print("Error fetching location chunk: $e");
      }
    }

    return loadedLocations;
  }
  // --- PRIVATE HELPERS ---

  List<Inspection> _mapQuerySnapshotToInspections(QuerySnapshot snapshot) {
    return snapshot.docs.map((doc) {
      final data = doc.data() as Map<String, dynamic>;
      // Ensure the ID is passed if it's not in the data body
      // data['id'] = doc.id;
      return Inspection.fromFirestore(doc);
    }).toList();
  }

  /// Handles the "10 items per IN query" limit by running parallel queries and merging them.
  Stream<List<Inspection>> _getChunkedInspections({
    required String field,
    required List<int> values,
    required Query baseQuery,
  }) {
    List<Stream<List<Inspection>>> streams = [];

    // Split values into chunks of 10
    for (var i = 0; i < values.length; i += 10) {
      var end = (i + 10 < values.length) ? i + 10 : values.length;
      var chunk = values.sublist(i, end);

      var stream = baseQuery
          .where(field, whereIn: chunk)
          .orderBy('inspectionDate', descending: true)
          .limit(50) // Limit each chunk to avoid massive memory usage
          .snapshots()
          .map(_mapQuerySnapshotToInspections);

      streams.add(stream);
    }

    // Merge streams (RxDart 'CombineLatest' is better, but this is a simple standard Flutter way)
    // Note: This relies on 'rxdart' or manual merging.
    // SIMPLE VERSION: Just return the first chunk for now to prevent crashes,
    // unless you want to add the 'rxdart' package.
    print(
      "Warning: User has >10 scopes. Returning first 10 only for performance.",
    );
    return streams[0];
  }

  Stream<List<SubmissionDetail>> getDefectsStream(int inspectionId) {
    return _db
        .collection('inspections')
        .doc(inspectionId.toString())
        .collection('submissionDetails')
        .snapshots()
        .map((snapshot) {
          return snapshot.docs
              .map(
                (doc) => SubmissionDetail.fromFirestore(doc),
              ) // Use new factory
              .toList();
        });
  }

  // 2. NEW: Method to update status
  Future<void> updateDefectStatus(
    int inspectionId,
    String defectId,
    int newStatus,
  ) async {
    await _db
        .collection('inspections')
        .doc(inspectionId.toString())
        .collection('submissionDetails')
        .doc(defectId)
        .update({
          'detailStatusId': newStatus,
          // We will add 'repairedPhotoUrl' and 'signatureUrl' here later!
        });
  }

  // Fetch single inspection (for validation)
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

  Future<void> updateLocationClosedStatus(
    int locationId,
    bool isClosedOut,
  ) async {
    await _db.collection('locations').doc(locationId.toString()).update({
      'isClosedOut': isClosedOut,
    });
  }
}
