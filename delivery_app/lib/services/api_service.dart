import 'dart:convert';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:http/http.dart' as http;

class ApiService {
  static const String baseUrl = 'http://10.150.35.51:3000/api/v1'; // Wi-Fi mode (PC LAN IP)
  // static const String baseUrl = 'http://localhost:3000/api/v1'; // USB mode (requires adb reverse tcp:3000 tcp:3000)
  static const FlutterSecureStorage _storage = FlutterSecureStorage();
  static const String _tokenKey = 'jwt_token';

  static Future<String?> getToken() => _storage.read(key: _tokenKey);
  static Future<void> saveToken(String token) =>
      _storage.write(key: _tokenKey, value: token);
  static Future<void> clearToken() => _storage.delete(key: _tokenKey);

  static Future<Map<String, String>> _authHeaders() async {
    final token = await getToken();
    return {'Content-Type': 'application/json',
      if (token != null) 'Authorization': 'Bearer $token'};
  }

  static Future<dynamic> get(String path) async {
    final res = await http.get(Uri.parse('$baseUrl$path'),
        headers: await _authHeaders());
    return _handle(res);
  }

  static Future<dynamic> patch(String path, Map<String, dynamic> body) async {
    final res = await http.patch(Uri.parse('$baseUrl$path'),
        headers: await _authHeaders(), body: jsonEncode(body));
    return _handle(res);
  }

  static Future<dynamic> post(String path, Map<String, dynamic> body) async {
    final res = await http.post(Uri.parse('$baseUrl$path'),
        headers: await _authHeaders(), body: jsonEncode(body));
    return _handle(res);
  }

  static dynamic _handle(http.Response res) {
    if (res.statusCode >= 200 && res.statusCode < 300) {
      if (res.body.isEmpty) return null;
      return jsonDecode(res.body);
    }
    final body = jsonDecode(res.body);
    final raw = body['message'];
    final msg = raw is List ? raw.join(', ') : (raw?.toString() ?? 'Error ${res.statusCode}');
    throw Exception(msg);
  }
}
