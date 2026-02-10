import 'dart:convert';
import 'dart:io';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:http/http.dart' as http;

class FCMService {
  static final FCMService _instance = FCMService._internal();
  factory FCMService() => _instance;
  FCMService._internal();

  // Student note: change base url if you deploy backend
  static const String _baseUrl = 'http://10.0.2.2:3000';

  static const String _androidChannelId = 'high_importance_channel';
  static const String _androidChannelName = 'High Importance Notifications';
  static const String _androidChannelDesc =
      'This channel is used for important notifications.';

  final FirebaseMessaging _messaging = FirebaseMessaging.instance;
  final FlutterLocalNotificationsPlugin _local =
  FlutterLocalNotificationsPlugin();

  String? _fcmToken;
  String? get fcmToken => _fcmToken;

  bool _isInitialized = false;

  void Function(Map<String, dynamic> data)? onNotificationTap;

  // ---------------------------
  // Init
  // ---------------------------
  Future<void> initialize({void Function(Map<String, dynamic> data)? onTap}) async {
    if (_isInitialized) {
      debugPrint('FCM already initialized');
      return;
    }

    onNotificationTap = onTap;

    try {
      await _initLocalNotifications();
      await _requestPermissions();

      await _messaging.setForegroundNotificationPresentationOptions(
        alert: true,
        badge: true,
        sound: true,
      );

      await _getTokenAndSave();

      _messaging.onTokenRefresh.listen(_onTokenRefresh);

      FirebaseMessaging.onMessage.listen(_handleForegroundMessage);
      FirebaseMessaging.onMessageOpenedApp.listen(_handleMessageOpenedApp);

      final initialMessage = await _messaging.getInitialMessage();
      if (initialMessage != null) {
        _handleMessageOpenedApp(initialMessage);
      }

      _isInitialized = true;
      debugPrint('=== FCM Initialized ===');
      debugPrint('FCM Token: $_fcmToken');
    } catch (e) {
      debugPrint('FCM initialization error: $e');
    }
  }

  // ---------------------------
  // Permissions
  // ---------------------------
  Future<void> _requestPermissions() async {
    final settings = await _messaging.requestPermission(
      alert: true,
      badge: true,
      sound: true,
    );
    debugPrint('FCM Permission: ${settings.authorizationStatus}');

    if (!kIsWeb && Platform.isAndroid) {
      final androidImpl = _local.resolvePlatformSpecificImplementation<
          AndroidFlutterLocalNotificationsPlugin>();
      await androidImpl?.requestNotificationsPermission();
    }
  }

  // ---------------------------
  // Local notifications
  // ---------------------------
  Future<void> _initLocalNotifications() async {
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

    await _local.initialize(
      initSettings,
      onDidReceiveNotificationResponse: (NotificationResponse response) {
        if (response.payload == null || response.payload!.isEmpty) return;
        try {
          final data = jsonDecode(response.payload!) as Map<String, dynamic>;
          _handleTapData(data);
        } catch (_) {}
      },
    );

    const channel = AndroidNotificationChannel(
      _androidChannelId,
      _androidChannelName,
      description: _androidChannelDesc,
      importance: Importance.high,
    );

    await _local
        .resolvePlatformSpecificImplementation<
        AndroidFlutterLocalNotificationsPlugin>()
        ?.createNotificationChannel(channel);
  }

  NotificationDetails _notificationDetails() {
    return const NotificationDetails(
      android: AndroidNotificationDetails(
        _androidChannelId,
        _androidChannelName,
        channelDescription: _androidChannelDesc,
        importance: Importance.high,
        priority: Priority.high,
        icon: '@mipmap/ic_launcher',
      ),
      iOS: DarwinNotificationDetails(
        presentAlert: true,
        presentBadge: true,
        presentSound: true,
      ),
    );
  }

  // ---------------------------
  // Token + backend save
  // ---------------------------
  Future<void> _getTokenAndSave() async {
    _fcmToken = await _messaging.getToken();
    debugPrint('FCM Token: $_fcmToken');

    if (_fcmToken != null) {
      await _saveTokenToBackend(_fcmToken!);
    }
  }

  Future<void> _onTokenRefresh(String token) async {
    debugPrint('FCM Token Refreshed: $token');
    _fcmToken = token;
    await _saveTokenToBackend(token);
  }

  Future<void> saveTokenAfterLogin() async {
    if (_fcmToken != null) {
      await _saveTokenToBackend(_fcmToken!);
    } else {
      await _getTokenAndSave();
    }
  }

  Future<void> _saveTokenToBackend(String token) async {
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) {
        debugPrint('No Firebase user; will save FCM token after login');
        return;
      }

      final idToken = await user.getIdToken();

      // Student note: optional device info for ERD
      final deviceInfo = kIsWeb
          ? 'web'
          : Platform.isAndroid
          ? 'android'
          : Platform.isIOS
          ? 'ios'
          : 'other';

      final response = await http.post(
        Uri.parse('$_baseUrl/auth/save-fcm-token'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $idToken',
        },
        body: jsonEncode({
          'fcmToken': token,
          'deviceInfo': deviceInfo,
        }),
      );

