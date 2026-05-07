import 'dart:async';
import 'package:firebase_database/firebase_database.dart';
import 'package:flutter/material.dart';
import '../models/user_model.dart';

class DatabaseService {
  // Singleton
  DatabaseService._singleton();
  static final DatabaseService _instance = DatabaseService._singleton();
  factory DatabaseService() => _instance;

  final FirebaseDatabase _database = FirebaseDatabase.instance;

  // Save user data to Realtime Database
  Future<void> saveUserData(UserModel user) async {
    try {
      await _database.ref('users/${user.id}').set({
        'id': user.id,
        'name': user.name,
        'email': user.email,
        'avatarUrl': user.avatarUrl,
        'contributionCount': user.contributionCount,
        'reviewCount': user.reviewCount,
        'isSuperUser': user.isSuperUser,
        'savedPlaces': user.savedPlaces,
        'createdAt': DateTime.now().toIso8601String(),
      }).timeout(
        const Duration(seconds: 20),
        onTimeout: () {
          throw TimeoutException('Save user data timed out', const Duration(seconds: 20));
        },
      );
      debugPrint('User data saved to database: ${user.id}');
    } on TimeoutException {
      debugPrint('Error saving user data: timeout');
      rethrow;
    } catch (e) {
      debugPrint('Error saving user data: $e');
      rethrow;
    }
  }

  // Retrieve user data from Realtime Database
  Future<UserModel?> getUserData(String userId) async {
    try {
      final snapshot = await _database.ref('users/$userId').get().timeout(
        const Duration(seconds: 20),
        onTimeout: () {
          debugPrint('Database request timeout for user $userId');
          throw TimeoutException('Database request timed out', const Duration(seconds: 20));
        },
      );

      if (snapshot.exists) {
        if (snapshot.value is! Map) {
          debugPrint('Unexpected data type for user $userId: ${snapshot.value.runtimeType}');
          return null;
        }
        final data = Map<String, dynamic>.from(snapshot.value as Map);
        return UserModel.fromMap(userId, data);
      }
      return null;
    } on TimeoutException {
      debugPrint('Error retrieving user data: timeout');
      return null;
    } catch (e) {
      debugPrint('Error retrieving user data: $e');
      return null;
    }
  }

  // Check if user exists by email
  Future<String?> getUserIdByEmail(String email) async {
    try {
      final snapshot = await _database.ref('users').get().timeout(
        const Duration(seconds: 20),
        onTimeout: () {
          throw TimeoutException('Check email timed out', const Duration(seconds: 20));
        },
      );

      if (snapshot.exists) {
        if (snapshot.value is! Map) {
          debugPrint('Unexpected data type for users list: ${snapshot.value.runtimeType}');
          return null;
        }
        final users = Map<String, dynamic>.from(snapshot.value as Map);
        for (final entry in users.entries) {
          if (entry.value is Map && entry.value['email'] == email) {
            return entry.key;
          }
        }
      }
      return null;
    } on TimeoutException {
      debugPrint('Error checking email: timeout');
      return null;
    } catch (e) {
      debugPrint('Error checking email: $e');
      return null;
    }
  }

  // Update user data (e.g., after adding a contribution)
  Future<void> updateUserData(String userId, Map<String, dynamic> updates) async {
    try {
      await _database.ref('users/$userId').update(updates).timeout(
        const Duration(seconds: 20),
        onTimeout: () {
          throw TimeoutException('Update user data timed out', const Duration(seconds: 20));
        },
      );
      debugPrint('User data updated: $userId');
    } on TimeoutException {
      debugPrint('Error updating user data: timeout');
      rethrow;
    } catch (e) {
      debugPrint('Error updating user data: $e');
      rethrow;
    }
  }

  // Delete user data
  Future<void> deleteUserData(String userId) async {
    try {
      await _database.ref('users/$userId').remove().timeout(
        const Duration(seconds: 20),
        onTimeout: () {
          throw TimeoutException('Delete user data timed out', const Duration(seconds: 20));
        },
      );
      debugPrint('User data deleted: $userId');
    } on TimeoutException {
      debugPrint('Error deleting user data: timeout');
      rethrow;
    } catch (e) {
      debugPrint('Error deleting user data: $e');
      rethrow;
    }
  }
}
