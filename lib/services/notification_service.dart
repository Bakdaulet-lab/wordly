import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/timezone.dart' as tz;
import 'package:timezone/data/latest_all.dart' as tz_data;
import 'package:shared_preferences/shared_preferences.dart';

/// Service for scheduling and managing local push notifications.
///
/// Supports:
/// - Daily study reminders at a configurable time
/// - Streak-at-risk warnings
/// - Review-due nudges
/// - Achievement unlock celebrations
class NotificationService {
  static const String _prefReminderEnabled = 'notification_reminder_enabled';
  static const String _prefReminderHour = 'notification_reminder_hour';
  static const String _prefReminderMinute = 'notification_reminder_minute';

  static const int _dailyReminderId = 1000;
  static const int _streakWarningId = 1001;
  static const int _reviewDueId = 1002;

  final FlutterLocalNotificationsPlugin _plugin =
      FlutterLocalNotificationsPlugin();

  bool _initialized = false;

  bool get isInitialized => _initialized;

  /// Initialise the notification plugin and timezone database.
  Future<void> init() async {
    if (_initialized) return;
    if (kIsWeb) {
      _initialized = true;
      return; // Notifications not supported on web
    }

    tz_data.initializeTimeZones();

    const androidSettings =
        AndroidInitializationSettings('@mipmap/ic_launcher');
    const iosSettings = DarwinInitializationSettings(
      requestAlertPermission: true,
      requestBadgePermission: true,
      requestSoundPermission: true,
    );
    const settings = InitializationSettings(
      android: androidSettings,
      iOS: iosSettings,
    );

    await _plugin.initialize(
      settings,
      onDidReceiveNotificationResponse: _onNotificationTap,
    );

    _initialized = true;
    debugPrint('[NotificationService] Initialized');
  }

  void _onNotificationTap(NotificationResponse response) {
    debugPrint('[NotificationService] Tapped: ${response.payload}');
    // Navigation can be handled via a callback or event bus.
  }

  // ── Channel definitions ────────────────────────────────────────────

  static const AndroidNotificationDetails _reminderChannel =
      AndroidNotificationDetails(
    'daily_reminder',
    'Daily Reminders',
    channelDescription: 'Daily study reminder notifications',
    importance: Importance.high,
    priority: Priority.high,
    icon: '@mipmap/ic_launcher',
  );

  static const AndroidNotificationDetails _achievementChannel =
      AndroidNotificationDetails(
    'achievements',
    'Achievements',
    channelDescription: 'Achievement unlock notifications',
    importance: Importance.defaultImportance,
    priority: Priority.defaultPriority,
    icon: '@mipmap/ic_launcher',
  );

  // ── Daily study reminder ───────────────────────────────────────────

  /// Schedule a daily recurring reminder at the specified time.
  Future<void> scheduleDailyReminder({
    required int hour,
    required int minute,
  }) async {
    if (kIsWeb) return;
    await cancelDailyReminder();

    final now = tz.TZDateTime.now(tz.local);
    var scheduledDate = tz.TZDateTime(
      tz.local,
      now.year,
      now.month,
      now.day,
      hour,
      minute,
    );

    // If the time has already passed today, schedule for tomorrow
    if (scheduledDate.isBefore(now)) {
      scheduledDate = scheduledDate.add(const Duration(days: 1));
    }

    await _plugin.zonedSchedule(
      _dailyReminderId,
      'Time to learn! 📚',
      'Keep your streak going — practice a few words today.',
      scheduledDate,
      const NotificationDetails(
        android: _reminderChannel,
        iOS: DarwinNotificationDetails(),
      ),
      androidScheduleMode: AndroidScheduleMode.inexactAllowWhileIdle,
      uiLocalNotificationDateInterpretation: UILocalNotificationDateInterpretation.absoluteTime,
      matchDateTimeComponents: DateTimeComponents.time,
      payload: 'daily_reminder',
    );

    // Persist preference
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_prefReminderEnabled, true);
    await prefs.setInt(_prefReminderHour, hour);
    await prefs.setInt(_prefReminderMinute, minute);

