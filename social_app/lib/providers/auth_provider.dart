import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import '../models/user.dart';
import '../services/auth_service.dart';
import '../services/api_service.dart';

class AuthProvider with ChangeNotifier {
  User? _currentUser;
  bool _isLoading = false;
  String? _errorMessage;

  User? get currentUser => _currentUser;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;
  bool get isLoggedIn => _currentUser != null;

  final AuthService _authService = AuthService();

  void resetState() {
    _isLoading = false;
    _errorMessage = null;
    notifyListeners();
  }

  Future<bool> login(String email, String password) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    final result = await _authService.login(email, password);

    if (result['success']) {
      _currentUser = result['user'];
      _isLoading = false;
      notifyListeners();
      return true;
    } else {
      _errorMessage = result['message'];
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  Future<bool> register(String username, String email, String password) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    final result = await _authService.register(username, email, password);

    _isLoading = false;
    _errorMessage = result['success'] ? null : result['message'];
    notifyListeners();
    return result['success'];
  }

  Future<void> logout() async {
    await _authService.logout();
    _currentUser = null;
    notifyListeners();
  }

  Future<bool> checkLoginStatus() async {
    try {
      final token = await ApiService.getToken();
      if (token == null) {
        debugPrint('checkLoginStatus: no token found');
        return false;
      }

      // Decode JWT payload
      final parts = token.split('.');
      if (parts.length != 3) {
        debugPrint('checkLoginStatus: invalid token format');
        await ApiService.deleteToken();
        return false;
      }

      // Decode base64 payload
      String payload = parts[1];
      while (payload.length % 4 != 0) {
        payload += '=';
      }

      final decoded = utf8.decode(base64Url.decode(payload));
      final data = jsonDecode(decoded);
      debugPrint('checkLoginStatus: token payload: $data');

      // Check token expiry
      final exp = data['exp'] as int;
      final now = DateTime.now().millisecondsSinceEpoch ~/ 1000;

      if (now >= exp) {
        debugPrint('checkLoginStatus: token expired');
        await ApiService.deleteToken();
        return false;
      }

      // Restore _currentUser from token
      _currentUser = User(
        id: data['id']?.toString() ?? '',
        username: data['username']?.toString() ?? '',
        email: '',
      );
      debugPrint('checkLoginStatus: restored user: ${_currentUser?.username}');
      notifyListeners();
      return true;
    } catch (e) {
      debugPrint('checkLoginStatus error: $e');
      await ApiService.deleteToken();
      return false;
    }
  }
}
