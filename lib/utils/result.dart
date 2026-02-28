/// A lightweight Result type for typed error handling.
///
/// Every service/repository call returns `Result<T>` instead of throwing.
/// Consumers use [when], [fold], or the [isSuccess]/[isFailure] getters
/// to handle the two cases without try/catch boiler-plate.
sealed class Result<T> {
  const Result();

  /// Create a success result wrapping [data].
  const factory Result.success(T data) = Success<T>;

  /// Create a failure result wrapping [error].
  const factory Result.failure(AppException error) = Failure<T>;

  bool get isSuccess => this is Success<T>;
  bool get isFailure => this is Failure<T>;

  /// Pattern-match both branches.
  R when<R>({
    required R Function(T data) success,
    required R Function(AppException error) failure,
  }) {
    return switch (this) {
      Success<T>(:final data) => success(data),
      Failure<T>(:final error) => failure(error),
    };
  }

  /// Extract data or null.
  T? get dataOrNull => switch (this) {
    Success<T>(:final data) => data,
    Failure<T>() => null,
  };

  /// Extract error or null.
  AppException? get errorOrNull => switch (this) {
    Success<T>() => null,
    Failure<T>(:final error) => error,
  };
}

final class Success<T> extends Result<T> {
  final T data;
  const Success(this.data);
}

final class Failure<T> extends Result<T> {
  final AppException error;
  const Failure(this.error);
}

/// Typed application exception that replaces raw [Exception]/[Error] objects.
class AppException implements Exception {
  final String message;
  final String? code;
  final AppExceptionType type;
  final Object? originalError;

  const AppException({
    required this.message,
    this.code,
    this.type = AppExceptionType.unknown,
    this.originalError,
  });

  /// User-friendly display string.
  String get userMessage => switch (type) {
    AppExceptionType.network =>
      'No internet connection. Please check your network.',
    AppExceptionType.auth => message,
    AppExceptionType.database =>
      'A database error occurred. Please try again.',
    AppExceptionType.permission =>
      'Permission denied. Please sign in again.',
    AppExceptionType.rateLimit =>
      'Too many requests. Please wait a moment and try again.',
    AppExceptionType.timeout =>
      'Request timed out. Please try again.',
    AppExceptionType.validation => message,
    AppExceptionType.notFound =>
      'The requested resource was not found.',
    AppExceptionType.unknown =>
      'Something went wrong. Please try again.',
  };

  @override
  String toString() => 'AppException($type): $message';
}

enum AppExceptionType {
  network,
  auth,
  database,
  permission,
  rateLimit,
  timeout,
  validation,
  notFound,
  unknown,
}
