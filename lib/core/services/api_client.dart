import 'dart:convert';
import 'package:burgess_go/features/auth/services/auth_service.dart';
import 'package:http/http.dart' as http;
import '../constants/api_constants.dart';

class ApiClient {
  final IAuthService _authService;

  ApiClient(this._authService);

  /// Standard GET request
  /// Automatically adds Base URL + Auth Headers
  Future<dynamic> get(String endpoint) async {
    final uri = Uri.parse('${ApiConstants.baseUrl}$endpoint');
    final headers = _getHeaders();

    final response = await http.get(uri, headers: headers);
    return _handleResponse(response);
  }

  /// Standard POST request
  Future<dynamic> post(String endpoint, Map<String, dynamic> body) async {
    final uri = Uri.parse('${ApiConstants.baseUrl}$endpoint');
    final headers = _getHeaders();

    final response = await http.post(
      uri,
      headers: headers,
      body: jsonEncode(body),
    );
    return _handleResponse(response);
  }

  // --- PRIVATE HELPERS ---

  Map<String, String> _getHeaders() {
    final token = _authService.apiToken;
    return {
      'Content-Type': 'application/json',
      if (token != null) 'Authorization': 'Bearer $token',
    };
  }

  dynamic _handleResponse(http.Response response) {
    // 1. Success
    if (response.statusCode >= 200 && response.statusCode < 300) {
      if (response.body.isEmpty) return null;
      return jsonDecode(response.body);
    }

    // 2. Auth Error (401)
    if (response.statusCode == 401) {
      // Optional: Trigger a logout via a callback if needed
      throw Exception("Unauthorized: Token expired or invalid.");
    }

    // 3. Other Errors
    throw Exception('API Error ${response.statusCode}: ${response.body}');
  }
}
