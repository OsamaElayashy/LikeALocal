import 'dart:async';
import 'package:firebase_database/firebase_database.dart';
import 'package:flutter/material.dart';
import '../models/chat_models.dart';
import '../models/user_model.dart';
import '../models/place_model.dart';

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
        'nameLower': user.name.toLowerCase(),
        'email': user.email,
        'emailLower': user.email.toLowerCase(),
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

  // ── Places ───────────────────────────────────────────
  Future<List<Place>> fetchPlaces() async {
    try {
      final snapshot = await _database.ref('places').get().timeout(
        const Duration(seconds: 20),
        onTimeout: () {
          throw TimeoutException('Fetch places timed out', const Duration(seconds: 20));
        },
      );

      if (!snapshot.exists) return [];
      if (snapshot.value is! Map) {
        debugPrint('Unexpected places data type: ${snapshot.value.runtimeType}');
        return [];
      }

      final data = Map<String, dynamic>.from(snapshot.value as Map);
      final places = <Place>[];
      for (final entry in data.entries) {
        try {
          final map = Map<String, dynamic>.from(entry.value as Map);
          places.add(Place.fromMap(entry.key, map));
        } catch (e) {
          debugPrint('Error parsing place ${entry.key}: $e');
        }
      }
      return places;
    } on TimeoutException {
      debugPrint('Error fetching places: timeout');
      return [];
    } catch (e) {
      debugPrint('Error fetching places: $e');
      return [];
    }
  }

  Future<void> addPlace(Place place) async {
    try {
      await _database.ref('places/${place.id}').set(place.toMap()).timeout(
        const Duration(seconds: 20),
        onTimeout: () {
          throw TimeoutException('Add place timed out', const Duration(seconds: 20));
        },
      );
      debugPrint('Place added: ${place.id}');
    } on TimeoutException {
      debugPrint('Error adding place: timeout');
      rethrow;
    } catch (e) {
      debugPrint('Error adding place: $e');
      rethrow;
    }
  }

  Future<void> updatePlace(Place place) async {
    try {
      await _database.ref('places/${place.id}').set(place.toMap()).timeout(
        const Duration(seconds: 20),
        onTimeout: () {
          throw TimeoutException('Update place timed out', const Duration(seconds: 20));
        },
      );
      debugPrint('Place updated: ${place.id}');
    } on TimeoutException {
      debugPrint('Error updating place: timeout');
      rethrow;
    } catch (e) {
      debugPrint('Error updating place: $e');
      rethrow;
    }
  }

  Future<void> deletePlace(String placeId) async {
    try {
      await _database.ref('places/$placeId').remove().timeout(
        const Duration(seconds: 20),
        onTimeout: () {
          throw TimeoutException('Delete place timed out', const Duration(seconds: 20));
        },
      );
      debugPrint('Place deleted: $placeId');
    } on TimeoutException {
      debugPrint('Error deleting place: timeout');
      rethrow;
    } catch (e) {
      debugPrint('Error deleting place: $e');
      rethrow;
    }
  }

  Future<void> addReview(String placeId, Review review) async {
    try {
      final ref = _database.ref('places/$placeId/reviews');
      final snapshot = await ref.get();
      final current = <dynamic>[];
      if (snapshot.exists && snapshot.value is List) {
        current.addAll(List<dynamic>.from(snapshot.value as List));
      } else if (snapshot.exists && snapshot.value is Map) {
        // Realtime DB may return a map for lists; convert
        final m = Map<String, dynamic>.from(snapshot.value as Map);
        current.addAll(m.values);
      }
      current.add(review.toMap());
      await ref.set(current);
      debugPrint('Review added for $placeId');
    } catch (e) {
      debugPrint('Error adding review: $e');
      rethrow;
    }
  }

  Future<void> toggleSavePlace(String placeId, String userId) async {
    try {
      final ref = _database.ref('places/$placeId/savedBy');
      final snapshot = await ref.get();
      final current = <String>[];
      if (snapshot.exists && snapshot.value is List) {
        current.addAll(List<String>.from(snapshot.value as List));
      } else if (snapshot.exists && snapshot.value is Map) {
        final m = Map<String, dynamic>.from(snapshot.value as Map);
        current.addAll(m.values.map((e) => e.toString()));
      }
      if (current.contains(userId)) {
        current.remove(userId);
      } else {
        current.add(userId);
      }
      await ref.set(current);
      debugPrint('Toggled save for $placeId by $userId');
    } catch (e) {
      debugPrint('Error toggling save: $e');
      rethrow;
    }
  }

  // ── City filter ───────────────────────────────────────
  // Fetch places filtered by city
  Future<List<Place>> fetchPlacesByCity(String city) async {
    try {
      final allPlaces = await fetchPlaces();
      if (city == 'All') return _sortPlaces(allPlaces);
      return _sortPlaces(
          allPlaces.where((p) => p.city == city).toList());
    } catch (e) {
      debugPrint('Error fetching places by city: $e');
      return [];
    }
  }

  // Super users appear first, then sort by date
  List<Place> _sortPlaces(List<Place> places) {
    places.sort((a, b) {
      if (a.contributorIsSuperUser && !b.contributorIsSuperUser) return -1;
      if (!a.contributorIsSuperUser && b.contributorIsSuperUser) return 1;
      return b.createdAt.compareTo(a.createdAt);
    });
    return places;
  }

  // ── Edit review ───────────────────────────────────────
  Future<void> editReview(
      String placeId, String reviewId, String newComment, double newScore) async {
    try {
      final ref = _database.ref('places/$placeId/reviews');
      final snapshot = await ref.get();
      if (!snapshot.exists) return;

      List<dynamic> reviews = [];
      if (snapshot.value is List) {
        reviews = List<dynamic>.from(snapshot.value as List);
      } else if (snapshot.value is Map) {
        reviews = Map<String, dynamic>.from(snapshot.value as Map).values.toList();
      }

      // Find and update the matching review
      final updated = reviews.map((r) {
        final map = Map<String, dynamic>.from(r);
        if (map['reviewId'] == reviewId) {
          map['comment'] = newComment;
          map['score'] = newScore;
        }
        return map;
      }).toList();

      await ref.set(updated);
      debugPrint('Review edited: $reviewId');
    } catch (e) {
      debugPrint('Error editing review: $e');
      rethrow;
    }
  }

  // ── Delete review ─────────────────────────────────────
  Future<void> deleteReview(String placeId, String reviewId) async {
    try {
      final ref = _database.ref('places/$placeId/reviews');
      final snapshot = await ref.get();
      if (!snapshot.exists) return;

      List<dynamic> reviews = [];
      if (snapshot.value is List) {
        reviews = List<dynamic>.from(snapshot.value as List);
      } else if (snapshot.value is Map) {
        reviews = Map<String, dynamic>.from(snapshot.value as Map).values.toList();
      }

      // Remove the matching review
      reviews.removeWhere((r) {
        final map = Map<String, dynamic>.from(r);
        return map['reviewId'] == reviewId;
      });

      await ref.set(reviews);
      debugPrint('Review deleted: $reviewId');
    } catch (e) {
      debugPrint('Error deleting review: $e');
      rethrow;
    }
  }

  // ── Super user check ──────────────────────────────────
  // Call this after every new contribution or review
  Future<void> checkAndUpdateSuperUser(String userId) async {
    try {
      final user = await getUserData(userId);
      if (user == null) return;

      if (user.qualifiesAsSuperUser && !user.isSuperUser) {
        await updateUserData(userId, {'isSuperUser': true});
        debugPrint('User $userId is now a Super User!');
      }
    } catch (e) {
      debugPrint('Error checking super user: $e');
    }
  }

  // ── Pin count ─────────────────────────────────────────
  Future<void> incrementPinCount(String userId) async {
    try {
      final user = await getUserData(userId);
      if (user == null) return;
      await updateUserData(userId, {'pinCount': user.pinCount + 1});
    } catch (e) {
      debugPrint('Error incrementing pin count: $e');
    }
  }

  // ── Privacy mode ──────────────────────────────────────
  Future<void> updatePrivacyMode(String userId, bool enabled) async {
    try {
      await updateUserData(userId, {'chatPrivacyEnabled': enabled});
      debugPrint('Privacy mode updated for $userId: $enabled');
    } catch (e) {
      debugPrint('Error updating privacy mode: $e');
      rethrow;
    }
  }

  // ── Chat: User Search ────────────────────────────────
  Future<List<UserModel>> searchUsers({
    required String query,
    required String currentUserId,
    int limit = 30,
  }) async {
    try {
      final snapshot = await _database.ref('users').get().timeout(
        const Duration(seconds: 20),
        onTimeout: () {
          throw TimeoutException('Search users timed out', const Duration(seconds: 20));
        },
      );

      if (!snapshot.exists || snapshot.value is! Map) return [];

      final q = _normalizeSearchText(query);
      final usersData = Map<String, dynamic>.from(snapshot.value as Map);
      final users = <UserModel>[];

      for (final entry in usersData.entries) {
        final uid = entry.key;
        if (uid == currentUserId || entry.value is! Map) continue;

        final rawData = Map<String, dynamic>.from(entry.value as Map);
        final user = UserModel.fromMap(uid, rawData);

        final name = _normalizeSearchText(
          (rawData['name'] ??
                  rawData['fullName'] ??
                  rawData['displayName'] ??
                  rawData['username'] ??
                  rawData['userName'] ??
                  user.name)
              .toString(),
        );
        final email = _normalizeSearchText(
          (rawData['email'] ?? rawData['mail'] ?? rawData['userEmail'] ?? user.email).toString(),
        );
        final idText = _normalizeSearchText(uid);
        final searchableText = '$name $email $idText';

        if (q.isEmpty || searchableText.contains(q)) {
          users.add(user);
        }
      }

      users.sort((a, b) => a.name.toLowerCase().compareTo(b.name.toLowerCase()));
      return users.take(limit).toList();
    } on TimeoutException {
      debugPrint('Error searching users: timeout');
      return [];
    } catch (e) {
      debugPrint('Error searching users: $e');
      return [];
    }
  }

  String _normalizeSearchText(String value) {
    return value.trim().toLowerCase().replaceAll(RegExp(r'\s+'), ' ');
  }

  // ── Chat: Direct Thread Helpers ──────────────────────
  String buildDirectChatId(String userIdA, String userIdB) {
    final ids = [userIdA, userIdB]..sort();
    return '${ids[0]}__${ids[1]}';
  }

  Future<String> ensureDirectChat({
    required UserModel currentUser,
    required UserModel otherUser,
  }) async {
    final chatId = buildDirectChatId(currentUser.id, otherUser.id);
    final now = DateTime.now().millisecondsSinceEpoch;

    final ref = _database.ref('chats/$chatId');
    final snap = await ref.get();
    if (!snap.exists) {
      await ref.set({
        'participantIds': [currentUser.id, otherUser.id]..sort(),
        'participants': {
          currentUser.id: {
            'name': currentUser.name,
            'email': currentUser.email,
            'avatarUrl': currentUser.avatarUrl,
          },
          otherUser.id: {
            'name': otherUser.name,
            'email': otherUser.email,
            'avatarUrl': otherUser.avatarUrl,
          },
        },
        'lastMessage': '',
        'lastSenderId': '',
        'lastMessageAt': now,
        'createdAt': now,
      });
    } else {
      // Keep participant display fields fresh.
      await ref.child('participants/${currentUser.id}').update({
        'name': currentUser.name,
        'email': currentUser.email,
        'avatarUrl': currentUser.avatarUrl,
      });
      await ref.child('participants/${otherUser.id}').update({
        'name': otherUser.name,
        'email': otherUser.email,
        'avatarUrl': otherUser.avatarUrl,
      });
    }

    await _database.ref('userChats/${currentUser.id}/$chatId').set(true);
    await _database.ref('userChats/${otherUser.id}/$chatId').set(true);

    return chatId;
  }

  Stream<List<ChatThread>> watchUserChats(String userId) {
    final ref = _database.ref('chats');
    return ref.onValue.map((event) {
      final value = event.snapshot.value;
      if (value == null || value is! Map) return <ChatThread>[];

      final data = Map<String, dynamic>.from(value);
      final threads = <ChatThread>[];
      for (final entry in data.entries) {
        if (entry.value is! Map) continue;
        final map = Map<String, dynamic>.from(entry.value);
        final thread = ChatThread.fromMap(entry.key, map);
        if (thread.participantIds.contains(userId)) {
          threads.add(thread);
        }
      }
      threads.sort((a, b) => b.lastMessageAt.compareTo(a.lastMessageAt));
      return threads;
    });
  }

  Stream<List<DirectMessage>> watchMessages(String chatId) {
    final ref = _database.ref('chats/$chatId/messages');
    return ref.onValue.map((event) {
      final value = event.snapshot.value;
      if (value == null) return <DirectMessage>[];

      final messages = <DirectMessage>[];
      if (value is Map) {
        final map = Map<String, dynamic>.from(value);
        for (final entry in map.entries) {
          if (entry.value is! Map) continue;
          messages.add(
            DirectMessage.fromMap(
              entry.key,
              Map<String, dynamic>.from(entry.value),
            ),
          );
        }
      } else if (value is List) {
        for (int i = 0; i < value.length; i++) {
          final item = value[i];
          if (item is Map) {
            messages.add(
              DirectMessage.fromMap(
                i.toString(),
                Map<String, dynamic>.from(item),
              ),
            );
          }
        }
      }

      messages.sort((a, b) => a.createdAt.compareTo(b.createdAt));
      return messages;
    });
  }

  Future<void> sendDirectMessage({
    required String chatId,
    required UserModel sender,
    required UserModel receiver,
    required String text,
  }) async {
    final trimmed = text.trim();
    if (trimmed.isEmpty) return;

    final chatRef = _database.ref('chats/$chatId');
    final messagesRef = chatRef.child('messages');
    final newMessageRef = messagesRef.push();
    final now = DateTime.now().millisecondsSinceEpoch;

    await newMessageRef.set({
      'senderId': sender.id,
      'receiverId': receiver.id,
      'text': trimmed,
      'createdAt': now,
    });

    await chatRef.update({
      'lastMessage': trimmed,
      'lastSenderId': sender.id,
      'lastMessageAt': now,
    });

    await _database.ref('userChats/${sender.id}/$chatId').set(true);
    await _database.ref('userChats/${receiver.id}/$chatId').set(true);
  }
}
