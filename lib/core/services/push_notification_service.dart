import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart'; // Added for routing
import 'package:burgess_go/core/providers/service_providers.dart';

final pushNotificationServiceProvider = Provider(
  (ref) => PushNotificationService(ref),
);

class PushNotificationService {
  final Ref ref;
  final FirebaseMessaging _fcm = FirebaseMessaging.instance;

  PushNotificationService(this.ref);

  // --- 1. TOKEN & PERMISSION LOGIC (Your Existing Code) ---
  Future<void> initPushNotifications(int userId) async {
    final logger = ref.read(loggingServiceProvider);

    NotificationSettings settings = await _fcm.requestPermission(
      alert: true,
      badge: true,
      sound: true,
    );

    if (settings.authorizationStatus == AuthorizationStatus.authorized ||
        settings.authorizationStatus == AuthorizationStatus.provisional) {
      logger.info('Push Notifications: User granted permission.');

      // Ensure iOS displays notification banners/sounds even when the app is in the foreground
      await _fcm.setForegroundNotificationPresentationOptions(
        alert: true,
        badge: true,
        sound: true,
      );

      try {
        // On iOS, APNs token registration is asynchronous after permission grant.
        // Wait briefly for the APNs token before requesting the FCM token.
        if (!kIsWeb && defaultTargetPlatform == TargetPlatform.iOS) {
          String? apnsToken = await _fcm.getAPNSToken();
          int retries = 0;
          while (apnsToken == null && retries < 5) {
            await Future.delayed(const Duration(seconds: 1));
            apnsToken = await _fcm.getAPNSToken();
            retries++;
          }
          if (apnsToken == null) {
            logger.warning(
              'Push Notifications: APNs token not yet available (Note: iOS Simulator or missing APNs entitlement may not return an APNs token).',
            );
          }
        }

        String? token = await _fcm.getToken();
        if (token != null) {
          logger.info('🔥 FCM Token: $token');
          await _saveTokenToFirestore(userId, token);
        }
      } catch (e) {
        logger.error('Push Notifications: Failed to get FCM token: $e');
      }

      _fcm.onTokenRefresh.listen((newToken) {
        logger.info('🔥 FCM Token Refreshed: $newToken');
        _saveTokenToFirestore(userId, newToken);
      });
    } else {
      logger.info('Push Notifications: User declined permission.');
    }
  }

  Future<void> _saveTokenToFirestore(int userId, String token) async {
    try {
      await FirebaseFirestore.instance
          .collection('user_tokens')
          .doc(userId.toString())
          .set({
            'tokens': FieldValue.arrayUnion([token]),
            'lastUpdated': FieldValue.serverTimestamp(),
          }, SetOptions(merge: true));

      ref
          .read(loggingServiceProvider)
          .info('✅ Token saved to Firestore for User $userId');
    } catch (e) {
      ref
          .read(loggingServiceProvider)
          .error('Failed to save token to Firestore: $e');
    }
  }

  // --- 2. ROUTING LOGIC (The New Features) ---
  Future<void> setupRouting(GoRouter router) async {
    // Handle taps when the app is completely closed (Terminated)
    RemoteMessage? initialMessage = await _fcm.getInitialMessage();
    if (initialMessage != null) {
      _handleNotificationRouting(initialMessage, router);
    }

    // Handle taps when the app is in the background (Minimized)
    FirebaseMessaging.onMessageOpenedApp.listen((RemoteMessage message) {
      _handleNotificationRouting(message, router);
    });

    // Handle foreground messages
    FirebaseMessaging.onMessage.listen((RemoteMessage message) {
      debugPrint('Received a notification while app is in foreground!');
      // Optional: You can trigger an in-app Snackbar here if you want!
    });
  }

  void _handleNotificationRouting(RemoteMessage message, GoRouter router) {
    final data = message.data;
    final String? type = data['type'];
    final String? inspectionId = data['inspectionId'];

    if (inspectionId == null) return;

    if (type == 'chat_message') {
      router.push('/inspection/$inspectionId/chat');
    } else if (type == 'status_update') {
      router.push('/inspection/$inspectionId');
    }
  }
}
