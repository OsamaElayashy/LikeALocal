import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

import '../models/user_model.dart';
import 'database_service.dart';

class AuthService {
  // Singleton — one instance shared across the app
  AuthService._singleton();
  static final AuthService _instance = AuthService._singleton();
  factory AuthService() => _instance;

  final FirebaseAuth _auth = FirebaseAuth.instance;
  final DatabaseService _database = DatabaseService();

  // Get current Firebase user
  Future<UserModel?> getCurrentUser() async {
    try {
      final user = _auth.currentUser;
      if (user != null) {
        return await _database.getUserData(user.uid);
      }
      return null;
    } catch (e) {
      debugPrint('Error getting current user: $e');
      return null;
    }
  }

  // Login with email and password
  Future<UserModel?> login({
    required String email,
    required String password,
  }) async {
    try {
      // Sign in with Firebase Auth
      final userCredential = await _auth.signInWithEmailAndPassword(
        email: email,
        password: password,
      );

      // Retrieve user data from Realtime Database
      final userData = await _database.getUserData(userCredential.user!.uid);

      if (userData != null) {
        debugPrint('Login successful: ${userCredential.user!.email}');
        return userData;
      } else {
        debugPrint('User data not found in database for UID: ${userCredential.user!.uid}');
        // User exists in Auth but has no RTDB profile yet: create one so
        // search/chat can discover the account.
        final fallbackUser = UserModel(
          id: userCredential.user!.uid,
          name: userCredential.user!.displayName ?? email.split('@')[0],
          email: userCredential.user!.email ?? email,
        );
        try {
          await _database.saveUserData(fallbackUser);
        } catch (e) {
          debugPrint('Failed to backfill missing user profile on login: $e');
        }
        return fallbackUser;
      }
    } on FirebaseAuthException catch (e) {
      debugPrint('Firebase Auth Error: ${e.code}');
      rethrow;
    } catch (e) {
      debugPrint('Login error: $e');
      rethrow;
    }
  }

  // Register new user
  Future<UserModel?> register({
    required String name,
    required String email,
    required String password,
  }) async {
    try {
      // Create user account in Firebase Auth
      final userCredential = await _auth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );

      // Create user model
      final newUser = UserModel(
        id: userCredential.user!.uid,
        name: name,
        email: email,
        contributionCount: 0,
        reviewCount: 0,
        isSuperUser: false,
        savedPlaces: [],
      );

      await userCredential.user?.updateDisplayName(name);

      // Save user data to Realtime Database
      await _database.saveUserData(newUser);

      debugPrint('Registration successful: $email');
      return newUser;
    } on FirebaseAuthException catch (e) {
      debugPrint('Firebase Auth Error: ${e.code}');
      rethrow;
    } catch (e) {
      debugPrint('Register error: $e');
      rethrow;
    }
  }

  // Sign out
  Future<void> logout() async {
    try {
      await _auth.signOut();
      debugPrint('User signed out');
    } catch (e) {
      debugPrint('Logout error: $e');
      rethrow;
    }
  }

  // Error message helper — converts Firebase error codes
  // to human readable messages
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
      case 'invalid-credential':
        return 'Email or password is incorrect.';
      case 'user-disabled':
        return 'This account has been disabled.';
      case 'too-many-requests':
        return 'Too many login attempts. Please try again later.';
      case 'operation-not-allowed':
        return 'Registration is temporarily unavailable. Please try again later.';
      case 'network-request-failed':
        return 'Network error. Please check your internet connection.';
      case 'unknown':
        return 'An error occurred. Please check your internet connection and try again.';
      default:
        return 'An error occurred: $code. Please try again.';
    }
  }
}
