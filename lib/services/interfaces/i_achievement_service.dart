import '../../models/achievement_model.dart';
import '../../models/user_achievement_model.dart';

/// Contract for achievement queries and unlocking.
abstract class IAchievementService {
  /// Fetch all global achievement definitions.
  Future<List<AchievementModel>> fetchAllAchievements();

  /// Fetch achievements unlocked by [userId].
  Future<List<UserAchievementModel>> fetchUserAchievements(String userId);

  /// Check if an achievement should be unlocked and do so if applicable.
  /// Returns the newly unlocked achievement model, or `null`.
  Future<AchievementModel?> checkAndUnlock({
    required String userId,
    required String conditionType,
    required int currentValue,
  });
}
