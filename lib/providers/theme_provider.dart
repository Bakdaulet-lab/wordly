import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Supported theme modes that the user can select.
enum AppThemeMode { system, light, dark }

/// Provider for app-wide theme management and speech rate.
///
/// Persists the user's choices to [SharedPreferences] and exposes
/// the resolved [ThemeMode] for [MaterialApp.router].
class ThemeProvider extends ChangeNotifier {
  static const String _prefKey = 'app_theme_mode';
  static const String _speechRatePrefKey = 'tts_speech_rate';

  AppThemeMode _themeMode = AppThemeMode.system;
  double _speechRate = 0.45;
  bool _initialized = false;

  AppThemeMode get themeMode => _themeMode;
  bool get initialized => _initialized;

  /// Current TTS speech rate (range 0.1 – 1.0).
  double get speechRate => _speechRate;

  /// Resolved Flutter [ThemeMode] used by MaterialApp.
  ThemeMode get resolvedThemeMode => switch (_themeMode) {
        AppThemeMode.system => ThemeMode.system,
        AppThemeMode.light => ThemeMode.light,
        AppThemeMode.dark => ThemeMode.dark,
      };

  /// Initialize from persisted preference.
  Future<void> init() async {
    final prefs = await SharedPreferences.getInstance();
    final stored = prefs.getString(_prefKey);
    if (stored != null) {
      _themeMode = AppThemeMode.values.firstWhere(
        (e) => e.name == stored,
        orElse: () => AppThemeMode.system,
      );
    }
    final storedRate = prefs.getDouble(_speechRatePrefKey);
    if (storedRate != null) {
      _speechRate = storedRate.clamp(0.1, 1.0);
    }
    _initialized = true;
    notifyListeners();
  }

  /// Change theme and persist.
  Future<void> setThemeMode(AppThemeMode mode) async {
    if (_themeMode == mode) return;
    _themeMode = mode;
    notifyListeners();

    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_prefKey, mode.name);
  }

  /// Change TTS speech rate and persist.
  Future<void> setSpeechRate(double rate) async {
    final clamped = rate.clamp(0.1, 1.0);
    if ((_speechRate - clamped).abs() < 0.01) return;
    _speechRate = clamped;
    notifyListeners();

    final prefs = await SharedPreferences.getInstance();
    await prefs.setDouble(_speechRatePrefKey, clamped);
  }

  /// Check if current resolved brightness is dark.
  bool isDark(BuildContext context) {
    if (_themeMode == AppThemeMode.dark) return true;
    if (_themeMode == AppThemeMode.light) return false;
    return MediaQuery.platformBrightnessOf(context) == Brightness.dark;
  }
}
