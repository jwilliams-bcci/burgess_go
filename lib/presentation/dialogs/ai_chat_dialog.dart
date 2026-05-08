import 'package:flutter/material.dart';
import '../../core/models/inspection/inspection.dart';
import '../../services/ai_service.dart';

class AIChatDialog extends StatefulWidget {
  final List<Inspection> contextData;

  const AIChatDialog({super.key, required this.contextData});

  @override
  State<AIChatDialog> createState() => _AIChatDialogState();
}

class _AIChatDialogState extends State<AIChatDialog> {
  final TextEditingController _controller = TextEditingController();
  final List<Map<String, String>> _messages =
      []; // 'role': 'user'/'ai', 'text': ...
  bool _isTyping = false;

  void _sendMessage() async {
    final text = _controller.text.trim();
    if (text.isEmpty) return;

    // 1. Show User Message
    setState(() {
      _messages.add({'role': 'user', 'text': text});
      _isTyping = true;
    });
    _controller.clear();

    // 2. Simulate AI Response (Replace this with real API call later)
    // We pass the question AND the data to the "Brain"
    final response = await _getAIResponse(text, widget.contextData);

    // 3. Show AI Response
    if (mounted) {
      setState(() {
        _isTyping = false;
        _messages.add({'role': 'ai', 'text': response});
      });
    }
  }

  // Replace the mock function with this:
  Future<String> _getAIResponse(String question, List<Inspection> data) async {
    // Use your existing service class
    final service = AIService();

    // Call the new method we just added
    return await service.askAboutData(question, data);
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Container(
        width: 400,
        height: 500,
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            // Header
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Colors.blue[50],
                    shape: BoxShape.circle,
                  ),
                  child: Icon(Icons.auto_awesome, color: Colors.blue[700]),
                ),
                const SizedBox(width: 12),
                const Text(
                  "Burgess Buddy",
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
                const Spacer(),
                IconButton(
                  onPressed: () => Navigator.pop(context),
                  icon: const Icon(Icons.close),
                ),
              ],
            ),
            const Divider(),

            // Chat Area
            Expanded(
              child: ListView.builder(
                itemCount: _messages.length,
                itemBuilder: (context, index) {
                  final msg = _messages[index];
                  final isUser = msg['role'] == 'user';
                  return Align(
                    alignment: isUser
                        ? Alignment.centerRight
                        : Alignment.centerLeft,
                    child: Container(
                      margin: const EdgeInsets.symmetric(vertical: 4),
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: isUser ? Colors.blue[600] : Colors.grey[200],
                        borderRadius: BorderRadius.only(
                          topLeft: const Radius.circular(12),
                          topRight: const Radius.circular(12),
                          bottomLeft: isUser
                              ? const Radius.circular(12)
                              : Radius.zero,
                          bottomRight: isUser
                              ? Radius.zero
                              : const Radius.circular(12),
                        ),
                      ),
                      constraints: const BoxConstraints(maxWidth: 260),
                      child: Text(
                        msg['text']!,
                        style: TextStyle(
                          color: isUser ? Colors.white : Colors.black87,
                        ),
                      ),
                    ),
                  );
                },
              ),
            ),

            if (_isTyping)
              const Padding(
                padding: EdgeInsets.all(8.0),
                child: Align(
                  alignment: Alignment.centerLeft,
                  child: Text(
                    "Analyzing data...",
                    style: TextStyle(color: Colors.grey, fontSize: 12),
                  ),
                ),
              ),

            // Input Area
            const SizedBox(height: 8),
            Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _controller,
                    decoration: InputDecoration(
                      hintText: "Ask a question...",
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(24),
                      ),
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 8,
                      ),
                    ),
                    onSubmitted: (_) => _sendMessage(),
                  ),
                ),
                const SizedBox(width: 8),
                CircleAvatar(
                  backgroundColor: Colors.blue[700],
                  child: IconButton(
                    icon: const Icon(Icons.send, color: Colors.white, size: 20),
                    onPressed: _sendMessage,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
