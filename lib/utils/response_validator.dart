import 'result.dart';

/// Validates raw Supabase responses before they are consumed by services.
///
/// Supabase's PostgREST API returns JSON arrays for `.select()` and maps
/// for single-row operations. This class ensures the response shape matches
/// what the caller expects, converting unexpected shapes into typed
/// [AppException] failures rather than letting `cast` errors propagate.
class ResponseValidator {
  const ResponseValidator._();

  /// Validate that [response] is a `List` (e.g. from `.select()`).
  ///
  /// Returns a typed `List<Map<String, dynamic>>` on success, or a
  /// [Result.failure] if the shape is unexpected.
  static Result<List<Map<String, dynamic>>> validateList(
    dynamic response, {
    String context = 'query',
  }) {
    if (response is List) {
      try {
        return Result.success(
          List<Map<String, dynamic>>.from(response),
        );
      } catch (e) {
        return Result.failure(AppException(
          message: 'Invalid list item format in $context response',
          type: AppExceptionType.validation,
          originalError: e,
        ),);
      }
    }

    return Result.failure(AppException(
      message: 'Expected list response for $context, '
          'got ${response.runtimeType}',
      type: AppExceptionType.validation,
      originalError: response,
    ),);
  }

  /// Validate that [response] is a non-empty `List` and return the first row
  /// as a `Map<String, dynamic>` (e.g. from `.select().limit(1)`).
  ///
  /// Returns `null` inside [Result.success] when the list is empty
  /// (i.e. "not found" is not an error, just absent data).
  static Result<Map<String, dynamic>?> validateSingleRow(
    dynamic response, {
    String context = 'single-row query',
  }) {
    if (response is List) {
      if (response.isEmpty) return const Result.success(null);
      final first = response.first;
      if (first is Map<String, dynamic>) {
        return Result.success(first);
      }
      // Try to cast from Map<dynamic, dynamic>
      if (first is Map) {
        try {
          return Result.success(Map<String, dynamic>.from(first));
        } catch (e) {
          return Result.failure(AppException(
            message: 'Invalid row format in $context response',
            type: AppExceptionType.validation,
            originalError: e,
          ),);
        }
      }
      return Result.failure(AppException(
        message: 'Expected map row in $context response, '
            'got ${first.runtimeType}',
        type: AppExceptionType.validation,
        originalError: first,
      ),);
    }

    // Some Supabase operations return a single map directly
    if (response is Map) {
      try {
        return Result.success(Map<String, dynamic>.from(response));
      } catch (e) {
        return Result.failure(AppException(
          message: 'Invalid map format in $context response',
          type: AppExceptionType.validation,
          originalError: e,
        ),);
      }
    }

    return Result.failure(AppException(
      message: 'Expected list or map for $context, '
          'got ${response.runtimeType}',
      type: AppExceptionType.validation,
      originalError: response,
    ),);
  }

  /// Validate that [response] is a `Map<String, dynamic>`
  /// (e.g. from `.insert(...).select().single()`).
  static Result<Map<String, dynamic>> validateMap(
    dynamic response, {
    String context = 'map query',
  }) {
    if (response is Map<String, dynamic>) {
      return Result.success(response);
    }
    if (response is Map) {
      try {
        return Result.success(Map<String, dynamic>.from(response));
      } catch (e) {
        return Result.failure(AppException(
          message: 'Invalid map format in $context response',
          type: AppExceptionType.validation,
          originalError: e,
        ),);
      }
    }
    return Result.failure(AppException(
      message: 'Expected map for $context, got ${response.runtimeType}',
      type: AppExceptionType.validation,
      originalError: response,
    ),);
  }

  /// Validate that [response] is a `List`, then transform each item
  /// using [fromJson].
  ///
  /// Catches format errors per-item and wraps them in a validation failure.
  static Result<List<T>> validateAndMapList<T>(
    dynamic response,
    T Function(Map<String, dynamic>) fromJson, {
    String context = 'list query',
  }) {
    final validated = validateList(response, context: context);
    return validated.when(
      success: (rows) {
        try {
          return Result.success(rows.map(fromJson).toList());
        } catch (e) {
          return Result.failure(AppException(
            message: 'Failed to parse $context items: $e',
            type: AppExceptionType.validation,
            originalError: e,
          ),);
        }
      },
      failure: (error) => Result.failure(error),
    );
  }

  /// Validate a single-row response and transform it using [fromJson].
  ///
  /// Returns `null` when the row is absent.
  static Result<T?> validateAndMapSingleRow<T>(
    dynamic response,
    T Function(Map<String, dynamic>) fromJson, {
    String context = 'single-row query',
  }) {
    final validated = validateSingleRow(response, context: context);
    return validated.when(
      success: (row) {
        if (row == null) return const Result.success(null);
        try {
          return Result.success(fromJson(row));
        } catch (e) {
          return Result.failure(AppException(
            message: 'Failed to parse $context: $e',
            type: AppExceptionType.validation,
            originalError: e,
          ),);
        }
      },
      failure: (error) => Result.failure(error),
    );
  }
}
