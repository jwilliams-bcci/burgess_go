import 'dart:convert';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:collection/collection.dart';
import 'package:intl/intl.dart';

String encodeToJson<T>(T object, Map<String, dynamic> Function(T) toJson) {
  return jsonEncode(toJson(object));
}

DateTime? parseDateTimeFromTimestamp(dynamic value) {
  if (value == null) {
    return null;
  }
  if (value is String) {
    return DateTime.tryParse(value);
  }
  if (value is Timestamp) {
    return value.toDate();
  }
  return null; // Handle other cases if needed
}

String formatTimestamp(Timestamp timestamp) {
  DateTime dateTime = timestamp.toDate();
  final formatter = DateFormat('MMM d, yyy HH:mm:ss');
  return formatter.format(dateTime);
}

String formatDateTime(DateTime? dateTime) {
  final formatter = DateFormat('MMM d, yyy HH:mm');
  return formatter.format(dateTime!);
}

Map<String, dynamic> findDifferences(
  Map<String, dynamic> map1,
  Map<String, dynamic> map2,
) {
  final Map<String, dynamic> differences = {};
  const DeepCollectionEquality deepEquality = DeepCollectionEquality();

  // Check for keys that exist in map1 but not in map2 (potential removals)
  // or keys that exist in both but have different values.
  for (final key in map1.keys) {
    if (!map2.containsKey(key)) {
      // Key exists in map1 but not in map2 - indicates removal
      differences[key] = null; // Or FieldValue.delete() for Firestore update if that's the intent
    } else {
      // Key exists in both, compare values
      final value1 = map1[key];
      final value2 = map2[key];

      // Use DeepCollectionEquality for comparison
      // This will deeply compare lists, maps, and other collections.
      if (!deepEquality.equals(value1, value2)) {
        differences[key] = value2; // The new value from map2
      }
      // If values are equal (even deeply), do nothing.
    }
  }

  // Check for keys that exist in map2 but not in map1 (new keys)
  for (final key in map2.keys) {
    if (!map1.containsKey(key)) {
      // Key exists in map2 but not in map1 - indicates a new key
      differences[key] = map2[key]; // The new value from map2
    }
    // If key exists in map1, it was already handled in the first loop.
  }

  return differences;
}
