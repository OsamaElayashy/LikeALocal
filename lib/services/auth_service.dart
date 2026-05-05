import 'package:flutter/material.dart';

// NOTE: We will add Firebase imports here later when we set up Firebase.
// For now this service uses a mock so the UI works immediately.

import '../models/user_model.dart';

class AuthService {
  // Singleton — one instance shared across the app
  AuthService._singleton();
  static final AuthService _instance = AuthService._singleton();
  factory AuthService() => _instance;

  // ── Mock current user (replace with Firebase later) ──
  UserModel? _mockUser;

  Future<UserModel?> getCurrentUser() async {
    return _mockUser;
  }

  Future<UserModel?> login({
    required String email,
    required String password,
  }) async {
    try {
      // TODO: Replace with Firebase sign in
      // Simulate network delay
      await Future.delayed(const Duration(seconds: 1));

      // Mock successful login
      _mockUser = UserModel(
        id: 'user_001',
        name: 'Test User',
        email: email,
        contributionCount: 3,
        reviewCount: 7,
        isSuperUser: false,
      );
      return _mockUser;
    } catch (e) {
      debugPrint('Login error: $e');
      return null;
    }
  }

  Future<UserModel?> register({
    required String name,
    required String email,
    required String password,
  }) async {
    try {
      // TODO: Replace with Firebase create user
      await Future.delayed(const Duration(seconds: 1));

      _mockUser = UserModel(
        id: 'user_${DateTime.now().millisecondsSinceEpoch}',
        name: name,
        email: email,
      );
      return _mockUser;
    } catch (e) {
      debugPrint('Register error: $e');
      return null;
    }
  }

  Future<void> logout() async {
    // TODO: Replace with Firebase sign out
    _mockUser = null;
  }

  // Error message helper — converts Firebase error codes
  // to human readable messages (ready for when we add Firebase)
  String getErrorMessage(String code) {
    switch (code) {
      case 'user-not-found':
        return 'No account found with this email.';
      case 'wrong-password':
        return 'Incorrect password.';
      case 'email-already-in-use':
        return 'An account already exists with this email.';
      case 'weak-password':
        return 'Password must be at least 6 characters.';
      case 'invalid-email':
        return 'Please enter a valid email address.';
      default:
        return 'Something went wrong. Please try again.';
    }
  }
}