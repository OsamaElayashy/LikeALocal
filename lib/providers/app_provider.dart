import 'package:flutter/material.dart';
import '../models/user_model.dart';
import '../models/place_model.dart';

class AppProvider extends ChangeNotifier {
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
    _places.insert(0, place); // add to top of list
    notifyListeners();
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
    final alreadySaved = _savedPlaces.any((p) => p.id == place.id);
    if (alreadySaved) {
      _savedPlaces.removeWhere((p) => p.id == place.id);
    } else {
      _savedPlaces.add(place);
    }
    notifyListeners();
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
}