    debugPrint('[NotificationService] Daily reminder set for $hour:$minute');
  }

  Future<void> cancelDailyReminder() async {
    await _plugin.cancel(_dailyReminderId);
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_prefReminderEnabled, false);
  }

  /// Restore the previously-scheduled reminder (call on app startup).
  Future<void> restoreReminder() async {
    final prefs = await SharedPreferences.getInstance();
    final enabled = prefs.getBool(_prefReminderEnabled) ?? false;
    if (!enabled) return;

    final hour = prefs.getInt(_prefReminderHour) ?? 20;
    final minute = prefs.getInt(_prefReminderMinute) ?? 0;
    await scheduleDailyReminder(hour: hour, minute: minute);
  }

  /// Get current reminder settings.
  Future<ReminderSettings> getReminderSettings() async {
    final prefs = await SharedPreferences.getInstance();
    return ReminderSettings(
      enabled: prefs.getBool(_prefReminderEnabled) ?? false,
      hour: prefs.getInt(_prefReminderHour) ?? 20,
      minute: prefs.getInt(_prefReminderMinute) ?? 0,
    );
  }

  // ── Streak-at-risk warning ─────────────────────────────────────────

  /// Schedule a "you'll lose your streak!" notification for tonight at 21:00.
  Future<void> scheduleStreakWarning({required int currentStreak}) async {
    if (currentStreak <= 0) return;

    await _plugin.cancel(_streakWarningId);

    final now = tz.TZDateTime.now(tz.local);
    final tonight = tz.TZDateTime(
      tz.local,
      now.year,
      now.month,
      now.day,
      21,
      0,
    );
    if (tonight.isBefore(now)) {
      // Already past 9 PM — skip
      return;
    }

    await _plugin.zonedSchedule(
      _streakWarningId,
      'Your $currentStreak-day streak is at risk! 🔥',
      'Open Wordly and complete a quick session to keep it going.',
      tonight,
      const NotificationDetails(
        android: _reminderChannel,
        iOS: DarwinNotificationDetails(),
      ),
      androidScheduleMode: AndroidScheduleMode.inexactAllowWhileIdle,
      uiLocalNotificationDateInterpretation: UILocalNotificationDateInterpretation.absoluteTime,
      payload: 'streak_warning',
    );
  }

  // ── Review-due nudge ───────────────────────────────────────────────

  /// Show a notification about words due for review.
  Future<void> showReviewDueNotification(int count) async {
    if (count <= 0) return;

    await _plugin.show(
      _reviewDueId,
      'You have $count word${count == 1 ? '' : 's'} to review 📝',
      'Spaced repetition works best when you review on time!',
      const NotificationDetails(
        android: _reminderChannel,
        iOS: DarwinNotificationDetails(),
      ),
      payload: 'review_due',
    );
  }

  // ── Achievement unlock ─────────────────────────────────────────────

  /// Show an immediate notification for an achievement unlock.
  Future<void> showAchievementNotification({
    required String achievementName,
    required String description,
  }) async {
    await _plugin.show(
      achievementName.hashCode, // unique per achievement
      '🏆 Achievement Unlocked!',
      '$achievementName — $description',
      const NotificationDetails(
        android: _achievementChannel,
        iOS: DarwinNotificationDetails(),
      ),
      payload: 'achievement:$achievementName',
    );
  }

  // ── Cancel all ─────────────────────────────────────────────────────

  Future<void> cancelAll() async {
    await _plugin.cancelAll();
  }

  /// Request notification permissions (iOS / Android 13+).
  Future<bool> requestPermission() async {
    final android = _plugin.resolvePlatformSpecificImplementation<
        AndroidFlutterLocalNotificationsPlugin>();
    if (android != null) {
      final granted = await android.requestNotificationsPermission();
      return granted ?? false;
    }
    // iOS permissions are requested during init.
    return true;
  }
}

/// Simple value object for reminder settings.
class ReminderSettings {
  final bool enabled;
  final int hour;
  final int minute;

  const ReminderSettings({
    required this.enabled,
    required this.hour,
    required this.minute,
  });
}
