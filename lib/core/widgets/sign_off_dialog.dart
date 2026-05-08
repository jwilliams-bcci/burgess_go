import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:signature/signature.dart';
import 'package:image_picker/image_picker.dart';

class SignOffDialog extends StatefulWidget {
  final Function(Uint8List? signatureBytes, XFile? photo) onSubmit;

  const SignOffDialog({super.key, required this.onSubmit});

  @override
  State<SignOffDialog> createState() => _SignOffDialogState();
}

class _SignOffDialogState extends State<SignOffDialog> {
  // Controller for the signature pad
  final SignatureController _sigController = SignatureController(
    penStrokeWidth: 3,
    penColor: Colors.black,
    exportBackgroundColor: Colors.transparent,
  );

  XFile? _selectedPhoto;
  final ImagePicker _picker = ImagePicker();
  bool _isSubmitting = false;

  @override
  void dispose() {
    _sigController.dispose();
    super.dispose();
  }

  Future<void> _pickPhoto() async {
    final XFile? image = await _picker.pickImage(
      source: ImageSource.camera, // or gallery
      imageQuality: 50, // Optimize size
    );
    if (image != null) {
      setState(() => _selectedPhoto = image);
    }
  }

  Future<void> _handleSubmit() async {
    if (_sigController.isEmpty) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text("Please sign to continue.")));
      return;
    }

    setState(() => _isSubmitting = true);

    // Export signature to PNG Bytes
    final Uint8List? sigBytes = await _sigController.toPngBytes();

    if (sigBytes != null) {
      // Pass data back to the parent (Controller)
      widget.onSubmit(sigBytes, _selectedPhoto);
      Navigator.pop(context); // Close dialog
    } else {
      setState(() => _isSubmitting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Container(
        padding: const EdgeInsets.all(16),
        constraints: const BoxConstraints(maxWidth: 400),
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Header
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    "Sign Off & Repair",
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close),
                    onPressed: () => Navigator.pop(context),
                  ),
                ],
              ),
              const Divider(),

              // 1. SIGNATURE PAD
              const Padding(
                padding: EdgeInsets.only(bottom: 8.0),
                child: Text(
                  "Superintendent Signature:",
                  style: TextStyle(fontWeight: FontWeight.w600),
                ),
              ),
              Container(
                decoration: BoxDecoration(
                  border: Border.all(color: Colors.grey[300]!),
                  borderRadius: BorderRadius.circular(8),
                  color: Colors.grey[50],
                ),
                child: Signature(
                  controller: _sigController,
                  height: 150,
                  backgroundColor: Colors.grey[50]!,
                ),
              ),
              Align(
                alignment: Alignment.centerRight,
                child: TextButton(
                  onPressed: () => _sigController.clear(),
                  child: const Text(
                    "Clear Signature",
                    style: TextStyle(color: Colors.red),
                  ),
                ),
              ),

              const SizedBox(height: 16),

              // 2. PHOTO UPLOAD
              const Text(
                "Repair Photo (Optional):",
                style: TextStyle(fontWeight: FontWeight.w600),
              ),
              const SizedBox(height: 8),
              InkWell(
                onTap: _pickPhoto,
                child: Container(
                  height: 100,
                  decoration: BoxDecoration(
                    color: Colors.blue[50],
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(
                      color: Colors.blue[200]!,
                      style: BorderStyle.solid,
                    ),
                  ),
                  child: _selectedPhoto == null
                      ? Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              Icons.camera_alt,
                              color: Colors.blue[800],
                              size: 32,
                            ),
                            const SizedBox(height: 4),
                            Text(
                              "Tap to take photo",
                              style: TextStyle(color: Colors.blue[800]),
                            ),
                          ],
                        )
                      : Stack(
                          fit: StackFit.expand,
                          children: [
                            // Show generic icon for web or raw file logic could be added here
                            // For simplicity, we just show "File Selected"
                            Center(
                              child: Text(
                                "Photo Selected:\n${_selectedPhoto!.name}",
                                textAlign: TextAlign.center,
                                style: TextStyle(
                                  color: Colors.green[800],
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                            Positioned(
                              top: 4,
                              right: 4,
                              child: Icon(
                                Icons.check_circle,
                                color: Colors.green[600],
                              ),
                            ),
                          ],
                        ),
                ),
              ),

              const SizedBox(height: 24),

              // 3. SUBMIT BUTTON
              ElevatedButton(
                onPressed: _isSubmitting ? null : _handleSubmit,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.green[700],
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
                child: _isSubmitting
                    ? const SizedBox(
                        height: 20,
                        width: 20,
                        child: CircularProgressIndicator(
                          color: Colors.white,
                          strokeWidth: 2,
                        ),
                      )
                    : const Text(
                        "COMPLETE ITEM",
                        style: TextStyle(fontWeight: FontWeight.bold),
                      ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
