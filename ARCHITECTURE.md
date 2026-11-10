# Burgess GO — Architecture & Repository Guide

`burgess_go` is a cross-platform Flutter client (iOS, Android, Web) and Firebase Cloud Functions backend for **Burgess Construction Consultants**. It empowers field superintendents and area managers to track inspections, manage construction locations, triage and dispatch trade defects (punch lists), and receive real-time push updates.

---

## 1. Core Tech Stack & Runtimes

### Client Application (Flutter / Dart)
- **Dart SDK**: `^3.9.0`
- **Framework**: Flutter (Material 3 enabled)
- **State Management & DI**: `flutter_riverpod` (`^3.1.0`) + `rxdart` (`^0.28.0`)
- **Routing**: `go_router` (`^17.1.0`)
- **Firebase Suite**:
  - `firebase_core` (`^4.3.0`)
  - `firebase_auth` (`^6.1.3`)
  - `cloud_firestore` (`^6.1.1`)
  - `firebase_storage` (`^13.0.6`)
  - `firebase_messaging` (`^16.2.0`)
- **Networking**: `http` (`^1.6.0`)
- **AI & LLM**: `google_generative_ai` (`^0.4.7`, configured with `gemini-2.5-pro`)
- **Observability & Logging**: `logger` (`^2.6.2`), `logging` (`^1.3.0`), `sentry_flutter` (`^9.13.0`)
- **UI & Utilities**: `google_fonts` (`^8.0.2`), `fl_chart` (`^1.1.1`), `signature` (`^6.3.0`), `image_picker` (`^1.2.1`), `share_plus` (`^12.0.1`), `url_launcher` (`^6.3.2`), `showcaseview` (`^5.1.0`), `shared_preferences` (`^2.5.5`), `intl` (`^0.20.2`), `uuid` (`^4.5.2`)

### Serverless Backend (`functions/`)
- **Runtime**: Node.js `24`
- **Language**: TypeScript (`^5.7.3`)
- **Frameworks**: `firebase-functions` (`^7.0.0`, v2 Firestore triggers), `firebase-admin` (`^13.6.0`)

---

## 2. Directory Structure & Entry Points

```text
burgess_go/
├── lib/
│   ├── main.dart                     # App bootstrap, Firebase init, ProviderScope, FCM routing setup
│   ├── firebase_options.dart         # Generated FlutterFire platform config (Project: keystone-31e70)
│   ├── core/                         # App-wide singletons, infrastructure, and design system
│   │   ├── constants/                # API base URLs and timeout constants (api_constants.dart)
│   │   ├── models/                   # Shared domain models (Inspection, Location, UserProfile, LookupItem)
│   │   ├── providers/                # Root Riverpod DI registrations (service_providers.dart, holiday_provider.dart)
│   │   ├── router/                   # GoRouter configuration and auth guards (app_router.dart)
│   │   ├── services/                 # ApiClient, LoggingService, PushNotificationService
│   │   ├── theme/                    # Material 3 AppTheme & AppColors palette
│   │   ├── utils/                    # Business day / holiday scheduling helpers
│   │   └── widgets/                  # Shared layout shells (BaseScaffold, AppDrawer, SignOffDialog)
│   ├── features/                     # Feature-first vertical slices
│   │   ├── auth/                     # Login, Registration, Password Reset, AuthController, AuthService
│   │   ├── superintendent_dash/      # Main Superintendent Action Board & 7-Day Schedule
│   │   ├── inspections/              # Inspection detail view, reschedule/reinspection DTOs, chat messages
│   │   ├── defects/                  # Defect triage, Trade Punch List dispatch, Guest magic-link portal
│   │   ├── locations/                # Active/Closed locations, Add Location flow, Location management
│   │   ├── trade_contact/            # User-scoped trade contractor address book
│   │   └── sync/                     # Foundation SQL <-> Firestore synchronization triggers
│   ├── presentation/                 # Legacy/secondary screens (Area Manager Dashboard, AI Chat Dialog)
│   ├── services/                     # Legacy/shared FirestoreService and Gemini AIService
│   ├── models/                       # Shared interfaces (i_uploadable.dart)
│   └── utils/                        # JSON/Timestamp serialization helpers (json_helper.dart)
├── functions/                        # Firebase Cloud Functions (TypeScript)
│   ├── src/
│   │   ├── index.ts                  # Cloud Functions entry point (onInspectionUpdated trigger)
│   │   ├── handlers/                 # Event handlers for chat messages and inspection status changes
│   │   └── utils/                    # FCM push notification dispatch helper (pushHelper.ts)
│   └── package.json                  # Functions scripts and dependencies
├── assets/images/                    # App logos and icons
├── firebase.json                     # Firebase project & predeploy configuration
└── pubspec.yaml                      # Dart package manifest
```

