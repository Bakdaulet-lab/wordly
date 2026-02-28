import 'package:flutter_test/flutter_test.dart';
import 'package:wordly/utils/input_sanitizer.dart';

void main() {
  group('InputSanitizer', () {
    group('sanitize', () {
      test('strips HTML tags', () {
        expect(InputSanitizer.sanitize('<b>Hello</b>'), equals('Hello'));
        expect(
          InputSanitizer.sanitize('<script>alert("xss")</script>'),
          equals('alert("xss")'),
        );
      });

      test('trims whitespace', () {
        expect(InputSanitizer.sanitize('  hello  '), equals('hello'));
      });

      test('collapses multiple spaces', () {
        expect(InputSanitizer.sanitize('a   b   c'), equals('a b c'));
      });

      test('handles empty string', () {
        expect(InputSanitizer.sanitize(''), equals(''));
      });

      test('handles string with only tags', () {
        expect(InputSanitizer.sanitize('<br><hr>'), equals(''));
      });
    });

    group('sanitizeWithLimit', () {
      test('truncates strings exceeding max length', () {
        final long = 'a' * 200;
        final result = InputSanitizer.sanitizeWithLimit(long, 50);
        expect(result.length, equals(50));
      });

      test('keeps strings within limit unchanged', () {
        expect(InputSanitizer.sanitizeWithLimit('hello', 50), equals('hello'));
      });
    });

    group('sanitizeDisplayName', () {
      test('strips tags and trims', () {
        expect(
          InputSanitizer.sanitizeDisplayName('<b>Alex</b>'),
          equals('Alex'),
        );
      });

      test('truncates at max display name length', () {
        final long = 'a' * 100;
        final result = InputSanitizer.sanitizeDisplayName(long);
        expect(result.length, equals(InputSanitizer.maxDisplayNameLength));
      });
    });

    group('sanitizeEmail', () {
      test('lowercases and trims email', () {
        expect(
          InputSanitizer.sanitizeEmail('  User@Example.COM  '),
          equals('user@example.com'),
        );
      });

      test('truncates at max email length', () {
        final long = '${'a' * 300}@example.com';
        final result = InputSanitizer.sanitizeEmail(long);
        expect(result.length, equals(InputSanitizer.maxEmailLength));
      });
    });

    group('sanitizeSearch', () {
      test('strips tags and trims', () {
        expect(
          InputSanitizer.sanitizeSearch('<script>test</script>'),
          equals('test'),
        );
      });

      test('truncates at max search length', () {
        final long = 'a' * 200;
        final result = InputSanitizer.sanitizeSearch(long);
        expect(result.length, equals(InputSanitizer.maxSearchLength));
      });
    });
  });
}
