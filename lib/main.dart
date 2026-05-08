import 'package:burgess_go/core/theme/app_theme.dart';
import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:burgess_go/core/router/app_router.dart';
// 🚨 IMPORTANT: Import your newly merged Push Notification Service
import 'package:burgess_go/core/services/push_notification_service.dart';
import 'firebase_options.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);

  runApp(const ProviderScope(child: BurgessGoApp()));
}

// --- 1. CONVERT TO ConsumerStatefulWidget ---
class BurgessGoApp extends ConsumerStatefulWidget {
  const BurgessGoApp({super.key});

  @override
  ConsumerState<BurgessGoApp> createState() => _BurgessGoAppState();
}

class _BurgessGoAppState extends ConsumerState<BurgessGoApp> {
  @override
  void initState() {
    super.initState();

    // --- 2. WIRE UP THE ROUTING LISENTERS ---
    // addPostFrameCallback ensures Riverpod and the Router are fully loaded
    // before we try to attach the push notification listeners to them.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final router = ref.read(goRouterProvider);
      ref.read(pushNotificationServiceProvider).setupRouting(router);
    });
  }

  @override
  Widget build(BuildContext context) {
    // 3. Your build method stays exactly the same!
    final goRouter = ref.watch(goRouterProvider);

    return MaterialApp.router(
      title: 'Burgess Go',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.lightTheme,
      routerConfig: goRouter,
    );
  }
}
