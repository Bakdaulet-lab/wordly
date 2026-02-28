import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/daily_stats_model.dart';
import '../models/profile_model.dart';
import '../utils/date_helpers.dart';

class StatsService {
  final SupabaseClient _client = Supabase.instance.client;

  /// Get or create today's stats row.
  Future<DailyStatsModel> getOrCreateTodayStats(String userId) async {
    final today = DateHelpers.today().toIso8601String().split('T')[0];

    // Try to fetch existing
    final existing = await _client
        .from('daily_stats')
        .select()
        .eq('user_id', userId)
        .eq('date', today)
        .limit(1);

    final list = existing as List;
    if (list.isNotEmpty) {
      return DailyStatsModel.fromJson(list.first);
    }

    // Create new row
    final response = await _client.from('daily_stats').insert({
      'user_id': userId,
      'date': today,
    }).select();

    final inserted = response as List;
    return DailyStatsModel.fromJson(inserted.first);
  }

  /// Increment a numeric field in today's stats.
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

    final list = current as List;
    final currentValue = list.isNotEmpty ? (list.first[field] as int? ?? 0) : 0;

    await _client
        .from('daily_stats')
        .update({field: currentValue + amount})
        .eq('user_id', userId)
        .eq('date', today);
  }

  /// Get stats for a date range.
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

    return (response as List)
        .map((json) => DailyStatsModel.fromJson(json))
        .toList();
  }

  /// Update streak based on last login date.
  Future<void> updateStreak(String userId) async {
    final profileResponse = await _client
        .from('profiles')
        .select()
        .eq('id', userId)
        .limit(1);

    final list = profileResponse as List;
    if (list.isEmpty) return;

    final profile = ProfileModel.fromJson(list.first);
    final today = DateHelpers.today();

    int newStreak = profile.currentStreak;
    int newLongest = profile.longestStreak;

    if (profile.lastLoginDate == null) {
      // First login ever
      newStreak = 1;
    } else if (DateHelpers.isToday(profile.lastLoginDate!)) {
      // Already logged in today, no change
      return;
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
  }
}
