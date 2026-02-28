import 'package:flutter_test/flutter_test.dart';
import 'package:wordly/utils/validators.dart';

void main() {
  group('Validators', () {
    group('validateEmail', () {
      test('returns error for null', () {
        expect(Validators.validateEmail(null), isNotNull);
      });

      test('returns error for empty string', () {
        expect(Validators.validateEmail(''), isNotNull);
      });

      test('returns error for whitespace only', () {
        expect(Validators.validateEmail('   '), isNotNull);
      });

      test('returns error for invalid email format', () {
        expect(Validators.validateEmail('notanemail'), isNotNull);
        expect(Validators.validateEmail('missing@tld'), isNotNull);
        expect(Validators.validateEmail('@no-local.com'), isNotNull);
      });

      test('returns null for valid email', () {
        expect(Validators.validateEmail('user@example.com'), isNull);
        expect(Validators.validateEmail('test.user@domain.org'), isNull);
      });
    });

    group('validatePassword', () {
      test('returns error for null', () {
        expect(Validators.validatePassword(null), isNotNull);
      });

      test('returns error for empty string', () {
        expect(Validators.validatePassword(''), isNotNull);
      });

      test('returns error for password shorter than 6 chars', () {
        expect(Validators.validatePassword('12345'), isNotNull);
      });

      test('returns null for password with 6+ characters', () {
        expect(Validators.validatePassword('123456'), isNull);
        expect(Validators.validatePassword('strongpassword'), isNull);
      });

      test('returns error for password longer than 128 chars', () {
        final longPassword = 'a' * 129;
        expect(Validators.validatePassword(longPassword), isNotNull);
      });

      test('returns null for password exactly 128 chars', () {
        final maxPassword = 'a' * 128;
        expect(Validators.validatePassword(maxPassword), isNull);
      });
    });

    group('validateDisplayName', () {
      test('returns error for null', () {
        expect(Validators.validateDisplayName(null), isNotNull);
      });

      test('returns error for single character', () {
        expect(Validators.validateDisplayName('A'), isNotNull);
      });

      test('returns null for valid name', () {
        expect(Validators.validateDisplayName('Alex'), isNull);
        expect(Validators.validateDisplayName('Jo'), isNull);
      });

      test('returns error for name with HTML tags after sanitization', () {
        // After stripping <script>alert('x')</script>, only "alert('x')" remains
        // which contains invalid characters (parentheses, quotes)
        expect(Validators.validateDisplayName("<script>alert('x')</script>"),
            isNotNull,);
      });

      test('returns error for name with special characters', () {
        expect(Validators.validateDisplayName('Name@#\$'), isNotNull);
      });

      test('accepts names with accented and Cyrillic characters', () {
        expect(Validators.validateDisplayName('André'), isNull);
        expect(Validators.validateDisplayName('Алексей'), isNull);
      });
    });

    group('validateSearchQuery', () {
      test('returns null for empty query', () {
        expect(Validators.validateSearchQuery(''), isNull);
        expect(Validators.validateSearchQuery(null), isNull);
      });

      test('returns null for valid query', () {
        expect(Validators.validateSearchQuery('hello'), isNull);
      });
    });
  });
}