      if (response.statusCode == 200) {
        debugPrint('FCM token saved to backend');
      } else {
        debugPrint(
            'Failed to save FCM token: ${response.statusCode} ${response.body}');
      }
    } catch (e) {
      debugPrint('Error saving FCM token: $e');
    }
  }

  // ---------------------------
  // Message handlers
  // ---------------------------
  void _handleForegroundMessage(RemoteMessage message) {
    debugPrint('=== Foreground Message ===');
    debugPrint('Title: ${message.notification?.title}');
    debugPrint('Body: ${message.notification?.body}');
    debugPrint('Data: ${message.data}');

    _showLocalNotification(message);
  }

  Future<void> _showLocalNotification(RemoteMessage message) async {
    final title = message.notification?.title ??
        message.data['title']?.toString() ??
        "New notification";
    final body = message.notification?.body ??
        message.data['message']?.toString() ??
        "";

    final payload = message.data.isNotEmpty ? jsonEncode(message.data) : null;

    await _local.show(
      DateTime.now().millisecondsSinceEpoch ~/ 1000,
      title,
      body,
      _notificationDetails(),
      payload: payload,
    );
  }

  void _handleMessageOpenedApp(RemoteMessage message) {
    debugPrint('App opened from notification: ${message.data}');
    _handleTapData(message.data);
  }

  void _handleTapData(Map<String, dynamic> data) {
    if (onNotificationTap != null) {
      onNotificationTap!(data);
    } else {
      debugPrint('Notification tap data (no handler set): $data');
    }
  }

  // ---------------------------
  // Topic subscriptions (FIXED)
  // ---------------------------

  Future<void> subscribeToAllResidents() async {
    await _messaging.subscribeToTopic("all_residents");
    debugPrint('Subscribed to topic: all_residents');
  }

  Future<void> subscribeToAllVendors() async {
    await _messaging.subscribeToTopic("all_vendors");
    debugPrint('Subscribed to topic: all_vendors');
  }

  /// Student note:
  /// ward can be:
  ///  - "Kathmandu Ward 4"
  ///  - Map {id:1, name:"Kathmandu Ward 4"}
  Future<void> subscribeToWardDynamic(Object? ward) async {
    final topic = _wardToTopicDynamic(ward);
    if (topic == null) {
      debugPrint('Ward topic is null, skipping subscription');
      return;
    }

    await _messaging.subscribeToTopic(topic);
    debugPrint('Subscribed to topic: $topic');
  }

  Future<void> unsubscribeFromWardDynamic(Object? ward) async {
    final topic = _wardToTopicDynamic(ward);
    if (topic == null) return;

    await _messaging.unsubscribeFromTopic(topic);
    debugPrint('Unsubscribed from topic: $topic');
  }

  /// Keep old API (string ward) but now sanitized properly
  Future<void> subscribeToWard(String ward) async {
    final topic = _wardToTopicFromName(ward);
    if (topic == null) return;
    await _messaging.subscribeToTopic(topic);
    debugPrint('Subscribed to topic: $topic');
  }

  Future<void> unsubscribeFromWard(String ward) async {
    final topic = _wardToTopicFromName(ward);
    if (topic == null) return;
    await _messaging.unsubscribeFromTopic(topic);
    debugPrint('Unsubscribed from topic: $topic');
  }

  Future<void> unsubscribeFromAll({Object? ward}) async {
    try {
      await unsubscribeFromWardDynamic(ward);
      await _messaging.unsubscribeFromTopic("all_residents");
      await _messaging.unsubscribeFromTopic("all_vendors");
      debugPrint('Unsubscribed from all topics');
    } catch (e) {
      debugPrint('Error unsubscribing from all: $e');
    }
  }

  // ---------------------------
  // Topic builders (VERY IMPORTANT)
  // ---------------------------

  String? _wardToTopicDynamic(Object? ward) {
    if (ward == null) return null;

    // If ERD ward map exists, prefer ward_<id> (always safe and short)
    if (ward is Map) {
      final id = ward['id'];
      final idInt = int.tryParse(id?.toString() ?? '');
      if (idInt != null) return 'ward_$idInt';

      final name = ward['name']?.toString();
      return _wardToTopicFromName(name);
    }

    // else treat it as string
    return _wardToTopicFromName(ward.toString());
  }

  String? _wardToTopicFromName(String? wardName) {
    final name = (wardName ?? '').trim();
    if (name.isEmpty) return null;

    // Firebase topic allowed chars: [a-zA-Z0-9-_.~%]
    // We replace everything else with underscore
    final cleaned = name
        .toLowerCase()
        .replaceAll(RegExp(r'[^a-z0-9\-\_\.\~%]'), '_')
        .replaceAll(RegExp(r'_+'), '_');

    final topic = 'ward_$cleaned';

    // Safety: topic length must be <= 900
    if (topic.length > 900) {
      return topic.substring(0, 900);
    }

    return topic;
  }
}