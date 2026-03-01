import 'package:flutter/material.dart';
import '../models/word_model.dart';
import '../services/notification_service.dart';

/// Provider exposing notification/reminder settings to the UI.
class NotificationProvider extends ChangeNotifier {
  final NotificationService _service;

  bool _reminderEnabled = false;
  int _reminderHour = 20;
  int _reminderMinute = 0;
  bool _permissionGranted = false;
  bool _isLoading = false;

  // Word of the Day fields
  bool _wotdEnabled = false;
  int _wotdHour = 9;
  int _wotdMinute = 0;

  bool get reminderEnabled => _reminderEnabled;
  int get reminderHour => _reminderHour;
  int get reminderMinute => _reminderMinute;
  bool get permissionGranted => _permissionGranted;
  bool get isLoading => _isLoading;

  bool get wotdEnabled => _wotdEnabled;
  int get wotdHour => _wotdHour;
  int get wotdMinute => _wotdMinute;
  TimeOfDay get wotdTime => TimeOfDay(hour: _wotdHour, minute: _wotdMinute);

  TimeOfDay get reminderTime =>
      TimeOfDay(hour: _reminderHour, minute: _reminderMinute);

  NotificationProvider(this._service);

  /// Load persisted settings.
  Future<void> init() async {
    _isLoading = true;
    notifyListeners();

    final settings = await _service.getReminderSettings();
    _reminderEnabled = settings.enabled;
    _reminderHour = settings.hour;
    _reminderMinute = settings.minute;

    final wotd = await _service.getWotdSettings();
    _wotdEnabled = wotd.enabled;
    _wotdHour = wotd.hour;
    _wotdMinute = wotd.minute;

    _permissionGranted = await _service.requestPermission();

    _isLoading = false;
    notifyListeners();
  }

  /// Enable the daily reminder at the specified time.
  Future<void> enableReminder({required int hour, required int minute}) async {
    if (!_permissionGranted) {
      _permissionGranted = await _service.requestPermission();
      if (!_permissionGranted) return;
    }

    await _service.scheduleDailyReminder(hour: hour, minute: minute);
    _reminderEnabled = true;
    _reminderHour = hour;
    _reminderMinute = minute;
    notifyListeners();
  }

  /// Disable the daily reminder.
  Future<void> disableReminder() async {
    await _service.cancelDailyReminder();
    _reminderEnabled = false;
    notifyListeners();
  }

  /// Toggle reminder on/off.
  Future<void> toggleReminder() async {
    if (_reminderEnabled) {
      await disableReminder();
    } else {
      await enableReminder(hour: _reminderHour, minute: _reminderMinute);
    }
  }

  /// Update the reminder time.
  Future<void> setReminderTime(TimeOfDay time) async {
    _reminderHour = time.hour;
    _reminderMinute = time.minute;
    if (_reminderEnabled) {
      await enableReminder(hour: time.hour, minute: time.minute);
    }
    notifyListeners();
  }

  // ── Word of the Day ─────────────────────────────────────────────

  /// Enable Word of the Day notification at the specified time.
  Future<void> enableWotd({
    required int hour,
    required int minute,
    required List<WordModel> words,
  }) async {
    if (!_permissionGranted) {
      _permissionGranted = await _service.requestPermission();
      if (!_permissionGranted) return;
    }

    await _service.scheduleWordOfTheDay(
      hour: hour,
      minute: minute,
      words: words,
    );
    _wotdEnabled = true;
    _wotdHour = hour;
    _wotdMinute = minute;
    notifyListeners();
  }

  /// Disable Word of the Day notification.
  Future<void> disableWotd() async {
    await _service.cancelWordOfTheDay();
    _wotdEnabled = false;
    notifyListeners();
  }

  /// Toggle Word of the Day on/off.
  Future<void> toggleWotd(List<WordModel> words) async {
    if (_wotdEnabled) {
      await disableWotd();
    } else {
      await enableWotd(hour: _wotdHour, minute: _wotdMinute, words: words);
    }
  }

  /// Update the Word of the Day notification time.
  Future<void> setWotdTime(TimeOfDay time, List<WordModel> words) async {
    _wotdHour = time.hour;
    _wotdMinute = time.minute;
    if (_wotdEnabled) {
      await enableWotd(hour: time.hour, minute: time.minute, words: words);
    }
    notifyListeners();
  }
}
