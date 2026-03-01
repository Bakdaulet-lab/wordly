import '../models/profile_model.dart';
import '../di/service_locator.dart';
import '../repositories/profile_repository.dart';
import '../utils/xp_calculator.dart';
import 'base_provider.dart';

/// Manages the current user's profile data and XP/level display.
class ProfileProvider extends BaseProvider {
  final ProfileRepository _profileRepo = sl<ProfileRepository>();

  ProfileModel? _profile;

  ProfileModel? get profile => _profile;

  int get level => _profile?.level ?? 1;
  int get totalXp => _profile?.totalXp ?? 0;
  int get currentStreak => _profile?.currentStreak ?? 0;
  int get longestStreak => _profile?.longestStreak ?? 0;
  String get displayName => _profile?.displayName ?? '';

  double get xpProgress => XpCalculator.xpProgressInLevel(totalXp);
  int? get xpForNextLevel => XpCalculator.xpForNextLevel(level);

  Future<void> loadProfile(String userId) async {
    setLoading(true);
    setError(null, notify: false);

    final result = await _profileRepo.getProfile(userId);
    setLoading(false);

    result.when(
      success: (profile) {
        _profile = profile;
        notifyListeners();
      },
      failure: (error) {
        setError(error.userMessage);
      },
    );
  }

  Future<void> refreshProfile(String userId) async {
    final result = await _profileRepo.getProfile(userId);
    result.when(
      success: (profile) {
        _profile = profile;
        notifyListeners();
      },
      failure: (error) {
        setError(error.userMessage);
      },
    );
  }

  Future<bool> updateDisplayName(String userId, String newName) async {
    final result =
        await _profileRepo.updateProfile(userId, {'display_name': newName});
    return result.when(
      success: (_) {
        _profile = _profile?.copyWith(displayName: newName);
        notifyListeners();
        return true;
      },
      failure: (error) {
        setError(error.userMessage);
        return false;
      },
    );
  }

  /// Reset all learning progress (XP, streaks, level).
  Future<bool> resetProgress(String userId) async {
    final result = await _profileRepo.updateProfile(userId, {
      'total_xp': 0,
      'level': 1,
      'current_streak': 0,
      'longest_streak': 0,
    });
    return result.when(
      success: (_) {
        _profile = _profile?.copyWith(
          totalXp: 0,
          level: 1,
          currentStreak: 0,
          longestStreak: 0,
        );
        notifyListeners();
        return true;
      },
      failure: (error) {
        setError(error.userMessage);
        return false;
      },
    );
  }

  void clear() {
    _profile = null;
    setError(null);
  }
}
