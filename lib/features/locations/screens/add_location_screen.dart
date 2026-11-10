import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'package:burgess_go/features/locations/controllers/add_location_controller.dart';
import 'package:burgess_go/features/locations/models/create_location_request.dart';
import 'package:burgess_go/features/locations/states/add_location_state.dart';

// --- STRING FORMATTING UTILITIES ---
extension StringFormatting on String {
  /// Converts a string to Title Case (e.g., "my community" -> "My Community")
  String toTitleCase() {
    if (trim().isEmpty) return this;
    return trim()
        .split(RegExp(r'\s+'))
        .map((word) {
          if (word.isEmpty) return word;
          return word[0].toUpperCase() + word.substring(1).toLowerCase();
        })
        .join(' ');
  }

  /// Expands common street abbreviations at the end of a string
  String expandStreetSuffix() {
    if (trim().isEmpty) return this;
    final words = split(RegExp(r'\s+'));

    // Grab the last word and remove any periods (e.g., "Blvd." -> "blvd")
    final lastWord = words.last.toLowerCase().replaceAll('.', '');

    const suffixes = {
      'ave': 'Avenue',
      'blvd': 'Boulevard',
      'cir': 'Circle',
      'ct': 'Court',
      'dr': 'Drive',
      'hwy': 'Highway',
      'ln': 'Lane',
      'pkwy': 'Parkway',
      'pl': 'Place',
      'rd': 'Road',
      'st': 'Street',
      'sq': 'Square',
      'ter': 'Terrace',
      'trl': 'Trail',
      'wy': 'Way',
      'way': 'Way',
    };

    if (suffixes.containsKey(lastWord)) {
      words[words.length - 1] = suffixes[lastWord]!;
      return words.join(' ');
    }
    return this;
  }

