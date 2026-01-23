import 'package:flutter_local_notifications/flutter_local_notifications.dart';
// tz package is required by flutter_local_notifications for zonedSchedule
import 'package:timezone/data/latest_all.dart' as tzdata;
import 'package:timezone/timezone.dart' as tz;

class LocalNotificationService {
  static final FlutterLocalNotificationsPlugin _plugin = FlutterLocalNotificationsPlugin();
  static bool _initialized = false;

  static Future<void> init() async {
    if (_initialized) return;

    const androidInit = AndroidInitializationSettings('@mipmap/ic_launcher');
    const iosInit = IOSInitializationSettings();
    const initSettings = InitializationSettings(android: androidInit, iOS: iosInit);

    await _plugin.initialize(initSettings);
    _initialized = true;
  }

  static Future<void> scheduleNotification({
    required int id,
    required String title,
    required String body,
    required DateTime scheduledDate,
    String? payload,
  }) async {
    await init();

    const androidDetails = AndroidNotificationDetails(
      'mbaymi_reminders',
      'Rappels agricoles',
      'Rappels pour semis, traitements et récoltes',
      importance: Importance.max,
      priority: Priority.high,
      playSound: true,
    );

    const iosDetails = IOSNotificationDetails();

    final details = NotificationDetails(android: androidDetails, iOS: iosDetails);

    await _plugin.zonedSchedule(
      id,
      title,
      body,
      // Convert to tz-aware time using local timezone
      tz.TZDateTime.from(scheduledDate, tz.local),
      details,
      androidAllowWhileIdle: true,
      uiLocalNotificationDateInterpretation: UILocalNotificationDateInterpretation.absoluteTime,
      payload: payload,
    );
  }

  static Future<void> cancelNotification(int id) async {
    await _plugin.cancel(id);
  }
}
Future<void> initTimezone() async {
  tzdata.initializeTimeZones();
  try {
    tz.setLocalLocation(tz.getLocation(DateTime.now().timeZoneName));
  } catch (_) {
    // Fallback to a known TZ database name if local lookup fails
    try {
      tz.setLocalLocation(tz.getLocation('Etc/UTC'));
    } catch (__){
      // As a last resort, set to the system local (may still throw in some environments)
      tz.setLocalLocation(tz.getLocation(DateTime.now().timeZoneName));
    }
  }
}
