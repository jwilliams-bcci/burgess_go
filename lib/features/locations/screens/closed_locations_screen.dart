import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:burgess_go/features/locations/controllers/location_list_controller.dart';
import 'package:burgess_go/features/superintendent_dash/controllers/superintendent_dash_controller.dart';
import 'package:burgess_go/features/locations/widgets/location_card.dart';

class ClosedLocationsScreen extends ConsumerWidget {
  const ClosedLocationsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final asyncLocations = ref.watch(locationListControllerProvider);
    final dashState = ref.watch(superintendentDashControllerProvider);

    return Scaffold(
      backgroundColor: Colors.grey[100],
      appBar: AppBar(
        title: const Text("Closed Homes"),
        backgroundColor: Colors.grey[800], // Darker theme for the archive
        foregroundColor: Colors.white,
      ),
      body: asyncLocations.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, stack) => Center(child: Text("Error: $error")),
        data: (locations) {
          final closedLocations = locations
              .where((l) => l.isClosedOut == true)
              .toList();

          if (closedLocations.isEmpty) {
            return const Center(
              child: Text(
                "No closed out homes.",
                style: TextStyle(color: Colors.grey, fontSize: 16),
              ),
            );
          }

          return GridView.builder(
            padding: const EdgeInsets.all(12),
            gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(
              maxCrossAxisExtent: 380,
              mainAxisExtent: 280,
              crossAxisSpacing: 12,
              mainAxisSpacing: 12,
            ),
            itemCount: closedLocations.length,
            itemBuilder: (context, index) {
              final location = closedLocations[index];
              final locationInspections = dashState.inspections
                  .where((i) => i.locationId == location.locationId)
                  .toList();

              return LocationCard(
                location: location,
                inspections: locationInspections,
                isClosedOut: true, // Triggers the UI change in your card!
                onTap: () {
                  context.pushNamed(
                    'location_management',
                    pathParameters: {
                      'locationId': location.locationId.toString(),
                    },
                    extra: {'location': location},
                  );
                },
                onToggleCloseOut: () async {
                  // Run the Firestore update to "Unarchive" it
                  await FirebaseFirestore.instance
                      .collection('locations')
                      .doc(location.locationId.toString())
                      .update({'isClosedOut': false});

                  // Optional: Show a quick snackbar confirmation
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('Home returned to active list')),
                  );
                },
              );
            },
          );
        },
      ),
    );
  }
}
