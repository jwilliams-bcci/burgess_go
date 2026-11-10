import 'package:burgess_go/core/models/inspection/inspection.dart';
import 'package:burgess_go/core/models/inspection/submission_detail.dart';
import 'package:burgess_go/core/models/location/location.dart';
import 'package:burgess_go/core/widgets/base_scaffold.dart';
import 'package:burgess_go/features/auth/controllers/auth_controller.dart';
import 'package:burgess_go/features/auth/screens/forgot_password_screen.dart';
import 'package:burgess_go/features/auth/screens/register_screen.dart';
import 'package:burgess_go/features/auth/screens/splash_screen.dart';
import 'package:burgess_go/features/defects/screens/defects_screen.dart';
import 'package:burgess_go/features/inspections/screens/inspection_management_screen.dart';
import 'package:burgess_go/features/locations/screens/add_location_screen.dart';
import 'package:burgess_go/features/locations/screens/location_list_screen.dart';
import 'package:burgess_go/features/locations/screens/location_management_screen.dart';
import 'package:burgess_go/features/locations/screens/closed_locations_screen.dart';
import 'package:burgess_go/features/defects/screens/dispatch_screen.dart';
import 'package:burgess_go/features/trade_contact/screens/trade_contact_list_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

import 'package:burgess_go/features/auth/screens/login_screen.dart';
import 'package:burgess_go/features/superintendent_dash/screens/superintendent_dash_screen.dart';
import 'package:burgess_go/features/defects/screens/guest_defects_screen.dart';

import 'package:burgess_go/features/locations/repositories/location_repository.dart';
import 'package:burgess_go/features/inspections/repositories/inspection_repository.dart';

final _rootNavigatorKey = GlobalKey<NavigatorState>();
final _shellNavigatorKey = GlobalKey<NavigatorState>();

final goRouterProvider = Provider<GoRouter>((ref) {
  // 🔥 THE FIX: We use .select() to only rebuild the Router if the login status
  // actually changes. This stops background profile refreshes from destroying the navigation stack!
  final isLoggedIn = ref.watch(
    authControllerProvider.select((state) => state.user != null),
  );
  final isInitializing = ref.watch(
    authControllerProvider.select((state) => state.isInitializing),
  );

  return GoRouter(
    navigatorKey: _rootNavigatorKey,
    initialLocation: '/splash',

    redirect: (context, state) {
      if (state.uri.path.startsWith('/guest')) return null;

      // 🔥 Dynamically read the full auth state during the routing check
      final authState = ref.read(authControllerProvider);

      if (authState.isInitializing) return '/splash';

      final isAuthRoute =
          state.uri.path == '/login' ||
          state.uri.path == '/register' ||
          state.uri.path == '/forgot-password';

      if (authState.user == null) {
        return isAuthRoute ? null : '/login';
      }

      if (isAuthRoute || state.uri.path == '/splash') {
        return '/super-dash';
      }

      return null;
    },
    routes: [
      GoRoute(
        path: '/splash',
        builder: (context, state) => const SplashScreen(),
      ),

      GoRoute(path: '/login', builder: (context, state) => const LoginScreen()),

      GoRoute(
        path: '/register',
        builder: (context, state) => const RegisterScreen(),
      ),

      GoRoute(
        path: '/forgot-password',
        builder: (context, state) => const ForgotPasswordScreen(),
      ),

      GoRoute(
        path: '/guest',
        builder: (context, state) {
          final inspectionId = state.uri.queryParameters['inspectionId'];
          final listId = state.uri.queryParameters['listId'];
          final token = state.uri.queryParameters['token'];

          if (inspectionId != null && listId != null && token != null) {
            return GuestDefectsScreen(
              inspectionId: inspectionId,
              listId: listId,
              token: token,
            );
          }

          return const Scaffold(
            body: Center(child: Text('Invalid or expired magic link.')),
          );
        },
      ),

      ShellRoute(
        navigatorKey: _shellNavigatorKey,
        builder: (context, state, child) {
          return BaseScaffold(title: 'Burgess GO', body: child);
        },
        routes: [
          GoRoute(
            path: '/super-dash',
            builder: (context, state) => const SuperintendentDashScreen(),
          ),

          GoRoute(
            path: '/trade-contacts',
            builder: (context, state) => const TradeContactListScreen(),
          ),

          GoRoute(
            path: '/inspection/:inspectionId',
            builder: (context, state) {
              final inspectionId = state.pathParameters['inspectionId'];
              return InspectionManagementScreen(
                inspectionId: inspectionId ?? '',
              );
            },
            routes: [
              GoRoute(
                path: 'defects',
                builder: (context, state) {
                  final inspectionIdStr = state.pathParameters['inspectionId'];
                  final inspectionId = int.tryParse(inspectionIdStr ?? '') ?? 0;
                  return DefectsScreen(inspectionId: inspectionId);
                },
                routes: [
                  GoRoute(
                    path: 'dispatch',
                    builder: (context, state) {
                      final extraList =
                          state.extra as List<SubmissionDetail>? ?? [];
                      final inspectionIdStr =
                          state.pathParameters['inspectionId'];
                      final inspectionId =
                          int.tryParse(inspectionIdStr ?? '') ?? 0;

                      return DispatchScreen(
                        inspectionId: inspectionId,
                        selectedDetails: extraList,
                      );
                    },
                  ),
                ],
              ),
            ],
          ),

          GoRoute(
            path: '/locations',
            name: 'locations_list',
            builder: (context, state) => const LocationListScreen(),
            routes: [
              // 🔥 ARCHITECTURAL FIX: Nested Add Location Route
              // Path becomes: /locations/add
              GoRoute(
                path: 'add',
                name: 'add_location',
                builder: (context, state) => const AddLocationScreen(),
              ),
              // 🔥 ARCHITECTURAL FIX: Nested Location Details Route
              // Path becomes: /locations/123
              GoRoute(
                path: ':locationId',
                name: 'location_management',
                builder: (context, state) {
                  final locationIdStr = state.pathParameters['locationId'];
                  final locationId = int.tryParse(locationIdStr ?? '') ?? 0;

                  final extraData = state.extra as Map<String, dynamic>?;
                  final location = extraData?['location'] as Location?;

                  // 1. If we passed it normally via navigation, use it!
                  if (location != null) {
                    return LocationManagementScreen(location: location);
                  }

                  // 2. THE NOSQL WAY: Direct Document Lookup for Deep Links
                  return FutureBuilder<DocumentSnapshot>(
                    future: FirebaseFirestore.instance
                        .collection('locations')
                        .doc(locationId.toString())
                        .get(),
                    builder: (context, snapshot) {
                      if (snapshot.connectionState == ConnectionState.waiting) {
                        return const Scaffold(
                          body: Center(child: CircularProgressIndicator()),
                        );
                      }

                      if (snapshot.hasData && snapshot.data!.exists) {
                        final fetchedLocation = Location.fromFirestore(
                          snapshot.data!,
                        );
                        return LocationManagementScreen(
                          location: fetchedLocation,
                        );
                      }

                      return const Scaffold(
                        body: Center(child: Text("Location not found.")),
                      );
                    },
                  );
                },
              ),
            ],
          ),

          GoRoute(
            path: '/closed-locations',
            name: 'closed_locations',
            builder: (context, state) => const ClosedLocationsScreen(),
          ),
        ],
      ),
    ],
  );
});
