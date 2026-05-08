import 'package:flutter/material.dart';
import 'package:burgess_go/core/models/location/location.dart';
import 'package:burgess_go/core/models/inspection/inspection.dart';
import 'package:burgess_go/core/models/location/inspection_type.dart';

class LocationCard extends StatelessWidget {
  final Location? location;
  final List<Inspection> inspections;
  final VoidCallback onTap;
  final bool isClosedOut;
  final VoidCallback? onToggleCloseOut;

  const LocationCard({
    super.key,
    required this.location,
    required this.inspections,
    required this.onTap,
    this.isClosedOut = false,
    this.onToggleCloseOut,
  });

  @override
  Widget build(BuildContext context) {
    // 1. Address & Lot Number
    String addressLine = location?.address ?? "Unknown Address";
    if (location?.lotNumber != null && location!.lotNumber!.isNotEmpty) {
      addressLine = "$addressLine - Lot ${location!.lotNumber}";
    }

    // 2. Community
    String community = location?.community ?? "Unknown Community";

    // 3. Inspection Types (Contract)
    final contractTypes = location?.availableInspectionTypes ?? [];

    return Card(
      elevation: 2,
      margin: const EdgeInsets.only(bottom: 12),
      clipBehavior:
          Clip.antiAlias, // Ensures the top image gets rounded corners
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(color: Colors.grey.withValues(alpha: 0.2), width: 1),
      ),
      child: InkWell(
        onTap: onTap,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // --- UPGRADE 1: THE HERO IMAGE HEADER ---
            SizedBox(
              height: 140, // Fixed height for the hero image
              child: Stack(
                fit: StackFit.expand,
                children: [
                  // The Background Photo
                  _buildHeroImage(),

                  // The Dark Gradient Overlay (for text readability)
                  Container(
                    decoration: const BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: [
                          Colors.transparent,
                          Colors
                              .black87, // Darkens at the bottom where text lives
                        ],
                        stops: [0.4, 1.0],
                      ),
                    ),
                  ),

                  // The Overlay Text (Address & Community)
                  Positioned(
                    bottom: 12,
                    left: 16,
                    right: 16,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          addressLine,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            letterSpacing: 0.3,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 4),
                        Row(
                          children: [
                            const Icon(
                              Icons.location_city,
                              color: Colors.white70,
                              size: 14,
                            ),
                            const SizedBox(width: 4),
                            Expanded(
                              child: Text(
                                community,
                                style: const TextStyle(
                                  color: Colors.white70,
                                  fontSize: 13,
                                  fontWeight: FontWeight.w500,
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),

            // --- UPGRADE 2: PROGRESS TRACKER ---
            Expanded(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: isClosedOut
                    ? _buildClosedOutSection()
                    : _buildProgressSection(contractTypes),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // --- HELPER: Hero Image logic ---
  Widget _buildHeroImage() {
    if (location?.elevationPhotoUrl != null &&
        location!.elevationPhotoUrl!.isNotEmpty) {
      return Image.network(
        location!.elevationPhotoUrl!,
        fit: BoxFit.cover,
        errorBuilder: (context, error, stackTrace) => _buildPlaceholder(),
      );
    }
    return _buildPlaceholder();
  }

  // A premium placeholder for homes without a photo yet
  Widget _buildPlaceholder() {
    return Container(
      color: const Color(0xFF003366), // Burgess Blue
      child: const Center(
        child: Icon(Icons.home_work_outlined, color: Colors.white24, size: 64),
      ),
    );
  }

  // --- HELPER: Phase & Progress Logic ---
  Widget _buildProgressSection(List<InspectionType> types) {
    if (types.isEmpty) {
      return Center(
        child: Text(
          "No contract types assigned.",
          style: TextStyle(
            color: Colors.grey[500],
            fontStyle: FontStyle.italic,
          ),
        ),
      );
    }

    // 1. Calculate Progress
    final total = types.length;
    final passed = types.where((t) => t.iconStatus == 'Pass').length;
    final double progressPercent = total > 0 ? passed / total : 0;

    // 2. Determine "Next Action" or "Current Phase"
    // Find the first inspection that has NOT passed yet.
    InspectionType? activePhase;
    try {
      activePhase = types.firstWhere((t) => t.iconStatus != 'Pass');
    } catch (e) {
      activePhase = null; // Everything passed!
    }

    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Progress Bar Info Row
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              "BUILD PROGRESS",
              style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.bold,
                letterSpacing: 0.8,
                color: Colors.grey[600],
              ),
            ),
            Text(
              "${(progressPercent * 100).toInt()}%",
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.bold,
                color: const Color(0xFF003366), // Burgess Blue
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),

        // The Actual Progress Bar
        ClipRRect(
          borderRadius: BorderRadius.circular(4),
          child: LinearProgressIndicator(
            value: progressPercent,
            minHeight: 8,
            backgroundColor: Colors.grey[200],
            valueColor: const AlwaysStoppedAnimation<Color>(Color(0xFF003366)),
          ),
        ),
        const SizedBox(height: 16),

        // Action Item / Current Phase Status
        if (activePhase == null)
          _buildActionRow(
            Icons.check_circle,
            "All Inspections Passed",
            Colors.green,
          )
        else if (activePhase.iconStatus == 'Fail')
          // 🔥 Highlight failures in RED
          _buildActionRow(
            Icons.cancel,
            "${activePhase.typeName} FAILED",
            Colors.red,
          )
        else
          // Standard "Next Up" pending/scheduled item
          _buildActionRow(
            Icons.play_arrow_rounded,
            "Next: ${activePhase.typeName}",
            const Color(0xFFF27D00),
          ),
      ],
    );
  }

  Widget _buildActionRow(IconData icon, String text, Color color) {
    return Row(
      children: [
        Icon(icon, size: 20, color: color),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            text,
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.bold,
              color: color,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ],
    );
  }

  // --- HELPER: Closed Out State ---
  Widget _buildClosedOutSection() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        const Row(
          children: [
            Icon(Icons.archive, color: Colors.grey, size: 20),
            SizedBox(width: 8),
            Text(
              "CLOSED OUT",
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.bold,
                letterSpacing: 1.2,
                color: Colors.grey,
              ),
            ),
          ],
        ),
        OutlinedButton.icon(
          onPressed: onToggleCloseOut,
          icon: const Icon(Icons.unarchive, size: 18),
          label: const Text("Re-open"),
          style: OutlinedButton.styleFrom(
            foregroundColor: const Color(0xFF003366), // Burgess Blue
            side: const BorderSide(color: Color(0xFF003366)),
          ),
        ),
      ],
    );
  }
}
