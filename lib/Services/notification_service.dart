import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:timezone/timezone.dart' as tz;
import 'package:timezone/data/latest.dart' as tzdata;

class NotificationService {
  static final FlutterLocalNotificationsPlugin _plugin =
      FlutterLocalNotificationsPlugin();

  static const int _clearReminderId = 9001;

  // Must match the keys used in NotificationsPage.
  static const _kGeneral      = 'notif_general';
  static const _kSound        = 'notif_sound';
  static const _kDnd          = 'notif_dnd';
  static const _kVibrate      = 'notif_vibrate';
  static const _kDataReminder = 'notif_data_reminder';

  /// Call once in main() before runApp().
  static Future<void> init() async {
    tzdata.initializeTimeZones();
    tz.setLocalLocation(tz.getLocation('Asia/Karachi'));

    const androidSettings =
        AndroidInitializationSettings('@mipmap/ic_launcher');
    const iosSettings = DarwinInitializationSettings(
      requestAlertPermission: true,
      requestBadgePermission: true,
      requestSoundPermission: true,
    );

    await _plugin.initialize(
      const InitializationSettings(
        android: androidSettings,
        iOS: iosSettings,
      ),
    );

    // Permission is actually requested from the Notifications settings page
    // when the user flips "General Notification" on — this call just makes
    // sure the channel/plugin is ready, it doesn't itself prompt anything
    // extra on top of what permission_handler already asked for.
    await _plugin
        .resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin>()
        ?.requestNotificationsPermission();
  }

  /// Schedules (or reschedules) a single reminder for [clearDate] at 9 AM
  /// local time, telling the user their oldest activity data is about to
  /// be cleared. Safe to call every time the history page loads — it
  /// always cancels any previous reminder first.
  ///
  /// Respects the user's settings from the Notifications page:
  /// - Does nothing if General Notification or Data Backup Reminder is off
  /// - Sound follows the Sound toggle (muted automatically if DND is on)
  /// - Vibration follows the Vibrate toggle
  static Future<void> scheduleClearReminder(DateTime clearDate) async {
    try {
      await _plugin.cancel(_clearReminderId);

      final prefs = await SharedPreferences.getInstance();
      final generalOn = prefs.getBool(_kGeneral) ?? false;
      final dataReminderOn = prefs.getBool(_kDataReminder) ?? false;

      if (!generalOn || !dataReminderOn) {
        debugPrint('[NOTIF] Clear reminder skipped — disabled in settings');
        return;
      }

      final dndOn = prefs.getBool(_kDnd) ?? false;
      final soundOn = (prefs.getBool(_kSound) ?? false) && !dndOn;
      final vibrateOn = prefs.getBool(_kVibrate) ?? false;

      // final now = tz.TZDateTime.now(tz.local);
      // final scheduled = now.add(const Duration(minutes: 2)); ---------------------------------// TEST ONLY

      final now = tz.TZDateTime.now(tz.local);
      final scheduled = tz.TZDateTime(
        tz.local,
        clearDate.year,
        clearDate.month,
        clearDate.day,
        9, 0, // 9:00 AM on the clear date
      );

      // Don't schedule a notification in the past.
      if (scheduled.isBefore(now)) return;

      final androidDetails = AndroidNotificationDetails(
        'data_retention_channel',
        'Data Retention Reminders',
        channelDescription:
            'Reminds you before your oldest activity history is cleared.',
        importance: Importance.high,
        priority: Priority.high,
        playSound: soundOn,
        enableVibration: vibrateOn,
      );
      final iosDetails = DarwinNotificationDetails(
        presentAlert: true,
        presentBadge: true,
        presentSound: soundOn,
      );

      await _plugin.zonedSchedule(
        _clearReminderId,
        'Your activity data clears today 💛',
        'Open Get Fit and download your history as a PDF before it\'s gone for good.',
        scheduled,
        NotificationDetails(android: androidDetails, iOS: iosDetails),
        androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
        uiLocalNotificationDateInterpretation:
            UILocalNotificationDateInterpretation.absoluteTime,
      );

      debugPrint('[NOTIF] Clear reminder scheduled for $scheduled');
    } catch (e) {
      debugPrint('[NOTIF] ERROR | scheduleClearReminder | $e');
    }
  }

  static Future<void> cancelClearReminder() async {
    await _plugin.cancel(_clearReminderId);
  }
}