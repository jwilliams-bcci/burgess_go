import 'package:google_generative_ai/google_generative_ai.dart';
import '../core/models/inspection/inspection.dart';

class AIService {
  // ⚠️ SECURITY WARNING: In production, do not hardcode keys.
  static const String _apiKey = 'AIzaSyB5qTOUoJThLBTUvnQJTRVgo0XGufU8yzw';

  late final GenerativeModel _model;

  AIService() {
    // gemini-1.5-flash is perfect for large context windows (1M tokens)
    // It can easily read thousands of inspection rows.
    _model = GenerativeModel(model: 'gemini-2.5-pro', apiKey: _apiKey);
  }

  // --- EXISTING SUPERINTENDENT FUNCTION ---
  Future<String> explainDefect(String category, String description) async {
    try {
      final prompt =
          '''
You are an expert building code inspector. 
Category: $category
Defect: $description

1. Explain why this is a violation of the International Residential Code (IRC).
2. Cite the specific IRC code section if possible.
3. Keep the response concise (under 60 words).
''';
      final content = [Content.text(prompt)];
      final response = await _model.generateContent(content);
      return response.text ?? "Unable to generate explanation.";
    } catch (e) {
      print("AI Service Error: $e");
      return "Could not contact Code Assistant.";
    }
  }

  // --- AREA MANAGER FUNCTION ---
  Future<String> askAboutData(
    String userQuestion,
    List<Inspection> data,
  ) async {
    try {
      // 1. Build the Condensed Data Table (The "Database" for the AI)
      // We take the last 500 items to ensure we stay within safe limits,
      // but Gemini 1.5 Flash can actually handle much more if needed.
      final systemContext = _buildCondensedTable(data);

      // 2. Combine with User Question
      final fullPrompt =
          '''
SYSTEM ROLE: Data Analyst.
You have access to the following inspection logs (Format: Date | Status | Community | Address | Type | Super | Defects).

DATA LOGS:
$systemContext

USER QUESTION: "$userQuestion"

INSTRUCTIONS:
- Search the logs above to find the exact answer.
- If asking about a specific address, look for partial matches.
- If asking for a count (e.g. "how many defects"), sum the numbers in the [Defects] column.
- Keep answers short and direct.
''';

      final content = [Content.text(fullPrompt)];
      final response = await _model.generateContent(content);

      return response.text ?? "I couldn't find that information.";
    } catch (e) {
      print("AI Data Error: $e");
      return "Error analyzing data.";
    }
  }

  // --- HELPER: Turn Objects into a Text Table ---
  String _buildCondensedTable(List<Inspection> inspections) {
    if (inspections.isEmpty) return "No data available.";

    // Sort by date (Newest first) so recent answers are prioritized
    inspections.sort(
      (a, b) => (b.inspectionDate ?? DateTime(2000)).compareTo(
        a.inspectionDate ?? DateTime(2000),
      ),
    );

    // Header for the AI to understand columns
    StringBuffer buffer = StringBuffer();
    buffer.writeln(
      "Date | Status | Community | Address | Type | Super | Defects",
    );

    // Take the most recent 500 records (Adjust this number based on performance needs)
    final subset = inspections.take(500);

    for (var i in subset) {
      final date = _formatDate(i.inspectionDate);
      // Simplify Status (Pass/Fail/Cancel)
      String status = "Other";
      final r = (i.resolution ?? '').toLowerCase();
      if (r.contains('pass') || r.contains('performed'))
        status = "PASS";
      else if (r.contains('fail') || r.contains('not ready'))
        status = "FAIL";
      else if (r.contains('cancel') || r.contains('defer'))
        status = "CNCL";

      final comm = i.community ?? "N/A";
      final addr = i.address ?? "No Addr";
      // Clean Type Name
      String type = (i.inspectionType ?? "N/A").replaceAll(
        RegExp(r'\s*-\s*\d+$'),
        '',
      );
      final sup = (i.superName ?? "N/A")
          .split(' ')
          .first; // First name only to save space
      final def = i.submission?.inspectionTotal ?? 0;

      // Write the row
      buffer.writeln("$date | $status | $comm | $addr | $type | $sup | $def");
    }

    return buffer.toString();
  }

  String _formatDate(DateTime? d) {
    if (d == null) return "--/--";
    return "${d.month}/${d.day}";
  }
}
