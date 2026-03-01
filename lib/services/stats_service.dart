import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/daily_stats_model.dart';
import '../models/profile_model.dart';
import '../utils/date_helpers.dart';
import '../utils/response_validator.dart';
import 'interfaces/i_stats_service.dart';

/// Supabase data-access layer for daily statistics and streak tracking.
class StatsService implements IStatsService {
  final SupabaseClient _client;

  StatsService(this._client);

  /// Get or create today's stats row.
  @override
  Future<DailyStatsModel> getOrCreateTodayStats(String userId) async {
    final today = DateHelpers.today().toIso8601String().split('T')[0];

    // Try to fetch existing
    final existing = await _client
        .from('daily_stats')
        .select()
        .eq('user_id', userId)
        .eq('date', today)
        .limit(1);

    final validated = ResponseValidator.validateList(
      existing,
      context: 'getOrCreateTodayStats',
    );
    final list = validated.when(
      success: (rows) => rows,
      failure: (error) => throw error,
    );
    if (list.isNotEmpty) {
      return DailyStatsModel.fromJson(list.first);
    }

    // Create new row
    final response = await _client.from('daily_stats').insert({
      'user_id': userId,
      'date': today,
    }).select();

    final insertValidated = ResponseValidator.validateAndMapList(
      response, DailyStatsModel.fromJson,
      context: 'getOrCreateTodayStats.insert',
    );
    return insertValidated.when(
      success: (rows) => rows.first,
      failure: (error) => throw error,
    );
  }

  /// Increment a numeric field in today's stats.
  @override
  Future<void> incrementStat(String userId, String field, int amount) async {
    final today = DateHelpers.today().toIso8601String().split('T')[0];

    // Ensure row exists
    await getOrCreateTodayStats(userId);

    // Fetch current value, then update
    final current = await _client
        .from('daily_stats')
        .select(field)
        .eq('user_id', userId)
        .eq('date', today)
        .limit(1);

    final valValidated = ResponseValidator.validateList(
      current,
      context: 'incrementStat.read',
    );
    final list = valValidated.when(
      success: (rows) => rows,
      failure: (error) => throw error,
    );
    final currentValue = list.isNotEmpty ? (list.first[field] as int? ?? 0) : 0;

    await _client
        .from('daily_stats')
        .update({field: currentValue + amount})
        .eq('user_id', userId)
        .eq('date', today);
  }

  /// Get stats for a date range.
  @override
  Future<List<DailyStatsModel>> getStatsForRange(
    String userId,
    DateTime startDate,
    DateTime endDate,
  ) async {
    final start = startDate.toIso8601String().split('T')[0];
    final end = endDate.toIso8601String().split('T')[0];

    final response = await _client
        .from('daily_stats')
        .select()
        .eq('user_id', userId)
        .gte('date', start)
        .lte('date', end)
        .order('date', ascending: false);

    final validated = ResponseValidator.validateAndMapList(
      response, DailyStatsModel.fromJson,
      context: 'getStatsForRange',
    );
    return validated.when(
      success: (stats) => stats,
      failure: (error) => throw error,
    );
  }

  /// Update streak based on last login date and return the new value.
  @override
  Future<int> updateStreak(String userId) async {
    final profileResponse = await _client
        .from('profiles')
        .select()
        .eq('id', userId)
        .limit(1);

    final validated = ResponseValidator.validateAndMapSingleRow(
      profileResponse, ProfileModel.fromJson,
      context: 'updateStreak',
    );
    final profile = validated.when(
      success: (p) => p,
      failure: (error) => throw error,
    );
    if (profile == null) return 0;
    final today = DateHelpers.today();

    int newStreak = profile.currentStreak;
    int newLongest = profile.longestStreak;

    if (profile.lastLoginDate == null) {
      // First login ever
      newStreak = 1;
    } else if (DateHelpers.isToday(profile.lastLoginDate!)) {
      // Already logged in today, no change
      return profile.currentStreak;
    } else if (DateHelpers.isYesterday(profile.lastLoginDate!)) {
      // Consecutive day
      newStreak = profile.currentStreak + 1;
    } else {
      // Streak broken
      newStreak = 1;
    }

    if (newStreak > newLongest) {
      newLongest = newStreak;
    }

    await _client.from('profiles').update({
      'current_streak': newStreak,
      'longest_streak': newLongest,
      'last_login_date': today.toIso8601String().split('T')[0],
    }).eq('id', userId);

    return newStreak;
  }
}
