import 'package:flutter/material.dart';
import '../models/achievement_model.dart';
import '../models/user_achievement_model.dart';
import '../services/achievement_service.dart';
import '../utils/error_helpers.dart';

class AchievementProvider extends ChangeNotifier {
  final AchievementService _achievementService = AchievementService();

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

    try {
      _allAchievements = await _achievementService.fetchAllAchievements();
      _userAchievements = await _achievementService.fetchUserAchievements(userId);
      _isLoading = false;
      notifyListeners();
    } catch (e) {
      _errorMessage = friendlyError(e);
      _isLoading = false;
      notifyListeners();
    }
  }

  /// Check and potentially unlock an achievement. Returns the achievement if newly unlocked.
  Future<AchievementModel?> checkAndUnlock({
    required String userId,
    required String conditionType,
    required int currentValue,
  }) async {
    try {
      final unlocked = await _achievementService.checkAndUnlock(
        userId: userId,
        conditionType: conditionType,
        currentValue: currentValue,
      );
      if (unlocked != null) {
        // Refresh user achievements
        _userAchievements = await _achievementService.fetchUserAchievements(userId);
        notifyListeners();
      }
      return unlocked;
    } catch (e) {
      return null;
    }
  }
}
