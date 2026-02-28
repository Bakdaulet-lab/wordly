import '../constants/app_constants.dart';

class SM2Result {
  final int repetitionCount;
  final double easeFactor;
  final int intervalDays;
  final DateTime nextReviewDate;

  SM2Result({
    required this.repetitionCount,
    required this.easeFactor,
    required this.intervalDays,
    required this.nextReviewDate,
  });
}

SM2Result calculateSM2({
  required int quality,
  required int repetitionCount,
  required double easeFactor,
  required int intervalDays,
}) {
  int newRepCount = repetitionCount;
  int newInterval = intervalDays;
  double newEF = easeFactor;

  if (quality < 3) {
    // Wrong answer: reset
    newRepCount = 0;
    newInterval = AppConstants.sm2FirstInterval;
  } else {
    // Correct answer
    if (newRepCount == 0) {
      newInterval = AppConstants.sm2FirstInterval;
    } else if (newRepCount == 1) {
      newInterval = AppConstants.sm2SecondInterval;
    } else {
      newInterval = (newInterval * newEF).round();
    }
    newRepCount += 1;
  }

  // Update ease factor
  newEF = newEF + (0.1 - (5 - quality) * (0.08 + (5 - quality) * 0.02));
  if (newEF < AppConstants.sm2MinEaseFactor) {
    newEF = AppConstants.sm2MinEaseFactor;
  }

  final now = DateTime.now();
  final nextReview = DateTime(now.year, now.month, now.day)
      .add(Duration(days: newInterval));

  return SM2Result(
    repetitionCount: newRepCount,
    easeFactor: newEF,
    intervalDays: newInterval,
    nextReviewDate: nextReview,
  );
}
