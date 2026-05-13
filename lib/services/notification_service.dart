import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter/material.dart';

class NotificationService {
  // Singleton
  NotificationService._singleton();
  static final NotificationService _instance =
      NotificationService._singleton();
  factory NotificationService() => _instance;
  static NotificationService get instance => _instance;

  final FlutterLocalNotificationsPlugin _plugin =
      FlutterLocalNotificationsPlugin();

  bool _initialized = false;

  Future<void> initialize() async {
    if (_initialized) return;

    const androidSettings =
        AndroidInitializationSettings('@mipmap/ic_launcher');
    const iosSettings = DarwinInitializationSettings(
      requestAlertPermission: true,
      requestBadgePermission: true,
      requestSoundPermission: true,
    );

    const initSettings = InitializationSettings(
      android: androidSettings,
      iOS: iosSettings,
    );

    await _plugin.initialize(initSettings);
    _initialized = true;
    debugPrint('NotificationService initialized');
  }

  // Request permission (needed for Android 13+ and iOS)
  Future<void> requestPermission() async {
    final androidImplementation = _plugin.resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>();
    if (androidImplementation != null) {
      await androidImplementation.requestNotificationsPermission();
    }

    final iosImplementation = _plugin.resolvePlatformSpecificImplementation<IOSFlutterLocalNotificationsPlugin>();
    if (iosImplementation != null) {
      await iosImplementation.requestPermissions(
        alert: true,
        badge: true,
        sound: true,
      );
    }
  }

  // Show a notification when user is near a place
  Future<void> showNearbyPlaceNotification({
    required String placeId,
    required String placeTitle,
    required String placeCategory,
    required String city,
  }) async {
    const androidDetails = AndroidNotificationDetails(
      'nearby_places',           // channel id
      'Nearby Places',           // channel name
      channelDescription:
          'Notifications for places near your location',
      importance: Importance.high,
      priority: Priority.high,
      icon: '@mipmap/ic_launcher',
      color: Color(0xFF2563EB),
      styleInformation: BigTextStyleInformation(''),
    );

    const iosDetails = DarwinNotificationDetails(
      presentAlert: true,
      presentBadge: true,
      presentSound: true,
    );

    const details = NotificationDetails(
      android: androidDetails,
      iOS: iosDetails,
    );

    await _plugin.show(
      placeId.hashCode,   // unique notification id per place
      '📍 Hidden gem nearby!',
      '$placeTitle — $placeCategory in $city is less than 1km away',
      details,
    );

    debugPrint('Notification shown for: $placeTitle');
  }
}