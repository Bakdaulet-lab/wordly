import 'dart:async';
import 'dart:math';
import 'package:flutter/foundation.dart';
import 'result.dart';

/// Retries an async operation with exponential backoff.
///
/// [call] is the async function to retry.
/// [maxAttempts] is the maximum number of attempts (default: 3).
/// [initialDelay] is the delay before the first retry (default: 500ms).
/// [maxDelay] is the maximum delay between retries (default: 8s).
/// [retryIf] optionally filters which exceptions warrant a retry.
///
/// Returns the result of the first successful call, or the last failure.
Future<T> retryWithBackoff<T>({
  required Future<T> Function() call,
  int maxAttempts = 3,
  Duration initialDelay = const Duration(milliseconds: 500),
  Duration maxDelay = const Duration(seconds: 8),
  bool Function(Object error)? retryIf,
}) async {
  final random = Random();
  Object? lastError;
  StackTrace? lastStack;

  for (var attempt = 0; attempt < maxAttempts; attempt++) {
    try {
      return await call();
    } catch (e, stack) {
      lastError = e;
      lastStack = stack;

      // Don't retry if retryIf says no
      if (retryIf != null && !retryIf(e)) {
        rethrow;
      }

      // Don't delay after the last attempt
      if (attempt < maxAttempts - 1) {
        final baseDelay = initialDelay * pow(2, attempt);
        final jitter = Duration(
          milliseconds: random.nextInt(baseDelay.inMilliseconds ~/ 2 + 1),
        );
        final delay = baseDelay + jitter;
        final capped = delay > maxDelay ? maxDelay : delay;

        debugPrint(
          '[Retry] Attempt ${attempt + 1}/$maxAttempts failed, '
          'retrying in ${capped.inMilliseconds}ms: $e',
        );
        await Future.delayed(capped);
      }
    }
  }

  // Exhausted all retries – rethrow the last error
  Error.throwWithStackTrace(lastError!, lastStack!);
}

/// Whether an [AppException] error type is retryable.
///
/// Network errors, timeouts, and unknown errors are retryable.
/// Auth, validation, permission, and not-found errors are NOT.
bool isRetryableError(Object error) {
  if (error is AppException) {
    return switch (error.type) {
      AppExceptionType.network => true,
      AppExceptionType.timeout => true,
      AppExceptionType.unknown => true,
      AppExceptionType.database => true,
      AppExceptionType.rateLimit => false,
      AppExceptionType.auth => false,
      AppExceptionType.permission => false,
      AppExceptionType.validation => false,
      AppExceptionType.notFound => false,
    };
  }
  // For raw exceptions, retry network/timeout, skip the rest
  final msg = error.toString().toLowerCase();
  if (msg.contains('socket') || msg.contains('connection') || msg.contains('timeout')) {
    return true;
  }
  return false;
}

/// Convenience: wraps [apiGuard]-style calls with retry + backoff.
///
/// Usage:
/// ```dart
/// final result = await apiGuardWithRetry(() => supabase.from('words').select());
/// ```
Future<Result<T>> apiGuardWithRetry<T>(
  Future<T> Function() call, {
  int maxAttempts = 3,
}) async {
  try {
    final data = await retryWithBackoff(
      call: call,
      maxAttempts: maxAttempts,
      retryIf: (e) {
        final msg = e.toString().toLowerCase();
        return msg.contains('socket') ||
            msg.contains('connection') ||
            msg.contains('network') ||
            msg.contains('timeout') ||
            msg.contains('timed out');
      },
    );
    return Result.success(data);
  } catch (e) {
    // Fall through to apiGuard-style error mapping
    return _mapError(e);
  }
}

Result<T> _mapError<T>(Object e) {
  final msg = e.toString().toLowerCase();
  if (msg.contains('socketexception') ||
      msg.contains('connection') ||
      msg.contains('network')) {
    return Result.failure(AppException(
      message: 'Network error after retries',
      type: AppExceptionType.network,
      originalError: e,
    ),);
  }
  if (msg.contains('timeout') || msg.contains('timed out')) {
    return Result.failure(AppException(
      message: 'Request timed out after retries',
      type: AppExceptionType.timeout,
      originalError: e,
    ),);
  }
  return Result.failure(AppException(
    message: e.toString(),
    type: AppExceptionType.unknown,
    originalError: e,
  ),);
}
