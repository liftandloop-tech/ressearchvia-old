import 'dart:async';
import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:spresearch_web/services/api.service.dart';
import '../models/user.model.dart';

class AuthService extends ApiService {
  static const String _tokenKey = 'auth_token';
  static const String _userKey = 'user_data';

  // Save token to SharedPreferences
  Future<void> _saveToken(String token) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_tokenKey, token);
      debugPrint('Token saved: $token');
    } catch (e) {
      debugPrint('Error saving token: $e');
    }
  }

  // Get token from SharedPreferences
  Future<String?> getToken() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      return prefs.getString(_tokenKey);
    } catch (e) {
      debugPrint('Error getting token: $e');
      return null;
    }
  }

  // Save user data to SharedPreferences
  Future<void> _saveUserData(Map<String, dynamic> userData) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_userKey, jsonEncode(userData));
    } catch (e) {
      debugPrint('Error saving user data: $e');
    }
  }

  // Get user data and reconstruct UserModel
  Future<UserModel?> getUser() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final userStr = prefs.getString(_userKey);
      if (userStr != null) {
        final Map<String, dynamic> userData = jsonDecode(userStr);
        // Handle nested userObject for admin users if needed
        if (userData.containsKey('userObject') &&
            userData['userObject'] is Map) {
          final userObject = userData['userObject'] as Map<String, dynamic>;
          userData['email'] = userData['email'] ?? userObject['emailAddress'];
          userData['fullName'] = userData['fullName'] ?? 'Admin User';
        }
        final user = UserModel.fromJson(userData);
        debugPrint(
          'Reconstructed User: ${user.fullName}, Role: ${user.subscriptionPlan}',
        );
        return user;
      }
      return null;
    } catch (e) {
      debugPrint('Error getting user data: $e');
      return null;
    }
  }

  // Clear auth data
  Future<void> _clearAuthData() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove(_tokenKey);
      await prefs.remove(_userKey);
    } catch (e) {
      debugPrint('Error clearing auth data: $e');
    }
  }

  Future<({UserModel? user, String? token, String? error})> login(
    String email,
    String password,
  ) async {
    try {
      debugPrint('Attempting admin login for: $email');

      final response = await post('/user/admin-login', {
        'email': email,
        'password': password,
      });

      debugPrint('Login response status: ${response.statusCode}');
      debugPrint('Login response body: ${response.body}');

      if (response.statusCode == 200 && response.body != null) {
        final data = response.body;

        if (data['status'] == 200 && data['data'] != null) {
          final adminData = data['data']['admin'];
          final token = data['data']['token'];

          if (token != null) {
            await _saveToken(token as String);
            await _saveUserData(adminData);

            // Create UserModel from admin data
            final user = UserModel.fromJson(adminData);

            return (user: user, token: token as String, error: null);
          }
        }

        return (
          user: null,
          token: null,
          error: (data['message'] ?? 'Login failed') as String,
        );
      } else {
        return (user: null, token: null, error: 'Invalid email or password');
      }
    } catch (e) {
      debugPrint('Login error: $e');
      return (user: null, token: null, error: 'Network error: $e');
    }
  }

  Future<bool> forgotPassword(String email) async {
    try {
      await Future.delayed(const Duration(seconds: 1));
      return true;
    } catch (e) {
      debugPrint('Forgot password error: $e');
      return false;
    }
  }

  Future<bool> resetPassword(String newPassword) async {
    try {
      await Future.delayed(const Duration(seconds: 2));
      return true;
    } catch (e) {
      debugPrint('Reset password error: $e');
      return false;
    }
  }

  Future<void> logout() async {
    await _clearAuthData();
    await Future.delayed(const Duration(milliseconds: 300));
  }

  // Staff (Manager) Login - Request OTP
  Future<({bool success, String? error})> staffRequestOtp(String mobile) async {
    try {
      debugPrint('Requesting OTP for staff mobile: $mobile');

      final response = await post('/staff/staff-login', {'phone': mobile});

      debugPrint('Staff OTP request response status: ${response.statusCode}');
      debugPrint('Staff OTP request response body: ${response.body}');

      if (response.statusCode == 200 && response.body != null) {
        final data = response.body;

        if (data['status'] == 200) {
          return (success: true, error: null);
        } else {
          return (
            success: false,
            error: (data['message'] ?? 'Failed to send OTP') as String,
          );
        }
      } else {
        return (success: false, error: 'Failed to send OTP');
      }
    } catch (e) {
      debugPrint('Staff OTP request error: $e');
      return (success: false, error: 'Network error: $e');
    }
  }

  // Staff (Manager) Login - Verify OTP
  Future<({UserModel? user, String? token, String? error})> staffVerifyOtp(
    String otp,
  ) async {
    try {
      debugPrint('Verifying staff OTP: $otp');

      final response = await post('/staff/staff-otp-verify', {'otp': otp});

      debugPrint('Staff OTP verify response status: ${response.statusCode}');
      debugPrint('Staff OTP verify response body: ${response.body}');

      if (response.statusCode == 200 && response.body != null) {
        final data = response.body;

        if (data['status'] == 200 && data['data'] != null) {
          final staffData = data['data']['staff'];
          final token = data['data']['token'];

          if (token != null) {
            await _saveToken(token as String);
            await _saveUserData(staffData);

            // Create UserModel from staff data
            final user = UserModel.fromJson(staffData);

            return (user: user, token: token as String, error: null);
          }
        }

        return (
          user: null,
          token: null,
          error: (data['message'] ?? 'OTP verification failed') as String,
        );
      } else {
        return (user: null, token: null, error: 'Invalid OTP');
      }
    } catch (e) {
      debugPrint('Staff OTP verify error: $e');
      return (user: null, token: null, error: 'Network error: $e');
    }
  }

  // Staff (Manager) Login - MPIN
  Future<({UserModel? user, String? token, String? error})> staffMpinLogin(
    String phone,
    String mpin,
  ) async {
    try {
      debugPrint('Staff MPIN login for: $phone');

      String formattedPhone = phone;
      if (!phone.startsWith('+91') && !phone.startsWith('91')) {
        formattedPhone = '91$phone';
      } else if (phone.startsWith('+91')) {
        formattedPhone = phone.substring(1); // Remove + sign
      }

      final response = await post('/staff/staff-mpin-login', {
        'phone': formattedPhone,
        'mpin': mpin,
      });

      if (response.statusCode == 200 && response.body != null) {
        final data = response.body;

        if (data['status'] == 200 && data['data'] != null) {
          final staffData = data['data']['staff'];
          final token = data['data']['token'];

          if (token != null) {
            await _saveToken(token as String);
            await _saveUserData(staffData);

            // Create UserModel from staff data
            final user = UserModel.fromJson(staffData);

            return (user: user, token: token as String, error: null);
          }
        }

        return (
          user: null,
          token: null,
          error: (data['message'] ?? 'Login failed') as String,
        );
      } else {
        return (
          user: null,
          token: null,
          error: 'Login failed: ${response.statusText ?? "Unknown error"}',
        );
      }
    } catch (e) {
      debugPrint('Staff MPIN login error: $e');
      return (user: null, token: null, error: 'Network error: $e');
    }
  }
}
