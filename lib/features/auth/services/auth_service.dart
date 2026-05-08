import 'dart:convert';
import 'package:burgess_go/core/constants/api_constants.dart';
import 'package:burgess_go/core/services/logging_service.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:http/http.dart' as http;
import '../../../core/models/user/user_profile.dart';

// =============================
// INTERFACE
// =============================
abstract class IAuthService {
  /// Emits [User] updates when the authentication state changes.
  /// Returns null if the user is logged out.
  Stream<User?> get authStateChanges;

  /// The currently logged-in user, or null if none.
  User? get currentUser;

  /// Returns the current Foundation API Token for data requests.
  String? get apiToken;

  /// Registers a new user with [email] and [password].
  ///
  /// Throws a [FirebaseAuthException] if registration fails on Google's side.
  /// If the user's email doesn't exist in builder personnel profiles,
  /// then it throws an error back from the SQL Server.
  Future<void> register(String email, String password);

  /// Signs in a user with [email] and [password].
  ///
  /// Throws a [FirebaseAuthException] if the login fails on Google's side.
  /// Throws an [Exception] if the backend API rejects the token exchange.
  Future<UserCredential> signIn(String email, String password);

  /// Creates a new account in Firebase.
  /// Note: This does not automatically create a profile in the SQL database.
  Future<UserCredential> signUp(String email, String password);

  /// Signs the user out of Firebase and clears the local Bridge API token.
  Future<void> signOut();

  /// Fetches the full profile (Role, Communities, etc.) from the backend.
  Future<UserProfile?> fetchUserProfile();

  /// Sends a password reset email to the provided address
  Future<void> sendPasswordResetEmail(String email);
}

// =============================
// IMPLEMENTATION
// =============================
class AuthService implements IAuthService {
  final ILoggingService _logger;
  final FirebaseAuth _fbAuth = FirebaseAuth.instance;
  String? _foundationToken;
  static const String _loginPath = '/v1/burgessgo/auth/login';
  static const String _profilePath = '/v1/burgessgo/auth/user-profile';

  AuthService(this._logger);

  @override
  Stream<User?> get authStateChanges => _fbAuth.authStateChanges();

  @override
  User? get currentUser => _fbAuth.currentUser;

  @override
  String? get apiToken => _foundationToken;

  @override
  Future<void> register(String email, String password) async {
    try {
      _logger.info('🔐 Attempting to register new user in Firebase...');

      // 1. Create the user in Firebase Auth
      final credential = await _fbAuth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );

      final user = credential.user;
      if (user == null) throw Exception("Failed to create Firebase user.");

      _logger.info('✅ Firebase user created! Syncing with SQL Backend...');

      // 2. Send the credentials to our new C# Registration Endpoint
      final response = await http.post(
        Uri.parse('${ApiConstants.baseUrl}/v1/burgessgo/auth/register'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'email': email,
          'password': password,
          'firebaseUid': user.uid,
        }),
      );

      // 3. Handle the Response
      final data = jsonDecode(response.body);

