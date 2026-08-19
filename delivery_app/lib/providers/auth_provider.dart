import 'package:flutter/foundation.dart';
import 'package:google_sign_in/google_sign_in.dart';
import '../services/api_service.dart';
import '../services/delivery_service.dart';

class AuthProvider extends ChangeNotifier {
  Map<String, dynamic>? _user;
  bool _loading = false;
  String? _error;
  String? _pendingOtpPhone;

  bool get isLoggedIn => _user != null;
  Map<String, dynamic>? get user => _user;
  bool get loading => _loading;
  String? get error => _error;
  String? get pendingOtpPhone => _pendingOtpPhone;

  final GoogleSignIn _googleSignIn = GoogleSignIn(scopes: ['email', 'profile']);

  // ── Auto login ──────────────────────────────────────────────────────────
  Future<void> tryAutoLogin() async {
    final token = await ApiService.getToken();
    if (token == null) return;
    try {
      if (DeliveryService.useMockData || token == 'mock-jwt-token') {
        _user = {
          'id': 'mock-partner-123',
          'name': 'Nafeesh (Mock Agent)',
          'email': 'agent@zonesupply.com',
          'phone': '+91 98845 12093',
          'role': 'DELIVERY',
        };
        notifyListeners();
        return;
      }
      final me = await ApiService.get('/users/me');
      if (me['role'] != 'DELIVERY') {
        throw Exception('Access denied. Not a Delivery agent.');
      }
      _user = me;
      notifyListeners();
    } catch (_) {
      if (DeliveryService.useMockData) {
        _user = {
          'id': 'mock-partner-123',
          'name': 'Nafeesh (Mock Agent)',
          'email': 'agent@zonesupply.com',
          'phone': '+91 98845 12093',
          'role': 'DELIVERY',
        };
        notifyListeners();
      } else {
        await ApiService.clearToken();
      }
    }
  }

  // ── Email / Password ────────────────────────────────────────────────────
  Future<bool> login(String email, String password) async {
    _loading = true;
    _error = null;
    notifyListeners();
    final normalizedEmail = email.contains('@')
        ? email.trim()
        : 'delivery_${email.trim().replaceAll(RegExp(r'\D'), '')}@zonesupply.com';

    try {
      if (DeliveryService.useMockData) {
        _user = {
          'id': 'mock-partner-123',
          'name': 'Nafeesh (Mock Agent)',
          'email': normalizedEmail,
          'phone': email.contains('@') ? '+91 98845 12093' : email,
          'role': 'DELIVERY',
        };
        await ApiService.saveToken('mock-jwt-token');
        _loading = false;
        notifyListeners();
        return true;
      }

      final res = await ApiService.post('/auth/login', {'email': normalizedEmail, 'password': password});
      if (res['user']['role'] != 'DELIVERY') {
        throw Exception('Access denied. This portal is only for Delivery Partners.');
      }
      await ApiService.saveToken(res['accessToken']);
      _user = res['user'];
      _loading = false;
      notifyListeners();
      return true;
    } catch (e) {
      if (DeliveryService.useMockData) {
        _user = {
          'id': 'mock-partner-123',
          'name': 'Nafeesh (Mock Agent)',
          'email': normalizedEmail,
          'phone': email.contains('@') ? '+91 98845 12093' : email,
          'role': 'DELIVERY',
        };
        _loading = false;
        notifyListeners();
        return true;
      }
      _error = e.toString().replaceAll('Exception: ', '').replaceAll('ApiException(401): ', '');
      _loading = false;
      notifyListeners();
      return false;
    }
  }

