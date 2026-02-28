import 'package:flutter_test/flutter_test.dart';
import 'package:wordly/utils/retry.dart';
import 'package:wordly/utils/result.dart';

void main() {
  group('retryWithBackoff', () {
    test('succeeds on first attempt', () async {
      int attempts = 0;
      final result = await retryWithBackoff(
        call: () async {
          attempts++;
          return 42;
        },
        maxAttempts: 3,
        initialDelay: const Duration(milliseconds: 1),
      );
      expect(result, 42);
      expect(attempts, 1);
    });

    test('retries and succeeds on second attempt', () async {
      int attempts = 0;
      final result = await retryWithBackoff(
        call: () async {
          attempts++;
          if (attempts < 2) throw Exception('network error');
          return 'ok';
        },
        maxAttempts: 3,
        initialDelay: const Duration(milliseconds: 1),
      );
      expect(result, 'ok');
      expect(attempts, 2);
    });

    test('exhausts all retries and throws', () async {
      // ignore: unused_local_variable
      int attempts = 0;
      expect(
        () => retryWithBackoff(
          call: () async {
            attempts++;
            throw Exception('timeout error');
          },
          maxAttempts: 3,
          initialDelay: const Duration(milliseconds: 1),
        ),
        throwsA(isA<Exception>()),
      );
    });

    test('does not retry when retryIf returns false', () async {
      int attempts = 0;
      expect(
        () => retryWithBackoff(
          call: () async {
            attempts++;
            throw Exception('auth error');
          },
          maxAttempts: 3,
          initialDelay: const Duration(milliseconds: 1),
          retryIf: (e) => e.toString().contains('network'),
        ),
        throwsA(isA<Exception>()),
      );
      // Should have run once then given up (retryIf said no)
      await Future.delayed(const Duration(milliseconds: 50));
      expect(attempts, 1);
    });

    test('respects maxAttempts parameter', () async {
      int attempts = 0;
      try {
        await retryWithBackoff(
          call: () async {
            attempts++;
            throw Exception('connection error');
          },
          maxAttempts: 5,
          initialDelay: const Duration(milliseconds: 1),
        );
      } catch (_) {}
      expect(attempts, 5);
    });
  });

  group('isRetryableError', () {
    test('network errors are retryable', () {
      const error = AppException(
        message: 'Network error',
        type: AppExceptionType.network,
      );
      expect(isRetryableError(error), isTrue);
    });

    test('timeout errors are retryable', () {
      const error = AppException(
        message: 'Timeout',
        type: AppExceptionType.timeout,
      );
      expect(isRetryableError(error), isTrue);
    });

    test('auth errors are NOT retryable', () {
      const error = AppException(
        message: 'Unauthorized',
        type: AppExceptionType.auth,
      );
      expect(isRetryableError(error), isFalse);
    });

    test('validation errors are NOT retryable', () {
      const error = AppException(
        message: 'Invalid email',
        type: AppExceptionType.validation,
      );
      expect(isRetryableError(error), isFalse);
    });

    test('permission errors are NOT retryable', () {
      const error = AppException(
        message: 'Denied',
        type: AppExceptionType.permission,
      );
      expect(isRetryableError(error), isFalse);
    });

    test('notFound errors are NOT retryable', () {
      const error = AppException(
        message: 'Not found',
        type: AppExceptionType.notFound,
      );
      expect(isRetryableError(error), isFalse);
    });

    test('database errors are retryable', () {
      const error = AppException(
        message: 'DB error',
        type: AppExceptionType.database,
      );
      expect(isRetryableError(error), isTrue);
    });

    test('unknown errors are retryable', () {
      const error = AppException(
        message: 'Something',
        type: AppExceptionType.unknown,
      );
      expect(isRetryableError(error), isTrue);
    });

    test('raw socket exceptions are retryable', () {
      expect(isRetryableError(Exception('SocketException')), isTrue);
    });

    test('raw timeout exceptions are retryable', () {
      expect(isRetryableError(Exception('connection timeout')), isTrue);
    });

    test('raw non-network exceptions are not retryable', () {
      expect(isRetryableError(Exception('null check')), isFalse);
    });
  });

  group('apiGuardWithRetry', () {
    test('returns success on immediate success', () async {
      final result = await apiGuardWithRetry(() async => 42);
      expect(result.isSuccess, isTrue);
      expect(result.dataOrNull, 42);
    });

    test('returns failure after retries exhausted for network errors',
        () async {
      final result = await apiGuardWithRetry(
        () async => throw Exception('SocketException: Connection refused'),
        maxAttempts: 2,
      );
      expect(result.isFailure, isTrue);
      expect(result.errorOrNull?.type, AppExceptionType.network);
    });

    test('returns failure for timeout after retries', () async {
      final result = await apiGuardWithRetry(
        () async => throw Exception('Request timed out'),
        maxAttempts: 2,
      );
      expect(result.isFailure, isTrue);
      expect(result.errorOrNull?.type, AppExceptionType.timeout);
    });

    test('does not retry non-retryable errors', () async {
      int attempts = 0;
      final result = await apiGuardWithRetry(
        () async {
          attempts++;
          throw const FormatException('bad data');
        },
        maxAttempts: 3,
      );
      // FormatException doesn't match the retryIf filters (socket/connection/network/timeout)
      expect(result.isFailure, isTrue);
      expect(attempts, 1);
    });
  });
}
