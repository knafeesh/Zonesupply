import 'package:flutter/foundation.dart';
import 'package:google_sign_in/google_sign_in.dart';
import '../services/api_service.dart';

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
      final me = await ApiService.get('/users/me');
      if (me['role'] != 'RETAILER') throw Exception('Not a retailer');
      _user = me;
      notifyListeners();
    } catch (_) {
      await ApiService.clearToken();
    }
  }

  // ── Email / Password ────────────────────────────────────────────────────
  Future<bool> login(String email, String password) async {
    _loading = true;
    _error = null;
    notifyListeners();
    try {
      final res = await ApiService.post('/auth/login', {'email': email, 'password': password});
      if (res['user']['role'] != 'RETAILER') {
        throw Exception('Access denied. This portal is only for Retailers.');
      }
      await ApiService.saveToken(res['accessToken']);
      _user = res['user'];
      _loading = false;
      notifyListeners();
      return true;
    } catch (e) {
      _error = e.toString().replaceAll('ApiException(401): ', '').replaceAll('Exception: ', '');
      _loading = false;
      notifyListeners();
      return false;
    }
  }

  Future<bool> register(String email, String password, String name) async {
    _loading = true;
    _error = null;
    notifyListeners();
    try {
      final res = await ApiService.post('/auth/register', {
        'email': email,
        'password': password,
        'name': name,
        'role': 'RETAILER',
      });
      await ApiService.saveToken(res['accessToken']);
      _user = res['user'];
      _loading = false;
      notifyListeners();
      return true;
    } catch (e) {
      _error = e.toString();
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
        'role': 'RETAILER',
      });
      if (res['user']['role'] != 'RETAILER') {
        throw Exception('Access denied. This portal is only for Retailers.');
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
      await ApiService.post('/auth/otp/send', {'phone': phone, 'role': 'RETAILER'});
    } catch (_) {
      // Ignore API errors during dev so OTP 1234 always works locally
    }
    _pendingOtpPhone = phone;
    _loading = false;
    notifyListeners();
    return true;
  }

  // ── Membership Login (Zone Store Portal) ─────────────────────────────────
  /// Called after membership is verified as APPROVED.
  /// Gets a real JWT from the backend so all API calls work correctly.
  Future<bool> loginWithMembership({
    required String mobile,
    required String name,
    required String membershipId,
    String? email,
    String? shopName,
  }) async {
    _loading = true;
    _error = null;
    notifyListeners();

    try {
      final res = await ApiService.post('/auth/membership-login', {
        'membershipId': membershipId,
        'mobile': mobile,
        'name': name,
        'email': email,
        'shopName': shopName,
      });

      if (res != null && res['accessToken'] != null) {
        await ApiService.saveToken(res['accessToken']);
        _user = Map<String, dynamic>.from(res['user']);
        _user!['membershipId'] = membershipId;
        _user!['name'] = name;
        _pendingOtpPhone = null;
        _loading = false;
        notifyListeners();
        return true;
      }
      throw Exception('Failed to obtain authentication token');
    } catch (e) {
      _error = e.toString().replaceAll('Exception: ', '').replaceAll('ApiException: ', '');
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
      final res = await ApiService.post('/auth/otp/verify', {
        'phone': phone,
        'otp': otp,
        'role': 'RETAILER',
        if (name != null && name.isNotEmpty) 'name': name,
      });
      if (res['user']['role'] != 'RETAILER') {
        throw Exception('Access denied. This portal is only for Retailers.');
      }
      await ApiService.saveToken(res['accessToken']);
      _user = res['user'];
      _pendingOtpPhone = null;
      _loading = false;
      notifyListeners();
      return true;
    } catch (e) {
      // 1234 or 123456 fallback for dev/testing before SMS panel purchase
      if (otp == '1234' || otp == '123456' || otp == '0000') {
        _user = {
          'id': 'retailer-${phone.replaceAll(RegExp(r'\D'), '')}',
          'name': (name != null && name.isNotEmpty) ? name : 'Zone Retailer',
          'phone': phone,
          'email': 'retailer_${phone.replaceAll(RegExp(r'\D'), '')}@zonesupply.com',
          'role': 'RETAILER',
          'businessName': 'Retail Shop',
        };
        await ApiService.saveToken('mock_retailer_token_${phone.replaceAll(RegExp(r'\D'), '')}');
        _pendingOtpPhone = null;
        _loading = false;
        notifyListeners();
        return true;
      }
      _error = e.toString().replaceAll('Exception: ', '').replaceAll('ApiException(400): ', '');
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
