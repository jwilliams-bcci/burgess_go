import 'package:burgess_go/core/utils/scheduling_helper.dart';
import 'package:burgess_go/core/models/location/inspection_type.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

class ScheduleDateDialog extends StatefulWidget {
  final String title;
  final List<DateTime> companyHolidays;
  final List<InspectionType>? availableInspectionTypes;

  const ScheduleDateDialog({
    super.key,
    required this.title,
    this.companyHolidays = const [],
    this.availableInspectionTypes,
  });

  @override
  State<ScheduleDateDialog> createState() => _ScheduleDateDialogState();
}

class _ScheduleDateDialogState extends State<ScheduleDateDialog> {
  DateTime? _selectedDate;
  int? _selectedInspectionTypeId; // Holds the selected dropdown value
  final TextEditingController _notesController = TextEditingController();

  @override
  void dispose() {
    _notesController.dispose();
    super.dispose();
  }

  Future<void> _pickDate() async {
    final firstValidDate = SchedulingHelper.getFirstAvailableDate(
      widget.companyHolidays,
    );

    final picked = await showDatePicker(
      context: context,
      initialDate: firstValidDate,
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 365)),
      selectableDayPredicate: (DateTime day) {
        return SchedulingHelper.isDaySelectable(
          day,
          firstValidDate,
          widget.companyHolidays,
        );
      },
    );

    if (picked != null) {
      setState(() => _selectedDate = picked);
    }
  }

  // Helper to determine if the form is valid
  bool get _isFormValid {
    if (_selectedDate == null) return false;

    // If types were provided, one MUST be selected
    if (widget.availableInspectionTypes != null &&
        widget.availableInspectionTypes!.isNotEmpty &&
        _selectedInspectionTypeId == null) {
      return false;
    }

    return true;
  }

  @override
  Widget build(BuildContext context) {
    // Check if we need to show the dropdown
    final showTypeDropdown =
        widget.availableInspectionTypes != null &&
        widget.availableInspectionTypes!.isNotEmpty;

    return AlertDialog(
      title: Text(widget.title),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // --- Inspection Type Dropdown ---
            if (showTypeDropdown) ...[
              DropdownButtonFormField<int>(
                value: _selectedInspectionTypeId,
                decoration: const InputDecoration(
                  labelText: "Inspection Type *",
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.assignment),
                ),
                hint: const Text("Select an inspection type"),
                items: widget.availableInspectionTypes!.map((type) {
                  // 🔥 Check the iconStatus we mapped from the SQL database
                  final isUnavailable = [
                    'Pass',
                    'Scheduled',
                    'Pending',
                  ].contains(type.iconStatus);

                  return DropdownMenuItem<int>(
                    value: type.inspectionTypeId,
                    enabled:
                        !isUnavailable, // 🔥 Disables clicking if unavailable
                    child: Text(
                      isUnavailable
                          ? "${type.typeName} (${type.iconStatus})"
                          : type.typeName,
                      style: TextStyle(
                        color: isUnavailable ? Colors.grey : null,
                        fontStyle: isUnavailable
                            ? FontStyle.italic
                            : FontStyle.normal,
                      ),
                    ),
                  );
                }).toList(),
                onChanged: (value) {
                  setState(() => _selectedInspectionTypeId = value);
                },
              ),
              const SizedBox(height: 16),
            ],

            // --- Date Picker Row ---
            Row(
              children: [
                Expanded(
                  child: Text(
                    _selectedDate == null
                        ? "Select Date *"
                        : "Date: ${DateFormat('MM/dd/yyyy').format(_selectedDate!)}",
                    style: TextStyle(
                      color: _selectedDate == null ? Colors.red : Colors.black,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                TextButton.icon(
                  icon: const Icon(Icons.calendar_month),
                  label: const Text("Pick Date"),
                  onPressed: _pickDate,
                ),
              ],
            ),
            const Divider(),
            const SizedBox(height: 8),

            // --- Notes Field ---
            TextField(
              controller: _notesController,
              maxLines: 3,
              decoration: const InputDecoration(
                labelText: "Notes (Optional)",
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.notes),
              ),
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text("Cancel"),
        ),
        ElevatedButton(
          onPressed: !_isFormValid
              ? null
              : () {
                  Navigator.pop(context, {
                    'date': _selectedDate,
                    'inspectionTypeId': _selectedInspectionTypeId,
                    'notes': _notesController.text,
                  });
                },
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.blue[900],
            foregroundColor: Colors.white,
          ),
          child: const Text("Confirm"),
        ),
      ],
    );
  }
}
