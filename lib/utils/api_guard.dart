import 'package:supabase_flutter/supabase_flutter.dart';
import 'result.dart';

/// Wraps any async [call] and converts raw exceptions into [AppException].
///
/// Usage:
/// ```dart
/// final result = await apiGuard(() => supabase.from('words').select());
/// ```
Future<Result<T>> apiGuard<T>(Future<T> Function() call) async {
  try {
    final data = await call();
    return Result.success(data);
  } on AuthException catch (e) {
    return Result.failure(AppException(
      message: _friendlyAuthMessage(e.message),
      code: e.statusCode,
      type: AppExceptionType.auth,
      originalError: e,
    ));
  } on PostgrestException catch (e) {
    return Result.failure(AppException(
      message: e.message,
      code: e.code,
      type: _postgrestType(e),
      originalError: e,
    ));
  } on FormatException catch (e) {
    return Result.failure(AppException(
      message: 'Invalid data format: ${e.message}',
      type: AppExceptionType.validation,
      originalError: e,
    ));
  } catch (e) {
    final msg = e.toString().toLowerCase();
    if (msg.contains('socketexception') ||
        msg.contains('connection') ||
        msg.contains('network')) {
      return Result.failure(AppException(
        message: 'Network error',
        type: AppExceptionType.network,
        originalError: e,
      ));
    }
    if (msg.contains('timeout') || msg.contains('timed out')) {
      return Result.failure(AppException(
        message: 'Request timed out',
        type: AppExceptionType.timeout,
        originalError: e,
      ));
    }
    return Result.failure(AppException(
      message: e.toString(),
      type: AppExceptionType.unknown,
      originalError: e,
    ));
  }
}

String _friendlyAuthMessage(String raw) {
  final msg = raw.toLowerCase();
  if (msg.contains('invalid login credentials') ||
      msg.contains('invalid_grant')) {
    return 'Wrong email or password. Please try again.';
  }
  if (msg.contains('email not confirmed')) {
    return 'Please check your email and confirm your account.';
  }
  if (msg.contains('user already registered') ||
      msg.contains('already been registered')) {
    return 'An account with this email already exists. Try logging in.';
  }
  if (msg.contains('password') && msg.contains('length')) {
    return 'Password must be at least 6 characters.';
  }
  if (msg.contains('invalid email') ||
      msg.contains('unable to validate email')) {
    return 'Please enter a valid email address.';
  }
  if (msg.contains('too many requests') || msg.contains('rate limit')) {
    return 'Too many attempts. Please wait a moment and try again.';
  }
  return raw;
}

AppExceptionType _postgrestType(PostgrestException e) {
  final code = e.code;
  if (code == '42501' || e.message.contains('row-level security')) {
    return AppExceptionType.permission;
  }
  if (code == 'PGRST116') {
    return AppExceptionType.notFound;
  }
  return AppExceptionType.database;
}
