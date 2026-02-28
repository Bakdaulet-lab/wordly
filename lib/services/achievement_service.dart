import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/achievement_model.dart';
import '../models/user_achievement_model.dart';
import 'interfaces/i_achievement_service.dart';

/// Supabase data-access layer for achievements and unlock tracking.
class AchievementService implements IAchievementService {
  final SupabaseClient _client;

  AchievementService(this._client);

  @override
  Future<List<AchievementModel>> fetchAllAchievements() async {
    final response = await _client
        .from('achievements')
        .select()
        .order('id', ascending: true);
    return (response as List)
        .map((json) => AchievementModel.fromJson(json))
        .toList();
  }

  @override
  Future<List<UserAchievementModel>> fetchUserAchievements(String userId) async {
    final response = await _client
        .from('user_achievements')
        .select()
        .eq('user_id', userId);
    return (response as List)
        .map((json) => UserAchievementModel.fromJson(json))
        .toList();
  }

  /// Check if a condition is met and unlock the achievement if not already earned.
  /// Returns the newly unlocked achievement, or null if already unlocked or condition not met.
  @override
  Future<AchievementModel?> checkAndUnlock({
    required String userId,
    required String conditionType,
    required int currentValue,
  }) async {
    // Fetch all achievements matching this condition type
    final achievements = await _client
        .from('achievements')
        .select()
        .eq('condition_type', conditionType);

    for (final achJson in achievements) {
      final achievement = AchievementModel.fromJson(achJson);

      if (currentValue >= achievement.conditionValue) {
        // Check if already unlocked
        final existing = await _client
            .from('user_achievements')
            .select('id')
            .eq('user_id', userId)
            .eq('achievement_id', achievement.id)
            .limit(1);

        if ((existing as List).isEmpty) {
          // Unlock it
          await _client.from('user_achievements').insert({
            'user_id': userId,
            'achievement_id': achievement.id,
          });
          return achievement;
        }
      }
    }
    return null;
  }
}
