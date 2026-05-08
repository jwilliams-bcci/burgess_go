import 'dart:async';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/legacy.dart';
import '../../../core/models/location/location.dart';
import '../../../core/models/inspection/inspection.dart';
import '../../../../services/firestore_service.dart';

// --- VIEW MODELS (Keep these consistent) ---
class CommunityInfo {
  final int id;
  final String name;
  CommunityInfo({required this.id, required this.name});
}

class CommunityGroup {
  final int communityId;
  final String communityName;
  final List<LocationGroup> locations;

  CommunityGroup({
    required this.communityId,
    required this.communityName,
    required this.locations,
  });
}

class LocationGroup {
  final int locationId;
  final List<Inspection> inspections;

  LocationGroup({required this.locationId, required this.inspections});
}

// --- STATE CLASS ---
class DashboardState {
  final List<CommunityGroup> groups;
  final List<CommunityInfo> allCommunities;
  final Set<int> selectedCommunityIds;
  final bool isLoading;
  final Map<int, Location> locationData;

  DashboardState({
    this.groups = const [],
    this.allCommunities = const [],
    this.selectedCommunityIds = const {},
    this.isLoading = true,
    this.locationData = const {},
  });

  DashboardState copyWith({
    List<CommunityGroup>? groups,
    List<CommunityInfo>? allCommunities,
    Set<int>? selectedCommunityIds,
    bool? isLoading,
    Map<int, Location>? locationData,
  }) {
    return DashboardState(
      groups: groups ?? this.groups,
      allCommunities: allCommunities ?? this.allCommunities,
      selectedCommunityIds: selectedCommunityIds ?? this.selectedCommunityIds,
      isLoading: isLoading ?? this.isLoading,
      locationData: locationData ?? this.locationData,
    );
  }
}

// --- CONTROLLER (StateNotifier) ---
// We wrap the state in AsyncValue to handle loading/error states cleanly
class DashboardController extends StateNotifier<AsyncValue<DashboardState>> {
  final Ref ref;
  final FirestoreService _firestoreService = FirestoreService();

  StreamSubscription? _subscription;
  List<Inspection> _rawInspections = []; // Internal cache for filtering

  // Constructor
  DashboardController(this.ref) : super(const AsyncValue.loading()) {
    //_init();
  }

  // void _init() {
  //   final user = ref.read(userProvider);
  //   if (user == null) {
  //     state = AsyncValue.data(DashboardState(isLoading: false));
  //     return;
  //   }

  //   _subscription = _firestoreService
  //       .getInspectionsForUser(user)
  //       .listen(
  //         (inspections) async {
  //           _rawInspections = inspections;

  //           // --- NEW: FETCH LOCATIONS ---
  //           // 1. Extract IDs from inspections (and ensure not null)
  //           final locationIds = inspections
  //               .map((i) => i.locationId)
  //               .whereType<int>()
  //               .toSet()
  //               .toList();

  //           // 2. Fetch valid locations from service
  //           // (Wait for this future to complete)
  //           final locations = await _firestoreService.getLocationsByIds(
  //             locationIds,
  //           );

  //           // 3. Create Map: { 101: LocationObject, 102: LocationObject }
  //           final locMap = {for (var loc in locations) loc.locationId: loc};

  //           // 4. Update State
  //           _updateState(newLocationMap: locMap);
  //         },
  //         onError: (error, stack) {
  //           state = AsyncValue.error(error, stack);
  //         },
  //       );
  // }

  @override
  void dispose() {
    _subscription?.cancel();
    super.dispose();
  }

  // --- ACTIONS ---

  void toggleFilter(int communityId) {
    // 1. Get current valid state or exit
    final currentState = state.value;
    if (currentState == null) return;

    // 2. Modify filters
    final newFilters = Set<int>.from(currentState.selectedCommunityIds);
    if (newFilters.contains(communityId)) {
      newFilters.remove(communityId);
    } else {
      newFilters.add(communityId);
    }

    // 3. Update state temporarily with new filters
    // We emit 'data' immediately to make the UI snappy
    state = AsyncValue.data(
      currentState.copyWith(selectedCommunityIds: newFilters),
    );

    // 4. Recalculate the groups
    _updateState();
  }

  // --- PRIVATE HELPERS ---

  void _updateState({Map<int, Location>? newLocationMap}) {
    final currentState = state.value ?? DashboardState();

    // Use new map if provided, otherwise keep existing
    final locMap = newLocationMap ?? currentState.locationData;

    final filters = currentState.selectedCommunityIds;
    final allComms = _extractCommunities(_rawInspections);

    final filtered = filters.isEmpty
        ? _rawInspections
        : _rawInspections
              .where((i) => filters.contains(i.communityId))
              .toList();

    final grouped = _groupInspectionsByCommunity(filtered);

    state = AsyncValue.data(
      currentState.copyWith(
        groups: grouped,
        allCommunities: allComms,
        isLoading: false,
        locationData: locMap, // Store the map
      ),
    );
  }

  // --- LOGIC: Grouping & Sorting ---

  List<CommunityInfo> _extractCommunities(List<Inspection> inspections) {
    final unique = <int, String>{};
    for (var i in inspections) {
      if (i.communityId != null) {
        unique[i.communityId!] = i.community ?? "Unknown Community";
      }
    }
    final list = unique.entries
        .map((e) => CommunityInfo(id: e.key, name: e.value))
        .toList();
    list.sort((a, b) => a.name.compareTo(b.name));
    return list;
  }

  List<CommunityGroup> _groupInspectionsByCommunity(
    List<Inspection> inspections,
  ) {
    Map<int, List<Inspection>> communityMap = {};
    for (var i in inspections) {
      final cId = i.communityId ?? 0;
      if (!communityMap.containsKey(cId)) communityMap[cId] = [];
      communityMap[cId]!.add(i);
    }

    List<CommunityGroup> communityGroups = [];
    communityMap.forEach((commId, commInspections) {
      String commName = commInspections.first.community ?? "Unknown Community";
      List<LocationGroup> locationGroups = _groupInspectionsByLocation(
        commInspections,
      );

      communityGroups.add(
        CommunityGroup(
          communityId: commId,
          communityName: commName,
          locations: locationGroups,
        ),
      );
    });

    communityGroups.sort((a, b) => a.communityName.compareTo(b.communityName));
    return communityGroups;
  }

  List<LocationGroup> _groupInspectionsByLocation(
    List<Inspection> inspections,
  ) {
    final Map<int, List<Inspection>> groups = {};
    for (var insp in inspections) {
      final id = insp.locationId ?? 0;
      if (!groups.containsKey(id)) groups[id] = [];
      groups[id]!.add(insp);
    }

    List<LocationGroup> result = [];
    groups.forEach((key, value) {
      // Sort inspections by Date Descending
      value.sort(
        (a, b) => (b.inspectionDate ?? DateTime(2000)).compareTo(
          a.inspectionDate ?? DateTime(2000),
        ),
      );
      result.add(LocationGroup(locationId: key, inspections: value));
    });

    // Sort locations by most recent inspection
    result.sort(
      (a, b) => (b.inspections.first.inspectionDate ?? DateTime(2000))
          .compareTo(a.inspections.first.inspectionDate ?? DateTime(2000)),
    );
    return result;
  }
}

// --- PROVIDER DEFINITION ---
final dashboardControllerProvider =
    StateNotifierProvider.autoDispose<
      DashboardController,
      AsyncValue<DashboardState>
    >((ref) {
      return DashboardController(ref);
    });