  /// Strips out everything except letters and numbers for fair comparisons
  /// (e.g., "101-A" and "101 A" both become "101a")
  String normalizeForComparison() {
    return toLowerCase().replaceAll(RegExp(r'[^a-z0-9]'), '');
  }
}

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
  final _stateController = TextEditingController();

  // Standard Form Controllers
  final _streetNumberController = TextEditingController();
  final _cityController = TextEditingController();
  final _lotNumberController = TextEditingController();
  final _sqftController = TextEditingController(text: "1");

  // 🔥 Focus node to detect when the user taps the Sq. Ft. field
  final _sqftFocusNode = FocusNode();

  // Local state to track selections
  int? _selectedCommunityId;
  int? _selectedStreetId;

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

    // 🔥 Highlight all text when Square Footage field is tapped
    _sqftFocusNode.addListener(() {
      if (_sqftFocusNode.hasFocus) {
        // We use microtask to ensure this happens AFTER the tap cursor is placed
        Future.microtask(() {
          _sqftController.selection = TextSelection(
            baseOffset: 0,
            extentOffset: _sqftController.text.length,
          );
        });
      }
    });

    // 🔥 Magic Listener #1: Watch the Community Input
    _communityController.addListener(() {
      final state = ref.read(addLocationControllerProvider);
      final text = _communityController.text.trim();

      final match = state.communities
          .where((c) => c.name.toLowerCase() == text.toLowerCase())
          .firstOrNull;

      if (match != null) {
        if (_selectedCommunityId != match.id) {
          setState(() {
            _selectedCommunityId = match.id;

            // Pre-populate City & State strongly typed
            if (match.city != null && match.city!.trim().isNotEmpty) {
              _cityController.text = match.city!.toTitleCase();
            }
            if (match.state != null && match.state!.trim().isNotEmpty) {
              _stateController.text = match.state!.toUpperCase();
            }
          });
          ref
              .read(addLocationControllerProvider.notifier)
              .fetchStreetsForCommunity(match.id);
        }
      } else {
        if (_selectedCommunityId != null) {
          setState(() {
            _selectedCommunityId = null;
            _selectedStreetId = null;
            _streetController.clear();
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
          });
        }
      }
    });
  }

  @override
  void dispose() {
    _sqftFocusNode.dispose(); // 🔥 Clean up the focus node!
    _communityController.dispose();
    _streetController.dispose();
    _stateController.dispose();
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
        const SnackBar(content: Text("Please enter a Street Number.")),
      );
      return;
    }

    final request = CreateLocationRequest(
      communityId: _selectedCommunityId,
      newCommunityName: _selectedCommunityId == null
          ? communityText.toTitleCase()
          : null,
      streetNameId: _selectedStreetId,
      newStreetName: _selectedStreetId == null
          ? streetText.toTitleCase().expandStreetSuffix()
          : null,
      streetNumber: numberText,
      squareFootage: int.tryParse(_sqftController.text) ?? 1,
      city: _cityController.text.trim().isEmpty
          ? null
          : _cityController.text.trim().toTitleCase(),
      state: _stateController.text.trim().isEmpty
          ? null
          : _stateController.text.trim().toUpperCase(),
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
      context.pushNamed('locations_list');
    } else if (mounted) {
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

    // 🔥 THE MAGIC: Lazy Auto-Correct Listener
    ref.listen<AddLocationState>(addLocationControllerProvider, (
      previous,
      next,
    ) {
      if (previous?.isLoadingStreetNumbers == true &&
          next.isLoadingStreetNumbers == false) {
        final typedNumber = _streetNumberController.text;

        if (typedNumber.isNotEmpty && next.streetNumbers.isNotEmpty) {
          final normalizedTyped = typedNumber.normalizeForComparison();

          final dbMatch = next.streetNumbers.where((dbNum) {
            return dbNum.normalizeForComparison() == normalizedTyped;
          }).firstOrNull;

          if (dbMatch != null && dbMatch != typedNumber) {
            _streetNumberController.text = dbMatch;

            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text("✨ Auto-formatted street number: $dbMatch"),
                duration: const Duration(seconds: 2),
                backgroundColor: Colors.blue[800],
              ),
            );
          }
        }
      }
    });

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

                    // --- 2. STREET NUMBER (Moved up!) & SQFT ---
                    Row(
                      children: [
                        Expanded(
                          flex: 2,
                          child: TextFormField(
                            controller: _streetNumberController,
                            decoration: const InputDecoration(
                              labelText: 'Street Number *',
                              border: OutlineInputBorder(),
                            ),
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          flex: 1,
                          child: TextFormField(
                            controller: _sqftController,
                            focusNode:
                                _sqftFocusNode, // 🔥 Attach the FocusNode
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

                    // --- 3. STREET DROPDOWN (Moved down!) ---
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
                          child: LayoutBuilder(
                            builder: (context, constraints) {
                              return DropdownMenu<String>(
                                width: constraints.maxWidth,
                                menuHeight:
                                    200, // 🔥 Constrain dropdown height (shows ~3-4 states)
                                controller: _stateController,
                                enableFilter: true,
                                enableSearch: true,
                                requestFocusOnTap: true,
                                label: const Text('State'),
                                inputDecorationTheme:
                                    const InputDecorationTheme(
                                      border: OutlineInputBorder(),
                                    ),
                                dropdownMenuEntries: _usStates.map((stateAbbr) {
                                  return DropdownMenuEntry<String>(
                                    value: stateAbbr,
                                    label: stateAbbr,
                                  );
                                }).toList(),
                              );
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
            // 🔥 Removed ValueListenableBuilder so entries are ALWAYS populated.
            // This allows the menu to instantly pop open on tap!
            return DropdownMenu<int>(
              width: constraints.maxWidth,
              menuHeight: 200, // Constrain dropdown height (shows ~3-4 items)
              controller: controller,
              enableFilter: true,
              enableSearch: true,
              requestFocusOnTap: true,
              label: Text(label),
              hintText:
                  'Type to search or add new entry', // 🔥 Added intuitive hint text
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
              "✨ Creating new: '${controller.text.toTitleCase().expandStreetSuffix()}'",
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
}
