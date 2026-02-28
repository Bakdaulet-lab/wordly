import 'package:flutter_test/flutter_test.dart';
import 'package:wordly/utils/result.dart';

void main() {
  group('Result', () {
    group('Success', () {
      test('isSuccess is true', () {
        const result = Result<int>.success(42);
        expect(result.isSuccess, isTrue);
        expect(result.isFailure, isFalse);
      });

      test('dataOrNull returns data', () {
        const result = Result<String>.success('hello');
        expect(result.dataOrNull, 'hello');
      });

      test('errorOrNull returns null', () {
        const result = Result<int>.success(1);
        expect(result.errorOrNull, isNull);
      });

      test('when calls success branch', () {
        const result = Result<int>.success(10);
        final output = result.when(
          success: (data) => 'got $data',
          failure: (error) => 'error',
        );
        expect(output, 'got 10');
      });
    });

    group('Failure', () {
      test('isFailure is true', () {
        const error = AppException(
            message: 'oops', type: AppExceptionType.unknown);
        const result = Result<int>.failure(error);
        expect(result.isFailure, isTrue);
        expect(result.isSuccess, isFalse);
      });

      test('errorOrNull returns AppException', () {
        const error = AppException(
            message: 'fail', type: AppExceptionType.network);
        const result = Result<int>.failure(error);
        expect(result.errorOrNull, isNotNull);
        expect(result.errorOrNull!.type, AppExceptionType.network);
      });

      test('dataOrNull returns null', () {
        const error = AppException(
            message: 'fail', type: AppExceptionType.database);
        const result = Result<String>.failure(error);
        expect(result.dataOrNull, isNull);
      });

      test('when calls failure branch', () {
        const error = AppException(
            message: 'boom', type: AppExceptionType.auth);
        const result = Result<int>.failure(error);
        final output = result.when(
          success: (data) => 'ok',
          failure: (e) => e.message,
        );
        expect(output, 'boom');
      });
    });

    group('AppException', () {
      test('userMessage returns friendly network message', () {
        const e = AppException(
            message: 'raw', type: AppExceptionType.network);
        expect(e.userMessage,
            'No internet connection. Please check your network.');
      });

      test('userMessage returns raw message for auth type', () {
        const e = AppException(
            message: 'Wrong email or password.',
            type: AppExceptionType.auth);
        expect(e.userMessage, 'Wrong email or password.');
      });

      test('userMessage returns generic for unknown type', () {
        const e = AppException(
            message: 'raw', type: AppExceptionType.unknown);
        expect(e.userMessage, 'Something went wrong. Please try again.');
      });

      test('toString contains type and message', () {
        const e = AppException(
            message: 'test', type: AppExceptionType.timeout);
        expect(e.toString(), contains('timeout'));
        expect(e.toString(), contains('test'));
      });
    });
  });
}
