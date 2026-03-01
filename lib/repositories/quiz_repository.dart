import '../models/word_model.dart';
import '../models/quiz_option_model.dart';
import '../constants/app_constants.dart';
import '../services/quiz_service.dart';
import '../services/progress_service.dart';
import '../services/xp_service.dart';
import '../services/stats_service.dart';
import '../services/logger_service.dart';
import '../utils/api_guard.dart';
import '../utils/performance_monitor.dart';
import '../utils/result.dart';

/// Repository that handles quiz generation and persisting quiz answers.
class QuizRepository {
  final QuizService _quizService;
  final ProgressService _progressService;
  final XpService _xpService;
  final StatsService _statsService;

  QuizRepository(
    this._quizService,
    this._progressService,
    this._xpService,
    this._statsService,
  );

  /// Generate quiz options (pure, no network).
  List<QuizOptionModel> generateOptions({
    required WordModel correctWord,
    required List<WordModel> allWords,
  }) {
    return _quizService.generateOptions(
        correctWord: correctWord, allWords: allWords,);
  }

  /// Pick random words for a quiz session (pure, no network).
  List<WordModel> pickQuizWords(List<WordModel> allWords, {int count = 10}) {
    return _quizService.pickQuizWords(allWords, count: count);
  }

  /// Fetch quiz words prioritizing those due for SM-2 review, then backfill
  /// with random new words from [allWords] that haven't been reviewed.
  Future<List<WordModel>> getQuizWords({
    required String userId,
    required List<WordModel> allWords,
    int count = 10,
  }) async {
    final selected = <WordModel>[];
    final selectedIds = <int>{};

    // Step 1: Fetch words due for review (next_review_date <= now)
    try {
      final dueRows = await _progressService.getWordsForReview(
        userId,
        limit: count,
      );
      // Build a lookup from allWords for quick matching
      final wordMap = {for (final w in allWords) w.id: w};
      for (final row in dueRows) {
        final wordData = row['words'];
        if (wordData != null) {
          final wordId = wordData['id'] as int?;
          if (wordId != null && wordMap.containsKey(wordId) && !selectedIds.contains(wordId)) {
            selected.add(wordMap[wordId]!);
            selectedIds.add(wordId);
          }
        }
        if (selected.length >= count) break;
      }
    } catch (e) {
      AppLogger.error('Failed to fetch due words: $e', tag: 'QuizRepository', error: e);
    }

    // Step 2: Backfill with random words that are not already selected
    if (selected.length < count) {
      final remaining = allWords
          .where((w) => !selectedIds.contains(w.id))
          .toList();
      final backfill = _quizService.pickQuizWords(
        remaining,
        count: count - selected.length,
      );
      selected.addAll(backfill);
    }

    return selected;
  }

  /// Submit a quiz answer — persists progress, awards XP, increments stats.
  Future<Result<void>> submitAnswer({
    required String userId,
    required int wordId,
    required bool isCorrect,
  }) {
    final quality =
        isCorrect ? AppConstants.qualityCorrect : AppConstants.qualityWrong;
    final xp = isCorrect
        ? AppConstants.xpCorrectAnswer
        : AppConstants.xpIncorrectAnswer;
    final statField = isCorrect ? 'correct_answers' : 'incorrect_answers';

    return apiGuard(() => PerformanceMonitor.measure('QuizRepo.submitAnswer', () => Future.wait([
          _xpService.awardXp(userId, xp),
          _statsService.incrementStat(userId, statField, 1),
          _progressService.updateProgress(
            userId: userId,
            wordId: wordId,
            quality: quality,
          ),
        ]),),);
  }

  /// Finish quiz — awards bonus XP and logs aggregate stats.
  Future<Result<void>> finishQuiz({
    required String userId,
    required int score,
    required int totalQuestions,
    required int totalXpEarned,
  }) {
    return apiGuard(() => PerformanceMonitor.measure('QuizRepo.finishQuiz', () async {
      final futures = <Future>[];

      int xpToLog = totalXpEarned;

      if (score == totalQuestions && totalQuestions > 0) {
        const bonus = AppConstants.xpPerfectQuizBonus;
        xpToLog += bonus;
        futures.add(_xpService.awardXp(userId, bonus));
      }

      futures.add(
          _statsService.incrementStat(userId, 'words_reviewed', totalQuestions),);
      futures.add(_statsService.incrementStat(userId, 'xp_earned', xpToLog));

      await Future.wait(futures);
    }),);
  }
}
