import 'package:flutter/material.dart';
import '../models/user_model.dart';
import '../models/place_model.dart';
import '../services/database_service.dart';
import 'package:likealocal/services/location_service.dart';

class AppProvider extends ChangeNotifier {
  AppProvider() {
    // Populate some sample places for initial display
    _places = [
      Place(
        id: 'p1',
        title: 'Sunny Cafe',
        description: 'Cozy cafe with great coffee and pastries.',
        category: 'Food',
        city: 'Cairo',
        localTip: 'Try the croissant with almond butter.',
        imageUrl: 'https://images.unsplash.com/photo-1504754524776-8f4f37790ca0?w=800',
        latitude: 37.7749,
        longitude: -122.4194,
        contributorId: 'u1',
        contributorName: 'Ahmed',
        createdAt: DateTime.now(),
        reviews: [
          // sample reviews
          Review(reviewId: 'r1', userId: 'u2', userName: 'Sara', score: 4.5, comment: 'Lovely spot!', createdAt: DateTime.now()),
        ],
      ),
      Place(
        id: 'p2',
        title: 'Old Town Museum',
        description: 'Local history museum with free guided tours.',
        category: 'Culture',
        city: 'Cairo',
        localTip: 'Visit on weekdays for fewer crowds.',
        imageUrl: 'https://images.unsplash.com/photo-1549880338-65ddcdfd017b?w=800',
        latitude: 51.5074,
        longitude: -0.1278,
        contributorId: 'u2',
        contributorName: 'Sara',
        createdAt: DateTime.now(),
        reviews: [
          Review(reviewId: 'r2', userId: 'u3', userName: 'Omar', score: 4.2, comment: 'Great exhibits.', createdAt: DateTime.now()),
        ],
      ),
    ];
  }

  final DatabaseService _db = DatabaseService();

  /// Load places from Firebase into provider
  Future<void> loadPlaces() async {
    setLoading(true);
    try {
      final places = await _db.fetchPlaces();
      _places = places;
      // update savedPlaces for current user if available
      if (_currentUser != null) {
        _savedPlaces = _places.where((p) => p.savedBy.contains(_currentUser!.id)).toList();
      }

      // START TRACKING after places are loaded so location service knows what to check against
      LocationService.instance.startTracking(_places);
    } catch (e) {
      debugPrint('Failed to load places: $e');
    } finally {
      setLoading(false);
    }
  }

  Future<void> refreshPlaces() async {
    await loadPlaces();
    LocationService.instance.startTracking(_places);
  }
  UserModel? _currentUser;
  List<Place> _places = [];
  List<Place> _savedPlaces = [];
  bool _isLoading = false;
  String _selectedCategory = 'All';

  // ── Getters ──────────────────────────────────────────
  UserModel? get currentUser => _currentUser;
  List<Place> get places => _places;
  List<Place> get savedPlaces => _savedPlaces;
  bool get isLoading => _isLoading;
  String get selectedCategory => _selectedCategory;
  bool get isLoggedIn => _currentUser != null;

  // Filtered places based on selected category and city
  List<Place> get filteredPlaces {
    var list = _places;

    if (_selectedCity != 'All') {
      list = list.where((p) => p.city == _selectedCity).toList();
    }
    if (_selectedCategory != 'All') {
      list = list.where((p) => p.category == _selectedCategory).toList();
    }
    // Super users first
    list.sort((a, b) {
      if (a.contributorIsSuperUser && !b.contributorIsSuperUser) return -1;
      if (!a.contributorIsSuperUser && b.contributorIsSuperUser) return 1;
      return b.createdAt.compareTo(a.createdAt);
    });
    return list;
  }

  // ── Auth ─────────────────────────────────────────────
  void setUser(UserModel? user) {
    _currentUser = user;
    notifyListeners();
  }

  void clearUser() {
    _currentUser = null;
    _savedPlaces = [];
    LocationService.instance.stopTracking();
    notifyListeners();
  }

  // ── Places ───────────────────────────────────────────
  void setPlaces(List<Place> places) {
    _places = places;
    notifyListeners();
  }

  Future<void> addPlace(Place place) async {
    try {
      await _db.addPlace(place);
      _places.insert(0, place);

      if (_currentUser != null) {
        final updatedUser = UserModel(
          id: _currentUser!.id,
          name: _currentUser!.name,
          email: _currentUser!.email,
          avatarUrl: _currentUser!.avatarUrl,
          contributionCount: _currentUser!.contributionCount + 1,
          reviewCount: _currentUser!.reviewCount,
          isSuperUser: _currentUser!.isSuperUser,
          savedPlaces: _currentUser!.savedPlaces,
          chatPrivacyEnabled: _currentUser!.chatPrivacyEnabled,
          pinCount: _currentUser!.pinCount,
        );
        _currentUser = updatedUser;
        await _db.updateUserData(updatedUser.id, {'contributionCount': updatedUser.contributionCount});
        await _db.checkAndUpdateSuperUser(updatedUser.id);
        final refreshed = await _db.getUserData(updatedUser.id);
        if (refreshed != null) {
          _currentUser = refreshed;
        }
      }

      notifyListeners();
    } catch (e) {
      debugPrint('Error adding place to DB: $e');
    }
  }

