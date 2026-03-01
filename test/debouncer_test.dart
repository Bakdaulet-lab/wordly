import 'package:flutter_test/flutter_test.dart';
import 'package:wordly/utils/debouncer.dart';

void main() {
  group('Debouncer', () {
    group('run (trailing-edge debounce)', () {
      test('calls action after delay', () async {
        final debouncer = Debouncer(delay: const Duration(milliseconds: 50));
        int callCount = 0;

        debouncer.run(() => callCount++);
        expect(callCount, 0, reason: 'Action should not fire immediately');

        await Future.delayed(const Duration(milliseconds: 80));
        expect(callCount, 1, reason: 'Action should fire after delay');

        debouncer.dispose();
      });

      test('cancels previous call when run is called again', () async {
        final debouncer = Debouncer(delay: const Duration(milliseconds: 50));
        int callCount = 0;

        debouncer.run(() => callCount++);
        await Future.delayed(const Duration(milliseconds: 20));
        debouncer.run(() => callCount++); // restart timer

        await Future.delayed(const Duration(milliseconds: 80));
        expect(callCount, 1, reason: 'Only the last call should fire');

        debouncer.dispose();
      });

      test('cancel prevents pending call from executing', () async {
        final debouncer = Debouncer(delay: const Duration(milliseconds: 50));
        int callCount = 0;

        debouncer.run(() => callCount++);
        debouncer.cancel();

        await Future.delayed(const Duration(milliseconds: 80));
        expect(callCount, 0, reason: 'Cancelled call should not fire');

        debouncer.dispose();
      });
    });

    group('runImmediate (leading-edge throttle)', () {
      test('executes first call immediately', () {
        final debouncer = Debouncer(delay: const Duration(milliseconds: 100));
        int callCount = 0;

        final executed = debouncer.runImmediate(() => callCount++);
        expect(executed, isTrue);
        expect(callCount, 1);

        debouncer.dispose();
      });

      test('blocks subsequent calls during cooldown', () {
        final debouncer = Debouncer(delay: const Duration(milliseconds: 100));
        int callCount = 0;

        debouncer.runImmediate(() => callCount++);
        final second = debouncer.runImmediate(() => callCount++);
        final third = debouncer.runImmediate(() => callCount++);

        expect(callCount, 1, reason: 'Only first call should execute');
        expect(second, isFalse);
        expect(third, isFalse);

        debouncer.dispose();
      });

      test('allows calls after cooldown expires', () async {
        final debouncer = Debouncer(delay: const Duration(milliseconds: 50));
        int callCount = 0;

        debouncer.runImmediate(() => callCount++);
        expect(callCount, 1);

        await Future.delayed(const Duration(milliseconds: 80));

        final executed = debouncer.runImmediate(() => callCount++);
        expect(executed, isTrue);
        expect(callCount, 2);

        debouncer.dispose();
      });

      test('isDebouncing reflects cooldown state', () async {
        final debouncer = Debouncer(delay: const Duration(milliseconds: 50));

        expect(debouncer.isDebouncing, isFalse);

        debouncer.runImmediate(() {});
        expect(debouncer.isDebouncing, isTrue);

        await Future.delayed(const Duration(milliseconds: 80));
        expect(debouncer.isDebouncing, isFalse);

        debouncer.dispose();
      });
    });

    group('guard (async leading-edge throttle)', () {
      test('returns result on first call', () async {
        final debouncer = Debouncer(delay: const Duration(milliseconds: 100));

        final result = await debouncer.guard(() async => 42);
        expect(result, 42);

        debouncer.dispose();
      });

      test('returns null for debounced calls', () async {
        final debouncer = Debouncer(delay: const Duration(milliseconds: 100));

        final first = await debouncer.guard(() async => 'first');
        final second = await debouncer.guard(() async => 'second');

        expect(first, 'first');
        expect(second, isNull);

        debouncer.dispose();
      });

      test('allows calls after cooldown', () async {
        final debouncer = Debouncer(delay: const Duration(milliseconds: 50));

        final first = await debouncer.guard(() async => 1);
        await Future.delayed(const Duration(milliseconds: 80));
        final second = await debouncer.guard(() async => 2);

        expect(first, 1);
        expect(second, 2);

        debouncer.dispose();
      });

      test('resets cooldown even on exception', () async {
        final debouncer = Debouncer(delay: const Duration(milliseconds: 50));

        try {
          await debouncer.guard(() async => throw Exception('fail'));
        } catch (_) {}

        // During cooldown, should be blocked
        final blocked = await debouncer.guard(() async => 'ok');
        expect(blocked, isNull);

        // After cooldown, should work
        await Future.delayed(const Duration(milliseconds: 80));
        final ok = await debouncer.guard(() async => 'recovered');
        expect(ok, 'recovered');

        debouncer.dispose();
      });
    });

    group('timeSinceLastCall', () {
      test('is null before any call', () {
        final debouncer = Debouncer();
        expect(debouncer.timeSinceLastCall, isNull);
        debouncer.dispose();
      });

      test('is non-null after a call', () async {
        final debouncer = Debouncer(delay: const Duration(milliseconds: 50));
        debouncer.runImmediate(() {});

        await Future.delayed(const Duration(milliseconds: 10));
        final elapsed = debouncer.timeSinceLastCall;
        expect(elapsed, isNotNull);
        expect(elapsed!.inMilliseconds, greaterThanOrEqualTo(5));

        debouncer.dispose();
      });
    });

    group('dispose', () {
      test('cancels pending timer and resets state', () async {
        final debouncer = Debouncer(delay: const Duration(milliseconds: 50));
        int callCount = 0;

        debouncer.run(() => callCount++);
        debouncer.dispose();

        await Future.delayed(const Duration(milliseconds: 80));
        expect(callCount, 0);
        expect(debouncer.isDebouncing, isFalse);
      });
    });
  });
}
