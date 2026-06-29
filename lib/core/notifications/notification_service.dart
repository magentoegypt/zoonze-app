import 'dart:async';
import 'dart:convert';
import 'dart:ui' show Color;

import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';

/// Background message handler — runs in its own isolate; keep it minimal.
@pragma('vm:entry-point')
Future<void> firebaseBackgroundHandler(RemoteMessage message) async {}

/// A received notification surfaced to the app for the local inbox.
class NotificationMessage {
  const NotificationMessage({
    this.title,
    this.body,
    this.data = const <String, dynamic>{},
  });

  final String? title;
  final String? body;
  final Map<String, dynamic> data;
}

/// App-side push plumbing. Local notifications work standalone; FCM is enabled
/// only when a Firebase config (google-services.json / GoogleService-Info.plist)
/// is present, otherwise it degrades to a no-op so the app still runs.
class NotificationService {
  NotificationService._();
  static final NotificationService instance = NotificationService._();

  final FlutterLocalNotificationsPlugin _local =
      FlutterLocalNotificationsPlugin();
  bool _fcmAvailable = false;

  bool get fcmAvailable => _fcmAvailable;

  /// Data payloads of notifications the user tapped (foreground-local or a
  /// backgrounded FCM message). The app layer maps these to a route. Stays
  /// UI-agnostic — core doesn't know about app routes.
  final StreamController<Map<String, dynamic>> _opened =
      StreamController<Map<String, dynamic>>.broadcast();

  Stream<Map<String, dynamic>> get onNotificationOpened => _opened.stream;

  /// Every received notification (foreground push, or a tapped/cold-start one),
  /// for persisting into the local inbox. UI-agnostic.
  final StreamController<NotificationMessage> _received =
      StreamController<NotificationMessage>.broadcast();

  Stream<NotificationMessage> get onNotificationReceived => _received.stream;

  void _ingest(RemoteMessage message) {
    final notification = message.notification;
    final data = Map<String, dynamic>.from(message.data);
    if (notification == null && data.isEmpty) return;
    _received.add(
      NotificationMessage(
        title: notification?.title ?? data['title'] as String?,
        body: notification?.body ?? data['body'] as String?,
        data: data,
      ),
    );
  }

  Map<String, dynamic>? _initial;

  /// The notification that cold-started the app, if any. Consumed once (so the
  /// app navigates to it exactly once, after the first frame).
  Map<String, dynamic>? takeInitialMessage() {
    final message = _initial;
    _initial = null;
    return message;
  }

  static const AndroidNotificationChannel _channel = AndroidNotificationChannel(
    'zoonze_default',
    'General',
    description: 'Order updates and promotions',
    importance: Importance.high,
  );

  Future<void> init() async {
    await _initLocal();
    await _initFirebase();
  }

  Future<void> _initLocal() async {
    const settings = InitializationSettings(
      // White status-bar silhouette (res/drawable/ic_stat_notify) — the colour
      // launcher icon would render as a white square in the status bar.
      android: AndroidInitializationSettings('ic_stat_notify'),
      iOS: DarwinInitializationSettings(),
    );
    await _local.initialize(
      settings: settings,
      onDidReceiveNotificationResponse: _onLocalTap,
    );
    final android = _local
        .resolvePlatformSpecificImplementation<
          AndroidFlutterLocalNotificationsPlugin
        >();
    await android?.createNotificationChannel(_channel);
    await android?.requestNotificationsPermission();
  }

  Future<void> _initFirebase() async {
    try {
      await Firebase.initializeApp();
      _fcmAvailable = true;
    } catch (error) {
      // No Firebase config bundled — FCM stays disabled (see docs/decisions).
      _fcmAvailable = false;
      debugPrint('FCM disabled (no Firebase config): $error');
      return;
    }
    try {
      FirebaseMessaging.onBackgroundMessage(firebaseBackgroundHandler);
      await FirebaseMessaging.instance.requestPermission();
      FirebaseMessaging.onMessage.listen(_showRemote);
      // Tapped while backgrounded → navigate (and record in the inbox). Cold-
      // start tap is captured once via getInitialMessage and replayed after the
      // first frame.
      FirebaseMessaging.onMessageOpenedApp.listen((m) {
        _ingest(m);
        _emit(m.data);
      });
      final initial = await FirebaseMessaging.instance.getInitialMessage();
      if (initial != null) {
        _ingest(initial);
        if (initial.data.isNotEmpty) {
          _initial = Map<String, dynamic>.from(initial.data);
        }
      }
    } catch (error) {
      debugPrint('FCM setup error: $error');
    }
  }

  void _onLocalTap(NotificationResponse response) {
    final payload = response.payload;
    if (payload == null || payload.isEmpty) return;
    try {
      final decoded = jsonDecode(payload);
      if (decoded is Map) _emit(Map<String, dynamic>.from(decoded));
    } catch (_) {
      // Non-JSON payload — ignore.
    }
  }

  void _emit(Map<String, dynamic> data) {
    if (data.isNotEmpty) _opened.add(data);
  }

  Future<void> _showRemote(RemoteMessage message) async {
    final notification = message.notification;
    if (notification == null) return;
    await _local.show(
      id: notification.hashCode,
      title: notification.title,
      body: notification.body,
      // Carry the data so tapping the foreground notification routes too.
      payload: message.data.isEmpty ? null : jsonEncode(message.data),
      notificationDetails: NotificationDetails(
        android: AndroidNotificationDetails(
          _channel.id,
          _channel.name,
          channelDescription: _channel.description,
          importance: Importance.high,
          priority: Priority.high,
          icon: 'ic_stat_notify',
          color: Color(0xFF9E1B3F),
        ),
        iOS: const DarwinNotificationDetails(),
      ),
    );
    // Surface to the local inbox.
    _ingest(message);
  }

  Future<void> subscribeToTopic(String topic) async {
    if (!_fcmAvailable) return;
    await FirebaseMessaging.instance.subscribeToTopic(topic);
  }

  Future<void> unsubscribeFromTopic(String topic) async {
    if (!_fcmAvailable) return;
    await FirebaseMessaging.instance.unsubscribeFromTopic(topic);
  }

  Future<String?> token() async =>
      _fcmAvailable ? FirebaseMessaging.instance.getToken() : null;

  /// Emits whenever FCM rotates the device token, so the app can re-register it
  /// with the backend. Empty stream when FCM is unavailable.
  Stream<String> get onTokenRefresh => _fcmAvailable
      ? FirebaseMessaging.instance.onTokenRefresh
      : const Stream<String>.empty();
}