  Future<void> updatePlace(Place place) async {
    try {
      await _db.updatePlace(place);
      final idx = _places.indexWhere((p) => p.id == place.id);
      if (idx != -1) {
        _places[idx] = place;
      }
      notifyListeners();
    } catch (e) {
      debugPrint('Error updating place: $e');
    }
  }

  Future<void> deletePlace(String placeId) async {
    try {
      await _db.deletePlace(placeId);
      _places.removeWhere((p) => p.id == placeId);
      notifyListeners();
    } catch (e) {
      debugPrint('Error deleting place: $e');
    }
  }

  void removePlace(String placeId) {
    _places.removeWhere((p) => p.id == placeId);
    notifyListeners();
  }

  // ── Saved / Pins ─────────────────────────────────────
  void setSavedPlaces(List<Place> places) {
    _savedPlaces = places;
    notifyListeners();
  }

  void toggleSavePlace(Place place) {
    final userId = _currentUser?.id ?? 'local_user';
    _db.toggleSavePlace(place.id, userId).then((_) {
      final idx = _places.indexWhere((p) => p.id == place.id);
      if (idx != -1) {
        final p = _places[idx];
        final newSaved = List<String>.from(p.savedBy);
        if (newSaved.contains(userId)) {
          newSaved.remove(userId);
        } else {
          newSaved.add(userId);
        }
        _places[idx] = Place(
          id: p.id,
          title: p.title,
          description: p.description,
          category: p.category,
          city: p.city,
          localTip: p.localTip,
          imageUrl: p.imageUrl,
          latitude: p.latitude,
          longitude: p.longitude,
          contributorId: p.contributorId,
          contributorName: p.contributorName,
          contributorIsSuperUser: p.contributorIsSuperUser,
          createdAt: p.createdAt,
          savedBy: newSaved,
          reviews: p.reviews,
        );
      }
      if (isPlaceSaved(place.id)) {
        // already saved -> remove
        _savedPlaces.removeWhere((p) => p.id == place.id);
      } else {
        _savedPlaces.add(place);
      }
      notifyListeners();
    }).catchError((e) {
      debugPrint('Error toggling save: $e');
    });
  }

  bool isPlaceSaved(String placeId) {
    return _savedPlaces.any((p) => p.id == placeId);
  }

  // ── Category Filter ───────────────────────────────────
  void setCategory(String category) {
    _selectedCategory = category;
    notifyListeners();
  }

  // ── Loading ───────────────────────────────────────────
  void setLoading(bool value) {
    _isLoading = value;
    notifyListeners();
  }

  // ── Ratings ───────────────────────────────────────────
  /// Adds a new rating for a place and updates its average rating.
  Future<void> addRating(String placeId, double newRating, String comment, {String? userId, String? userName}) async {
    final idx = _places.indexWhere((p) => p.id == placeId);
    if (idx == -1) return;

    final currentUser = _currentUser;
    final resolvedUserId = userId ?? currentUser?.id ?? 'local_user';
    final resolvedUserName = userName ?? currentUser?.name ?? 'Local User';
    final place = _places[idx];
    final review = Review(
      reviewId: DateTime.now().millisecondsSinceEpoch.toString(),
      userId: resolvedUserId,
      userName: resolvedUserName,
      score: newRating,
      comment: comment,
      createdAt: DateTime.now(),
    );

    try {
      await _db.addReview(placeId, review);
      final updated = List<Review>.from(place.reviews)..add(review);
      _places[idx] = Place(
        id: place.id,
        title: place.title,
        description: place.description,
        category: place.category,
        city: place.city,
        localTip: place.localTip,
        imageUrl: place.imageUrl,
        latitude: place.latitude,
        longitude: place.longitude,
        contributorId: place.contributorId,
        contributorName: place.contributorName,
        contributorIsSuperUser: place.contributorIsSuperUser,
        createdAt: place.createdAt,
        savedBy: place.savedBy,
        reviews: updated,
      );

      if (currentUser != null && currentUser.id == resolvedUserId) {
        final updatedUser = UserModel(
          id: currentUser.id,
          name: currentUser.name,
          email: currentUser.email,
          avatarUrl: currentUser.avatarUrl,
          contributionCount: currentUser.contributionCount,
          reviewCount: currentUser.reviewCount + 1,
          isSuperUser: currentUser.isSuperUser,
          savedPlaces: currentUser.savedPlaces,
          chatPrivacyEnabled: currentUser.chatPrivacyEnabled,
          pinCount: currentUser.pinCount,
        );
        _currentUser = updatedUser;
        await _db.updateUserData(updatedUser.id, {'reviewCount': updatedUser.reviewCount});
        await _db.checkAndUpdateSuperUser(updatedUser.id);
        final refreshed = await _db.getUserData(updatedUser.id);
        if (refreshed != null) {
          _currentUser = refreshed;
        }
      }

      notifyListeners();
    } catch (e) {
      debugPrint('Error adding review to DB: $e');
    }
  }

  // ── City Filter ───────────────────────────────────────
  String _selectedCity = 'All';
  String get selectedCity => _selectedCity;

  void setCity(String city) {
    _selectedCity = city;
    notifyListeners();
  }

  // ── Reload User ───────────────────────────────────────
  // Reload current user from DB
  Future<void> reloadUser() async {
    if (_currentUser == null) return;
    final updated = await DatabaseService().getUserData(_currentUser!.id);
    if (updated != null) {
      _currentUser = updated;
      notifyListeners();
    }
  }
}