  Future<bool> register(String email, String password, String name, [String? phone]) async {
    _loading = true;
    _error = null;
    notifyListeners();
    final normalizedEmail = email.contains('@')
        ? email.trim()
        : 'delivery_${email.trim().replaceAll(RegExp(r'\D'), '')}@zonesupply.com';
    final actualPhone = phone ?? (email.contains('@') ? '' : email);

    try {
      if (DeliveryService.useMockData) {
        _user = {
          'id': 'mock-partner-123',
          'name': name,
          'email': normalizedEmail,
          'phone': actualPhone,
          'role': 'DELIVERY',
        };
        await ApiService.saveToken('mock-jwt-token');
        _loading = false;
        notifyListeners();
        return true;
      }

      final res = await ApiService.post('/auth/register', {
        'email': normalizedEmail,
        'password': password,
        'name': name,
        'role': 'DELIVERY',
        if (actualPhone.isNotEmpty) 'phone': actualPhone,
      });
      await ApiService.saveToken(res['accessToken']);
      _user = res['user'];
      _loading = false;
      notifyListeners();
      return true;
    } catch (e) {
      if (DeliveryService.useMockData) {
        _user = {
          'id': 'mock-partner-123',
          'name': name,
          'email': normalizedEmail,
          'phone': actualPhone,
          'role': 'DELIVERY',
        };
        _loading = false;
        notifyListeners();
        return true;
      }
      _error = e.toString().replaceAll('Exception: ', '');
      _loading = false;
      notifyListeners();
      return false;
    }
  }

  // ── Google Sign-In ──────────────────────────────────────────────────────
  Future<bool> loginWithGoogle() async {
    _loading = true;
    _error = null;
    notifyListeners();
    try {
      if (DeliveryService.useMockData) {
        _user = {
          'id': 'mock-google-partner',
          'name': 'Google Agent (Mock)',
          'email': 'google.agent@zonesupply.com',
          'role': 'DELIVERY',
        };
        await ApiService.saveToken('mock-jwt-token');
        _loading = false;
        notifyListeners();
        return true;
      }

      final account = await _googleSignIn.signIn();
      if (account == null) {
        _error = 'Google sign-in cancelled';
        _loading = false;
        notifyListeners();
        return false;
      }
      final auth = await account.authentication;
      final idToken = auth.idToken;
      if (idToken == null) throw Exception('Failed to get Google ID token');

      final res = await ApiService.post('/auth/google', {
        'idToken': idToken,
        'role': 'DELIVERY',
      });
      if (res['user']['role'] != 'DELIVERY') {
        throw Exception('Access denied. This portal is only for Delivery Partners.');
      }
      await ApiService.saveToken(res['accessToken']);
      _user = res['user'];
      _loading = false;
      notifyListeners();
      return true;
    } catch (e) {
      _error = e.toString().replaceAll('Exception: ', '');
      _loading = false;
      notifyListeners();
      return false;
    }
  }

  // ── Phone OTP ────────────────────────────────────────────────────────────
  Future<bool> sendOtp(String phone) async {
    _loading = true;
    _error = null;
    notifyListeners();
    try {
      if (DeliveryService.useMockData) {
        _pendingOtpPhone = phone;
        _loading = false;
        notifyListeners();
        return true;
      }
      await ApiService.post('/auth/otp/send', {'phone': phone, 'role': 'DELIVERY'});
      _pendingOtpPhone = phone;
      _loading = false;
      notifyListeners();
      return true;
    } catch (e) {
      _error = e.toString().replaceAll('Exception: ', '');
      _loading = false;
      notifyListeners();
      return false;
    }
  }

  Future<bool> verifyOtp(String phone, String otp, {String? name}) async {
    _loading = true;
    _error = null;
    notifyListeners();
    try {
      if (DeliveryService.useMockData) {
        _user = {
          'id': 'mock-otp-partner',
          'name': name ?? phone,
          'phone': phone,
          'role': 'DELIVERY',
        };
        await ApiService.saveToken('mock-jwt-token');
        _pendingOtpPhone = null;
        _loading = false;
        notifyListeners();
        return true;
      }

      final res = await ApiService.post('/auth/otp/verify', {
        'phone': phone,
        'otp': otp,
        'role': 'DELIVERY',
        if (name != null && name.isNotEmpty) 'name': name,
      });
      if (res['user']['role'] != 'DELIVERY') {
        throw Exception('Access denied. This portal is only for Delivery Partners.');
      }
      await ApiService.saveToken(res['accessToken']);
      _user = res['user'];
      _pendingOtpPhone = null;
      _loading = false;
      notifyListeners();
      return true;
    } catch (e) {
      _error = e.toString().replaceAll('Exception: ', '');
      _loading = false;
      notifyListeners();
      return false;
    }
  }

  // ── Logout ───────────────────────────────────────────────────────────────
  Future<void> logout() async {
    await ApiService.clearToken();
    await _googleSignIn.signOut();
    _user = null;
    notifyListeners();
  }
}
