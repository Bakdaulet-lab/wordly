import '../models/user_word_progress_model.dart';
import '../services/progress_service.dart';
import '../services/xp_service.dart';
import '../services/stats_service.dart';
import '../constants/app_constants.dart';
import '../utils/api_guard.dart';
import '../utils/result.dart';

/// Repository that orchestrates progress updates, XP awards, and stat tracking.
class ProgressRepository {
  final ProgressService _progressService;
  final XpService _xpService;
  final StatsService _statsService;

  ProgressRepository(this._progressService, this._xpService, this._statsService);

  Future<Result<List<Map<String, dynamic>>>> getWordsForReview(
      String userId, {int limit = 20}) {
    return apiGuard(
        () => _progressService.getWordsForReview(userId, limit: limit));
  }

  Future<Result<UserWordProgressModel?>> getProgress(
      String userId, int wordId) {
    return apiGuard(() => _progressService.getProgress(userId, wordId));
  }

  Future<Result<int>> countDueWords(String userId) {
    return apiGuard(() => _progressService.countDueWords(userId));
  }

  /// Answer a review question — updates progress, awards XP, and logs stats.
  ///
  /// Returns a [Result] indicating success or failure of the combined operation.
  Future<Result<void>> answerReview({
    required String userId,
    required int wordId,
    required bool knewIt,
  }) {
    final quality =
        knewIt ? AppConstants.qualityCorrect : AppConstants.qualityWrong;
    final xp = knewIt
        ? AppConstants.xpCorrectAnswer
        : AppConstants.xpIncorrectAnswer;
    final statField = knewIt ? 'correct_answers' : 'incorrect_answers';

    return apiGuard(() => Future.wait([
          _progressService.updateProgress(
            userId: userId,
            wordId: wordId,
            quality: quality,
          ),
          _xpService.awardXp(userId, xp),
          _statsService.incrementStat(userId, 'words_reviewed', 1),
          _statsService.incrementStat(userId, statField, 1),
          _statsService.incrementStat(userId, 'xp_earned', xp),
        ]));
  }
}