### Key Entry Points
- **`lib/main.dart`**: Initializes `WidgetsFlutterBinding` and `Firebase.initializeApp`, wraps `BurgessGoApp` in a Riverpod `ProviderScope`, and binds `PushNotificationService.setupRouting(router)` via a post-frame callback.
- **`lib/core/router/app_router.dart`**: Defines `goRouterProvider`, route hierarchy, `ShellRoute` wrapping `BaseScaffold`, and authentication redirects.
- **`functions/src/index.ts`**: Exports `onInspectionUpdated`, a Firestore v2 `onDocumentWritten("inspections/{inspectionId}")` trigger that dispatches FCM notifications on new chat messages or status transitions.

---

## 3. Architecture & Data Flow

### Hybrid Data Architecture (CQRS-style Read/Write Split)
The system uses a hybrid architecture bridging a legacy C#/.NET SQL backend (**Foundation API** at `https://m.burgess-inc.com`) and **Cloud Firestore**:
1. **Reads (Real-Time NoSQL)**: The Flutter app primarily reads and streams domain entities (`inspections`, `locations`, `submissionDetails`, `trade_lists`, `users/{id}/contacts`) directly from Cloud Firestore via repositories (`InspectionRepository`, `LocationRepository`, `TradeContactRepository`).
2. **Writes & Commands (REST API + Sync)**: Mutating business operations (creating locations, scheduling inspections, rescheduling, requesting reinspections) are sent as strongly typed DTOs via `ApiClient` (`POST /v1/burgessgo/...`) to the Foundation API.
3. **Synchronization (`SyncService`)**: After mutating state on the Foundation API, controllers trigger `SyncService` (`/v1/burgessgo/sync/locations`, `/v1/burgessgo/sync/headers`, `/v1/burgessgo/sync/locations/{id}/inspections`), instructing the backend to push updated SQL records into Firestore, which then stream reactively to the UI.
4. **Direct Firestore Writes**: Tactical collaborative features (defect status updates, trade punch list dispatches, inspection chat messages, trade contacts, and FCM `user_tokens`) write directly to Firestore and Firebase Storage.

### Authentication & Token Exchange Flow
Managed by `AuthService` (`lib/features/auth/services/auth_service.dart`) and `AuthController`:
1. Users authenticate against **Firebase Auth** (`signInWithEmailAndPassword` or `createUserWithEmailAndPassword`).
2. `AuthService` retrieves the Firebase JWT (`user.getIdToken(true)`) and exchanges it with the Foundation API (`POST /v1/burgessgo/auth/login` or `/v1/burgessgo/auth/register`) for a **Foundation Bridge Token** (`_foundationToken`).
3. `AuthService.fetchUserProfile()` calls `GET /v1/burgessgo/auth/user-profile` using `Bearer <_foundationToken>` to hydrate `UserProfile` (containing `securityUserId`, `communityIds`, `divisionIds`, `builderIds`, `locationIds`).
4. Once hydrated, `PushNotificationService.initPushNotifications(securityUserId)` registers the device's FCM token under `user_tokens/{securityUserId}` in Firestore.

### State Management & Dependency Injection
- **Riverpod 3 (`Notifier` / `NotifierProvider`)**: Feature controllers extend `Notifier<TState>` or `AutoDisposeNotifier<TState>` paired with immutable state classes implementing `.copyWith()`.
- **Core Service Providers (`lib/core/providers/service_providers.dart`)**: Registers singletons for `loggingServiceProvider`, `authServiceProvider`, `apiClientProvider`, `syncServiceProvider`, `aiServiceProvider`, and `firestoreServiceProvider`.

### Routing & Deep Linking
- `goRouterProvider` watches `authControllerProvider.select((s) => s.user != null)` and `isInitializing` to avoid resetting the navigation stack on background profile updates.
- **Unauthenticated Routes**: `/splash`, `/login`, `/register`, `/forgot-password`, and `/guest` (magic-link access for external trade contractors using `inspectionId`, `listId`, and `token` query parameters).
- **Authenticated Shell**: Wrapped in `BaseScaffold` (`ShellRoute`), serving `/super-dash`, `/trade-contacts`, `/inspection/:inspectionId` (with nested `defects` and `dispatch` routes), `/locations` (with nested `add` and `:locationId` routes), and `/closed-locations`.

