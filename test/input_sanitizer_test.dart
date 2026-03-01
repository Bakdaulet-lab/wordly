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

      test('strips XSS event handler patterns', () {
        expect(
          InputSanitizer.sanitize('hello onload=alert(1)'),
          equals('hello alert(1)'),
        );
        expect(
          InputSanitizer.sanitize('javascript:alert(1)'),
          equals('alert(1)'),
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

    group('escapeHtml', () {
      test('escapes all five critical HTML characters', () {
        expect(InputSanitizer.escapeHtml('&'), equals('&amp;'));
        expect(InputSanitizer.escapeHtml('<'), equals('&lt;'));
        expect(InputSanitizer.escapeHtml('>'), equals('&gt;'));
        expect(InputSanitizer.escapeHtml('"'), equals('&quot;'));
        expect(InputSanitizer.escapeHtml("'"), equals('&#x27;'));
      });

      test('escapes mixed content', () {
        expect(
          InputSanitizer.escapeHtml('<script>alert("xss")</script>'),
          equals(
            '&lt;script&gt;alert(&quot;xss&quot;)&lt;/script&gt;',
          ),
        );
      });

      test('leaves safe text unchanged', () {
        expect(InputSanitizer.escapeHtml('Hello World'), equals('Hello World'));
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
      test('strips tags, escapes HTML entities, and trims', () {
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

      test('removes disallowed characters', () {
        expect(
          InputSanitizer.sanitizeDisplayName('Al@ex#\$%'),
          equals('Alex'),
        );
      });

      test('allows Unicode letters', () {
        expect(
          InputSanitizer.sanitizeDisplayName('Алексей'),
          equals('Алексей'),
        );
      });

      test('allows hyphens, underscores, apostrophes, dots', () {
        expect(
          InputSanitizer.sanitizeDisplayName("O'Brien-Jr."),
          equals("O'Brien-Jr."),
        );
      });

      test('blocks XSS via javascript: URI in display name', () {
        final result = InputSanitizer.sanitizeDisplayName(
          'javascript:alert(1)',
        );
        expect(result, isNot(contains('javascript:')));
      });

      test('blocks XSS via event handler in display name', () {
        final result = InputSanitizer.sanitizeDisplayName(
          'name" onmouseover="alert(1)"',
        );
        expect(result, isNot(contains('onmouseover')));
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
