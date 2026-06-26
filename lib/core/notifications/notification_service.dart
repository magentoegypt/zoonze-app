import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';

/// Background message handler — runs in its own isolate; keep it minimal.
@pragma('vm:entry-point')
Future<void> firebaseBackgroundHandler(RemoteMessage message) async {}

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
      android: AndroidInitializationSettings('@mipmap/ic_launcher'),
      iOS: DarwinInitializationSettings(),
    );
    await _local.initialize(settings: settings);
    final android = _local.resolvePlatformSpecificImplementation<
        AndroidFlutterLocalNotificationsPlugin>();
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
    } catch (error) {
      debugPrint('FCM setup error: $error');
    }
  }

  Future<void> _showRemote(RemoteMessage message) async {
    final notification = message.notification;
    if (notification == null) return;
    await _local.show(
      id: notification.hashCode,
      title: notification.title,
      body: notification.body,
      notificationDetails: NotificationDetails(
        android: AndroidNotificationDetails(
          _channel.id,
          _channel.name,
          channelDescription: _channel.description,
          importance: Importance.high,
          priority: Priority.high,
        ),
        iOS: const DarwinNotificationDetails(),
      ),
    );
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
}
