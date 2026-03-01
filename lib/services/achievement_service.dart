import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/achievement_model.dart';
import '../models/user_achievement_model.dart';
import '../utils/response_validator.dart';
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
    final validated = ResponseValidator.validateAndMapList(
      response, AchievementModel.fromJson,
      context: 'fetchAllAchievements',
    );
    return validated.when(
      success: (list) => list,
      failure: (error) => throw error,
    );
  }

  @override
  Future<List<UserAchievementModel>> fetchUserAchievements(String userId) async {
    final response = await _client
        .from('user_achievements')
        .select()
        .eq('user_id', userId);
    final validated = ResponseValidator.validateAndMapList(
      response, UserAchievementModel.fromJson,
      context: 'fetchUserAchievements',
    );
    return validated.when(
      success: (list) => list,
      failure: (error) => throw error,
    );
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

    final achValidated = ResponseValidator.validateAndMapList(
      achievements, AchievementModel.fromJson,
      context: 'checkAndUnlock.achievements',
    );
    final achList = achValidated.when(
      success: (list) => list,
      failure: (error) => throw error,
    );

    for (final achievement in achList) {
      if (currentValue >= achievement.conditionValue) {
        // Check if already unlocked
        final existing = await _client
            .from('user_achievements')
            .select('id')
            .eq('user_id', userId)
            .eq('achievement_id', achievement.id)
            .limit(1);

        final existValidated = ResponseValidator.validateList(
          existing,
          context: 'checkAndUnlock.existing',
        );
        final existList = existValidated.when(
          success: (rows) => rows,
          failure: (error) => throw error,
        );

        if (existList.isEmpty) {
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
