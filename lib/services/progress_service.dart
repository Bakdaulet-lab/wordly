import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/user_word_progress_model.dart';
import '../utils/sm2_algorithm.dart';
import '../constants/app_constants.dart';
import 'interfaces/i_progress_service.dart';

/// Supabase data-access layer for spaced-repetition word progress.
class ProgressService implements IProgressService {
  final SupabaseClient _client;

  ProgressService(this._client);

  /// Fetch words due for review (next_review_date <= today).
  @override
  Future<List<Map<String, dynamic>>> getWordsForReview(String userId, {int limit = 20}) async {
    final today = DateTime.now().toIso8601String().split('T')[0];
    final response = await _client
        .from('user_word_progress')
        .select('*, words(*)')
        .eq('user_id', userId)
        .lte('next_review_date', today)
        .order('next_review_date', ascending: true)
        .limit(limit);
    return List<Map<String, dynamic>>.from(response);
  }

  /// Get progress for a specific user-word pair.
  @override
  Future<UserWordProgressModel?> getProgress(String userId, int wordId) async {
    final response = await _client
        .from('user_word_progress')
        .select()
        .eq('user_id', userId)
        .eq('word_id', wordId)
        .limit(1);
    final list = response as List;
    if (list.isEmpty) return null;
    return UserWordProgressModel.fromJson(list.first);
  }

  /// Create or update progress after a quiz/review answer.
  @override
  Future<void> updateProgress({
    required String userId,
    required int wordId,
    required int quality,
  }) async {
    final existing = await getProgress(userId, wordId);

    if (existing == null) {
      // First time seeing this word
      final result = calculateSM2(
        quality: quality,
        repetitionCount: 0,
        easeFactor: AppConstants.sm2DefaultEaseFactor,
        intervalDays: 0,
      );

      await _client.from('user_word_progress').insert({
        'user_id': userId,
        'word_id': wordId,
        'ease_factor': result.easeFactor,
        'interval_days': result.intervalDays,
        'repetition_count': result.repetitionCount,
        'next_review_date': result.nextReviewDate.toIso8601String().split('T')[0],
        'last_review_date': DateTime.now().toIso8601String().split('T')[0],
        'correct_count': quality >= AppConstants.sm2CorrectThreshold ? 1 : 0,
        'incorrect_count': quality < AppConstants.sm2CorrectThreshold ? 1 : 0,
      });
    } else {
      // Update existing progress
      final result = calculateSM2(
        quality: quality,
        repetitionCount: existing.repetitionCount,
        easeFactor: existing.easeFactor,
        intervalDays: existing.intervalDays,
      );

      await _client.from('user_word_progress').update({
        'ease_factor': result.easeFactor,
        'interval_days': result.intervalDays,
        'repetition_count': result.repetitionCount,
        'next_review_date': result.nextReviewDate.toIso8601String().split('T')[0],
        'last_review_date': DateTime.now().toIso8601String().split('T')[0],
        'correct_count': existing.correctCount + (quality >= AppConstants.sm2CorrectThreshold ? 1 : 0),
        'incorrect_count': existing.incorrectCount + (quality < AppConstants.sm2CorrectThreshold ? 1 : 0),
      }).eq('id', existing.id);
    }
  }

  /// Count how many words are due for review today.
  @override
  Future<int> countDueWords(String userId) async {
    final today = DateTime.now().toIso8601String().split('T')[0];
    final response = await _client
        .from('user_word_progress')
        .select('id')
        .eq('user_id', userId)
        .lte('next_review_date', today);
    return (response as List).length;
  }
}
