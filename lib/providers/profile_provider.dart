import 'package:flutter/material.dart';
import '../models/profile_model.dart';
import '../di/service_locator.dart';
import '../repositories/profile_repository.dart';
import '../utils/xp_calculator.dart';

/// Manages the current user's profile data and XP/level display.
class ProfileProvider extends ChangeNotifier {
  final ProfileRepository _profileRepo = sl<ProfileRepository>();

  ProfileModel? _profile;
  bool _isLoading = false;
  String? _errorMessage;

  ProfileModel? get profile => _profile;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;

  int get level => _profile?.level ?? 1;
  int get totalXp => _profile?.totalXp ?? 0;
  int get currentStreak => _profile?.currentStreak ?? 0;
  int get longestStreak => _profile?.longestStreak ?? 0;
  String get displayName => _profile?.displayName ?? '';

  double get xpProgress => XpCalculator.xpProgressInLevel(totalXp);
  int? get xpForNextLevel => XpCalculator.xpForNextLevel(level);

  Future<void> loadProfile(String userId) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    final result = await _profileRepo.getProfile(userId);
    _isLoading = false;

    result.when(
      success: (profile) {
        _profile = profile;
        notifyListeners();
      },
      failure: (error) {
        _errorMessage = error.userMessage;
        notifyListeners();
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
        _errorMessage = error.userMessage;
        notifyListeners();
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
        _errorMessage = error.userMessage;
        notifyListeners();
        return false;
      },
    );
  }

  void clear() {
    _profile = null;
    _errorMessage = null;
    notifyListeners();
  }
}
