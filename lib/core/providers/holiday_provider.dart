import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:burgess_go/core/providers/service_providers.dart'; // Ensure you have access to apiClientProvider

final holidayProvider = FutureProvider<List<DateTime>>((ref) async {
  final apiClient = ref.read(apiClientProvider);

  try {
    // Hit our brand new endpoint!
    final response = await apiClient.get('/v1/burgessgo/inspections/holidays');

    if (response != null && response is List) {
      // Map the JSON array into a List of Dart DateTimes
      return response
          .map((item) => DateTime.parse(item['holidayDate']))
          .toList();
    }
    return [];
  } catch (e) {
    print("Failed to fetch holidays: $e");
    return []; // Return empty list on failure so the app doesn't crash
  }
});
