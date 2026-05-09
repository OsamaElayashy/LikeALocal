import 'package:flutter/material.dart';
import '../models/user_model.dart';
import '../models/place_model.dart';
import '../services/database_service.dart';

class AppProvider extends ChangeNotifier {
  AppProvider() {
    // Populate some sample places for initial display
    _places = [
      Place(
        id: 'p1',
        title: 'Sunny Cafe',
        description: 'Cozy cafe with great coffee and pastries.',
        category: 'Food',
        localTip: 'Try the croissant with almond butter.',
        imageUrl: 'https://images.unsplash.com/photo-1504754524776-8f4f37790ca0?w=800',
        latitude: 37.7749,
        longitude: -122.4194,
        contributorId: 'u1',
        contributorName: 'Ahmed',
        createdAt: DateTime.now(),
        reviews: [
          // sample reviews
          Review(userId: 'u2', userName: 'Sara', score: 4.5, comment: 'Lovely spot!', createdAt: DateTime.now()),
        ],
      ),
      Place(
        id: 'p2',
        title: 'Old Town Museum',
        description: 'Local history museum with free guided tours.',
        category: 'Culture',
        localTip: 'Visit on weekdays for fewer crowds.',
        imageUrl: 'https://images.unsplash.com/photo-1549880338-65ddcdfd017b?w=800',
        latitude: 51.5074,
        longitude: -0.1278,
        contributorId: 'u2',
        contributorName: 'Sara',
        createdAt: DateTime.now(),
        reviews: [
          Review(userId: 'u3', userName: 'Omar', score: 4.2, comment: 'Great exhibits.', createdAt: DateTime.now()),
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
    } catch (e) {
      debugPrint('Failed to load places: $e');
    } finally {
      setLoading(false);
    }
  }

  Future<void> refreshPlaces() async {
    await loadPlaces();
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

  // Filtered places based on selected category
  List<Place> get filteredPlaces {
    if (_selectedCategory == 'All') return _places;
    return _places
        .where((p) => p.category == _selectedCategory)
        .toList();
  }

  // ── Auth ─────────────────────────────────────────────
  void setUser(UserModel? user) {
    _currentUser = user;
    notifyListeners();
  }

  void clearUser() {
    _currentUser = null;
    _savedPlaces = [];
    notifyListeners();
  }

  // ── Places ───────────────────────────────────────────
  void setPlaces(List<Place> places) {
    _places = places;
    notifyListeners();
  }

  void addPlace(Place place) {
    // persist to DB and update local list
    _db.addPlace(place).then((_) {
      _places.insert(0, place);
      notifyListeners();
    }).catchError((e) {
      debugPrint('Error adding place to DB: $e');
    });
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
          localTip: p.localTip,
          imageUrl: p.imageUrl,
          latitude: p.latitude,
          longitude: p.longitude,
          contributorId: p.contributorId,
          contributorName: p.contributorName,
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
  void addRating(String placeId, double newRating, String comment, {String userId = 'anonymous', String userName = 'Anonymous'}) {
    final idx = _places.indexWhere((p) => p.id == placeId);
    if (idx == -1) return;
    final place = _places[idx];
    final review = Review(userId: userId, userName: userName, score: newRating, comment: comment, createdAt: DateTime.now());
    // Persist review then update local state
    _db.addReview(placeId, review).then((_) {
      final updated = List<Review>.from(place.reviews)..add(review);
      _places[idx] = Place(
        id: place.id,
        title: place.title,
        description: place.description,
        category: place.category,
        localTip: place.localTip,
        imageUrl: place.imageUrl,
        latitude: place.latitude,
        longitude: place.longitude,
        contributorId: place.contributorId,
        contributorName: place.contributorName,
        createdAt: place.createdAt,
        savedBy: place.savedBy,
        reviews: updated,
      );
      notifyListeners();
    }).catchError((e) {
      debugPrint('Error adding review to DB: $e');
    });
  }
}