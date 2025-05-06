import 'package:flutter/foundation.dart';
import '../models/user_model.dart';
import '../services/auth_service.dart';

class AuthProvider with ChangeNotifier {
  User? _currentUser;
  bool _isLoading = false;
  String? _error;

  // Getters
  User? get currentUser => _currentUser;
  bool get isLoading => _isLoading;
  String? get error => _error;
  bool get isLoggedIn => _currentUser != null;

  // Initialize - check if user is already logged in
  Future<void> initialize() async {
    _setLoading(true);
    try {
      final isLoggedIn = await AuthService.isLoggedIn();
      if (isLoggedIn) {
        final user = await AuthService.getCurrentUser();
        _currentUser = user;
      }
    } catch (e) {
      _setError(e.toString());
    } finally {
      _setLoading(false);
    }
  }

  // Login
  Future<bool> login({
    required String email,
    required String password,
    required String deviceName,
    String? deviceToken,
  }) async {
    _setLoading(true);
    _clearError();
    
    try {
      final user = await AuthService.login(
        email: email,
        password: password,
        deviceName: deviceName,
        deviceToken: deviceToken,
      );
      
      _currentUser = user;
      notifyListeners();
      return true;
    } catch (e) {
      _setError(e.toString());
      return false;
    } finally {
      _setLoading(false);
    }
  }

  // Logout
  Future<void> logout() async {
    _setLoading(true);
    try {
      await AuthService.logout();
      _currentUser = null;
    } catch (e) {
      _setError(e.toString());
    } finally {
      _setLoading(false);
    }
  }

  // Forgot password
  Future<bool> forgotPassword(String email) async {
    _setLoading(true);
    _clearError();
    
    try {
      final result = await AuthService.forgotPassword(email);
      return result;
    } catch (e) {
      _setError(e.toString());
      return false;
    } finally {
      _setLoading(false);
    }
  }

  // Reset password
  Future<bool> resetPassword({
    required String email,
    required String otp,
    required String password,
    required String passwordConfirmation,
  }) async {
    _setLoading(true);
    _clearError();
    
    try {
      final result = await AuthService.resetPassword(
        email: email,
        otp: otp,
        password: password,
        passwordConfirmation: passwordConfirmation,
      );
      return result;
    } catch (e) {
      _setError(e.toString());
      return false;
    } finally {
      _setLoading(false);
    }
  }

  // Update user profile
  Future<bool> updateProfile({
    required Map<String, dynamic> data,
    String? imagePath,
  }) async {
    _setLoading(true);
    _clearError();
    
    try {
      final updatedUser = await AuthService.updateProfile(
        data: data,
        imagePath: imagePath,
      );
      
      _currentUser = updatedUser;
      notifyListeners();
      return true;
    } catch (e) {
      _setError(e.toString());
      return false;
    } finally {
      _setLoading(false);
    }
  }

  // Refresh user data from server
  Future<bool> refreshUserData() async {
    _clearError();
    try {
      final user = await AuthService.getCurrentUser();
      if (user != null) {
        _currentUser = user;
        notifyListeners();
        return true;
      } else {
        _setError('Failed to refresh user data');
        return false;
      }
    } catch (e) {
      _setError(e.toString());
      return false;
    }
  }

  // Helper methods
  void _setLoading(bool loading) {
    _isLoading = loading;
    notifyListeners();
  }

  void _setError(String error) {
    _error = error;
    notifyListeners();
  }

  void _clearError() {
    _error = null;
    notifyListeners();
  }
} 