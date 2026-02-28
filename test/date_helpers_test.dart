import 'package:flutter_test/flutter_test.dart';
import 'package:wordly/utils/date_helpers.dart';

void main() {
  group('DateHelpers', () {
    test('today() returns a date with no time component', () {
      final t = DateHelpers.today();
      expect(t.hour, 0);
      expect(t.minute, 0);
      expect(t.second, 0);
    });

    test('isToday returns true for now', () {
      expect(DateHelpers.isToday(DateTime.now()), isTrue);
    });

    test('isToday returns false for yesterday', () {
      final yesterday = DateTime.now().subtract(const Duration(days: 1));
      expect(DateHelpers.isToday(yesterday), isFalse);
    });

    test('isYesterday returns true for yesterday', () {
      final yesterday = DateTime.now().subtract(const Duration(days: 1));
      expect(DateHelpers.isYesterday(yesterday), isTrue);
    });

    test('isYesterday returns false for today', () {
      expect(DateHelpers.isYesterday(DateTime.now()), isFalse);
    });

    test('daysBetween calculates correctly', () {
      final a = DateTime(2025, 1, 1);
      final b = DateTime(2025, 1, 10);
      expect(DateHelpers.daysBetween(a, b), 9);
    });

    test('daysBetween returns negative for reversed dates', () {
      final a = DateTime(2025, 1, 10);
      final b = DateTime(2025, 1, 1);
      expect(DateHelpers.daysBetween(a, b), -9);
    });

    test('formatDate formats correctly', () {
      final d = DateTime(2025, 3, 15);
      expect(DateHelpers.formatDate(d), 'Mar 15, 2025');
    });
  });
}
