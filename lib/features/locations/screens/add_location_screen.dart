import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'package:burgess_go/features/locations/controllers/add_location_controller.dart';
import 'package:burgess_go/features/locations/models/create_location_request.dart';

class AddLocationScreen extends ConsumerStatefulWidget {
  const AddLocationScreen({super.key});

  @override
  ConsumerState<AddLocationScreen> createState() => _AddLocationScreenState();
}

class _AddLocationScreenState extends ConsumerState<AddLocationScreen> {
  final _formKey = GlobalKey<FormState>();

  // Controllers for the Autocomplete Text inputs
  final _communityController = TextEditingController();
  final _streetController = TextEditingController();

  // Standard Form Controllers
  final _streetNumberController = TextEditingController();
  final _cityController = TextEditingController();
  final _lotNumberController = TextEditingController();
  final _sqftController = TextEditingController(text: "1"); // Defaults to 1

  // Local state to track selections
  int? _selectedCommunityId;
  int? _selectedStreetId;
  String? _selectedState;

  // List of standard US State abbreviations
  static const List<String> _usStates = [
    'AL',
    'AK',
    'AZ',
    'AR',
    'CA',
    'CO',
    'CT',
    'DE',
    'FL',
    'GA',
    'HI',
    'ID',
    'IL',
    'IN',
    'IA',
    'KS',
    'KY',
    'LA',
    'ME',
    'MD',
    'MA',
    'MI',
    'MN',
    'MS',
    'MO',
    'MT',
    'NE',
    'NV',
    'NH',
    'NJ',
    'NM',
    'NY',
    'NC',
    'ND',
    'OH',
    'OK',
    'OR',
    'PA',
    'RI',
    'SC',
    'SD',
    'TN',
    'TX',
    'UT',
    'VT',
    'VA',
    'WA',
    'WV',
    'WI',
    'WY',
  ];

  @override
  void initState() {
    super.initState();

    // 🔥 Magic Listener #1: Watch the Community Input
    _communityController.addListener(() {
      final state = ref.read(addLocationControllerProvider);
      final text = _communityController.text.trim();

      // See if what they typed exactly matches an existing community
      final match = state.communities
          .where((c) => c.name.toLowerCase() == text.toLowerCase())
          .firstOrNull;

      if (match != null) {
        if (_selectedCommunityId != match.id) {
          setState(() => _selectedCommunityId = match.id);
          // They selected a real community! Fetch its streets!
          ref
              .read(addLocationControllerProvider.notifier)
              .fetchStreetsForCommunity(match.id);
        }
      } else {
        // They are typing a brand new community
        if (_selectedCommunityId != null) {
          setState(() {
            _selectedCommunityId = null;
            _selectedStreetId = null; // Reset street if community changes
            _streetController.clear();
            _streetNumberController.clear(); // 🔥 Clear number too
          });
        }
      }
    });

    // 🔥 Magic Listener #2: Watch the Street Input
    _streetController.addListener(() {
      final state = ref.read(addLocationControllerProvider);
      final text = _streetController.text.trim();

      final match = state.streets
          .where((s) => s.name.toLowerCase() == text.toLowerCase())
          .firstOrNull;

      if (match != null) {
        if (_selectedStreetId != match.id) {
          setState(() => _selectedStreetId = match.id);

          // 🔥 NEW: Fetch Street Numbers since they picked a real street!
          if (_selectedCommunityId != null) {
            ref
                .read(addLocationControllerProvider.notifier)
                .fetchStreetNumbers(_selectedCommunityId!, match.id);
          }
        }
      } else {
        if (_selectedStreetId != null) {
          setState(() {
            _selectedStreetId = null;
            _streetNumberController
                .clear(); // 🔥 Clear number if street changes
          });
        }
      }
    });
  }

