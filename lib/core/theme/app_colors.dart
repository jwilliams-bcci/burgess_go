import 'package:flutter/material.dart';

/// Centralized color palette for Burgess GO.
/// Keeps UI consistent and prevents hard-coded hex values scattered across the app.
class AppColors {
  // Brand Colors
  static const Color burgessBlue = Color(0xFF002395);
  static const Color burgessOrange = Color(0xFFF27D00);

  // Neutral & Background Colors (Optimized for outdoor contrast)
  static const Color backgroundLight = Color(
    0xFFF8F9FA,
  ); // Off-white to reduce glare
  static const Color surfaceLight = Colors.white; // Pure white for cards to pop

  // Text Colors
  static const Color textPrimary = Color(
    0xFF111827,
  ); // Near black for high legibility
  static const Color textSecondary = Color(0xFF4B5563); // Gray for helper text

  // Status Colors (Crucial for a construction app)
  static const Color success = Color(0xFF10B981); // Passed Inspections
  static const Color error = Color(0xFFEF4444); // Failed / Defects
  static const Color warning = Color(0xFFF59E0B); // Pending / Re-inspect
}
