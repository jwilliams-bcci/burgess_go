import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../controllers/trade_contact_controller.dart';

class TradeContactListScreen extends ConsumerWidget {
  const TradeContactListScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // Watch the AsyncValue state
    final asyncContacts = ref.watch(tradeContactControllerProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text("Trade Rolodex"),
        backgroundColor: Colors.blue[900],
        foregroundColor: Colors.white,
      ),
      floatingActionButton: FloatingActionButton(
        backgroundColor: Colors.blue[900],
        child: const Icon(Icons.person_add, color: Colors.white),
        onPressed: () => showDialog(
          context: context,
          builder: (context) => const _AddContactDialog(),
        ),
      ),
      body: asyncContacts.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, stack) => Center(child: Text("Error: $error")),
        data: (contacts) {
          if (contacts.isEmpty) {
            return const Center(
              child: Text("No trades added yet. Tap + to start."),
            );
          }

          return ListView.builder(
            itemCount: contacts.length,
            itemBuilder: (context, index) {
              final contact = contacts[index];
              return ListTile(
                leading: CircleAvatar(
                  backgroundColor: Colors.blue[100],
                  child: Text(
                    contact.name.isNotEmpty
                        ? contact.name[0].toUpperCase()
                        : '?',
                    style: TextStyle(
                      color: Colors.blue[900],
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                title: Text(
                  contact.name,
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
                subtitle: Text(contact.trade),
                trailing: Text(contact.phone ?? ""),
              );
            },
          );
        },
      ),
    );
  }
}

// --- NEW: Extracted Dialog Widget for Clean Form State Management ---
class _AddContactDialog extends ConsumerStatefulWidget {
  const _AddContactDialog();

  @override
  ConsumerState<_AddContactDialog> createState() => _AddContactDialogState();
}

class _AddContactDialogState extends ConsumerState<_AddContactDialog> {
  final _formKey = GlobalKey<FormState>();
  final _nameCtrl = TextEditingController();
  final _tradeCtrl = TextEditingController();
  final _phoneCtrl = TextEditingController();
  final _emailCtrl = TextEditingController();

  @override
  void dispose() {
    _nameCtrl.dispose();
    _tradeCtrl.dispose();
    _phoneCtrl.dispose();
    _emailCtrl.dispose();
    super.dispose();
  }

  void _submit() {
    // Triggers validation on all TextFormFields
    if (_formKey.currentState!.validate()) {
      ref
          .read(tradeContactControllerProvider.notifier)
          .addContact(
            _nameCtrl.text.trim(),
            _tradeCtrl.text.trim(),
            _phoneCtrl.text.trim().isEmpty ? null : _phoneCtrl.text.trim(),
            _emailCtrl.text.trim().isEmpty ? null : _emailCtrl.text.trim(),
          );
      Navigator.pop(context);
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text("New Trade Contact"),
      content: SingleChildScrollView(
        child: Form(
          key: _formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextFormField(
                controller: _nameCtrl,
                textCapitalization: TextCapitalization.words,
                decoration: const InputDecoration(labelText: "Name *"),
                validator: (val) => val == null || val.trim().isEmpty
                    ? 'Name is required'
                    : null,
              ),
              const SizedBox(height: 8),
              TextFormField(
                controller: _tradeCtrl,
                textCapitalization: TextCapitalization.words,
                decoration: const InputDecoration(
                  labelText: "Trade (e.g. Electrician) *",
                ),
                validator: (val) => val == null || val.trim().isEmpty
                    ? 'Trade is required'
                    : null,
              ),
              const SizedBox(height: 8),
              TextFormField(
                controller: _phoneCtrl,
                keyboardType: TextInputType.phone,
                // Apply the custom formatter!
                inputFormatters: [PhoneInputFormatter()],
                decoration: const InputDecoration(
                  labelText: "Phone (Optional)",
                  hintText: "(555) 555-5555",
                ),
                validator: (val) {
                  if (val != null && val.trim().isNotEmpty && val.length < 14) {
                    return 'Enter a valid 10-digit phone number';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 8),
              TextFormField(
                controller: _emailCtrl,
                keyboardType: TextInputType.emailAddress,
                decoration: const InputDecoration(
                  labelText: "Email (Optional)",
                  hintText: "trade@example.com",
                ),
                validator: (val) {
                  if (val == null || val.trim().isEmpty)
                    return null; // Optional
                  // Standard Email Regex
                  final emailRegex = RegExp(r'^[^@]+@[^@]+\.[^@]+');
                  if (!emailRegex.hasMatch(val.trim())) {
                    return 'Enter a valid email address';
                  }
                  return null;
                },
              ),
            ],
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text("Cancel"),
        ),
        ElevatedButton(
          onPressed: _submit,
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.blue[900],
            foregroundColor: Colors.white,
          ),
          child: const Text("Save"),
        ),
      ],
    );
  }
}

// --- NEW: Custom Formatter for (###) ###-#### ---
class PhoneInputFormatter extends TextInputFormatter {
  @override
  TextEditingValue formatEditUpdate(
    TextEditingValue oldValue,
    TextEditingValue newValue,
  ) {
    // Strip everything except digits
    final digits = newValue.text.replaceAll(RegExp(r'[^\d]'), '');

    if (digits.isEmpty) return const TextEditingValue(text: '');

    final buffer = StringBuffer();

    // Add formatting characters
    if (digits.isNotEmpty) buffer.write('(');
    if (digits.length > 3) {
      buffer.write('${digits.substring(0, 3)}) ');
      if (digits.length > 6) {
        buffer.write('${digits.substring(3, 6)}-');
        // Cap at 10 digits
        buffer.write(
          digits.substring(6, digits.length > 10 ? 10 : digits.length),
        );
      } else {
        buffer.write(digits.substring(3));
      }
    } else {
      buffer.write(digits);
    }

    final formattedText = buffer.toString();

    // Move the cursor to the end
    return TextEditingValue(
      text: formattedText,
      selection: TextSelection.collapsed(offset: formattedText.length),
    );
  }
}