  @override
  void dispose() {
    _communityController.dispose();
    _streetController.dispose();
    _streetNumberController.dispose();
    _cityController.dispose();
    _lotNumberController.dispose();
    _sqftController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;

    final communityText = _communityController.text.trim();
    final streetText = _streetController.text.trim();
    final numberText = _streetNumberController.text.trim();

    if (communityText.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Please select or enter a Community.")),
      );
      return;
    }
    if (streetText.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Please select or enter a Street.")),
      );
      return;
    }
    if (numberText.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("Please select or enter a Street Number."),
        ),
      );
      return;
    }

    // Build the payload mapping perfectly to our C# DTO
    final request = CreateLocationRequest(
      communityId: _selectedCommunityId,
      newCommunityName: _selectedCommunityId == null ? communityText : null,
      streetNameId: _selectedStreetId,
      newStreetName: _selectedStreetId == null ? streetText : null,
      streetNumber: numberText,
      squareFootage: int.tryParse(_sqftController.text) ?? 1,
      city: _cityController.text.trim().isEmpty
          ? null
          : _cityController.text.trim(),
      state: _selectedState,
      lotNumber: _lotNumberController.text.trim().isEmpty
          ? null
          : _lotNumberController.text.trim(),
    );

    final success = await ref
        .read(addLocationControllerProvider.notifier)
        .createLocation(request);

    if (success && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("Home created successfully!"),
          backgroundColor: Colors.green,
        ),
      );
      context.goNamed('locations_list'); // Go back to the list screen
    } else if (mounted) {
      // The controller automatically catches SQL errors and puts them in state.errorMessage
      final error = ref.read(addLocationControllerProvider).errorMessage;
      if (error != null) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(error),
            backgroundColor: Colors.red,
            duration: const Duration(seconds: 4),
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(addLocationControllerProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text("Add New Home"),
        backgroundColor: const Color(0xFF003366),
        foregroundColor: Colors.white,
      ),
      body: state.isBusy && state.communities.isEmpty
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(16.0),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Error Banner
                    if (state.errorMessage != null)
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(12),
                        margin: const EdgeInsets.only(bottom: 16),
                        decoration: BoxDecoration(
                          color: Colors.red[50],
                          border: Border.all(color: Colors.red[200]!),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          state.errorMessage!,
                          style: TextStyle(
                            color: Colors.red[800],
                            fontSize: 13,
                          ),
                        ),
                      ),

                    const Text(
                      "Start typing to search, or type a new name to create one.",
                      style: TextStyle(
                        color: Colors.grey,
                        fontStyle: FontStyle.italic,
                      ),
                    ),
                    const SizedBox(height: 24),

                    // --- 1. COMMUNITY DROPDOWN ---
                    _buildDynamicDropdown(
                      key: const ValueKey('community_dropdown'),
                      controller: _communityController,
                      label: "Community *",
                      items: state.communities,
                      isNew:
                          _selectedCommunityId == null &&
                          _communityController.text.isNotEmpty,
                    ),
                    const SizedBox(height: 16),

                    // --- 2. STREET DROPDOWN ---
                    Stack(
                      alignment: Alignment.centerRight,
                      children: [
                        _buildDynamicDropdown(
                          key: const ValueKey('street_dropdown'),
                          controller: _streetController,
                          label: "Street Name *",
                          items: state.streets,
                          isNew:
                              _selectedStreetId == null &&
                              _streetController.text.isNotEmpty,
                        ),
                        if (state.isLoadingStreets)
                          const Padding(
                            padding: EdgeInsets.only(right: 16.0),
                            child: SizedBox(
                              height: 16,
                              width: 16,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            ),
                          ),
                      ],
                    ),
                    const SizedBox(height: 16),

                    // --- 3. STREET NUMBER (NOW A DROPDOWN) & SQFT ---
                    Row(
                      children: [
                        Expanded(
                          flex: 2,
                          child: Stack(
                            alignment: Alignment.centerRight,
                            children: [
                              // 🔥 Specialized dropdown for the list of Strings!
                              _buildStringDropdown(
                                key: const ValueKey('street_number_dropdown'),
                                controller: _streetNumberController,
                                label: "Street Number *",
                                items: state.streetNumbers,
                              ),
                              if (state.isLoadingStreetNumbers)
                                const Padding(
                                  padding: EdgeInsets.only(right: 16.0),
                                  child: SizedBox(
                                    height: 16,
                                    width: 16,
                                    child: CircularProgressIndicator(
                                      strokeWidth: 2,
                                    ),
                                  ),
                                ),
                            ],
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          flex: 1,
                          child: TextFormField(
                            controller: _sqftController,
                            decoration: const InputDecoration(
                              labelText: 'Sq. Ft.',
                              border: OutlineInputBorder(),
                            ),
                            keyboardType: TextInputType.number,
                            inputFormatters: [
                              FilteringTextInputFormatter.digitsOnly,
                            ],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),

                    // --- 4. CITY & STATE ---
                    Row(
                      children: [
                        Expanded(
                          flex: 2,
                          child: TextFormField(
                            controller: _cityController,
                            decoration: const InputDecoration(
                              labelText: 'City',
                              border: OutlineInputBorder(),
                            ),
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          flex: 1,
                          child: DropdownButtonFormField<String>(
                            initialValue: _selectedState,
                            decoration: const InputDecoration(
                              labelText: 'State',
                              border: OutlineInputBorder(),
                            ),
                            items: _usStates.map((stateAbbr) {
                              return DropdownMenuItem<String>(
                                value: stateAbbr,
                                child: Text(stateAbbr),
                              );
                            }).toList(),
                            onChanged: (value) {
                              setState(() => _selectedState = value);
                            },
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),

                    // --- 5. LOT NUMBER ---
                    TextFormField(
                      controller: _lotNumberController,
                      decoration: const InputDecoration(
                        labelText: 'Lot Number (Optional)',
                        border: OutlineInputBorder(),
                      ),
                    ),
                    const SizedBox(height: 32),

                    // --- SUBMIT BUTTON ---
                    SizedBox(
                      width: double.infinity,
                      height: 50,
                      child: ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF003366),
                          foregroundColor: Colors.white,
                        ),
                        onPressed: state.isBusy ? null : _submit,
                        child: state.isBusy
                            ? const SizedBox(
                                height: 24,
                                width: 24,
                                child: CircularProgressIndicator(
                                  color: Colors.white,
                                ),
                              )
                            : const Text(
                                "Create Home",
                                style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
    );
  }

  // Helper for Communities & Streets (Objects with IDs)
  Widget _buildDynamicDropdown({
    required TextEditingController controller,
    required String label,
    required List<dynamic> items,
    required bool isNew,
    Key? key,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        LayoutBuilder(
          builder: (context, constraints) {
            return DropdownMenu<int>(
              width: constraints.maxWidth,
              controller: controller,
              enableFilter: true,
              enableSearch: true,
              requestFocusOnTap: true,
              label: Text(label),
              inputDecorationTheme: const InputDecorationTheme(
                border: OutlineInputBorder(),
              ),
              dropdownMenuEntries: items.map((item) {
                return DropdownMenuEntry<int>(value: item.id, label: item.name);
              }).toList(),
            );
          },
        ),
        if (isNew)
          Padding(
            padding: const EdgeInsets.only(top: 6.0, left: 4.0),
            child: Text(
              "✨ Creating new: '${controller.text}'",
              style: TextStyle(
                color: Colors.blue[800],
                fontSize: 12,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
      ],
    );
  }

  // 🔥 NEW: Helper for Street Numbers (Simple Strings)
  Widget _buildStringDropdown({
    required TextEditingController controller,
    required String label,
    required List<String> items,
    Key? key,
  }) {
    return LayoutBuilder(
      builder: (context, constraints) {
        return DropdownMenu<String>(
          width: constraints.maxWidth,
          controller: controller,
          enableFilter: true,
          enableSearch: true,
          requestFocusOnTap: true,
          label: Text(label),
          inputDecorationTheme: const InputDecorationTheme(
            border: OutlineInputBorder(),
          ),
          dropdownMenuEntries: items.map((item) {
            return DropdownMenuEntry<String>(value: item, label: item);
          }).toList(),
        );
      },
    );
  }
}
