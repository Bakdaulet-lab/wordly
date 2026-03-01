import 'package:flutter_test/flutter_test.dart';
import 'package:wordly/utils/app_logger.dart';

void main() {
  group('AppLogger', () {
    test('singleton instance is consistent', () {
      final a = AppLogger.instance;
      final b = AppLogger.instance;
      expect(identical(a, b), isTrue);
    });

    test('default minLevel is debug in test mode', () {
      // In flutter_test (debug mode), minLevel defaults to debug
      expect(AppLogger.instance.minLevel, LogLevel.debug);
    });

    test('minLevel can be changed', () {
      final original = AppLogger.instance.minLevel;
      AppLogger.instance.minLevel = LogLevel.error;
      expect(AppLogger.instance.minLevel, LogLevel.error);
      // Restore
      AppLogger.instance.minLevel = original;
    });

    test('logging methods do not throw', () {
      // Verify all log methods can be called without exceptions
      expect(
        () => AppLogger.debug('test debug', tag: 'Test'),
        returnsNormally,
      );
      expect(
        () => AppLogger.info('test info', tag: 'Test'),
        returnsNormally,
      );
      expect(
        () => AppLogger.warning('test warning', tag: 'Test', error: 'err'),
        returnsNormally,
      );
      expect(
        () => AppLogger.error(
          'test error',
          tag: 'Test',
          error: Exception('boom'),
          stackTrace: StackTrace.current,
        ),
        returnsNormally,
      );
      expect(
        () => AppLogger.fatal(
          'test fatal',
          tag: 'Test',
          error: Exception('fatal'),
          stackTrace: StackTrace.current,
        ),
        returnsNormally,
      );
    });

    test('messages below minLevel are suppressed without error', () {
      final original = AppLogger.instance.minLevel;
      AppLogger.instance.minLevel = LogLevel.fatal;

      // These should all silently do nothing
      expect(() => AppLogger.debug('suppressed'), returnsNormally);
      expect(() => AppLogger.info('suppressed'), returnsNormally);
      expect(() => AppLogger.warning('suppressed'), returnsNormally);
      expect(() => AppLogger.error('suppressed'), returnsNormally);

      // Only fatal should go through
      expect(() => AppLogger.fatal('not suppressed'), returnsNormally);

      AppLogger.instance.minLevel = original;
    });
  });

  group('LogLevel', () {
    test('enum values are in ascending severity order', () {
      expect(LogLevel.debug.index, lessThan(LogLevel.info.index));
      expect(LogLevel.info.index, lessThan(LogLevel.warning.index));
      expect(LogLevel.warning.index, lessThan(LogLevel.error.index));
      expect(LogLevel.error.index, lessThan(LogLevel.fatal.index));
    });

    test('all levels have labels', () {
      for (final level in LogLevel.values) {
        expect(level.label, isNotEmpty);
      }
    });

    test('all levels have devToolsLevel values', () {
      for (final level in LogLevel.values) {
        expect(level.devToolsLevel, greaterThan(0));
      }
    });
  });
}