---

## 4. Coding Conventions & Styling

### Feature Modularity
New features should be placed under `lib/features/<feature_name>/` following a strict 5-layer separation:
- `models/`: Feature-specific request DTOs (e.g., `ScheduleReinspectionRequest`) and domain models.
- `repositories/`: Abstract interface (`IXxxRepository`) + Firestore/API implementation (`XxxRepository`) + Riverpod `Provider`.
- `services/`: Stateless external integrations or API wrappers (`IXxxService` + `XxxService`).
- `states/`: Immutable state classes with `isLoading`, `errorMessage`, domain data lists, and `.copyWith()`.
- `controllers/`: Riverpod `Notifier` classes orchestrating repositories, services, and UI state transitions.
- `screens/` & `widgets/`: `ConsumerWidget` or `ConsumerStatefulWidget` UI components.

### Naming & Serialization Conventions
- **Files**: `snake_case.dart` for Dart; `camelCase.ts` for TypeScript Cloud Functions.
- **Interfaces**: Prefixed with `I` (e.g., `IAuthService`, `ILoggingService`, `ISyncService`, `IInspectionRepository`, `ILocationRepository`, `IUploadable`).
- **Serialization**: Manual `fromJson`, `toJson`, and `fromFirestore(DocumentSnapshot)` factory constructors using helpers in `lib/utils/json_helper.dart` (`parseDateTimeFromTimestamp`). No `build_runner` or `freezed` code generation is used.
- **Defensive API Handling**: Controllers check HTTP 200 responses from Foundation API for soft-error payloads (`response['success'] == false` or `response['error'] != null`) before assuming success.

### UI & Theme System
- Centralized in `lib/core/theme/app_colors.dart` and `lib/core/theme/app_theme.dart` (Material 3).
- **Typography**: Global `GoogleFonts.inter()` font family.
- **Brand Palette (`AppColors`)**:
  - Primary: `burgessBlue` (`#002395`)
  - Secondary: `burgessOrange` (`#F27D00`)
  - Outdoor-optimized high-contrast backgrounds: `backgroundLight` (`#F8F9FA`) and `surfaceLight` (`#FFFFFF`)
  - Semantic statuses: `success` (`#10B981`), `error` (`#EF4444`), `warning` (`#F59E0B`)
- **Field Ergonomics**: `ElevatedButton` defaults to a minimum height of `50px` for easy tapping on construction sites.

---

## 5. Build & Environment Setup

### Prerequisites
- **Flutter SDK**: Compatible with Dart `^3.9.0`
- **Node.js**: Version `24` (for Firebase Cloud Functions)
- **Firebase CLI**: Configured with access to project `keystone-31e70`

### Primary Commands

#### Flutter Client (Root Directory)
```bash
# Install dependencies
flutter pub get

# Run static analysis / lint checks (configured via analysis_options.yaml)
flutter analyze

# Run unit and widget tests
flutter test

# Launch the app (iOS, Android, or Web)
flutter run

# Build release artifacts
flutter build apk
flutter build ios
flutter build web
```

#### Firebase Cloud Functions (`functions/` Directory)
```bash
# Install Node dependencies
npm --prefix functions install

# Compile TypeScript to functions/lib/
npm --prefix functions run build

# Run ESLint
npm --prefix functions run lint

# Start local Firebase Functions emulator
npm --prefix functions run serve

# Deploy Cloud Functions to Firebase
npm --prefix functions run deploy
```

### Configuration & Environment Notes
- **Firebase Config**: Platform keys and project bindings (`keystone-31e70`) are checked into `firebase.json` and `lib/firebase_options.dart` (`android/app/google-services.json`, `ios/Runner/GoogleService-Info.plist`).
- **Backend Base URL**: Configured statically in `lib/core/constants/api_constants.dart` (`ApiConstants.baseUrl = 'https://m.burgess-inc.com'`).
- **AI Service Key**: Configured in `lib/services/ai_service.dart` (uses `gemini-2.5-pro`).
- **Logging & Crash Reporting**: `LoggingService` routes warnings, errors, and breadcrumbs to `Sentry` in production while pretty-printing to console in `kDebugMode`.
