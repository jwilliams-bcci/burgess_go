import 'package:burgess_go/core/providers/service_providers.dart';
import 'package:burgess_go/core/services/logging_service.dart';
import 'package:burgess_go/core/services/push_notification_service.dart';
import 'package:burgess_go/features/auth/services/auth_service.dart';
import 'package:burgess_go/features/auth/states/auth_state.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

// --- PROVIDER ---
final authControllerProvider = NotifierProvider<AuthController, AuthState>(
  AuthController.new,
);

// --- CONTROLLER ---
class AuthController extends Notifier<AuthState> {
  IAuthService get _authService => ref.read(authServiceProvider);
  ILoggingService get _logger => ref.read(loggingServiceProvider);

  @override
  AuthState build() {
    Future.microtask(_init);
    return AuthState(isInitializing: true);
  }

  Future<void> _init() async {
    _logger.info("🚀 Bootstrapping application...");
    try {
      if (_authService.currentUser != null) {
        _logger.info(
          "Session found for ${_authService.currentUser!.email}. Loading profile...",
        );

        await loadUser();
      } else {
        _logger.info("No active session found.");
      }
    } finally {
      state = state.copyWith(isInitializing: false);
      _logger.info("🏁 Initialization complete.");
    }
  }

  Future<void> checkLoginStatus() async {
    if (_authService.currentUser != null) {
      await loadUser();
    }
  }

  Future<bool> loadUser() async {
    try {
      final profile = await _authService.fetchUserProfile();
      if (profile != null) {
        state = state.copyWith(user: profile, isInitializing: false);
        ref
            .read(pushNotificationServiceProvider)
            .initPushNotifications(profile.securityUserId);
        return true;
      }
    } catch (e) {
      _logger.error("Error loading user: $e");
    }
    return false;
  }

  void logout() {
    ref.read(authServiceProvider).signOut();
    state = AuthState(isInitializing: false, user: null);
  }
}
