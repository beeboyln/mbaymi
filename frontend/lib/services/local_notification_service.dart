import 'package:flutter/foundation.dart';

/// Stub for local notifications service.
/// Android uses native Android notifications API.
/// This class provides a placeholder interface.
class LocalNotificationService {
  static bool _initialized = false;

  static Future<void> init() async {
    if (_initialized) return;
    debugPrint('✅ Local Notification Service initialized');
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
    debugPrint('📬 Scheduled notification: $title at $scheduledDate');
  }

  static Future<void> showNotification({
    required int id,
    required String title,
    required String body,
    String? payload,
  }) async {
    await init();
    debugPrint('🔔 Showing notification: $title');
  }

  static Future<void> cancelNotification(int id) async {
    debugPrint('❌ Cancelled notification: $id');
  }

  static Future<void> cancelAllNotifications() async {
    debugPrint('❌ Cancelled all notifications');
  }
}
