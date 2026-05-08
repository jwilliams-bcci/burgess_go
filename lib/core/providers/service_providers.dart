import 'package:burgess_go/core/services/api_client.dart';
import 'package:burgess_go/features/sync/services/sync_service.dart';
import 'package:burgess_go/services/ai_service.dart';
import 'package:burgess_go/services/firestore_service.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../features/auth/services/auth_service.dart';
import '../services/logging_service.dart';

// 1. Logger (Independent)
final loggingServiceProvider = Provider<ILoggingService>((ref) {
  return LoggingService();
});

// 2. Auth Service (Depends on Logger)
final authServiceProvider = Provider<IAuthService>((ref) {
  final logger = ref.watch(loggingServiceProvider);
  return AuthService(logger);
});

// 3. API Client (depends on Auth Service)
final apiClientProvider = Provider<ApiClient>((ref) {
  final authService = ref.watch(authServiceProvider);
  return ApiClient(authService);
});

// 4. Sync Service
final syncServiceProvider = Provider<ISyncService>((ref) {
  final apiClient = ref.watch(apiClientProvider);
  final logger = ref.watch(loggingServiceProvider);
  return SyncService(apiClient, logger);
});

// 5. AI Service
final aiServiceProvider = Provider<AIService>((ref) {
  return AIService();
});

// 6. Firestore Provider
final firestoreServiceProvider = Provider<FirestoreService>((ref) {
  return FirestoreService();
});
