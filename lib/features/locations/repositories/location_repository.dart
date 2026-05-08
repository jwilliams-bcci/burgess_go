import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:burgess_go/core/providers/service_providers.dart';
import 'package:burgess_go/core/services/logging_service.dart';
import 'package:burgess_go/core/models/location/location.dart';
import 'package:burgess_go/core/models/user/user_profile.dart';

// --- PROVIDER ---
final locationRepositoryProvider = Provider<ILocationRepository>((ref) {
  final logger = ref.watch(loggingServiceProvider);
  return LocationRepository(
    firestore: FirebaseFirestore.instance,
    logger: logger,
  );
});

// --- INTERFACE ---
abstract class ILocationRepository {
  Stream<List<Location>> watchLocationsForUser(UserProfile user);
}

// --- REPOSITORY ---
class LocationRepository implements ILocationRepository {
  final FirebaseFirestore _db;
  final ILoggingService _logger;

  LocationRepository({
    required FirebaseFirestore firestore,
    required ILoggingService logger,
  }) : _db = firestore,
       _logger = logger;

  @override
  Stream<List<Location>> watchLocationsForUser(UserProfile user) {
    return _db
        .collection('locations')
        .where('allowedUserIds', arrayContains: user.securityUserId)
        .snapshots()
        .map((snapshot) {
          final locations = snapshot.docs
              .map((doc) => Location.fromFirestore(doc))
              .toList();

          // Sort alphabetically by address
          locations.sort(
            (a, b) => (a.address ?? '').compareTo(b.address ?? ''),
          );

          return locations;
        });
  }
}
