import 'dart:convert';
import 'dart:io';

import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';

import '../firebase_options.dart';
import '../screens/dashboard_screen.dart';

/// Global navigator key. Lets us push a screen when a notification is tapped,
/// even from callbacks that have no [BuildContext]. Wired into [MaterialApp]
/// via `navigatorKey:` in `myapp.dart`.
final GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();

/// The single Android channel used for all notifications.
///
/// * `importance: high` + a sound => Android shows a heads-up banner and plays
///   the **default** system notification sound.
/// * The same id is referenced by `default_notification_channel_id` in
///   `AndroidManifest.xml`, so notifications that Android renders on its own
///   (background / terminated) also land on this channel and get the sound.
const AndroidNotificationChannel kDefaultChannel = AndroidNotificationChannel(
  'high_importance_channel',
  'General Notifications',
  description: 'Visitor and invite alerts.',
  importance: Importance.high,
  playSound: true, // default system sound (no custom sound file)
);

final FlutterLocalNotificationsPlugin _localNotifications =
    FlutterLocalNotificationsPlugin();

/// Background / terminated message handler.
///
/// MUST be a top-level (or static) function annotated with
/// `@pragma('vm:entry-point')` — it runs in its own background isolate, so
/// Firebase has to be initialised again here before any Firebase call.
///
/// When the FCM payload contains a `notification` block, the OS renders the
/// system notification (with sound) automatically in this state; we only log.
/// Add data-only handling here if you need it later.
@pragma('vm:entry-point')
Future<void> firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );
  debugPrint(
    '🔔 [BG] id=${message.messageId} '
    'title=${message.notification?.title} data=${message.data}',
  );
}

/// Sets up Firebase Cloud Messaging + local notifications for the whole app.
///
/// Call [initialize] once, after `Firebase.initializeApp`, before `runApp`.
class NotificationService {
  NotificationService._();
  static final NotificationService instance = NotificationService._();

  final FirebaseMessaging _fcm = FirebaseMessaging.instance;

  Future<void> initialize() async {
    // 1. Ask the OS for permission. iOS shows the system prompt now; Android
    //    13+ is requested via the local-notifications plugin below.
    final settings = await _fcm.requestPermission(
      alert: true,
      badge: true,
      sound: true,
    );
    debugPrint('📱 Permission: ${settings.authorizationStatus}');

    // 2. Foreground presentation (mainly iOS): show the banner and play the
    //    sound even while the app is open.
    await _fcm.setForegroundNotificationPresentationOptions(
      alert: true,
      badge: true,
      sound: true,
    );

    // 3. Local notifications plugin + Android channel (used for FOREGROUND
    //    notifications on Android).
    await _initLocalNotifications();

    // 4. Message streams.
    FirebaseMessaging.onMessage.listen(_onForegroundMessage);
    FirebaseMessaging.onMessageOpenedApp.listen(_onMessageOpenedApp);

    // 5. Log tokens (APNs must resolve before the FCM token on iOS).
    await _logTokens();

    // 6. Cold start: app launched by tapping a notification (terminated state).
    final initialMessage = await _fcm.getInitialMessage();
    if (initialMessage != null) {
      _handleTap(initialMessage);
    }
  }

  Future<void> _initLocalNotifications() async {
    const androidInit = AndroidInitializationSettings('@mipmap/ic_launcher');
    // Don't request iOS permissions here — FCM.requestPermission already did,
    // otherwise the user would be prompted twice.
    const darwinInit = DarwinInitializationSettings(
      requestAlertPermission: false,
      requestBadgePermission: false,
      requestSoundPermission: false,
    );
    const initSettings = InitializationSettings(
      android: androidInit,
      iOS: darwinInit,
    );

    await _localNotifications.initialize(
      initSettings,
      onDidReceiveNotificationResponse: (response) =>
          _handleTapPayload(response.payload),
    );

    final androidImpl = _localNotifications
        .resolvePlatformSpecificImplementation<
          AndroidFlutterLocalNotificationsPlugin
        >();
    // Create the channel (safe to call repeatedly).
    await androidImpl?.createNotificationChannel(kDefaultChannel);
    // Android 13+ runtime notification permission.
    await androidImpl?.requestNotificationsPermission();
  }

  /// Foreground message: on Android we must render the notification ourselves;
  /// on iOS the system already shows it (see presentation options above).
  void _onForegroundMessage(RemoteMessage message) {
    debugPrint('🔔 [FG] ${message.notification?.title}');
    final notification = message.notification;
    if (notification == null) return; // data-only message, nothing to show

    if (Platform.isAndroid) {
      _localNotifications.show(
        notification.hashCode,
        notification.title,
        notification.body,
        NotificationDetails(
          android: AndroidNotificationDetails(
            kDefaultChannel.id,
            kDefaultChannel.name,
            channelDescription: kDefaultChannel.description,
            importance: Importance.high,
            priority: Priority.high,
            playSound: true, // default system sound
            icon: '@mipmap/ic_launcher',
          ),
        ),
        payload: message.data.isEmpty ? null : jsonEncode(message.data),
      );
    }
  }

  void _onMessageOpenedApp(RemoteMessage message) => _handleTap(message);

  void _handleTap(RemoteMessage message) {
    debugPrint('🔔 Tapped (FCM): ${message.data}');
    _navigateToTarget();
  }

  void _handleTapPayload(String? payload) {
    debugPrint('🔔 Tapped (local): $payload');
    _navigateToTarget();
  }

  /// Where a notification tap takes the user. Change [DashboardScreen] to your
  /// desired destination, or branch on the message data. Guarded so it never
  /// throws if the navigator isn't mounted yet.
  void _navigateToTarget() {
    final nav = navigatorKey.currentState;
    if (nav == null) return;
    nav.push(MaterialPageRoute<void>(builder: (_) => const DashboardScreen()));
  }

  Future<void> _logTokens() async {
    try {
      if (Platform.isIOS) {
        String? apns;
        for (var i = 0; i < 10 && apns == null; i++) {
          apns = await _fcm.getAPNSToken();
          if (apns == null) {
            await Future.delayed(const Duration(milliseconds: 500));
          }
        }
        debugPrint(
          apns == null
              ? '❌ APNs token null — use a real device and check Xcode signing/capabilities.'
              : '✅ APNs token received',
        );
      }
      final token = await _fcm.getToken();
      debugPrint('✅ FCM token: $token');
    } catch (e) {
      debugPrint('❌ Failed to get token: $e');
    }
  }
}
