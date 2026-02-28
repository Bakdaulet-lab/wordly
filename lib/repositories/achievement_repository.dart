import '../models/achievement_model.dart';
import '../models/user_achievement_model.dart';
import '../services/achievement_service.dart';
import '../utils/api_guard.dart';
import '../utils/result.dart';

/// Repository for achievement queries and unlocking.
class AchievementRepository {
  final AchievementService _achievementService;

  AchievementRepository(this._achievementService);

  Future<Result<List<AchievementModel>>> fetchAllAchievements() {
    return apiGuard(() => _achievementService.fetchAllAchievements());
  }

  Future<Result<List<UserAchievementModel>>> fetchUserAchievements(
      String userId,) {
    return apiGuard(
        () => _achievementService.fetchUserAchievements(userId),);
  }

  Future<Result<AchievementModel?>> checkAndUnlock({
    required String userId,
    required String conditionType,
    required int currentValue,
  }) {
    return apiGuard(() => _achievementService.checkAndUnlock(
          userId: userId,
          conditionType: conditionType,
          currentValue: currentValue,
        ),);
  }
}
