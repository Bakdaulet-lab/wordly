import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:wordly/constants/app_theme.dart';

void main() {
  group('AppTheme', () {
    group('lightTheme', () {
      test('has light brightness', () {
        final theme = AppTheme.lightTheme;
        expect(theme.brightness, equals(Brightness.light));
      });

      test('uses Material3', () {
        final theme = AppTheme.lightTheme;
        expect(theme.useMaterial3, isTrue);
      });

      test('has correct scaffold background', () {
        final theme = AppTheme.lightTheme;
        expect(theme.scaffoldBackgroundColor, equals(const Color(0xFFF5F5FA)));
      });

      test('appBar has light surface color', () {
        final theme = AppTheme.lightTheme;
        expect(theme.appBarTheme.backgroundColor, equals(const Color(0xFFFFFFFF)));
      });

      test('card has white color', () {
        final theme = AppTheme.lightTheme;
        expect(theme.cardTheme.color, equals(const Color(0xFFFFFFFF)));
      });

      test('card has non-zero elevation in light mode', () {
        final theme = AppTheme.lightTheme;
        expect(theme.cardTheme.elevation, equals(1));
      });

      test('elevated button has primary background', () {
        final theme = AppTheme.lightTheme;
        final style = theme.elevatedButtonTheme.style!;
        final bgColor = style.backgroundColor!.resolve({});
        expect(bgColor, equals(const Color(0xFF6C63FF)));
      });

      test('bottom nav selected color is primary', () {
        final theme = AppTheme.lightTheme;
        expect(theme.bottomNavigationBarTheme.selectedItemColor,
            equals(const Color(0xFF6C63FF)),);
      });
    });

    group('darkTheme', () {
      test('has dark brightness', () {
        final theme = AppTheme.darkTheme;
        expect(theme.brightness, equals(Brightness.dark));
      });

      test('uses Material3', () {
        final theme = AppTheme.darkTheme;
        expect(theme.useMaterial3, isTrue);
      });

      test('has correct scaffold background', () {
        final theme = AppTheme.darkTheme;
        expect(theme.scaffoldBackgroundColor, equals(const Color(0xFF121218)));
      });

      test('appBar has dark surface color', () {
        final theme = AppTheme.darkTheme;
        expect(theme.appBarTheme.backgroundColor, equals(const Color(0xFF1E1E2C)));
      });

      test('card has dark color', () {
        final theme = AppTheme.darkTheme;
        expect(theme.cardTheme.color, equals(const Color(0xFF252538)));
      });

      test('card has zero elevation in dark mode', () {
        final theme = AppTheme.darkTheme;
        expect(theme.cardTheme.elevation, equals(0));
      });

      test('bottom nav selected color is dark primary', () {
        final theme = AppTheme.darkTheme;
        expect(theme.bottomNavigationBarTheme.selectedItemColor,
            equals(const Color(0xFF9D97FF)),);
      });
    });

    group('context-aware helpers with light theme', () {
      testWidgets('primary returns light primary in light mode', (tester) async {
        late Color result;
        await tester.pumpWidget(
          MaterialApp(
            theme: AppTheme.lightTheme,
            home: Builder(
              builder: (context) {
                result = AppTheme.primary(context);
                return const SizedBox();
              },
            ),
          ),
        );
        expect(result, equals(const Color(0xFF6C63FF)));
      });

      testWidgets('background returns light background', (tester) async {
        late Color result;
        await tester.pumpWidget(
          MaterialApp(
            theme: AppTheme.lightTheme,
            home: Builder(
              builder: (context) {
                result = AppTheme.background(context);
                return const SizedBox();
              },
            ),
          ),
        );
        expect(result, equals(const Color(0xFFF5F5FA)));
      });

      testWidgets('textPrimary returns light text color', (tester) async {
        late Color result;
        await tester.pumpWidget(
          MaterialApp(
            theme: AppTheme.lightTheme,
            home: Builder(
              builder: (context) {
                result = AppTheme.textPrimary(context);
                return const SizedBox();
              },
            ),
          ),
        );
        expect(result, equals(const Color(0xFF1A1A2E)));
      });
    });

    group('context-aware helpers with dark theme', () {
      testWidgets('primary returns dark primary in dark mode', (tester) async {
        late Color result;
        await tester.pumpWidget(
          MaterialApp(
            theme: AppTheme.darkTheme,
            themeMode: ThemeMode.dark,
            darkTheme: AppTheme.darkTheme,
            home: Builder(
              builder: (context) {
                result = AppTheme.primary(context);
                return const SizedBox();
              },
            ),
          ),
        );
        expect(result, equals(const Color(0xFF9D97FF)));
      });

      testWidgets('background returns dark background', (tester) async {
        late Color result;
        await tester.pumpWidget(
          MaterialApp(
            theme: AppTheme.darkTheme,
            themeMode: ThemeMode.dark,
            darkTheme: AppTheme.darkTheme,
            home: Builder(
              builder: (context) {
                result = AppTheme.background(context);
                return const SizedBox();
              },
            ),
          ),
        );
        expect(result, equals(const Color(0xFF121218)));
      });

      testWidgets('textPrimary returns dark text color', (tester) async {
        late Color result;
        await tester.pumpWidget(
          MaterialApp(
            theme: AppTheme.darkTheme,
            themeMode: ThemeMode.dark,
            darkTheme: AppTheme.darkTheme,
            home: Builder(
              builder: (context) {
                result = AppTheme.textPrimary(context);
                return const SizedBox();
              },
            ),
          ),
        );
        expect(result, equals(const Color(0xFFE8E8F0)));
      });
    });

    group('shared constants', () {
      test('gamification colors are defined', () {
        expect(AppTheme.xpGold, equals(const Color(0xFFFFD700)));
        expect(AppTheme.streakOrange, equals(const Color(0xFFFF6B35)));
        expect(AppTheme.successGreen, equals(const Color(0xFF4CAF50)));
        expect(AppTheme.errorRed, equals(const Color(0xFFEF5350)));
      });

      test('difficulty colors are defined', () {
        expect(AppTheme.difficultyBeginner, equals(const Color(0xFF4CAF50)));
        expect(AppTheme.difficultyEasy, equals(const Color(0xFF8BC34A)));
        expect(AppTheme.difficultyMedium, equals(const Color(0xFFFFEB3B)));
        expect(AppTheme.difficultyHard, equals(const Color(0xFFFF9800)));
        expect(AppTheme.difficultyExpert, equals(const Color(0xFFf44336)));
      });
    });
  });
}
