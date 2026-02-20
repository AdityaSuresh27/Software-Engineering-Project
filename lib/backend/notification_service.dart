// notification_service.dart
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/timezone.dart' as tz;
import 'package:timezone/data/latest_all.dart' as tz;
import 'package:permission_handler/permission_handler.dart';

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
          // payload could be used here in future to deep-link to a specific event
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
  }) async {
    if (!_initialized) await initialize();
    if (!_initialized) return;

    // Skip silently — past reminders are filtered out in the UI already,
    // but this is a safety net in case of clock drift or delayed saves.
    if (scheduledDate.isBefore(DateTime.now())) return;

    const details = NotificationDetails(
      android: AndroidNotificationDetails(
        'classflow_reminders',
        'Event Reminders',
        channelDescription: 'Reminders for your events and tasks',
        importance: Importance.high,
        priority: Priority.high,
        playSound: true,
        enableVibration: true,
      ),
      iOS: DarwinNotificationDetails(
        presentAlert: true,
        presentBadge: true,
        presentSound: true,
      ),
    );

    // Convert to timezone-aware datetime so notifications fire correctly
    // even if the user travels to a different timezone after scheduling.
    final tzDate = tz.TZDateTime.from(scheduledDate, tz.local);

    try {
      // Preferred: exact alarm wakes the device even in Doze mode.
      // Requires SCHEDULE_EXACT_ALARM permission on Android 12+.
      await _notifications.zonedSchedule(
        id,
        title,
        body,
        tzDate,
        details,
        androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
        uiLocalNotificationDateInterpretation:
            UILocalNotificationDateInterpretation.absoluteTime,
      );
    } catch (_) {
      try {
        // Fallback: inexact alarm — Android may delay this by up to 15 minutes
        // depending on battery optimization settings, but it will still fire.
        await _notifications.zonedSchedule(
          id,
          title,
          body,
          tzDate,
          details,
          androidScheduleMode: AndroidScheduleMode.inexactAllowWhileIdle,
          uiLocalNotificationDateInterpretation:
              UILocalNotificationDateInterpretation.absoluteTime,
        );
      } catch (_) {
        // Device has notifications fully disabled or in an unsupported environment.
        // Fail silently — the user will still see reminders inside the app.
      }
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