import 'package:flutter/material.dart';
import '../services/auth_service.dart';
import '../models/user_model.dart';

class AuthProvider extends ChangeNotifier {
  final AuthService _authService;
  String? _token;
  bool _isLoading = false;
  User? _user;

  AuthProvider(this._authService);

  bool get isAuthenticated => _token != null;
  bool get isLoading => _isLoading;
  User? get user => _user;

  Future<void> login(String email, String password) async {
    _isLoading = true;
    notifyListeners();

    try {
      final response = await _authService.login(email, password);
      _token = response['token'] as String;
      _user = User.fromJson(response['user'] as Map<String, dynamic>);
      notifyListeners();
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> register(Map<String, dynamic> userData) async {
    _isLoading = true;
    notifyListeners();

    try {
      print('AuthProvider: Starting registration');
      if (userData['birth_date'] is DateTime) {
        final birthDate = userData['birth_date'] as DateTime;
        userData['birth_date'] = "${birthDate.year}-${birthDate.month.toString().padLeft(2, '0')}-${birthDate.day.toString().padLeft(2, '0')}";
      }
      
      final response = await _authService.register(userData);
      print('AuthProvider: Registration response received');
      
      if (response != null) {
        _token = response['token'] as String?;
        if (response['user'] != null) {
          _user = User.fromJson(response['user'] as Map<String, dynamic>);
        }
        print('AuthProvider: Token and user data processed');
      }
    } catch (e) {
      print('AuthProvider: Registration error - $e');
      rethrow;
    } finally {
      _isLoading = false;
      notifyListeners();
      print('AuthProvider: Registration process completed');
    }
  }

  Future<void> logout() async {
    await _authService.logout();
    _token = null;
    _user = null;
    notifyListeners();
  }
} 