import '../services/logger_service.dart';

/// Utility that measures the wall-clock time of async operations and
/// logs a warning when any call exceeds the configured threshold.
///
/// Usage:
/// ```dart
/// final words = await PerformanceMonitor.measure(
///   'fetchWords',
///   () => _wordService.fetchWords(limit: 20, offset: 0),
/// );
/// ```
class PerformanceMonitor {
  PerformanceMonitor._();

  /// Threshold above which a warning is logged (default: 300 ms).
  static Duration threshold = const Duration(milliseconds: 300);

  /// Execute [fn] and log a warning if it takes longer than [threshold].
  ///
  /// [label] is included in the log message for easy identification.
  /// Returns the value produced by [fn].
  static Future<T> measure<T>(String label, Future<T> Function() fn) async {
    final stopwatch = Stopwatch()..start();
    try {
      final result = await fn();
      return result;
    } finally {
      stopwatch.stop();
      final elapsed = stopwatch.elapsed;
      if (elapsed > threshold) {
        AppLogger.warning(
          '$label took ${elapsed.inMilliseconds}ms (threshold: ${threshold.inMilliseconds}ms)',
          tag: 'PerformanceMonitor',
        );
      } else {
        AppLogger.debug(
          '$label completed in ${elapsed.inMilliseconds}ms',
          tag: 'PerformanceMonitor',
        );
      }
    }
  }
}
