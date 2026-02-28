import 'package:flutter/material.dart';
import '../services/notification_service.dart';

/// Provider exposing notification/reminder settings to the UI.
class NotificationProvider extends ChangeNotifier {
  final NotificationService _service;

  bool _reminderEnabled = false;
  int _reminderHour = 20;
  int _reminderMinute = 0;
  bool _permissionGranted = false;
  bool _isLoading = false;

  bool get reminderEnabled => _reminderEnabled;
  int get reminderHour => _reminderHour;
  int get reminderMinute => _reminderMinute;
  bool get permissionGranted => _permissionGranted;
  bool get isLoading => _isLoading;

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
}
