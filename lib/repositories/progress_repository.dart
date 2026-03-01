import '../models/user_word_progress_model.dart';
import '../services/progress_service.dart';
import '../services/xp_service.dart';
import '../services/stats_service.dart';
import '../services/offline_cache_service.dart';
import '../services/logger_service.dart';
import '../di/service_locator.dart';
import '../constants/app_constants.dart';
import '../utils/api_guard.dart';
import '../utils/performance_monitor.dart';
import '../utils/result.dart';
import '../utils/retry.dart';
import '../utils/sm2_algorithm.dart';

/// Repository that orchestrates progress updates, XP awards, and stat tracking.
/// Falls back to offline cache when the network is unavailable.
class ProgressRepository {
  final ProgressService _progressService;
  final XpService _xpService;
  final StatsService _statsService;

  ProgressRepository(this._progressService, this._xpService, this._statsService);

  OfflineCacheService get _cache => sl<OfflineCacheService>();

  /// Get words due for review, with offline fallback.
  Future<Result<List<Map<String, dynamic>>>> getWordsForReview(
      String userId, {int limit = 20,}) async {
    final result = await apiGuardWithRetry(
        () => PerformanceMonitor.measure('ProgressRepo.getWordsForReview', () => _progressService.getWordsForReview(userId, limit: limit)),);
    return result.when(
      success: (items) => Result.success(items),
      failure: (error) async {
        if (error.type == AppExceptionType.network ||
            error.type == AppExceptionType.timeout) {
          AppLogger.info('Falling back to cached due words', tag: 'ProgressRepo');
          final cached = await _cache.getCachedDueWords(userId);
          return Result.success(cached);
        }
        return Result.failure(error);
      },
    );
  }

  /// Get progress for a specific word, with offline fallback.
  Future<Result<UserWordProgressModel?>> getProgress(
      String userId, int wordId,) async {
    final result = await apiGuardWithRetry(
        () => PerformanceMonitor.measure('ProgressRepo.getProgress', () => _progressService.getProgress(userId, wordId)),);
    return result.when(
      success: (data) => Result.success(data),
      failure: (error) async {
        if (error.type == AppExceptionType.network ||
            error.type == AppExceptionType.timeout) {
          final cached = await _cache.getCachedProgress(userId, wordId);
          return Result.success(cached);
        }
        return Result.failure(error);
      },
    );
  }

  /// Count due words, with offline fallback.
  Future<Result<int>> countDueWords(String userId) async {
    final result = await apiGuardWithRetry(
        () => PerformanceMonitor.measure('ProgressRepo.countDueWords', () => _progressService.countDueWords(userId)),);
    return result.when(
      success: (count) => Result.success(count),
      failure: (error) async {
        if (error.type == AppExceptionType.network ||
            error.type == AppExceptionType.timeout) {
          final count = await _cache.countCachedDueWords(userId);
          return Result.success(count);
        }
        return Result.failure(error);
      },
    );
  }

  /// Answer a review question — updates progress, awards XP, and logs stats.
  /// When offline, queues the mutation and updates local cache.
  Future<Result<void>> answerReview({
    required String userId,
    required int wordId,
    required bool knewIt,
  }) async {
    final quality =
        knewIt ? AppConstants.qualityCorrect : AppConstants.qualityWrong;
    final xp = knewIt
        ? AppConstants.xpCorrectAnswer
        : AppConstants.xpIncorrectAnswer;
    final statField = knewIt ? 'correct_answers' : 'incorrect_answers';

    if (!_cache.isOnline) {
      // Offline: compute SM-2 locally and queue for sync
      AppLogger.info('Offline — queuing review for word $wordId', tag: 'ProgressRepo');
      final existing = await _cache.getCachedProgress(userId, wordId);
      final sm2 = calculateSM2(
        quality: quality,
        repetitionCount: existing?.repetitionCount ?? 0,
        easeFactor: existing?.easeFactor ?? AppConstants.sm2DefaultEaseFactor,
        intervalDays: existing?.intervalDays ?? 0,
      );
      await _cache.queueProgressUpdate(
        userId: userId,
        wordId: wordId,
        data: {
          'ease_factor': sm2.easeFactor,
          'interval_days': sm2.intervalDays,
          'repetition_count': sm2.repetitionCount,
          'next_review_date': sm2.nextReviewDate.toIso8601String().split('T')[0],
          'last_review_date': DateTime.now().toIso8601String().split('T')[0],
          'correct_count': (existing?.correctCount ?? 0) +
              (quality >= AppConstants.sm2CorrectThreshold ? 1 : 0),
          'incorrect_count': (existing?.incorrectCount ?? 0) +
              (quality < AppConstants.sm2CorrectThreshold ? 1 : 0),
        },
      );
      return const Result.success(null);
    }

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
        ]),);
  }
}
