import 'dart:convert';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';

/// Firebase Cloud Messaging service for handling push notifications.
/// Manages token registration, foreground/background message handling,
/// and notification permission requests.
class NotificationService {
  final FirebaseMessaging _messaging = FirebaseMessaging.instance;
  String? _fcmToken;

  String? get fcmToken => _fcmToken;

  /// Initializes FCM: requests permissions, gets token, and sets up handlers.
  Future<void> init() async {
    // Request notification permission (required for iOS, optional for Android 13+)
    final settings = await _messaging.requestPermission(
      alert: true,
      announcement: false,
      badge: true,
      carPlay: false,
      criticalAlert: false,
      provisional: false,
      sound: true,
    );

    debugPrint('FCM permission status: ${settings.authorizationStatus}');

    if (settings.authorizationStatus == AuthorizationStatus.authorized ||
        settings.authorizationStatus == AuthorizationStatus.provisional) {
      await _getToken();
      _setupMessageHandlers();
    }
  }

  /// Retrieves the FCM device token for push notification targeting.
  Future<void> _getToken() async {
    _fcmToken = await _messaging.getToken();
    debugPrint('FCM Token: $_fcmToken');

    // Listen for token refresh (happens when app data is cleared, etc.)
    _messaging.onTokenRefresh.listen((newToken) {
      _fcmToken = newToken;
      debugPrint('FCM Token refreshed: $newToken');
      // TODO: Sprint 1 — Send updated token to backend
    });
  }

  /// Configures handlers for foreground and background messages.
  void _setupMessageHandlers() {
    // Foreground messages — app is open and in the foreground
    FirebaseMessaging.onMessage.listen((RemoteMessage message) {
      debugPrint('Foreground message received: ${message.messageId}');
      _handleMessage(message);
    });

    // When user taps a notification while app is in background
    FirebaseMessaging.onMessageOpenedApp.listen((RemoteMessage message) {
      debugPrint('Message opened app: ${message.messageId}');
      _handleNotificationTap(message);
    });

    // Check if app was opened from a terminated state via notification
    _messaging.getInitialMessage().then((RemoteMessage? message) {
      if (message != null) {
        debugPrint('App opened from terminated state: ${message.messageId}');
        _handleNotificationTap(message);
      }
    });
  }

  /// Handles incoming messages (both foreground and background).
  void _handleMessage(RemoteMessage message) {
    final notification = message.notification;
    final data = message.data;

    if (notification != null) {
      debugPrint('Notification: ${notification.title} — ${notification.body}');
    }

    if (data.isNotEmpty) {
      debugPrint('Data payload: ${jsonEncode(data)}');
      // TODO: Sprint 2 — Route to correct screen based on data payload type
    }
  }

  /// Handles notification tap — navigates to the relevant screen.
  void _handleNotificationTap(RemoteMessage message) {
    final data = message.data;
    final type = data['type'];
    final targetId = data['targetId'];

    debugPrint('Notification tapped: type=$type, targetId=$targetId');

    // TODO: Sprint 2 — Navigate using GoRouter based on notification type
    // e.g., type='chat' → navigate to chat detail screen
    // e.g., type='call' → navigate to incoming call screen
  }

  /// Subscribes the device to a notification topic (e.g., group chat).
  Future<void> subscribeToTopic(String topic) async {
    await _messaging.subscribeToTopic(topic);
    debugPrint('Subscribed to topic: $topic');
  }

  /// Unsubscribes the device from a notification topic.
  Future<void> unsubscribeFromTopic(String topic) async {
    await _messaging.unsubscribeFromTopic(topic);
    debugPrint('Unsubscribed from topic: $topic');
  }
}

/// Top-level function for handling background messages.
/// Must be a top-level function (not a class method).
@pragma('vm:entry-point')
Future<void> firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  debugPrint('Background message received: ${message.messageId}');
  // TODO: Sprint 2 — Process background messages (update local DB, etc.)
}
