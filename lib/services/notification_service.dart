import 'dart:io';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:timezone/timezone.dart' as tz;
import 'package:timezone/data/latest.dart' as tz_data;

/// Background message handler - must be top-level function
@pragma('vm:entry-point')
Future<void> firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  debugPrint('Handling background message: ${message.messageId}');
}

/// Initialize timezone data - call this in main.dart before runApp
Future<void> initializeTimezone() async {
  tz_data.initializeTimeZones();
}

/// Service for handling push notifications and local reminders
class NotificationService {
  static final NotificationService _instance = NotificationService._internal();
  factory NotificationService() => _instance;
  NotificationService._internal();

  final FirebaseMessaging _messaging = FirebaseMessaging.instance;
  final FlutterLocalNotificationsPlugin _localNotifications =
      FlutterLocalNotificationsPlugin();
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  bool _isInitialized = false;

  /// Initialize notification service
  Future<void> initialize() async {
    if (_isInitialized) return;

    try {
      // Request permission
      await _requestPermission();

      // Initialize local notifications
      await _initializeLocalNotifications();

      // Setup FCM handlers
      _setupFCMHandlers();

      _isInitialized = true;
      debugPrint('NotificationService: Initialized');
    } catch (e) {
      debugPrint('NotificationService: Initialization error: $e');
      // Don't block app startup if notifications fail
      _isInitialized = true;
    }
  }

  /// Request notification permissions
  Future<void> _requestPermission() async {
    final settings = await _messaging.requestPermission(
      alert: true,
      announcement: false,
      badge: true,
      carPlay: false,
      criticalAlert: false,
      provisional: false,
      sound: true,
    );

    debugPrint(
      'NotificationService: Permission status: ${settings.authorizationStatus}',
    );
  }

  /// Initialize local notifications plugin
  Future<void> _initializeLocalNotifications() async {
    const androidSettings = AndroidInitializationSettings('@mipmap/ic_launcher');
    const iosSettings = DarwinInitializationSettings(
      requestAlertPermission: true,
      requestBadgePermission: true,
      requestSoundPermission: true,
    );

    const initSettings = InitializationSettings(
      android: androidSettings,
      iOS: iosSettings,
    );

    await _localNotifications.initialize(
      initSettings,
      onDidReceiveNotificationResponse: _onNotificationTapped,
    );

    // Create notification channel for Android
    try {
      if (Platform.isAndroid) {
        const channel = AndroidNotificationChannel(
          'session_reminders',
          'Session Reminders',
          description: 'Reminders for upcoming language sessions',
          importance: Importance.high,
        );

        await _localNotifications
            .resolvePlatformSpecificImplementation<
                AndroidFlutterLocalNotificationsPlugin>()
            ?.createNotificationChannel(channel);
      }
    } catch (e) {
      debugPrint('NotificationService: Channel creation error: $e');
    }
  }

  /// Handle notification tap
  void _onNotificationTapped(NotificationResponse response) {
    debugPrint('NotificationService: Notification tapped: ${response.payload}');
    // Navigation can be handled here if needed
  }

  /// Setup FCM message handlers
  void _setupFCMHandlers() {
    // Handle foreground messages
    FirebaseMessaging.onMessage.listen(_handleForegroundMessage);

    // Handle when app is opened from notification
    FirebaseMessaging.onMessageOpenedApp.listen(_handleMessageOpenedApp);

    // Check if app was opened from a terminated state via notification
    _checkInitialMessage();
  }

  /// Handle foreground FCM messages
  Future<void> _handleForegroundMessage(RemoteMessage message) async {
    debugPrint('NotificationService: Foreground message received');

    // Show local notification when app is in foreground
    if (message.notification != null) {
      await showLocalNotification(
        title: message.notification!.title ?? 'Vocalize',
        body: message.notification!.body ?? '',
        payload: message.data.toString(),
      );
    }
  }

  /// Handle when app is opened from notification
  void _handleMessageOpenedApp(RemoteMessage message) {
    debugPrint('NotificationService: App opened from notification');
    // Handle navigation based on message data
  }

