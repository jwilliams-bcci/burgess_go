import 'package:burgess_go/features/superintendent_dash/controllers/superintendent_dash_controller.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:burgess_go/features/locations/controllers/location_list_controller.dart';
import 'package:burgess_go/features/locations/widgets/location_card.dart';

// 🔥 Standard Notifier class for Community Filter
class SelectedCommunityNotifier extends Notifier<String?> {
  @override
  String? build() {
    return null;
  }

  void updateCommunity(String? community) {
    state = community;
  }
}

// Provided as autoDispose
final selectedCommunityProvider =
    NotifierProvider.autoDispose<SelectedCommunityNotifier, String?>(
      SelectedCommunityNotifier.new,
    );

class LocationListScreen extends ConsumerWidget {
  const LocationListScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final asyncLocations = ref.watch(locationListControllerProvider);
    final dashState = ref.watch(superintendentDashControllerProvider);

    return Scaffold(
      backgroundColor: Colors.grey[100],
      appBar: AppBar(
        title: const Text("My Addresses"),
        backgroundColor: const Color(0xFF003366),
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            icon: const Icon(Icons.add_location_alt),
            tooltip: "Add New Location",
            onPressed: () => _onAddLocationTapped(context),
          ),
        ],
      ),
      body: asyncLocations.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, stack) => Center(child: Text("Error: $error")),
        data: (locations) {
          final activeLocations = locations
              .where((l) => l.isClosedOut != true)
              .toList();

          final uniqueCommunities =
              activeLocations
                  .map((loc) => loc.community ?? 'Unknown Community')
                  .toSet()
                  .toList()
                ..sort();

          final selectedCommunity = ref.watch(selectedCommunityProvider);

          final filteredLocations = selectedCommunity == null
              ? activeLocations
              : activeLocations
                    .where(
                      (loc) =>
                          (loc.community ?? 'Unknown Community') ==
                          selectedCommunity,
                    )
                    .toList();

          return Column(
            children: [
              // --- The Dropdown UI ---
              Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 8,
                ),
                decoration: BoxDecoration(
                  color: Colors.white,
                  border: Border(bottom: BorderSide(color: Colors.grey[300]!)),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.05),
                      blurRadius: 4,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: DropdownButtonHideUnderline(
                  child: DropdownButton<String?>(
                    isExpanded: true,
                    value: selectedCommunity,
                    icon: const Icon(
                      Icons.arrow_drop_down,
                      color: Color(0xFF003366),
                    ),
                    hint: const Text(
                      "All Communities",
                      style: TextStyle(fontWeight: FontWeight.bold),
                    ),
                    items: [
                      const DropdownMenuItem<String?>(
                        value: null,
                        child: Text(
                          "All Communities",
                          style: TextStyle(fontWeight: FontWeight.bold),
                        ),
                      ),
                      ...uniqueCommunities.map((community) {
                        return DropdownMenuItem<String?>(
                          value: community,
                          child: Text(community),
                        );
                      }),
                    ],
                    onChanged: (value) {
                      ref
                          .read(selectedCommunityProvider.notifier)
                          .updateCommunity(value);
                    },
                  ),
                ),
              ),

              // --- The Fluid Responsive GridView ---
              Expanded(
                child: GridView.builder(
                  padding: const EdgeInsets.all(12),
                  // 🔥 THE MAGIC HAPPENS HERE
                  gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(
                    maxCrossAxisExtent:
                        380, // Cards will never be wider than 380px
                    mainAxisExtent:
                        280, // Hard-locks the height to exactly 280px to prevent overflow
                    crossAxisSpacing: 12,
                    mainAxisSpacing: 12,
                  ),
                  itemCount: filteredLocations.length + 1,
                  itemBuilder: (context, index) {
                    if (index == 0) {
                      return _buildAddLocationCard(context);
                    }

                    final location = filteredLocations[index - 1];

                    final locationInspections = dashState.inspections
                        .where((i) => i.locationId == location.locationId)
                        .toList();

                    return LocationCard(
                      location: location,
                      inspections: locationInspections,
                      onTap: () {
                        context.pushNamed(
                          'location_management',
                          pathParameters: {
                            'locationId': location.locationId.toString(),
                          },
                          extra: {'location': location},
                        );
                      },
                    );
                  },
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  // --- HELPER WIDGETS & METHODS ---

  void _onAddLocationTapped(BuildContext context) {
    context.pushNamed('add_location');
  }

  Widget _buildAddLocationCard(BuildContext context) {
    return InkWell(
      onTap: () => _onAddLocationTapped(context),
      borderRadius: BorderRadius.circular(12),
      child: Container(
        decoration: BoxDecoration(
          color: Colors.blue[50], // Soft blue background
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: const Color(0xFF003366).withValues(alpha: 0.3),
            width: 2,
          ),
        ),
        child: const Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.add_location_alt_outlined,
              size: 48,
              color: Color(0xFF003366),
            ),
            SizedBox(height: 12),
            Text(
              "Add New Address",
              style: TextStyle(
                color: Color(0xFF003366),
                fontWeight: FontWeight.bold,
                fontSize: 14,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
