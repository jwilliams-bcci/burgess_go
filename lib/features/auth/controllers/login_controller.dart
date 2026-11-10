import 'package:burgess_go/core/providers/service_providers.dart';
import 'package:burgess_go/core/services/logging_service.dart';
import 'package:burgess_go/features/auth/controllers/auth_controller.dart';
import 'package:burgess_go/features/auth/services/auth_service.dart';
import 'package:burgess_go/features/auth/states/login_state.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

// 1. Use NotifierProvider.autoDispose
final loginControllerProvider =
    NotifierProvider.autoDispose<LoginController, LoginState>(
      LoginController.new,
    );

// 2. Extend AutoDisposeNotifier (to match the .autoDispose provider)
class LoginController extends Notifier<LoginState> {
  IAuthService get _authService => ref.read(authServiceProvider);
  ILoggingService get _logger => ref.read(loggingServiceProvider);

  @override
  LoginState build() {
    return LoginState();
  }

  void toggleMode() {
    state = state.copyWith(isLoginMode: !state.isLoginMode, errorMessage: null);
  }

  Future<void> submit(String email, String password) async {
    _logger.info("Login process started for user: $email");
    state = state.copyWith(isLoading: true, errorMessage: null);

    try {
      _logger.debug("Attempting Firebase Authentication...");
      await _authService.signIn(email, password);
      _logger.info("Firebase Auth successful for $email");

      _logger.debug("Fetching Burgess system profile...");
      final success = await ref
          .read(authControllerProvider.notifier)
          .loadUser();

      if (!success) {
        _logger.warning(
          "Auth successful, but no Burgess profile found for $email. Access denied.",
        );

        state = state.copyWith(
          isLoading: false,
          errorMessage:
              "PROFILE_MISSING", // 🔥 Changed to a specific flag string
        );

        await _authService.signOut();
        return;
      }

      _logger.info(
        "Login and profile retrieval complete for $email. Proceeding to sync/dashboard.",
      );
      state = state.copyWith(isLoading: false);
    } on FirebaseAuthException catch (e) {
      _logger.warning("Firebase Auth Exception: ${e.code} - ${e.message}");

      String userMessage =
          "Authentication failed. Please check your credentials.";
      if (e.code == 'user-not-found' ||
          e.code == 'wrong-password' ||
          e.code == 'invalid-credential') {
        userMessage = "Invalid email or password.";
      } else if (e.code == 'network-request-failed') {
        userMessage = "Network error. Please check your internet connection.";
      }

      state = state.copyWith(isLoading: false, errorMessage: userMessage);
    } catch (e, stackTrace) {
      _logger.error(
        "Login sequence failed unexpectedly: $e\nStackTrace: $stackTrace",
      );

      state = state.copyWith(
        isLoading: false,
        errorMessage: "An error occurred during login. Please try again.",
      );
    }
  }

  Future<void> register(String email, String password) async {
    _logger.info("Registration process started for user: $email");
    state = state.copyWith(isLoading: true, errorMessage: null);

    try {
      _logger.debug("Attempting Firebase Registration & SQL Sync...");

      // 1. Call our new register method in the service
      await _authService.register(email, password);
      _logger.info("Registration and sync successful for $email");

      _logger.debug("Fetching Burgess system profile...");

      // 2. Load the user profile into the global AuthController
      final success = await ref
          .read(authControllerProvider.notifier)
          .loadUser();

      if (!success) {
        _logger.warning("Profile load failed after registration for $email.");
        state = state.copyWith(
          isLoading: false,
          errorMessage:
              "PROFILE_MISSING", // 🔥 Changed to a specific flag string
        );
        await _authService.signOut();
        return;
      }

      _logger.info(
        "Registration complete for $email. Proceeding to dashboard.",
      );
      state = state.copyWith(isLoading: false);
    } catch (e) {
      // The service throws clean, human-readable errors now (like the SQL 51000 message)
      _logger.warning("Registration sequence failed: $e");

      state = state.copyWith(
        isLoading: false,
        errorMessage: e.toString(), // Passes the clean message right to the UI
      );
    }
  }

  Future<bool> resetPassword(String email) async {
    _logger.info("Password reset requested for: $email");
    state = state.copyWith(isLoading: true, errorMessage: null);

    try {
      await _authService.sendPasswordResetEmail(email);
      state = state.copyWith(isLoading: false);
      return true;
    } catch (e) {
      _logger.warning("Password reset failed: $e");
      state = state.copyWith(
        isLoading: false,
        errorMessage: e.toString().replaceFirst('Exception: ', ''),
      );
      return false;
    }
  }
}
