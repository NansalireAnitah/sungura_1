import 'dart:convert';
import 'package:http/http.dart' as http;

class AuthService {
  static const String baseUrl = "http://127.0.0.1:5000/api/v1/users"; // Updated to /api/v1/users
  static const String registerUrl = "$baseUrl/register"; // Now http://127.0.0.1:5000/api/v1/users/register
  static const String loginUrl = "$baseUrl/login";       // Now http://127.0.0.1:5000/api/v1/users/login

  // Register a new user
  Future<Map<String, dynamic>> register({
    required String name,
    required String phoneNumber,
    required String password,
  }) async {
    try {
      final response = await http.post(
        Uri.parse(registerUrl),
        headers: {'Content-Type': 'application/json'},
        body: json.encode({
          'name': name,
          'phoneNumber': phoneNumber,
          'password': password,
        }),
      );

      return _processResponse(response);
    } catch (e) {
      return _handleError(e);
    }
  }

  // Login an existing user
  Future<Map<String, dynamic>> login({
    required String phoneNumber,
    required String password,
  }) async {
    try {
      final response = await http.post(
        Uri.parse(loginUrl),
        headers: {'Content-Type': 'application/json'},
        body: json.encode({
          'phoneNumber': phoneNumber,
          'password': password,
        }),
      );

      return _processResponse(response);
    } catch (e) {
      return _handleError(e);
    }
  }

  // Process the API response
  Map<String, dynamic> _processResponse(http.Response response) {
    try {
      final data = jsonDecode(response.body);
      return {
        'success': response.statusCode == 200 || response.statusCode == 201,
        'message': data['message'] ?? 'Operation completed.',
        'data': data, // Could include token or user info from your backend
      };
    } catch (e) {
      return {
        'success': false,
        'message': 'Invalid server response.',
      };
    }
  }

  // Handle errors
  Map<String, dynamic> _handleError(dynamic e) {
    return {
      'success': false,
      'message': 'Network error: ${e.toString()}\nPlease check your internet connection.',
    };
  }
}