      if (response.statusCode == 200) {
        // Success! The C# API sent back our new Go Token
        _foundationToken = data['token'];
        _logger.info("✅ SQL Sync complete! Go Token obtained.");
      } else {
        // SQL sync failed (e.g., "Email not found. Please contact Burgess...")
        _logger.warning("❌ SQL Sync Failed: ${data['message']}");

        // Clean up: Delete the orphaned Firebase user so they can try again later
        await user.delete();

        // Throw the exact error message from C# so the UI can display it
        throw Exception(data['message']);
      }
    } on FirebaseAuthException catch (e) {
      // Handle Firebase specific errors (like "weak-password" or "email-already-in-use")
      _logger.error("Firebase Registration Error: ${e.message}");
      throw Exception(e.message);
    } catch (e) {
      _logger.error("Registration Exception: $e");
      // Strip out the "Exception: " prefix if it exists to keep UI clean
      final cleanMessage = e.toString().replaceFirst('Exception: ', '');
      throw Exception(cleanMessage);
    }
  }

  @override
  Future<UserCredential> signIn(String email, String password) async {
    try {
      _logger.info('🔐 Signing in to Firebase...');
      final credential = await _fbAuth.signInWithEmailAndPassword(
        email: email,
        password: password,
      );

      if (credential.user != null) {
        await _authenticateWithBackend(credential.user!);
      }

      return credential;
    } on FirebaseAuthException catch (e) {
      throw Exception(e.message);
    } catch (e) {
      throw Exception('Login failed: $e');
    }
  }

  @override
  Future<UserCredential> signUp(String email, String password) async {
    try {
      return await _fbAuth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );
    } on FirebaseAuthException catch (e) {
      throw Exception(e.message);
    } catch (e) {
      throw Exception('Sign up failed: $e');
    }
  }

  @override
  Future<void> signOut() async {
    _foundationToken = null;
    await _fbAuth.signOut();
  }

  @override
  Future<UserProfile?> fetchUserProfile() async {
    try {
      _logger.info('👤 Fetching User Profile...');

      // 1. Get valid headers (triggering exchange if needed)
      final headers = await _getAuthHeaders();

      // 2. Call the API
      final response = await http
          .get(
            Uri.parse('${ApiConstants.baseUrl}$_profilePath'),
            headers: headers,
          )
          .timeout(
            const Duration(seconds: 10),
            onTimeout: () => http.Response('Error: Connection Timeout', 408),
          );

      _logger.info('📥 Profile Response: ${response.statusCode}');

      if (response.statusCode == 200) {
        if (response.body.isEmpty) return null;
        return UserProfile.fromJson(jsonDecode(response.body));
      } else {
        _logger.error('❌ API Error: ${response.statusCode} - ${response.body}');
        return null;
      }
    } catch (e) {
      _logger.error('⚠️ Fetch Profile Exception: $e');
      return null;
    }
  }

  @override
  Future<void> sendPasswordResetEmail(String email) async {
    try {
      _logger.info('📧 Sending password reset email to $email...');
      await _fbAuth.sendPasswordResetEmail(email: email);
      _logger.info('✅ Password reset email sent.');
    } on FirebaseAuthException catch (e) {
      _logger.error("Firebase Password Reset Error: ${e.message}");
      throw Exception(e.message);
    } catch (e) {
      _logger.error("Password Reset Exception: $e");
      throw Exception('Failed to send password reset email.');
    }
  }

  // ---------------------------------------------------------------------------
  // PRIVATE TOKEN EXCHANGE
  // ---------------------------------------------------------------------------

  /// Sends the Firebase ID Token to Foundation API.
  Future<void> _authenticateWithBackend(User user) async {
    try {
      _logger.info('🔄 Exchanging Firebase Token for Bridge Token...');

      // 1. Get the raw Firebase (Google) JWT
      final firebaseToken = await user.getIdToken(true);
      if (firebaseToken == null) {
        throw Exception("Failed to get Firebase Token");
      }

      // 2. Send to Foundation API
      final response = await http.post(
        Uri.parse('${ApiConstants.baseUrl}$_loginPath'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'firebaseToken': firebaseToken}),
      );

      // 3. Handle Response
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        _foundationToken = data['token'];
        _logger.info("✅ Backend Authenticated! Bridge Token obtained.");
      } else {
        _logger.error(
          "❌ Backend Auth Failed: ${response.statusCode} - ${response.body}",
        );
        throw Exception(
          "Backend rejected authentication. Check if your email exists in SQL.",
        );
      }
    } catch (e) {
      _logger.error("⚠️ Token Exchange Error: $e");
      rethrow;
    }
  }

  /// Helper to generate the headers for ANY data request.
  /// Automatically re-authenticates if the app was restarted.
  Future<Map<String, String>> _getAuthHeaders() async {
    if (_foundationToken == null) {
      final user = _fbAuth.currentUser;
      if (user != null) {
        await _authenticateWithBackend(user);
      } else {
        throw Exception('User is not logged in');
      }
    }

    return {
      'Authorization': 'Bearer $_foundationToken',
      'Content-Type': 'application/json',
    };
  }
}