  /// Check if app was opened from terminated state via notification
  Future<void> _checkInitialMessage() async {
    final initialMessage = await _messaging.getInitialMessage();
    if (initialMessage != null) {
      debugPrint('NotificationService: App opened from terminated state');
      // Handle navigation based on message data
    }
  }

  /// Get FCM token for this device
  Future<String?> getToken() async {
    final token = await _messaging.getToken();
    debugPrint('NotificationService: FCM Token: $token');
    return token;
  }

  /// Save FCM token to Firestore for the user
  Future<void> saveTokenToFirestore(String userId) async {
    try {
      final token = await getToken();
      if (token != null && token.isNotEmpty) {
        await _firestore.collection('users').doc(userId).set({
          'fcmToken': token,
          'fcmTokenUpdatedAt': FieldValue.serverTimestamp(),
        }, SetOptions(merge: true));
        debugPrint('NotificationService: Token saved for user $userId');
      } else {
        debugPrint('NotificationService: No token available for user $userId');
      }
    } catch (e) {
      debugPrint('NotificationService: Error saving token: $e');
    }
  }

  /// Show a local notification
  Future<void> showLocalNotification({
    required String title,
    required String body,
    String? payload,
  }) async {
    const androidDetails = AndroidNotificationDetails(
      'session_reminders',
      'Session Reminders',
      channelDescription: 'Reminders for upcoming language sessions',
      importance: Importance.high,
      priority: Priority.high,
      icon: '@mipmap/ic_launcher',
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

    await _localNotifications.show(
      DateTime.now().millisecondsSinceEpoch ~/ 1000,
      title,
      body,
      details,
      payload: payload,
    );
  }

  /// Schedule a reminder notification for a session
  Future<void> scheduleSessionReminder({
    required String sessionId,
    required String partnerName,
    required DateTime scheduledTime,
    int minutesBefore = 15,
  }) async {
    final reminderTime = scheduledTime.subtract(
      Duration(minutes: minutesBefore),
    );

    // Only schedule if reminder time is in the future
    if (reminderTime.isBefore(DateTime.now())) {
      debugPrint('NotificationService: Reminder time is in the past, skipping');
      return;
    }

    const androidDetails = AndroidNotificationDetails(
      'session_reminders',
      'Session Reminders',
      channelDescription: 'Reminders for upcoming language sessions',
      importance: Importance.high,
      priority: Priority.high,
      icon: '@mipmap/ic_launcher',
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

    // Use zonedSchedule for precise scheduling
    await _localNotifications.zonedSchedule(
      sessionId.hashCode,
      'Session Starting Soon! 🗣️',
      'Your session with $partnerName starts in $minutesBefore minutes',
      _convertToTZDateTime(reminderTime),
      details,
      androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
      uiLocalNotificationDateInterpretation:
          UILocalNotificationDateInterpretation.absoluteTime,
      payload: sessionId,
    );

    debugPrint(
      'NotificationService: Scheduled reminder for $sessionId at $reminderTime',
    );
  }

  /// Convert DateTime to TZDateTime
  tz.TZDateTime _convertToTZDateTime(DateTime dateTime) {
    return tz.TZDateTime.from(dateTime, tz.local);
  }

  /// Cancel a scheduled notification
  Future<void> cancelScheduledNotification(String sessionId) async {
    await _localNotifications.cancel(sessionId.hashCode);
    debugPrint('NotificationService: Cancelled notification for $sessionId');
  }

  /// Cancel all scheduled notifications
  Future<void> cancelAllNotifications() async {
    await _localNotifications.cancelAll();
    debugPrint('NotificationService: Cancelled all notifications');
  }

  /// Send notification to a specific user (requires Cloud Functions)
  /// This stores the notification request in Firestore, which can be
  /// processed by a Cloud Function to send the actual FCM message
  Future<void> sendNotificationToUser({
    required String userId,
    required String title,
    required String body,
    Map<String, dynamic>? data,
  }) async {
    await _firestore.collection('notification_queue').add({
      'userId': userId,
      'title': title,
      'body': body,
      'data': data ?? {},
      'createdAt': FieldValue.serverTimestamp(),
      'status': 'pending',
    });
    debugPrint('NotificationService: Queued notification for user $userId');
  }
}
