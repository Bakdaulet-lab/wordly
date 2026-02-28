import 'package:flutter/material.dart';
import '../models/achievement_model.dart';
import '../models/user_achievement_model.dart';
import '../di/service_locator.dart';
import '../repositories/achievement_repository.dart';

class AchievementProvider extends ChangeNotifier {
  final AchievementRepository _achievementRepo = sl<AchievementRepository>();

  List<AchievementModel> _allAchievements = [];
  List<UserAchievementModel> _userAchievements = [];
  bool _isLoading = false;
  String? _errorMessage;

  List<AchievementModel> get allAchievements => _allAchievements;
  List<UserAchievementModel> get userAchievements => _userAchievements;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;

  Set<int> get unlockedIds =>
      _userAchievements.map((ua) => ua.achievementId).toSet();

  bool isUnlocked(int achievementId) => unlockedIds.contains(achievementId);

  Future<void> loadAchievements(String userId) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    final allResult = await _achievementRepo.fetchAllAchievements();
    final userResult = await _achievementRepo.fetchUserAchievements(userId);

    _isLoading = false;

    allResult.when(
      success: (achievements) => _allAchievements = achievements,
      failure: (error) => _errorMessage = error.userMessage,
    );
    userResult.when(
      success: (achievements) => _userAchievements = achievements,
      failure: (error) => _errorMessage ??= error.userMessage,
    );

    notifyListeners();
  }

  /// Check and potentially unlock an achievement. Returns the achievement if newly unlocked.
  Future<AchievementModel?> checkAndUnlock({
    required String userId,
    required String conditionType,
    required int currentValue,
  }) async {
    final result = await _achievementRepo.checkAndUnlock(
      userId: userId,
      conditionType: conditionType,
      currentValue: currentValue,
    );

    return result.when(
      success: (unlocked) async {
        if (unlocked != null) {
          final userResult =
              await _achievementRepo.fetchUserAchievements(userId);
          userResult.when(
            success: (achievements) {
              _userAchievements = achievements;
              notifyListeners();
            },
            failure: (_) {},
          );
        }
        return unlocked;
      },
      failure: (_) => null,
    );
  }
}
