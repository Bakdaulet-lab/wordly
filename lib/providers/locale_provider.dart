import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Provider for app locale management.
///
/// Persists the user's language choice to [SharedPreferences].
class LocaleProvider extends ChangeNotifier {
  static const String _prefKey = 'app_locale';

  Locale _locale = const Locale('en');
  bool _initialized = false;

  Locale get locale => _locale;
  bool get initialized => _initialized;

  /// Initialize from persisted preference.
  Future<void> init() async {
    final prefs = await SharedPreferences.getInstance();
    final stored = prefs.getString(_prefKey);
    if (stored != null && ['en', 'ru'].contains(stored)) {
      _locale = Locale(stored);
    }
    _initialized = true;
    notifyListeners();
  }

  /// Change locale and persist.
  Future<void> setLocale(Locale locale) async {
    if (_locale == locale) return;
    _locale = locale;
    notifyListeners();

    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_prefKey, locale.languageCode);
  }

  bool get isRussian => _locale.languageCode == 'ru';
  bool get isEnglish => _locale.languageCode == 'en';
}
