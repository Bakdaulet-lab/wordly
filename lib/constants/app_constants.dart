class AppConstants {
  AppConstants._();

  // Quiz
  static const int quizOptionsCount = 4;
  static const int quizQuestionsPerSession = 10;
  static const int quizAutoAdvanceDelayMs = 800;
  static const int quizTimerSeconds = 15;

  // SM-2 Spaced Repetition defaults
  static const double sm2DefaultEaseFactor = 2.5;
  static const double sm2MinEaseFactor = 1.3;
  static const int sm2FirstInterval = 1;
  static const int sm2SecondInterval = 6;

  // XP rewards
  static const int xpCorrectAnswer = 10;
  static const int xpIncorrectAnswer = 2;
  static const int xpPerfectQuizBonus = 25;
  static const int xpDailyStreakBonus = 15;

  // Level thresholds (cumulative XP required)
  static const List<int> levelThresholds = [
    0,     // Level 1
    100,   // Level 2
    250,   // Level 3
    500,   // Level 4
    1000,  // Level 5
    1750,  // Level 6
    2800,  // Level 7
    4200,  // Level 8
    6000,  // Level 9
    8500,  // Level 10
  ];

  // Review
  static const int maxReviewWordsPerSession = 20;

  // Quality ratings for SM-2
  static const int qualityWrong = 1;
  static const int qualityCorrect = 4;
  static const int qualityPerfect = 5;

  /// SM-2 threshold: quality >= this value counts as "correct" for
  /// spaced-repetition interval advancement (standard SM-2 boundary).
  static const int sm2CorrectThreshold = 3;

  // Text-to-Speech
  static const String ttsLanguage = 'en-US';
  static const double ttsSpeechRate = 0.45;
  static const double ttsVolume = 1.0;
  static const double ttsPitch = 1.0;
}
