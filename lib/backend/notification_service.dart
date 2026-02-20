// notification_service.dart
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/timezone.dart' as tz;
import 'package:timezone/data/latest_all.dart' as tz;
import 'package:permission_handler/permission_handler.dart';
import 'package:flutter/material.dart';
import '../main.dart'; // for navigatorKey
import '../frontend/event_action_dialog.dart';
import '../backend/models.dart';
import '../backend/data_provider.dart';
import 'package:provider/provider.dart';

// Singleton so notification state is shared across the app without
// needing to pass an instance through the widget tree.
class NotificationService {
  static final NotificationService _instance = NotificationService._internal();
  factory NotificationService() => _instance;
  NotificationService._internal();

  final FlutterLocalNotificationsPlugin _notifications =
      FlutterLocalNotificationsPlugin();

  // Guard against calling initialize() multiple times, which would
  // re-request permissions and reset internal plugin state unnecessarily.
  bool _initialized = false;

  Future<void> initialize() async {
    if (_initialized) return;

    // Must be called before any tz.TZDateTime conversions, otherwise
    // scheduled times will be wrong or throw a null lookup error.
    tz.initializeTimeZones();
    await _requestPermissions();

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

    try {
      final result = await _notifications.initialize(
        initSettings,
        onDidReceiveNotificationResponse: (details) {
        // payload is the event ID set when the notification was scheduled
        final eventId = details.payload;
        if (eventId == null || eventId.isEmpty) return;

        final context = navigatorKey.currentContext;
        if (context == null) return;

        final dataProvider =
            Provider.of<DataProvider>(context, listen: false);
        try {
          final event = dataProvider.events.firstWhere((e) => e.id == eventId);
          // Push the event detail dialog on top of whatever screen is open
          showDialog(
            context: navigatorKey.currentContext!,
            builder: (_) => EventActionDialog(event: event),
          );
        } catch (_) {
          // Event may have been deleted since the notification was scheduled
        }
      },
      );
      _initialized = result ?? false;
    } catch (e) {
      // Plugin failed to initialize (e.g. emulator with no notification support).
      // App continues normally — reminders just won't fire.
      _initialized = false;
    }
  }

  Future<void> _requestPermissions() async {
    try {
      if (await Permission.notification.isDenied) {
        await Permission.notification.request();
      }
    } catch (_) {}
    // scheduleExactAlarm is intentionally NOT requested here.
    // On some manufacturers (e.g. Xiaomi, Samsung with battery optimization)
    // requesting it at startup throws a SecurityException and crashes the app.
    // Instead, we attempt exact scheduling and silently fall back to inexact.
  }

  Future<void> scheduleNotification({
    required int id,
    required String title,
    required String body,
    required DateTime scheduledDate,
    String? payload, // event ID so tapping opens the correct event
  }) async {
    if (!_initialized) await initialize();
    if (!_initialized) return;

    if (scheduledDate.isBefore(DateTime.now())) return;

    const details = NotificationDetails(
      android: AndroidNotificationDetails(
        'classflow_reminders',
        'Event Reminders',
        channelDescription: 'Reminders for your events and tasks',
        importance: Importance.max, // max so it shows as a heads-up banner
        priority: Priority.high,
        playSound: true,
        enableVibration: true,
        styleInformation: BigTextStyleInformation(''), // allows long body text to expand
        icon: '@mipmap/ic_launcher',
      ),
      iOS: DarwinNotificationDetails(
        presentAlert: true,
        presentBadge: true,
        presentSound: true,
        threadIdentifier: 'classflow_events',
      ),
    );

    final tzDate = tz.TZDateTime.from(scheduledDate, tz.local);

    try {
      await _notifications.zonedSchedule(
        id,
        title,
        body,
        tzDate,
        details,
        payload: payload, // passed through to onDidReceiveNotificationResponse
        androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
        uiLocalNotificationDateInterpretation:
            UILocalNotificationDateInterpretation.absoluteTime,
      );
    } catch (_) {
      try {
        await _notifications.zonedSchedule(
          id,
          title,
          body,
          tzDate,
          details,
          payload: payload,
          androidScheduleMode: AndroidScheduleMode.inexactAllowWhileIdle,
          uiLocalNotificationDateInterpretation:
              UILocalNotificationDateInterpretation.absoluteTime,
        );
      } catch (_) {}
    }
  }

  Future<void> cancelNotification(int id) async {
    try {
      await _notifications.cancel(id);
    } catch (_) {}
  }

  Future<void> cancelAllNotifications() async {
    try {
      await _notifications.cancelAll();
    } catch (_) {}
  }
}