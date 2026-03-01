import 'dart:math';

import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/timezone.dart' as tz;
import 'package:timezone/data/latest_all.dart' as tz_data;
import 'package:shared_preferences/shared_preferences.dart';
import '../services/logger_service.dart';
import '../models/word_model.dart';

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
  static const String _prefWotdEnabled = 'notification_wotd_enabled';
  static const String _prefWotdHour = 'notification_wotd_hour';
  static const String _prefWotdMinute = 'notification_wotd_minute';

  static const int _dailyReminderId = 1000;
  static const int _streakWarningId = 1001;
  static const int _reviewDueId = 1002;
  static const int _wordOfTheDayId = 1003;

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
    AppLogger.info('Initialized', tag: 'NotificationService');
  }

  void _onNotificationTap(NotificationResponse response) {
    AppLogger.debug('Tapped: ${response.payload}', tag: 'NotificationService');
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

    AppLogger.info('Daily reminder set for $hour:$minute', tag: 'NotificationService');
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

  // ── Word of the Day ─────────────────────────────────────────────

  static const AndroidNotificationDetails _wotdChannel =
      AndroidNotificationDetails(
    'word_of_the_day',
    'Word of the Day',
    channelDescription: 'Daily word of the day notifications',
    importance: Importance.high,
    priority: Priority.high,
    icon: '@mipmap/ic_launcher',
  );

  /// Schedule a daily "Word of the Day" notification at the given time.
  ///
  /// Picks a random word from [words] using the current date as seed (same word
  /// the dashboard shows) and schedules it as a recurring daily notification.
  /// If [words] is empty the call is a no-op.
  Future<void> scheduleWordOfTheDay({
    required int hour,
    required int minute,
    required List<WordModel> words,
  }) async {
    if (kIsWeb || words.isEmpty) return;

    await cancelWordOfTheDay();

    // Deterministic pick identical to the dashboard card
    final now = DateTime.now();
    final daySeed = now.year * 10000 + now.month * 100 + now.day;
    final index = Random(daySeed).nextInt(words.length);
    final word = words[index];

    final tzNow = tz.TZDateTime.now(tz.local);
    var scheduledDate = tz.TZDateTime(
      tz.local,
      tzNow.year,
      tzNow.month,
      tzNow.day,
      hour,
      minute,
    );
    if (scheduledDate.isBefore(tzNow)) {
      scheduledDate = scheduledDate.add(const Duration(days: 1));
    }

    await _plugin.zonedSchedule(
      _wordOfTheDayId,
      '🌟 Word of the Day: ${word.englishWord}',
      '${word.russianTranslation} — Tap to learn more!',
      scheduledDate,
      const NotificationDetails(
        android: _wotdChannel,
        iOS: DarwinNotificationDetails(),
      ),
      androidScheduleMode: AndroidScheduleMode.inexactAllowWhileIdle,
      uiLocalNotificationDateInterpretation:
          UILocalNotificationDateInterpretation.absoluteTime,
      matchDateTimeComponents: DateTimeComponents.time,
      payload: 'word_of_the_day:${word.id}',
    );

    // Persist preference
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_prefWotdEnabled, true);
    await prefs.setInt(_prefWotdHour, hour);
    await prefs.setInt(_prefWotdMinute, minute);

    AppLogger.info(
      'Word of the Day scheduled at $hour:$minute — "${word.englishWord}"',
      tag: 'NotificationService',
    );
  }

  /// Cancel the Word of the Day notification.
  Future<void> cancelWordOfTheDay() async {
    await _plugin.cancel(_wordOfTheDayId);
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_prefWotdEnabled, false);
  }

  /// Restore the word-of-the-day notification on app startup.
  Future<void> restoreWordOfTheDay(List<WordModel> words) async {
    final prefs = await SharedPreferences.getInstance();
    final enabled = prefs.getBool(_prefWotdEnabled) ?? false;
    if (!enabled) return;

    final hour = prefs.getInt(_prefWotdHour) ?? 9;
    final minute = prefs.getInt(_prefWotdMinute) ?? 0;
    await scheduleWordOfTheDay(hour: hour, minute: minute, words: words);
  }

  /// Get current Word of the Day notification settings.
  Future<WotdSettings> getWotdSettings() async {
    final prefs = await SharedPreferences.getInstance();
    return WotdSettings(
      enabled: prefs.getBool(_prefWotdEnabled) ?? false,
      hour: prefs.getInt(_prefWotdHour) ?? 9,
      minute: prefs.getInt(_prefWotdMinute) ?? 0,
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

/// Simple value object for Word of the Day notification settings.
class WotdSettings {
  final bool enabled;
  final int hour;
  final int minute;

  const WotdSettings({
    required this.enabled,
    required this.hour,
    required this.minute,
  });
}
