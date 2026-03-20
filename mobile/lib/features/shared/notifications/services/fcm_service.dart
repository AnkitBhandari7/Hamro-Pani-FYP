import 'dart:convert';
import 'dart:io';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:http/http.dart' as http;

///
/// This service handles:
/// 1) FCM permission + token generation
/// 2) saving token to backend (/auth/save-fcm-token)
/// 3) subscribing user to correct TOPICS based on backend profile (/auth/me)
/// Backend sends schedule notifications to a ward topic like:
///   ward_kathmandu_ward_4
/// so RESIDENT must subscribe to that exact topic.

class FCMService {
  static final FCMService _instance = FCMService._internal();
  factory FCMService() => _instance;
  FCMService._internal();

  // change base url if you deploy backend
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

  // Init

  Future<void> initialize({
    void Function(Map<String, dynamic> data)? onTap,
  }) async {
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

      //  get token -> save to backend -> sync subscriptions
      await _getTokenAndSave();
      await _syncTopicSubscriptionsFromBackendProfile();

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

  // Permissions

  Future<void> _requestPermissions() async {
    final settings = await _messaging.requestPermission(
      alert: true,
      badge: true,
      sound: true,
    );
    debugPrint('FCM Permission: ${settings.authorizationStatus}');

    //  Android 13+ runtime notification permission
    if (!kIsWeb && Platform.isAndroid) {
      final androidImpl = _local
          .resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin
          >();
      await androidImpl?.requestNotificationsPermission();
    }
  }

  // Local notifications

  Future<void> _initLocalNotifications() async {
    const androidSettings = AndroidInitializationSettings(
      '@mipmap/ic_launcher',
    );
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
          AndroidFlutterLocalNotificationsPlugin
        >()
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

  // Token + backend save

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
    await _syncTopicSubscriptionsFromBackendProfile();
  }

  /// Call this after login/register in Flutter.
  /// It saves FCM token then subscribes topics using backend /auth/me.
  Future<void> saveTokenAfterLogin() async {
    if (_fcmToken != null) {
      await _saveTokenToBackend(_fcmToken!);
    } else {
      await _getTokenAndSave();
    }
    await _syncTopicSubscriptionsFromBackendProfile();
  }

  Future<void> _saveTokenToBackend(String token) async {
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) {
        debugPrint('No Firebase user; will save FCM token after login');
        return;
      }

      final idToken = await user.getIdToken();

      //  optional device info for ERD
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
        body: jsonEncode({'fcmToken': token, 'deviceInfo': deviceInfo}),
      );

      if (response.statusCode == 200) {
        debugPrint('FCM token saved to backend');
      } else {
        debugPrint(
          'Failed to save FCM token: ${response.statusCode} ${response.body}',
        );
      }
    } catch (e) {
      debugPrint('Error saving FCM token: $e');
    }
  }

  // Topic sync (role + ward)

  /// Backend is source of truth for user role + ward.
  /// We fetch /auth/me and subscribe accordingly.
  Future<void> _syncTopicSubscriptionsFromBackendProfile() async {
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) {
        debugPrint('No logged-in user; skipping topic subscription sync');
        return;
      }

      final idToken = await user.getIdToken();

      final resp = await http.get(
        Uri.parse('$_baseUrl/auth/me'),
        headers: {'Authorization': 'Bearer $idToken'},
      );

      if (resp.statusCode != 200) {
        debugPrint(
          'Failed /auth/me for topic sync: ${resp.statusCode} ${resp.body}',
        );
        return;
      }

      final me = jsonDecode(resp.body) as Map<String, dynamic>;
      final role = (me['role'] ?? '').toString().toUpperCase();
      final ward = me['ward']; // null or {id,name}

      debugPrint('=== Topic Sync (/auth/me) ===');
      debugPrint('Role: $role');
      debugPrint('Ward: $ward');

      if (role == 'RESIDENT') {
        await subscribeToAllResidents();
        if (ward != null) {
          await subscribeToWardDynamic(ward);
        } else {
          debugPrint('Resident ward is null; cannot subscribe to ward topic');
        }
      } else if (role == 'VENDOR') {
        await subscribeToAllVendors();
      } else {
        debugPrint('No resident/vendor subscription needed for role=$role');
      }
    } catch (e) {
      debugPrint('Topic sync error: $e');
    }
  }

  // Message handlers
  void _handleForegroundMessage(RemoteMessage message) {
    debugPrint('=== Foreground Message ===');
    debugPrint('Title: ${message.notification?.title}');
    debugPrint('Body: ${message.notification?.body}');
    debugPrint('Data: ${message.data}');
    _showLocalNotification(message);
  }

  Future<void> _showLocalNotification(RemoteMessage message) async {
    final title =
        message.notification?.title ??
        message.data['title']?.toString() ??
        "New notification";
    final body =
        message.notification?.body ?? message.data['message']?.toString() ?? "";

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

  // Topic subscriptions

  Future<void> subscribeToAllResidents() async {
    await _messaging.subscribeToTopic("all_residents");
    debugPrint('Subscribed to topic: all_residents');
  }

  Future<void> subscribeToAllVendors() async {
    await _messaging.subscribeToTopic("all_vendors");
    debugPrint('Subscribed to topic: all_vendors');
  }

  /// ward can be:
  ///  - Map {id:1, name:"Kathmandu Ward 4"}
  ///  - or string "Kathmandu Ward 4"
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

  Future<void> subscribeToWard(String wardName) async {
    final topic = _wardToTopicFromName(wardName);
    if (topic == null) {
      debugPrint('subscribeToWard: invalid wardName="$wardName"');
      return;
    }
    await _messaging.subscribeToTopic(topic);
    debugPrint('Subscribed to topic: $topic');
  }

  Future<void> unsubscribeFromWard(String wardName) async {
    final topic = _wardToTopicFromName(wardName);
    if (topic == null) {
      debugPrint('unsubscribeFromWard: invalid wardName="$wardName"');
      return;
    }
    await _messaging.unsubscribeFromTopic(topic);
    debugPrint('Unsubscribed from topic: $topic');
  }

  // Topic builders

  String? _wardToTopicDynamic(Object? ward) {
    if (ward == null) return null;

    //  backend returns ward as {id, name}
    if (ward is Map) {
      final name = ward['name']?.toString();
      return _wardToTopicFromName(name);
    }

    return _wardToTopicFromName(ward.toString());
  }

  ///   return `ward_${String(ward).toLowerCase().trim().replaceAll(" ", "_")}`;
  String? _wardToTopicFromName(String? wardName) {
    final name = (wardName ?? '').trim();
    if (name.isEmpty) return null;

    final cleaned = name.toLowerCase().replaceAll(' ', '_');
    return 'ward_$cleaned';
  }
}
