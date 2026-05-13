import 'dart:async';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/place_model.dart';
import 'package:likealocal/services/notification_service.dart';

class LocationService {
  // Singleton
  LocationService._singleton();
  static final LocationService _instance = LocationService._singleton();
  factory LocationService() => _instance;
  static LocationService get instance => _instance;

  // Proximity threshold — 1km in meters
  static const double _proximityRadius = 1000;

  // Key prefix for SharedPreferences
  // We store notified place IDs so we never notify twice
  static const String _notifiedPrefix = 'notified_place_';

  StreamSubscription<Position>? _positionStream;
  bool _isTracking = false;

  // Start tracking user location
  Future<void> startTracking(List<Place> places) async {
    if (_isTracking) return;

    // Check and request permission
    LocationPermission permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) {
        debugPrint('Location permission denied');
        return;
      }
    }
    if (permission == LocationPermission.deniedForever) {
      debugPrint('Location permission permanently denied');
      return;
    }

    _isTracking = true;
    debugPrint('Location tracking started');

    // Listen to position updates every 30 seconds
    // distanceFilter: only fires when user moves 50m — saves battery
    const locationSettings = LocationSettings(
      accuracy: LocationAccuracy.medium,
      distanceFilter: 50,    // meters moved before update fires
    );

    _positionStream = Geolocator.getPositionStream(
      locationSettings: locationSettings,
    ).listen(
      (Position position) {
        _checkProximity(position, places);
      },
      onError: (e) {
        debugPrint('Location stream error: $e');
        _isTracking = false;
      },
    );
  }

  // Stop tracking — call when user logs out
  void stopTracking() {
    _positionStream?.cancel();
    _positionStream = null;
    _isTracking = false;
    debugPrint('Location tracking stopped');
  }

  // Update places list when new places are loaded
  // Call this from app_provider when places refresh
  void updatePlaces(List<Place> places) {
    if (!_isTracking) return;
    stopTracking();
    startTracking(places);
  }

  // Check if user is within 1km of any place
  Future<void> _checkProximity(
      Position userPosition, List<Place> places) async {
    final prefs = await SharedPreferences.getInstance();

    for (final place in places) {
      // Skip if we already notified for this place
      final alreadyNotified =
          prefs.getBool('$_notifiedPrefix${place.id}') ?? false;
      if (alreadyNotified) continue;

      // Skip places with no real coordinates
      if (place.latitude == 0 && place.longitude == 0) continue;

      // Calculate distance in meters
      final distanceMeters = _calculateDistance(
        userPosition.latitude,
        userPosition.longitude,
        place.latitude,
        place.longitude,
      );

      debugPrint(
          'Distance to ${place.title}: ${distanceMeters.toStringAsFixed(0)}m');

      if (distanceMeters <= _proximityRadius) {
        // User is within 1km — send notification
        await NotificationService.instance.showNearbyPlaceNotification(
          placeId: place.id,
          placeTitle: place.title,
          placeCategory: place.category,
          city: place.city,
        );

        // Mark as notified so it never fires again
        await prefs.setBool('$_notifiedPrefix${place.id}', true);

        debugPrint(
            'User is near ${place.title} — notification sent!');
      }
    }
  }

  // Haversine formula — accurate distance between 2 GPS points
  double _calculateDistance(
    double lat1,
    double lon1,
    double lat2,
    double lon2,
  ) {
    const double earthRadius = 6371000; // meters
    final dLat = _toRadians(lat2 - lat1);
    final dLon = _toRadians(lon2 - lon1);

    final a = sin(dLat / 2) * sin(dLat / 2) +
        cos(_toRadians(lat1)) *
            cos(_toRadians(lat2)) *
            sin(dLon / 2) *
            sin(dLon / 2);

    final c = 2 * atan2(sqrt(a), sqrt(1 - a));
    return earthRadius * c;
  }

  double _toRadians(double degrees) => degrees * pi / 180;

  // Clear all notified places — useful for testing
  Future<void> clearNotifiedPlaces() async {
    final prefs = await SharedPreferences.getInstance();
    final keys = prefs.getKeys()
        .where((k) => k.startsWith(_notifiedPrefix))
        .toList();
    for (final key in keys) {
      await prefs.remove(key);
    }
    debugPrint('Cleared all notified places');
  }

  bool get isTracking => _isTracking;
}