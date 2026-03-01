import 'dart:developer' as developer;
import 'package:flutter/foundation.dart';

/// Centralized application logger service.
///
/// All log output flows through this class so it can be routed, filtered,
/// or forwarded to a remote crash-reporting service in the future.
///
/// Severity levels (ascending): debug, info, warning, error, fatal.
///
/// This is the canonical logger — prefer importing from
/// `package:wordly/services/logger_service.dart`.
class AppLogger {
  AppLogger._();

  static final AppLogger _instance = AppLogger._();

  /// Singleton access.
  static AppLogger get instance => _instance;

  /// Minimum level that will be printed.  Defaults to [LogLevel.debug] in
  /// debug mode and [LogLevel.info] in release/profile mode.
  LogLevel minLevel = kDebugMode ? LogLevel.debug : LogLevel.info;

  // ── Public API ──────────────────────────────────────────────────────

  /// Log a debug-level message (stripped in release builds by default).
  static void debug(String message, {String? tag}) {
    _instance._log(LogLevel.debug, message, tag: tag);
  }

  /// Log an informational message.
  static void info(String message, {String? tag}) {
    _instance._log(LogLevel.info, message, tag: tag);
  }

  /// Log a warning.
  static void warning(String message, {String? tag, Object? error}) {
    _instance._log(LogLevel.warning, message, tag: tag, error: error);
  }

  /// Log an error with optional stack trace.
  static void error(
    String message, {
    String? tag,
    Object? error,
    StackTrace? stackTrace,
  }) {
    _instance._log(
      LogLevel.error,
      message,
      tag: tag,
      error: error,
      stackTrace: stackTrace,
    );
  }

  /// Log a fatal / unrecoverable error.
  static void fatal(
    String message, {
    String? tag,
    Object? error,
    StackTrace? stackTrace,
  }) {
    _instance._log(
      LogLevel.fatal,
      message,
      tag: tag,
      error: error,
      stackTrace: stackTrace,
    );
  }

  // ── Internals ───────────────────────────────────────────────────────

  void _log(
    LogLevel level,
    String message, {
    String? tag,
    Object? error,
    StackTrace? stackTrace,
  }) {
    if (level.index < minLevel.index) return;

    final prefix = tag != null ? '[$tag] ' : '';
    final label = level.label.toUpperCase().padRight(7);
    final timestamp = DateTime.now().toIso8601String().substring(11, 23);
    final line = '$timestamp $label $prefix$message';

    // In debug mode, use dart:developer log for DevTools integration.
    // In release mode, use debugPrint (which respects throttling).
    if (kDebugMode) {
      developer.log(
        '$prefix$message',
        name: 'Wordly',
        level: level.devToolsLevel,
        error: error,
        stackTrace: stackTrace,
      );
    } else {
      debugPrint(line);
      if (error != null) debugPrint('  Error: $error');
      if (stackTrace != null) debugPrint('  Stack: $stackTrace');
    }
  }
}

/// Log severity levels.
enum LogLevel {
  debug('debug', 500),
  info('info', 800),
  warning('warning', 900),
  error('error', 1000),
  fatal('fatal', 1200);

  final String label;
  final int devToolsLevel;

  const LogLevel(this.label, this.devToolsLevel);
}
