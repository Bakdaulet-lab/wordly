import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:wordly/providers/theme_provider.dart';
import 'package:flutter/material.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('ThemeProvider', () {
    late ThemeProvider provider;

    setUp(() {
      SharedPreferences.setMockInitialValues({});
      provider = ThemeProvider();
    });

    test('default theme mode is system', () {
      expect(provider.themeMode, equals(AppThemeMode.system));
    });

    test('resolvedThemeMode maps correctly', () {
      expect(provider.resolvedThemeMode, equals(ThemeMode.system));
    });

    test('setThemeMode changes to light', () async {
      await provider.setThemeMode(AppThemeMode.light);
      expect(provider.themeMode, equals(AppThemeMode.light));
      expect(provider.resolvedThemeMode, equals(ThemeMode.light));
    });

    test('setThemeMode changes to dark', () async {
      await provider.setThemeMode(AppThemeMode.dark);
      expect(provider.themeMode, equals(AppThemeMode.dark));
      expect(provider.resolvedThemeMode, equals(ThemeMode.dark));
    });

    test('setThemeMode same value does not notify', () async {
      int notifyCount = 0;
      provider.addListener(() => notifyCount++);
      await provider.setThemeMode(AppThemeMode.system);
      expect(notifyCount, equals(0));
    });

    test('setThemeMode different value notifies', () async {
      int notifyCount = 0;
      provider.addListener(() => notifyCount++);
      await provider.setThemeMode(AppThemeMode.dark);
      expect(notifyCount, equals(1));
    });

    test('setThemeMode persists to SharedPreferences', () async {
      await provider.setThemeMode(AppThemeMode.dark);
      final prefs = await SharedPreferences.getInstance();
      expect(prefs.getString('app_theme_mode'), equals('dark'));
    });

    test('init loads persisted theme mode', () async {
      SharedPreferences.setMockInitialValues({'app_theme_mode': 'light'});
      final p = ThemeProvider();
      await p.init();
      expect(p.themeMode, equals(AppThemeMode.light));
      expect(p.initialized, isTrue);
    });

    test('init defaults to system for unknown value', () async {
      SharedPreferences.setMockInitialValues({'app_theme_mode': 'unknown'});
      final p = ThemeProvider();
      await p.init();
      expect(p.themeMode, equals(AppThemeMode.system));
    });
  });

  group('AppThemeMode enum', () {
    test('has three values', () {
      expect(AppThemeMode.values.length, equals(3));
    });

    test('values are system, light, dark', () {
      expect(AppThemeMode.values,
          containsAll([AppThemeMode.system, AppThemeMode.light, AppThemeMode.dark]),);
    });
  });
}
