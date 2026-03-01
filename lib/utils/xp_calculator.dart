import '../constants/app_constants.dart';

/// Pure functions for calculating experience-point rewards.
class XpCalculator {
  XpCalculator._();

  static int xpForCorrectAnswer() => AppConstants.xpCorrectAnswer;

  static int xpForIncorrectAnswer() => AppConstants.xpIncorrectAnswer;

  static int xpForPerfectQuiz() => AppConstants.xpPerfectQuizBonus;

  static int xpForDailyStreak() => AppConstants.xpDailyStreakBonus;

  /// Returns the level for a given total XP amount.
  static int levelFromXp(int totalXp) {
    const thresholds = AppConstants.levelThresholds;
    for (int i = thresholds.length - 1; i >= 0; i--) {
      if (totalXp >= thresholds[i]) {
        return i + 1; // Levels are 1-indexed
      }
    }
    return 1;
  }

  /// Returns total XP needed to reach the next level.
  /// Returns null if already at max level.
  static int? xpForNextLevel(int currentLevel) {
    const thresholds = AppConstants.levelThresholds;
    if (currentLevel >= thresholds.length) return null;
    return thresholds[currentLevel]; // currentLevel is 1-indexed, so index = currentLevel for next
  }

  /// Returns XP progress within the current level (0.0 to 1.0).
  static double xpProgressInLevel(int totalXp) {
    const thresholds = AppConstants.levelThresholds;
    final level = levelFromXp(totalXp);

    if (level >= thresholds.length) return 1.0; // Max level

    final currentLevelXp = thresholds[level - 1];
    final nextLevelXp = thresholds[level];
    final xpInLevel = totalXp - currentLevelXp;
    final xpNeeded = nextLevelXp - currentLevelXp;

    return xpNeeded > 0 ? xpInLevel / xpNeeded : 1.0;
  }
}
