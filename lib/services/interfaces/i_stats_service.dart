import '../../models/daily_stats_model.dart';

/// Contract for daily statistics tracking.
abstract class IStatsService {
  /// Get or create today's stats row for [userId].
  Future<DailyStatsModel> getOrCreateTodayStats(String userId);

  /// Increment a single stat [field] by [amount].
  Future<void> incrementStat(String userId, String field, int amount);

  /// Fetch stats for a date range.
  Future<List<DailyStatsModel>> getStatsForRange(
    String userId,
    DateTime startDate,
    DateTime endDate,
  );

  /// Update the user's streak and return the new streak value.
  Future<int> updateStreak(String userId);
}
