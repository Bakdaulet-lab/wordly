import 'package:flutter_test/flutter_test.dart';
import 'package:wordly/utils/sm2_algorithm.dart';

void main() {
  group('SM-2 Algorithm', () {
    test('first correct answer gives interval of 1 day', () {
      final result = calculateSM2(
        quality: 4,
        repetitionCount: 0,
        easeFactor: 2.5,
        intervalDays: 0,
      );
      expect(result.intervalDays, 1);
      expect(result.repetitionCount, 1);
      expect(result.easeFactor, greaterThanOrEqualTo(1.3));
    });

    test('second correct answer gives interval of 6 days', () {
      final result = calculateSM2(
        quality: 4,
        repetitionCount: 1,
        easeFactor: 2.5,
        intervalDays: 1,
      );
      expect(result.intervalDays, 6);
      expect(result.repetitionCount, 2);
    });

    test('third correct answer multiplies interval by ease factor', () {
      final result = calculateSM2(
        quality: 4,
        repetitionCount: 2,
        easeFactor: 2.5,
        intervalDays: 6,
      );
      // 6 * 2.5 = 15
      expect(result.intervalDays, 15);
      expect(result.repetitionCount, 3);
    });

    test('wrong answer resets repetition count and interval', () {
      final result = calculateSM2(
        quality: 1,
        repetitionCount: 5,
        easeFactor: 2.5,
        intervalDays: 30,
      );
      expect(result.repetitionCount, 0);
      expect(result.intervalDays, 1);
    });

    test('ease factor never drops below 1.3', () {
      // quality=0 drastically reduces EF
      final result = calculateSM2(
        quality: 0,
        repetitionCount: 0,
        easeFactor: 1.3,
        intervalDays: 0,
      );
      expect(result.easeFactor, greaterThanOrEqualTo(1.3));
    });

    test('perfect quality (5) increases ease factor', () {
      final result = calculateSM2(
        quality: 5,
        repetitionCount: 3,
        easeFactor: 2.5,
        intervalDays: 15,
      );
      expect(result.easeFactor, greaterThan(2.5));
    });

    test('next review date is in the future', () {
      final now = DateTime.now();
      final result = calculateSM2(
        quality: 4,
        repetitionCount: 0,
        easeFactor: 2.5,
        intervalDays: 0,
      );
      expect(result.nextReviewDate.isAfter(now) ||
          result.nextReviewDate.isAtSameMomentAs(
              DateTime(now.year, now.month, now.day).add(const Duration(days: 1))),
          isTrue);
    });
  });
}
