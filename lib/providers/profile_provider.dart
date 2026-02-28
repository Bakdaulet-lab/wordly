import 'package:flutter/material.dart';
import '../models/profile_model.dart';
import '../services/profile_service.dart';
import '../utils/xp_calculator.dart';
import '../utils/error_helpers.dart';

class ProfileProvider extends ChangeNotifier {
  final ProfileService _profileService = ProfileService();

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

    try {
      _profile = await _profileService.getProfile(userId);
      _isLoading = false;
      notifyListeners();
    } catch (e) {
      _errorMessage = friendlyError(e);
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> refreshProfile(String userId) async {
    try {
      _profile = await _profileService.getProfile(userId);
      notifyListeners();
    } catch (e) {
      _errorMessage = friendlyError(e);
      notifyListeners();
    }
  }

  Future<bool> updateDisplayName(String userId, String newName) async {
    try {
      await _profileService.updateProfile(userId, {'display_name': newName});
      _profile = _profile?.copyWith(displayName: newName);
      notifyListeners();
      return true;
    } catch (e) {
      _errorMessage = friendlyError(e);
      notifyListeners();
      return false;
    }
  }

  void clear() {
    _profile = null;
    _errorMessage = null;
    notifyListeners();
  }
}
