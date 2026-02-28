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
    });
  });
}
