import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter/foundation.dart';
import '../models/user_model.dart';

class AuthService {
  static const String baseUrl = 'http://192.168.1.100:8800/api'; // Android emulator localhost
  // static const String baseUrl = 'http://127.0.0.1:8000/api'; // iOS simulator
  // static const String baseUrl = 'https://your-production-api.com/api'; // Production

  // Shared Preferences Keys
  static const String tokenKey = 'auth_token';
  static const String userKey = 'user_data';

  // Login user
  static Future<User> login({
    required String email,
    required String password,
    required String deviceName,
    String? deviceToken,
  }) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/auth/login'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'email': email,
          'password': password,
          'device_name': deviceName,
          if (deviceToken != null) 'device_token': deviceToken,
        }),
      );

      final responseData = jsonDecode(response.body);

      if (response.statusCode == 200 && responseData['status'] == true) {
        final userData = responseData['data']['user'];
        final token = responseData['data']['token'];

        // Create user model
        final user = User.fromJson(userData);

        // Save token and user data to shared preferences
        await _saveAuthData(token, userData);

        return user;
      } else {
        throw responseData['message'] ?? 'Login failed';
      }
    } catch (e) {
      throw e.toString();
    }
  }

  // Logout user
  static Future<bool> logout() async {
    try {
      final token = await getToken();
      if (token == null) return false;

      await http.post(
        Uri.parse('$baseUrl/auth/logout'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
      );

      // Clear local storage regardless of response
      await _clearAuthData();

      return true;
    } catch (e) {
      // Still clear local data even if API call fails
      await _clearAuthData();
      return false;
    }
  }

  // Get current user
  static Future<User?> getCurrentUser() async {
    try {
      final token = await getToken();
      if (token == null) return null;

      final response = await http.get(
        Uri.parse('$baseUrl/auth/user'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
      );

      final responseData = jsonDecode(response.body);

      if (response.statusCode == 200 && responseData['status'] == true) {
        final userData = responseData['data']['user'];
        return User.fromJson(userData);
      } else {
        return null;
      }
    } catch (e) {
      debugPrint('Error getting current user: $e');
      return null;
    }
  }

  // Request password reset
  static Future<bool> forgotPassword(String email) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/auth/forgot-password'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'email': email}),
      );

      final responseData = jsonDecode(response.body);
      
      if (response.statusCode == 200 && responseData['status'] == true) {
        return true;
      } else {
        throw responseData['message'] ?? 'Failed to send reset link';
      }
    } catch (e) {
      throw e.toString();
    }
  }

  // Reset password with OTP
  static Future<bool> resetPassword({
    required String email,
    required String otp,
    required String password,
    required String passwordConfirmation,
  }) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/auth/reset-password'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'email': email,
          'otp': otp,
          'password': password,
          'password_confirmation': passwordConfirmation,
        }),
      );

      final responseData = jsonDecode(response.body);
      
      if (response.statusCode == 200 && responseData['status'] == true) {
        return true;
      } else {
        throw responseData['message'] ?? 'Failed to reset password';
      }
    } catch (e) {
      throw e.toString();
    }
  }

  // Update user profile
  static Future<User> updateProfile({
    required Map<String, dynamic> data,
    String? imagePath,
  }) async {
    try {
      final token = await getToken();
      if (token == null) throw 'Not authenticated';

      if (imagePath != null) {
        // Use multipart request for file upload
        var request = http.MultipartRequest(
          'POST',
          Uri.parse('$baseUrl/profile/update'),
        );

        // Add authorization header
        request.headers.addAll({
          'Authorization': 'Bearer $token',
          'Accept': 'application/json',
        });

        // Add form fields from data map
        data.forEach((key, value) {
          request.fields[key] = value.toString();
        });

        // Add file
        request.files.add(await http.MultipartFile.fromPath(
          'profile_image',
          imagePath,
        ));

        // Send request
        final streamedResponse = await request.send();
        final response = await http.Response.fromStream(streamedResponse);
        
        final responseData = jsonDecode(response.body);
        
        if (response.statusCode == 200 && responseData['success'] == true) {
          final userData = responseData['data'];
          
          // Save updated user data
          final prefs = await SharedPreferences.getInstance();
          await prefs.setString(userKey, jsonEncode(userData));
          
          // Return updated user
          return User.fromJson(userData);
        } else {
          throw responseData['message'] ?? 'Failed to update profile';
        }
      } else {
        // Regular JSON request without file
        final response = await http.post(
          Uri.parse('$baseUrl/profile/update'),
          headers: {
            'Content-Type': 'application/json',
            'Authorization': 'Bearer $token',
          },
          body: jsonEncode(data),
        );

        final responseData = jsonDecode(response.body);
        
        if (response.statusCode == 200 && responseData['success'] == true) {
          final userData = responseData['data'];
          
          // Save updated user data
          final prefs = await SharedPreferences.getInstance();
          await prefs.setString(userKey, jsonEncode(userData));
          
          // Return updated user
          return User.fromJson(userData);
        } else {
          throw responseData['message'] ?? 'Failed to update profile';
        }
      }
    } catch (e) {
      throw e.toString();
    }
  }

  // Get authentication token
  static Future<String?> getToken() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(tokenKey);
  }

  // Check if user is logged in
  static Future<bool> isLoggedIn() async {
    final token = await getToken();
    return token != null;
  }

  // Save token and user data to shared preferences
  static Future<void> _saveAuthData(String token, Map<String, dynamic> userData) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(tokenKey, token);
    await prefs.setString(userKey, jsonEncode(userData));
  }

  // Clear authentication data
  static Future<void> _clearAuthData() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(tokenKey);
    await prefs.remove(userKey);
  }
} 