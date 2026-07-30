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
  static const _kReminder     = 'notif_reminder';

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
  static const int _bookingClearReminderId = 9002;

  static Future<void> scheduleBookingClearReminder(DateTime clearDate) async {
    try {
      await _plugin.cancel(_bookingClearReminderId);

      final prefs = await SharedPreferences.getInstance();
      final generalOn = prefs.getBool(_kGeneral) ?? false;
      final dataReminderOn = prefs.getBool(_kDataReminder) ?? false;

      if (!generalOn || !dataReminderOn) {
        debugPrint('[NOTIF] Booking clear reminder skipped — disabled in settings');
        return;
      }

      final dndOn = prefs.getBool(_kDnd) ?? false;
      final soundOn = (prefs.getBool(_kSound) ?? false) && !dndOn;
      final vibrateOn = prefs.getBool(_kVibrate) ?? false;

      final now = tz.TZDateTime.now(tz.local);
      final scheduled = tz.TZDateTime(
        tz.local,
        clearDate.year,
        clearDate.month,
        clearDate.day,
        9, 0,
      );

      if (scheduled.isBefore(now)) return;

      final androidDetails = AndroidNotificationDetails(
        'booking_retention_channel',
        'Booking Retention Reminders',
        channelDescription: 'Reminds you before your booking history is cleared.',
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
        _bookingClearReminderId,
        'Your booking history clears today 💛',
        'Open Get Fit and download your bookings as a PDF before it\'s cleared.',
        scheduled,
        NotificationDetails(android: androidDetails, iOS: iosDetails),
        androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
        uiLocalNotificationDateInterpretation:
            UILocalNotificationDateInterpretation.absoluteTime,
      );

      debugPrint('[NOTIF] Booking clear reminder scheduled for $scheduled');
    } catch (e) {
      debugPrint('[NOTIF] ERROR | scheduleBookingClearReminder | $e');
    }
  }

  // ─────────────────────────────────────────────
  // TEMPORARY TEST METHOD — fires a notification 2 minutes from now,
  // bypassing all settings checks (General/Reminder toggles) so you can
  // confirm vibration + notification delivery work on this device.
  // Remove this once you're done testing.
  // ─────────────────────────────────────────────
  static Future<void> scheduleTestReminder() async {
    const testId = 77777;
    await _plugin.cancel(testId);

    final scheduled = tz.TZDateTime.now(tz.local).add(const Duration(minutes: 2));

    final androidDetails = AndroidNotificationDetails(
      'appointment_reminder_channel',
      'Appointment Reminders',
      channelDescription: 'Reminders before your trainer appointments.',
      importance: Importance.high,
      priority: Priority.high,
      playSound: true,
      enableVibration: true,
    );
    const iosDetails = DarwinNotificationDetails(
      presentAlert: true,
      presentBadge: true,
      presentSound: true,
    );

    await _plugin.zonedSchedule(
      testId,
      'Test: Session with Aisha tomorrow',
      'Your session with Aisha is scheduled for Sun, Jul 5 at 9:00 AM.',
      scheduled,
      NotificationDetails(android: androidDetails, iOS: iosDetails),
      androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
      uiLocalNotificationDateInterpretation:
          UILocalNotificationDateInterpretation.absoluteTime,
    );

    debugPrint('[NOTIF] TEST reminder scheduled for $scheduled');
  }

  // ─────────────────────────────────────────────
  // TRAINER APPOINTMENT REMINDERS
  // 3 notifications per appointment: 1 day before, 2 hours before,
  // 5 minutes before the actual start time.
  // ─────────────────────────────────────────────

  /// Derives 3 stable, unique-per-appointment notification IDs.
  /// Kept well under 32-bit range and away from _clearReminderId (9001).
  static List<int> _appointmentNotifIds(String appointmentId) {
    final base = (appointmentId.hashCode.abs() % 900000) + 10000; // avoid collisions with 9001
    return [base + 1, base + 2, base + 3]; // 1-day, 2-hour, 5-minute
  }

  /// Schedules the 3 reminders for a trainer appointment.
  /// [startDateTime] must be the appointment's actual local start time.
  /// Safe to call again for the same appointment — always cancels old
  /// reminders for it first (e.g. if rescheduled).
  static Future<void> scheduleAppointmentReminders({
    required String appointmentId,
    required String trainerName,
    required DateTime startDateTime,
  }) async {
    try {
      final ids = _appointmentNotifIds(appointmentId);
      await _plugin.cancel(ids[0]);
      await _plugin.cancel(ids[1]);
      await _plugin.cancel(ids[2]);

      final prefs = await SharedPreferences.getInstance();
      final generalOn = prefs.getBool(_kGeneral) ?? false;
      final reminderOn = prefs.getBool(_kReminder) ?? false;

      if (!generalOn || !reminderOn) {
        debugPrint('[NOTIF] Appointment reminders skipped — disabled in settings');
        return;
      }

      final dndOn = prefs.getBool(_kDnd) ?? false;
      final soundOn = (prefs.getBool(_kSound) ?? false) && !dndOn;
      final vibrateOn = prefs.getBool(_kVibrate) ?? false;

      final start = tz.TZDateTime(
        tz.local,
        startDateTime.year,
        startDateTime.month,
        startDateTime.day,
        startDateTime.hour,
        startDateTime.minute,
      );
      final now = tz.TZDateTime.now(tz.local);

      final stages = [
        (id: ids[0], offset: const Duration(days: 1),
          title: 'Upcoming session tomorrow',
          body: 'Your session with $trainerName is tomorrow at ${_fmtTime(start)}.'),
        (id: ids[1], offset: const Duration(hours: 2),
          title: 'Session in 2 hours',
          body: 'Your session with $trainerName starts in 2 hours.'),
        (id: ids[2], offset: const Duration(minutes: 5),
          title: 'Session starting soon',
          body: 'Your session with $trainerName starts in 5 minutes.'),
      ];

      final androidDetails = AndroidNotificationDetails(
        'appointment_reminder_channel',
        'Appointment Reminders',
        channelDescription: 'Reminders before your trainer appointments.',
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
      final details = NotificationDetails(android: androidDetails, iOS: iosDetails);

      for (final stage in stages) {
        final scheduled = start.subtract(stage.offset);
        if (scheduled.isBefore(now)) continue; // don't schedule in the past
        await _plugin.zonedSchedule(
          stage.id,
          stage.title,
          stage.body,
          scheduled,
          details,
          androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
          uiLocalNotificationDateInterpretation:
              UILocalNotificationDateInterpretation.absoluteTime,
        );
        debugPrint('[NOTIF] Appointment reminder (${stage.title}) scheduled for $scheduled');
      }
    } catch (e) {
      debugPrint('[NOTIF] ERROR | scheduleAppointmentReminders | $e');
    }
  }

  static Future<void> cancelAppointmentReminders(String appointmentId) async {
    final ids = _appointmentNotifIds(appointmentId);
    await _plugin.cancel(ids[0]);
    await _plugin.cancel(ids[1]);
    await _plugin.cancel(ids[2]);
  }

  static String _fmtTime(tz.TZDateTime t) {
    final h = t.hour % 12 == 0 ? 12 : t.hour % 12;
    final period = t.hour >= 12 ? 'PM' : 'AM';
    final m = t.minute.toString().padLeft(2, '0');
    return '$h:$m $period';
  }
}