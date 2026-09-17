// lib/services/notification_service.dart
//
// Initialises flutter_local_notifications so FCM messages show as
// system notifications when the app is in the foreground or background.
// Notification channels:
//   chat_channel  — messages & match alerts  (high importance)

import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';

class NotificationService {
  static final _notifications = FlutterLocalNotificationsPlugin();

  // ── Android notification channel ──────────────────────────────────────────
  static const _chatChannel = AndroidNotificationChannel(
    'chat_channel',
    'Chat & Match Notifications',
    description: 'Notifications for new messages and job matches',
    importance: Importance.max,
    playSound: true,
    enableVibration: true,
  );

  // ── Initialise once at app startup ────────────────────────────────────────
  static Future<void> initialize() async {
    const androidSettings =
        AndroidInitializationSettings('@mipmap/ic_launcher');
    const iosSettings = DarwinInitializationSettings(
      requestAlertPermission: false, // we request explicitly in main.dart
      requestBadgePermission: false,
      requestSoundPermission: false,
    );
    const initSettings =
        InitializationSettings(android: androidSettings, iOS: iosSettings);

    // Create the Android channel before initialising the plugin
    await _notifications
        .resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin>()
        ?.createNotificationChannel(_chatChannel);

    await _notifications.initialize(
      initSettings,
      onDidReceiveNotificationResponse: (response) {
        // Payload is the chatId — navigation is handled by onMessageOpenedApp
        // in main.dart; no extra work needed here.
      },
    );
  }

  // ── Show a local notification (foreground & background) ───────────────────
  static Future<void> showNotification(RemoteMessage message) async {
    const androidDetails = AndroidNotificationDetails(
      'chat_channel',
      'Chat & Match Notifications',
      channelDescription: 'Notifications for new messages and job matches',
      importance: Importance.max,
      priority: Priority.high,
      playSound: true,
    );
    const iosDetails = DarwinNotificationDetails(
      presentAlert: true,
      presentBadge: true,
      presentSound: true,
    );
    const details =
        NotificationDetails(android: androidDetails, iOS: iosDetails);

    await _notifications.show(
      message.messageId?.hashCode ?? message.data.hashCode,
      message.notification?.title ?? 'SwipeHire',
      message.notification?.body ?? 'You have a new notification',
      details,
      payload: message.data['chatId'],
    );
  }
}
