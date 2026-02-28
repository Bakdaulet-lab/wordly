import 'package:flutter_test/flutter_test.dart';
import 'package:wordly/utils/xp_calculator.dart';

void main() {
  group('XpCalculator', () {
    group('levelFromXp', () {
      test('returns level 1 for 0 XP', () {
        expect(XpCalculator.levelFromXp(0), 1);
      });

      test('returns level 1 for 99 XP (just below threshold)', () {
        expect(XpCalculator.levelFromXp(99), 1);
      });

      test('returns level 2 for exactly 100 XP', () {
        expect(XpCalculator.levelFromXp(100), 2);
      });

      test('returns level 3 for 250 XP', () {
        expect(XpCalculator.levelFromXp(250), 3);
      });

      test('returns level 5 for 1000 XP', () {
        expect(XpCalculator.levelFromXp(1000), 5);
      });

      test('returns level 10 for 8500 XP', () {
        expect(XpCalculator.levelFromXp(8500), 10);
      });

      test('returns level 10 for XP beyond all thresholds', () {
        expect(XpCalculator.levelFromXp(99999), 10);
      });
    });

    group('xpForNextLevel', () {
      test('returns 100 for level 1', () {
        expect(XpCalculator.xpForNextLevel(1), 100);
      });

      test('returns 250 for level 2', () {
        expect(XpCalculator.xpForNextLevel(2), 250);
      });

      test('returns null for max level (10)', () {
        expect(XpCalculator.xpForNextLevel(10), null);
      });
    });

    group('xpProgressInLevel', () {
      test('returns 0.0 at start of level 1', () {
        expect(XpCalculator.xpProgressInLevel(0), 0.0);
      });

      test('returns 0.5 at midpoint of level 1 (50/100)', () {
        expect(XpCalculator.xpProgressInLevel(50), 0.5);
      });

      test('returns 1.0 at max level', () {
        expect(XpCalculator.xpProgressInLevel(99999), 1.0);
      });

      test('returns correct progress mid-level 2 (175 XP = 75 out of 150)', () {
        // Level 2: 100–250, so 175 is 75/150 = 0.5
        expect(XpCalculator.xpProgressInLevel(175), 0.5);
      });
    });
  });
}
