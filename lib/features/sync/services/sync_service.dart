import 'package:burgess_go/core/services/logging_service.dart';
import 'package:burgess_go/core/services/api_client.dart';

// --- INTERFACE ---
abstract class ISyncService {
  /// Syncs all Locations from the Foundation API to Firestore.
  Future<void> syncLocations();

  /// Syncs all 6-month Inspection Headers from the Foundation API to Firestore.
  Future<void> syncHeaders();

  /// Performs a deep sync for a specific location, including all related inspections.
  Future<void> syncLocationDetails(int locationId);
}

// --- IMPLEMENTATION ---
class SyncService implements ISyncService {
  final ApiClient _api;
  final ILoggingService _logger;

  SyncService(this._api, this._logger);

  @override
  Future<void> syncLocations() async {
    _logger.info('🔄 Requesting Location Sync from Foundation...');
    await _api.post('/v1/burgessgo/sync/locations', {});
  }

  @override
  Future<void> syncHeaders() async {
    _logger.info('🔄 Requesting Header Sync from Foundation...');
    await _api.post('/v1/burgessgo/sync/headers', {});
  }

  @override
  Future<void> syncLocationDetails(int locationId) async {
    _logger.info('🔄 Requesting Location Details Sync from Foundation...');
    await _api.post('/v1/burgessgo/sync/locations/$locationId/inspections', {});
  }
}
