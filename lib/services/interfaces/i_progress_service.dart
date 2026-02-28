import '../../models/user_word_progress_model.dart';

/// Contract for spaced-repetition progress tracking.
abstract class IProgressService {
  /// Fetch words due for review (next_review_date <= today).
  Future<List<Map<String, dynamic>>> getWordsForReview(
    String userId, {
    int limit = 20,
  });

  /// Get progress for a specific user–word pair.
  Future<UserWordProgressModel?> getProgress(String userId, int wordId);

  /// Count words due for review.
  Future<int> countDueWords(String userId);

  /// Update progress after a review using SM-2 algorithm.
  Future<void> updateProgress({
    required String userId,
    required int wordId,
    required int quality,
  });
}
