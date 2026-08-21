 import 'dart:convert';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:http/http.dart' as http;

class ApiService {
  // Deployed Cloud Backend (Render) — works from any Wi-Fi or Mobile Data
  static const String baseUrl = 'https://zonesupply-api.onrender.com/api/v1';
  // static const String baseUrl = 'http://192.168.1.11:3000/api/v1'; // Local Wi-Fi mode
  static const FlutterSecureStorage _storage = FlutterSecureStorage();
  static const String _tokenKey = 'jwt_token';

  static Future<String?> getToken() => _storage.read(key: _tokenKey);
  static Future<void> saveToken(String token) =>
      _storage.write(key: _tokenKey, value: token);
  static Future<void> clearToken() => _storage.delete(key: _tokenKey);

  static Future<Map<String, String>> _authHeaders() async {
    final token = await getToken();
    return {
      'Content-Type': 'application/json',
      if (token != null) 'Authorization': 'Bearer $token',
    };
  }

  static Future<dynamic> get(String path) async {
    final res = await http.get(Uri.parse('$baseUrl$path'),
        headers: await _authHeaders());
    return _handle(res);
  }

  static Future<dynamic> post(String path, Map<String, dynamic> body) async {
    final res = await http.post(Uri.parse('$baseUrl$path'),
        headers: await _authHeaders(), body: jsonEncode(body));
    return _handle(res);
  }

  static Future<dynamic> patch(String path, Map<String, dynamic> body) async {
    final res = await http.patch(Uri.parse('$baseUrl$path'),
        headers: await _authHeaders(), body: jsonEncode(body));
    return _handle(res);
  }

  static Future<dynamic> put(String path, Map<String, dynamic> body) async {
    final res = await http.put(Uri.parse('$baseUrl$path'),
        headers: await _authHeaders(), body: jsonEncode(body));
    return _handle(res);
  }

  // Deployed Membership Backend (Render)
  static const String membershipApiUrl = 'https://zonesupply-membership-api.onrender.com/api';

  static Future<Map<String, dynamic>> checkMembership(String identifier) async {
    try {
      final res = await http.post(
        Uri.parse('$membershipApiUrl/check-membership'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'identifier': identifier}),
      ).timeout(const Duration(seconds: 8));
      final data = jsonDecode(res.body);
      return data is Map<String, dynamic> ? data : {'success': false, 'message': 'Invalid response'};
    } catch (err) {
      return {
        'success': false,
        'isApproved': false,
        'message': 'Unable to connect to membership server. Please ensure backend is running.',
      };
    }
  }

  static dynamic _handle(http.Response res) {
    if (res.statusCode >= 200 && res.statusCode < 300) {
      if (res.body.isEmpty) return null;
      return jsonDecode(res.body);
    }
    final body = jsonDecode(res.body);
    final raw = body['message'];
    final msg = raw is List ? raw.join(', ') : (raw?.toString() ?? 'Error');
    throw ApiException(message: msg, statusCode: res.statusCode);
  }
}

class ApiException implements Exception {
  final String message;
  final int statusCode;
  ApiException({required this.message, required this.statusCode});

  @override
  String toString() => message;
}
